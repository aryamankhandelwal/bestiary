import SwiftUI

struct Episode: Identifiable, Hashable {
    let id: String
    let seasonNumber: Int
    let episodeNumber: Int
    let title: String
}

struct Season: Identifiable, Hashable {
    let id: String
    let seasonNumber: Int
    let episodes: [Episode]
}

struct Show: Identifiable, Hashable {
    let id: String
    let title: String
    let posterColor: Color
    let genres: [String]
    let seasons: [Season]
}
