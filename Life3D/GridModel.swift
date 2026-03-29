import Foundation
import simd

struct GridModel: Sendable {
    let size: Int
    /// Cell age: 0 = dead, 1+ = alive (value is age in generations)
    private(set) var cells: [Int]
    /// Second buffer for double-buffered generation advancement (avoids per-generation allocation).
    private var nextCells: [Int]
    /// Cells that died in the most recent generation (positions stored for fade-out rendering).
    /// Pre-allocated and reused via removeAll(keepingCapacity:) to avoid per-generation heap allocation.
    private(set) var dyingCells: [Int] = []
    /// Cells born in the most recent generation (for particle effects).
    /// Pre-allocated and reused via removeAll(keepingCapacity:) to avoid per-generation heap allocation.
    private(set) var bornCells: [Int] = []
    /// Cells fading out over multiple generations: (flatIndex, remainingFrames)
    /// Starts at fadeDuration and decrements each generation until 0.
    private(set) var fadingCells: [(index: Int, framesLeft: Int)] = []
    /// Flat indices of all currently alive cells, maintained incrementally.
    /// Used by `aliveCellsWithAge` to avoid scanning the entire grid (O(alive) vs O(n³)).
    private(set) var aliveCellIndices: [Int] = []
    /// Reverse mapping: cell flat index → position in aliveCellIndices (-1 = not alive).
    /// Enables O(1) removal from aliveCellIndices instead of O(alive) linear scan.
    private var aliveIndexMap: [Int] = []
    /// Number of generations a dying cell takes to fully fade out.
    static let fadeDuration: Int = 3

