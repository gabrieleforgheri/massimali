import XCTest
@testable import Massimali

final class OneRepMaxTests: XCTestCase {

    func testSingleRepReturnsRawWeight() {
        XCTAssertEqual(OneRepMaxFormula.epley.oneRepMax(weight: 100, reps: 1), 100)
        XCTAssertEqual(OneRepMaxFormula.brzycki.oneRepMax(weight: 100, reps: 1), 100)
    }

    func testEpley() {
        // 100 × (1 + 5/30) = 116,66…
        XCTAssertEqual(OneRepMaxFormula.epley.oneRepMax(weight: 100, reps: 5), 116.666, accuracy: 0.01)
        XCTAssertEqual(OneRepMaxFormula.epley.oneRepMax(weight: 80, reps: 10), 106.666, accuracy: 0.01)
    }

    func testBrzycki() {
        // 100 × 36 / (37 − 5) = 112,5
        XCTAssertEqual(OneRepMaxFormula.brzycki.oneRepMax(weight: 100, reps: 5), 112.5, accuracy: 0.01)
    }

    func testInvalidInputs() {
        XCTAssertEqual(OneRepMaxFormula.epley.oneRepMax(weight: 0, reps: 5), 0)
        XCTAssertEqual(OneRepMaxFormula.epley.oneRepMax(weight: 100, reps: 0), 0)
        XCTAssertEqual(OneRepMaxFormula.brzycki.oneRepMax(weight: 100, reps: -3), 0)
    }

    /// A 10 ripetizioni le due formule coincidono: è lì che Brzycki passa a Epley,
    /// quindi il raccordo non deve produrre alcun salto.
    func testFormulasAgreeAtTenReps() {
        XCTAssertEqual(
            OneRepMaxFormula.brzycki.oneRepMax(weight: 60, reps: 10),
            OneRepMaxFormula.epley.oneRepMax(weight: 60, reps: 10),
            accuracy: 0.0001
        )
    }

    /// Oltre le 10 ripetizioni Brzycki esplode: deve ripiegare su Epley e restare crescente.
    func testBrzyckiStaysMonotonicAtHighReps() {
        let formula = OneRepMaxFormula.brzycki
        var previous = 0.0
        for reps in 1...50 {
            let value = formula.oneRepMax(weight: 60, reps: reps)
            XCTAssertGreaterThan(value, previous, "1RM non crescente a \(reps) ripetizioni")
            XCTAssertLessThan(value, 1000)
            previous = value
        }
    }


    func testUnitConversionRoundTrip() {
        let kilograms = 82.5
        let pounds = WeightUnit.lb.fromKilograms(kilograms)
        XCTAssertEqual(pounds, 181.88, accuracy: 0.01)
        XCTAssertEqual(WeightUnit.lb.toKilograms(pounds), kilograms, accuracy: 0.0001)
    }
}
