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

    /// Su una leg press da 10 kg non ha senso suggerire 47,5 kg.
    func testWeightsAreRoundedDownToMachineStep() {
        let plan = Warmup.plan(base: 119, step: 10)
        XCTAssertEqual(plan.map(\.weight), [40, 70, 90])

        let fine = Warmup.plan(base: 119, step: 2.5)
        XCTAssertEqual(fine.map(\.weight), [47.5, 70, 95])
    }

    /// Con massimali piccoli l'arrotondamento non deve mai produrre zero.
    func testNeverSuggestsZero() {
        let plan = Warmup.plan(base: 8, step: 5)
        XCTAssertEqual(plan.first?.weight, 5)
        XCTAssertTrue(plan.allSatisfy { $0.weight >= 5 })
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
