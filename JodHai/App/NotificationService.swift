import UserNotifications
import Foundation

final class NotificationService: Sendable {
    static let shared = NotificationService()

    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func checkBudget(category: String, spent: Double, limit: Double) {
        guard limit > 0 else { return }
        let ratio = spent / limit
        if ratio >= 1.0 {
            fire(
                id: "over-\(category)-\(dayTag)",
                title: "เกินงบ: \(category)",
                body: "ใช้ไปแล้ว \(formatTHB(spent)) จากงบ \(formatTHB(limit))"
            )
        } else if ratio >= 0.8 {
            fire(
                id: "near-\(category)-\(dayTag)",
                title: "งบใกล้เต็ม: \(category)",
                body: "ใช้ไป \(Int(ratio * 100))% เหลือ \(formatTHB(limit - spent))"
            )
        }
    }

    private var dayTag: String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return "\(c.year ?? 0)-\(c.month ?? 0)-\(c.day ?? 0)"
    }

    private func formatTHB(_ value: Double) -> String {
        value.formatted(.currency(code: "THB").precision(.fractionLength(0)))
    }

    private func fire(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request  = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
