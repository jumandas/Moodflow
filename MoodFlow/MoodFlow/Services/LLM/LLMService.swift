import Foundation

class LLMService {
    static let shared = LLMService()
    private let apiURL = "https://api.anthropic.com/v1/messages"

    func generateJourney(emotion: Emotion, goal: Goal, duration: Int) async throws -> [JourneyStage] {
        let prompt = PromptBuilder.build(emotion: emotion, goal: goal, duration: duration)

        var request = URLRequest(url: URL(string: apiURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(APIKeys.claude, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1000,
            "messages": [["role": "user", "content": prompt]]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONParser.parseJourneyStages(from: data)
    }
}
