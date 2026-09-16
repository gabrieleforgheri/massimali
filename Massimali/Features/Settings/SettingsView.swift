import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Exercise.sortIndex) private var exercises: [Exercise]

    @State private var shareURL: URL?
    @State private var showingImporter = false
    @State private var pendingImport: Data?
    @State private var showingImportChoice = false
    @State private var showingEraseConfirm = false
    @State private var showingShare = false
    @State private var healthMessage: String?
    @State private var alert: AlertPayload?

    private struct AlertPayload: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    private var archivedCount: Int { exercises.filter(\.isArchived).count }

    var body: some View {
        @Bindable var settings = settings

        return NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    if settings.needsExportReminder {
                        WarningBanner(
                            symbol: "externaldrive.badge.exclamationmark",
                            title: "Fai un backup",
                            message: exportReminderMessage,
                            actionTitle: "Esporta adesso"
                        ) {
                            refreshShareFile()
                            showingShare = true
                        }
                    }

                    // Unità
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Unità di misura")
                            Picker("Unità", selection: $settings.unit) {
                                ForEach(WeightUnit.allCases) { Text($0.symbol.uppercased()).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            Text("I dati restano sempre salvati in chilogrammi: cambia solo come vengono mostrati.")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    // Formula
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Formula del 1RM stimato")
                            Picker("Formula", selection: $settings.formula) {
                                ForEach(OneRepMaxFormula.allCases) { Text($0.title).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            Text("\(settings.formula.subtitle). Il massimale dell'app resta il carico vero che hai sollevato: questa formula serve solo alla stima scritta in piccolo accanto.")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }

                    // Accento
                    GlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Colore accento")
                            HStack(spacing: 10) {
                                ForEach(AccentPalette.allCases) { palette in
                                    Button {
                                        settings.accent = palette
                                        Haptics.tap()
                                    } label: {
                                        Circle()
                                            .fill(palette.color)
                                            .frame(width: 34, height: 34)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(.white.opacity(settings.accent == palette ? 0.9 : 0), lineWidth: 2)
                                                    .padding(-4)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .accessibilityLabel(palette.title)
                                }
                                Spacer()
                            }
                        }
                    }

                    healthCard
                    backupCard
                    catalogCard
                    infoCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
            .screenBackground(settings.accentColor)
            .navigationTitle("Impostazioni")
            .onAppear(perform: refreshShareFile)
            .sheet(isPresented: $showingShare) {
                if let shareURL {
                    ShareSheet(items: [shareURL]) { completed in
                        if completed {
                            settings.lastExportDate = Date()
                            Haptics.success()
                        }
                    }
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handlePickedFile(result)
            }
            .confirmationDialog(
                "Come importare il backup?",
                isPresented: $showingImportChoice,
                titleVisibility: .visible
            ) {
                Button("Unisci ai dati attuali") { performImport(mode: .merge) }
                Button("Sostituisci tutto", role: .destructive) { performImport(mode: .replace) }
                Button("Annulla", role: .cancel) { pendingImport = nil }
            } message: {
                Text("«Unisci» aggiunge solo ciò che manca. «Sostituisci» cancella i dati attuali e riparte dal file.")
            }
            .confirmationDialog(
                "Cancellare tutti i dati?",
                isPresented: $showingEraseConfirm,
                titleVisibility: .visible
            ) {
                Button("Cancella tutto", role: .destructive) { eraseAll() }
                Button("Annulla", role: .cancel) {}
            } message: {
                Text("Macchinari, massimali e allenamenti verranno eliminati. Esporta un backup prima di procedere.")
            }
            .alert(
                alert?.title ?? "",
                isPresented: Binding(get: { alert != nil }, set: { if !$0 { alert = nil } })
            ) {
                Button("Ok", role: .cancel) {}
            } message: {
                Text(alert?.message ?? "")
            }
        }
    }

    // MARK: - Salute

    private var healthCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "App Salute")

                if HealthService.isAvailable {
                    Toggle(isOn: Binding(
                        get: { settings.healthSyncEnabled },
                        set: { newValue in
                            settings.healthSyncEnabled = newValue
                            if newValue { Task { await connectHealth() } }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sincronizza con Salute")
                                .font(Theme.rounded(15, .semibold))
                            Text("Legge il peso corporeo e registra lì i tuoi allenamenti.")
                                .font(Theme.rounded(11, .medium))
                                .foregroundStyle(Theme.textTertiary)
                        }
                    }
                    .tint(settings.accentColor)

                    if let healthMessage {
                        Text(healthMessage)
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                } else {
                    Text("Salute non è disponibile su questo dispositivo.")
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.textTertiary)
                }
            }
        }
    }

    // MARK: - Backup

    private var backupCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Backup")

                Text("I dati vivono solo su questo iPhone. Esporta un file ogni tanto e tienilo su iCloud Drive: è l'unico modo per non perderli se l'app viene disinstallata.")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.textSecondary)

                Button {
                    refreshShareFile()
                    showingShare = true
                } label: {
                    Label("Esporta backup", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(PrimaryButtonStyle(tint: settings.accentColor))

                Button {
                    showingImporter = true
                } label: {
                    Label("Importa backup", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(SecondaryButtonStyle())

                Divider().overlay(Theme.stroke)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Backup automatico")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(settings.lastBackupDate.map { "Aggiornato \(Fmt.dateTime($0))" } ?? "Non ancora eseguito")
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: "folder")
                        .foregroundStyle(Theme.textTertiary)
                }

                Text("Lo trovi in File › Sul mio iPhone › Massimali › \(BackupService.autoBackupFilename)")
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.textTertiary)

                Divider().overlay(Theme.stroke)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ultimo export fuori dall'app")
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(exportStatusText)
                            .font(Theme.rounded(11, .medium))
                            .foregroundStyle(settings.needsExportReminder ? .orange : Theme.textTertiary)
                    }
                    Spacer()
                    Image(systemName: settings.needsExportReminder ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                        .foregroundStyle(settings.needsExportReminder ? .orange : Theme.positive)
                }
            }
        }
    }

    // MARK: - Catalogo

    private var catalogCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader(title: "Catalogo", trailing: "\(exercises.count) macchinari")

                NavigationLink {
                    CatalogCurationView()
                } label: {
                    HStack {
                        Label("Scegli i macchinari della tua palestra", systemImage: "checklist")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 4)
                }

                Divider().overlay(Theme.stroke)

                NavigationLink {
                    ArchivedExercisesView()
                } label: {
                    HStack {
                        Label("Macchinari archiviati", systemImage: "archivebox")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(archivedCount)")
                            .font(Theme.rounded(13, .medium))
                            .foregroundStyle(Theme.textTertiary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Theme.textTertiary)
                    }
                    .padding(.vertical, 4)
                }

                Divider().overlay(Theme.stroke)

                Button {
                    restoreCatalog()
                } label: {
                    Label("Aggiungi i macchinari mancanti dal catalogo", systemImage: "arrow.clockwise")
                        .font(Theme.rounded(14, .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(settings.accentColor)

                Divider().overlay(Theme.stroke)

                Button(role: .destructive) {
                    showingEraseConfirm = true
                } label: {
                    Label("Cancella tutti i dati", systemImage: "trash")
                        .font(Theme.rounded(14, .semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Theme.negative)
            }
        }
    }

    private var infoCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader(title: "Nota sulla firma")
                Text("L'app è installata con un Apple ID gratuito: il certificato scade dopo 7 giorni e l'app smette di aprirsi. Basta ricollegare l'iPhone al Mac e premere Run in Xcode per rinnovarla — i dati restano al loro posto finché non disinstalli l'app.")
                    .font(Theme.rounded(12, .medium))
                    .foregroundStyle(Theme.textSecondary)
                if let status = Provisioning.statusText() {
                    Divider().overlay(Theme.stroke)
                    HStack(spacing: 8) {
                        Image(systemName: Provisioning.isExpiringSoon() ? "exclamationmark.triangle.fill" : "checkmark.seal")
                            .foregroundStyle(Provisioning.isExpiringSoon() ? .orange : Theme.textTertiary)
                        Text(status)
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(Provisioning.isExpiringSoon() ? .orange : Theme.textSecondary)
                    }
                }

                Text("Massimali 1.0")
                    .font(Theme.rounded(11, .medium))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }

    private func connectHealth() async {
        do {
            try await HealthService.requestAuthorization()
            healthMessage = "Collegato. Concedi i permessi nell'app Salute se non l'hai già fatto."
            Haptics.success()
        } catch {
            settings.healthSyncEnabled = false
            healthMessage = error.localizedDescription
            Haptics.warning()
        }
    }

    private var exportStatusText: String {
        guard let date = settings.lastExportDate else {
            return "Mai esportato"
        }
        let days = settings.daysSinceExport ?? 0
        if days == 0 { return "Oggi" }
        if days == 1 { return "Ieri" }
        return "\(days) giorni fa · \(Fmt.date(date))"
    }

    private var exportReminderMessage: String {
        guard let days = settings.daysSinceExport else {
            return "I dati vivono solo su questo iPhone. Salva il file su iCloud Drive: se disinstalli l'app, è l'unica copia che resta."
        }
        return "Non esporti da \(days) giorni. Se disinstalli l'app, tutto quello che non è uscito da qui si perde."
    }

    // MARK: - Azioni

    private func refreshShareFile() {
        shareURL = try? BackupService.makeShareFile(context: context)
    }

    private func handlePickedFile(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                pendingImport = try Data(contentsOf: url)
                showingImportChoice = true
            } catch {
                alert = AlertPayload(title: "Import non riuscito", message: error.localizedDescription)
            }
        case .failure(let error):
            alert = AlertPayload(title: "Import non riuscito", message: error.localizedDescription)
        }
    }

    private func performImport(mode: RestoreMode) {
        guard let data = pendingImport else { return }
        pendingImport = nil
        do {
            let file = try BackupService.restore(from: data, context: context, mode: mode)
            settings.didSeedCatalog = true
            refreshShareFile()
            Haptics.success()
            alert = AlertPayload(
                title: "Backup importato",
                message: "\(file.exercises.count) macchinari e \(file.workouts.count) allenamenti dal \(Fmt.date(file.exportedAt))."
            )
        } catch {
            Haptics.warning()
            alert = AlertPayload(title: "Import non riuscito", message: error.localizedDescription)
        }
    }

    private func restoreCatalog() {
        let existing = Set(exercises.map { $0.name.lowercased() })
        var nextIndex = (exercises.map(\.sortIndex).max() ?? 0) + 1
        var added = 0

        for entry in SeedCatalog.entries where !existing.contains(entry.name.lowercased()) {
            let exercise = Exercise(
                name: entry.name,
                muscleGroup: entry.group,
                incrementStep: entry.step,
                notes: entry.notes,
                sortIndex: nextIndex
            )
            context.insert(exercise)
            nextIndex += 1
            added += 1
        }

        try? context.save()
        Haptics.commit()
        alert = AlertPayload(
            title: added == 0 ? "Catalogo già completo" : "Catalogo aggiornato",
            message: added == 0
                ? "Tutti i macchinari del catalogo sono già presenti."
                : "Aggiunti \(added) macchinari."
        )
    }

    private func eraseAll() {
        do {
            try context.delete(model: WorkoutSet.self)
            try context.delete(model: Workout.self)
            try context.delete(model: MaxRecord.self)
            try context.delete(model: Exercise.self)
            try context.save()
            settings.didSeedCatalog = false
            Haptics.warning()
        } catch {
            alert = AlertPayload(title: "Errore", message: error.localizedDescription)
        }
    }
}

