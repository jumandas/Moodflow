// MARK: - Fill in your credentials before building
enum Config {
    // Spotify Developer Dashboard → Your App → Settings
    static let spotifyClientID = "YOUR-KEY-HERE"
    // Spotify Redirect URI (must match exactly what you set in Spotify Dashboard)
    static let spotifyRedirectURI = "moodflow://spotify-callback"
    // Groq API key
    static let openAIAPIKey = "YOUR-KEY-HERE"

    // Spotify API endpoints
    static let spotifyAuthURL = "https://accounts.spotify.com/authorize"
    static let spotifyTokenURL = "https://accounts.spotify.com/api/token"
    static let spotifyAPIBase = "https://api.spotify.com/v1"

    // Groq API (OpenAI-compatible)
    static let openAIAPIURL = "https://api.groq.com/openai/v1/chat/completions"
    static let openAIModel = "llama-3.3-70b-versatile"

    // Spotify scopes required
    static let spotifyScopes = [
        "app-remote-control",
        "streaming",
        "user-read-playback-state",
        "user-modify-playback-state",
        "user-read-currently-playing",
        "playlist-modify-public",
        "playlist-modify-private",
        "user-library-read"
    ].joined(separator: " ")
}
