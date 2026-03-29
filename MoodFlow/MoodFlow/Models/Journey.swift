import Foundation

struct JourneyStage: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var stageDescription: String
    var order: Int
    var targetBPMMin: Int
    var targetBPMMax: Int
    var targetEnergy: Double
    var targetValence: Double
    var songs: [Song]

    var totalDurationSeconds: Double {
        songs.compactMap { $0.durationMs }.reduce(0, +).toDouble / 1000.0
    }

    var totalDurationFormatted: String {
        let total = Int(totalDurationSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(
        id: UUID = UUID(),
        name: String,
        stageDescription: String,
        order: Int,
        targetBPMMin: Int = 80,
        targetBPMMax: Int = 120,
        targetEnergy: Double = 0.5,
        targetValence: Double = 0.5,
        songs: [Song] = []
    ) {
        self.id = id
        self.name = name
        self.stageDescription = stageDescription
        self.order = order
        self.targetBPMMin = targetBPMMin
        self.targetBPMMax = targetBPMMax
        self.targetEnergy = targetEnergy
        self.targetValence = targetValence
        self.songs = songs
    }
}

struct Journey: Codable, Identifiable {
    let id: UUID
    var currentMood: Mood
    var desiredMood: Mood
    var durationMinutes: Int
    var stages: [JourneyStage]
    var currentStageIndex: Int
    var currentSongIndex: Int
    var startTime: Date?
    var isComplete: Bool

    var currentStage: JourneyStage? {
        guard currentStageIndex < stages.count else { return nil }
        return stages[currentStageIndex]
    }

    var currentSong: Song? {
        guard let stage = currentStage,
              currentSongIndex < stage.songs.count else { return nil }
        return stage.songs[currentSongIndex]
    }

    var totalSongs: Int {
        stages.flatMap(\.songs).count
    }

    var allSongs: [Song] {
        stages.flatMap(\.songs)
    }

    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        return Date().timeIntervalSince(start)
    }

    var targetDurationSeconds: Double {
        Double(durationMinutes) * 60.0
    }

    var progressFraction: Double {
        guard targetDurationSeconds > 0 else { return 0 }
        return min(elapsedTime / targetDurationSeconds, 1.0)
    }

    init(
        id: UUID = UUID(),
        currentMood: Mood,
        desiredMood: Mood,
        durationMinutes: Int,
        stages: [JourneyStage] = [],
        currentStageIndex: Int = 0,
        currentSongIndex: Int = 0,
        startTime: Date? = nil,
        isComplete: Bool = false
    ) {
        self.id = id
        self.currentMood = currentMood
        self.desiredMood = desiredMood
        self.durationMinutes = durationMinutes
        self.stages = stages
        self.currentStageIndex = currentStageIndex
        self.currentSongIndex = currentSongIndex
        self.startTime = startTime
        self.isComplete = isComplete
    }
}

private extension Int {
    var toDouble: Double { Double(self) }
}
