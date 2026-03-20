import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var engine = SimulationEngine(size: 16)
    @State private var gridEntity: Entity?
    @State private var isRebuilding = false

    var body: some View {
        ZStack {
            RealityView { content in
                // Empty scene — grid added via update closure
            } update: { content in
                let existing = content.entities.first { $0.name == "CellGrid" }
                if let grid = gridEntity, existing == nil {
                    content.add(grid)
                } else if let grid = gridEntity, let old = existing, old !== grid {
                    content.entities.removeAll { $0.name == "CellGrid" }
                    content.add(grid)
                }
            }

            VStack {
                Spacer()

                // Generation counter overlay
                Text("Gen \(engine.generation) | Alive: \(engine.grid.aliveCount)")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                // Controls
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
                        Task { await rebuildMesh() }
                    }
                    .disabled(engine.isRunning)

                    Menu("Pattern") {
                        ForEach(SimulationEngine.Pattern.allCases) { pattern in
                            Button(pattern.rawValue) {
                                engine.reset(pattern: pattern)
                                Task { await rebuildMesh() }
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
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding(.bottom, 8)

            if gridEntity == nil {
                ProgressView("Building grid…")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .task {
            await rebuildMesh()
        }
        .onChange(of: engine.generation) {
            if engine.isRunning {
                Task { await rebuildMesh() }
            }
        }
    }

    private func rebuildMesh() async {
        guard !isRebuilding else { return }
        isRebuilding = true
        do {
            let grid = try await GridRenderer.makeGridAsync(model: engine.grid)
            gridEntity = grid
        } catch {
            print("Failed to build grid: \(error)")
        }
        isRebuilding = false
    }
}
