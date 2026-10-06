import SwiftUI

struct ContentView: View {
    @Environment(WatchModel.self) private var model

    var body: some View {
        if let exercise = model.exercise {
            ExerciseView(exercise: exercise)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "iphone")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                Text("Apri un esercizio nella sessione sull'iPhone.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

private struct ExerciseView: View {
    @Environment(WatchModel.self) private var model
    let exercise: WatchExercise

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(spacing: 8) {
                Text(exercise.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(model.displayWeight(model.weight))
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .focusable()
                    .digitalCrownRotation(
                        $model.weight,
                        from: 0,
                        through: 500,
                        by: max(exercise.step, 0.5),
                        sensitivity: .low,
                        isContinuous: false,
                        isHapticFeedbackEnabled: true
                    )

                Text("\(model.reps)")
                    .font(.system(size: 54, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())

                HStack {
                    Button { if model.reps > 0 { model.reps -= 1 } } label: { Image(systemName: "minus") }
                    Button { model.reps += 1 } label: { Image(systemName: "plus") }
                }

                Button("Registra") { model.send() }
                    .tint(.green)
                    .disabled(model.reps == 0)

                if let last = model.lastSent {
                    Text("Registrata: \(model.displayWeight(last.weight)) × \(last.reps)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Massimali")
    }
}
