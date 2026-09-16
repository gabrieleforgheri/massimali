import SwiftUI

/// Avviso in cima alla schermata, per le due cose che possono farti perdere i dati:
/// la firma che scade e il backup che non fai da troppo.
struct WarningBanner: View {
    let symbol: String
    let title: String
    let message: String
    var tint: Color = .orange
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        GlassCard(padding: 14, tint: tint) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(Theme.rounded(14, .bold))
                        .foregroundStyle(Theme.textPrimary)
                    Text(message)
                        .font(Theme.rounded(12, .medium))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let actionTitle, let action {
                        Button(actionTitle, action: action)
                            .font(Theme.rounded(13, .bold))
                            .foregroundStyle(tint)
                            .padding(.top, 4)
                    }
                }

                Spacer(minLength: 0)
            }
        }
    }
}
