import Foundation
import Combine

@MainActor
class JourneyViewModel: ObservableObject {
    @Published var stages: [JourneyStage] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var journeyReady = false

    func buildJourney(emotion: Emotion, goal: Goal, duration: Int) async {
        isLoading = true
        errorMessage = nil

        do {
            stages = try await LLMService.shared.generateJourney(
                emotion: emotion,
                goal: goal,
                duration: duration
            )
            journeyReady = true
        } catch {
            // Fall back to mock data if API fails
            stages = FallbackData.journey(for: emotion, goal: goal)
            journeyReady = true
            errorMessage = "Using offline plan"
        }

        isLoading = false
    }
}
