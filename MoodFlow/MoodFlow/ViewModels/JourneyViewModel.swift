import Foundation
import SwiftUI
import Combine

enum JourneyState: Equatable {
    case idle
    case generating
    case resolvingSpotify
    case preview
    case active
    case recuating
    case complete
    case error(String)
}

@MainActor
class JourneyViewModel: ObservableObject {

    // MARK: - Published state

    @Published var journeyState: JourneyState = .idle
    @Published var journey: Journey?
    @Published var loadingMessage: String = ""

    // Active journey tracking
    @Published var elapsedSeconds: Double = 0
    @Published var currentStageIndex: Int = 0
    @Published var currentSongIndex: Int = 0
    @Published var moodCheckInVisible: Bool = false
    @Published var showMoodFeedback: Bool = false

    // Services
    let authService: SpotifyAuthService
    let playbackService: SpotifyPlaybackService

    private let claudeService = ClaudeService()
    private let webAPIService = SpotifyWebAPIService()

    private var journeyTimer: Timer?
    private var moodCheckTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // Flat ordered list of all songs across all stages — mirrors the Spotify queue
    private var flatSongList: [Song] = []

    // MARK: - Init

    init(authService: SpotifyAuthService, playbackService: SpotifyPlaybackService) {
        self.authService = authService
        self.playbackService = playbackService

        // Queue index → stage/song index sync
        playbackService.onQueueIndexChanged = { [weak self] flatIndex in
            self?.syncUIToFlatIndex(flatIndex)
        }
    }

    // MARK: - Generate Journey

    func generateJourney(currentMood: Mood, desiredMood: Mood, durationMinutes: Int, biometricContext: String? = nil) async {
        journeyState = .generating
        loadingMessage = "Crafting your \(currentMood.displayName) → \(desiredMood.displayName) journey..."

        do {
            // 1. Refresh Spotify token
            try await authService.refreshTokenIfNeeded()
            guard let token = authService.accessToken else {
                throw AppError.authError("No access token")
            }
            await webAPIService.setAccessToken(token)

            // 2. Call Claude to generate journey
            loadingMessage = "AI is composing your music journey..."
            let claudeJourney = try await claudeService.generateJourney(
                currentMood: currentMood,
                desiredMood: desiredMood,
                durationMinutes: durationMinutes,
                biometricContext: biometricContext
            )

            // 3. Resolve songs on Spotify
            journeyState = .resolvingSpotify
            loadingMessage = "Finding your songs on Spotify..."

            var stages: [JourneyStage] = []
            for claudeStage in claudeJourney.stages {
                let resolvedSongs = try await webAPIService.resolveSpotifySongs(
                    from: claudeStage.songs
                )
                let stage = JourneyStage(
                    name: claudeStage.name,
                    stageDescription: claudeStage.description,
                    order: claudeStage.order,
                    targetBPMMin: claudeStage.targetBpmMin,
                    targetBPMMax: claudeStage.targetBpmMax,
                    targetEnergy: claudeStage.targetEnergy,
                    targetValence: claudeStage.targetValence,
                    songs: trimSongsToFit(
                        songs: resolvedSongs,
                        targetMinutes: durationMinutes / 4
                    )
                )
                stages.append(stage)
            }

            // 4. Create journey
            journey = Journey(
                currentMood: currentMood,
                desiredMood: desiredMood,
                durationMinutes: durationMinutes,
                stages: stages
            )
            journeyState = .preview
            loadingMessage = ""

        } catch {
            journeyState = .error(error.localizedDescription)
        }
    }

    // MARK: - Start Journey

