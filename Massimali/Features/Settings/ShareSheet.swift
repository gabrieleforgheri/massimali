import SwiftUI
import UIKit

/// Foglio di condivisione di sistema.
///
/// Si usa al posto di `ShareLink` perché serve sapere **se** la condivisione è
/// andata in porto: è quella data che alimenta il promemoria "non fai un backup
/// da troppo tempo", e `ShareLink` non riporta nulla al chiamante.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    let onComplete: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onComplete(completed)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
