import Foundation

enum JSONParser {
    static func parseJourneyStages(from data: Data) throws -> [JourneyStage] {
        // Extract the text content from Claude's response envelope
        let response = try JSONDecoder().decode(ClaudeResponse.self, from: data)
        guard let text = response.content.first?.text,
              let jsonData = text.data(using: .utf8) else {
            throw ParsingError.noContent
        }
        return try JSONDecoder().decode([JourneyStage].self, from: jsonData)
    }
}

// Claude API response envelope
struct ClaudeResponse: Codable {
    let content: [ContentBlock]
}
struct ContentBlock: Codable {
    let text: String
}

enum ParsingError: Error {
    case noContent
    case invalidJSON
}
