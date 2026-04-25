import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(SocialStore.self) private var socialStore
    @State private var showClearFeedConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    profileRow(label: "Username", value: appState.currentUser?.username ?? "—")
                }

                Section {
                    Button("Log Out", role: .destructive) {
                        appState.signOut()
                    }
                }

                if appState.currentUsername == "arya" {
                    Section {
                        Button {
                            showClearFeedConfirmation = true
                        } label: {
                            Label("Clear Feed", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                        .popover(isPresented: $showClearFeedConfirmation) {
                            VStack(spacing: 16) {
                                Text("Clear All Feed Activity")
                                    .font(.headline)
                                Text("This removes all feed activity for every user. This cannot be undone.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                Button("Clear", role: .destructive) {
                                    showClearFeedConfirmation = false
                                    socialStore.clearAllFeeds()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.red)
                            }
                            .padding()
                            .presentationCompactAdaptation(.popover)
                        }
                    }
                }
            }
            .navigationTitle("Bestiary")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.msBody)
            Spacer()
            Text(value).font(.msBody).foregroundStyle(.secondary)
        }
    }
}
