import SwiftUI

struct EpisodeRowView: View {
    let episode: Episode
    let isWatched: Bool
    let isNext: Bool
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text("E\(episode.episodeNumber)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(episode.title)
                    .font(isNext ? .body.bold() : .body)
                    .foregroundStyle(isWatched && !isNext ? .secondary : .primary)

                if isNext {
                    Text("Up next")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                }
            }

            Spacer()

            Image(systemName: isWatched ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isWatched ? .green : Color.secondary.opacity(0.4))
                .font(.title3)
                .animation(.easeInOut(duration: 0.2), value: isWatched)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .padding(.vertical, 1)
    }
}
