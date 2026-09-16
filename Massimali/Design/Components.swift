import SwiftUI

// MARK: - Chip del gruppo muscolare

struct MuscleGroupChip: View {
    let group: MuscleGroup
    var compact: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: group.symbol)
                .font(.system(size: compact ? 10 : 12, weight: .semibold))
            if !compact {
                Text(group.title.uppercased())
                    .font(Theme.rounded(11, .bold))
                    .tracking(0.6)
            }
        }
        .foregroundStyle(group.tint)
        .padding(.horizontal, compact ? 8 : 10)
        .padding(.vertical, compact ? 5 : 6)
        .background(group.tint.opacity(0.16), in: Capsule())
        .overlay(Capsule().strokeBorder(group.tint.opacity(0.28), lineWidth: 1))
    }
}

// MARK: - Badge

struct PRBadge: View {
    var text: String = "PR"

    var body: some View {
        Text(text)
            .font(Theme.rounded(10, .heavy))
            .tracking(0.8)
            .foregroundStyle(Theme.bg)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Theme.positive, in: Capsule())
    }
}

/// Variazione percentuale colorata, con freccia.
struct DeltaBadge: View {
    let percent: Double

    var body: some View {
        let positive = percent >= 0
        HStack(spacing: 2) {
            Image(systemName: positive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text(Fmt.delta(percent))
                .font(Theme.rounded(11, .bold))
        }
        .foregroundStyle(positive ? Theme.positive : Theme.negative)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background((positive ? Theme.positive : Theme.negative).opacity(0.14), in: Capsule())
    }
}

// MARK: - Tessera statistica

struct StatTile: View {
    let symbol: String
    let title: String
    let value: String
    var caption: String? = nil
    var tint: Color = .white

    var body: some View {
        GlassCard(padding: 14, radius: Theme.radiusSmall) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .bold))
                    Text(title.uppercased())
                        .font(Theme.rounded(10, .bold))
                        .tracking(0.7)
                        .lineLimit(1)
                }
                .foregroundStyle(tint.opacity(0.9))

                Text(value)
                    .font(Theme.display(24))
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                if let caption {
                    Text(caption)
                        .font(Theme.rounded(11, .medium))
                        .foregroundStyle(Theme.textTertiary)
                        .lineLimit(1)
                }
            }
        }
    }
}

// MARK: - Stepper del peso

/// Stepper del carico. Il binding è **sempre in kg**; la conversione nell'unità
/// scelta avviene solo per la visualizzazione e per l'input.
struct WeightStepper: View {
    @Binding var kilograms: Double
    var step: Double
    var unit: WeightUnit
    var tint: Color = .white

    private var displayValue: Binding<Double> {
        Binding(
            get: { unit.fromKilograms(kilograms) },
            set: { kilograms = max(0, unit.toKilograms($0)) }
        )
    }

    private func bump(_ direction: Double) {
        let next = kilograms + direction * step
        kilograms = max(0, (next * 100).rounded() / 100)
        Haptics.tap()
    }

    var body: some View {
        HStack(spacing: 12) {
            StepperButton(symbol: "minus", tint: tint) { bump(-1) }

            VStack(spacing: 0) {
                TextField("0", value: displayValue, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .font(Theme.display(38))
                    .foregroundStyle(Theme.textPrimary)
                Text(unit.symbol)
                    .font(Theme.rounded(12, .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
            .frame(maxWidth: .infinity)

            StepperButton(symbol: "plus", tint: tint) { bump(1) }
        }
    }
}

/// Stepper delle ripetizioni, con scorciatoie ai valori più usati.
struct RepsStepper: View {
    @Binding var reps: Int
    var tint: Color = .white
    var quickValues: [Int] = [1, 3, 5, 8, 10, 12]

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StepperButton(symbol: "minus", tint: tint) {
                    reps = max(1, reps - 1)
                    Haptics.tap()
                }

                VStack(spacing: 0) {
                    Text("\(reps)")
                        .font(Theme.display(38))
                        .foregroundStyle(Theme.textPrimary)
                    Text(reps == 1 ? "ripetizione" : "ripetizioni")
                        .font(Theme.rounded(12, .semibold))
                        .foregroundStyle(Theme.textTertiary)
                }
                .frame(maxWidth: .infinity)

                StepperButton(symbol: "plus", tint: tint) {
                    reps = min(50, reps + 1)
                    Haptics.tap()
                }
            }

            HStack(spacing: 8) {
                ForEach(quickValues, id: \.self) { value in
                    Button {
                        reps = value
                        Haptics.tap()
                    } label: {
                        Text("\(value)")
                            .font(Theme.rounded(13, .bold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                reps == value ? tint.opacity(0.22) : Theme.card,
                                in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                            )
                            .foregroundStyle(reps == value ? tint : Theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private struct StepperButton: View {
    let symbol: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(tint)
                .frame(width: 52, height: 52)
                .background(Theme.cardStrong, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Theme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pulsanti

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color
    var fullWidth: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(16, .bold))
            .foregroundStyle(Theme.bg)
            .padding(.vertical, 15)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .padding(.horizontal, fullWidth ? 0 : 22)
            .background(tint, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.rounded(15, .semibold))
            .foregroundStyle(tint)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(Theme.cardStrong, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.stroke, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Intestazioni

struct SectionHeader: View {
    let title: String
    var trailing: String? = nil

    var body: some View {
        HStack {
            Text(title.uppercased())
                .font(Theme.rounded(11, .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.textTertiary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(Theme.rounded(11, .semibold))
                    .foregroundStyle(Theme.textTertiary)
            }
        }
    }
}
