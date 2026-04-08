import SwiftUI

struct AddShowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    private var availableShows: [Show] {
        AppState.catalog.filter { candidate in
            !appState.shows.contains(where: { $0.id == candidate.id })
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if availableShows.isEmpty {
                    ContentUnavailableView(
                        "All caught up",
                        systemImage: "checkmark.seal.fill",
                        description: Text("You're already tracking every show in the catalog.")
                    )
                } else {
                    List(availableShows) { show in
                        HStack(spacing: 14) {
                            Circle()
                                .fill(show.posterColor.gradient)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    Text(show.title.prefix(1))
                                        .font(.headline.bold())
                                        .foregroundStyle(.white)
                                }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(show.title)
                                    .font(.headline)
                                Text(show.genres.prefix(2).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.title2)
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            appState.addShow(show)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Add Show")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
