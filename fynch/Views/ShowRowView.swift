import SwiftUI

struct ShowRowView: View {
    let show: Show
    let isCompleted: Bool

    var body: some View {
        HStack(spacing: 14) {
            avatarView

            Text(show.title)
                .font(.headline)

            Spacer()
        }
        .padding(.vertical, 4)
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
