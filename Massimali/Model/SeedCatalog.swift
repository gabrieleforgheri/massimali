import Foundation
import SwiftData

/// Catalogo dei macchinari e degli esercizi tipici di una palestra attrezzata,
/// inserito al primo avvio e ripristinabile dalle impostazioni.
///
/// È volutamente abbondante: copre selectorized, plate loaded, cavi, bilancieri,
/// manubri e corpo libero. Quello che non hai in palestra si archivia con uno
/// swipe e sparisce dalle liste senza perdere nulla.
enum SeedCatalog {

    struct Entry {
        let name: String
        let group: MuscleGroup
        /// Incremento tipico del carico su quella macchina/bilanciere, in kg.
        let step: Double
        /// Promemoria sull'esecuzione, per gli attrezzi che si prestano a equivoci.
        var notes: String = ""
    }

    static let entries: [Entry] = petto + schiena + gambe + spalle + braccia + core

    // MARK: - Petto

    static let petto: [Entry] = [
        Entry(name: "Chest Press", group: .petto, step: 5),
        Entry(name: "Chest Press Plate Loaded", group: .petto, step: 5,
              notes: "Dischi da caricare a mano, uno per lato."),
        Entry(name: "Pectoral Machine", group: .petto, step: 5,
              notes: "La butterfly: seduto, chiudi le braccia davanti al petto."),
        Entry(name: "Panca Piana Bilanciere", group: .petto, step: 2.5),
        Entry(name: "Panca Piana Manubri", group: .petto, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Panca Inclinata Bilanciere", group: .petto, step: 2.5),
        Entry(name: "Panca Inclinata Manubri", group: .petto, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Panca Declinata", group: .petto, step: 2.5),
        Entry(name: "Panca Piana al Multipower", group: .petto, step: 2.5,
              notes: "Il bilanciere guidato dai binari verticali."),
        Entry(name: "Croci ai Cavi", group: .petto, step: 2.5,
              notes: "In piedi fra due puleggie alte, chiudi le braccia davanti."),
        Entry(name: "Croci su Panca Manubri", group: .petto, step: 2),
        Entry(name: "Pullover con Manubrio", group: .petto, step: 2.5),
        Entry(name: "Dip alle Parallele", group: .petto, step: 2.5,
              notes: "A corpo libero: segna l'eventuale zavorra in cintura."),
        Entry(name: "Dip Machine Assistita", group: .petto, step: 5,
              notes: "Il carico è l'assistenza: più peso = più aiuto."),
        Entry(name: "Piegamenti", group: .petto, step: 2.5,
              notes: "A corpo libero: segna l'eventuale zavorra.")
    ]

    // MARK: - Schiena

    static let schiena: [Entry] = [
        Entry(name: "Lat Machine", group: .schiena, step: 5),
        Entry(name: "Lat Machine Presa Stretta", group: .schiena, step: 5,
              notes: "Con il triangolo o la presa supina."),
        Entry(name: "Lat Machine a un Braccio", group: .schiena, step: 5,
              notes: "Il carico è per braccio."),
        Entry(name: "Pulley Basso", group: .schiena, step: 5,
              notes: "Seduto, tirata orizzontale al cavo basso."),
        Entry(name: "Rematore Machine", group: .schiena, step: 5),
        Entry(name: "Rematore Plate Loaded", group: .schiena, step: 5,
              notes: "Braccia orizzontali, dischi da caricare a mano."),
        Entry(name: "Rematore ai Cavi", group: .schiena, step: 5),
        Entry(name: "Rematore ai Cavi a un Braccio", group: .schiena, step: 5,
              notes: "Panca sotto la puleggia, seduto al contrario, tirata a mezza altezza un braccio per volta. Il carico è per braccio."),
        Entry(name: "Rematore Bilanciere", group: .schiena, step: 2.5),
        Entry(name: "Rematore con Manubrio", group: .schiena, step: 2,
              notes: "Un ginocchio sulla panca, il carico è per braccio."),
        Entry(name: "Rematore T-Bar", group: .schiena, step: 5),
        Entry(name: "Pullover Machine", group: .schiena, step: 5),
        Entry(name: "Trazioni alla Sbarra", group: .schiena, step: 2.5,
              notes: "A corpo libero: segna l'eventuale zavorra in cintura."),
        Entry(name: "Trazioni Assistite", group: .schiena, step: 5,
              notes: "Il gravitron: il carico è l'assistenza, più peso = più aiuto."),
        Entry(name: "Stacco da Terra", group: .schiena, step: 5),
        Entry(name: "Stacco Rumeno", group: .schiena, step: 2.5),
        Entry(name: "Good Morning", group: .schiena, step: 2.5),
        Entry(name: "Iperestensioni", group: .schiena, step: 2.5,
              notes: "Panca a 45° o orizzontale: segna l'eventuale disco al petto."),
        Entry(name: "Face Pull ai Cavi", group: .schiena, step: 2.5)
    ]

    // MARK: - Gambe

    static let gambe: [Entry] = [
        Entry(name: "Leg Press 45°", group: .gambe, step: 10),
        Entry(name: "Leg Press Orizzontale", group: .gambe, step: 5),
        Entry(name: "Leg Extension", group: .gambe, step: 5),
        Entry(name: "Leg Curl Seduto", group: .gambe, step: 5),
        Entry(name: "Leg Curl Sdraiato", group: .gambe, step: 5),
        Entry(name: "Squat con Bilanciere", group: .gambe, step: 2.5),
        Entry(name: "Front Squat", group: .gambe, step: 2.5),
        Entry(name: "Squat al Multipower", group: .gambe, step: 2.5),
        Entry(name: "Hack Squat", group: .gambe, step: 10),
        Entry(name: "Pressa a Cuneo", group: .gambe, step: 10),
        Entry(name: "Affondi con Manubri", group: .gambe, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Affondi al Multipower", group: .gambe, step: 2.5),
        Entry(name: "Bulgarian Split Squat", group: .gambe, step: 2,
              notes: "Piede posteriore sulla panca, il carico è per manubrio."),
        Entry(name: "Step Up", group: .gambe, step: 2),
        Entry(name: "Stacco a Gambe Tese", group: .gambe, step: 2.5),
        Entry(name: "Hip Thrust", group: .gambe, step: 5,
              notes: "Schiena appoggiata alla panca, bilanciere sul bacino."),
        Entry(name: "Glute Machine", group: .gambe, step: 5,
              notes: "La slanciata indietro, il carico è per gamba."),
        Entry(name: "Adductor Machine", group: .gambe, step: 5,
              notes: "Seduto, chiudi le gambe contro i cuscinetti."),
        Entry(name: "Abductor Machine", group: .gambe, step: 5,
              notes: "Seduto, apri le gambe contro i cuscinetti."),
        Entry(name: "Calf Machine in Piedi", group: .gambe, step: 5),
        Entry(name: "Calf Machine Seduto", group: .gambe, step: 5),
        Entry(name: "Calf alla Pressa", group: .gambe, step: 10)
    ]

    // MARK: - Spalle

    static let spalle: [Entry] = [
        Entry(name: "Shoulder Press", group: .spalle, step: 5),
        Entry(name: "Shoulder Press Plate Loaded", group: .spalle, step: 5,
              notes: "Dischi da caricare a mano, uno per lato."),
        Entry(name: "Lento Avanti Bilanciere", group: .spalle, step: 2.5),
        Entry(name: "Lento Avanti Manubri", group: .spalle, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Lento Avanti al Multipower", group: .spalle, step: 2.5),
        Entry(name: "Arnold Press", group: .spalle, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Alzate Laterali", group: .spalle, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Alzate Laterali ai Cavi", group: .spalle, step: 2.5,
              notes: "Il carico è per braccio."),
        Entry(name: "Alzate Laterali Machine", group: .spalle, step: 5),
        Entry(name: "Alzate Frontali", group: .spalle, step: 2),
        Entry(name: "Reverse Butterfly", group: .spalle, step: 5,
              notes: "La pectoral machine al contrario, per i deltoidi posteriori."),
        Entry(name: "Alzate Posteriori su Panca", group: .spalle, step: 2),
        Entry(name: "Tirate al Mento", group: .spalle, step: 2.5),
        Entry(name: "Scrollate Bilanciere", group: .spalle, step: 5),
        Entry(name: "Scrollate Manubri", group: .spalle, step: 2,
              notes: "Il carico è per manubrio.")
    ]

    // MARK: - Braccia

    static let braccia: [Entry] = [
        Entry(name: "Curl Bilanciere", group: .braccia, step: 2.5),
        Entry(name: "Curl Bilanciere EZ", group: .braccia, step: 2.5),
        Entry(name: "Curl Manubri", group: .braccia, step: 2,
              notes: "Il carico è per manubrio."),
        Entry(name: "Curl Alternato", group: .braccia, step: 2),
        Entry(name: "Curl Martello", group: .braccia, step: 2),
        Entry(name: "Curl Machine", group: .braccia, step: 5),
        Entry(name: "Panca Scott", group: .braccia, step: 2.5,
              notes: "Braccia appoggiate al leggio inclinato."),
        Entry(name: "Curl ai Cavi", group: .braccia, step: 2.5),
        Entry(name: "Curl Concentrato", group: .braccia, step: 2,
              notes: "Seduto, gomito appoggiato all'interno coscia."),
        Entry(name: "Pushdown ai Cavi", group: .braccia, step: 2.5,
              notes: "Con la barra o la corda al cavo alto."),
        Entry(name: "French Press Bilanciere", group: .braccia, step: 2.5),
        Entry(name: "French Press Manubri", group: .braccia, step: 2),
        Entry(name: "Triceps Machine", group: .braccia, step: 5),
        Entry(name: "Panca Stretta", group: .braccia, step: 2.5,
              notes: "Panca piana con presa stretta, per i tricipiti."),
        Entry(name: "Kickback ai Cavi", group: .braccia, step: 2.5,
              notes: "Il carico è per braccio."),
        Entry(name: "Curl ai Polsi", group: .braccia, step: 2.5,
              notes: "Per gli avambracci.")
    ]

    // MARK: - Core

    static let core: [Entry] = [
        Entry(name: "Crunch Machine", group: .core, step: 5),
        Entry(name: "Cable Crunch", group: .core, step: 5,
              notes: "In ginocchio davanti al cavo alto, con la corda."),
        Entry(name: "Rotary Torso", group: .core, step: 5,
              notes: "Seduto, ruoti il busto contro il carico."),
        Entry(name: "Sedia Romana", group: .core, step: 2.5,
              notes: "Il castello: appeso sugli avambracci, porti le ginocchia al petto."),
        Entry(name: "Leg Raise alla Sbarra", group: .core, step: 2.5),
        Entry(name: "Panca Addominali Inclinata", group: .core, step: 2.5,
              notes: "Segna l'eventuale disco tenuto al petto."),
        Entry(name: "Crunch a Terra", group: .core, step: 2.5),
        Entry(name: "Russian Twist", group: .core, step: 2),
        Entry(name: "Side Bend con Manubrio", group: .core, step: 2),
        Entry(name: "Ab Wheel", group: .core, step: 2.5),
        Entry(name: "Plank", group: .core, step: 2.5,
              notes: "A corpo libero: qui conviene segnare i secondi al posto delle ripetizioni.")
    ]

    /// Inserisce il catalogo nel contesto indicato. Non salva: pensaci tu fuori.
    @discardableResult
    static func insert(into context: ModelContext, startingAt startIndex: Int = 0) -> [Exercise] {
        var created: [Exercise] = []
        for (offset, entry) in entries.enumerated() {
            let exercise = Exercise(
                name: entry.name,
                muscleGroup: entry.group,
                incrementStep: entry.step,
                notes: entry.notes,
                sortIndex: startIndex + offset
            )
            context.insert(exercise)
            created.append(exercise)
        }
        return created
    }
}
