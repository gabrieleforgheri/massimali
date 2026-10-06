import XCTest
@testable import Massimali

final class PlatesTests: XCTestCase {

    private let standard: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]

    func testBarbellUsesFewestPlates() {
        let load = Plates.load(total: 102.5, bar: 20, plates: standard)
        XCTAssertEqual(load.perSide, [25, 15, 1.25])
        XCTAssertEqual(load.leftover, 0)
    }

    func testPlateLoadedHasNoBar() {
        let load = Plates.load(total: 90, bar: 0, plates: standard)
        XCTAssertEqual(load.perSide, [25, 20])
    }

    func testMissingPlatesLeaveALeftover() {
        let load = Plates.load(total: 65, bar: 20, plates: [20, 10, 5])
        XCTAssertEqual(load.perSide, [20])
        XCTAssertEqual(load.leftover, 2.5)
    }

    func testOnlyTheBar() {
        XCTAssertEqual(Plates.load(total: 20, bar: 20, plates: standard).perSide, [])
        XCTAssertEqual(Plates.load(total: 15, bar: 20, plates: standard).perSide, [])
    }
}
