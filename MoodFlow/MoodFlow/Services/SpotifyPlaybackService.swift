import Foundation
import SpotifyiOS
import UIKit

@MainActor
class SpotifyPlaybackService: NSObject, ObservableObject {

    @Published var isConnected = false
    @Published var isPlaying = false
    @Published var currentTrackURI: String?
    @Published var currentTrackName: String?
    @Published var currentArtistName: String?
    @Published var connectionError: String?

    private var appRemote: SPTAppRemote?

    // We own this queue entirely — Spotify must always play songQueue[queueIndex]
    private(set) var songQueue: [String] = []
    private(set) var queueIndex: Int = 0
    private var songDurations: [Int] = []

    private var pendingPlayURI: String?

    // Auto-advance: fires when current song's duration elapses
    private var advanceTimer: Timer?
    // Sync watchdog: every 3s checks Spotify is on the right track
    private var syncTimer: Timer?
    // Grace period: suppresses watchdog corrections right after a play command
    private var lastPlayCommandTime: Date?
    private var songStartTime: Date?

    var onQueueIndexChanged: ((Int) -> Void)?

    override init() {
        super.init()
        setupAppRemote()
    }

    // MARK: - Setup

    private func setupAppRemote() {
        guard !Config.spotifyClientID.hasPrefix("YOUR_") else { return }
        let config = SPTConfiguration(
            clientID: Config.spotifyClientID,
            redirectURL: URL(string: Config.spotifyRedirectURI)!
        )
        let remote = SPTAppRemote(configuration: config, logLevel: .error)
        remote.delegate = self
        self.appRemote = remote
    }

    // MARK: - Public API

    func startQueue(uris: [String], durations: [Int], accessToken: String) {
        guard !uris.isEmpty else { return }
        songQueue = uris
        songDurations = durations
        queueIndex = 0
        pendingPlayURI = uris[0]
        appRemote?.connectionParameters.accessToken = accessToken

        if appRemote?.isConnected == true {
            playCurrent()
        } else {
            appRemote?.connect()
        }
    }

    func skipToNext() {
        guard queueIndex + 1 < songQueue.count else { return }
        queueIndex += 1
        playCurrent()
    }

    func skipToPrevious() {
        guard queueIndex - 1 >= 0 else { return }
        queueIndex -= 1
        playCurrent()
    }

    func pause() {
        advanceTimer?.invalidate()
        appRemote?.playerAPI?.pause { _, _ in }
        isPlaying = false
    }

    func resume() {
        playCurrent()
    }

    func disconnect() {
        advanceTimer?.invalidate()
        syncTimer?.invalidate()
        appRemote?.disconnect()
    }

    func handleOpenURL(_ url: URL) {
        guard let appRemote else { return }
        let params = appRemote.authorizationParameters(from: url)
        if let token = params?[SPTAppRemoteAccessTokenKey] as? String {
            appRemote.connectionParameters.accessToken = token
            appRemote.connect()
        }
    }

    func connectAndPlay(uri: String, accessToken: String) {
        startQueue(uris: [uri], durations: [210_000], accessToken: accessToken)
    }

    func updateQueue(uris: [String], fromIndex: Int) {
        let prefix = Array(songQueue.prefix(fromIndex))
        songQueue = prefix + uris
    }

    // MARK: - Core: play exactly songQueue[queueIndex]

    private func playCurrent() {
        advanceTimer?.invalidate()
        guard queueIndex < songQueue.count else { return }

        let uri = songQueue[queueIndex]
        lastPlayCommandTime = Date()
        songStartTime = Date()

        // Update UI immediately — don't wait for Spotify to confirm
        currentTrackURI = uri
        onQueueIndexChanged?(queueIndex)

        sendPlayCommand(uri: uri)
    }

