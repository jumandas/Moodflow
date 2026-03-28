import Foundation

enum FallbackData {
    static func journey(for emotion: Emotion, goal: Goal) -> [JourneyStage] {
        return [
            JourneyStage(
                stageName: "validate",
                durationMinutes: 3,
                targetArousal: 0.75,
                microPrompt: "Name what you're feeling without judging it.",
                musicCriteria: MusicCriteria(maxBpm: 90, energyLevel: "mid", lyrics: "low")
            ),
            JourneyStage(
                stageName: "regulate",
                durationMinutes: 4,
                targetArousal: 0.45,
                microPrompt: "Breathe out longer than you breathe in.",
                musicCriteria: MusicCriteria(maxBpm: 70, energyLevel: "low", lyrics: "none")
            ),
            JourneyStage(
                stageName: "stabilize",
                durationMinutes: 3,
                targetArousal: 0.30,
                microPrompt: "Feel your feet on the floor. You're here.",
                musicCriteria: MusicCriteria(maxBpm: 75, energyLevel: "low", lyrics: "none")
            ),
            JourneyStage(
                stageName: "activate",
                durationMinutes: 2,
                targetArousal: 0.50,
                microPrompt: "What's the one smallest thing you can do right now?",
                musicCriteria: MusicCriteria(maxBpm: 95, energyLevel: "mid", lyrics: "low")
            )
        ]
    }
}
