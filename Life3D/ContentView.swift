import SwiftUI

struct ContentView: View {
    @Environment(SimulationEngine.self) private var engine
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @State private var showingSimulation = false
    @State private var launchOpacity: Double = 1.0
    @State private var autoHideTask: Task<Void, Never>?
    private static let autoHideDelay: UInt64 = 4_000_000_000 // 4 seconds

    var body: some View {
        Group {
            if showingSimulation {
                SimulationControlBar(onBack: {
                    engine.pause()
                    engine.isExiting = true
                })
                .environment(engine)
                .opacity(engine.controlBarVisible ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.35), value: engine.controlBarVisible)
                .onHover { hovering in
                    if hovering {
                        showControlBar()
                    }
                }
            } else {
                LaunchView(onStart: {
                    Task {
                        // Fade out launch view, then open immersive space
                        withAnimation(.easeOut(duration: 0.3)) {
                            launchOpacity = 0.0
                        }
                        try? await Task.sleep(nanoseconds: 300_000_000)
                        showingSimulation = true
                        launchOpacity = 1.0
                    }
                })
                .environment(engine)
                .opacity(launchOpacity)
            }
        }
        .onChange(of: showingSimulation) {
            if showingSimulation {
                Task {
                    await openImmersiveSpace(id: "life3d-grid")
                    engine.start()
                    scheduleAutoHide()
                }
            }
        }
        .onChange(of: engine.exitAnimationComplete) {
            if engine.exitAnimationComplete {
                autoHideTask?.cancel()
                engine.controlBarVisible = true
                Task {
                    await dismissImmersiveSpace()
                    // Fade in launch view for smooth return transition
                    launchOpacity = 0.0
                    showingSimulation = false
                    engine.isExiting = false
                    engine.exitAnimationComplete = false
                    withAnimation(.easeOut(duration: 0.4)) {
                        launchOpacity = 1.0
                    }
                }
            }
        }
    }

    /// Shows the control bar and resets the auto-hide timer.
    private func showControlBar() {
        engine.controlBarVisible = true
        scheduleAutoHide()
    }

    /// Schedules the control bar to fade out after a delay.
    private func scheduleAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = Task {
            try? await Task.sleep(nanoseconds: Self.autoHideDelay)
            guard !Task.isCancelled else { return }
            engine.controlBarVisible = false
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

                // Quick reset
                Button {
                    engine.reset(pattern: engine.selectedPattern)
                    engine.start()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Reset simulation")

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

                // Help: replay gesture onboarding
                Button {
                    engine.showHelp = true
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Show gesture help")

                Spacer()

                // Population sparkline
                PopulationSparkline(data: engine.populationHistory)
                    .frame(width: 60, height: 16)

                // Stats with population trend
                HStack(spacing: 4) {
                    Text("Gen \(engine.generation)")
                    Image(systemName: engine.trendSymbol)
                        .font(.caption2)
                        .foregroundStyle(engine.populationTrend > 0 ? .green :
                                        engine.populationTrend < 0 ? .orange : .secondary)
                    Text("\(engine.grid.aliveCount)")
                    Text("peak \(engine.peakPopulation)")
                        .foregroundStyle(.tertiary)
                    Text("| \(engine.rulesLabel)")
                    if engine.generationRate > 0 {
                        Text("| \(String(format: "%.1f", engine.generationRate)) gen/s")
                            .foregroundStyle(.tertiary)
                    }
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
        .onChange(of: engine.theme) {
            engine.savePreferences()
            engine.controlBarVisible = true  // keep visible during interaction
        }
        .onChange(of: engine.speed) {
            engine.savePreferences()
            engine.controlBarVisible = true
        }
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

/// Tiny inline sparkline showing population history over recent generations.
struct PopulationSparkline: View {
    let data: [Int]

    var body: some View {
        Canvas { context, size in
            guard data.count >= 2 else { return }
            let maxVal = max(data.max() ?? 1, 1)
            let step = size.width / CGFloat(data.count - 1)

            var path = Path()
            for (i, value) in data.enumerated() {
                let x = CGFloat(i) * step
                let y = size.height - (CGFloat(value) / CGFloat(maxVal)) * size.height
                if i == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }

            context.stroke(path, with: .color(.secondary.opacity(0.6)), lineWidth: 1)

            // Fill under the curve
            var fillPath = path
            fillPath.addLine(to: CGPoint(x: size.width, y: size.height))
            fillPath.addLine(to: CGPoint(x: 0, y: size.height))
            fillPath.closeSubpath()
            context.fill(fillPath, with: .color(.secondary.opacity(0.15)))
        }
    }
}
