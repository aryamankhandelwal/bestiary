import SwiftUI

struct ShowDetailView: View {
    let show: Show
    @Environment(AppState.self) private var appState

    var body: some View {
        List {
            ForEach(show.seasons.sorted(by: { $0.seasonNumber < $1.seasonNumber })) { season in
                Section("Season \(season.seasonNumber)") {
                    ForEach(season.episodes.sorted(by: { $0.episodeNumber < $1.episodeNumber })) { episode in
                        EpisodeRowView(
                            episode: episode,
                            isWatched: appState.isWatched(
                                showId: show.id,
                                season: season.seasonNumber,
                                episode: episode.episodeNumber
                            ),
                            isNext: appState.nextEpisode(for: show)?.id == episode.id,
                            onTap: {
                                appState.toggleWatched(
                                    showId: show.id,
                                    season: season.seasonNumber,
                                    episode: episode.episodeNumber
                                )
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle(show.title)
        .navigationBarTitleDisplayMode(.large)
    }
}
