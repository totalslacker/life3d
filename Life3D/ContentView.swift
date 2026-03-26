import SwiftUI

struct ContentView: View {
    @Environment(SimulationEngine.self) private var engine
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var showingSimulation = false

    var body: some View {
        Group {
            if showingSimulation {
                SimulationControlBar(onBack: {
                    Task {
                        engine.pause()
                        await dismissImmersiveSpace()
                        showingSimulation = false
                    }
                })
                .environment(engine)
            } else {
                LaunchView(onStart: {
                    showingSimulation = true
                })
                .environment(engine)
            }
        }
        .onChange(of: showingSimulation) {
            if showingSimulation {
                Task {
                    await openImmersiveSpace(id: "life3d-grid")
                }
            }
        }
    }
}

/// The compact control bar shown during active simulation.
struct SimulationControlBar: View {
    @Environment(SimulationEngine.self) private var engine
    @State private var showingSettings = false
    let onBack: () -> Void

    var body: some View {
        @Bindable var engine = engine

        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Back to settings
                Button {
                    onBack()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Back to settings")

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

                // Settings gear
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showingSettings.toggle()
                    }
                } label: {
                    Image(systemName: showingSettings ? "gearshape.fill" : "gearshape")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Simulation settings")

                Spacer()

                // Stats
                Text("Gen \(engine.generation) | \(engine.grid.aliveCount) | \(engine.rulesLabel)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)

            // Settings overlay panel
            if showingSettings {
                Divider()
                MidSimulationSettings()
                    .environment(engine)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: engine.theme) { engine.savePreferences() }
        .onChange(of: engine.speed) { engine.savePreferences() }
        .onChange(of: engine.audioMuted) { engine.savePreferences() }
    }
}

/// Settings panel that slides open below the control bar during simulation.
struct MidSimulationSettings: View {
    @Environment(SimulationEngine.self) private var engine

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
            GridRow {
                Text("Pattern")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                HStack(spacing: 8) {
                    ForEach(SimulationEngine.Pattern.allCases) { pattern in
                        Button(pattern.rawValue) {
                            engine.reset(pattern: pattern)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            GridRow {
                Text("Theme")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                HStack(spacing: 8) {
                    ForEach(ColorTheme.allThemes) { theme in
                        Button(theme.name) {
                            engine.theme = theme
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            GridRow {
                Text("Rules")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                HStack(spacing: 8) {
                    ForEach(SimulationEngine.RuleSet.allCases) { ruleSet in
                        Button(ruleSet.rawValue) {
                            engine.applyRuleSet(ruleSet)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            GridRow {
                Text("Size")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                HStack(spacing: 8) {
                    ForEach(SimulationEngine.GridSize.allCases) { size in
                        Button(size.label) {
                            engine.changeGridSize(size.rawValue)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
