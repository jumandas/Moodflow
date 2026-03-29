import Foundation

struct Song: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var artist: String
    var spotifyURI: String?
    var spotifyID: String?
    var albumArtURL: String?
    var durationMs: Int?
    var estimatedBPM: Int?
    var estimatedEnergy: Double?
    var estimatedValence: Double?
    var reason: String

    var durationSeconds: Double {
        Double(durationMs ?? 200000) / 1000.0
    }

    var durationFormatted: String {
        let total = Int(durationSeconds)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        spotifyURI: String? = nil,
        spotifyID: String? = nil,
        albumArtURL: String? = nil,
        durationMs: Int? = nil,
        estimatedBPM: Int? = nil,
        estimatedEnergy: Double? = nil,
        estimatedValence: Double? = nil,
        reason: String = ""
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.spotifyURI = spotifyURI
        self.spotifyID = spotifyID
        self.albumArtURL = albumArtURL
        self.durationMs = durationMs
        self.estimatedBPM = estimatedBPM
        self.estimatedEnergy = estimatedEnergy
        self.estimatedValence = estimatedValence
        self.reason = reason
    }
}

// Spotify Web API track response
struct SpotifyTrackResponse: Codable {
    let tracks: SpotifyTracksPage
}

struct SpotifyTracksPage: Codable {
    let items: [SpotifyTrack]
}

struct SpotifyTrack: Codable {
    let id: String
    let name: String
    let uri: String
    let durationMs: Int
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum

    enum CodingKeys: String, CodingKey {
        case id, name, uri, artists, album
        case durationMs = "duration_ms"
    }

    var primaryArtist: String {
        artists.first?.name ?? "Unknown"
    }

    var albumArtURL: String? {
        album.images.first?.url
    }
}

struct SpotifyArtist: Codable {
    let id: String
    let name: String
}

struct SpotifyAlbum: Codable {
    let id: String
    let name: String
    let images: [SpotifyImage]
}

struct SpotifyImage: Codable {
    let url: String
    let width: Int?
    let height: Int?
}
