import XCTest
import simd
@testable import Massimali

final class RepCounterTests: XCTestCase {

    /// Rumore deterministico in [−amplitude, amplitude].
    private struct Noise {
        var state: UInt64 = 42
        mutating func next(_ amplitude: Double) -> Double {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return (Double(state >> 11) / Double(1 << 53) * 2 - 1) * amplitude
        }
    }

    /// `count` ripetizioni lente lungo `direction`: si parte fermi in basso, come un curl.
    private func count(
        reps count: Int,
        amplitude: Double,
        direction: SIMD3<Double>,
        period: Double = 2.5,
        noise: Double = 0.02,
        sensitivity: Double = 1
    ) -> Int {
        var counter = RepCounter(sensitivity: sensitivity)
        var rng = Noise()
        let axis = simd_normalize(direction)
        let rate = 50.0
        let total = Double(count) * period + 1
        for i in 0..<Int(total * rate) {
            let t = Double(i) / rate
            let signal = t < Double(count) * period ? amplitude * cos(2 * .pi * t / period) : 0
            let sample = axis * signal + SIMD3(rng.next(noise), rng.next(noise), rng.next(noise))
            counter.add(sample, at: t)
        }
        return counter.reps
    }

    func testVerticalRepsAreCounted() {
        XCTAssertEqual(count(reps: 10, amplitude: 0.15, direction: [0, 0, 1]), 10)
    }

    /// Rematore o croce: il movimento è orizzontale e in diagonale rispetto agli assi.
    func testDiagonalRepsAreCounted() {
        XCTAssertEqual(count(reps: 8, amplitude: 0.15, direction: [1, 1, 0.3]), 8)
    }

    func testStillWristCountsNothing() {
        XCTAssertEqual(count(reps: 10, amplitude: 0, direction: [0, 0, 1], noise: 0.03), 0)
    }

    /// La sensibilità è la manopola di calibrazione: movimenti piccoli contano solo se alzata.
    func testSensitivityControlsSmallMovements() {
        XCTAssertEqual(count(reps: 10, amplitude: 0.04, direction: [0, 0, 1], noise: 0.005), 0)
        XCTAssertEqual(count(reps: 10, amplitude: 0.04, direction: [0, 0, 1], noise: 0.005, sensitivity: 2), 10)
    }
}
