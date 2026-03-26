import SwiftUI

struct LaunchView: View {
    @Environment(SimulationEngine.self) private var engine
    let onStart: () -> Void

    var body: some View {
        @Bindable var engine = engine

        VStack(spacing: 20) {
            // Title
            Text("Life3D")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("3D Game of Life for Apple Vision Pro")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            // Configuration grid
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    Text("Pattern")
                        .foregroundStyle(.secondary)
                    Picker("Pattern", selection: Binding(
                        get: { engine.selectedPattern },
                        set: { engine.selectedPattern = $0 }
                    )) {
                        ForEach(SimulationEngine.Pattern.allCases) { pattern in
                            Text(pattern.rawValue).tag(pattern)
                        }
                    }
                    .pickerStyle(.menu)
                }

                GridRow {
                    Text("Theme")
                        .foregroundStyle(.secondary)
                    Picker("Theme", selection: Binding(
                        get: { engine.theme },
                        set: { engine.theme = $0 }
                    )) {
                        ForEach(ColorTheme.allThemes) { theme in
                            Text(theme.name).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)
                }

                GridRow {
                    Text("Grid Size")
                        .foregroundStyle(.secondary)
                    Picker("Grid Size", selection: Binding(
                        get: { SimulationEngine.GridSize(rawValue: engine.grid.size) ?? .medium },
                        set: { engine.changeGridSize($0.rawValue) }
                    )) {
                        ForEach(SimulationEngine.GridSize.allCases) { size in
                            Text(size.label).tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                GridRow {
                    Text("Rules")
                        .foregroundStyle(.secondary)
                    Picker("Rules", selection: Binding(
                        get: {
                            SimulationEngine.RuleSet.allCases.first {
                                $0.birthCounts == engine.grid.birthCounts &&
                                $0.survivalCounts == engine.grid.survivalCounts
                            } ?? .standard
                        },
                        set: { engine.applyRuleSet($0) }
                    )) {
                        ForEach(SimulationEngine.RuleSet.allCases) { ruleSet in
                            Text(ruleSet.rawValue).tag(ruleSet)
                        }
                    }
                    .pickerStyle(.menu)
                }

                GridRow {
                    Text("Speed")
                        .foregroundStyle(.secondary)
                    HStack {
                        Slider(value: $engine.speed, in: 1...30, step: 1)
                        Text("\(Int(engine.speed))×")
                            .monospacedDigit()
                            .frame(minWidth: 30, alignment: .trailing)
                    }
                }
            }

            Divider()

            // Start button
            Button {
                engine.loadPattern(engine.selectedPattern)
                onStart()
            } label: {
                Label("Start Simulation", systemImage: "play.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}