    /// When true, grid edges wrap around (toroidal topology).
    /// Boundary cells see neighbors on the opposite face instead of treating out-of-bounds as dead.
    var wrapping: Bool = false

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
        self.aliveIndexMap = [Int](repeating: -1, count: count)
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
        if alive && wasAlive { return }  // Already alive — preserve age
        if !alive && !wasAlive { return }  // Already dead — no-op
        cells[idx] = alive ? 1 : 0
        if alive {
            aliveCount += 1
            aliveIndexMap[idx] = aliveCellIndices.count
            aliveCellIndices.append(idx)
        } else {
            aliveCount -= 1
            // O(1) swap-remove using reverse mapping
            let pos = aliveIndexMap[idx]
            if pos >= 0 && pos < aliveCellIndices.count {
                let lastIdx = aliveCellIndices[aliveCellIndices.count - 1]
                aliveCellIndices.swapAt(pos, aliveCellIndices.count - 1)
                aliveCellIndices.removeLast()
                if pos < aliveCellIndices.count {
                    aliveIndexMap[lastIdx] = pos
                }
            }
            aliveIndexMap[idx] = -1
        }
    }

    mutating func toggleCell(x: Int, y: Int, z: Int) {
        guard x >= 0, x < size, y >= 0, y < size, z >= 0, z < size else { return }
        let idx = index(x: x, y: y, z: z)
        if cells[idx] > 0 {
            cells[idx] = 0
            aliveCount -= 1
            let pos = aliveIndexMap[idx]
            if pos >= 0 && pos < aliveCellIndices.count {
                let lastIdx = aliveCellIndices[aliveCellIndices.count - 1]
                aliveCellIndices.swapAt(pos, aliveCellIndices.count - 1)
                aliveCellIndices.removeLast()
                if pos < aliveCellIndices.count {
                    aliveIndexMap[lastIdx] = pos
                }
            }
            aliveIndexMap[idx] = -1
        } else {
            cells[idx] = 1
            aliveCount += 1
            aliveIndexMap[idx] = aliveCellIndices.count
            aliveCellIndices.append(idx)
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
                    if wrapping {
                        let nx = (x + dx + size) % size
                        let ny = (y + dy + size) % size
                        let nz = (z + dz + size) % size
                        if cells[index(x: nx, y: ny, z: nz)] > 0 { count += 1 }
                    } else {
                        if isAlive(x: x + dx, y: y + dy, z: z + dz) {
                            count += 1
                        }
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
        // Zero the next buffer using bulk memset — faster than per-element loop for 32K+ ints
        nextCells.withUnsafeMutableBufferPointer { buf in
            buf.update(repeating: 0)
        }
        // Reuse pre-allocated born/dying/alive buffers — removeAll(keepingCapacity:) avoids heap allocation
        dyingCells.removeAll(keepingCapacity: true)
        bornCells.removeAll(keepingCapacity: true)
        aliveCellIndices.removeAll(keepingCapacity: true)

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
                    } else if wrapping {
                        // Wrapping boundary: use modular arithmetic (toroidal topology)
                        for dx in -1...1 {
                            for dy in -1...1 {
                                for dz in -1...1 {
                                    if dx == 0 && dy == 0 && dz == 0 { continue }
                                    let nx = (x + dx + size) % size
                                    let ny = (y + dy + size) % size
                                    let nz = (z + dz + size) % size
                                    if cells[nx * ss + ny * size + nz] > 0 { neighbors &+= 1 }
                                }
                            }
                        }
                    } else {
                        // Finite boundary: out-of-bounds treated as dead
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
                            aliveIndexMap[idx] = aliveCellIndices.count
                            aliveCellIndices.append(idx)

                        } else {
                            nextCells[idx] = 0
                            dyingCells.append(idx)
                        }
                    } else {
                        if birthLookup[neighbors] {
                            nextCells[idx] = 1
                            bornCells.append(idx)
                            aliveIndexMap[idx] = aliveCellIndices.count
                            aliveCellIndices.append(idx)

                        }
                    }
                }
            }
        }
        swap(&cells, &nextCells)

        // Update fading cells in-place: decrement counters, remove expired/reborn, add newly dying.
        // Avoids compactMap allocation by using swap-remove (O(1) per removal).
        var i = 0
        while i < fadingCells.count {
            fadingCells[i].framesLeft -= 1
            let fadeIdx = fadingCells[i].index
            if fadingCells[i].framesLeft <= 0 || fadeIdx >= cells.count || cells[fadeIdx] != 0 {
                // Swap with last element and remove (O(1) removal)
                fadingCells[i] = fadingCells[fadingCells.count - 1]
                fadingCells.removeLast()
            } else {
                i += 1
            }
        }
        // Add newly dying cells at full fade duration
        fadingCells.reserveCapacity(fadingCells.count + dyingCells.count)
        for idx in dyingCells {
            fadingCells.append((index: idx, framesLeft: Self.fadeDuration))
        }

        // Delta-based alive count: born cells added, dying cells removed
        aliveCount += bornCells.count - dyingCells.count
    }

    // MARK: - Alive Cell Positions

    /// Returns (position, age) for each alive cell, using pre-built index list.
    /// O(alive) instead of O(n³) — skips scanning dead cells entirely.
    func aliveCellsWithAge(cellSize: Float, cellSpacing: Float) -> [(position: SIMD3<Float>, age: Int)] {
        let ss = size * size
        return aliveCellIndices.map { idx in
            let x = idx / ss
            let y = (idx / size) % size
            let z = idx % size
            return (cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing), cells[idx])
        }
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
        fadingCells.compactMap { entry in
            guard entry.index >= 0 && entry.index < cellCount else { return nil }
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

    /// Rebuilds the alive cell index list by scanning the flat cells array.
    /// Called after bulk mutations (pattern loading, random seed) where
    /// incremental tracking isn't practical.
    private mutating func rebuildAliveCellIndices() {
        aliveCellIndices.removeAll(keepingCapacity: true)
        aliveIndexMap.withUnsafeMutableBufferPointer { $0.update(repeating: -1) }
        for i in 0..<cellCount {
            if cells[i] > 0 {
                aliveIndexMap[i] = aliveCellIndices.count
                aliveCellIndices.append(i)
            }
        }
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
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
        rebuildAliveCellIndices()
    }

    /// A mirror-symmetric random seed — generates one octant randomly, then mirrors
    /// across all three axes. Symmetric initial conditions produce visually striking
    /// evolutions with kaleidoscopic structure that persists for many generations.
    mutating func loadMirror(density: Double = 0.35) {
        clearAll()
        let half = size / 2
        // Fill one octant randomly
        for x in 0..<half {
            for y in 0..<half {
                for z in 0..<half {
                    if Double.random(in: 0...1) < density {
                        // Mirror across all three axes (8-fold symmetry)
                        let mx = size - 1 - x
                        let my = size - 1 - y
                        let mz = size - 1 - z
                        setCell(x: x,  y: y,  z: z,  alive: true)
                        setCell(x: mx, y: y,  z: z,  alive: true)
                        setCell(x: x,  y: my, z: z,  alive: true)
                        setCell(x: x,  y: y,  z: mz, alive: true)
                        setCell(x: mx, y: my, z: z,  alive: true)
                        setCell(x: mx, y: y,  z: mz, alive: true)
                        setCell(x: x,  y: my, z: mz, alive: true)
                        setCell(x: mx, y: my, z: mz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A staggered lattice: every 3rd cell in each dimension, offset on alternate layers.
    /// Creates a sparse, evenly-distributed seed that produces expanding wavefront dynamics
    /// as isolated clusters grow and merge into larger structures.
    mutating func loadStagger() {
        clearAll()
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    // Offset alternate layers by 1 cell for stagger effect
                    let xOff = (y % 2 == 0) ? 0 : 1
                    let zOff = (y % 2 == 0) ? 0 : 1
                    if (x + xOff) % 3 == 0 && y % 3 == 0 && (z + zOff) % 3 == 0 {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A double helix spiral around the Y axis — two interleaved helical strands
    /// with enough thickness to sustain evolution. Creates DNA-like structures that
    /// unwind and evolve into complex branching forms.
    mutating func loadHelix() {
        clearAll()
        let mid = Float(size) / 2.0
        let turns: Float = 2.5  // number of full rotations
        let radius: Float = Float(min(size / 4, 5))
        let thickness: Float = 1.4  // strand thickness for neighbor density

        for y in 0..<size {
            let t = Float(y) / Float(size - 1)  // 0 to 1 along height
            let angle = t * turns * 2.0 * .pi

            // Two strands offset by π (180°)
            for strand in 0..<2 {
                let strandAngle = angle + Float(strand) * .pi
                let cx = mid + radius * cos(strandAngle)
                let cz = mid + radius * sin(strandAngle)

                // Fill a small sphere around the strand center for thickness
                for x in 0..<size {
                    for z in 0..<size {
                        let dx = Float(x) - cx + 0.5
                        let dz = Float(z) - cz + 0.5
                        let dist = (dx * dx + dz * dz).squareRoot()
                        if dist <= thickness {
                            setCell(x: x, y: y, z: z, alive: true)
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Concentric spherical shells — two thin shells at different radii.
    /// Creates layered evolution where inner and outer rings interact,
    /// producing pulsing, breathing dynamics as shells expand and collide.
    mutating func loadRings() {
        clearAll()
        let mid = Float(size) / 2.0
        let outerR = Float(min(size / 3, 5))
        let innerR = outerR * 0.5
        let thickness: Float = 0.8
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let dx = Float(x) - mid + 0.5
                    let dy = Float(y) - mid + 0.5
                    let dz = Float(z) - mid + 0.5
                    let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
                    let onOuter = abs(dist - outerR) <= thickness
                    let onInner = abs(dist - innerR) <= thickness
                    if onOuter || onInner {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A 3D logarithmic spiral — cells trace a widening helix from the center outward.
    /// Creates a dramatic vortex structure that evolves into fractal-like branching forms.
    mutating func loadSpiral() {
        clearAll()
        let mid = Float(size) / 2.0
        let totalPoints = size * 12  // dense enough to create a solid spiral
        let maxRadius = Float(min(size / 3, 6))
        let turns: Float = 3.0
        let thickness: Float = 1.3

        for i in 0..<totalPoints {
            let t = Float(i) / Float(totalPoints)
            let angle = t * turns * 2.0 * .pi
            let radius = maxRadius * t  // linear growth for Archimedean spiral
            let y = mid - Float(size) * 0.4 + t * Float(size) * 0.8  // spans 80% of grid height

            let cx = mid + radius * cos(angle)
            let cz = mid + radius * sin(angle)

            // Fill a small sphere around the spiral center for thickness
            for x in 0..<size {
                for z in 0..<size {
                    let dx = Float(x) - cx + 0.5
                    let dz = Float(z) - cz + 0.5
                    let dist = (dx * dx + dz * dz).squareRoot()
                    if dist <= thickness {
                        let yi = Int(y)
                        if yi >= 0 && yi < size {
                            setCell(x: x, y: yi, z: z, alive: true)
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A 3D torus (doughnut) lying in the XZ plane — ring of circular cross-section.
    /// The only pattern with genus-1 topology (has a hole). Produces unique evolution
    /// as cells on the inner ring face higher neighbor density than the outer ring,
    /// creating asymmetric growth that breaks the initial symmetry beautifully.
    mutating func loadTorus() {
        clearAll()
        let mid = Float(size) / 2.0
        let majorR = Float(min(size / 4, 4))  // distance from center to tube center
        let minorR: Float = majorR * 0.4       // tube radius
        let thickness: Float = 1.2             // fill thickness for neighbor density
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let dx = Float(x) - mid + 0.5
                    let dy = Float(y) - mid + 0.5
                    let dz = Float(z) - mid + 0.5
                    // Distance from the Y axis in XZ plane
                    let distXZ = (dx * dx + dz * dz).squareRoot()
                    // Distance from the major ring (circle in XZ plane at radius majorR)
                    let ringDx = distXZ - majorR
                    let dist = (ringDx * ringDx + dy * dy).squareRoot()
                    if dist <= minorR + thickness && dist >= minorR - thickness {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A spiral galaxy with two arms emanating from a dense spherical core.
    /// The arms trace logarithmic spirals in the XZ plane with vertical spread,
    /// creating a recognizable galaxy shape that evolves into chaotic branching forms.
    mutating func loadGalaxy() {
        clearAll()
        let mid = Float(size) / 2.0
        let coreR: Float = Float(min(size / 6, 3))  // dense central core
        let armLength: Float = Float(min(size / 3, 6))
        let thickness: Float = 1.2
        let armPoints = size * 15  // dense sampling for solid arms
        let turns: Float = 1.5

        // Dense spherical core
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let dx = Float(x) - mid + 0.5
                    let dy = Float(y) - mid + 0.5
                    let dz = Float(z) - mid + 0.5
                    let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
                    if dist <= coreR {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }

        // Two spiral arms offset by π
        for arm in 0..<2 {
            let armOffset = Float(arm) * .pi
            for i in 0..<armPoints {
                let t = Float(i) / Float(armPoints)
                let angle = armOffset + t * turns * 2.0 * .pi
                let radius = coreR + armLength * t
                let cx = mid + radius * cos(angle)
                let cz = mid + radius * sin(angle)
                // Vertical spread increases along arm (thin at core, wider at tips)
                let ySpread = thickness * (0.5 + t * 0.8)

                for x in 0..<size {
                    for z in 0..<size {
                        let dx = Float(x) - cx + 0.5
                        let dz = Float(z) - cz + 0.5
                        let distXZ = (dx * dx + dz * dz).squareRoot()
                        if distXZ <= thickness {
                            // Fill a vertical slice centered at mid-Y
                            let yCenter = Int(mid)
                            let yRange = Int(ySpread)
                            for dy in -yRange...yRange {
                                let yi = yCenter + dy
                                if yi >= 0 && yi < size {
                                    setCell(x: x, y: yi, z: z, alive: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A stepped 3D pyramid with four triangular faces rising to a single apex.
    /// Each layer is a centered square that shrinks by one cell per side,
    /// creating a ziggurat-like structure with exposed surfaces that evolve
    /// differently from the dense interior — edges erode first while the core sustains.
    mutating func loadPyramid() {
        clearAll()
        let mid = size / 2
        let height = min(size / 2, 8)  // pyramid height in cells
        for layer in 0..<height {
            let halfWidth = height - layer  // each layer shrinks by 1
            let y = mid - height / 2 + layer
            guard y >= 0 && y < size else { continue }
            for dx in -halfWidth...halfWidth {
                for dz in -halfWidth...halfWidth {
                    let x = mid + dx
                    let z = mid + dz
                    if x >= 0 && x < size && z >= 0 && z < size {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A sinusoidal surface — two perpendicular sine waves create a rippling 3D sheet.
    /// The surface has high neighbor density along the sheet and sparse edges,
    /// producing wave-like propagation that flows outward as the surface evolves.
    mutating func loadWave() {
        clearAll()
        let mid = Float(size) / 2.0
        let amplitude = Float(size) / 6.0
        let frequency: Float = 2.0 * .pi / Float(size)
        let thickness: Float = 1.2

        for x in 0..<size {
            for z in 0..<size {
                // Two perpendicular sine waves summed
                let fx = Float(x) - mid + 0.5
                let fz = Float(z) - mid + 0.5
                let yCenter = mid + amplitude * (sin(frequency * fx * 2.0) + sin(frequency * fz * 2.0)) / 2.0
                // Fill a vertical slice around the surface
                for y in 0..<size {
                    let dy = Float(y) - yCenter
                    if abs(dy) <= thickness {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A 3D crystal lattice — regularly spaced cells forming a periodic grid-within-a-grid.
    mutating func loadLattice() {
        clearAll()
        let margin = max(1, size / 6)
        for x in stride(from: margin, to: size - margin, by: 2) {
            for y in stride(from: margin, to: size - margin, by: 2) {
                for z in stride(from: margin, to: size - margin, by: 2) {
                    setCell(x: x, y: y, z: z, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A full-grid 3D checkerboard — alternating cells in every dimension.
    mutating func loadCheckerboard() {
        clearAll()
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    if (x + y + z) % 2 == 0 {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A trefoil knot — a three-lobed 3D knot, the simplest nontrivial mathematical knot.
    /// Parametric curve: x = sin(t) + 2sin(2t), y = cos(t) - 2cos(2t), z = -sin(3t).
    /// Creates an intertwined looping structure that evolves into complex branching forms
    /// as the thin tube sections erode while crossing points sustain through neighbor density.
    mutating func loadTrefoilKnot() {
        clearAll()
        let mid = Float(size) / 2.0
        let scale = Float(size) / 8.0
        let thickness: Float = 1.4
        let samples = size * 20  // dense sampling for solid tube

        for i in 0..<samples {
            let t = Float(i) / Float(samples) * 2.0 * .pi
            // Trefoil parametric equations (scaled to fit grid)
            let px = (sin(t) + 2.0 * sin(2.0 * t)) * scale + mid
            let py = (cos(t) - 2.0 * cos(2.0 * t)) * scale + mid
            let pz = (-sin(3.0 * t)) * scale + mid

            // Fill a small sphere around the knot curve for thickness
            let xi = Int(px)
            let yi = Int(py)
            let zi = Int(pz)
            let r = Int(ceil(thickness))
            for dx in -r...r {
                for dy in -r...r {
                    for dz in -r...r {
                        let x = xi + dx
                        let y = yi + dy
                        let z = zi + dz
                        guard x >= 0, x < size, y >= 0, y < size, z >= 0, z < size else { continue }
                        let fdx = Float(x) - px + 0.5
                        let fdy = Float(y) - py + 0.5
                        let fdz = Float(z) - pz + 0.5
                        let dist = (fdx * fdx + fdy * fdy + fdz * fdz).squareRoot()
                        if dist <= thickness {
                            setCell(x: x, y: y, z: z, alive: true)
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A 3D Menger sponge — a fractal cube with recursive square holes through each face.
    mutating func loadMengerSponge() {
        clearAll()
        let margin = max(1, size / 8)
        let extent = size - 2 * margin
        guard extent > 0 else { return }
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let lx = x - margin
                    let ly = y - margin
                    let lz = z - margin
                    guard lx >= 0, lx < extent, ly >= 0, ly < extent, lz >= 0, lz < extent else { continue }
                    if Self.isMengerSolid(lx, ly, lz, extent) {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    private static func isMengerSolid(_ x: Int, _ y: Int, _ z: Int, _ extent: Int) -> Bool {
        var cx = x, cy = y, cz = z, side = extent
        while side >= 3 {
            let third = side / 3
            var centerCount = 0
            if cx / third == 1 { centerCount += 1 }
            if cy / third == 1 { centerCount += 1 }
            if cz / third == 1 { centerCount += 1 }
            if centerCount >= 2 { return false }
            cx %= third; cy %= third; cz %= third; side = third
        }
        return true
    }

    /// A wireframe cube — only the 12 edges are populated with cells.
    mutating func loadCage() {
        clearAll()
        let margin = max(1, size / 6)
        let lo = margin
        let hi = size - 1 - margin
        for x in lo...hi {
            setCell(x: x, y: lo, z: lo, alive: true)
            setCell(x: x, y: lo, z: hi, alive: true)
            setCell(x: x, y: hi, z: lo, alive: true)
            setCell(x: x, y: hi, z: hi, alive: true)
        }
        for y in lo...hi {
            setCell(x: lo, y: y, z: lo, alive: true)
            setCell(x: lo, y: y, z: hi, alive: true)
            setCell(x: hi, y: y, z: lo, alive: true)
            setCell(x: hi, y: y, z: hi, alive: true)
        }
        for z in lo...hi {
            setCell(x: lo, y: lo, z: z, alive: true)
            setCell(x: lo, y: hi, z: z, alive: true)
            setCell(x: hi, y: lo, z: z, alive: true)
            setCell(x: hi, y: hi, z: z, alive: true)
        }
        rebuildAliveCellIndices()
    }

    /// A 3D snowflake — 6 radial arms along the positive/negative X, Y, Z axes
    /// emanating from a dense central core, with perpendicular cross-bars at intervals
    /// for structural support. Creates 6-fold axial symmetry (octahedral point group).
    /// The arms have enough thickness to sustain evolution under standard rules, and
    /// the cross-bars create localized high-density nodes that persist while the arms erode.
    mutating func loadSnowflake() {
        clearAll()
        let mid = size / 2
        let armLength = min(size / 3, 6)
        let coreR = max(1, armLength / 3)

        // Dense spherical core
        for x in (mid - coreR)...(mid + coreR) {
            for y in (mid - coreR)...(mid + coreR) {
                for z in (mid - coreR)...(mid + coreR) {
                    let dx = x - mid, dy = y - mid, dz = z - mid
                    if dx * dx + dy * dy + dz * dz <= coreR * coreR {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }

        // 6 arms along ±X, ±Y, ±Z with thickness of 1 cell on each side
        for d in 1...armLength {
            for offset in -1...1 {
                // +X arm
                setCell(x: mid + d, y: mid + offset, z: mid, alive: true)
                setCell(x: mid + d, y: mid, z: mid + offset, alive: true)
                // -X arm
                setCell(x: mid - d, y: mid + offset, z: mid, alive: true)
                setCell(x: mid - d, y: mid, z: mid + offset, alive: true)
                // +Y arm
                setCell(x: mid + offset, y: mid + d, z: mid, alive: true)
                setCell(x: mid, y: mid + d, z: mid + offset, alive: true)
                // -Y arm
                setCell(x: mid + offset, y: mid - d, z: mid, alive: true)
                setCell(x: mid, y: mid - d, z: mid + offset, alive: true)
                // +Z arm
                setCell(x: mid + offset, y: mid, z: mid + d, alive: true)
                setCell(x: mid, y: mid + offset, z: mid + d, alive: true)
                // -Z arm
                setCell(x: mid + offset, y: mid, z: mid - d, alive: true)
                setCell(x: mid, y: mid + offset, z: mid - d, alive: true)
            }
            // Cross-bars at midpoints along each arm for structural nodes
            if d == armLength / 2 || d == armLength {
                for o1 in -1...1 {
                    for o2 in -1...1 {
                        setCell(x: mid + d, y: mid + o1, z: mid + o2, alive: true)
                        setCell(x: mid - d, y: mid + o1, z: mid + o2, alive: true)
                        setCell(x: mid + o1, y: mid + d, z: mid + o2, alive: true)
                        setCell(x: mid + o1, y: mid - d, z: mid + o2, alive: true)
                        setCell(x: mid + o1, y: mid + o2, z: mid + d, alive: true)
                        setCell(x: mid + o1, y: mid + o2, z: mid - d, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Four dense clusters at the vertices of a regular tetrahedron inscribed in the grid.
    /// Each vertex is a small solid sphere of cells. The four clusters evolve independently
    /// at first, then interact as they expand and their wavefronts collide — creating
    /// dramatic multi-center dynamics with interference patterns at the meeting points.
    mutating func loadTetrahedron() {
        clearAll()
        let mid = Float(size) / 2.0
        let radius = Float(min(size / 3, 5))
        let clusterR: Float = Float(min(size / 6, 3))

        // Regular tetrahedron vertices inscribed in a sphere of given radius.
        // Using coordinates that place the tetrahedron centered at origin:
        //   (1,1,1), (1,-1,-1), (-1,1,-1), (-1,-1,1) normalized to radius
        let scale = radius / Float(3.0).squareRoot()
        let vertices: [SIMD3<Float>] = [
            SIMD3( scale,  scale,  scale),
            SIMD3( scale, -scale, -scale),
            SIMD3(-scale,  scale, -scale),
            SIMD3(-scale, -scale,  scale),
        ]

        for vertex in vertices {
            let cx = mid + vertex.x
            let cy = mid + vertex.y
            let cz = mid + vertex.z
            for x in 0..<size {
                for y in 0..<size {
                    for z in 0..<size {
                        let dx = Float(x) - cx + 0.5
                        let dy = Float(y) - cy + 0.5
                        let dz = Float(z) - cz + 0.5
                        let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
                        if dist <= clusterR {
                            setCell(x: x, y: y, z: z, alive: true)
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A regular octahedron — the dual of a cube, with 8 triangular faces.
    /// Cells occupy the surface (|x-mid| + |y-mid| + |z-mid| == radius) of the
    /// L1 (Manhattan distance) sphere. The resulting diamond shape has 6 vertices
    /// and 12 edges. Under standard rules, flat triangular faces erode quickly while
    /// the 6 vertex points (higher local density) persist, producing a distinctive
    /// "dissolving gem" evolution that reveals the underlying symmetry axes.
    mutating func loadOctahedron() {
        clearAll()
        let mid = size / 2
        let radius = max(2, size / 3)
        let thickness = max(1, radius / 4)
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let d = abs(x - mid) + abs(y - mid) + abs(z - mid)
                    if d >= radius - thickness && d <= radius {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A regular dodecahedron — the dual of the icosahedron, with 12 pentagonal faces,
    /// 20 vertices, and 30 edges. Vertices are placed at the 20 positions of a regular
    /// dodecahedron inscribed in a sphere, connected by thick edges. Under standard rules,
    /// the thin edge sections erode first while vertex junctions (3 edges meeting = higher
    /// local density) persist, creating a skeletal fragmentation that eventually breaks into
    /// freely evolving clusters.
    mutating func loadDodecahedron() {
        clearAll()
        let mid = Float(size) / 2.0
        let radius = Float(min(size / 3, 6))
        let edgeThickness: Float = 1.3

        // Golden ratio for dodecahedron vertex coordinates
        let phi: Float = (1.0 + Float(5.0).squareRoot()) / 2.0
        let invPhi: Float = 1.0 / phi

        // 20 vertices of a regular dodecahedron (normalized to unit sphere, then scaled)
        // Three groups: 8 cube vertices, 4 on each axis pair
        let raw: [SIMD3<Float>] = [
            // 8 cube vertices (±1, ±1, ±1)
            SIMD3( 1,  1,  1), SIMD3( 1,  1, -1),
            SIMD3( 1, -1,  1), SIMD3( 1, -1, -1),
            SIMD3(-1,  1,  1), SIMD3(-1,  1, -1),
            SIMD3(-1, -1,  1), SIMD3(-1, -1, -1),
            // 4 on YZ plane (0, ±1/φ, ±φ)
            SIMD3(0,  invPhi,  phi), SIMD3(0,  invPhi, -phi),
            SIMD3(0, -invPhi,  phi), SIMD3(0, -invPhi, -phi),
            // 4 on XZ plane (±1/φ, 0, ±φ) — wait, correct is (±φ, 0, ±1/φ)
            SIMD3( phi, 0,  invPhi), SIMD3( phi, 0, -invPhi),
            SIMD3(-phi, 0,  invPhi), SIMD3(-phi, 0, -invPhi),
            // 4 on XY plane (±1/φ, ±φ, 0)
            SIMD3( invPhi,  phi, 0), SIMD3( invPhi, -phi, 0),
            SIMD3(-invPhi,  phi, 0), SIMD3(-invPhi, -phi, 0),
        ]

        // Normalize each vertex to unit sphere then scale to radius
        let verts = raw.map { v -> SIMD3<Float> in
            let len = simd_length(v)
            return v / len * radius
        }

        // Pre-compute edge pairs: two vertices share an edge if their angular distance
        // on the unit sphere matches the dodecahedron edge length (2/φ ≈ 1.236)
        let edgeLen: Float = 2.0 / phi
        let edgeThreshold: Float = edgeLen * 1.05
        var edges: [(Int, Int)] = []
        for i in 0..<raw.count {
            let ni = simd_normalize(raw[i])
            for j in (i+1)..<raw.count {
                let nj = simd_normalize(raw[j])
                let d = simd_length(ni - nj)
                if d < edgeThreshold {
                    edges.append((i, j))
                }
            }
        }

        // For each grid cell, check if it's near any edge
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let p = SIMD3<Float>(Float(x) - mid + 0.5,
                                         Float(y) - mid + 0.5,
                                         Float(z) - mid + 0.5)
                    var onEdge = false
                    for (i, j) in edges where !onEdge {
                        let a = verts[i]
                        let b = verts[j]
                        let ab = b - a
                        let ap = p - a
                        let abDot = simd_dot(ab, ab)
                        let t = max(Float(0), min(Float(1), simd_dot(ap, ab) / abDot))
                        let closest = a + t * ab
                        let dist = simd_length(p - closest)
                        if dist <= edgeThickness {
                            onEdge = true
                        }
                    }
                    if onEdge {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// A regular icosahedron — 12 vertices, 30 edges, 20 triangular faces. The fifth
    /// and final Platonic solid. Vertices are placed at (0, ±1, ±φ) and permutations,
    /// connected by thick edges. Under standard rules, the thin edge sections erode
    /// first while vertex junctions (5 edges meeting = highest local density among
    /// Platonic solids) persist longest, creating a distinctive star-burst fragmentation.
    mutating func loadIcosahedron() {
        clearAll()
        let mid = Float(size) / 2.0
        let radius = Float(min(size / 3, 6))
        let edgeThickness: Float = 1.3

        // Golden ratio
        let phi: Float = (1.0 + Float(5.0).squareRoot()) / 2.0

        // 12 vertices of a regular icosahedron (3 orthogonal golden rectangles)
        let raw: [SIMD3<Float>] = [
            SIMD3(0,  1,  phi), SIMD3(0,  1, -phi),
            SIMD3(0, -1,  phi), SIMD3(0, -1, -phi),
            SIMD3( 1,  phi, 0), SIMD3( 1, -phi, 0),
            SIMD3(-1,  phi, 0), SIMD3(-1, -phi, 0),
            SIMD3( phi, 0,  1), SIMD3( phi, 0, -1),
            SIMD3(-phi, 0,  1), SIMD3(-phi, 0, -1),
        ]

        // Normalize to unit sphere then scale
        let verts = raw.map { v -> SIMD3<Float> in
            let len = simd_length(v)
            return v / len * radius
        }

        // Edge detection: two vertices share an edge if their unit-sphere distance
        // matches the icosahedron edge length (2/φ ≈ 1.051 on unit sphere)
        let edgeLen: Float = 2.0 / phi
        let edgeThreshold: Float = edgeLen * 1.05
        var edges: [(Int, Int)] = []
        for i in 0..<raw.count {
            let ni = simd_normalize(raw[i])
            for j in (i+1)..<raw.count {
                let nj = simd_normalize(raw[j])
                let d = simd_length(ni - nj)
                if d < edgeThreshold {
                    edges.append((i, j))
                }
            }
        }

        // For each grid cell, check proximity to any edge
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let p = SIMD3<Float>(Float(x) - mid + 0.5,
                                         Float(y) - mid + 0.5,
                                         Float(z) - mid + 0.5)
                    var onEdge = false
                    for (i, j) in edges where !onEdge {
                        let a = verts[i]
                        let b = verts[j]
                        let ab = b - a
                        let ap = p - a
                        let abDot = simd_dot(ab, ab)
                        let t = max(Float(0), min(Float(1), simd_dot(ap, ab) / abDot))
                        let closest = a + t * ab
                        let dist = simd_length(p - closest)
                        if dist <= edgeThickness {
                            onEdge = true
                        }
                    }
                    if onEdge {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadMobiusStrip() {
        clearAll()
        let mid = Float(size) / 2.0
        let radius = Float(min(size / 3, 6))
        let halfWidth: Float = 2.5
        let steps = 200

        for step in 0..<steps {
            let t = Float(step) / Float(steps) * 2.0 * .pi
            // Center of the strip follows a circle
            let cx = radius * cos(t)
            let cy: Float = 0
            let cz = radius * sin(t)
            // Local frame: radial direction in XZ plane
            let radialX = cos(t)
            let radialZ = sin(t)
            // Möbius twist: the local "up" vector rotates by half a turn over the full loop
            let twist = t / 2.0
            // Sample across the strip width
            let widthSteps = 12
            for w in 0..<widthSteps {
                let s = (Float(w) / Float(widthSteps - 1) - 0.5) * 2.0 * halfWidth
                // The strip surface point: offset along twisted normal
                let upY = cos(twist)
                let upRadial = sin(twist)
                let px = cx + s * upRadial * radialX
                let py = cy + s * upY
                let pz = cz + s * upRadial * radialZ
                // Map to grid coordinates
                let gx = Int(round(px + mid - 0.5))
                let gy = Int(round(py + mid - 0.5))
                let gz = Int(round(pz + mid - 0.5))
                if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Klein bottle — a non-orientable closed surface with no boundary.
    /// Parametrized as a "figure-8" immersion in 3D where the surface passes through itself.
    mutating func loadKleinBottle() {
        clearAll()
        let mid = Float(size) / 2.0
        let scale = Float(min(size / 4, 5))
        let uSteps = 200
        let vSteps = 20

        for ui in 0..<uSteps {
            let u = Float(ui) / Float(uSteps) * 2.0 * .pi
            let cosU = cos(u)
            let sinU = sin(u)
            for vi in 0..<vSteps {
                let v = Float(vi) / Float(vSteps) * 2.0 * .pi
                // Figure-8 Klein bottle immersion
                let cosV = cos(v)
                let sin2V = sin(2.0 * v)
                let r: Float = 2.0

                let px = (r + cosU / 2.0 * cosV - sinU / 2.0 * sin2V) * cos(u) * scale / 3.0
                let py = (r + cosU / 2.0 * cosV - sinU / 2.0 * sin2V) * sin(u) * scale / 3.0
                let pz = (sinU / 2.0 * cosV + cosU / 2.0 * sin2V) * scale / 3.0

                let gx = Int(round(px + mid - 0.5))
                let gy = Int(round(py + mid - 0.5))
                let gz = Int(round(pz + mid - 0.5))
                if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func clearAll() {
        cells.withUnsafeMutableBufferPointer { buf in
            buf.update(repeating: 0)
        }
        dyingCells.removeAll(keepingCapacity: true)
        bornCells.removeAll(keepingCapacity: true)
        fadingCells.removeAll(keepingCapacity: true)
        aliveCellIndices.removeAll(keepingCapacity: true)
        aliveIndexMap.withUnsafeMutableBufferPointer { $0.update(repeating: -1) }
        aliveCount = 0
    }
}
