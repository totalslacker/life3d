import Foundation
import Observation

@Observable
@MainActor
final class SimulationEngine {
    var grid: GridModel
    var generation: Int = 0
    var isRunning: Bool = false
    var speed: Double = 5.0 // generations per second

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

    func loadPattern(_ pattern: Pattern) {
        switch pattern {
        case .random:
            grid.randomSeed(density: 0.1)
        case .blinker:
            grid.loadBlinker()
        case .block:
            grid.loadBlock()
        case .cluster:
            grid.loadCluster()
        case .clear:
            grid.clearAll()
        }
    }

    enum Pattern: String, CaseIterable, Identifiable {
        case random = "Random"
        case blinker = "Blinker"
        case block = "Block"
        case cluster = "Cluster"
        case clear = "Clear"

        var id: String { rawValue }
    }
}
