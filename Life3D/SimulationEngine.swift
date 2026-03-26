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

    private var timerTask: Task<Void, Never>?

    init(size: Int = 16) {
        self.grid = GridModel(size: size)
        self.grid.randomSeed(density: 0.1)
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
    }

    enum Pattern: String, CaseIterable, Identifiable {
        case random = "Random (25%)"
        case soup = "Soup (6³ blob)"
        case block = "Block (2³)"
        case cluster = "Cluster (4³)"
        case clear = "Clear"

        var id: String { rawValue }
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
