import CoreMotion
import Foundation
import HealthKit
import Observation
import WatchConnectivity
import WatchKit

/// Stato dell'app del Watch: l'esercizio aperto sull'iPhone e la serie in corso.
@Observable
final class WatchModel: NSObject, WCSessionDelegate {

    enum Phase {
        /// Fermo: si aspetta "Via".
        case idle
        /// Modalità automatica: sensori accesi, nessuna ripetizione ancora.
        case listening
        /// Serie in corso: ogni ripetizione vibra.
        case counting
    }

    private(set) var context: WatchContext?
    private(set) var phase: Phase = .idle
    /// Carico della serie, in kg; la Digital Crown lo sposta del passo del macchinario.
    var weight: Double = 0
    var reps = 0
    /// Ultima serie inviata, per conferma a schermo.
    private(set) var lastSent: WatchSet?

    var exercise: WatchExercise? { context?.exercise }
    var mode: WatchCountMode { context?.mode ?? .tapStartAutoEnd }
    /// Il polso si muove con l'esercizio: niente conteggio sulle gambe.
    var canCount: Bool { exercise.map { !$0.worksLegs } ?? false }

    @ObservationIgnored private let motion = CMMotionManager()
    @ObservationIgnored private let health = HKHealthStore()
    @ObservationIgnored private var workout: HKWorkoutSession?
    @ObservationIgnored private var counter = RepCounter()

    /// Sotto questa soglia, in modalità automatica, una "serie" è un falso allarme.
    private static let automaticMinimumReps = 3

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

    // MARK: - Serie

    /// "Via", dal Watch o dall'iPhone.
    func begin() {
        guard canCount else { return }
        startCounting(phase: .counting)
        WKInterfaceDevice.current().play(.start)
    }

    /// Chiude la serie e la registra sull'iPhone.
    func finish() {
        let automatic = mode == .automatic
        stopMotion()
        if reps > 0 { send() }
        if automatic, canCount {
            startCounting(phase: .listening)
        } else {
            phase = .idle
        }
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

    private func startCounting(phase newPhase: Phase) {
        reps = 0
        counter = RepCounter(sensitivity: context?.sensitivity ?? 1)
        phase = newPhase
        startWorkout()
        startMotion()
    }

    // MARK: - Sensori

    private func startMotion() {
        guard motion.isDeviceMotionAvailable, !motion.isDeviceMotionActive else { return }
        motion.deviceMotionUpdateInterval = 1.0 / 50
        motion.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            self.handle(data)
        }
    }

    private func stopMotion() {
        motion.stopDeviceMotionUpdates()
    }

    private func handle(_ data: CMDeviceMotion) {
        // Accelerazione portata nel riferimento fisso (z verticale): così l'asse del
        // movimento non gira con il polso durante un curl.
        let a = data.userAcceleration
        let m = data.attitude.rotationMatrix
        let world = SIMD3(
            a.x * m.m11 + a.y * m.m21 + a.z * m.m31,
            a.x * m.m12 + a.y * m.m22 + a.z * m.m32,
            a.x * m.m13 + a.y * m.m23 + a.z * m.m33
        )
        let now = data.timestamp

        if counter.add(world, at: now) {
            reps = counter.reps
            if phase == .listening { phase = .counting }
            WKInterfaceDevice.current().play(.click)
        }

        // Fine automatica: tot secondi fermi dopo l'ultima ripetizione.
        guard phase == .counting, mode != .tapStartTapEnd,
              let last = counter.lastRepAt,
              now - last >= (context?.autoEndSeconds ?? 4) else { return }
        if mode == .automatic, reps < Self.automaticMinimumReps {
            startCounting(phase: .listening)
        } else {
            finish()
        }
    }

    // MARK: - Sessione di allenamento

    /// Una sessione di allenamento tiene l'app viva e i sensori accesi a polso
    /// abbassato. Non viene mai salvata: in Salute l'allenamento lo scrive l'iPhone.
    func startWorkout() {
        guard workout == nil, HKHealthStore.isHealthDataAvailable() else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        health.requestAuthorization(toShare: [HKObjectType.workoutType()], read: []) { [weak self] _, _ in
            DispatchQueue.main.async {
                guard let self, self.workout == nil,
                      let session = try? HKWorkoutSession(healthStore: self.health, configuration: configuration)
                else { return }
                self.workout = session
                session.startActivity(with: Date())
            }
        }
    }

    private func endWorkout() {
        workout?.end()
        workout = nil
    }

    // MARK: - Dall'iPhone

    private func apply(_ newContext: WatchContext) {
        let changedExercise = newContext.exercise?.uuid != context?.exercise?.uuid
        context = newContext

        guard newContext.exercise != nil else {
            // Allenamento finito sull'iPhone.
            stopMotion()
            phase = .idle
            endWorkout()
            return
        }

        if changedExercise || newContext.startRequestedAt != nil {
            if phase == .counting, reps > 0 { finish() }
            stopMotion()
            phase = .idle
            weight = newContext.exercise?.weight ?? 0
            reps = 0
            lastSent = nil
        }

        if let requested = newContext.startRequestedAt, Date().timeIntervalSince(requested) < 20 {
            begin()
        } else if mode == .automatic, canCount, phase == .idle {
            startCounting(phase: .listening)
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
