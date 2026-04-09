import UserNotifications
import UIKit

actor NotificationService {
    static let shared = NotificationService()
    private static let idPrefix = "fynch-notif-"

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    func scheduleEpisodeNotifications(for shows: [Show]) async {
        let status = await authorizationStatus()

        if status == .notDetermined {
            let appState = await MainActor.run { UIApplication.shared.applicationState }
            guard appState == .active else { return }
            let granted = await requestAuthorization()
            guard granted else { return }
        } else {
            guard status == .authorized || status == .provisional else { return }
        }

        let center = UNUserNotificationCenter.current()

        // Remove all previously scheduled fynch notifications
        let pending = await center.pendingNotificationRequests()
        let fynchIds = pending.map(\.identifier).filter { $0.hasPrefix(Self.idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: fynchIds)

        // Group upcoming episodes by (showId, airDate)
        let today = Self.todayString()
        // key: "showId|airDate" → (showTitle, airDate, episodeCount)
        var groups: [String: (title: String, airDate: String, count: Int)] = [:]

        for show in shows {
            for season in show.seasons {
                for episode in season.episodes {
                    guard let airDate = episode.airDate, !airDate.isEmpty, airDate > today else { continue }
                    let key = "\(show.id)|\(airDate)"
                    if let existing = groups[key] {
                        groups[key] = (existing.title, airDate, existing.count + 1)
                    } else {
                        groups[key] = (show.title, airDate, 1)
                    }
                }
            }
        }

        // Sort by air date ascending, cap at 64 (iOS limit)
        let sorted = groups.sorted { $0.value.airDate < $1.value.airDate }.prefix(64)

        let formatter = Self.makeDateFormatter()

        for (key, group) in sorted {
            let parts = key.split(separator: "|", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let showId = String(parts[0])

            guard let date = formatter.date(from: group.airDate) else { continue }
            var comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
            comps.hour = 20
            comps.minute = 0
            comps.second = 0

            let content = UNMutableNotificationContent()
            content.title = group.title
            content.body = group.count == 1
                ? "New episode is now available"
                : "\(group.count) new episodes are now available"
            content.sound = .default
            content.userInfo = ["showId": showId]

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = "\(Self.idPrefix)\(showId)-\(group.airDate)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    // MARK: - Debug

    // #if DEBUG
    // func scheduleTestNotification(for show: Show) async {
    //     let status = await authorizationStatus()
    //     if status == .notDetermined {
    //         let granted = await requestAuthorization()
    //         guard granted else { return }
    //     } else {
    //         guard status == .authorized || status == .provisional else { return }
    //     }
    //     let content = UNMutableNotificationContent()
    //     content.title = show.title
    //     content.body = "New episode is now available"
    //     content.sound = .default
    //     content.userInfo = ["showId": show.id]
    //     let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
    //     let request = UNNotificationRequest(identifier: "fynch-test", content: content, trigger: trigger)
    //     try? await UNUserNotificationCenter.current().add(request)
    // }
    // #endif

    // MARK: - Cancellation

    func cancelNotifications(forShowId showId: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let prefix = "\(Self.idPrefix)\(showId)-"
        let toRemove = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }

    // MARK: - Helpers

    private static func todayString() -> String {
        makeDateFormatter().string(from: Date())
    }

    private static func makeDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }
}
