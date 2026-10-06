import Foundation
import simd

/// Conta le ripetizioni dall'accelerazione del polso (senza gravità, in un sistema di
/// riferimento fisso nello spazio, campionata a ~50 Hz).
///
/// Una ripetizione è un'oscillazione completa lungo la direzione in cui il polso si
/// muove di più: si trova con l'asse principale delle ultime ~2 s di campioni, che vale
/// per curl e spinte (verticale) come per rematori e croci (orizzontale). Il segnale
/// proiettato passa da un filtro passa-basso e si conta ogni risalita da sotto −soglia a
/// sopra +soglia: isteresi, così il tremolio non conta mai.
// ponytail: soglia fissa scalata dalla sensibilità; se in palestra sbaglia su alcuni
// esercizi, il passo dopo è una soglia adattiva sull'ampiezza delle prime ripetizioni.
struct RepCounter {

    /// Manopola di calibrazione: 1 normale, 2 conta movimenti grandi la metà.
    var sensitivity: Double

    private(set) var reps = 0
    /// Istante dell'ultima ripetizione (stesso orologio dei campioni).
    private(set) var lastRepAt: TimeInterval?

    private var window: [SIMD3<Double>] = []
    private var axis: SIMD3<Double>?
    private var samplesSinceAxis = 0
    private var filtered = 0.0
    /// `true` dopo essere scesi sotto −soglia: la prossima risalita è una ripetizione.
    private var armed = false

    static let windowSize = 100
    static let axisRefresh = 25
    /// Più rapido di così non è una ripetizione, è un sobbalzo.
    static let minInterval: TimeInterval = 0.6
    private static let smoothing = 0.25

    init(sensitivity: Double = 1) {
        self.sensitivity = sensitivity
    }

    /// Soglia in g.
    var threshold: Double { 0.05 / max(sensitivity, 0.1) }

    /// Aggiunge un campione; `true` se ha appena chiuso una ripetizione.
    @discardableResult
    mutating func add(_ acceleration: SIMD3<Double>, at time: TimeInterval) -> Bool {
        window.append(acceleration)
        if window.count > Self.windowSize { window.removeFirst() }
        samplesSinceAxis += 1

        // L'asse si aggiorna finché non arriva la prima ripetizione, poi resta fermo:
        // cambiarlo a metà serie confonderebbe l'isteresi.
        if reps == 0, window.count >= Self.axisRefresh, axis == nil || samplesSinceAxis >= Self.axisRefresh {
            axis = Self.principalAxis(of: window)
            samplesSinceAxis = 0
        }
        guard let axis else { return false }

        filtered += Self.smoothing * (simd_dot(acceleration, axis) - filtered)

        if filtered < -threshold { armed = true }
        guard armed, filtered > threshold else { return false }
        if let lastRepAt, time - lastRepAt < Self.minInterval { return false }
        armed = false
        reps += 1
        lastRepAt = time
        return true
    }

    /// Direzione di massima varianza (iterazione di potenza sulla covarianza 3×3),
    /// con il segno fissato: la componente più grande è positiva.
    static func principalAxis(of samples: [SIMD3<Double>]) -> SIMD3<Double>? {
        guard samples.count > 1 else { return nil }
        let mean = samples.reduce(SIMD3<Double>(repeating: 0), +) / Double(samples.count)
        var covariance = simd_double3x3()
        for sample in samples {
            let d = sample - mean
            covariance += simd_double3x3(columns: (d * d.x, d * d.y, d * d.z))
        }
        var vector = SIMD3<Double>(1, 1, 1)
        for _ in 0..<20 {
            let next = covariance * vector
            let length = simd_length(next)
            guard length > 1e-12 else { return nil }
            vector = next / length
        }
        let largest = [vector.x, vector.y, vector.z].max { abs($0) < abs($1) } ?? 1
        return largest < 0 ? -vector : vector
    }
}
