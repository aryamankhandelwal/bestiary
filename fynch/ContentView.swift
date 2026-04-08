//
//  ContentView.swift
//  fynch
//
//  Created by Aryaman on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    let tmdbService: TMDBService
    let refreshService: RefreshService

    var body: some View {
        Group {
            if appState.isLoggedIn {
                TabView {
                    HomeView(tmdbService: tmdbService, refreshService: refreshService)
                        .tabItem { Label("My List", systemImage: "tv") }
                    ProfileView()
                        .tabItem { Label("Profile", systemImage: "person.circle") }
                }
                .transition(.opacity)
            } else {
                LoginView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: appState.isLoggedIn)
    }
}

#Preview {
    ContentView(
        tmdbService: TMDBService(bearerToken: ""),
        refreshService: RefreshService()
    )
    .environment(AppState())
}
