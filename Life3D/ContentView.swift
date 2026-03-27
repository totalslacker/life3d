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
                    engine.pause()
                    engine.isExiting = true
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
                    engine.start()
                }
            }
        }
        .onChange(of: engine.exitAnimationComplete) {
            if engine.exitAnimationComplete {
                Task {
                    await dismissImmersiveSpace()
                    showingSimulation = false
                    engine.isExiting = false
                    engine.exitAnimationComplete = false
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
                    if !engine.drawMode { engine.eraserMode = false }
                } label: {
                    Image(systemName: engine.drawMode ? "pencil.circle.fill" : "arrow.triangle.2.circlepath")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help(engine.drawMode ? "Draw mode: drag to paint cells" : "Rotate mode: drag to rotate")

                // Eraser toggle (only visible in draw mode)
                if engine.drawMode {
                    Button {
                        engine.eraserMode.toggle()
                    } label: {
                        Image(systemName: engine.eraserMode ? "eraser.fill" : "eraser")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help(engine.eraserMode ? "Eraser: drag to remove cells" : "Pencil: drag to add cells")
                }

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

                // Stats with population trend
                HStack(spacing: 4) {
                    Text("Gen \(engine.generation)")
                    Image(systemName: engine.trendSymbol)
                        .font(.caption2)
                        .foregroundStyle(engine.populationTrend > 0 ? .green :
                                        engine.populationTrend < 0 ? .orange : .secondary)
                    Text("\(engine.grid.aliveCount) | \(engine.rulesLabel)")
                }
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
                        .tint(pattern == engine.selectedPattern ? .accentColor : .gray)
                    }
                }
            }

            GridRow {
                Text("Theme")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                HStack(spacing: 8) {
                    ForEach(ColorTheme.allThemes) { theme in
                        Button {
                            engine.theme = theme
                        } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(
                                        red: Double(theme.newborn.emissiveColor.x),
                                        green: Double(theme.newborn.emissiveColor.y),
                                        blue: Double(theme.newborn.emissiveColor.z)
                                    ))
                                    .frame(width: 8, height: 8)
                                Text(theme.name)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(theme == engine.theme ? .accentColor : .gray)
                    }
                }
            }

            GridRow {
                Text("Rules")
                    .foregroundStyle(.secondary)
                    .font(.callout)
                HStack(spacing: 8) {
                    let currentRuleSet = SimulationEngine.RuleSet.allCases.first {
                        $0.birthCounts == engine.grid.birthCounts &&
                        $0.survivalCounts == engine.grid.survivalCounts
                    }
                    ForEach(SimulationEngine.RuleSet.allCases) { ruleSet in
                        Button(ruleSet.rawValue) {
                            engine.applyRuleSet(ruleSet)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(ruleSet == currentRuleSet ? .accentColor : .gray)
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
                        .tint(size.rawValue == engine.grid.size ? .accentColor : .gray)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
