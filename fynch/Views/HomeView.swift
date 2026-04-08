import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(appState.shows) { show in
                    NavigationLink(value: show) {
                        ShowRowView(
                            show: show,
                            isCompleted: appState.isCompleted(show),
                            statusLabel: appState.statusLabel(for: show)
                        )
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            appState.deleteShow(id: show.id)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("fynch")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Show.self) { show in
                ShowDetailView(show: show)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddShowView()
            }
            .animation(.easeInOut, value: appState.shows.count)
        }
    }
}
