import SwiftUI

struct ContentView: View {
    @Environment(SimulationEngine.self) private var engine
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        @Bindable var engine = engine

        VStack(spacing: 16) {
            Text("Life3D")
                .font(.title)

            Text("Gen \(engine.generation) | Alive: \(engine.grid.aliveCount)")
                .font(.headline)
                .monospacedDigit()

            HStack(spacing: 16) {
                Button(engine.isRunning ? "Pause" : "Play") {
                    if engine.isRunning {
                        engine.pause()
                    } else {
                        engine.start()
                    }
                }

                Button("Step") {
                    engine.step()
                }
                .disabled(engine.isRunning)

                Menu("Pattern") {
                    ForEach(SimulationEngine.Pattern.allCases) { pattern in
                        Button(pattern.rawValue) {
                            engine.reset(pattern: pattern)
                        }
                    }
                }

                HStack(spacing: 4) {
                    Text("Speed:")
                        .font(.caption2)
                    Text("\(Int(engine.speed))")
                        .font(.caption2)
                        .monospacedDigit()
                    Stepper("", value: $engine.speed, in: 1...30, step: 1)
                        .labelsHidden()
                }
            }
        }
        .padding()
        .task {
            await openImmersiveSpace(id: "life3d-grid")
        }
    }
}
