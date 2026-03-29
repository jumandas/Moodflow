import Foundation

actor SpotifyWebAPIService {

    private var accessToken: String?

    func setAccessToken(_ token: String) {
        self.accessToken = token
    }

    // MARK: - User

    func getCurrentUserID() async throws -> String {
        struct UserProfile: Decodable { let id: String }
        let data = try await get(path: "/me")
        return try JSONDecoder().decode(UserProfile.self, from: data).id
    }

    // MARK: - Search

    func searchTrack(title: String, artist: String) async throws -> SpotifyTrack? {
        let query = "\(title) artist:\(artist)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let data = try await get(path: "/search?q=\(query)&type=track&limit=3&market=US")
        let result = try JSONDecoder().decode(SpotifyTrackResponse.self, from: data)
        return result.tracks.items.first
    }

    func findBestMatch(title: String, artist: String) async throws -> SpotifyTrack? {
        if let track = try await searchTrack(title: title, artist: artist) { return track }
        // Fallback: title only
        let query = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let data = try await get(path: "/search?q=\(query)&type=track&limit=1&market=US")
        let result = try JSONDecoder().decode(SpotifyTrackResponse.self, from: data)
        return result.tracks.items.first
    }

    // MARK: - Playlist creation

    func createJourneyPlaylist(journey: Journey) async throws -> String {
        let userID = try await getCurrentUserID()

        // Create playlist
        let playlistID = try await createPlaylist(
            userID: userID,
            name: "MoodFlow: \(journey.currentMood.displayName) → \(journey.desiredMood.displayName)",
            description: "AI-curated \(journey.durationMinutes)-min journey by MoodFlow"
        )

        // Collect all URIs in stage order
        let uris = journey.stages
            .flatMap { $0.songs }
            .compactMap { $0.spotifyURI }

        guard !uris.isEmpty else { throw AppError.noSongsFound }

        // Spotify accepts max 100 tracks per request
        for chunk in uris.chunked(into: 100) {
            try await addTracksToPlaylist(playlistID: playlistID, uris: chunk)
        }

        return "spotify:playlist:\(playlistID)"
    }

    private func createPlaylist(userID: String, name: String, description: String) async throws -> String {
        struct CreateBody: Encodable {
            let name: String
            let description: String
            let `public`: Bool
        }
        struct PlaylistResponse: Decodable { let id: String }

        let body = CreateBody(name: name, description: description, public: false)
        let data = try await post(path: "/users/\(userID)/playlists", body: body)
        return try JSONDecoder().decode(PlaylistResponse.self, from: data).id
    }

    private func addTracksToPlaylist(playlistID: String, uris: [String]) async throws {
        struct AddBody: Encodable { let uris: [String] }
        _ = try await post(path: "/playlists/\(playlistID)/tracks", body: AddBody(uris: uris))
    }

    // MARK: - Resolve Claude songs to Spotify tracks

    func resolveSpotifySongs(from claudeSongs: [ClaudeService.ClaudeSong]) async throws -> [Song] {
        var resolved: [Song] = []

        await withTaskGroup(of: (Int, Song?).self) { group in
            for (index, claudeSong) in claudeSongs.enumerated() {
                group.addTask {
                    do {
                        if let track = try await self.findBestMatch(
                            title: claudeSong.title,
                            artist: claudeSong.artist
                        ) {
                            return (index, Song(
                                title: track.name,
                                artist: track.primaryArtist,
                                spotifyURI: track.uri,
                                spotifyID: track.id,
                                albumArtURL: track.albumArtURL,
                                durationMs: track.durationMs,
                                estimatedBPM: claudeSong.estimatedBpm,
                                estimatedEnergy: claudeSong.estimatedEnergy,
                                reason: claudeSong.reason
                            ))
                        }
                    } catch {}
                    // Fallback without URI
                    return (index, Song(
                        title: claudeSong.title,
                        artist: claudeSong.artist,
                        estimatedBPM: claudeSong.estimatedBpm,
                        estimatedEnergy: claudeSong.estimatedEnergy,
                        reason: claudeSong.reason
                    ))
                }
            }
            var indexed: [(Int, Song)] = []
            for await (i, song) in group {
                if let song { indexed.append((i, song)) }
            }
            indexed.sort { $0.0 < $1.0 }
            resolved = indexed.map { $0.1 }
        }

        return resolved
    }

    // MARK: - HTTP helpers

    private func get(path: String) async throws -> Data {
        guard let token = accessToken else { throw AppError.authError("No access token") }
        guard let url = URL(string: Config.spotifyAPIBase + path) else {
            throw AppError.apiError("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    private func post<B: Encodable>(path: String, body: B) async throws -> Data {
        guard let token = accessToken else { throw AppError.authError("No access token") }
        guard let url = URL(string: Config.spotifyAPIBase + path) else {
            throw AppError.apiError("Invalid URL: \(path)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response, data: data)
        return data
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw AppError.apiError("Spotify API \(http.statusCode): \(body)")
        }
    }
}

// MARK: - Array chunking helper

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
