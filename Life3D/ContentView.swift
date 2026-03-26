import SwiftUI

struct ContentView: View {
    @Environment(SimulationEngine.self) private var engine
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace

    var body: some View {
        @Bindable var engine = engine

        HStack(spacing: 12) {
            // Play/Pause + Step
            HStack(spacing: 6) {
                Button {
                    if engine.isRunning { engine.pause() } else { engine.start() }
                } label: {
                    Image(systemName: engine.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    engine.step()
                } label: {
                    Image(systemName: "forward.frame.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(engine.isRunning)
            }

            // Pattern menu
            Menu("Pattern") {
                ForEach(SimulationEngine.Pattern.allCases) { pattern in
                    Button(pattern.rawValue) {
                        engine.reset(pattern: pattern)
                    }
                }
            }
            .controlSize(.small)

            // Theme menu
            Menu("Theme") {
                ForEach(ColorTheme.allThemes) { theme in
                    Button(theme.name) {
                        engine.theme = theme
                    }
                }
            }
            .controlSize(.small)

            // Rules menu
            Menu("Rules") {
                ForEach(SimulationEngine.RuleSet.allCases) { ruleSet in
                    Button(ruleSet.rawValue) {
                        engine.applyRuleSet(ruleSet)
                    }
                }
            }
            .controlSize(.small)

            // Grid size menu
            Menu("Size") {
                ForEach(SimulationEngine.GridSize.allCases) { size in
                    Button(size.label) {
                        engine.changeGridSize(size.rawValue)
                    }
                }
            }
            .controlSize(.small)

            // Draw mode toggle
            Button {
                engine.drawMode.toggle()
            } label: {
                Image(systemName: engine.drawMode ? "pencil.circle.fill" : "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(engine.drawMode ? "Draw mode: drag to paint cells" : "Rotate mode: drag to rotate")

            // Surround mode toggle
            Button {
                engine.surroundMode.toggle()
            } label: {
                Image(systemName: engine.surroundMode ? "cube.fill" : "cube.transparent")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(engine.surroundMode ? "Surround mode: grid around you" : "Tabletop mode: grid in front")

            // Audio mute toggle
            Button {
                engine.audioMuted.toggle()
            } label: {
                Image(systemName: engine.audioMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help(engine.audioMuted ? "Audio muted" : "Audio on")

            // Speed slider
            HStack(spacing: 4) {
                Text("\(Int(engine.speed))×")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(minWidth: 24, alignment: .trailing)
                Slider(value: $engine.speed, in: 1...30, step: 1)
                    .frame(width: 80)
            }

            Spacer()

            // Stats
            Text("Gen \(engine.generation) | \(engine.grid.aliveCount) | \(engine.rulesLabel)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .task {
            await openImmersiveSpace(id: "life3d-grid")
        }
    }
}
