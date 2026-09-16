import XCTest
import UIKit
@testable import Massimali

final class MachineGlyphTests: XCTestCase {

    private func glyph(_ name: String, _ group: MuscleGroup) -> MachineGlyph {
        MachineGlyph.suggested(for: name, group: group)
    }

    func testRecognisesCommonMachines() {
        XCTAssertEqual(glyph("Leg Press 45°", .gambe), .legPress)
        XCTAssertEqual(glyph("Lat Machine", .schiena), .latPulldown)
        XCTAssertEqual(glyph("Pulley Basso", .schiena), .seatedRow)
        XCTAssertEqual(glyph("Pectoral Machine", .petto), .pecDeck)
        XCTAssertEqual(glyph("Croci ai Cavi", .petto), .cableCross)
        XCTAssertEqual(glyph("Sedia Romana", .core), .romanChair)
        XCTAssertEqual(glyph("Squat al Multipower", .gambe), .smithMachine)
    }

    /// Le voci più specifiche devono vincere su quelle generiche: senza il giusto
    /// ordine "Rematore Bilanciere" finirebbe sul pittogramma del rematore a cavi.
    func testSpecificNamesWinOverGenericOnes() {
        XCTAssertEqual(glyph("Rematore Machine", .schiena), .seatedRow)
        XCTAssertEqual(glyph("Rematore Bilanciere", .schiena), .barbell)
        XCTAssertEqual(glyph("Rematore con Manubrio", .schiena), .dumbbell)
        XCTAssertEqual(glyph("Rematore ai Cavi", .schiena), .cableStation)
        XCTAssertEqual(glyph("Hack Squat", .gambe), .legPress, "hack squat non è un rack")
        XCTAssertEqual(glyph("Squat con Bilanciere", .gambe), .squatRack)
        XCTAssertEqual(glyph("Chest Press Plate Loaded", .petto), .plateLoaded)
    }

    func testIsCaseInsensitive() {
        XCTAssertEqual(glyph("LEG PRESS", .gambe), .legPress)
        XCTAssertEqual(glyph("lat machine presa stretta", .schiena), .latPulldown)
    }

    /// Un nome inventato non deve lasciare l'esercizio senza immagine.
    func testUnknownNameFallsBackToGroup() {
        XCTAssertEqual(glyph("Attrezzo Sconosciuto", .core), .bodyweight)
        XCTAssertEqual(glyph("Attrezzo Sconosciuto", .gambe), .legLever)
        XCTAssertEqual(glyph("Attrezzo Sconosciuto", .schiena), .seatedRow)
        XCTAssertEqual(glyph("", .petto), .seatedPush)
    }

    /// Ogni voce del catalogo deve avere un pittogramma e un disegno non vuoto.
    func testEveryCatalogEntryHasADrawableGlyph() {
        for entry in SeedCatalog.entries {
            let g = MachineGlyph.suggested(for: entry.name, group: entry.group)
            XCTAssertFalse(g.shapes.isEmpty, "\(entry.name) senza disegno")
            XCTAssertFalse(g.title.isEmpty)
        }
    }

    func testEveryGlyphStaysInsideItsBox() {
        for glyph in MachineGlyph.allCases {
            for shape in glyph.shapes {
                let coords: [CGFloat]
                switch shape {
                case let .line(a, b, c, d), let .bar(a, b, c, d):
                    coords = [a, b, c, d]
                case let .solidRect(x, y, w, h):
                    coords = [x, y, x + w, y + h]
                case let .dot(cx, cy, r), let .ring(cx, cy, r):
                    coords = [cx - r, cy - r, cx + r, cy + r]
                }
                for value in coords {
                    XCTAssertGreaterThanOrEqual(value, 0, "\(glyph.rawValue) esce dal riquadro")
                    XCTAssertLessThanOrEqual(value, 1, "\(glyph.rawValue) esce dal riquadro")
                }
            }
        }
    }

    // MARK: - Foto

    private func makeImage(width: CGFloat, height: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { context in
            UIColor.systemBlue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        }
    }

    func testDownscaleCapsTheLongSideAndKeepsAspect() {
        let image = makeImage(width: 3000, height: 2000)
        let resized = ImageStore.downscale(image, maxDimension: 640)
        XCTAssertEqual(resized.size.width, 640, accuracy: 1)
        XCTAssertEqual(resized.size.height, 427, accuracy: 1)
    }

    func testSmallImagesAreNotEnlarged() {
        let image = makeImage(width: 120, height: 80)
        let resized = ImageStore.downscale(image, maxDimension: 640)
        XCTAssertEqual(resized.size.width, 120, accuracy: 1)
        XCTAssertEqual(resized.size.height, 80, accuracy: 1)
    }

    /// Una foto da fotocamera pesa megabyte: dopo la preparazione deve stare
    /// in poche decine di KB, altrimenti il database e i backup esplodono.
    func testPreparedPhotoIsSmall() throws {
        let image = makeImage(width: 3000, height: 2000)
        let data = try XCTUnwrap(ImageStore.prepare(image))
        XCTAssertLessThan(data.count, 300_000)
        XCTAssertNotNil(UIImage(data: data))
    }
}
