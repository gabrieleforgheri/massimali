import XCTest
@testable import Massimali

final class WarmupTests: XCTestCase {

    func testRampPercentagesAndReps() {
        let plan = Warmup.plan(base: 100, step: 5)
        XCTAssertEqual(plan.count, 3)
        XCTAssertEqual(plan.map(\.reps), [10, 6, 3])
        XCTAssertEqual(plan.map(\.weight), [40, 60, 80])
        XCTAssertEqual(plan.map(\.percentLabel), ["40%", "60%", "80%"])
    }

    /// Si scende dal massimale di N passi fino al peso più vicino al calcolato.
    func testWeightsAreNearestOnMachineGrid() {
        let plan = Warmup.plan(base: 119, step: 10)
        XCTAssertEqual(plan.map(\.weight), [49, 69, 99])

        let fine = Warmup.plan(base: 120, step: 2.5)
        XCTAssertEqual(fine.map(\.weight), [47.5, 72.5, 95])
    }

    /// Pacco sfalsato (passo 3,75 che non parte da zero): ogni peso suggerito
    /// dev'essere raggiungibile dal massimale scendendo di passi interi.
    func testOffsetStackStaysOnGrid() {
        let base = 50.0, step = 3.75
        for warmup in Warmup.plan(base: base, step: step) {
            let steps = (base - warmup.weight) / step
            XCTAssertEqual(steps, steps.rounded(), accuracy: 0.0001, "\(warmup.weight) fuori griglia")
            XCTAssertLessThanOrEqual(abs(warmup.weight - base * warmup.percent), step / 2 + 0.0001)
        }
    }

    /// Con massimali piccoli non deve mai produrre zero: resta il peso più leggero della griglia.
    func testNeverSuggestsZero() {
        let plan = Warmup.plan(base: 8, step: 5)
        XCTAssertEqual(plan.first?.weight, 3)
        XCTAssertTrue(plan.allSatisfy { $0.weight > 0 })
        XCTAssertEqual(Warmup.nearest(0.5, anchor: 60, step: 3.75), 3.75)
    }

    func testNoMaxMeansNoPlan() {
        XCTAssertTrue(Warmup.plan(base: nil, step: 5).isEmpty)
        XCTAssertTrue(Warmup.plan(base: 0, step: 5).isEmpty)
    }

    func testRampIsNonDecreasing() {
        for base in stride(from: 10.0, through: 300.0, by: 7.5) {
            for step in [1.0, 2.5, 5.0, 10.0] {
                let weights = Warmup.plan(base: base, step: step).map(\.weight)
                XCTAssertEqual(weights, weights.sorted(), "rampa non crescente con massimale \(base) e passo \(step)")
            }
        }
    }
}