// MARK: - Archiviati

struct ArchivedExercisesView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppSettings.self) private var settings

    @Query(sort: \Exercise.sortIndex) private var exercises: [Exercise]

    private var archived: [Exercise] { exercises.filter(\.isArchived) }

    var body: some View {
        Group {
            if archived.isEmpty {
                ContentUnavailableView(
                    "Nessun macchinario archiviato",
                    systemImage: "archivebox",
                    description: Text("Gli archiviati spariscono dalle liste ma conservano tutto lo storico.")
                )
            } else {
                List {
                    ForEach(archived) { exercise in
                        HStack(spacing: 12) {
                            Image(systemName: exercise.muscleGroup.symbol)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(exercise.muscleGroup.tint)
                                .frame(width: 30, height: 30)
                                .background(exercise.muscleGroup.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                            Text(exercise.name)
                                .font(Theme.rounded(15, .semibold))
                                .foregroundStyle(Theme.textPrimary)

                            Spacer()

                            Button("Ripristina") {
                                exercise.isArchived = false
                                try? context.save()
                                Haptics.commit()
                            }
                            .font(Theme.rounded(13, .semibold))
                            .foregroundStyle(settings.accentColor)
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .glassSurface(radius: Theme.radiusSmall)
                        .plainListRow()
                    }
                }
                .listStyle(.plain)
            }
        }
        .screenBackground(settings.accentColor)
        .navigationTitle("Archiviati")
        .navigationBarTitleDisplayMode(.inline)
    }
}
