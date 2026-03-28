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
    var eraserMode: Bool = false    // false = paint cells on, true = erase cells
    var surroundMode: Bool = false  // false = tabletop, true = room-scale
    var audioMuted: Bool = true
    var selectedPattern: Pattern = .random
    var wrapping: Bool = false {
        didSet { grid.wrapping = wrapping }
    }

    // Exit animation coordination
    var isExiting: Bool = false
    var exitAnimationComplete: Bool = false

    // Help overlay trigger
    var showHelp: Bool = false

    // Population trend tracking (circular buffer for O(1) append)
    private var _trendBuffer: [Int]
    private var _trendWriteIndex: Int = 0
    private var _trendCount: Int = 0
    private static let trendWindow = 5  // number of generations to average over
    private static let trendBufferSize = 10  // 2x window for recent history

    /// Population history for sparkline display (last N generations).
    /// Uses a circular buffer for O(1) append instead of O(n) removeFirst.
    private var _historyBuffer: [Int]
    private var _historyWriteIndex: Int = 0
    private var _historyCount: Int = 0
    private static let historyLength = 60  // ~12 seconds at 5 gen/s

    /// Cached population history array, rebuilt in-place when a generation advances.
    /// Pre-allocated to historyLength to avoid per-generation heap allocations.
    private(set) var populationHistory: [Int] = []

    /// Rebuilds the populationHistory array from the circular buffer in-place.
    /// Uses a single pre-sized array and copies via slices instead of allocating
    /// two temporary arrays and concatenating them each generation.
    private func _rebuildPopulationHistory() {
        guard _historyCount > 0 else {
            if !populationHistory.isEmpty { populationHistory.removeAll(keepingCapacity: true) }
            return
        }
        let count = _historyCount
        // Ensure backing array is the right size without reallocating each call
        if populationHistory.count != count {
            if populationHistory.capacity < count {
                populationHistory.reserveCapacity(Self.historyLength)
            }
            populationHistory = [Int](repeating: 0, count: count)
        }
        if count < Self.historyLength {
            // Buffer not yet full — straight copy
            populationHistory.withUnsafeMutableBufferPointer { dst in
                _historyBuffer.withUnsafeBufferPointer { src in
                    dst.baseAddress!.update(from: src.baseAddress!, count: count)
                }
            }
        } else {
            // Buffer full — unwrap circular: [writeIndex..<length] + [0..<writeIndex]
            let start = _historyWriteIndex
            let tailCount = Self.historyLength - start
            populationHistory.withUnsafeMutableBufferPointer { dst in
                _historyBuffer.withUnsafeBufferPointer { src in
                    dst.baseAddress!.update(from: src.baseAddress! + start, count: tailCount)
                    dst.baseAddress!.advanced(by: tailCount).update(from: src.baseAddress!, count: start)
                }
            }
        }
    }

    /// Peak population reached since last reset.
    var peakPopulation: Int = 0

    /// Whether the population just went extinct (for notification overlay).
    var showExtinctionNotice: Bool = false

    /// Actual generations per second (measured).
    var generationRate: Double = 0.0
    private var rateTimestamp: Date = .now
    private var rateGenerationCount: Int = 0
    private static let rateSampleInterval: Double = 1.0  // recalculate every 1s

    /// Last generation computation time in milliseconds (for performance monitoring).
    var lastStepTimeMs: Double = 0.0

    /// Cached population trend, rebuilt only when a generation advances.
    private(set) var populationTrend: Int = 0

    /// Symbol name for the current population trend.
    var trendSymbol: String {
        switch populationTrend {
        case 1: return "arrow.up.right"
        case -1: return "arrow.down.right"
        default: return "arrow.right"
        }
    }

    /// Recomputes populationTrend from the trend circular buffer.
    private func _rebuildPopulationTrend() {
        guard _trendCount >= 2 else { populationTrend = 0; return }
        let count = min(_trendCount, Self.trendWindow)
        let firstIdx = (_trendWriteIndex - count + Self.trendBufferSize) % Self.trendBufferSize
        let lastIdx = (_trendWriteIndex - 1 + Self.trendBufferSize) % Self.trendBufferSize
        let first = _trendBuffer[firstIdx]
        let last = _trendBuffer[lastIdx]
        let delta = last - first
        let threshold = max(1, (first + 19) / 20)
        if delta > threshold { populationTrend = 1 }
        else if delta < -threshold { populationTrend = -1 }
        else { populationTrend = 0 }
    }

    private var timerTask: Task<Void, Never>?

    // MARK: - User Defaults Keys
    private enum PrefKey {
        static let theme = "life3d.theme"
        static let gridSize = "life3d.gridSize"
        static let speed = "life3d.speed"
        static let ruleSet = "life3d.ruleSet"
        static let audioMuted = "life3d.audioMuted"
        static let wrapping = "life3d.wrapping"
    }

    init(size: Int = 16) {
        // Initialize circular buffers
        self._historyBuffer = [Int](repeating: 0, count: Self.historyLength)
        self._trendBuffer = [Int](repeating: 0, count: Self.trendBufferSize)

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

        // Restore wrapping topology
        if defaults.object(forKey: PrefKey.wrapping) != nil {
            self.wrapping = defaults.bool(forKey: PrefKey.wrapping)
            self.grid.wrapping = self.wrapping
        }
    }

    /// Saves current user preferences to UserDefaults.
    func savePreferences() {
        let defaults = UserDefaults.standard
        defaults.set(theme.name, forKey: PrefKey.theme)
        defaults.set(grid.size, forKey: PrefKey.gridSize)
        defaults.set(speed, forKey: PrefKey.speed)
        defaults.set(audioMuted, forKey: PrefKey.audioMuted)
        defaults.set(wrapping, forKey: PrefKey.wrapping)
        // Find matching rule set
        if let ruleSet = RuleSet.allCases.first(where: {
            $0.birthCounts == grid.birthCounts && $0.survivalCounts == grid.survivalCounts
        }) {
            defaults.set(ruleSet.rawValue, forKey: PrefKey.ruleSet)
        }
    }

    /// Number of consecutive generations with zero alive cells before auto-restart.
    private var extinctionCounter: Int = 0
    private static let extinctionDelay: Int = 3  // wait 3 empty generations (~0.6s at 5 gen/s)

    /// Patterns to cycle through on auto-restart (excludes Clear).
    private static let cyclablePatterns: [Pattern] = Pattern.allCases.filter { $0 != .clear }
    /// Index into cyclablePatterns for auto-restart cycling.
    private var cycleIndex: Int = 0

    func step() {
        let stepStart = ContinuousClock.now
        grid.advanceGeneration()
        let stepEnd = ContinuousClock.now
        lastStepTimeMs = Double((stepEnd - stepStart).components.attoseconds) / 1_000_000_000_000_000.0
        generation += 1
        // Track generation rate
        rateGenerationCount += 1
        let now = Date.now
        let elapsed = now.timeIntervalSince(rateTimestamp)
        if elapsed >= Self.rateSampleInterval {
            let measured = Double(rateGenerationCount) / elapsed
            // Exponential moving average smooths jitter (5.3→4.8→5.1 becomes steady ~5.0)
            if generationRate > 0 {
                generationRate = generationRate * 0.7 + measured * 0.3
            } else {
                generationRate = measured
            }
            rateGenerationCount = 0
            rateTimestamp = now
        }
        // Track population for trend indicator (circular buffer — O(1))
        _trendBuffer[_trendWriteIndex] = grid.aliveCount
        _trendWriteIndex = (_trendWriteIndex + 1) % Self.trendBufferSize
        if _trendCount < Self.trendBufferSize { _trendCount += 1 }
        // Track population history for sparkline (circular buffer — O(1))
        _historyBuffer[_historyWriteIndex] = grid.aliveCount
        _historyWriteIndex = (_historyWriteIndex + 1) % Self.historyLength
        if _historyCount < Self.historyLength { _historyCount += 1 }
        // Track peak population
        if grid.aliveCount > peakPopulation {
            peakPopulation = grid.aliveCount
        }
        // Rebuild cached display values (avoids per-frame array allocations in UI)
        _rebuildPopulationHistory()
        _rebuildPopulationTrend()
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isRunning else { break }
                self.step()

                // Auto-restart: if population is extinct (and all fading done), reseed
                // Skip if exit animation is in progress to avoid spawning new grid during dissolve
                if self.grid.aliveCount == 0 && self.grid.fadingCells.isEmpty && !self.isExiting {
                    self.extinctionCounter += 1
                    if self.extinctionCounter >= Self.extinctionDelay {
                        self.extinctionCounter = 0
                        self.showExtinctionNotice = true
                        self.generation = 0
                        self._historyWriteIndex = 0
                        self._historyCount = 0
                        self._trendWriteIndex = 0
                        self._trendCount = 0
                        self.populationHistory = []
                        self.populationTrend = 0
                        // Cycle through patterns on auto-restart for variety
                        let nextPattern = Self.cyclablePatterns[self.cycleIndex % Self.cyclablePatterns.count]
                        self.cycleIndex += 1
                        self.selectedPattern = nextPattern
                        self.loadPattern(nextPattern)
                        // Auto-dismiss extinction notice after 2 seconds
                        Task { @MainActor [weak self] in
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            self?.showExtinctionNotice = false
                        }
                    }
                } else {
                    self.extinctionCounter = 0
                }

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
        _trendWriteIndex = 0
        _trendCount = 0
        _historyWriteIndex = 0
        _historyCount = 0
        populationHistory = []
        populationTrend = 0
        peakPopulation = 0
        showExtinctionNotice = false
        generationRate = 0.0
        lastStepTimeMs = 0.0
        rateGenerationCount = 0
        rateTimestamp = .now
        selectedPattern = pattern
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
        case .diamond:
            grid.loadDiamond()
        case .cross:
            grid.loadCross()
        case .tube:
            grid.loadTube()
        case .sphere:
            grid.loadSphere()
        case .mirror:
            grid.loadMirror()
        case .stagger:
            grid.loadStagger()
        case .helix:
            grid.loadHelix()
        case .rings:
            grid.loadRings()
        case .spiral:
            grid.loadSpiral()
        case .torus:
            grid.loadTorus()
        case .galaxy:
            grid.loadGalaxy()
        case .pyramid:
            grid.loadPyramid()
        case .wave:
            grid.loadWave()
        case .lattice:
            grid.loadLattice()
        case .checkerboard:
            grid.loadCheckerboard()
        case .mengerSponge:
            grid.loadMengerSponge()
        case .cage:
            grid.loadCage()
        case .trefoilKnot:
            grid.loadTrefoilKnot()
        case .snowflake:
            grid.loadSnowflake()
        case .clear:
            grid.clearAll()
        }
    }

    /// Incremented each time the grid is replaced (e.g. size change).
    /// Observers can watch this to invalidate stale per-grid state like paintedCells.
    private(set) var gridEpoch: Int = 0

    func changeGridSize(_ newSize: Int) {
        pause()
        generation = 0
        // Preserve current birth/survival rules when changing grid size
        let currentBirth = grid.birthCounts
        let currentSurvival = grid.survivalCounts
        grid = GridModel(size: newSize, birthCounts: currentBirth, survivalCounts: currentSurvival)
        grid.wrapping = wrapping
        grid.randomSeed()
        gridEpoch += 1
        savePreferences()
    }

    enum Pattern: String, CaseIterable, Identifiable {
        case random = "Random (25%)"
        case soup = "Soup (6³ blob)"
        case block = "Block (2³)"
        case cluster = "Cluster (4³)"
        case diamond = "Diamond"
        case cross = "Cross"
        case tube = "Tube"
        case sphere = "Sphere"
        case mirror = "Mirror (8-fold)"
        case stagger = "Stagger (lattice)"
        case helix = "Helix (DNA)"
        case rings = "Rings (shells)"
        case spiral = "Spiral"
        case torus = "Torus"
        case galaxy = "Galaxy"
        case pyramid = "Pyramid"
        case wave = "Wave"
        case lattice = "Lattice"
        case checkerboard = "Checkerboard"
        case mengerSponge = "Menger Sponge"
        case cage = "Cage"
        case trefoilKnot = "Trefoil Knot"
        case snowflake = "Snowflake"
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
