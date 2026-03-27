import Foundation

struct GridModel: Sendable {
    let size: Int
    /// Cell age: 0 = dead, 1+ = alive (value is age in generations)
    private(set) var cells: [Int]
    /// Second buffer for double-buffered generation advancement (avoids per-generation allocation).
    private var nextCells: [Int]
    /// Cells that died in the most recent generation (positions stored for fade-out rendering)
    private(set) var dyingCells: [Int] = []
    /// Cells born in the most recent generation (for particle effects)
    private(set) var bornCells: [Int] = []
    /// Cells fading out over multiple generations: (flatIndex, remainingFrames)
    /// Starts at fadeDuration and decrements each generation until 0.
    private(set) var fadingCells: [(index: Int, framesLeft: Int)] = []
    /// Number of generations a dying cell takes to fully fade out.
    static let fadeDuration: Int = 3

    /// Rule configuration: born when neighbor count is in birthCounts, survives when in survivalCounts
    var birthCounts: Set<Int> {
        didSet { birthLookup = Self.buildLookup(from: birthCounts) }
    }
    var survivalCounts: Set<Int> {
        didSet { survivalLookup = Self.buildLookup(from: survivalCounts) }
    }

    /// Pre-computed neighbor offsets as flat array index deltas (cached for the grid's size).
    private let cachedNeighborOffsets: [Int]

    /// Lookup tables for birth/survival rules: index by neighbor count (0-26), true = applies.
    /// Avoids Set.contains() hash overhead in the hot inner loop.
    private var birthLookup: [Bool]
    private var survivalLookup: [Bool]

    var cellCount: Int { size * size * size }

    init(size: Int, birthCounts: Set<Int> = [5, 6, 7], survivalCounts: Set<Int> = [5, 6, 7, 8]) {
        self.size = size
        let count = size * size * size
        self.cells = [Int](repeating: 0, count: count)
        self.nextCells = [Int](repeating: 0, count: count)
        self.birthCounts = birthCounts
        self.survivalCounts = survivalCounts
        self.cachedNeighborOffsets = Self.neighborOffsets(size: size)
        self.birthLookup = Self.buildLookup(from: birthCounts)
        self.survivalLookup = Self.buildLookup(from: survivalCounts)
    }

    /// Builds a 27-element Bool array for O(1) neighbor count lookup.
    private static func buildLookup(from counts: Set<Int>) -> [Bool] {
        var lookup = [Bool](repeating: false, count: 27)
        for count in counts where count >= 0 && count < 27 {
            lookup[count] = true
        }
        return lookup
    }


    // MARK: - Indexing

    func index(x: Int, y: Int, z: Int) -> Int {
        x * size * size + y * size + z
    }

    func isAlive(x: Int, y: Int, z: Int) -> Bool {
        guard x >= 0, x < size, y >= 0, y < size, z >= 0, z < size else { return false }
        return cells[index(x: x, y: y, z: z)] > 0
    }

    func cellAge(x: Int, y: Int, z: Int) -> Int {
        guard x >= 0, x < size, y >= 0, y < size, z >= 0, z < size else { return 0 }
        return cells[index(x: x, y: y, z: z)]
    }

    mutating func setCell(x: Int, y: Int, z: Int, alive: Bool) {
        guard x >= 0, x < size, y >= 0, y < size, z >= 0, z < size else { return }
        let idx = index(x: x, y: y, z: z)
        let wasAlive = cells[idx] > 0
        cells[idx] = alive ? 1 : 0
        if alive && !wasAlive { aliveCount += 1 }
        else if !alive && wasAlive { aliveCount -= 1 }
    }

    mutating func toggleCell(x: Int, y: Int, z: Int) {
        guard x >= 0, x < size, y >= 0, y < size, z >= 0, z < size else { return }
        let idx = index(x: x, y: y, z: z)
        if cells[idx] > 0 {
            cells[idx] = 0
            aliveCount -= 1
        } else {
            cells[idx] = 1
            aliveCount += 1
        }
    }

    /// Converts a 3D position (in grid local space) to the nearest grid coordinates.
    func nearestGridCoords(for position: SIMD3<Float>, cellSize: Float, cellSpacing: Float) -> (x: Int, y: Int, z: Int) {
        let stride = cellSize + cellSpacing
        let offset = Float(size - 1) * stride / 2.0
        let x = Int(round((position.x + offset) / stride))
        let y = Int(round((position.y + offset) / stride))
        let z = Int(round((position.z + offset) / stride))
        return (
            min(max(x, 0), size - 1),
            min(max(y, 0), size - 1),
            min(max(z, 0), size - 1)
        )
    }

    // MARK: - Neighbor Counting (26-cell Moore neighborhood)

