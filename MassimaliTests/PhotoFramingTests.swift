import XCTest
@testable import Massimali

final class PhotoFramingTests: XCTestCase {

    /// Una foto 4:3 dentro un quadrato da 100 sborda di 33,3 punti in orizzontale.
    func testWideImageOverflowsHorizontally() {
        let overflow = PhotoFraming.overflow(imageAspect: 4.0 / 3.0, side: 100)
        XCTAssertEqual(overflow, 33.33, accuracy: 0.01)
        XCTAssertFalse(PhotoFraming.isVertical(imageAspect: 4.0 / 3.0))
    }

    /// Una foto 3:4 sborda della stessa quantità, ma in verticale.
    func testTallImageOverflowsVertically() {
        let overflow = PhotoFraming.overflow(imageAspect: 3.0 / 4.0, side: 100)
        XCTAssertEqual(overflow, 33.33, accuracy: 0.01)
        XCTAssertTrue(PhotoFraming.isVertical(imageAspect: 3.0 / 4.0))
    }

    func testSquareImageDoesNotOverflow() {
        XCTAssertEqual(PhotoFraming.overflow(imageAspect: 1, side: 100), 0, accuracy: 0.0001)
    }

    /// Al centro non si sposta nulla; agli estremi si arriva a metà dello sbordo,
    /// che è il punto oltre il quale comparirebbe il vuoto.
    func testOffsetEndpoints() {
        let aspect: CGFloat = 3.0 / 4.0
        XCTAssertEqual(PhotoFraming.offsetPoints(normalized: 0, imageAspect: aspect, side: 100), 0, accuracy: 0.001)
        XCTAssertEqual(PhotoFraming.offsetPoints(normalized: 1, imageAspect: aspect, side: 100), 16.67, accuracy: 0.01)
        XCTAssertEqual(PhotoFraming.offsetPoints(normalized: -1, imageAspect: aspect, side: 100), -16.67, accuracy: 0.01)
    }

    /// Trascinare oltre il limite non deve scoprire il bordo.
    func testOffsetIsClamped() {
        let aspect: CGFloat = 3.0 / 4.0
        let beyond = PhotoFraming.offsetPoints(normalized: 5, imageAspect: aspect, side: 100)
        let atLimit = PhotoFraming.offsetPoints(normalized: 1, imageAspect: aspect, side: 100)
        XCTAssertEqual(beyond, atLimit, accuracy: 0.001)

        let below = PhotoFraming.offsetPoints(normalized: -9, imageAspect: aspect, side: 100)
        XCTAssertEqual(below, -atLimit, accuracy: 0.001)
    }

    /// Trascinare per tutto lo sbordo disponibile deve portare da 0 al limite.
    func testDragAcrossFullOverflowReachesTheLimit() {
        let aspect: CGFloat = 3.0 / 4.0
        let side: CGFloat = 200
        let half = PhotoFraming.overflow(imageAspect: aspect, side: side) / 2
        let delta = PhotoFraming.normalizedDelta(dragPoints: half, imageAspect: aspect, side: side)
        XCTAssertEqual(delta, 1, accuracy: 0.001)
    }

    /// Su un'immagine quadrata non c'è margine: trascinare non deve fare nulla
    /// né produrre divisioni per zero.
    func testDragOnSquareImageDoesNothing() {
        let delta = PhotoFraming.normalizedDelta(dragPoints: 50, imageAspect: 1, side: 100)
        XCTAssertEqual(delta, 0)
    }

    func testDegenerateInputsAreSafe() {
        XCTAssertEqual(PhotoFraming.overflow(imageAspect: 0, side: 100), 0)
        XCTAssertEqual(PhotoFraming.overflow(imageAspect: 1.5, side: 0), 0)
        XCTAssertEqual(PhotoFraming.normalizedDelta(dragPoints: 10, imageAspect: 0, side: 100), 0)
    }
}
