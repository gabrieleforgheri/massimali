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

    func makeUIViewController(context: Context) -> Host {
        let host = Host()
        host.items = items
        host.onComplete = onComplete
        return host
    }

    func updateUIViewController(_ host: Host, context: Context) {}

    // Presentare in `viewDidAppear` (invece che in `makeUIViewController`/`updateUIViewController`)
    // garantisce che il controller sia già agganciato alla finestra: presentare prima fallisce
    // in silenzio e lascia la vista vuota (schermo grigio).
    final class Host: UIViewController {
        var items: [Any] = []
        var onComplete: ((Bool) -> Void)?
        private var didPresent = false

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            guard !didPresent else { return }
            didPresent = true

            let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activity.completionWithItemsHandler = { [weak self] _, completed, _, _ in
                self?.onComplete?(completed)
            }
            activity.popoverPresentationController?.sourceView = view
            present(activity, animated: true)
        }
    }
}
