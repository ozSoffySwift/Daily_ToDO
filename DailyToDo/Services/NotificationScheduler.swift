//
//  NotificationScheduler.swift
//  DailyToDo
//
//  Thin wrapper around UNUserNotificationCenter for task reminders.
//
import Foundation
import UserNotifications

extension Notification.Name {
    /// Posted by `NotificationDelegate` when the user taps a reminder, carrying the
    /// task's day (as a `Date` under the "date" key) so the UI can jump to it.
    static let dailyToDoOpenDate = Notification.Name("dailyToDoOpenDate")
}

/// Schedules, cancels, and tracks authorization for local reminder notifications.
enum NotificationScheduler {
    /// How many days ahead to pre-schedule concrete notifications for a recurring task.
    /// Refreshed on every app foreground, so this window never actually runs dry.
    static let recurringWindowDays = 14

    /// The most recently known notification authorization status. Call
    /// `refreshAuthorizationStatus()` to update it from the system.
    static var authorizationStatus: UNAuthorizationStatus = .notDetermined

    /// Re-reads the current notification authorization status from the system into `authorizationStatus`.
    static func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    /// Requests notification permission if it hasn't been decided yet. Returns whether
    /// notifications are (now) allowed, without re-prompting if the user already answered.
    @discardableResult
    static func requestAuthorizationIfNeeded() async -> Bool {
        await refreshAuthorizationStatus()
        switch authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            // Already allowed in some form; nothing more to do.
            return true
        case .denied:
            // The user already said no; don't re-prompt, just report the fact.
            return false
        case .notDetermined:
            // First time asking — show the system permission dialog.
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .sound, .badge])
                await refreshAuthorizationStatus()
                return granted
            } catch {
                return false
            }
        @unknown default:
            return false
        }
    }

    // MARK: - One-time / sticky task reminders

    /// Schedules a single reminder notification for a one-time or sticky task on the given day/time.
    /// Any previously scheduled reminder for this task is replaced.
    static func scheduleTaskReminder(taskID: UUID, title: String, day: Date, hour: Int, minute: Int, calendar: Calendar = .current) {
        // One stable identifier per task, so re-scheduling naturally replaces the old request.
        let identifier = "task-\(taskID.uuidString)"
        cancel(identifiers: [identifier])

        // Combine the task's day with the requested hour/minute into one fire date.
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute

        // Don't schedule reminders that would fire in the past.
        guard let fireDate = calendar.date(from: components), fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Daily 2do"
        content.body = title
        content.sound = .default
        // Stash the task's day so a tap on the notification can jump straight to it.
        content.userInfo = ["day": ISO8601DateFormatter().string(from: calendar.startOfDay(for: day))]

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels the pending reminder (if any) for a one-time or sticky task.
    static func cancelTaskReminder(taskID: UUID) {
        cancel(identifiers: ["task-\(taskID.uuidString)"])
    }

    // MARK: - Recurring task reminders

    /// Re-schedules all upcoming reminders for a recurring task over the next
    /// `recurringWindowDays` days, skipping days the rule doesn't apply to and
    /// days already marked complete. Any previously scheduled reminders for this
    /// task are cleared first, so this is safe to call every time something changes.
    static func rescheduleRecurringReminders(
        taskID: UUID,
        title: String,
        rule: RecurrenceRule,
        startDate: Date,
        hour: Int,
        minute: Int,
        completedDays: Set<Date>,
        calendar: Calendar = .current
    ) {
        cancelRecurringReminders(taskID: taskID)

        let today = calendar.startOfDay(for: Date())
        var requests: [UNNotificationRequest] = []

        // Walk forward day by day across the scheduling window, building one request per due day.
        for offset in 0..<recurringWindowDays {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let normalizedDay = calendar.startOfDay(for: day)
            // Skip days the recurrence rule doesn't cover.
            guard rule.isDue(on: normalizedDay, since: startDate, calendar: calendar) else { continue }
            // Skip days already checked off — no point reminding about a finished habit.
            guard completedDays.contains(normalizedDay) == false else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: normalizedDay)
            components.hour = hour
            components.minute = minute
            // Don't schedule reminders that would fire in the past.
            guard let fireDate = calendar.date(from: components), fireDate > Date() else { continue }

            let identifier = recurringIdentifier(taskID: taskID, day: normalizedDay, calendar: calendar)
            let content = UNMutableNotificationContent()
            content.title = "Daily 2do"
            content.body = title
            content.sound = .default
            // Stash the day so a tap on the notification can jump straight to it.
            content.userInfo = ["day": ISO8601DateFormatter().string(from: normalizedDay)]

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            requests.append(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
        }

        for request in requests {
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Cancels every pending reminder previously scheduled for a recurring task.
    static func cancelRecurringReminders(taskID: UUID) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            // All of this task's requests share a common identifier prefix, so match on that.
            let prefix = "recurring-\(taskID.uuidString)-"
            let matching = requests.map(\.identifier).filter { $0.hasPrefix(prefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: matching)
        }
    }

    /// Builds the per-day notification identifier for a recurring task, e.g. "recurring-<uuid>-20260701".
    private static func recurringIdentifier(taskID: UUID, day: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: day)
        let stamp = String(format: "%04d%02d%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
        return "recurring-\(taskID.uuidString)-\(stamp)"
    }

    /// Removes the given pending notification identifiers from the system.
    private static func cancel(identifiers: [String]) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

/// Handles incoming notification events: shows banners while the app is foregrounded,
/// and turns a notification tap into a `.dailyToDoOpenDate` broadcast the UI can observe.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    /// The single shared delegate instance, assigned to `UNUserNotificationCenter.current().delegate`.
    static let shared = NotificationDelegate()

    /// Called while the app is in the foreground when a notification would otherwise fire silently;
    /// tells the system to show it as a banner with sound anyway.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }

    /// Called when the user taps a delivered notification; extracts the task's day
    /// from its payload and broadcasts it so the daily view can navigate there.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard
            let dayString = response.notification.request.content.userInfo["day"] as? String,
            let day = ISO8601DateFormatter().date(from: dayString)
        else { return }
        NotificationCenter.default.post(name: .dailyToDoOpenDate, object: nil, userInfo: ["date": day])
    }
}
