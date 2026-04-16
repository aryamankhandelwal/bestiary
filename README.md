# Bestiary

A TV show tracking app for iOS.

Track what you're watching, mark episodes as watched, and keep a watchlist for shows you want to start.

## Requirements

- iOS 17+
- Xcode 15+
- No third-party dependencies

## Features

- Browse and search shows via TMDB
- Mark individual episodes as watched
- Track progress across seasons
- Watchlist for shows you haven't started yet
- Calendar view of upcoming episodes
- Bulk add shows at once

## Architecture

MVVM using Swift's `@Observable` framework (iOS 17+).

- `AppState` — single source of truth, injected via `.environment`
- Value-based navigation with `NavigationLink(value:)` + `.navigationDestination(for:)`
- Presentational leaf views (`ShowRowView`, `EpisodeRowView`) receive only what they need — no direct `AppState` access

## Project Structure

```
fynch/
  Models/
    Show.swift           — Episode, Season, Show value types
    AppState.swift       — @Observable class, all state + logic
    TMDBModels.swift     — TMDB API response models
    AuthSession.swift    — Auth state
  Views/
    HomeView.swift       — root NavigationStack
    ShowDetailView.swift — season/episode list
    AddShowView.swift    — single show search + add
    BulkAddView.swift    — bulk search + add
    WatchlistView.swift  — watchlist tab
    CalendarTrayView.swift
    ShowRowView.swift    — presentational row
    EpisodeRowView.swift — presentational row
  ContentView.swift      — delegates to HomeView
  fynchApp.swift         — injects AppState
```