    /// Sends play(uri) to Spotify. Falls back to authorizeAndPlayURI if not connected.
    private func sendPlayCommand(uri: String) {
        guard let appRemote else { return }

        if appRemote.isConnected, let playerAPI = appRemote.playerAPI {
            playerAPI.play(uri) { [weak self] _, error in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    if let error {
                        // Play call failed — fall back to authorizeAndPlayURI
                        appRemote.authorizeAndPlayURI(uri)
                        self.connectionError = error.localizedDescription
                    } else {
                        self.isPlaying = true
                        self.connectionError = nil
                        self.scheduleAdvanceTimer()
                        self.startSyncWatchdog()
                    }
                }
            }
        } else {
            // Not connected — authorizeAndPlayURI opens Spotify, auths, and plays the track
            pendingPlayURI = uri
            appRemote.authorizeAndPlayURI(uri)
        }
    }

    // MARK: - Auto-advance timer

    private func scheduleAdvanceTimer() {
        advanceTimer?.invalidate()
        guard queueIndex < songDurations.count else { return }
        let secs = max(10.0, Double(songDurations[queueIndex]) / 1000.0 - 1.5)

        advanceTimer = Timer.scheduledTimer(withTimeInterval: secs, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, self.queueIndex + 1 < self.songQueue.count else { return }
                self.queueIndex += 1
                self.playCurrent()
            }
        }
    }

    // MARK: - Sync watchdog

    private func startSyncWatchdog() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAndEnforceSync()
            }
        }
    }

    private func checkAndEnforceSync() {
        // Reconnect if dropped
        guard appRemote?.isConnected == true else {
            reconnect()
            return
        }
        guard queueIndex < songQueue.count else { return }

        // Skip check if we just issued a play command (give Spotify 4s to respond)
        if let last = lastPlayCommandTime, Date().timeIntervalSince(last) < 4.0 { return }

        let expectedURI = songQueue[queueIndex]

        appRemote?.playerAPI?.getPlayerState { [weak self] result, _ in
            Task { @MainActor [weak self] in
                guard let self,
                      let state = result as? SPTAppRemotePlayerState else { return }
                if state.track.uri != expectedURI {
                    self.handleTrackDrift(actualURI: state.track.uri)
                }
                // Keep shuffle+repeat locked
                self.appRemote?.playerAPI?.setShuffle(false, callback: { _, _ in })
                self.appRemote?.playerAPI?.setRepeatMode(.off, callback: { _, _ in })
            }
        }
    }

    /// Determines whether a track mismatch means the song finished (advance)
    /// or Spotify drifted mid-song (force correct track back).
    private func handleTrackDrift(actualURI: String) {
        guard queueIndex < songQueue.count else { return }
        let expectedURI = songQueue[queueIndex]
        guard actualURI != expectedURI else { return }

        // Skip during grace period
        if let last = lastPlayCommandTime, Date().timeIntervalSince(last) < 4.0 { return }

        // Check if the current song likely finished naturally
        let songLikelyFinished: Bool
        if let startTime = songStartTime, queueIndex < songDurations.count {
            let elapsed = Date().timeIntervalSince(startTime)
            let expectedDuration = Double(songDurations[queueIndex]) / 1000.0
            songLikelyFinished = elapsed >= expectedDuration * 0.80
        } else {
            songLikelyFinished = true
        }

        if songLikelyFinished && queueIndex + 1 < songQueue.count {
            // Song finished → advance to next in our queue
            advanceTimer?.invalidate()
            queueIndex += 1
            playCurrent()
        } else if !songLikelyFinished {
            // Unexpected mid-song drift → force Spotify back to our track
            sendPlayCommand(uri: expectedURI)
        }
    }

    private func reconnect() {
        guard appRemote?.isConnected == false else { return }
        appRemote?.connect()
    }
}

// MARK: - SPTAppRemoteDelegate

extension SpotifyPlaybackService: SPTAppRemoteDelegate {

    nonisolated func appRemoteDidEstablishConnection(_ appRemote: SPTAppRemote) {
        Task { @MainActor in
            isConnected = true
            connectionError = nil

            appRemote.playerAPI?.delegate = self
            appRemote.playerAPI?.subscribe(toPlayerState: { _, _ in })
            appRemote.playerAPI?.setShuffle(false, callback: { _, _ in })
            appRemote.playerAPI?.setRepeatMode(.off, callback: { _, _ in })

            // Play whatever should be playing now
            let uri = pendingPlayURI ?? (queueIndex < songQueue.count ? songQueue[queueIndex] : nil)
            pendingPlayURI = nil
            guard let uri else { return }

            lastPlayCommandTime = Date()
            appRemote.playerAPI?.play(uri) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    self?.isPlaying = true
                    self?.songStartTime = Date()
                    self?.scheduleAdvanceTimer()
                    self?.startSyncWatchdog()
                }
            }
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didFailConnectionAttemptWithError error: Error?) {
        Task { @MainActor in
            isConnected = false
            let uri = pendingPlayURI ?? (queueIndex < songQueue.count ? songQueue[queueIndex] : nil)
            if let uri {
                // authorizeAndPlayURI opens Spotify app, authenticates, and plays
                appRemote.authorizeAndPlayURI(uri)
            }
        }
    }

    nonisolated func appRemote(_ appRemote: SPTAppRemote, didDisconnectWithError error: Error?) {
        Task { @MainActor in
            isConnected = false
            isPlaying = false
            advanceTimer?.invalidate()
            syncTimer?.invalidate()
            // Auto-reconnect
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.reconnect()
            }
        }
    }
}

// MARK: - SPTAppRemotePlayerStateDelegate

extension SpotifyPlaybackService: SPTAppRemotePlayerStateDelegate {

    nonisolated func playerStateDidChange(_ playerState: SPTAppRemotePlayerState) {
        Task { @MainActor in
            isPlaying = !playerState.isPaused
            currentTrackName = playerState.track.name
            currentArtistName = playerState.track.artist.name

            // Primary sync mechanism: detect when Spotify drifts from our queue
            handleTrackDrift(actualURI: playerState.track.uri)
        }
    }
}
