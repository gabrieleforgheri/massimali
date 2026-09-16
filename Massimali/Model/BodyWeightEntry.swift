import Foundation
import SwiftData

/// Una pesata. Come per i carichi, il peso è **sempre in chilogrammi**.
@Model
final class BodyWeightEntry {
    var uuid: UUID = UUID()
    var date: Date = Date()
    var weight: Double = 0
    /// `true` se arriva dall'app Salute invece che dall'inserimento manuale.
    var fromHealth: Bool = false

    init(weight: Double, date: Date = Date(), fromHealth: Bool = false) {
        self.uuid = UUID()
        self.weight = weight
        self.date = date
        self.fromHealth = fromHealth
    }
}
