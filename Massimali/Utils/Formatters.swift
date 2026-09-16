import Foundation

enum Fmt {

    /// Peso formattato nell'unità scelta, es. "82,5 kg".
    static func weight(_ kilograms: Double, unit: WeightUnit, includeSymbol: Bool = true) -> String {
        let value = unit.fromKilograms(kilograms)
        // Due decimali: un disco da 1,25 kg deve leggersi 1,25, non 1,3.
        let number = value.formatted(.number.precision(.fractionLength(0...2)))
        return includeSymbol ? "\(number) \(unit.symbol)" : number
    }

    /// Solo il numero, senza simbolo, per i display grandi.
    static func weightValue(_ kilograms: Double, unit: WeightUnit) -> String {
        weight(kilograms, unit: unit, includeSymbol: false)
    }

    /// Volume totale: sopra la tonnellata passa a "12,4 t" per non riempire la riga di cifre.
    static func volume(_ kilograms: Double, unit: WeightUnit) -> String {
        let value = unit.fromKilograms(kilograms)
        if value >= 1000 {
            let tons = value / 1000
            return "\(tons.formatted(.number.precision(.fractionLength(0...1)))) \(unit == .kg ? "t" : "klb")"
        }
        return "\(value.formatted(.number.precision(.fractionLength(0)))) \(unit.symbol)"
    }

    /// Variazione percentuale con segno, es. "+4,2%".
    static func delta(_ percent: Double) -> String {
        let sign = percent > 0 ? "+" : ""
        return sign + percent.formatted(.number.precision(.fractionLength(0...1))) + "%"
    }

    static func date(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).year())
    }

    static func shortDate(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated))
    }

    static func dateTime(_ date: Date) -> String {
        date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
    }

    /// Data relativa e leggibile: "Oggi", "Ieri", altrimenti la data breve.
    static func relativeDay(_ date: Date, calendar: Calendar = .current) -> String {
        if calendar.isDateInToday(date) { return "Oggi" }
        if calendar.isDateInYesterday(date) { return "Ieri" }
        return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    static func duration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval.rounded()) / 60)
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }

    /// "80 kg × 5" — la riga base di una serie.
    static func setLine(weight: Double, reps: Int, unit: WeightUnit) -> String {
        "\(Self.weight(weight, unit: unit)) × \(reps)"
    }
}
