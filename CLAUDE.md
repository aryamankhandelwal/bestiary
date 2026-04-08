# fynch — Project Conventions

## Overview
fynch is a TV show tracking app for iOS. Phase 1 is a fully hardcoded, in-memory prototype — no networking, no persistence, no external dependencies.

## Requirements
- **iOS 17+** — required for `@Observable`, `ContentUnavailableView`, and `Color: Hashable`
- No third-party packages

## Architecture: MVVM with `@Observable`

### State management
- Use **`@Observable`** (Swift 5.9 Observation framework), not `@StateObject`/`@ObservedObject`
- `AppState` is the single source of truth, created once in `fynchApp` as `@State private var appState = AppState()`
- Injected into the view tree via `.environment(appState)`
- Consumed in views with `@Environment(AppState.self) private var appState`

### Navigation
- Use **`NavigationLink(value:)`** + **`.navigationDestination(for:)`** — never the deprecated `NavigationLink(destination:)` form
- `Show` must stay `Hashable` for value-based navigation

### View rules
- **Leaf views** (`ShowRowView`, `EpisodeRowView`) are **pure/presentational** — they receive pre-computed values as parameters and do not access `AppState` directly
- Parent views (`HomeView`, `ShowDetailView`, `AddShowView`) own the `AppState` connection and pass down only what each child needs

## Data

### All data is hardcoded in `AppState`
- `AppState.catalog` — static array of all known shows (superset)
- `AppState.makeSampleShows()` — subset that starts in the tracked list
- `AppState.makeSampleWatchedStates()` — initial watched state dictionary

### Watched state key format
```
"\(showId)-S\(seasonNumber)E\(episodeNumber)"
// e.g. "breaking-bad-S1E1"
```
This convention is defined once in `AppState.watchKey(showId:season:episode:)`.

## UI Conventions

### Avatar color (Home screen)
The show avatar circle communicates watch status — no progress text is shown on the home row:
- **Episodes remaining** → bright `show.posterColor.gradient` at full opacity
- **Fully watched** → `Color.gray.opacity(0.25)`, letter tint dimmed to `.secondary`
- Transition animated with `.easeInOut(duration: 0.3)`

### Episode rows (Show Detail)
- Next unwatched episode gets an "Up next" caption in blue and bold title
- Watched checkmark animates with `.easeInOut(duration: 0.2)`

## File Structure
```
fynch/
  Models/
    Show.swift          — Episode, Season, Show value types
    AppState.swift      — @Observable class, all logic + sample data
  Views/
    HomeView.swift      — root NavigationStack
    ShowDetailView.swift
    AddShowView.swift
    ShowRowView.swift   — presentational
    EpisodeRowView.swift — presentational
  ContentView.swift     — delegates to HomeView
  fynchApp.swift        — injects AppState
```
