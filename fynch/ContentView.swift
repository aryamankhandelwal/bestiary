//
//  ContentView.swift
//  fynch
//
//  Created by Aryaman on 4/8/26.
//

import SwiftUI

struct ContentView: View {
    let tmdbService: TMDBService
    let refreshService: RefreshService

    var body: some View {
        HomeView(tmdbService: tmdbService, refreshService: refreshService)
    }
}

#Preview {
    ContentView(
        tmdbService: TMDBService(bearerToken: ""),
        refreshService: RefreshService()
    )
    .environment(AppState())
}
