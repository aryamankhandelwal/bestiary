import SwiftUI

enum AddDestination {
    case myList
    case watchlist
}

private enum SearchState {
    case idle
    case loading
    case loaded([TMDBSearchResult])
    case error(String)
}

struct AddShowView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss

    let tmdbService: TMDBService
    let destination: AddDestination

    @State private var query: String = ""
    @State private var searchState: SearchState = .idle
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var addingShowId: Int? = nil
    @State private var showingBulkAdd: Bool = false

    var body: some View {
        NavigationStack {
            Group {
                switch searchState {
                case .idle:
                    ContentUnavailableView(
                        "Search for a show",
                        systemImage: "magnifyingglass",
                        description: Text("Type a show name above to get started.")
                    )

                case .loading:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .loaded(let results):
                    if results.isEmpty {
                        ContentUnavailableView.search(text: query)
                    } else {
                        resultsList(results)
                    }

                case .error(let message):
                    ContentUnavailableView(
                        "Something went wrong",
                        systemImage: "exclamationmark.triangle",
                        description: Text(message)
                    )
                }
            }
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search TV shows")
            .onChange(of: query) { _, newValue in
                scheduleSearch(query: newValue)
            }
            .navigationTitle("Add Show")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingBulkAdd = true
                    } label: {
                        Text("Bulk Add")
                    }
                }
            }
            .sheet(isPresented: $showingBulkAdd) {
                BulkAddView(tmdbService: tmdbService, destination: destination, onAdded: { dismiss() })
            }
        }
    }

    // MARK: - Results List

    private func resultsList(_ results: [TMDBSearchResult]) -> some View {
        let myListIds = Set(appState.myListShows.map(\.tmdbId))
        let watchlistIds = Set(appState.watchlistShows.map(\.tmdbId))
        let newResults = results.filter { !myListIds.contains($0.id) && !watchlistIds.contains($0.id) }
        let myListResults = results.filter { myListIds.contains($0.id) }
        let watchlistResults = results.filter { watchlistIds.contains($0.id) }

        return List {
            ForEach(newResults) { result in
                addableRow(result)
            }

            if !myListResults.isEmpty {
                Section("Already in My List") {
                    ForEach(myListResults) { result in
                        alreadyAddedRow(result)
                    }
                }
            }

            if !watchlistResults.isEmpty {
                Section("Already in Watchlist") {
                    ForEach(watchlistResults) { result in
                        alreadyAddedRow(result)
                    }
                }
            }
        }
    }

    private func addableRow(_ result: TMDBSearchResult) -> some View {
        HStack(spacing: 14) {
            let colorIndex = result.id % Show.palette.count
            Circle()
                .fill(Show.palette[colorIndex].gradient)
                .frame(width: 40, height: 40)
                .overlay {
                    Text(result.name.prefix(1))
                        .font(.headline.bold())
                        .foregroundStyle(.white)
                }

            Text(result.name)
                .font(.msHeadline)

            Spacer()

            if addingShowId == result.id {
                ProgressView()
            } else {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.title2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            guard addingShowId == nil else { return }
            addShow(result)
        }
    }

    private func alreadyAddedRow(_ result: TMDBSearchResult) -> some View {
        HStack(spacing: 14) {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 40)
                .overlay {
                    Text(result.name.prefix(1))
                        .font(.headline.bold())
                        .foregroundStyle(Color.secondary)
                }

            Text(result.name)
                .font(.msHeadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .opacity(0.6)
    }

    // MARK: - Search

    private func scheduleSearch(query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            searchState = .idle
            return
        }
        searchState = .loading
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            do {
                let results = try await tmdbService.searchShows(query: trimmed)
                searchState = .loaded(results)
            } catch {
                searchState = .error(error.localizedDescription)
            }
        }
    }

    // MARK: - Add

    private func addShow(_ result: TMDBSearchResult) {
        addingShowId = result.id
        Task {
            do {
                try await appState.addShowFromTMDB(searchResult: result, service: tmdbService, destination: destination)
                dismiss()
            } catch {
                searchState = .error("Failed to load show: \(error.localizedDescription)")
                addingShowId = nil
            }
        }
    }
}
