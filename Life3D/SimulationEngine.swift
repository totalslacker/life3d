import Foundation
import Observation

@Observable
@MainActor
final class SimulationEngine {
    var grid: GridModel
    var generation: Int = 0
    var isRunning: Bool = false
    var speed: Double = 5.0 // generations per second
    var theme: ColorTheme = .neon
    var drawMode: Bool = false
    var surroundMode: Bool = false  // false = tabletop, true = room-scale
    var audioMuted: Bool = false
    var selectedPattern: Pattern = .random

    private var timerTask: Task<Void, Never>?

    // MARK: - User Defaults Keys
    private enum PrefKey {
        static let theme = "life3d.theme"
        static let gridSize = "life3d.gridSize"
        static let speed = "life3d.speed"
        static let ruleSet = "life3d.ruleSet"
        static let audioMuted = "life3d.audioMuted"
    }

    init(size: Int = 16) {
        // Load saved preferences or use defaults
        let defaults = UserDefaults.standard
        let savedSize = defaults.integer(forKey: PrefKey.gridSize)
        let effectiveSize = savedSize > 0 ? savedSize : size

        self.grid = GridModel(size: effectiveSize)
        self.grid.randomSeed()

        // Restore saved speed
        let savedSpeed = defaults.double(forKey: PrefKey.speed)
        if savedSpeed > 0 { self.speed = savedSpeed }

        // Restore saved theme
        if let themeName = defaults.string(forKey: PrefKey.theme),
           let savedTheme = ColorTheme.allThemes.first(where: { $0.name == themeName }) {
            self.theme = savedTheme
        }

        // Restore saved rules
        if let ruleSetName = defaults.string(forKey: PrefKey.ruleSet),
           let savedRuleSet = RuleSet.allCases.first(where: { $0.rawValue == ruleSetName }) {
            self.grid.birthCounts = savedRuleSet.birthCounts
            self.grid.survivalCounts = savedRuleSet.survivalCounts
        }

        // Restore audio muted state
        if defaults.object(forKey: PrefKey.audioMuted) != nil {
            self.audioMuted = defaults.bool(forKey: PrefKey.audioMuted)
        }
    }

    /// Saves current user preferences to UserDefaults.
    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(theme.name, forKey: PrefKey.theme)
        defaults.set(grid.size, forKey: PrefKey.gridSize)
        defaults.set(speed, forKey: PrefKey.speed)
        defaults.set(audioMuted, forKey: PrefKey.audioMuted)
        // Find matching rule set
        if let ruleSet = RuleSet.allCases.first(where: {
            $0.birthCounts == grid.birthCounts && $0.survivalCounts == grid.survivalCounts
        }) {
            defaults.set(ruleSet.rawValue, forKey: PrefKey.ruleSet)
        }
    }

    func step() {
        grid.advanceGeneration()
        generation += 1
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isRunning else { break }
                self.step()
                let interval = UInt64(1_000_000_000 / max(self.speed, 1.0))
                try? await Task.sleep(nanoseconds: interval)
            }
        }
    }

    func pause() {
        isRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    func reset(pattern: Pattern = .random) {
        pause()
        generation = 0
        loadPattern(pattern)
    }

    var rulesLabel: String {
        let b = grid.birthCounts.sorted().map(String.init).joined(separator: ",")
        let s = grid.survivalCounts.sorted().map(String.init).joined(separator: ",")
        return "B\(b)/S\(s)"
    }

    func loadPattern(_ pattern: Pattern) {
        switch pattern {
        case .random:
            grid.randomSeed()
        case .soup:
            grid.loadSoup()
        case .block:
            grid.loadBlock()
        case .cluster:
            grid.loadCluster()
        case .clear:
            grid.clearAll()
        }
    }

    func changeGridSize(_ newSize: Int) {
        pause()
        generation = 0
        grid = GridModel(size: newSize)
        grid.randomSeed()
        savePreferences()
    }

    enum Pattern: String, CaseIterable, Identifiable {
        case random = "Random (25%)"
        case soup = "Soup (6³ blob)"
        case block = "Block (2³)"
        case cluster = "Cluster (4³)"
        case clear = "Clear"

        var id: String { rawValue }
    }

    enum RuleSet: String, CaseIterable, Identifiable {
        case standard = "B5-7/S5-8"
        case conservative = "B6/S5-7"
        case expansive = "B4-6/S4-8"
        case sparse = "B5/S4-6"

        var id: String { rawValue }

        var birthCounts: Set<Int> {
            switch self {
            case .standard: return [5, 6, 7]
            case .conservative: return [6]
            case .expansive: return [4, 5, 6]
            case .sparse: return [5]
            }
        }

        var survivalCounts: Set<Int> {
            switch self {
            case .standard: return [5, 6, 7, 8]
            case .conservative: return [5, 6, 7]
            case .expansive: return [4, 5, 6, 7, 8]
            case .sparse: return [4, 5, 6]
            }
        }
    }

    func applyRuleSet(_ ruleSet: RuleSet) {
        grid.birthCounts = ruleSet.birthCounts
        grid.survivalCounts = ruleSet.survivalCounts
        savePreferences()
    }

    /// Toggles the cell nearest to a 3D position (in grid local space).
    func toggleCell(at position: SIMD3<Float>) {
        let coords = grid.nearestGridCoords(for: position, cellSize: GridRenderer.cellSize, cellSpacing: GridRenderer.cellSpacing)
        grid.toggleCell(x: coords.x, y: coords.y, z: coords.z)
        generation += 1  // trigger mesh rebuild via onChange
    }

    enum GridSize: Int, CaseIterable, Identifiable {
        case small = 12
        case medium = 16
        case large = 24
        case extraLarge = 32

        var id: Int { rawValue }
        var label: String { "\(rawValue)³" }
    }
}
