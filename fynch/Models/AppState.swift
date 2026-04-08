import SwiftUI
import Observation

@Observable
final class AppState {
    var shows: [Show] = PersistenceService.loadShows()
    var watchedStates: [String: Bool] = PersistenceService.loadWatchedStates()
    var isAddingShow: Bool = false
    var isRefreshing: Bool = false

    // MARK: - Key

    static func watchKey(showId: String, season: Int, episode: Int) -> String {
        "\(showId)-S\(season)E\(episode)"
    }

    // MARK: - Air date

    private static let airDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f
    }()

    static func isAired(_ airDate: String?) -> Bool {
        guard let iso = airDate, !iso.isEmpty else { return true }
        guard let date = airDateFormatter.date(from: iso) else { return true }
        return date <= Date()
    }

    // MARK: - Queries

    func isWatched(showId: String, season: Int, episode: Int) -> Bool {
        watchedStates[AppState.watchKey(showId: showId, season: season, episode: episode)] ?? false
    }

    func nextEpisode(for show: Show) -> Episode? {
        for season in show.seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber }) {
            for episode in season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber }) {
                guard AppState.isAired(episode.airDate) else { continue }
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
                AppState.isAired($0.airDate) &&
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
        PersistenceService.saveWatchedStates(watchedStates)
    }

    func addShow(_ show: Show) {
        guard !shows.contains(where: { $0.id == show.id }) else { return }
        shows.append(show)
        PersistenceService.saveShows(shows)
    }

    func markSeasonWatched(showId: String, season: Season) {
        for episode in season.episodes {
            let key = AppState.watchKey(showId: showId, season: season.seasonNumber, episode: episode.episodeNumber)
            watchedStates[key] = true
        }
        PersistenceService.saveWatchedStates(watchedStates)
    }

    func markSeasonUnwatched(showId: String, season: Season) {
        for episode in season.episodes {
            let key = AppState.watchKey(showId: showId, season: season.seasonNumber, episode: episode.episodeNumber)
            watchedStates[key] = false
        }
        PersistenceService.saveWatchedStates(watchedStates)
    }

    func isSeasonWatched(showId: String, season: Season) -> Bool {
        season.episodes.allSatisfy {
            isWatched(showId: showId, season: season.seasonNumber, episode: $0.episodeNumber)
        }
    }

    func deleteShow(id: String) {
        shows.removeAll { $0.id == id }
        watchedStates = watchedStates.filter { !$0.key.hasPrefix(id + "-") }
        PersistenceService.saveShows(shows)
        PersistenceService.saveWatchedStates(watchedStates)
    }

    // MARK: - TMDB

    @MainActor
    func addShowFromTMDB(searchResult: TMDBSearchResult, service: TMDBService) async throws {
        isAddingShow = true
        defer { isAddingShow = false }
        let detail = try await service.fetchShowDetail(id: searchResult.id)
        let show = try await service.buildShow(from: detail)
        addShow(show)
    }

    // MARK: - Refresh

    @MainActor
    func refreshAllShows(service: TMDBService, refreshService: RefreshService, isManual: Bool) async {
        if isManual { isRefreshing = true }
        defer { if isManual { isRefreshing = false } }
        let result = await refreshService.refreshStaleShows(in: shows, tmdbService: service, force: isManual)
        applyRefreshResult(result)
    }

    @MainActor
    func applyRefreshResult(_ result: RefreshResult) {
        for updatedShow in result.updatedShows {
            if let idx = shows.firstIndex(where: { $0.id == updatedShow.id }) {
                shows[idx] = updatedShow
            }
        }
        if !result.updatedShows.isEmpty {
            PersistenceService.saveShows(shows)
        }
        // Future notification hook:
        // if result.totalNewEpisodes > 0 { scheduleNewEpisodeNotification(count: result.totalNewEpisodes) }
        #if DEBUG
        for (showId, error) in result.errors {
            print("[fynch] Refresh error for \(showId): \(error)")
        }
        #endif
    }
}
