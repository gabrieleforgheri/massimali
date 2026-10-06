import Foundation
import Observation
import WatchConnectivity
import WatchKit

/// Stato dell'app del Watch: l'esercizio aperto sull'iPhone e la serie in corso.
@Observable
final class WatchModel: NSObject, WCSessionDelegate {

    private(set) var context: WatchContext?
    /// Carico della serie, in kg; la Digital Crown lo sposta del passo del macchinario.
    var weight: Double = 0
    var reps = 0
    /// Ultima serie inviata, per conferma a schermo.
    private(set) var lastSent: WatchSet?

    var exercise: WatchExercise? { context?.exercise }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func displayWeight(_ kilograms: Double) -> String {
        let factor = context?.unitFactor ?? 1
        let value = (kilograms * factor).formatted(.number.precision(.fractionLength(0...2)))
        return "\(value) \(context?.unitSymbol ?? "kg")"
    }

    /// Manda la serie all'iPhone: subito se raggiungibile, altrimenti in coda garantita.
    func send() {
        guard let exercise, reps > 0 else { return }
        let set = WatchSet(exerciseUUID: exercise.uuid, weight: weight, reps: reps)
        let payload = set.watchPayload(key: WatchSet.key)
        let session = WCSession.default
        if session.isReachable {
            session.sendMessage(payload, replyHandler: nil) { _ in
                session.transferUserInfo(payload)
            }
        } else {
            session.transferUserInfo(payload)
        }
        lastSent = set
        reps = 0
        WKInterfaceDevice.current().play(.success)
    }

    // MARK: - Dall'iPhone

    private func apply(_ newContext: WatchContext) {
        let changedExercise = newContext.exercise?.uuid != context?.exercise?.uuid
        context = newContext
        if changedExercise || newContext.startRequestedAt != nil {
            weight = newContext.exercise?.weight ?? 0
            reps = 0
            lastSent = nil
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Il contesto più recente, arrivato mentre l'app era chiusa.
        let received = session.receivedApplicationContext
        guard let context = WatchContext(watchPayload: received, key: WatchContext.key) else { return }
        Task { @MainActor in self.apply(context) }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let context = WatchContext(watchPayload: applicationContext, key: WatchContext.key) else { return }
        Task { @MainActor in self.apply(context) }
    }
}
