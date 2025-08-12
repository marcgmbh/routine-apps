import Foundation
import UserNotifications

final class LocalNotificationScheduler: NotificationScheduler {
    func requestAuthorization() async throws {
        _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func scheduleStepNotification(at fireDate: Date, title: String, body: String, id: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        let interval = max(1, fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await UNUserNotificationCenter.current().add(request)
    }

    func clearPending(forRoutineID id: UUID) async {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id.uuidString])
    }
}
