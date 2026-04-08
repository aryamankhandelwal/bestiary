//
//  fynchApp.swift
//  fynch
//
//  Created by Aryaman on 4/8/26.
//

import SwiftUI
import BackgroundTasks

@main
struct fynchApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase
    private let tmdbService = TMDBService(bearerToken: Secrets.tmdbBearerToken)
    private let refreshService = RefreshService()

    var body: some Scene {
        WindowGroup {
            ContentView(tmdbService: tmdbService, refreshService: refreshService)
                .environment(appState)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await appState.refreshAllShows(
                        service: tmdbService,
                        refreshService: refreshService,
                        isManual: false
                    )
                }
                scheduleBackgroundRefreshIfNeeded()
            }
        }
        .backgroundTask(.appRefresh("com.fynch.refresh")) {
            await appState.refreshAllShows(
                service: tmdbService,
                refreshService: refreshService,
                isManual: false
            )
            scheduleNextBackgroundRefresh()
        }
    }

    // nonisolated so these can be called from non-MainActor contexts (BGTask closure, onChange)
    nonisolated private func scheduleBackgroundRefreshIfNeeded() {
        let request = BGAppRefreshTaskRequest(identifier: "com.fynch.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 86_400)
        try? BGTaskScheduler.shared.submit(request)
    }

    nonisolated private func scheduleNextBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.fynch.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 86_400)
        try? BGTaskScheduler.shared.submit(request)
    }
}