    func neighborCount(x: Int, y: Int, z: Int) -> Int {
        var count = 0
        for dx in -1...1 {
            for dy in -1...1 {
                for dz in -1...1 {
                    if dx == 0 && dy == 0 && dz == 0 { continue }
                    if isAlive(x: x + dx, y: y + dy, z: z + dz) {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    // MARK: - Generation Advancement

    /// Pre-computed neighbor offsets as flat array index deltas for the 26-cell Moore neighborhood.
    private static func neighborOffsets(size: Int) -> [Int] {
        let ss = size * size
        var offsets: [Int] = []
        offsets.reserveCapacity(26)
        for dx in -1...1 {
            for dy in -1...1 {
                for dz in -1...1 {
                    if dx == 0 && dy == 0 && dz == 0 { continue }
                    offsets.append(dx * ss + dy * size + dz)
                }
            }
        }
        return offsets
    }

    mutating func advanceGeneration() {
        let ss = size * size
        let offsets = cachedNeighborOffsets
        // Zero the next buffer (reuse pre-allocated array instead of allocating each generation)
        for i in 0..<cellCount { nextCells[i] = 0 }
        var dying: [Int] = []
        var born: [Int] = []

        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let idx = x * ss + y * size + z
                    var neighbors = 0

                    // Interior cells: skip bounds checking (82% of cells for 32³)
                    if x > 0 && x < size - 1 && y > 0 && y < size - 1 && z > 0 && z < size - 1 {
                        for offset in offsets {
                            if cells[idx &+ offset] > 0 { neighbors &+= 1 }
                        }
                    } else {
                        // Boundary cells: need bounds checking
                        for dx in -1...1 {
                            for dy in -1...1 {
                                for dz in -1...1 {
                                    if dx == 0 && dy == 0 && dz == 0 { continue }
                                    let nx = x + dx, ny = y + dy, nz = z + dz
                                    if nx >= 0 && nx < size && ny >= 0 && ny < size && nz >= 0 && nz < size {
                                        if cells[nx * ss + ny * size + nz] > 0 { neighbors &+= 1 }
                                    }
                                }
                            }
                        }
                    }

                    if cells[idx] > 0 {
                        if survivalLookup[neighbors] {
                            nextCells[idx] = cells[idx] + 1
                        } else {
                            nextCells[idx] = 0
                            dying.append(idx)
                        }
                    } else {
                        if birthLookup[neighbors] {
                            nextCells[idx] = 1
                            born.append(idx)
                        }
                    }
                }
            }
        }
        swap(&cells, &nextCells)
        dyingCells = dying
        bornCells = born

        // Update fading cells: decrement counters, remove expired, add newly dying
        fadingCells = fadingCells.compactMap { entry in
            let remaining = entry.framesLeft - 1
            // If a fading cell was reborn, stop fading it
            guard cells[entry.index] == 0, remaining > 0 else { return nil }
            return (index: entry.index, framesLeft: remaining)
        }
        // Add newly dying cells at full fade duration
        for idx in dying {
            fadingCells.append((index: idx, framesLeft: Self.fadeDuration))
        }

        // Delta-based alive count: born cells added, dying cells removed
        aliveCount += born.count - dying.count
    }

    // MARK: - Alive Cell Positions

    /// Returns positions of alive cells.
    func aliveCellPositions(cellSize: Float, cellSpacing: Float) -> [SIMD3<Float>] {
        var positions: [SIMD3<Float>] = []
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    if cells[index(x: x, y: y, z: z)] > 0 {
                        positions.append(cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing))
                    }
                }
            }
        }
        return positions
    }

    /// Returns (position, age) for each alive cell, grouped for rendering.
    func aliveCellsWithAge(cellSize: Float, cellSpacing: Float) -> [(position: SIMD3<Float>, age: Int)] {
        var result: [(position: SIMD3<Float>, age: Int)] = []
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let age = cells[index(x: x, y: y, z: z)]
                    if age > 0 {
                        result.append((cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing), age))
                    }
                }
            }
        }
        return result
    }

    /// Returns positions of cells that just died (for fade-out rendering).
    func dyingCellPositions(cellSize: Float, cellSpacing: Float) -> [SIMD3<Float>] {
        dyingCells.map { idx in
            let x = idx / (size * size)
            let y = (idx / size) % size
            let z = idx % size
            return cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing)
        }
    }

    /// Returns all fading cells with their progress (0.0 = about to vanish, 1.0 = just died).
    func fadingCellsWithProgress(cellSize: Float, cellSpacing: Float) -> [(position: SIMD3<Float>, progress: Float)] {
        fadingCells.map { entry in
            let x = entry.index / (size * size)
            let y = (entry.index / size) % size
            let z = entry.index % size
            let pos = cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing)
            let progress = Float(entry.framesLeft) / Float(Self.fadeDuration)
            return (position: pos, progress: progress)
        }
    }

    /// Returns positions of cells born this generation (for particle effects).
    func bornCellPositions(cellSize: Float, cellSpacing: Float) -> [SIMD3<Float>] {
        bornCells.map { idx in
            let x = idx / (size * size)
            let y = (idx / size) % size
            let z = idx % size
            return cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing)
        }
    }

    private(set) var aliveCount: Int = 0

    private mutating func recomputeAliveCount() {
        aliveCount = cells.reduce(0) { $0 + ($1 > 0 ? 1 : 0) }
    }

    // MARK: - Cell Positioning

    func cellPosition(x: Int, y: Int, z: Int, cellSize: Float, cellSpacing: Float) -> SIMD3<Float> {
        let stride = cellSize + cellSpacing
        let offset = Float(size - 1) * stride / 2.0
        return SIMD3<Float>(
            Float(x) * stride - offset,
            Float(y) * stride - offset,
            Float(z) * stride - offset
        )
    }

    // MARK: - Preset Patterns

    mutating func randomSeed(density: Double = 0.25) {
        for i in 0..<cellCount {
            cells[i] = Double.random(in: 0...1) < density ? 1 : 0
        }
        recomputeAliveCount()
    }

    /// A dense random blob centered in the grid — produces interesting evolution
    mutating func loadSoup() {
        clearAll()
        let blobSize = 6
        let start = (size - blobSize) / 2
        for x in start..<(start + blobSize) {
            for y in start..<(start + blobSize) {
                for z in start..<(start + blobSize) {
                    if Double.random(in: 0...1) < 0.45 {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
    }

    /// A 3D "block" still life — 2x2x2 cube. Each cell has 7 neighbors (survives under B5-7/S5-8). Stable.
    mutating func loadBlock() {
        clearAll()
        let mid = size / 2
        for dx in 0...1 {
            for dy in 0...1 {
                for dz in 0...1 {
                    setCell(x: mid + dx, y: mid + dy, z: mid + dz, alive: true)
                }
            }
        }
    }

    /// A 4x4x4 checkerboard centered in the grid — grows and evolves under B5-7/S5-8
    mutating func loadCluster() {
        clearAll()
        let clusterSize = 4
        let start = (size - clusterSize) / 2
        for x in start..<(start + clusterSize) {
            for y in start..<(start + clusterSize) {
                for z in start..<(start + clusterSize) {
                    if (x + y + z) % 2 == 0 {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
    }

    /// A diamond (octahedron) shell — cells at Manhattan distance exactly r from center.
    /// Produces symmetric growth patterns that expand outward like a crystal.
    mutating func loadDiamond() {
        clearAll()
        let mid = size / 2
        let radius = min(size / 4, 4)
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let dist = abs(x - mid) + abs(y - mid) + abs(z - mid)
                    if dist == radius || dist == radius - 1 {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
    }

    /// A 3D cross/plus shape — three orthogonal bars through the center.
    /// Creates interesting axial growth that breaks symmetry over time.
    mutating func loadCross() {
        clearAll()
        let mid = size / 2
        let arm = min(size / 4, 3)
        for d in -arm...arm {
            // X-axis bar
            setCell(x: mid + d, y: mid, z: mid, alive: true)
            // Y-axis bar
            setCell(x: mid, y: mid + d, z: mid, alive: true)
            // Z-axis bar
            setCell(x: mid, y: mid, z: mid + d, alive: true)
            // Thicken the bars — add adjacent cells for enough neighbor density
            for offset in [-1, 1] {
                setCell(x: mid + d, y: mid + offset, z: mid, alive: true)
                setCell(x: mid + d, y: mid, z: mid + offset, alive: true)
                setCell(x: mid, y: mid + d, z: mid + offset, alive: true)
                setCell(x: mid + offset, y: mid + d, z: mid, alive: true)
                setCell(x: mid, y: mid + offset, z: mid + d, alive: true)
                setCell(x: mid + offset, y: mid, z: mid + d, alive: true)
            }
        }
    }

    /// A hollow tube aligned along the Y axis — ring cross-section.
    /// Evolves differently from blob-like seeds, often producing wave-like behavior.
    mutating func loadTube() {
        clearAll()
        let mid = size / 2
        let height = min(size / 3, 5)
        let outerR: Float = Float(min(size / 5, 3))
        let innerR: Float = outerR - 1.2
        for y in (mid - height)...(mid + height) {
            for x in 0..<size {
                for z in 0..<size {
                    let dx = Float(x - mid)
                    let dz = Float(z - mid)
                    let dist = (dx * dx + dz * dz).squareRoot()
                    if dist >= innerR && dist <= outerR {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
    }

    /// A hollow sphere shell centered in the grid.
    /// Creates radially symmetric evolution that expands and contracts beautifully.
    mutating func loadSphere() {
        clearAll()
        let mid = Float(size) / 2.0
        let outerR = Float(min(size / 3, 5))
        let innerR = outerR - 1.3
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let dx = Float(x) - mid + 0.5
                    let dy = Float(y) - mid + 0.5
                    let dz = Float(z) - mid + 0.5
                    let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
                    if dist >= innerR && dist <= outerR {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
    }

    mutating func clearAll() {
        for i in 0..<cellCount { cells[i] = 0 }
        dyingCells = []
        bornCells = []
        fadingCells = []
        aliveCount = 0
    }
}
