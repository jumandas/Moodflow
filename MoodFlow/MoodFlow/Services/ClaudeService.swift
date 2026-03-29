import Foundation

actor ClaudeService {

    // MARK: - OpenAI API types

    private struct OpenAIRequest: Encodable {
        let model: String
        let messages: [OpenAIMessage]
        let temperature: Double
        let maxTokens: Int
        let responseFormat: ResponseFormat

        enum CodingKeys: String, CodingKey {
            case model, messages, temperature
            case maxTokens = "max_tokens"
            case responseFormat = "response_format"
        }
    }

    private struct OpenAIMessage: Encodable {
        let role: String
        let content: String
    }

    private struct ResponseFormat: Encodable {
        let type: String
    }

    private struct OpenAIResponse: Decodable {
        let choices: [OpenAIChoice]
    }

    private struct OpenAIChoice: Decodable {
        let message: OpenAIResponseMessage
    }

    private struct OpenAIResponseMessage: Decodable {
        let content: String
    }

    // MARK: - Journey JSON schema

    struct ClaudeJourneyResponse: Decodable {
        let stages: [ClaudeStage]
    }

    struct ClaudeStage: Decodable {
        let name: String
        let description: String
        let order: Int
        let targetBpmMin: Int
        let targetBpmMax: Int
        let targetEnergy: Double
        let targetValence: Double
        let songs: [ClaudeSong]

        enum CodingKeys: String, CodingKey {
            case name, description, order, songs
            case targetBpmMin = "target_bpm_min"
            case targetBpmMax = "target_bpm_max"
            case targetEnergy = "target_energy"
            case targetValence = "target_valence"
        }
    }

    struct ClaudeSong: Decodable {
        let title: String
        let artist: String
        let estimatedBpm: Int
        let estimatedEnergy: Double
        let reason: String

        enum CodingKeys: String, CodingKey {
            case title, artist, reason
            case estimatedBpm = "estimated_bpm"
            case estimatedEnergy = "estimated_energy"
        }
    }

    // MARK: - System prompt

    private let systemPrompt = """
    You are a music therapist and expert DJ specializing in emotional regulation through music. You have deep knowledge of how music's tempo (BPM), energy, and valence (emotional positivity) affect human emotions and mood states.

    Your task is to create personalized music journeys that gradually guide people from one emotional state to another through carefully curated, real songs available on Spotify.

    CRITICAL RULES:
    - Only suggest real, well-known songs that actually exist and are available on Spotify
    - The song progression must feel natural and gradual — never a jarring jump
    - Stage 1 meets the user where they are emotionally
    - Each subsequent stage moves incrementally toward the goal
    - Stage 4 fully embodies the desired mood
    - Consider BPM, energy, and emotional tone of each song carefully
    - Songs should be mainstream enough to be on Spotify
    - Always respond with valid JSON only — no explanation, no markdown, no code blocks

    JSON format:
    {
      "stages": [
        {
          "name": "Stage Name",
          "description": "What emotional work this stage does and why these songs",
          "order": 1,
          "target_bpm_min": 70,
          "target_bpm_max": 90,
          "target_energy": 0.3,
          "target_valence": 0.4,
          "songs": [
            {
              "title": "Song Title",
              "artist": "Artist Name",
              "estimated_bpm": 82,
              "estimated_energy": 0.35,
              "reason": "Brief reason why this song fits this stage"
            }
          ]
        }
      ]
    }
    """

    // MARK: - Public API

    func generateJourney(
        currentMood: Mood,
        desiredMood: Mood,
        durationMinutes: Int,
        biometricContext: String? = nil
    ) async throws -> ClaudeJourneyResponse {
        let songsPerStage = max(3, (durationMinutes * 60) / (4 * 200))
        var prompt = """
        Create a 4-stage music journey to guide someone emotionally:

        Current mood: \(currentMood.displayName)
        Description: \(currentMood.description)
        Current mood energy level: \(String(format: "%.1f", currentMood.energy)) (0=very calm, 1=very intense)
        Current mood positivity: \(String(format: "%.1f", currentMood.valence)) (0=very negative, 1=very positive)

        Desired mood: \(desiredMood.displayName)
        Description: \(desiredMood.description)
        Desired mood energy level: \(String(format: "%.1f", desiredMood.energy))
        Desired mood positivity: \(String(format: "%.1f", desiredMood.valence))

        Total journey duration: \(durationMinutes) minutes
        Provide \(songsPerStage) to \(songsPerStage + 2) songs per stage.

        Design 4 progressive stages. Stage 1 should match the current mood closely, then gradually move toward the desired mood by stage 4.
        """

        if let bio = biometricContext {
            prompt += "\n\nUser biometric data: \(bio)\nUse this physiological data to better calibrate BPM and energy of songs to the user's current body state."
        }

        return try await callOpenAI(prompt: prompt)
    }

    func recurateSongs(
        journey: Journey,
        currentStageIndex: Int,
        feedback: String
    ) async throws -> ClaudeJourneyResponse {
        let remainingMinutes = max(5, journey.durationMinutes - Int(journey.elapsedTime / 60))
        let prompt = """
        A user's music journey isn't working. Re-curate the remaining stages.

        Original journey:
        - From: \(journey.currentMood.displayName)
        - To: \(journey.desiredMood.displayName)
        - Total duration: \(journey.durationMinutes) minutes

        Current stage: \(currentStageIndex + 1) of 4
        Time remaining: ~\(remainingMinutes) minutes
        User feedback: "\(feedback)"

        Re-curate all 4 stages with better song choices. Focus on songs that more effectively transition to \(journey.desiredMood.displayName).
        """

        return try await callOpenAI(prompt: prompt)
    }

    // MARK: - Private

    private func callOpenAI(prompt: String) async throws -> ClaudeJourneyResponse {
        guard !Config.openAIAPIKey.hasPrefix("YOUR_") else {
            throw AppError.missingAPIKey("OpenAI API key not configured in Config.swift")
        }

        var request = URLRequest(url: URL(string: Config.openAIAPIURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let body = OpenAIRequest(
            model: Config.openAIModel,
            messages: [
                OpenAIMessage(role: "system", content: systemPrompt),
                OpenAIMessage(role: "user", content: prompt)
            ],
            temperature: 0.7,
            maxTokens: 4096,
            responseFormat: ResponseFormat(type: "json_object")
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            throw AppError.apiError("OpenAI API error \(statusCode): \(errorBody)")
        }

        let openAIResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)

        guard let text = openAIResponse.choices.first?.message.content else {
            throw AppError.parseError("No content in OpenAI response")
        }

        let jsonString = extractJSON(from: text)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw AppError.parseError("Could not convert response to data")
        }

        return try JSONDecoder().decode(ClaudeJourneyResponse.self, from: jsonData)
    }

    private func extractJSON(from text: String) -> String {
        if let start = text.range(of: "```json\n"),
           let end = text.range(of: "\n```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound])
        }
        if let start = text.range(of: "```\n"),
           let end = text.range(of: "\n```", range: start.upperBound..<text.endIndex) {
            return String(text[start.upperBound..<end.lowerBound])
        }
        if let start = text.firstIndex(of: "{"),
           let end = text.lastIndex(of: "}") {
            return String(text[start...end])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
