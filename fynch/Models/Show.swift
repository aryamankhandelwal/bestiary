import SwiftUI

struct Episode: Identifiable, Hashable, Codable {
    let id: String
    let seasonNumber: Int
    let episodeNumber: Int
    let title: String
    let airDate: String?  // ISO "yyyy-MM-dd", nil if unknown
}

struct Season: Identifiable, Hashable, Codable {
    let id: String
    let seasonNumber: Int
    let episodes: [Episode]
}

struct Show: Identifiable, Hashable {
    let id: String
    let tmdbId: Int
    let title: String
    let posterColor: Color
    let colorIndex: Int
    let genres: [String]
    let seasons: [Season]
    let tmdbStatus: String?     // "Returning Series", "Ended", "Canceled", etc.
    let lastRefreshedAt: Date?  // timestamp of last successful TMDB fetch

    static let palette: [Color] = [
        .red, .orange, .yellow, .green, .teal,
        .cyan, .blue, .indigo, .purple, .pink
    ]
}

extension Show {
    var isActivelyAiring: Bool {
        guard let status = tmdbStatus else { return true }  // unknown = assume active
        return !["Ended", "Canceled", "Cancelled"].contains(status)
    }

    var needsRefresh: Bool {
        guard isActivelyAiring else { return false }
        guard let last = lastRefreshedAt else { return true }
        return Date().timeIntervalSince(last) > 86_400  // 24 hours
    }
}

extension Show: Codable {
    enum CodingKeys: String, CodingKey {
        case id, tmdbId, title, colorIndex, genres, seasons, tmdbStatus, lastRefreshedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        tmdbId = try c.decode(Int.self, forKey: .tmdbId)
        title = try c.decode(String.self, forKey: .title)
        colorIndex = try c.decode(Int.self, forKey: .colorIndex)
        posterColor = Show.palette[colorIndex % Show.palette.count]
        genres = try c.decode([String].self, forKey: .genres)
        seasons = try c.decode([Season].self, forKey: .seasons)
        tmdbStatus = try c.decodeIfPresent(String.self, forKey: .tmdbStatus)
        lastRefreshedAt = try c.decodeIfPresent(Date.self, forKey: .lastRefreshedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(tmdbId, forKey: .tmdbId)
        try c.encode(title, forKey: .title)
        try c.encode(colorIndex, forKey: .colorIndex)
        try c.encode(genres, forKey: .genres)
        try c.encode(seasons, forKey: .seasons)
        try c.encodeIfPresent(tmdbStatus, forKey: .tmdbStatus)
        try c.encodeIfPresent(lastRefreshedAt, forKey: .lastRefreshedAt)
    }
}
