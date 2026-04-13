import SwiftUI

enum ShowSortOrder: String, CaseIterable {
    case `default` = "Default"
    case alphabetical = "A → Z"
    case mostToWatch = "Most to watch"
    case caughtUpLast = "Caught up last"
}

struct HomeView: View {
    @Environment(AppState.self) private var appState
    @State private var navigationPath = NavigationPath()
    @State private var showingAddSheet = false
    @State private var sortOrder: ShowSortOrder = .default
    // @State private var trayExpanded = false  // TODO: MVP — calendar tray disabled

    let tmdbService: TMDBService
    let refreshService: RefreshService

    private var sortedShows: [Show] {
        switch sortOrder {
        case .default:
            return appState.myListShows
        case .alphabetical:
            return appState.myListShows.sorted { $0.title < $1.title }
        case .mostToWatch:
            return appState.myListShows.sorted {
                appState.episodesRemaining(for: $0) > appState.episodesRemaining(for: $1)
            }
        case .caughtUpLast:
            return appState.myListShows.sorted {
                let lhsDone = appState.isCompleted($0)
                let rhsDone = appState.isCompleted($1)
                if lhsDone == rhsDone { return false }
                return !lhsDone
            }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if appState.myListShows.isEmpty {
                    ContentUnavailableView(
                        "No shows yet",
                        systemImage: "tv",
                        description: Text("Tap + to search and add a show.")
                    )
                } else {
                    List {
                        ForEach(sortedShows) { show in
                            NavigationLink(value: show) {
                                ShowRowView(
                                    show: show,
                                    isCompleted: appState.isCompleted(show),
                                    statusLabel: appState.statusLabel(for: show),
                                    nextAirDate: appState.nextAirDateLabel(for: show)
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
                    // .safeAreaInset(edge: .bottom) {  // TODO: MVP — calendar tray disabled
                    //     Color.clear.frame(height: CalendarTrayView.handleBarHeight)
                    // }
                    .refreshable {
                        await appState.refreshAllShows(
                            service: tmdbService,
                            refreshService: refreshService,
                            isManual: true
                        )
                    }
                }
            }
            .navigationTitle("fynch")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Show.self) { show in
                ShowDetailView(show: show)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Section("Sort by") {
                            ForEach(ShowSortOrder.allCases, id: \.self) { order in
                                Button {
                                    withAnimation { sortOrder = order }
                                } label: {
                                    HStack {
                                        Text(order.rawValue)
                                        if sortOrder == order {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddShowView(tmdbService: tmdbService, destination: .myList)
            }
            .animation(.easeInOut, value: appState.myListShows.map(\.id))
            .onChange(of: appState.pendingDeepLinkShowId) { _, newId in
                guard let id = newId,
                      let show = appState.shows.first(where: { $0.id == id })
                else { return }
                navigationPath.append(show)
                appState.pendingDeepLinkShowId = nil
            }
        }
        // .overlay(alignment: .bottom) {  // TODO: MVP — calendar tray disabled
        //     CalendarTrayView(isExpanded: $trayExpanded)
        // }
    }
}
