import SwiftUI

struct ShowRowView: View {
    let show: Show
    let isCompleted: Bool
    let statusLabel: String
    var nextAirDate: String? = nil

    var body: some View {
        HStack(spacing: 14) {
            avatarView

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(show.title)
                        .font(.headline)
                    if let airDate = nextAirDate {
                        Text(airDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(statusLabel)
                    .font(.subheadline)
                    .foregroundStyle(isCompleted ? .secondary : show.posterColor)
            }

            Spacer()

            if !isCompleted {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 8, height: 8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.vertical, 4)
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(isCompleted
                    ? AnyShapeStyle(Color.gray.opacity(0.25))
                    : AnyShapeStyle(show.posterColor.gradient)
                )
                .frame(width: 48, height: 48)
                .animation(.easeInOut(duration: 0.3), value: isCompleted)

            Text(show.title.prefix(1))
                .font(.title2.bold())
                .foregroundStyle(isCompleted ? Color.secondary : Color.white)
                .animation(.easeInOut(duration: 0.3), value: isCompleted)
        }
    }
}
