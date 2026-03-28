import Foundation

enum Emotion: String, CaseIterable, Identifiable {
    case anxious, sad, scattered, lowEnergy = "low-energy"
    var id: String { rawValue }
    var label: String {
        switch self {
        case .anxious: return "Anxious"
        case .sad: return "Sad"
        case .scattered: return "Scattered"
        case .lowEnergy: return "Low Energy"
        }
    }
    var emoji: String {
        switch self {
        case .anxious: return "😰"
        case .sad: return "😔"
        case .scattered: return "🌀"
        case .lowEnergy: return "🪫"
        }
    }
}

enum Goal: String, CaseIterable, Identifiable {
    case focus, calm, energize, process
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var emoji: String {
        switch self {
        case .focus: return "🎯"
        case .calm: return "🌊"
        case .energize: return "⚡️"
        case .process: return "💭"
        }
    }
}
