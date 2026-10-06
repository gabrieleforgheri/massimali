import Foundation
import UserNotifications

/// Notifica di fine recupero, per quando il telefono è in tasca o bloccato.
/// In app ci pensa la vista della sessione con una vibrazione.
enum RestTimer {

    private static let id = "rest-timer"
    private static var center: UNUserNotificationCenter { .current() }

    static func schedule(until end: Date) {
        cancel()
        let seconds = end.timeIntervalSinceNow
        guard seconds > 1 else { return }
        Task {
            // Al primo uso chiede il permesso; le volte dopo risponde subito.
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = "Recupero finito"
            content.body = "Tocca alla prossima serie."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}
