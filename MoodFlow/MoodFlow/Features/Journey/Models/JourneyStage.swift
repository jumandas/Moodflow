import Foundation

struct JourneyStage: Codable, Identifiable {
    let id = UUID()
    let stageName: String
    let durationMinutes: Int
    let targetArousal: Double
    let microPrompt: String
    let musicCriteria: MusicCriteria

    enum CodingKeys: String, CodingKey {
        case stageName = "stage_name"
        case durationMinutes = "duration_minutes"
        case targetArousal = "target_arousal"
        case microPrompt = "micro_prompt"
        case musicCriteria = "music_criteria"
    }
}

struct MusicCriteria: Codable {
    let maxBpm: Int
    let energyLevel: String
    let lyrics: String

    enum CodingKeys: String, CodingKey {
        case maxBpm = "max_bpm"
        case energyLevel = "energy_level"
        case lyrics
    }
}
