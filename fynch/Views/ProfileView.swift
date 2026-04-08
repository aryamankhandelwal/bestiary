import SwiftUI

struct ProfileView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    profileRow(label: "Name", value: "Aryaman Khandelwal")
                    profileRow(label: "Username", value: "arya")
                    profileRow(label: "Password", value: "••••••••")
                }

                Section {
                    Button("Log Out", role: .destructive) {
                        appState.logout()
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private func profileRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
