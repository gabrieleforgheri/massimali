import Foundation
import Observation
import UserNotifications

/// Il recupero in corso, unico per tutta l'app: lo avvia la sessione sull'iPhone
/// e anche una serie arrivata dal Watch. La notifica serve con il telefono in tasca;
/// in app ci pensa la vista della sessione con una vibrazione.
@Observable
final class RestTimer {

    static let shared = RestTimer()

    /// Fine del recupero, `nil` se non ce n'è uno.
    private(set) var end: Date?

    private static let notificationID = "rest-timer"
    private var center: UNUserNotificationCenter { .current() }

    func start(seconds: Int) {
        set(Date.now.addingTimeInterval(TimeInterval(seconds)))
    }

    func shift(by seconds: Int) {
        guard let end else { return }
        let shifted = end.addingTimeInterval(TimeInterval(seconds))
        set(shifted <= .now ? nil : shifted)
    }

    func stop() { set(nil) }

    private func set(_ newEnd: Date?) {
        end = newEnd
        center.removePendingNotificationRequests(withIdentifiers: [Self.notificationID])
        guard let newEnd else { return }
        let seconds = newEnd.timeIntervalSinceNow
        guard seconds > 1 else { return }
        let center = center
        Task {
            // Al primo uso chiede il permesso; le volte dopo risponde subito.
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return }
            let content = UNMutableNotificationContent()
            content.title = "Recupero finito"
            content.body = "Tocca alla prossima serie."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: Self.notificationID, content: content, trigger: trigger))
        }
    }
}
