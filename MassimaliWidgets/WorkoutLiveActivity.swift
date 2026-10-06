import ActivityKit
import SwiftUI
import WidgetKit

// ponytail: tinta fissa (il lime di default), non l'accento scelto nelle
// impostazioni. Per seguirlo basta passarlo negli attributi.
private let liftTint = Color(red: 0.72, green: 0.94, blue: 0.30)

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            LockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.6))
                .activitySystemActionForegroundColor(liftTint)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        timer(context)
                    } icon: {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .foregroundStyle(liftTint)
                    }
                    .font(.system(.title3, design: .rounded).weight(.bold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("\(context.state.sets)")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                        Text("serie")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.exercise.isEmpty ? "Allenamento in corso" : context.state.exercise)
                            .lineLimit(1)
                        Spacer()
                        Text(context.state.volume)
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
            } compactLeading: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(liftTint)
            } compactTrailing: {
                timer(context)
                    .frame(width: 44)
                    .foregroundStyle(liftTint)
            } minimal: {
                Image(systemName: "figure.strengthtraining.traditional")
                    .foregroundStyle(liftTint)
            }
            .keylineTint(liftTint)
        }
    }
}

/// Durante il recupero conta alla rovescia, altrimenti mostra la durata della sessione.
// ponytail: a recupero finito con l'app in background resta su 0:00 finché l'app
// non aggiorna l'attività; per tornare da solo alla durata servirebbe un push.
@ViewBuilder
private func timer(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
    if let restEnd = context.state.restEnd {
        Text(timerInterval: Date.now...max(restEnd, .now), countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    } else {
        Text(timerInterval: context.attributes.startDate...Date.distantFuture, countsDown: false)
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
    }
}

private struct LockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(liftTint)
                .frame(width: 44, height: 44)
                .background(liftTint.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(context.state.exercise.isEmpty ? "Allenamento in corso" : context.state.exercise)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                Text(context.state.restEnd == nil
                     ? "\(context.state.sets) serie · \(context.state.volume)"
                     : "Recupero · \(context.state.sets) serie")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            timer(context)
                .font(.system(.title2, design: .rounded).weight(.bold))
                .foregroundStyle(liftTint)
                .frame(maxWidth: 90, alignment: .trailing)
        }
        .padding(16)
    }
}
