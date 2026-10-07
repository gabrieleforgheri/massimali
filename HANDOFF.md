# Handoff — Massimali 1.3 (ottobre 2026)

Stato del lavoro per chi riprende, persona o agente. Il "come funziona" sta nel README;
qui ci sono cosa è stato fatto, cosa è verificato e cosa resta aperto.

## Fatto (un commit per funzionalità, su `main`)

| Funzionalità | Dove | Interruttore |
|---|---|---|
| Riscaldamento sulla griglia del macchinario: dal massimale si scende di N passi fino al peso più vicino al calcolato | `Model/Warmup.swift` | — |
| Esecuzione mono/bilaterale per macchinario (editor, dettaglio, backup) | `Model/Exercise.swift` `isUnilateral` | — |
| Timer di recupero: globale + per macchinario, ±15 s, Live Activity, notifica locale | `Store/RestTimer.swift` | Impostazioni → Allenamento |
| Prossimo carico (doppia progressione, range rip nelle impostazioni) | `Model/Progression.swift` | idem |
| Calcolatore dischi animato (bilanciere / plate loaded, dal pittogramma) | `Model/Plates.swift`, `Design/PlateBarView.swift` | idem |
| App Watch: conta le ripetizioni sulle braccia, vibra, registra la serie sull'iPhone | `MassimaliWatch/`, `WatchShared/`, `Store/WatchBridge.swift` | Impostazioni → Apple Watch |
| Installazione con il Watch dal Mac | `scripts/install_device.sh` | — |

Le serie dall'iPhone e dal Watch passano dallo stesso `RecordService.addSet`.

## Decisioni prese con l'utente

- Riscaldamento: peso **più vicino** a quello calcolato, non per difetto.
- Mono/bilaterale: solo etichetta, più il Watch. Nessun effetto su volume o serie per lato.
  Braccia/gambe si deducono dal gruppo muscolare (`worksLegs`).
- Watch, modalità di default: via (dal telefono o dal Watch) e fine automatica dopo N s
  fermo (default 4). Le altre due: via e fine a mano, tutto automatico. Tutto regolabile.
- Tutte le funzioni nuove si possono disattivare nelle impostazioni.
- **AltStore resta senza Watch; l'utente usa la versione con il Watch installata dal Mac.**

## Perché il Watch non passa da AltStore (verificato, non teoria)

Prove fatte sui dispositivi reali con una build di diagnostica (log `PROBE`):

1. App Watch installata da sola, app iPhone senza `Watch/`: entrambe le parti rispondono
   `watchAppInstalled`/`companionInstalled=false`.
2. App iPhone con `Watch/`: l'iPhone non installa da solo l'app sull'orologio (le build
   di sviluppo non vengono spinte).
3. App iPhone con `Watch/` e **poi** app Watch installata direttamente: collegate.
   Contesto ricevuto, app aperta da HealthKit, serie 42,5 × 7 arrivata all'iPhone.
4. App iPhone sostituita con una senza `Watch/`: il Watch torna a `companionInstalled=false`.

AltSign (`rileytestut/AltSign`, `ALTSigner.mm` + `ldid.cpp` riga ~2240) considera
annidati solo `Frameworks/*.framework` e `PlugIns/*.appex`. Così rifirma l'eseguibile in
`Watch/` senza entitlement e l'installazione fallisce. Si sblocca solo con un account a
pagamento (TestFlight/App Store) o se AltStore risolve le issue #229 e #684.

## Verificato / non verificato

- ✅ Test unitari fino al calcolatore dischi: 66 test verdi (Warmup, Progression, Plates,
  backup con i nuovi campi, ecc.).
- ✅ `RepCounter`: algoritmo provato con uno script sul Mac su segnali sintetici
  (10 rip verticali, 8 diagonali, polso fermo = 0, sensibilità, rip veloci da 1,2 s).
- ✅ Collegamento iPhone ↔ Watch end-to-end sui dispositivi (prova 3 sopra).
- ⚠️ `RepCounterTests.swift` e la suite completa dopo i commit Watch **non sono stati
  eseguiti nel simulatore**: l'utente ha chiesto di non lanciare test (il Mac si blocca).
  L'app iPhone e il Watch compilano.
- ⚠️ **Precisione del conteggio su esercizi veri: da provare in palestra.** La manopola
  è la sensibilità nelle impostazioni. Se sbaglia sistematicamente, il passo successivo è
  una soglia adattiva sull'ampiezza delle prime ripetizioni (commento `ponytail:` in
  `RepCounter.swift`).
- ⚠️ Il riferimento fisso per l'accelerazione (`WatchModel.handle`) usa la trasposta di
  `attitude.rotationMatrix`. Non è verificato che z sia davvero verticale; l'asse
  principale lo rende comunque robusto.
- ⚠️ Live Activity: a recupero finito con l'app in background resta su 0:00 finché l'app
  non la aggiorna (commento `ponytail:`).

## Da sapere prima di toccare qualcosa

- **Non lanciare test o simulatore senza chiedere**: su questo Mac lo bloccano. Per
  controllare che compili, build per `generic/platform=watchOS Simulator` o per il
  dispositivo. Per la logica pura basta uno script `swiftc` sul Mac.
- Il simulatore iPhone 17 Pro del README non esiste più: c'è `iPhone 18 Pro`.
- Bundle id: l'app AltStore è `com.gabrieleforghieri.massimali.HKR6AKCLPA`, il Watch è
  `….HKR6AKCLPA.watchkitapp` (fisso in `project.yml`). Se cambia team va cambiato lì,
  e lo script si ferma se non corrisponde.
- Nessun nuovo entitlement o chiave privacy nell'app iPhone, quindi `docs/apps.json`
  non è cambiato. HealthKit e Motion sono solo nel target Watch, che non va su AltStore.
- Su AltStore è pubblicata la 1.3.1 (tag `v1.3.1`, CI `altstore-release.yml`) **senza Watch**; sui dispositivi dell'utente c'è la 1.3.1 con il Watch, installata con lo script.

## Prossimi passi possibili

1. Prova in palestra del conteggio (curl, spinte, lat machine, rematore) e taratura della
   sensibilità o soglia adattiva.
2. Eseguire la suite di test quando il Mac è libero
   (`xcodebuild test … -destination 'platform=iOS Simulator,name=iPhone 18 Pro'`).
3. Ricordare che aggiornare Massimali da AltStore toglie il Watch: dopo, rilanciare
   `install_device.sh`.
4. Eventuale: countdown del recupero anche sul Watch, vibrazione a fine recupero al polso.
