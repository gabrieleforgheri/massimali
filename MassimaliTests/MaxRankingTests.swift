import XCTest
@testable import Massimali

/// La regola che decide cos'è "il massimo fatto sul macchinario".
final class MaxRankingTests: XCTestCase {

    func testFirstPerformanceAlwaysWins() {
        XCTAssertTrue(MaxRanking.beats(weight: 40, reps: 1, than: nil))
        XCTAssertFalse(MaxRanking.beats(weight: 0, reps: 5, than: nil))
        XCTAssertFalse(MaxRanking.beats(weight: 40, reps: 0, than: nil))
    }

    func testHeavierWins() {
        XCTAssertTrue(MaxRanking.beats(weight: 85, reps: 3, than: (80, 8)))
        XCTAssertFalse(MaxRanking.beats(weight: 75, reps: 12, than: (80, 8)))
    }

    func testSameWeightMoreRepsWins() {
        XCTAssertTrue(MaxRanking.beats(weight: 80, reps: 8, than: (80, 5)))
        XCTAssertFalse(MaxRanking.beats(weight: 80, reps: 5, than: (80, 8)))
        XCTAssertFalse(MaxRanking.beats(weight: 80, reps: 8, than: (80, 8)))
    }

    /// Mezzo grammo di differenza non è un record: sarebbe solo un arrotondamento.
    func testRoundingIsNotARecord() {
        XCTAssertFalse(MaxRanking.beats(weight: 80.005, reps: 5, than: (80, 5)))
        XCTAssertTrue(MaxRanking.beats(weight: 80.5, reps: 5, than: (80, 5)))
    }
}
