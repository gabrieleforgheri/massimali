import XCTest
@testable import Massimali

final class ProgressionTests: XCTestCase {

    private let range = 8...12

    func testAllSetsAtTopOfRangeAddsOneStep() {
        let next = Progression.next(lastSession: [(60, 12), (60, 12), (60, 13)], step: 2.5, range: range)
        XCTAssertEqual(next, .init(weight: 62.5, reps: 8))
    }

    func testOneSetShortKeepsWeightAndAddsARep() {
        let next = Progression.next(lastSession: [(60, 12), (60, 10)], step: 2.5, range: range)
        XCTAssertEqual(next, .init(weight: 60, reps: 12))
    }

    /// Le serie più leggere (back-off) non frenano la progressione.
    func testOnlyHeaviestWeightCounts() {
        let next = Progression.next(lastSession: [(60, 12), (50, 6)], step: 2.5, range: range)
        XCTAssertEqual(next, .init(weight: 62.5, reps: 8))
    }

    func testBelowRangeClimbsToTheBottom() {
        let next = Progression.next(lastSession: [(80, 5)], step: 5, range: range)
        XCTAssertEqual(next, .init(weight: 80, reps: 8))
    }

    func testNoSessionNoSuggestion() {
        XCTAssertNil(Progression.next(lastSession: [], step: 2.5, range: range))
    }
}
