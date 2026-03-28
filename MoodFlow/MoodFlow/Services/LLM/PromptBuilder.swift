import Foundation

enum PromptBuilder {
    static func build(emotion: Emotion, goal: Goal, duration: Int) -> String {
        """
        You are an emotion regulation assistant.
        A user is feeling \(emotion.rawValue) and wants to \(goal.rawValue) in \(duration) minutes.

        Generate a regulation journey with exactly 4 stages.
        For each stage return:
        - stage_name: one word (validate / regulate / stabilize / activate)
        - duration_minutes: number
        - target_arousal: 0.0–1.0
        - micro_prompt: one short sentence under 12 words, non-clinical
        - music_criteria: { max_bpm, energy_level (low/mid/high), lyrics (none/low/ok) }

        Return ONLY valid JSON array. No explanation. No markdown.
        """
    }
}
