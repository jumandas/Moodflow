import SwiftUI

enum Mood: String, CaseIterable, Codable, Identifiable {
    case anxious
    case stressed
    case sad
    case angry
    case overwhelmed
    case neutral
    case content
    case calm
    case happy
    case energized
    case focused
    case euphoric

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anxious: return "Anxious"
        case .stressed: return "Stressed"
        case .sad: return "Sad"
        case .angry: return "Angry"
        case .overwhelmed: return "Overwhelmed"
        case .neutral: return "Neutral"
        case .content: return "Content"
        case .calm: return "Calm"
        case .happy: return "Happy"
        case .energized: return "Energized"
        case .focused: return "Focused"
        case .euphoric: return "Euphoric"
        }
    }

    var emoji: String {
        switch self {
        case .anxious: return "😰"
        case .stressed: return "😤"
        case .sad: return "😢"
        case .angry: return "😠"
        case .overwhelmed: return "😵"
        case .neutral: return "😐"
        case .content: return "🙂"
        case .calm: return "😌"
        case .happy: return "😊"
        case .energized: return "⚡️"
        case .focused: return "🎯"
        case .euphoric: return "🌟"
        }
    }

    var color: Color {
        switch self {
        case .anxious: return Color(red: 1.0, green: 0.6, blue: 0.2)
        case .stressed: return Color(red: 1.0, green: 0.4, blue: 0.3)
        case .sad: return Color(red: 0.4, green: 0.6, blue: 1.0)
        case .angry: return Color(red: 0.9, green: 0.2, blue: 0.2)
        case .overwhelmed: return Color(red: 0.7, green: 0.3, blue: 0.9)
        case .neutral: return Color(red: 0.7, green: 0.7, blue: 0.7)
        case .content: return Color(red: 0.4, green: 0.8, blue: 0.6)
        case .calm: return Color(red: 0.3, green: 0.8, blue: 0.9)
        case .happy: return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .energized: return Color(red: 1.0, green: 0.6, blue: 0.1)
        case .focused: return Color(red: 0.3, green: 0.6, blue: 1.0)
        case .euphoric: return Color(red: 0.9, green: 0.4, blue: 0.9)
        }
    }

    var gradientColors: [Color] {
        [color, color.opacity(0.5)]
    }

    var description: String {
        switch self {
        case .anxious: return "Racing thoughts, restlessness, worry"
        case .stressed: return "Tension, pressure, feeling overwhelmed by tasks"
        case .sad: return "Low energy, melancholy, down"
        case .angry: return "Frustrated, irritated, tense"
        case .overwhelmed: return "Too much at once, scattered, lost"
        case .neutral: return "Neither good nor bad, baseline"
        case .content: return "Satisfied, at ease, comfortable"
        case .calm: return "Peaceful, relaxed, serene"
        case .happy: return "Joyful, positive, light-hearted"
        case .energized: return "Lively, motivated, ready to go"
        case .focused: return "Sharp, clear-minded, in flow"
        case .euphoric: return "Elated, blissful, on top of the world"
        }
    }

    // Approximate audio valence (positivity): 0.0 = very negative, 1.0 = very positive
    var valence: Double {
        switch self {
        case .anxious: return 0.2
        case .stressed: return 0.2
        case .sad: return 0.1
        case .angry: return 0.15
        case .overwhelmed: return 0.2
        case .neutral: return 0.5
        case .content: return 0.65
        case .calm: return 0.6
        case .happy: return 0.8
        case .energized: return 0.75
        case .focused: return 0.6
        case .euphoric: return 0.95
        }
    }

    // Approximate energy level: 0.0 = very low, 1.0 = very high
    var energy: Double {
        switch self {
        case .anxious: return 0.7
        case .stressed: return 0.75
        case .sad: return 0.2
        case .angry: return 0.85
        case .overwhelmed: return 0.65
        case .neutral: return 0.45
        case .content: return 0.4
        case .calm: return 0.2
        case .happy: return 0.65
        case .energized: return 0.9
        case .focused: return 0.55
        case .euphoric: return 0.85
        }
    }

    /// Infer the most likely mood by blending self-reported emotion with biometric signals.
    static func inferMood(selfReported: Mood, biometrics: BiometricInput) -> Mood {
        guard biometrics.hasAnyInput else { return selfReported }

        let bioEnergy = biometrics.energyLevel
        let bioStress = biometrics.stressLevel

        // Blend: 60% self-report, 40% biometrics
        let targetEnergy = selfReported.energy * 0.6 + bioEnergy * 0.4
        let stressAdjustedValence = max(0, 1.0 - bioStress)
        let targetValence = selfReported.valence * 0.6 + stressAdjustedValence * 0.4

        // Find mood whose energy+valence profile best matches
        var bestMood = selfReported
        var bestScore = Double.greatestFiniteMagnitude

        for mood in Mood.allCases {
            let score = abs(mood.energy - targetEnergy) + abs(mood.valence - targetValence)
            if score < bestScore {
                bestScore = score
                bestMood = mood
            }
        }
        return bestMood
    }
}
