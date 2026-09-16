import Foundation

/// Legge la scadenza del profilo con cui l'app è stata firmata.
///
/// Con un Apple ID gratuito il certificato dura 7 giorni: passati quelli l'app
/// non si apre più. La data sta dentro `embedded.mobileprovision`, che è un file
/// CMS firmato con un plist XML in mezzo: invece di tirare in ballo Security per
/// decodificare il CMS, si ritaglia il plist e lo si legge.
///
/// Sul simulatore il file non esiste: tutto restituisce `nil` e l'interfaccia
/// semplicemente non mostra nulla.
enum Provisioning {

    static var expirationDate: Date? {
        guard let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8))
        else { return nil }

        let plistData = Data(data[start.lowerBound..<end.upperBound])
        let plist = try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)
        return (plist as? [String: Any])?["ExpirationDate"] as? Date
    }

    /// Giorni interi che mancano alla scadenza. Negativo se è già scaduto.
    static func daysRemaining(from now: Date = Date(), calendar: Calendar = .current) -> Int? {
        guard let expirationDate else { return nil }
        return calendar.dateComponents([.day], from: now, to: expirationDate).day
    }

    /// `true` quando conviene avvisare: mancano due giorni o meno.
    static func isExpiringSoon(from now: Date = Date()) -> Bool {
        guard let days = daysRemaining(from: now) else { return false }
        return days <= 2
    }

    /// Frase pronta per l'interfaccia.
    static func statusText(from now: Date = Date()) -> String? {
        guard let expirationDate, let days = daysRemaining(from: now) else { return nil }
        if days < 0 { return "Firma scaduta il \(Fmt.date(expirationDate))" }
        if days == 0 { return "La firma scade oggi" }
        if days == 1 { return "La firma scade domani" }
        return "La firma scade fra \(days) giorni, il \(Fmt.date(expirationDate))"
    }
}
