import Foundation

struct ShowRefreshOutcome {
    let updatedShow: Show
    let newEpisodeCount: Int
}

struct RefreshResult {
    let updatedShows: [Show]
    let totalNewEpisodes: Int
    let errors: [String: Error]  // showId → error, for silent logging
}

actor RefreshService {

    // MARK: - Public

    /// Refreshes all shows that need updating. Pass `force: true` to bypass the staleness check (manual pull-to-refresh).
    func refreshStaleShows(in shows: [Show], tmdbService: TMDBService, force: Bool = false) async -> RefreshResult {
        let eligible = force
            ? shows.filter(\.isActivelyAiring)
            : shows.filter(\.needsRefresh)

        guard !eligible.isEmpty else {
            return RefreshResult(updatedShows: [], totalNewEpisodes: 0, errors: [:])
        }

        let prioritized = sortByPriority(eligible)

        var updatedShows: [Show] = []
        var totalNew = 0
        var errors: [String: Error] = [:]

        await withTaskGroup(of: (String, Result<ShowRefreshOutcome, Error>).self) { group in
            for show in prioritized {
                group.addTask {
                    do {
                        let outcome = try await self.refreshShow(show, tmdbService: tmdbService)
                        return (show.id, .success(outcome))
                    } catch {
                        return (show.id, .failure(error))
                    }
                }
            }
            for await (showId, result) in group {
                switch result {
                case .success(let outcome):
                    updatedShows.append(outcome.updatedShow)
                    totalNew += outcome.newEpisodeCount
                case .failure(let error):
                    errors[showId] = error
                }
            }
        }

        return RefreshResult(updatedShows: updatedShows, totalNewEpisodes: totalNew, errors: errors)
    }

    /// Refreshes a single show, merging any new episodes into existing season data.
    func refreshShow(_ show: Show, tmdbService: TMDBService) async throws -> ShowRefreshOutcome {
        let detail = try await tmdbService.fetchShowDetail(id: show.tmdbId)

        // Determine which seasons to fetch
        let existingSeasonNumbers = Set(show.seasons.map(\.seasonNumber))
        let latestExistingSeasonNumber = show.seasons.map(\.seasonNumber).max()

        var seasonsToFetch = Set<Int>()
        // Any seasons TMDB has that we don't
        let totalSeasons = max(1, detail.numberOfSeasons)
        for n in 1...totalSeasons {
            if !existingSeasonNumbers.contains(n) {
                seasonsToFetch.insert(n)
            }
        }
        // Always re-fetch the most recent season we have (catches mid-season additions)
        if let latest = latestExistingSeasonNumber {
            seasonsToFetch.insert(latest)
        }

        guard !seasonsToFetch.isEmpty else {
            // Nothing to fetch — just update status/timestamp
            let refreshed = Show(
                id: show.id, tmdbId: show.tmdbId, title: show.title,
                posterColor: show.posterColor, colorIndex: show.colorIndex,
                genres: show.genres, seasons: show.seasons,
                tmdbStatus: detail.status, lastRefreshedAt: Date()
            )
            return ShowRefreshOutcome(updatedShow: refreshed, newEpisodeCount: 0)
        }

        // Fetch determined seasons concurrently
        var fetchedSeasons: [Int: TMDBSeasonDetail] = [:]
        try await withThrowingTaskGroup(of: (Int, TMDBSeasonDetail).self) { group in
            for n in seasonsToFetch {
                group.addTask {
                    let seasonData = try await tmdbService.fetchSeason(showId: show.tmdbId, seasonNumber: n)
                    return (n, seasonData)
                }
            }
            for try await (n, seasonData) in group {
                fetchedSeasons[n] = seasonData
            }
        }

        // Merge seasons
        var mergedSeasons = show.seasons
        var newEpisodeCount = 0

        for (n, seasonData) in fetchedSeasons {
            guard seasonData.seasonNumber > 0 else { continue }

            let isNewSeason = !existingSeasonNumbers.contains(n)

            if isNewSeason {
                // Brand new season — add all episodes
                let episodes = seasonData.episodes.map { ep in
                    Episode(
                        id: "tmdb-\(show.tmdbId)-s\(n)e\(ep.episodeNumber)",
                        seasonNumber: n,
                        episodeNumber: ep.episodeNumber,
                        title: ep.name,
                        airDate: ep.airDate
                    )
                }.sorted { $0.episodeNumber < $1.episodeNumber }

                mergedSeasons.append(Season(
                    id: "tmdb-\(show.tmdbId)-s\(n)",
                    seasonNumber: n,
                    episodes: episodes
                ))
                newEpisodeCount += episodes.count
            } else {
                // Existing season — merge episode by episode
                guard let existingIdx = mergedSeasons.firstIndex(where: { $0.seasonNumber == n }) else { continue }
                let existingSeason = mergedSeasons[existingIdx]
                var episodesByNumber = Dictionary(
                    uniqueKeysWithValues: existingSeason.episodes.map { ($0.episodeNumber, $0) }
                )

                for ep in seasonData.episodes {
                    let id = "tmdb-\(show.tmdbId)-s\(n)e\(ep.episodeNumber)"
                    if episodesByNumber[ep.episodeNumber] == nil {
                        // New episode within existing season
                        episodesByNumber[ep.episodeNumber] = Episode(
                            id: id,
                            seasonNumber: n,
                            episodeNumber: ep.episodeNumber,
                            title: ep.name,
                            airDate: ep.airDate
                        )
                        newEpisodeCount += 1
                    } else {
                        // Update title and airDate in case TMDB corrected them
                        episodesByNumber[ep.episodeNumber] = Episode(
                            id: id,
                            seasonNumber: n,
                            episodeNumber: ep.episodeNumber,
                            title: ep.name,
                            airDate: ep.airDate
                        )
                    }
                }

                let mergedEpisodes = episodesByNumber.values.sorted { $0.episodeNumber < $1.episodeNumber }
                mergedSeasons[existingIdx] = Season(
                    id: existingSeason.id,
                    seasonNumber: n,
                    episodes: mergedEpisodes
                )
            }
        }

        let updatedShow = Show(
            id: show.id,
            tmdbId: show.tmdbId,
            title: show.title,
            posterColor: show.posterColor,
            colorIndex: show.colorIndex,
            genres: show.genres,
            seasons: mergedSeasons.sorted { $0.seasonNumber < $1.seasonNumber },
            tmdbStatus: detail.status,
            lastRefreshedAt: Date()
        )

        return ShowRefreshOutcome(updatedShow: updatedShow, newEpisodeCount: newEpisodeCount)
    }

    // MARK: - Private

    /// Shows with recent or upcoming air dates are fetched first.
    private func sortByPriority(_ shows: [Show]) -> [Show] {
        let sixtyDaysAgo = Date(timeIntervalSinceNow: -60 * 86_400)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")

        func hasRecentActivity(_ show: Show) -> Bool {
            show.seasons.contains { season in
                season.episodes.contains { ep in
                    guard let iso = ep.airDate, let date = formatter.date(from: iso) else { return false }
                    return date >= sixtyDaysAgo
                }
            }
        }
        return shows.sorted { hasRecentActivity($0) && !hasRecentActivity($1) }
    }
}
