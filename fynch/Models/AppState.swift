import SwiftUI
import Observation

@Observable
final class AppState {
    var shows: [Show] = AppState.makeSampleShows()
    var watchedStates: [String: Bool] = AppState.makeSampleWatchedStates()

    // MARK: - Key

    static func watchKey(showId: String, season: Int, episode: Int) -> String {
        "\(showId)-S\(season)E\(episode)"
    }

    // MARK: - Queries

    func isWatched(showId: String, season: Int, episode: Int) -> Bool {
        watchedStates[AppState.watchKey(showId: showId, season: season, episode: episode)] ?? false
    }

    func nextEpisode(for show: Show) -> Episode? {
        for season in show.seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber }) {
            for episode in season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber }) {
                if !isWatched(showId: show.id, season: season.seasonNumber, episode: episode.episodeNumber) {
                    return episode
                }
            }
        }
        return nil
    }

    func isCompleted(_ show: Show) -> Bool {
        nextEpisode(for: show) == nil
    }

    func episodesRemaining(for show: Show) -> Int {
        show.seasons.reduce(0) { total, season in
            total + season.episodes.filter {
                !isWatched(showId: show.id, season: season.seasonNumber, episode: $0.episodeNumber)
            }.count
        }
    }

    func statusLabel(for show: Show) -> String {
        let remaining = episodesRemaining(for: show)
        switch remaining {
        case 0: return "Caught up"
        case 1: return "1 new episode"
        default: return "\(remaining) new episodes"
        }
    }

    // MARK: - Mutations

    func toggleWatched(showId: String, season: Int, episode: Int) {
        let key = AppState.watchKey(showId: showId, season: season, episode: episode)
        watchedStates[key] = !(watchedStates[key] ?? false)
    }

    func addShow(_ show: Show) {
        guard !shows.contains(where: { $0.id == show.id }) else { return }
        shows.append(show)
    }

    func deleteShow(id: String) {
        shows.removeAll { $0.id == id }
        watchedStates = watchedStates.filter { !$0.key.hasPrefix(id + "-") }
    }

    // MARK: - Catalog (all known shows, superset of tracked list)

    static let catalog: [Show] = makeCatalog()

    // MARK: - Sample Data

    private static func makeSampleShows() -> [Show] {
        // Start with 4 shows already being tracked
        return [
            show(id: "breaking-bad"),
            show(id: "severance"),
            show(id: "the-bear"),
            show(id: "succession")
        ].compactMap { $0 }
    }

    private static func makeSampleWatchedStates() -> [String: Bool] {
        var states: [String: Bool] = [:]

        // Breaking Bad: fully watched (all caught up)
        for ep in 1...8 { states[watchKey(showId: "breaking-bad", season: 1, episode: ep)] = true }
        for ep in 1...8 { states[watchKey(showId: "breaking-bad", season: 2, episode: ep)] = true }

        // Severance: S1 fully done, S2 not started
        for ep in 1...9 { states[watchKey(showId: "severance", season: 1, episode: ep)] = true }

        // The Bear: nothing watched

        // Succession: S1E1–E6 done
        for ep in 1...6 { states[watchKey(showId: "succession", season: 1, episode: ep)] = true }

        return states
    }

    private static func makeCatalog() -> [Show] {
        [
            Show(
                id: "breaking-bad",
                title: "Breaking Bad",
                posterColor: .orange,
                genres: ["Drama", "Thriller"],
                seasons: [
                    Season(id: "bb-s1", seasonNumber: 1, episodes: breakingBadS1()),
                    Season(id: "bb-s2", seasonNumber: 2, episodes: breakingBadS2())
                ]
            ),
            Show(
                id: "severance",
                title: "Severance",
                posterColor: .indigo,
                genres: ["Sci-Fi", "Thriller"],
                seasons: [
                    Season(id: "sv-s1", seasonNumber: 1, episodes: severanceS1()),
                    Season(id: "sv-s2", seasonNumber: 2, episodes: severanceS2())
                ]
            ),
            Show(
                id: "the-bear",
                title: "The Bear",
                posterColor: .red,
                genres: ["Drama", "Comedy"],
                seasons: [
                    Season(id: "tb-s1", seasonNumber: 1, episodes: theBearS1()),
                    Season(id: "tb-s2", seasonNumber: 2, episodes: theBearS2())
                ]
            ),
            Show(
                id: "succession",
                title: "Succession",
                posterColor: .brown,
                genres: ["Drama"],
                seasons: [
                    Season(id: "sc-s1", seasonNumber: 1, episodes: successionS1()),
                    Season(id: "sc-s2", seasonNumber: 2, episodes: successionS2())
                ]
            ),
            Show(
                id: "white-lotus",
                title: "The White Lotus",
                posterColor: .teal,
                genres: ["Drama", "Mystery"],
                seasons: [
                    Season(id: "wl-s1", seasonNumber: 1, episodes: episodes(showId: "white-lotus", season: 1, count: 6, titles: [
                        "Arrivals", "New Day", "Mysterious Monkeys", "Recentering", "The Lotus-Eaters", "Departures"
                    ])),
                    Season(id: "wl-s2", seasonNumber: 2, episodes: episodes(showId: "white-lotus", season: 2, count: 7, titles: [
                        "Ciao", "Italian Dream", "Bull Elephants", "In the Sandbox",
                        "That's Amore", "Abductions", "Arrivederci"
                    ]))
                ]
            ),
            Show(
                id: "andor",
                title: "Andor",
                posterColor: .cyan,
                genres: ["Sci-Fi", "Action"],
                seasons: [
                    Season(id: "an-s1", seasonNumber: 1, episodes: episodes(showId: "andor", season: 1, count: 12, titles: [
                        "Kassa", "That Would Be Me", "Reckoning", "Aldhani",
                        "The Axe Forgets", "The Eye", "Announcement",
                        "Narkina 5", "Nobody's Listening!", "One Way Out",
                        "Daughter of Ferrix", "Rix Road"
                    ])),
                    Season(id: "an-s2", seasonNumber: 2, episodes: episodes(showId: "andor", season: 2, count: 12,
                        titles: (1...12).map { "Episode \($0)" }))
                ]
            )
        ]
    }

    private static func show(id: String) -> Show? {
        catalog.first { $0.id == id }
    }

    // MARK: - Episode Data

    private static func breakingBadS1() -> [Episode] {
        episodes(showId: "breaking-bad", season: 1, count: 8, titles: [
            "Pilot", "Cat's in the Bag", "...And the Bag's in the River",
            "Cancer Man", "Gray Matter", "Crazy Handful of Nothin'",
            "A No-Rough-Stuff-Type Deal", "Grilled"
        ])
    }

    private static func breakingBadS2() -> [Episode] {
        episodes(showId: "breaking-bad", season: 2, count: 8, titles: [
            "Seven Thirty-Seven", "Down", "Bit by a Dead Bee",
            "Down", "Breakage", "Peekaboo",
            "Negro y Azul", "Better Call Saul"
        ])
    }

    private static func severanceS1() -> [Episode] {
        episodes(showId: "severance", season: 1, count: 9, titles: [
            "Good News About Hell", "Half Loop", "In Perpetuity",
            "The You You Are", "The Grim Barbarity of Optics and Design",
            "Hide and Seek", "Defiant Jazz", "What's for Dinner?", "The We We Are"
        ])
    }

    private static func severanceS2() -> [Episode] {
        episodes(showId: "severance", season: 2, count: 9, titles: [
            "Hello, Ms. Cobel", "Goodbye, Mrs. Selvig", "Who Is Alive?",
            "Woe's Hollow", "Trojan's Horse", "Attila",
            "Chikhai Bardo", "The After Hours", "The Gimmick"
        ])
    }

    private static func theBearS1() -> [Episode] {
        episodes(showId: "the-bear", season: 1, count: 8, titles: [
            "System", "Hands", "Brigade",
            "Dogs", "Sheridan", "Ceres",
            "Review", "Braciole"
        ])
    }

    private static func theBearS2() -> [Episode] {
        episodes(showId: "the-bear", season: 2, count: 10, titles: [
            "Beef", "Pasta", "Sundae",
            "Honeydew", "Forks", "Fishes",
            "Bolognese", "Bolognese #2", "Napkins", "The Bear"
        ])
    }

    private static func successionS1() -> [Episode] {
        episodes(showId: "succession", season: 1, count: 10, titles: [
            "Celebration", "Shit Show at the Fuck Factory", "Lifeboats",
            "Sad Sack Wasp Trap", "I Went to Market", "Which Side Are You On?",
            "Austerlitz", "Prague", "Pre-Nuptial", "Nobody Is Ever Missing"
        ])
    }

    private static func successionS2() -> [Episode] {
        episodes(showId: "succession", season: 2, count: 10, titles: [
            "The Summer Palace", "Vaulter", "Hunting",
            "Safe Room", "Tern Haven", "Argestes",
            "DC", "Corporate Raider", "D.C.", "This Is Not for Tears"
        ])
    }

    // MARK: - Helper

    private static func episodes(showId: String, season: Int, count: Int, titles: [String]) -> [Episode] {
        (1...count).map { ep in
            Episode(
                id: "\(showId)-s\(season)e\(ep)",
                seasonNumber: season,
                episodeNumber: ep,
                title: titles.indices.contains(ep - 1) ? titles[ep - 1] : "Episode \(ep)"
            )
        }
    }
}