    func startJourney() {
        guard var j = journey else { return }
        j.startTime = Date()
        journey = j

        journeyState = .active
        currentStageIndex = 0
        currentSongIndex = 0
        elapsedSeconds = 0
        moodCheckInVisible = false

        // Queue-index callback: when playback service advances, sync our UI
        playbackService.onQueueIndexChanged = { [weak self] flatIndex in
            self?.syncUIToFlatIndex(flatIndex)
        }

        // Start playback
        Task { await startPlayback() }

        // Journey timer — advances elapsed time every second
        journeyTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let j = self.journey else { return }
                self.elapsedSeconds += 1
                if self.elapsedSeconds >= Double(j.durationMinutes * 60) {
                    self.completeJourney()
                    return
                }
                let checkInterval: Double = 5 * 60
                if Int(self.elapsedSeconds) % Int(checkInterval) == 0 && self.elapsedSeconds > 0 {
                    self.moodCheckInVisible = true
                }
            }
        }

        // First mood check-in after 2 minutes
        moodCheckTimer = Timer.scheduledTimer(withTimeInterval: 120, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.moodCheckInVisible = true
            }
        }
    }

    // MARK: - Playback

    private func startPlayback() async {
        guard let j = journey else { return }
        guard let token = authService.accessToken else {
            journeyState = .error("Not logged in to Spotify")
            return
        }

        let allURIs = j.stages.flatMap { $0.songs }.compactMap { $0.spotifyURI }
        guard !allURIs.isEmpty else {
            journeyState = .error("No Spotify tracks found. Please try again.")
            return
        }

        loadingMessage = "Creating your playlist on Spotify..."

        // Build flat song list mirroring the queue order
        flatSongList = j.stages.flatMap { $0.songs }
        let uris = flatSongList.compactMap { $0.spotifyURI }
        let durations = flatSongList.map { $0.durationMs ?? 210_000 }

        guard !uris.isEmpty else {
            journeyState = .error("No Spotify tracks found. Please try again.")
            return
        }

        // Hand off to playback service — it owns the queue from here
        playbackService.startQueue(uris: uris, durations: durations, accessToken: token)
    }

    // Called by next button — single entry point, no double-skip
    func advanceToNextSong() {
        playbackService.skipToNext()
        // UI index will update via onQueueIndexChanged callback
    }

    func goToPreviousSong() {
        playbackService.skipToPrevious()
    }

    // Queue index → stage index + song-within-stage index
    private func syncUIToFlatIndex(_ flatIndex: Int) {
        guard let j = journey else { return }
        var count = 0
        for (si, stage) in j.stages.enumerated() {
            for (sj, _) in stage.songs.enumerated() {
                if count == flatIndex {
                    currentStageIndex = si
                    currentSongIndex = sj
                    return
                }
                count += 1
            }
        }
    }

    // MARK: - Mood Feedback

    func moodImproving() {
        moodCheckInVisible = false
        showMoodFeedback = false
        // Continue as-is — journey is working
    }

    func moodNotImproving() {
        moodCheckInVisible = false
        showMoodFeedback = false
        Task {
            await recurateSongs(feedback: "The current music isn't effectively shifting my mood. Please try different songs.")
        }
    }

    func recurateSongs(feedback: String) async {
        guard let j = journey else { return }
        journeyState = .recuating
        loadingMessage = "Adjusting your journey..."

        do {
            try await authService.refreshTokenIfNeeded()
            guard let token = authService.accessToken else { throw AppError.authError("No token") }
            await webAPIService.setAccessToken(token)

            let newClaudeJourney = try await claudeService.recurateSongs(
                journey: j,
                currentStageIndex: currentStageIndex,
                feedback: feedback
            )

            // Only replace stages from currentStageIndex onward
            var updatedStages = j.stages
            let stagesToReplace = min(4 - currentStageIndex, newClaudeJourney.stages.count)

            for i in 0..<stagesToReplace {
                let claudeStage = newClaudeJourney.stages[currentStageIndex + i]
                let resolvedSongs = try await webAPIService.resolveSpotifySongs(
                    from: claudeStage.songs
                )
                let stage = JourneyStage(
                    name: claudeStage.name,
                    stageDescription: claudeStage.description,
                    order: claudeStage.order,
                    targetBPMMin: claudeStage.targetBpmMin,
                    targetBPMMax: claudeStage.targetBpmMax,
                    targetEnergy: claudeStage.targetEnergy,
                    targetValence: claudeStage.targetValence,
                    songs: resolvedSongs
                )
                if currentStageIndex + i < updatedStages.count {
                    updatedStages[currentStageIndex + i] = stage
                }
            }

            journey?.stages = updatedStages

            // Update playback queue with new URIs
            let newURIs = updatedStages[currentStageIndex...]
                .flatMap { $0.songs }
                .compactMap { $0.spotifyURI }
            playbackService.updateQueue(uris: newURIs, fromIndex: currentStageIndex)

            journeyState = .active

        } catch {
            journeyState = .active // Recover gracefully
        }
        loadingMessage = ""
    }

    // MARK: - Complete

    private func completeJourney() {
        journeyTimer?.invalidate()
        playbackService.disconnect()
        moodCheckTimer?.invalidate()
        playbackService.pause()
        journeyState = .complete
    }

    func resetJourney() {
        journeyTimer?.invalidate()
        playbackService.disconnect()
        moodCheckTimer?.invalidate()
        journey = nil
        journeyState = .idle
        elapsedSeconds = 0
        currentStageIndex = 0
        currentSongIndex = 0
        moodCheckInVisible = false
    }

    // MARK: - Helpers

    private func trimSongsToFit(songs: [Song], targetMinutes: Int) -> [Song] {
        // Keep songs until we reach target duration, always keep at least 2
        var total: Double = 0
        var result: [Song] = []
        let target = Double(targetMinutes) * 60.0

        for song in songs {
            total += Double(song.durationMs ?? 210_000) / 1000.0
            result.append(song)
            if total >= target && result.count >= 2 { break }
        }
        return result.isEmpty ? songs : result
    }

    var currentSong: Song? {
        journey?.stages[safe: currentStageIndex]?.songs[safe: currentSongIndex]
    }

    var currentStage: JourneyStage? {
        journey?.stages[safe: currentStageIndex]
    }

    var stageProgress: Double {
        guard let j = journey else { return 0 }
        let stageCount = Double(j.stages.count)
        guard stageCount > 0 else { return 0 }
        return Double(currentStageIndex) / stageCount
    }

    var overallProgress: Double {
        guard let j = journey, j.durationMinutes > 0 else { return 0 }
        return min(elapsedSeconds / Double(j.durationMinutes * 60), 1.0)
    }

    var timeRemaining: String {
        guard let j = journey else { return "0:00" }
        let remaining = max(0, Double(j.durationMinutes * 60) - elapsedSeconds)
        let minutes = Int(remaining) / 60
        let seconds = Int(remaining) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

