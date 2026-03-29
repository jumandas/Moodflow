import Foundation

enum AppError: LocalizedError {
    case authError(String)
    case apiError(String)
    case parseError(String)
    case playbackError(String)
    case missingAPIKey(String)
    case spotifyNotInstalled
    case noSongsFound

    var errorDescription: String? {
        switch self {
        case .authError(let msg): return "Auth Error: \(msg)"
        case .apiError(let msg): return "API Error: \(msg)"
        case .parseError(let msg): return "Parse Error: \(msg)"
        case .playbackError(let msg): return "Playback Error: \(msg)"
        case .missingAPIKey(let msg): return "Missing API Key: \(msg)"
        case .spotifyNotInstalled: return "Spotify app is not installed. Please install Spotify to use MoodFlow."
        case .noSongsFound: return "Could not find songs on Spotify. Please check your connection."
        }
    }
}
