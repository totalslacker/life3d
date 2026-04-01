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
                            aliveIndexMap[idx] = -1
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
        aliveCount = aliveCellIndices.count
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

    mutating func loadLissajous() {
        clearAll()
        let mid = Float(size) / 2.0
        let scale = Float(size) / 2.0 - 1.5
        // Lissajous parameters: x = sin(at + δ), y = sin(bt), z = sin(ct)
        // Using a=2, b=3, c=5, δ=π/4 creates a complex, non-repeating 3D curve
        let a: Float = 2.0
        let b: Float = 3.0
        let c: Float = 5.0
        let delta: Float = .pi / 4.0
        let tubeRadius: Float = 1.3
        let steps = 500

        for step in 0..<steps {
            let t = Float(step) / Float(steps) * 2.0 * .pi
            let px = scale * sin(a * t + delta)
            let py = scale * sin(b * t)
            let pz = scale * sin(c * t)
            // Rasterize a thick tube around the curve point
            let r = Int(ceil(tubeRadius))
            for dx in -r...r {
                for dy in -r...r {
                    for dz in -r...r {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= tubeRadius {
                            let gx = Int(round(px + mid - 0.5)) + dx
                            let gy = Int(round(py + mid - 0.5)) + dy
                            let gz = Int(round(pz + mid - 0.5)) + dz
                            if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadKleinBottle() {
        clearAll()
        let mid = Float(size) / 2.0
        let scale = Float(size) / 2.0 - 1.5
        let tubeRadius: Float = 1.0
        let uSteps = 200
        let vSteps = 24

        for uStep in 0..<uSteps {
            let u = Float(uStep) / Float(uSteps) * 2.0 * .pi
            for vStep in 0..<vSteps {
                let v = Float(vStep) / Float(vSteps) * 2.0 * .pi
                // Figure-8 Klein bottle immersion in 3D
                let cosU = cos(u)
                let sinU = sin(u)
                let cosV = cos(v)
                let sinV = sin(v)
                let r = tubeRadius
                let px = scale * (cosU * (1.0 + sinV * r) * 0.5 + r * cosV * cos(u / 2.0))
                let py = scale * (sinU * (1.0 + sinV * r) * 0.5 + r * cosV * sin(u / 2.0))
                let pz = scale * r * sinV * 0.5
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

    mutating func loadGyroid() {
        clearAll()
        // Scale so one full period of the gyroid fits in the grid
        let freq = 2.0 * Float.pi / Float(size)
        // Threshold for the implicit surface |sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x)| < t
        let threshold: Float = 0.3

        for x in 0..<size {
            let fx = Float(x) * freq * 2.0
            let sinX = sin(fx)
            let cosX = cos(fx)
            for y in 0..<size {
                let fy = Float(y) * freq * 2.0
                let sinY = sin(fy)
                let cosY = cos(fy)
                for z in 0..<size {
                    let fz = Float(z) * freq * 2.0
                    let sinZ = sin(fz)
                    let cosZ = cos(fz)
                    let val = sinX * cosY + sinY * cosZ + sinZ * cosX
                    if abs(val) < threshold {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadLorenzAttractor() {
        clearAll()
        // Lorenz system parameters
        let sigma: Float = 10.0
        let rho: Float = 28.0
        let beta: Float = 8.0 / 3.0
        let dt: Float = 0.005
        let steps = 8000
        let tubeRadius: Float = 1.0

        // Initial condition (slightly off origin to break symmetry)
        var lx: Float = 1.0
        var ly: Float = 1.0
        var lz: Float = 1.0

        // Track min/max to scale the attractor into the grid
        var positions: [(Float, Float, Float)] = []
        positions.reserveCapacity(steps)

        for _ in 0..<steps {
            let dxdt = sigma * (ly - lx)
            let dydt = lx * (rho - lz) - ly
            let dzdt = lx * ly - beta * lz
            lx += dxdt * dt
            ly += dydt * dt
            lz += dzdt * dt
            positions.append((lx, ly, lz))
        }

        // Find bounding box
        var minX: Float = .infinity, maxX: Float = -.infinity
        var minY: Float = .infinity, maxY: Float = -.infinity
        var minZ: Float = .infinity, maxZ: Float = -.infinity
        for (px, py, pz) in positions {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }

        // Scale to fit grid with margin
        let margin: Float = 2.0
        let rangeX = maxX - minX
        let rangeY = maxY - minY
        let rangeZ = maxZ - minZ
        let maxRange = max(rangeX, max(rangeY, rangeZ))
        let gridScale = (Float(size) - 2.0 * margin) / maxRange

        let r = Int(ceil(tubeRadius))
        for (px, py, pz) in positions {
            let gxf = (px - minX) * gridScale + margin
            let gyf = (py - minY) * gridScale + margin
            let gzf = (pz - minZ) * gridScale + margin
            let cx = Int(round(gxf))
            let cy = Int(round(gyf))
            let cz = Int(round(gzf))
            for ddx in -r...r {
                for ddy in -r...r {
                    for ddz in -r...r {
                        let dist = sqrt(Float(ddx * ddx + ddy * ddy + ddz * ddz))
                        if dist <= tubeRadius {
                            let gx = cx + ddx
                            let gy = cy + ddy
                            let gz = cz + ddz
                            if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// 3D Hilbert curve — a space-filling fractal curve that visits every cell
    /// in a cube exactly once, creating a continuous winding path.
    mutating func loadHilbertCurve() {
        clearAll()
        // Determine the largest power-of-2 order that fits in the grid
        var order = 1
        while (1 << (order + 1)) <= size { order += 1 }
        let n = 1 << order  // side length of the Hilbert cube

        let totalPoints = n * n * n
        let tubeRadius: Float = 1.0
        let r = Int(ceil(tubeRadius))
        let offset = (size - n) / 2  // center in the grid

        // Generate 3D Hilbert curve points using iterative algorithm
        for d in 0..<totalPoints {
            var (x, y, z) = hilbert3D(d: d, order: order)
            x += offset
            y += offset
            z += offset

            // Rasterize as a thick tube
            for ddx in -r...r {
                for ddy in -r...r {
                    for ddz in -r...r {
                        let dist = Float(ddx * ddx + ddy * ddy + ddz * ddz)
                        if dist <= tubeRadius * tubeRadius {
                            let gx = x + ddx
                            let gy = y + ddy
                            let gz = z + ddz
                            if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Convert a linear index d to (x,y,z) on a 3D Hilbert curve of given order.
    private func hilbert3D(d: Int, order: Int) -> (Int, Int, Int) {
        var x = 0, y = 0, z = 0
        var dd = d
        for s in 0..<order {
            let step = 1 << s
            let rx = (dd >> 2) & 1
            let ry = ((dd >> 1) ^ rx) & 1
            let rz = (dd ^ ry) & 1

            // Rotate quadrant
            if rz == 0 {
                if ry == 1 {
                    x = step - 1 - x
                    y = step - 1 - y
                }
                if rx == 1 {
                    // Swap y and z
                    let tmp = y; y = z; z = tmp
                } else {
                    // Swap x and z
                    let tmp = x; x = z; z = tmp
                }
            }

            x += step * rx
            y += step * ry
            z += step * rz
            dd >>= 3
        }
        return (x, y, z)
    }

    /// Dragon Curve — a 3D extension of the classic fractal dragon curve.
    /// The 2D dragon curve is generated by repeated folding: at each iteration,
    /// Loads a catenoid — the minimal surface of revolution formed by rotating
    /// a catenary curve (cosh) around an axis. This is the shape a soap film
    /// takes when stretched between two parallel rings. The surface is defined
    /// parametrically: x = c·cosh(v/c)·cos(u), y = c·cosh(v/c)·sin(u), z = v,
    /// where u ∈ [0, 2π) is the angle around the axis and v spans the height.
    /// The parameter c controls the waist radius. The result is a smooth
    /// hourglass-shaped surface that thins at the middle and flares at the ends.
    mutating func loadCatenoid() {
        clearAll()
        let c: Float = Float(size) * 0.12 // waist radius parameter
        let halfH: Float = Float(size) * 0.38 // half-height of the catenoid
        let center = Float(size) / 2.0
        let uSteps = max(80, size * 6)
        let vSteps = max(40, size * 3)

        for ui in 0..<uSteps {
            let u = Float(ui) / Float(uSteps) * 2.0 * Float.pi
            for vi in 0..<vSteps {
                let v = -halfH + Float(vi) / Float(vSteps - 1) * 2.0 * halfH
                let r = c * cosh(v / c) // catenary radius at height v
                let fx = r * cos(u) + center
                let fy = r * sin(u) + center
                let fz = v + center
                // Rasterize with thickness for solid surface
                for dx in -1...1 {
                    for dy in -1...1 {
                        let gx = Int(fx) + dx
                        let gy = Int(fy) + dy
                        let gz = Int(fz)
                        if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                            setCell(x: gx, y: gy, z: gz, alive: true)
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Sierpinski Tetrahedron — a 3D fractal formed by the chaos game on a
    /// regular tetrahedron. The algorithm randomly picks one of four tetrahedron
    /// vertices and moves halfway toward it from the current point, plotting each
    /// result. After many iterations, the attractor converges to the Sierpinski
    /// tetrahedron (also known as a tetrix), a self-similar fractal with Hausdorff
    /// dimension 2. Under evolution, the fractal's porous structure creates varied
    /// neighbor densities — dense cluster zones persist while sparse fractal dust
    /// erodes quickly.
    mutating func loadSierpinskiTetrahedron() {
        clearAll()
        let s = Float(size)

        // Regular tetrahedron vertices filling the grid
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(s * 0.5, s * 0.1, s * 0.5),
            SIMD3<Float>(s * 0.1, s * 0.9, s * 0.2),
            SIMD3<Float>(s * 0.9, s * 0.9, s * 0.2),
            SIMD3<Float>(s * 0.5, s * 0.9, s * 0.9)
        ]

        // Chaos game: iterate many times
        let iterations = size * size * size * 4
        var point = SIMD3<Float>(s * 0.5, s * 0.5, s * 0.5)

        // Simple LCG for deterministic results
        var seed: UInt64 = 42
        for _ in 0..<iterations {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            let vi = Int((seed >> 33) % 4)
            point = (point + vertices[vi]) * 0.5
            let gx = Int(point.x)
            let gy = Int(point.y)
            let gz = Int(point.z)
            if gx >= 0 && gx < size && gy >= 0 && gy < size && gz >= 0 && gz < size {
                setCell(x: gx, y: gy, z: gz, alive: true)
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadDragonCurve() {
        clearAll()
        // Build 2D dragon curve turn sequence: R=1, L=0
        // Each iteration: take existing, append R, then reversed-and-flipped tail
        let iterations = max(8, min(14, Int(log2(Float(size * size)))))
        var turns: [Int] = []
        for _ in 0..<iterations {
            var newTurns = turns
            newTurns.append(1) // right turn
            for t in turns.reversed() {
                newTurns.append(1 - t) // flip
            }
            turns = newTurns
        }

        // Trace the curve in 2D (dx, dy directions: 0=+x, 1=+y, 2=-x, 3=-y)
        let dirX = [1, 0, -1, 0]
        let dirY = [0, 1, 0, -1]
        var points: [(Int, Int)] = [(0, 0)]
        var dir = 0
        for t in turns {
            if t == 1 {
                dir = (dir + 1) & 3 // right
            } else {
                dir = (dir + 3) & 3 // left
            }
            let last = points[points.count - 1]
            points.append((last.0 + dirX[dir], last.1 + dirY[dir]))
        }

        // Find bounding box and scale to fit grid
        var minX = Int.max, maxX = Int.min, minY = Int.max, maxY = Int.min
        for p in points {
            minX = min(minX, p.0); maxX = max(maxX, p.0)
            minY = min(minY, p.1); maxY = max(maxY, p.1)
        }
        let rangeX = max(1, maxX - minX)
        let rangeY = max(1, maxY - minY)
        let margin = 1
        let usable = size - 2 * margin

        // Extrude into 3D: stack layers with the curve, alternating z-layers
        let zLayers = max(3, size / 4)
        let zStart = (size - zLayers) / 2

        for layer in 0..<zLayers {
            let gz = zStart + layer
            if gz < 0 || gz >= size { continue }
            for p in points {
                let gx = margin + (p.0 - minX) * usable / rangeX
                let gy = margin + (p.1 - minY) * usable / rangeY
                if gx >= 0, gx < size, gy >= 0, gy < size {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadApollonianGasket() {
        clearAll()
        // 3D Apollonian gasket: recursively pack spheres into the gaps between
        // 4 initial mutually tangent spheres arranged tetrahedrally.
        // Each sphere is rasterized as filled voxels within its radius.
        let center = Float(size) / 2.0
        let mainRadius = Float(size) * 0.42

        // Collect all spheres (center, radius) via recursive packing
        var spheres: [(SIMD3<Float>, Float)] = []

        // 4 initial spheres at tetrahedral vertices, tangent to each other
        let tetR = mainRadius * 0.42  // radius of each initial sphere
        let tetDist = tetR * 2.0      // distance between centers = 2r (tangent)
        // Tetrahedral vertex positions centered at origin
        let sqrt2over3: Float = sqrt(2.0 / 3.0)
        let sqrt6over3: Float = sqrt(6.0) / 3.0
        let tetVerts: [SIMD3<Float>] = [
            SIMD3<Float>(0, 1, -1.0 / sqrt(2.0)),
            SIMD3<Float>(-sqrt2over3 * sqrt(3.0) / 2.0, -0.5, -1.0 / sqrt(2.0)),
            SIMD3<Float>(sqrt2over3 * sqrt(3.0) / 2.0, -0.5, -1.0 / sqrt(2.0)),
            SIMD3<Float>(0, 0, sqrt6over3 - 1.0 / sqrt(2.0))
        ]
        // Scale and center
        for v in tetVerts {
            let pos = v * tetDist + SIMD3<Float>(repeating: center)
            spheres.append((pos, tetR))
        }

        // Recursively fill gaps between triplets of spheres
        func fillGap(s1: (SIMD3<Float>, Float), s2: (SIMD3<Float>, Float),
                     s3: (SIMD3<Float>, Float), depth: Int) {
            guard depth > 0 else { return }
            // Incircle of the triangle formed by three sphere centers,
            // with radius that fits tangent to all three
            let c = (s1.0 + s2.0 + s3.0) / 3.0
            let d1 = simd_length(s1.0 - s2.0)
            let d2 = simd_length(s2.0 - s3.0)
            let d3 = simd_length(s1.0 - s3.0)
            let avgDist = (d1 + d2 + d3) / 3.0
            let newR = (avgDist - s1.1 - s2.1) * 0.35
            guard newR >= 1.0 else { return }  // Stop when too small to voxelize
            spheres.append((c, newR))
            // Recurse on the 3 new gaps
            fillGap(s1: (c, newR), s2: s2, s3: s3, depth: depth - 1)
            fillGap(s1: s1, s2: (c, newR), s3: s3, depth: depth - 1)
            fillGap(s1: s1, s2: s2, s3: (c, newR), depth: depth - 1)
        }

        let maxDepth = size >= 24 ? 4 : 3
        // Fill gaps between all combinations of 3 from the 4 initial spheres
        let indices4 = [(0,1,2), (0,1,3), (0,2,3), (1,2,3)]
        for (a, b, c) in indices4 {
            fillGap(s1: spheres[a], s2: spheres[b], s3: spheres[c], depth: maxDepth)
        }

        // Rasterize all spheres
        for (sCenter, sRadius) in spheres {
            let rSq = sRadius * sRadius
            let lo = max(0, Int(sCenter.x - sRadius) - 1)
            let hi = min(size - 1, Int(sCenter.x + sRadius) + 1)
            for gx in lo...hi {
                for gy in max(0, Int(sCenter.y - sRadius) - 1)...min(size - 1, Int(sCenter.y + sRadius) + 1) {
                    for gz in max(0, Int(sCenter.z - sRadius) - 1)...min(size - 1, Int(sCenter.z + sRadius) + 1) {
                        let dx = Float(gx) + 0.5 - sCenter.x
                        let dy = Float(gy) + 0.5 - sCenter.y
                        let dz = Float(gz) + 0.5 - sCenter.z
                        if dx * dx + dy * dy + dz * dz <= rSq {
                            setCell(x: gx, y: gy, z: gz, alive: true)
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadTorusKnot() {
        clearAll()
        let s = Float(size)
        let center = s / 2.0
        // A (p,q) torus knot winds p times around the torus axis and q times
        // through the hole. We use (2,3) — the trefoil's cousin on a torus.
        // Parametric: x = (R + r·cos(q·t))·cos(p·t),
        //             y = (R + r·cos(q·t))·sin(p·t),
        //             z = r·sin(q·t)
        // where R is the major radius and r is the minor radius.
        let p: Float = 2.0
        let q: Float = 3.0
        let majorRadius: Float = s * 0.28
        let minorRadius: Float = s * 0.12
        let steps = max(400, size * 25)
        let tubeRadius: Float = 1.5  // voxel thickening radius

        for i in 0..<steps {
            let t = Float(i) / Float(steps) * 2.0 * .pi
            let r = majorRadius + minorRadius * cos(q * t)
            let px = center + r * cos(p * t)
            let py = center + r * sin(p * t)
            let pz = center + minorRadius * sin(q * t)
            // Thicken the curve into a tube for voxel visibility
            let ix = Int(round(px))
            let iy = Int(round(py))
            let iz = Int(round(pz))
            let tr = Int(ceil(tubeRadius))
            for dx in -tr...tr {
                for dy in -tr...tr {
                    for dz in -tr...tr {
                        let dist = Float(dx * dx + dy * dy + dz * dz)
                        if dist <= tubeRadius * tubeRadius {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0, gx < size, gy >= 0, gy < size, gz >= 0, gz < size {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadKochSnowflake() {
        clearAll()
        // Build a 3D Koch snowflake: generate 2D Koch curve boundary, fill interior, extrude into 3D
        // The Koch snowflake is formed by starting with an equilateral triangle and recursively
        // adding smaller triangles to each edge. We approximate this by computing the snowflake
        // boundary points and rasterizing them onto a 2D grid, then extruding.
        let depth = max(2, min(5, Int(log2(Float(size)))))
        let margin = 1
        let usable = Float(size - 2 * margin)
        let center = Float(size) / 2.0

        // Generate Koch snowflake vertices starting from equilateral triangle
        func kochEdge(_ ax: Float, _ ay: Float, _ bx: Float, _ by: Float, _ level: Int) -> [(Float, Float)] {
            if level == 0 {
                return [(ax, ay)]
            }
            let dx = bx - ax, dy = by - ay
            let p1x = ax + dx / 3, p1y = ay + dy / 3
            let p2x = ax + 2 * dx / 3, p2y = ay + 2 * dy / 3
            // Peak of equilateral triangle on the edge
            let peakX = (ax + bx) / 2 - (by - ay) * Float(3).squareRoot() / 6
            let peakY = (ay + by) / 2 + (bx - ax) * Float(3).squareRoot() / 6
            var pts: [(Float, Float)] = []
            pts.append(contentsOf: kochEdge(ax, ay, p1x, p1y, level - 1))
            pts.append(contentsOf: kochEdge(p1x, p1y, peakX, peakY, level - 1))
            pts.append(contentsOf: kochEdge(peakX, peakY, p2x, p2y, level - 1))
            pts.append(contentsOf: kochEdge(p2x, p2y, bx, by, level - 1))
            return pts
        }

        // Equilateral triangle centered in the grid (2D, normalized to usable area)
        let r = usable * 0.45
        let t0x = center, t0y = center - r
        let t1x = center - r * Float(3).squareRoot() / 2, t1y = center + r / 2
        let t2x = center + r * Float(3).squareRoot() / 2, t2y = center + r / 2

        var boundary: [(Float, Float)] = []
        boundary.append(contentsOf: kochEdge(t0x, t0y, t1x, t1y, depth))
        boundary.append(contentsOf: kochEdge(t1x, t1y, t2x, t2y, depth))
        boundary.append(contentsOf: kochEdge(t2x, t2y, t0x, t0y, depth))

        // Rasterize boundary onto 2D grid using line drawing
        var filled = [Bool](repeating: false, count: size * size)
        func plotLine(_ x0: Float, _ y0: Float, _ x1: Float, _ y1: Float) {
            let steps = max(Int(abs(x1 - x0)), Int(abs(y1 - y0)), 1)
            for s in 0...steps {
                let t = Float(s) / Float(steps)
                let px = Int(x0 + (x1 - x0) * t)
                let py = Int(y0 + (y1 - y0) * t)
                if px >= 0, px < size, py >= 0, py < size {
                    filled[py * size + px] = true
                }
            }
        }
        for i in 0..<boundary.count {
            let a = boundary[i]
            let b = boundary[(i + 1) % boundary.count]
            plotLine(a.0, a.1, b.0, b.1)
        }

        // Flood-fill exterior then invert to get filled snowflake
        var exterior = [Bool](repeating: false, count: size * size)
        var queue = [Int]()
        // Seed from edges
        for i in 0..<size {
            if !filled[i] { exterior[i] = true; queue.append(i) }
            let bottom = (size - 1) * size + i
            if !filled[bottom] { exterior[bottom] = true; queue.append(bottom) }
            let left = i * size
            if !filled[left] { exterior[left] = true; queue.append(left) }
            let right = i * size + (size - 1)
            if !filled[right] { exterior[right] = true; queue.append(right) }
        }
        while !queue.isEmpty {
            let idx = queue.removeLast()
            let row = idx / size, col = idx % size
            let neighbors = [(row-1, col), (row+1, col), (row, col-1), (row, col+1)]
            for (nr, nc) in neighbors {
                if nr >= 0, nr < size, nc >= 0, nc < size {
                    let ni = nr * size + nc
                    if !filled[ni], !exterior[ni] {
                        exterior[ni] = true
                        queue.append(ni)
                    }
                }
            }
        }

        // Extrude into 3D: fill layers around center z
        let zLayers = max(3, size / 4)
        let zStart = (size - zLayers) / 2
        for layer in 0..<zLayers {
            let gz = zStart + layer
            if gz < 0 || gz >= size { continue }
            for row in 0..<size {
                for col in 0..<size {
                    let idx2d = row * size + col
                    if !exterior[idx2d] { // interior or boundary
                        setCell(x: col, y: row, z: gz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Reuleaux Tetrahedron — a 3D curve of constant width formed by the intersection
    /// of four spheres, each centered at one vertex of a regular tetrahedron with radius
    /// equal to the tetrahedron's edge length. The resulting solid has curved triangular
    /// faces and is the simplest non-spherical body of constant width in 3D. Under
    /// evolution, the curved surfaces erode while the thicker central region persists.
    mutating func loadReuleauxTetrahedron() {
        clearAll()
        let s = Float(size)
        let center = s / 2.0
        let edge = s * 0.45 // edge length scaled to grid

        // Regular tetrahedron vertices centered in grid
        let sqrt3 = Float(3.0).squareRoot()
        let sqrt6 = Float(6.0).squareRoot()
        let vertices: [SIMD3<Float>] = [
            SIMD3<Float>(0, 1, 0),
            SIMD3<Float>(-sqrt3 / 3.0, -1.0 / 3.0, sqrt6 / 3.0),
            SIMD3<Float>(sqrt3 * 2.0 / 3.0, -1.0 / 3.0, 0),
            SIMD3<Float>(-sqrt3 / 3.0, -1.0 / 3.0, -sqrt6 / 3.0)
        ]

        // Scale and center the tetrahedron vertices
        let scale = edge / 2.0
        let scaledVertices = vertices.map { v in
            SIMD3<Float>(v.x * scale + center, v.y * scale + center, v.z * scale + center)
        }

        let radiusSq = edge * edge // sphere radius = edge length

        // A point is inside the Reuleaux tetrahedron if it's within ALL four spheres
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let p = SIMD3<Float>(Float(x) + 0.5, Float(y) + 0.5, Float(z) + 0.5)
                    var insideAll = true
                    for sv in scaledVertices {
                        let d = p - sv
                        if simd_length_squared(d) > radiusSq {
                            insideAll = false
                            break
                        }
                    }
                    if insideAll {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadMandelbulb() {
        clearAll()
        // Mandelbulb: 3D extension of the Mandelbrot set using spherical coordinates.
        // For each voxel, map to [-1.5, 1.5]³ and iterate z = z^n + c where the power
        // operation uses spherical coordinates: (r, θ, φ) → (r^n, nθ, nφ).
        // The power-8 Mandelbulb is the most visually striking variant.
        let n: Float = 8.0
        let maxIter = 8
        let bailout: Float = 2.0
        let bailoutSq = bailout * bailout
        let scale: Float = 3.0 / Float(size)  // Map grid to [-1.5, 1.5]³

        for gx in 0..<size {
            for gy in 0..<size {
                for gz in 0..<size {
                    // Map to continuous coordinates centered at origin
                    let cx = (Float(gx) + 0.5) * scale - 1.5
                    let cy = (Float(gy) + 0.5) * scale - 1.5
                    let cz = (Float(gz) + 0.5) * scale - 1.5

                    var zx = cx, zy = cy, zz = cz
                    var escaped = false

                    for _ in 0..<maxIter {
                        let rSq = zx * zx + zy * zy + zz * zz
                        if rSq > bailoutSq {
                            escaped = true
                            break
                        }
                        let r = sqrt(rSq)
                        let theta = acos(zz / max(r, 1e-10))
                        let phi = atan2(zy, zx)

                        let rN = pow(r, n)
                        let nTheta = n * theta
                        let nPhi = n * phi

                        zx = rN * sin(nTheta) * cos(nPhi) + cx
                        zy = rN * sin(nTheta) * sin(nPhi) + cy
                        zz = rN * cos(nTheta) + cz
                    }

                    if !escaped {
                        setCell(x: gx, y: gy, z: gz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    // MARK: - Julia Set (Quaternion)
    mutating func loadJuliaSet() {
        clearAll()
        // 3D Julia set using quaternion iteration.
        // For each voxel, map to continuous coordinates and iterate
        // q = q² + c where q is a quaternion (x, y, z, 0) and c is a
        // fixed quaternion constant chosen for visual interest.
        // Points that don't escape are inside the Julia set.
        let maxIter = 10
        let bailoutSq: Float = 4.0
        let scale: Float = 3.0 / Float(size)
        // c constant: produces a connected, visually rich Julia set
        let cx: Float = -0.2, cy: Float = 0.6, cz: Float = 0.2, cw: Float = 0.0

        for gx in 0..<size {
            for gy in 0..<size {
                for gz in 0..<size {
                    // Map voxel to [-1.5, 1.5]³
                    var qx = (Float(gx) + 0.5) * scale - 1.5
                    var qy = (Float(gy) + 0.5) * scale - 1.5
                    var qz = (Float(gz) + 0.5) * scale - 1.5
                    var qw: Float = 0.0

                    var escaped = false
                    for _ in 0..<maxIter {
                        let rSq = qx * qx + qy * qy + qz * qz + qw * qw
                        if rSq > bailoutSq {
                            escaped = true
                            break
                        }
                        // Quaternion square: q² = (x² - y² - z² - w², 2xy, 2xz, 2xw)
                        let nx = qx * qx - qy * qy - qz * qz - qw * qw + cx
                        let ny = 2.0 * qx * qy + cy
                        let nz = 2.0 * qx * qz + cz
                        let nw = 2.0 * qx * qw + cw
                        qx = nx; qy = ny; qz = nz; qw = nw
                    }

                    if !escaped {
                        setCell(x: gx, y: gy, z: gz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadCantorDust() {
        clearAll()
        // Cantor Dust: 3D generalization of the Cantor set. Start with the full
        // cube and recursively remove the middle third along each axis. At each
        // recursion level, the cube is divided into 27 sub-cubes (3×3×3) and only
        // the 8 corner sub-cubes are kept — the same rule applied along x, y, z.
        // After k iterations, 8^k cubes remain out of 27^k, giving fractal
        // dimension ln(8)/ln(3) ≈ 1.89. The result is a dust-like structure with
        // self-similar voids at every scale.
        let maxDepth = size >= 27 ? 3 : (size >= 9 ? 2 : 1)

        func fillCantor(x0: Int, y0: Int, z0: Int, span: Int, depth: Int) {
            if depth >= maxDepth || span <= 1 {
                // Base case: fill the entire sub-cube
                for gx in x0..<min(x0 + span, size) {
                    for gy in y0..<min(y0 + span, size) {
                        for gz in z0..<min(z0 + span, size) {
                            setCell(x: gx, y: gy, z: gz, alive: true)
                        }
                    }
                }
                return
            }
            let third = span / 3
            if third < 1 { // span too small to subdivide further
                for gx in x0..<min(x0 + span, size) {
                    for gy in y0..<min(y0 + span, size) {
                        for gz in z0..<min(z0 + span, size) {
                            setCell(x: gx, y: gy, z: gz, alive: true)
                        }
                    }
                }
                return
            }
            // Recurse into the 8 corner sub-cubes only (skip middle third on each axis)
            for dx in [0, 2] {
                for dy in [0, 2] {
                    for dz in [0, 2] {
                        fillCantor(x0: x0 + dx * third, y0: y0 + dy * third,
                                   z0: z0 + dz * third, span: third, depth: depth + 1)
                    }
                }
            }
        }

        fillCantor(x0: 0, y0: 0, z0: 0, span: size, depth: 0)
        rebuildAliveCellIndices()
    }

    /// 3D Barnsley Fern — the classic IFS fractal fern extended into 3D by rotating
    /// the 2D fern around its stem axis. The standard Barnsley fern uses four affine
    /// transformations with probabilities that produce a realistic fern frond. The 3D
    /// extension applies the same (x, y) → (x', y') maps then wraps x' around the
    /// Y-axis using cylindrical coordinates, giving a rotationally symmetric fern.
    mutating func loadBarnsleyFern() {
        clearAll()
        let n = size
        // Run the IFS chaos game in 2D, collect (x, y) points
        let iterations = n * n * n * 4
        var points: [(Double, Double)] = []
        points.reserveCapacity(iterations)
        var x = 0.0
        var y = 0.0
        for _ in 0..<iterations {
            let r = Double.random(in: 0..<1)
            let (nx, ny): (Double, Double)
            if r < 0.01 {
                // Stem
                nx = 0.0
                ny = 0.16 * y
            } else if r < 0.86 {
                // Main frond (successively smaller leaflets)
                nx = 0.85 * x + 0.04 * y
                ny = -0.04 * x + 0.85 * y + 1.6
            } else if r < 0.93 {
                // Left leaflet
                nx = 0.20 * x - 0.26 * y
                ny = 0.23 * x + 0.22 * y + 1.6
            } else {
                // Right leaflet
                nx = -0.15 * x + 0.28 * y
                ny = 0.26 * x + 0.24 * y + 0.44
            }
            x = nx
            y = ny
            points.append((x, y))
        }
        // Find bounding box of 2D fern
        var minX = Double.infinity, maxX = -Double.infinity
        var minY = Double.infinity, maxY = -Double.infinity
        for (px, py) in points {
            if px < minX { minX = px }
            if px > maxX { maxX = px }
            if py < minY { minY = py }
            if py > maxY { maxY = py }
        }
        let rangeX = maxX - minX
        let rangeY = maxY - minY
        guard rangeX > 0 && rangeY > 0 else {
            rebuildAliveCellIndices()
            return
        }
        // Map 2D fern points to 3D voxels by rotating around the Y-axis
        let margin = 1
        let usable = n - 2 * margin
        for (px, py) in points {
            // Normalize to [0, 1]
            let nx = (px - minX) / rangeX
            let ny = (py - minY) / rangeY
            // The fern's x becomes a radial distance, y becomes height
            let radius = nx * Double(usable) * 0.4
            let height = Int(ny * Double(usable - 1)) + margin
            // Rotate around Y-axis at several angles for a bushy 3D fern
            let angleCount = max(6, n / 3)
            for ai in 0..<angleCount {
                let angle = Double(ai) * (2.0 * .pi / Double(angleCount))
                let gx = Int(Double(n / 2) + radius * cos(angle))
                let gz = Int(Double(n / 2) + radius * sin(angle))
                let gy = height
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// 3D Vicsek Fractal — a cross-shaped recursive fractal. At each recursion level,
    /// a cube is divided into a 3×3×3 grid of 27 sub-cubes. Only the center sub-cube
    /// and the 6 face-adjacent sub-cubes are kept (forming a 3D plus/cross shape),
    /// discarding the 20 edge and corner sub-cubes. This is the dual of the Menger
    /// Sponge, which keeps the 20 and removes the 7. After k iterations, 7^k cubes
    /// remain out of 27^k, giving a fractal dimension of ln(7)/ln(3) ≈ 1.77.
    /// Under evolution, the thin arms of the cross erode first at their tips while
    /// the dense central junction retains higher neighbor density and persists longer.
    mutating func loadVicsekFractal() {
        clearAll()
        let n = size
        // Recursion depth scaled to grid size
        let maxDepth: Int
        if n >= 27 { maxDepth = 3 }
        else if n >= 9 { maxDepth = 2 }
        else { maxDepth = 1 }

        func fillVicsek(x0: Int, y0: Int, z0: Int, span: Int, depth: Int) {
            if depth >= maxDepth || span <= 1 {
                // Fill this entire sub-cube
                for x in x0..<min(x0 + span, n) {
                    for y in y0..<min(y0 + span, n) {
                        for z in z0..<min(z0 + span, n) {
                            setCell(x: x, y: y, z: z, alive: true)
                        }
                    }
                }
                return
            }
            let sub = span / 3
            if sub < 1 { return }
            // Keep only center + 6 face-adjacent sub-cubes (the 3D cross)
            // Center is at (1,1,1), face-adjacent are the 6 with exactly one
            // coordinate differing from 1 by ±1 while the other two are 1
            let kept: [(Int, Int, Int)] = [
                (1, 1, 1),  // center
                (0, 1, 1),  // -x face
                (2, 1, 1),  // +x face
                (1, 0, 1),  // -y face
                (1, 2, 1),  // +y face
                (1, 1, 0),  // -z face
                (1, 1, 2),  // +z face
            ]
            for (dx, dy, dz) in kept {
                fillVicsek(x0: x0 + dx * sub, y0: y0 + dy * sub, z0: z0 + dz * sub,
                           span: sub, depth: depth + 1)
            }
        }

        fillVicsek(x0: 0, y0: 0, z0: 0, span: n, depth: 0)
        rebuildAliveCellIndices()
    }

    mutating func loadBurningShip() {
        clearAll()
        let n = size
        // 3D Burning Ship fractal: like Mandelbrot but takes absolute values
        // before squaring, producing an asymmetric ship-like structure.
        // Iterate z = (|Re(z)| + i|Im(z)|)^2 + c for each point c in space.
        // The 3D version uses a triplex number system similar to Mandelbulb.
        let maxIter = 8
        let bailout = 4.0
        let scale = 3.0 / Double(n)
        let half = Double(n) / 2.0
        for x in 0..<n {
            for y in 0..<n {
                for z in 0..<n {
                    // Map voxel to [-1.5, 1.5]^3
                    let cx = (Double(x) - half) * scale
                    let cy = (Double(y) - half) * scale
                    let cz = (Double(z) - half) * scale
                    var zx = 0.0, zy = 0.0, zz = 0.0
                    var inside = true
                    for _ in 0..<maxIter {
                        // Take absolute values (the "burning ship" twist)
                        let ax = abs(zx)
                        let ay = abs(zy)
                        let az = abs(zz)
                        // Spherical coordinates for triplex power-2
                        let r = (ax * ax + ay * ay + az * az).squareRoot()
                        if r * r > bailout { inside = false; break }
                        if r < 1e-10 {
                            zx = cx; zy = cy; zz = cz
                            continue
                        }
                        let theta = acos(ay / r)
                        let phi = atan2(az, ax)
                        let r2 = r * r
                        let s2t = sin(2.0 * theta)
                        zx = r2 * s2t * cos(2.0 * phi) + cx
                        zy = r2 * cos(2.0 * theta) + cy
                        zz = r2 * s2t * sin(2.0 * phi) + cz
                    }
                    if inside {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadHopfFibration() {
        clearAll()
        let n = size
        // The Hopf fibration maps S³ → S² with S¹ fibers. We visualize it by
        // stereographically projecting fibers back to R³. For a grid of base
        // points on S² parameterized by (θ, φ), the fiber through that point
        // is a circle in R³. We sample several base points and trace their
        // circles, filling nearby voxels.
        let fiberCount = max(8, n / 2)  // number of fibers
        let pointsPerFiber = n * 4      // sample density per fiber

        for f in 0..<fiberCount {
            // Base point on S²: evenly spaced latitude
            let theta = Float.pi * Float(f) / Float(fiberCount)  // [0, π]
            let phi = Float.pi * 2.0 * Float(f) * 0.618034  // golden angle for spread

            // Lift to S³: one point in the fiber over (θ, φ)
            let cosH = cos(theta / 2.0)
            let sinH = sin(theta / 2.0)

            for p in 0..<pointsPerFiber {
                // Rotate around the fiber (S¹ action on S³)
                let t = Float.pi * 2.0 * Float(p) / Float(pointsPerFiber)
                // S³ point: (cos(θ/2)e^{it}, sin(θ/2)e^{i(t+φ)})
                let q0 = cosH * cos(t)
                let q1 = cosH * sin(t)
                let q2 = sinH * cos(t + phi)
                let q3 = sinH * sin(t + phi)
                // Stereographic projection from S³ to R³ (project from north pole (1,0,0,0))
                let denom = 1.0 - q0 + 1e-6
                let px = q1 / denom
                let py = q2 / denom
                let pz = q3 / denom
                // Scale projected point into grid
                let gx = px * 0.3 + 0.5  // normalize to ~[0,1]
                let gy = py * 0.3 + 0.5
                let gz = pz * 0.3 + 0.5
                // Map to voxel coordinates
                let vx = Int((gx * Float(n)).rounded())
                let vy = Int((gy * Float(n)).rounded())
                let vz = Int((gz * Float(n)).rounded())
                if vx >= 0 && vx < n && vy >= 0 && vy < n && vz >= 0 && vz < n {
                    setCell(x: vx, y: vy, z: vz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadEnneperSurface() {
        clearAll()
        let n = size
        // Enneper surface: a classical minimal surface from differential geometry.
        // Parametric form: x = u - u³/3 + uv², y = v - v³/3 + vu², z = u² - v²
        // The surface self-intersects, creating an elegant ruffled shape.
        let steps = n * 8 // sample density for good coverage
        let half = Double(n) / 2.0
        // Parameter range: [-1.5, 1.5] gives a nice ruffled shape without too much self-intersection
        let range = 1.5
        for i in 0..<steps {
            for j in 0..<steps {
                let u = -range + 2.0 * range * Double(i) / Double(steps - 1)
                let v = -range + 2.0 * range * Double(j) / Double(steps - 1)
                // Enneper surface parametric equations
                let ex = u - u * u * u / 3.0 + u * v * v
                let ey = v - v * v * v / 3.0 + v * u * u
                let ez = u * u - v * v
                // Scale to fit grid: the surface spans roughly [-3, 3] in each axis
                let scale = half / 3.5
                let gx = Int((ex * scale + half).rounded())
                let gy = Int((ey * scale + half).rounded())
                let gz = Int((ez * scale + half).rounded())
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadPerlinNoise() {
        clearAll()
        let n = size
        // 3D value noise using a simple hash-based approach.
        // We evaluate noise at each voxel and threshold to create organic structures.
        // The permutation table provides pseudo-random gradients; trilinear
        // interpolation smooths between grid points for coherent noise.
        let freq: Float = 4.0  // noise frequency — controls feature size
        let threshold: Float = 0.42  // density threshold — cells alive above this

        // Simple hash-based permutation table (256 entries, wrapping)
        let perm: [Int] = {
            var p = Array(0..<256)
            // Deterministic shuffle using a simple LCG
            var seed: UInt32 = 42
            for i in stride(from: 255, through: 1, by: -1) {
                seed = seed &* 1664525 &+ 1013904223
                let j = Int(seed >> 16) % (i + 1)
                p.swapAt(i, j)
            }
            return p + p  // double for wrapping
        }()

        func fade(_ t: Float) -> Float {
            t * t * t * (t * (t * 6.0 - 15.0) + 10.0)  // Perlin's improved smoothstep
        }

        func grad(_ hash: Int, _ x: Float, _ y: Float, _ z: Float) -> Float {
            let h = hash & 15
            let u = h < 8 ? x : y
            let v = h < 4 ? y : (h == 12 || h == 14 ? x : z)
            return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v)
        }

        func noise3D(_ x: Float, _ y: Float, _ z: Float) -> Float {
            let xi = Int(floor(x)) & 255
            let yi = Int(floor(y)) & 255
            let zi = Int(floor(z)) & 255
            let xf = x - floor(x)
            let yf = y - floor(y)
            let zf = z - floor(z)
            let u = fade(xf)
            let v = fade(yf)
            let w = fade(zf)
            let a  = perm[xi] + yi
            let aa = perm[a] + zi
            let ab = perm[a + 1] + zi
            let b  = perm[xi + 1] + yi
            let ba = perm[b] + zi
            let bb = perm[b + 1] + zi
            let x1 = lerp(grad(perm[aa], xf, yf, zf), grad(perm[ba], xf - 1, yf, zf), u)
            let x2 = lerp(grad(perm[ab], xf, yf - 1, zf), grad(perm[bb], xf - 1, yf - 1, zf), u)
            let y1 = lerp(x1, x2, v)
            let x3 = lerp(grad(perm[aa + 1], xf, yf, zf - 1), grad(perm[ba + 1], xf - 1, yf, zf - 1), u)
            let x4 = lerp(grad(perm[ab + 1], xf, yf - 1, zf - 1), grad(perm[bb + 1], xf - 1, yf - 1, zf - 1), u)
            let y2 = lerp(x3, x4, v)
            return (lerp(y1, y2, w) + 1.0) / 2.0  // normalize to [0, 1]
        }

        func lerp(_ a: Float, _ b: Float, _ t: Float) -> Float {
            a + t * (b - a)
        }

        for x in 0..<n {
            for y in 0..<n {
                for z in 0..<n {
                    let nx = Float(x) / Float(n) * freq
                    let ny = Float(y) / Float(n) * freq
                    let nz = Float(z) / Float(n) * freq
                    // Two octaves for more interesting structure
                    let val = noise3D(nx, ny, nz) * 0.7 + noise3D(nx * 2.0, ny * 2.0, nz * 2.0) * 0.3
                    if val > threshold {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadRomanSurface() {
        clearAll()
        let n = size
        // Steiner's Roman Surface — a self-intersecting mapping of the real
        // projective plane into 3D. The implicit equation is:
        //   x²y² + y²z² + z²x² - r²xyz = 0
        // We parametrize via spherical coordinates on S²:
        //   x = r² cos(θ)sin(θ)cos²(φ)
        //   y = r² cos(θ)sin(θ)sin²(φ)  (with sign flip for lobe orientation)
        //   z = r² cos²(θ)sin(φ)cos(φ)
        // Dense sampling over θ ∈ [0, π] and φ ∈ [0, 2π] traces all four lobes
        // plus the self-intersection lines, producing a visually distinctive
        // pinwheel-like structure. Under evolution, thin surface regions erode
        // while the dense intersection hub persists.
        let half = Float(n) / 2.0
        let scale = Float(n) * 0.38  // scale factor — keep surface within grid bounds
        let steps = n * 12  // dense sampling for continuous surface
        for i in 0..<steps {
            let theta = Float.pi * Float(i) / Float(steps - 1)
            let sinT = sin(theta)
            let cosT = cos(theta)
            for j in 0..<steps {
                let phi = 2.0 * Float.pi * Float(j) / Float(steps)
                let sinP = sin(phi)
                let cosP = cos(phi)
                // Parametric Roman surface
                let px = scale * cosT * sinT * cosP * cosP
                let py = scale * cosT * sinT * sinP * sinP
                let pz = scale * cosT * cosT * sinP * cosP
                let gx = Int((px + half).rounded())
                let gy = Int((py + half).rounded())
                let gz = Int((pz + half).rounded())
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadSchwarzPSurface() {
        clearAll()
        let n = size
        // Schwarz P (Primitive) Surface — a triply periodic minimal surface.
        // The implicit equation is: cos(x) + cos(y) + cos(z) = 0
        // This creates a smooth, continuous surface that divides 3D space into
        // two interlocking labyrinthine channels. The surface has cubic symmetry
        // and zero mean curvature everywhere. We sample the implicit function at
        // each voxel and set cells alive where the value is near zero (within a
        // thickness threshold), producing a thin shell that traces the surface.
        // Under evolution, the thin sheet erodes from edges while the smooth
        // curvature regions with higher neighbor density persist longer.
        let half = Float(n) / 2.0
        let periods: Float = 2.0  // number of periods across the grid
        let thickness: Float = 0.35  // surface thickness threshold
        for x in 0..<n {
            for y in 0..<n {
                for z in 0..<n {
                    let fx = (Float(x) - half + 0.5) / half * Float.pi * periods
                    let fy = (Float(y) - half + 0.5) / half * Float.pi * periods
                    let fz = (Float(z) - half + 0.5) / half * Float.pi * periods
                    let value = cos(fx) + cos(fy) + cos(fz)
                    if abs(value) < thickness {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Clifford Torus — the flat torus in S³ stereographically projected to R³.
    /// The Clifford torus is the set of points (cos θ, sin θ, cos φ, sin φ)/√2
    /// in S³ ⊂ R⁴. Stereographic projection from the north pole (0,0,0,1) maps
    /// (x₁,x₂,x₃,x₄) → (x₁,x₂,x₃)/(1-x₄), producing a torus in R³ whose
    /// shape depends on the projection point. The result is a smoothly curved
    /// torus with even surface density — visually distinct from the standard
    /// parametric torus (which has uniform thickness) because the stereographic
    /// distortion creates varying curvature. Under evolution, the thin surface
    /// erodes from the outer rim first while the denser inner ring persists.
    mutating func loadCliffordTorus() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let steps = n * 12  // dense sampling for smooth surface
        let invSqrt2: Float = 1.0 / sqrt(2.0)
        let scale = Float(n) * 0.28  // keep torus within grid bounds
        for i in 0..<steps {
            let theta = 2.0 * Float.pi * Float(i) / Float(steps)
            let cosTheta = cos(theta)
            let sinTheta = sin(theta)
            for j in 0..<steps {
                let phi = 2.0 * Float.pi * Float(j) / Float(steps)
                let cosPhi = cos(phi)
                let sinPhi = sin(phi)
                // Point on Clifford torus in S³
                let x1 = cosTheta * invSqrt2
                let x2 = sinTheta * invSqrt2
                let x3 = cosPhi * invSqrt2
                let x4 = sinPhi * invSqrt2
                // Stereographic projection from (0,0,0,1)
                let denom = 1.0 - x4
                if abs(denom) < 0.01 { continue }  // skip near-pole singularity
                let px = scale * x1 / denom
                let py = scale * x2 / denom
                let pz = scale * x3 / denom
                let gx = Int((px + half).rounded())
                let gy = Int((py + half).rounded())
                let gz = Int((pz + half).rounded())
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadBoysSurface() {
        clearAll()
        let n = size
        // Boy's Surface — an immersion of the real projective plane into R³
        // without singular points (unlike the Roman Surface which has pinch points).
        // Discovered by Werner Boy in 1901 as a counterexample to Hilbert's conjecture.
        // The parametric form uses Bryant-Kusner coordinates:
        //   x = (√2 cos²v cos(2u) + cos(u) sin(2v)) / D
        //   y = (√2 cos²v sin(2u) - sin(u) sin(2v)) / D
        //   z = (3 cos²v) / D
        // where D = 2 - √2 sin(3u) sin(2v)
        // This produces a smooth, three-lobed surface with elegant three-fold
        // symmetry. Under evolution, the thin lobes erode from their edges
        // while the dense triple junction at the center persists longer.
        let half = Float(n) / 2.0
        let scale = half * 0.7
        let uSteps = n * 8
        let vSteps = n * 4
        for ui in 0..<uSteps {
            let u = Float(ui) / Float(uSteps) * Float.pi
            for vi in 0..<vSteps {
                let v = Float(vi) / Float(vSteps) * Float.pi / 2.0
                let cosV = cos(v)
                let sinV = sin(v)
                let cos2V = cosV * cosV
                let sin2V = 2.0 * sinV * cosV // sin(2v)
                let cosU = cos(u)
                let sinU = sin(u)
                let cos2U = cos(2.0 * u)
                let sin2U = sin(2.0 * u)
                let sin3U = sin(3.0 * u)
                let sqrt2: Float = 1.41421356
                let denom = 2.0 - sqrt2 * sin3U * sin2V
                guard abs(denom) > 0.001 else { continue }
                let px = (sqrt2 * cos2V * cos2U + cosU * sin2V) / denom
                let py = (sqrt2 * cos2V * sin2U - sinU * sin2V) / denom
                let pz = (3.0 * cos2V) / denom
                let gx = Int((px * scale) + half)
                let gy = Int((py * scale) + half)
                let gz = Int((pz * scale * 0.5) + half)
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Dini's Surface — a twisted pseudospherical surface with constant negative
    /// Gaussian curvature. Parametrized by x = a*cos(u)*sin(v), y = a*sin(u)*sin(v),
    /// z = a*(cos(v) + log(tan(v/2))) + b*u, producing a helicoid-like spiral that
    /// twists along its axis. Under evolution, the thin twisted sheet erodes from
    /// edges while the denser spiral core persists.
    mutating func loadDiniSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let scale = Float(n) * 0.10
        let a: Float = 1.0
        let b: Float = 0.2
        let stepsU = n * 16
        let stepsV = n * 8
        for i in 0..<stepsU {
            let u = 4.0 * Float.pi * Float(i) / Float(stepsU)
            let cosU = cos(u)
            let sinU = sin(u)
            for j in 1..<stepsV {
                let v = Float.pi * 0.95 * Float(j) / Float(stepsV) + 0.05
                let sinV = sin(v)
                let cosV = cos(v)
                let tanHalfV = tan(v / 2.0)
                if tanHalfV <= 0.001 { continue }
                let logTan = log(tanHalfV)
                let px = scale * a * cosU * sinV
                let py = scale * a * sinU * sinV
                let pz = scale * (a * (cosV + logTan) + b * u)
                let gx = Int((px + half).rounded())
                let gy = Int((py + half).rounded())
                let gz = Int((pz + half).rounded())
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadVoronoiCells() {
        clearAll()
        let n = size
        // 3D Voronoi tessellation — random seed points partition space into cells.
        // Voxels near the boundary between two Voronoi cells (where the distance
        // to the nearest and second-nearest seeds are close) are set alive, creating
        // a foam-like structure of thin walls surrounding empty cavities.
        // Uses a deterministic LCG (linear congruential generator) for reproducibility.
        let seedCount = max(8, n * n / 4)  // scale seeds with grid area
        var rng: UInt64 = 42  // deterministic seed
        func nextRng() -> UInt64 {
            rng = rng &* 6364136223846793005 &+ 1442695040888963407
            return rng
        }
        // Generate seed points in [0, n) space
        var seeds = [(Float, Float, Float)]()
        seeds.reserveCapacity(seedCount)
        for _ in 0..<seedCount {
            let sx = Float(nextRng() % UInt64(n * 1000)) / 1000.0
            let sy = Float(nextRng() % UInt64(n * 1000)) / 1000.0
            let sz = Float(nextRng() % UInt64(n * 1000)) / 1000.0
            seeds.append((sx, sy, sz))
        }
        let boundaryThreshold: Float = 1.8  // distance margin for boundary detection
        for x in 0..<n {
            let fx = Float(x) + 0.5
            for y in 0..<n {
                let fy = Float(y) + 0.5
                for z in 0..<n {
                    let fz = Float(z) + 0.5
                    var d1: Float = .greatestFiniteMagnitude  // nearest distance squared
                    var d2: Float = .greatestFiniteMagnitude  // second nearest
                    for (sx, sy, sz) in seeds {
                        let dx = fx - sx
                        let dy = fy - sy
                        let dz = fz - sz
                        let distSq = dx * dx + dy * dy + dz * dz
                        if distSq < d1 {
                            d2 = d1
                            d1 = distSq
                        } else if distSq < d2 {
                            d2 = distSq
                        }
                    }
                    // Alive if near the boundary between two cells
                    if d2 - d1 < boundaryThreshold {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadSchwarzDSurface() {
        clearAll()
        let n = size
        // Schwarz D (Diamond) Surface — a triply periodic minimal surface.
        // The implicit equation is: sin(x)sin(y)sin(z) + sin(x)cos(y)cos(z)
        //   + cos(x)sin(y)cos(z) + cos(x)cos(y)sin(z) = 0
        // This creates a smooth surface with tetrahedral symmetry that divides
        // space into two congruent labyrinths. It is the dual of the Schwarz P
        // surface — where P has cubic symmetry with straight tunnels, D has
        // diamond-like channels that interweave at tetrahedral angles.
        let half = Float(n) / 2.0
        let periods: Float = 2.0
        let thickness: Float = 0.35
        for x in 0..<n {
            for y in 0..<n {
                for z in 0..<n {
                    let fx = (Float(x) - half + 0.5) / half * Float.pi * periods
                    let fy = (Float(y) - half + 0.5) / half * Float.pi * periods
                    let fz = (Float(z) - half + 0.5) / half * Float.pi * periods
                    let sx = sin(fx), sy = sin(fy), sz = sin(fz)
                    let cx = cos(fx), cy = cos(fy), cz = cos(fz)
                    let value = sx * sy * sz + sx * cy * cz + cx * sy * cz + cx * cy * sz
                    if abs(value) < thickness {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadScherkSurface() {
        clearAll()
        let n = size
        // Scherk's First Surface — a doubly periodic minimal surface discovered by
        // Heinrich Scherk in 1834. The implicit equation is:
        //   e^z * cos(y) = cos(x)  ⟺  z = ln(cos(x) / cos(y))
        // The surface extends infinitely with saddle-like sheets connected at their
        // edges, creating an alternating checkerboard of rising and falling minimal
        // surfaces. The implementation evaluates the implicit form
        //   f(x,y,z) = e^z * cos(y) - cos(x)
        // over 2 periods and marks voxels where |f| < threshold as alive, tracing
        // the thin surface. The result is an elegant lattice of saddle sheets —
        // visually distinct from the Schwarz P Surface (cubic symmetry tunnels) and
        // the Gyroid (labyrinthine channels). Under evolution, the thin saddle sheets
        // erode from their edges while the denser junction lines persist.
        let periods: Float = 2.0
        let scale = 2.0 * Float.pi * periods / Float(n)
        let threshold: Float = 0.5
        for x in 0..<n {
            let fx = (Float(x) + 0.5) * scale - Float.pi * periods
            let cosX = cos(fx)
            for y in 0..<n {
                let fy = (Float(y) + 0.5) * scale - Float.pi * periods
                let cosY = cos(fy)
                for z in 0..<n {
                    let fz = (Float(z) + 0.5) * scale - Float.pi * periods
                    let expZ = exp(fz)
                    // Implicit: e^z * cos(y) - cos(x) = 0
                    let value = expZ * cosY - cosX
                    if abs(value) < threshold {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Dupin Cyclide — a quartic algebraic surface that generalizes tori and
    /// spheres. A Dupin cyclide is the image of a torus under inversion in a sphere,
    /// producing a surface where all lines of curvature are circles. Parametrized by
    /// x = (d(c - a*cos(u)*cos(v)) + b²*cos(u)) / (a - c*cos(u)*cos(v)),
    /// y = (b*sin(u)*(a - d*cos(v))) / (a - c*cos(u)*cos(v)),
    /// z = (b*sin(v)*(c*cos(u) - d)) / (a - c*cos(u)*cos(v)),
    /// where a > b > 0, c² = a² - b², and d controls the offset. Under evolution,
    /// thin surface regions erode from edges while curved junctions persist.
    mutating func loadDupinCyclide() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let scale = Float(n) * 0.22
        // Cyclide parameters: a > b > 0, c = sqrt(a²-b²), d < c for ring cyclide
        let a: Float = 2.0
        let b: Float = 1.0
        let c: Float = sqrt(a * a - b * b) // √3
        let d: Float = 0.8 // offset — d < c ensures no singularity
        let stepsU = n * 12
        let stepsV = n * 12
        for i in 0..<stepsU {
            let u = 2.0 * Float.pi * Float(i) / Float(stepsU)
            let cosU = cos(u)
            let sinU = sin(u)
            for j in 0..<stepsV {
                let v = 2.0 * Float.pi * Float(j) / Float(stepsV)
                let cosV = cos(v)
                let sinV = sin(v)
                let denom = a - c * cosU * cosV
                if abs(denom) < 0.001 { continue }
                let px = (d * (c - a * cosU * cosV) + b * b * cosU) / denom
                let py = (b * sinU * (a - d * cosV)) / denom
                let pz = (b * sinV * (c * cosU - d)) / denom
                let gx = Int((px * scale / a + half).rounded())
                let gy = Int((py * scale / a + half).rounded())
                let gz = Int((pz * scale / a + half).rounded())
                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                    setCell(x: gx, y: gy, z: gz, alive: true)
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadMonkeySaddle() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let scale: Float = 2.0 / half
        let zScale = half / 8.0
        let thickness: Float = 0.8
        for gx in 0..<n {
            for gy in 0..<n {
                let x = (Float(gx) - half + 0.5) * scale
                let y = (Float(gy) - half + 0.5) * scale
                let zSurface = (x * x * x - 3.0 * x * y * y) * zScale + half
                for gz in 0..<n {
                    let zGrid = Float(gz)
                    if abs(zGrid - zSurface) < thickness {
                        setCell(x: gx, y: gy, z: gz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadHelicoid() {
        clearAll()
        let n = size
        // The Helicoid — a ruled minimal surface swept by a line rotating at
        // constant rate as it translates along an axis. Parametrically:
        //   x = u * cos(v), y = u * sin(v), z = c * v
        // where u is the distance from the axis and v is the rotation angle.
        // Unlike the Helix pattern (a pair of thin spiraling curves), the
        // Helicoid is a continuous ruled surface — every point on it lies on a
        // straight line (the ruling) perpendicular to the central axis.
        let half = Float(n) / 2.0
        let twists: Float = 2.0
        let thickness: Float = 0.6
        let steps = n * 12
        let rulingSteps = n * 4
        let maxU = half * 0.85
        for vi in 0..<steps {
            let v = Float(vi) / Float(steps) * twists * 2.0 * Float.pi
            let cosV = cos(v)
            let sinV = sin(v)
            let z = half + (v / (twists * 2.0 * Float.pi) - 0.5) * Float(n - 1)
            for ui in 0..<rulingSteps {
                let u = (Float(ui) / Float(rulingSteps - 1) - 0.5) * 2.0 * maxU
                let px = half + u * cosV
                let py = half + u * sinV
                let ix = Int(px)
                let iy = Int(py)
                let iz = Int(z)
                if ix >= 0 && ix < n && iy >= 0 && iy < n && iz >= 0 && iz < n {
                    setCell(x: ix, y: iy, z: iz, alive: true)
                    let t = Int(thickness)
                    for dx in -t...t {
                        for dy in -t...t {
                            let nx = ix + dx
                            let ny = iy + dy
                            if nx >= 0 && nx < n && ny >= 0 && ny < n {
                                let dist = sqrt(Float(dx * dx + dy * dy))
                                if dist <= thickness {
                                    setCell(x: nx, y: ny, z: iz, alive: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadSteinmetzSolid() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let r = half * 0.75  // radius — 75% of half-grid for good fill
        let rSq = r * r
        for x in 0..<n {
            let fx = Float(x) - half + 0.5
            for y in 0..<n {
                let fy = Float(y) - half + 0.5
                for z in 0..<n {
                    let fz = Float(z) - half + 0.5
                    // Intersection of three cylinders along x, y, z axes
                    let cyl1 = fx * fx + fy * fy  // cylinder along z-axis
                    let cyl2 = fx * fx + fz * fz  // cylinder along y-axis
                    let cyl3 = fy * fy + fz * fz  // cylinder along x-axis
                    if cyl1 <= rSq && cyl2 <= rSq && cyl3 <= rSq {
                        setCell(x: x, y: y, z: z, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadCrossCap() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Cross-Cap: an immersion of the real projective plane in 3D.
        // Parametric form (u in [0, π], v in [0, 2π]):
        //   x = cos(u) * sin(2v) / 2
        //   y = sin(u) * sin(2v) / 2
        //   z = (cos²(v) - cos²(u) * sin²(v)) / 2
        let uSteps = n * 8
        let vSteps = n * 8
        let scale = half * 0.8
        let thickness: Float = 0.6
        for ui in 0..<uSteps {
            let u = Float(ui) / Float(uSteps) * Float.pi
            let cosU = cos(u)
            let sinU = sin(u)
            let cos2U = cosU * cosU
            for vi in 0..<vSteps {
                let v = Float(vi) / Float(vSteps) * 2.0 * Float.pi
                let sin2V = sin(2.0 * v)
                let cosV = cos(v)
                let sinV = sin(v)
                let px = cosU * sin2V / 2.0
                let py = sinU * sin2V / 2.0
                let pz = (cosV * cosV - cos2U * sinV * sinV) / 2.0
                let ix = Int(half + px * scale)
                let iy = Int(half + py * scale)
                let iz = Int(half + pz * scale)
                let t = Int(thickness)
                for dx in -t...t {
                    for dy in -t...t {
                        for dz in -t...t {
                            let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                            if dist <= thickness {
                                let nx = ix + dx
                                let ny = iy + dy
                                let nz = iz + dz
                                if nx >= 0 && nx < n && ny >= 0 && ny < n && nz >= 0 && nz < n {
                                    setCell(x: nx, y: ny, z: nz, alive: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadCostaSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let scale: Float = 3.0 / half
        let thickness: Float = 0.7
        for gx in 0..<n {
            let x = (Float(gx) - half + 0.5) * scale
            for gy in 0..<n {
                let y = (Float(gy) - half + 0.5) * scale
                let rSq = x * x + y * y
                let r = sqrt(rSq)
                for gz in 0..<n {
                    let z = (Float(gz) - half + 0.5) * scale
                    let catenoidR = cosh(z)
                    let distCatenoid = abs(r - catenoidR)
                    let distPlane = abs(z)
                    let planeRadius: Float = 2.5
                    let inPlane = distPlane < thickness * 0.6 && r < planeRadius
                    let inCatenoid = distCatenoid < thickness && r > 0.3
                    if inCatenoid || inPlane {
                        setCell(x: gx, y: gy, z: gz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadBreatherSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let b: Float = 0.4
        let b2 = b * b
        let w = sqrt(1.0 - b2)
        let uSteps = n * 6
        let vSteps = n * 6
        let uRange: Float = 14.0
        let vRange: Float = Float.pi * 2.0
        var minX: Float = .greatestFiniteMagnitude, maxX: Float = -.greatestFiniteMagnitude
        var minY: Float = .greatestFiniteMagnitude, maxY: Float = -.greatestFiniteMagnitude
        var minZ: Float = .greatestFiniteMagnitude, maxZ: Float = -.greatestFiniteMagnitude
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(uSteps * vSteps)
        for ui in 0..<uSteps {
            let u = -uRange / 2.0 + Float(ui) / Float(uSteps) * uRange
            let cbu = cosh(b * u)
            let sbu = sinh(b * u)
            for vi in 0..<vSteps {
                let v = -vRange / 2.0 + Float(vi) / Float(vSteps) * vRange
                let wv = w * v
                let denom = b * ((1.0 - b2) * cbu) * ((1.0 - b2) * cbu) + b2 * sin(wv) * sin(wv)
                guard denom > 1e-6 else { continue }
                let px = -u + (2.0 * (1.0 - b2) * cbu * sbu) / denom
                let py = (2.0 * w * cbu * (-w * cos(v) * cos(wv) - sin(v) * sin(wv))) / denom
                let pz = (2.0 * w * cbu * (-w * sin(v) * cos(wv) + cos(v) * sin(wv))) / denom
                points.append((px, py, pz))
                minX = min(minX, px); maxX = max(maxX, px)
                minY = min(minY, py); maxY = max(maxY, py)
                minZ = min(minZ, pz); maxZ = max(maxZ, pz)
            }
        }
        let rangeX = maxX - minX
        let rangeY = maxY - minY
        let rangeZ = maxZ - minZ
        let maxRange = max(rangeX, max(rangeY, rangeZ))
        guard maxRange > 1e-6 else { return }
        let scale = Float(n - 2) / maxRange
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let thickness: Float = 0.6
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            let t = Int(thickness)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let nx = ix + dx
                            let ny = iy + dy
                            let nz = iz + dz
                            if nx >= 0 && nx < n && ny >= 0 && ny < n && nz >= 0 && nz < n {
                                setCell(x: nx, y: ny, z: nz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadSeashell() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let uSteps = n * 8
        let vSteps = n * 8
        let scale = half * 0.75
        let thickness: Float = 0.6
        let a: Float = 0.2
        let b: Float = 0.1
        let c: Float = 0.1
        let nTurns: Float = 3.0
        for ui in 0..<uSteps {
            let u = Float(ui) / Float(uSteps) * 2.0 * Float.pi
            let cosU = cos(u)
            let sinU = sin(u)
            for vi in 0..<vSteps {
                let v = Float(vi) / Float(vSteps) * nTurns * 2.0 * Float.pi
                let ev = exp(b * v)
                let r = a * ev
                let R = ev
                let px = (R + r * cosU) * cos(v)
                let py = (R + r * cosU) * sin(v)
                let pz = -c * v + r * sinU
                let maxExtent = exp(b * nTurns * 2.0 * Float.pi) * (1.0 + a)
                let norm = 1.0 / maxExtent
                let nx = px * norm
                let ny = py * norm
                let nz = pz * norm + 0.3
                let ix = Int(half + nx * scale)
                let iy = Int(half + ny * scale)
                let iz = Int(half + nz * scale)
                let t = Int(thickness)
                for dx in -t...t {
                    for dy in -t...t {
                        for dz in -t...t {
                            let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                            if dist <= thickness {
                                let gx = ix + dx
                                let gy = iy + dy
                                let gz = iz + dz
                                if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                    setCell(x: gx, y: gy, z: gz, alive: true)
                                }
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Catalan Surface — a ruled surface generated by the parametric equations:
    /// x = u - tanh(u), y = sech(u)·cos(v), z = sech(u)·sin(v)
    /// A surface of revolution whose profile is a tractrix. Has two cusps along
    /// the x-axis where the profile pinches, creating a barrel-like envelope.
    mutating func loadCatalanSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let uSteps = n * 8
        let vSteps = n * 8
        let thickness: Float = 0.6
        // Collect points for normalization
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(uSteps * vSteps)
        for ui in 0..<uSteps {
            let u = -2.0 + 4.0 * Float(ui) / Float(uSteps - 1)
            let sechU = 1.0 / cosh(u)
            let px = u - tanh(u)
            for vi in 0..<vSteps {
                let v = Float(vi) / Float(vSteps) * 2.0 * Float.pi
                let py = sechU * cos(v)
                let pz = sechU * sin(v)
                points.append((px, py, pz))
            }
        }
        // Find bounding box for normalization
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Henneberg Surface — a minimal surface with branch points.
    /// Parametrized by x = 2sinh(u)cos(v) - (2/3)sinh(3u)cos(3v),
    /// y = 2sinh(u)sin(v) + (2/3)sinh(3u)sin(3v), z = 2cosh(2u)cos(2v).
    mutating func loadHennebergSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let uSteps = n * 8
        let vSteps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(uSteps * vSteps)
        for ui in 0..<uSteps {
            let u = -1.5 + 3.0 * Float(ui) / Float(uSteps - 1)
            for vi in 0..<vSteps {
                let v = Float(vi) / Float(vSteps) * 2.0 * Float.pi
                let px = 2.0 * sinh(u) * cos(v) - (2.0 / 3.0) * sinh(3.0 * u) * cos(3.0 * v)
                let py = 2.0 * sinh(u) * sin(v) + (2.0 / 3.0) * sinh(3.0 * u) * sin(3.0 * v)
                let pz = 2.0 * cosh(2.0 * u) * cos(2.0 * v)
                points.append((px, py, pz))
            }
        }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Kuen Surface — a pseudospherical surface of constant negative Gaussian curvature.
    /// Parametrized by x = 2(cos(v) + v·sin(v))·sin(u) / (1 + v²·sin²(u)),
    /// y = 2(cos(v) + v·sin(v))·cos(u) / (1 + v²·sin²(u)),
    /// z = log(tan(v/2)) + 2·cos(v)/(1 + v²·sin²(u)).
    /// Related to the Breather Surface but with a trumpet-bell flare.
    mutating func loadKuenSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let uSteps = n * 8
        let vSteps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(uSteps * vSteps)
        for ui in 0..<uSteps {
            let u = -Float.pi + 2.0 * Float.pi * Float(ui) / Float(uSteps - 1)
            for vi in 0..<vSteps {
                // v avoids 0 and pi where tan(v/2) diverges
                let v = 0.05 + (Float.pi - 0.1) * Float(vi) / Float(vSteps - 1)
                let sinU = sin(u)
                let sinV = sin(v)
                let cosV = cos(v)
                let denom = 1.0 + v * v * sinU * sinU
                let r = 2.0 * (cosV + v * sinV)
                let px = r * sin(u) / denom
                let py = r * cos(u) / denom
                let pz = log(tan(v / 2.0)) + 2.0 * cosV / denom
                if pz.isFinite && px.isFinite && py.isFinite {
                    points.append((px, py, pz))
                }
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Richmond Surface — a minimal surface with a flat point at the origin.
    /// Uses the Weierstrass-Enneper parametrization with f(z) = z^(-2), g(z) = z^2.
    /// Parametric form: x = -Re(1/(3z^3) + 1/z), y = Re(i/(3z^3) - i/z), z_coord = Re(1/z^2).
    mutating func loadRichmondSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let rSteps = n * 6
        let tSteps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(rSteps * tSteps)
        for ri in 1...rSteps {
            let r = 0.3 + 1.7 * Float(ri) / Float(rSteps)
            for ti in 0..<tSteps {
                let t = Float(ti) / Float(tSteps) * 2.0 * Float.pi
                let cosT = cos(t)
                let sinT = sin(t)
                let cos2T = cos(2.0 * t)
                let cos3T = cos(3.0 * t)
                let sin3T = sin(3.0 * t)
                let r3 = r * r * r
                let invR = 1.0 / r
                let invR2 = invR * invR
                let invR3 = 1.0 / r3
                let px = -(invR3 * cos3T / 3.0 + invR * cosT)
                let py = invR3 * sin3T / 3.0 - invR * sinT
                let pz = invR2 * cos2T
                points.append((px, py, pz))
            }
        }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadBohemianDome() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let uSteps = n * 8
        let vSteps = n * 8
        let thickness: Float = 0.6
        let a: Float = 1.0
        let b: Float = 1.0
        let c: Float = 1.0
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(uSteps * vSteps)
        for ui in 0..<uSteps {
            let u = 2.0 * Float.pi * Float(ui) / Float(uSteps - 1)
            for vi in 0..<vSteps {
                let v = 2.0 * Float.pi * Float(vi) / Float(vSteps - 1)
                let px = a * cos(u)
                let py = b * cos(v) + a * sin(u)
                let pz = c * sin(v)
                points.append((px, py, pz))
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Astroidal Ellipsoid: x = cos³(u)cos³(v), y = sin³(u)cos³(v), z = sin³(v)
    /// A pinched, star-shaped quartic surface — visually distinct from smooth
    /// surfaces (Sphere, Catenoid) due to its cusps along all three axes.
    mutating func loadAstroidalEllipsoid() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let steps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(steps * steps)
        for ui in 0..<steps {
            let u = -Float.pi + 2.0 * Float.pi * Float(ui) / Float(steps - 1)
            let cosU = cos(u)
            let sinU = sin(u)
            for vi in 0..<steps {
                let v = -Float.pi / 2.0 + Float.pi * Float(vi) / Float(steps - 1)
                let cosV = cos(v)
                let sinV = sin(v)
                let cos3U = cosU * cosU * cosU
                let sin3U = sinU * sinU * sinU
                let cos3V = cosV * cosV * cosV
                let sin3V = sinV * sinV * sinV
                let px = cos3U * cos3V
                let py = sin3U * cos3V
                let pz = sin3V
                points.append((px, py, pz))
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Clebsch Diagonal Surface — a famous cubic surface defined implicitly by
    /// x³ + y³ + z³ + w³ + t³ = 0 where w = -(x+y+z+t) and t = 1. In 3D, this
    /// reduces to: x³ + y³ + z³ + (-(x+y+z+1))³ + 1 = 0. The surface is
    /// notable for containing all 27 lines of a smooth cubic surface.
    mutating func loadClebschDiagonalSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let range: Float = 2.0
        let threshold: Float = 0.15
        for xi in 0..<n {
            for yi in 0..<n {
                for zi in 0..<n {
                    let x = (Float(xi) - half) / half * range
                    let y = (Float(yi) - half) / half * range
                    let z = (Float(zi) - half) / half * range
                    let t: Float = 1.0
                    let w = -(x + y + z + t)
                    let value = x * x * x + y * y * y + z * z * z + w * w * w + t * t * t
                    if abs(value) < threshold * range {
                        setCell(x: xi, y: yi, z: zi, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Whitney Umbrella: x² = y²·z — a ruled algebraic surface with a
    /// singularity at the origin where the surface self-intersects along the
    /// negative z-axis. Parametrized as x = u·v, y = v, z = u² over
    /// u ∈ [-1.5, 1.5], v ∈ [-1.5, 1.5]. Visually distinct from Cross-Cap
    /// (closed non-orientable) and Roman Surface (symmetric self-intersection)
    /// — the Whitney Umbrella has a characteristic pinch-crease along one axis.
    mutating func loadWhitneyUmbrella() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let steps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(steps * steps)
        for ui in 0..<steps {
            let u = -1.5 + 3.0 * Float(ui) / Float(steps - 1)
            for vi in 0..<steps {
                let v = -1.5 + 3.0 * Float(vi) / Float(steps - 1)
                let px = u * v
                let py = v
                let pz = u * u
                points.append((px, py, pz))
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    /// Pseudosphere — a surface of revolution of a tractrix with constant negative
    /// Gaussian curvature (-1). Parametrized as:
    ///   x = cos(u) / cosh(v)
    ///   y = sin(u) / cosh(v)
    ///   z = v - tanh(v)
    /// where u ∈ [0, 2π) and v ∈ [-3, 3]. Produces a trumpet/horn shape that
    /// flares outward at the open end and tapers to a cusp. Distinct from Dini's
    /// Surface (helical pseudospherical) and Kuen Surface (flared with pinched edges).
    mutating func loadPseudosphere() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let steps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(steps * steps)
        for ui in 0..<steps {
            let u = 2.0 * Float.pi * Float(ui) / Float(steps - 1)
            for vi in 0..<steps {
                let v = -3.0 + 6.0 * Float(vi) / Float(steps - 1)
                let coshV = cosh(v)
                guard coshV > 0.001 else { continue }
                let px = cos(u) / coshV
                let py = sin(u) / coshV
                let pz = v - tanh(v)
                points.append((px, py, pz))
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadHyperboloid() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let steps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(steps * steps)
        // One-sheeted hyperboloid: x² + y² - z² = 1
        // Parametric: x = cosh(v)cos(u), y = cosh(v)sin(u), z = sinh(v)
        for ui in 0..<steps {
            let u = 2.0 * Float.pi * Float(ui) / Float(steps - 1)
            for vi in 0..<steps {
                let v = -1.5 + 3.0 * Float(vi) / Float(steps - 1)
                let coshV = cosh(v)
                let sinhV = sinh(v)
                let px = coshV * cos(u)
                let py = coshV * sin(u)
                let pz = sinhV
                points.append((px, py, pz))
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadBourMinimalSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        let steps = n * 8
        let thickness: Float = 0.6
        var points: [(Float, Float, Float)] = []
        points.reserveCapacity(steps * steps)
        // Bour's minimal surface with n=3
        // x(r,θ) = r cos(θ) - r^n/(2n) cos(nθ)
        // y(r,θ) = -r sin(θ) - r^n/(2n) sin(nθ)
        // z(r,θ) = 2 r^(n/2) / n cos(nθ/2)
        let order: Float = 3.0
        for ri in 0..<steps {
            let r = 0.1 + 1.9 * Float(ri) / Float(steps - 1)
            for ti in 0..<steps {
                let theta = 2.0 * Float.pi * Float(ti) / Float(steps - 1)
                let rn = pow(r, order)
                let rHalf = pow(r, order / 2.0)
                let px = r * cos(theta) - rn / (2.0 * order) * cos(order * theta)
                let py = -r * sin(theta) - rn / (2.0 * order) * sin(order * theta)
                let pz = 2.0 * rHalf / order * cos(order * theta / 2.0)
                points.append((px, py, pz))
            }
        }
        guard !points.isEmpty else { return }
        var minX = Float.greatestFiniteMagnitude, maxX = -Float.greatestFiniteMagnitude
        var minY = Float.greatestFiniteMagnitude, maxY = -Float.greatestFiniteMagnitude
        var minZ = Float.greatestFiniteMagnitude, maxZ = -Float.greatestFiniteMagnitude
        for (px, py, pz) in points {
            minX = min(minX, px); maxX = max(maxX, px)
            minY = min(minY, py); maxY = max(maxY, py)
            minZ = min(minZ, pz); maxZ = max(maxZ, pz)
        }
        let extX = maxX - minX
        let extY = maxY - minY
        let extZ = maxZ - minZ
        let maxExt = max(extX, max(extY, extZ))
        guard maxExt > 0 else { return }
        let scale = half * 1.5 / maxExt
        let cx = (minX + maxX) / 2.0
        let cy = (minY + maxY) / 2.0
        let cz = (minZ + maxZ) / 2.0
        let t = Int(thickness)
        for (px, py, pz) in points {
            let ix = Int(half + (px - cx) * scale)
            let iy = Int(half + (py - cy) * scale)
            let iz = Int(half + (pz - cz) * scale)
            for dx in -t...t {
                for dy in -t...t {
                    for dz in -t...t {
                        let dist = sqrt(Float(dx * dx + dy * dy + dz * dz))
                        if dist <= thickness {
                            let gx = ix + dx
                            let gy = iy + dy
                            let gz = iz + dz
                            if gx >= 0 && gx < n && gy >= 0 && gy < n && gz >= 0 && gz < n {
                                setCell(x: gx, y: gy, z: gz, alive: true)
                            }
                        }
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadBarthSextic() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Golden ratio
        let phi: Float = (1.0 + sqrt(5.0)) / 2.0
        let phi2 = phi * phi
        // Barth sextic: 4(φ²x² - y²)(φ²y² - z²)(φ²z² - x²) - (1+2φ)(x²+y²+z²-1)² = 0
        // Iterate grid, evaluate implicit equation, activate cells near zero
        let threshold: Float = 0.15
        let scale: Float = 1.3 / half
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    let x2 = x * x, y2 = y * y, z2 = z * z
                    let r2 = x2 + y2 + z2
                    if r2 > 1.5 { continue }
                    let term1 = 4.0 * (phi2 * x2 - y2) * (phi2 * y2 - z2) * (phi2 * z2 - x2)
                    let term2 = (1.0 + 2.0 * phi) * (r2 - 1.0) * (r2 - 1.0)
                    let value = term1 - term2
                    if abs(value) < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadCassiniSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Cassini surface: ((x-a)² + y² + z²)((x+a)² + y² + z²) = b⁴
        // With a=0.7, b=1.0 this produces a peanut-shaped surface
        let a: Float = 0.7
        let b4: Float = 1.0  // b⁴ = 1.0
        let threshold: Float = 0.25
        let scale: Float = 1.8 / half
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    let y2 = y * y, z2 = z * z
                    let xma = x - a, xpa = x + a
                    let d1 = xma * xma + y2 + z2
                    let d2 = xpa * xpa + y2 + z2
                    let value = d1 * d2 - b4
                    if abs(value) < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadKummerSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Kummer surface: a quartic surface with 16 ordinary double points
        // (x² + y² + z² - μ²)² - λ · p(x,y,z) = 0
        // where p = product of 4 planes through vertices of a tetrahedron
        // Using the standard form with μ² = 3, λ chosen for distinct nodes
        let mu2: Float = 3.0
        let lambda: Float = 3.0 * (3.0 - 1.0) / (3.0 - (3.0 - 1.0)) // = 3
        let sqrt3: Float = sqrt(3.0)
        let threshold: Float = 0.4
        let scale: Float = 2.0 / half
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    let x2 = x * x, y2 = y * y, z2 = z * z
                    let r2 = x2 + y2 + z2
                    if r2 > 4.0 { continue }
                    // (x² + y² + z² - μ²)²
                    let term1 = (r2 - mu2) * (r2 - mu2)
                    // Tetrahedral product: (x+y+z-1)(x-y-z-1)(-x+y-z-1)(-x-y+z-1)
                    let p1 = (x + y + z) / sqrt3 - 1.0
                    let p2 = (x - y - z) / sqrt3 - 1.0
                    let p3 = (-x + y - z) / sqrt3 - 1.0
                    let p4 = (-x - y + z) / sqrt3 - 1.0
                    let tetra = p1 * p2 * p3 * p4
                    let value = term1 - lambda * tetra
                    if abs(value) < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadCayleyCubic() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Cayley nodal cubic: a cubic surface with 4 ordinary double points
        // (the maximum for a cubic surface), discovered by Arthur Cayley.
        // Equation: xy + xz + yz + xyz = 0
        // The surface has tetrahedral symmetry and passes through the origin.
        let threshold: Float = 0.15
        let scale: Float = 3.0 / half
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    let r2 = x * x + y * y + z * z
                    if r2 > 9.0 { continue }
                    let value = x * y + x * z + y * z + x * y * z
                    if abs(value) < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadTogliattiSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Togliatti surface: a quintic surface with 31 ordinary double points
        // (the maximum for a degree-5 surface). Discovered by Eugenio Togliatti (1940).
        // Equation: 64(x₀ - w)(x₀⁴ - 4x₀³w - 10x₀²x₁² - 4x₀²w² + 16x₀w³
        //   - 20x₀x₁²w + 5x₁⁴ + 16w⁴ - 20x₁²w²) - 5√5(2x₀ - w)(4(x₁² + x₂²) - (1+3√5)w²)² = 0
        // Simplified in affine coords (w=1) and homogeneous form.
        // We use the Barth-style parameterization in Cartesian coordinates.
        let phi: Float = (1.0 + sqrt(5.0)) / 2.0 // golden ratio
        let threshold: Float = 0.3
        let scale: Float = 2.5 / half
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    let x2 = x * x, y2 = y * y, z2 = z * z
                    let r2 = x2 + y2 + z2
                    if r2 > 6.0 { continue }
                    // Togliatti quintic: using the icosahedral-invariant form
                    // F = x⁵ + y⁵ + z⁵ + w⁵ - (x² + y² + z² + w²)(x³ + y³ + z³ + w³)/2
                    // where w² = 1 - x² - y² - z² (projection from S³)
                    // Simplified affine form with w = 1:
                    let x3 = x * x2, y3 = y * y2, z3 = z * z2
                    let x5 = x3 * x2, y5 = y3 * y2, z5 = z3 * z2
                    let sum5 = x5 + y5 + z5 + 1.0
                    let sum2 = x2 + y2 + z2 + 1.0
                    let sum3 = x3 + y3 + z3 + 1.0
                    let value = sum5 - phi * sum2 * sum3 / 2.0
                    if abs(value) < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadFermatSurface() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Fermat quartic surface: x⁴ + y⁴ + z⁴ = 1
        // A smooth quartic surface with octahedral symmetry, studied by Pierre de Fermat.
        // Every cross-section is a superellipse (squircle). The surface is convex and
        // resembles a rounded cube — smoother than a cube but sharper than a sphere.
        let scale: Float = 1.5 / half
        let threshold: Float = 0.15
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    let x2 = x * x, y2 = y * y, z2 = z * z
                    let value = x2 * x2 + y2 * y2 + z2 * z2
                    // Activate cells near the surface |F - 1| < threshold
                    if abs(value - 1.0) < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
                }
            }
        }
        rebuildAliveCellIndices()
    }

    mutating func loadOloid() {
        clearAll()
        let n = size
        let half = Float(n) / 2.0
        // Oloid: the convex hull of two unit circles in perpendicular planes,
        // each passing through the center of the other. One circle lies in the
        // XY-plane centered at (0, -0.5, 0), the other in the YZ-plane centered
        // at (0, 0.5, 0). The resulting surface is a smooth, pillow-like convex
        // shape that can roll on its entire surface area.
        let scale: Float = 2.2 / half
        let r: Float = 1.0 // circle radius
        let d: Float = 0.5 // half-distance between circle centers
        let threshold: Float = 0.08
        // Sample points on both circles and build the convex hull implicitly
        // by checking distance to the closest point on each circle.
        let circleSteps = 64
        // Pre-compute circle sample points
        var circle1: [(Float, Float, Float)] = []
        var circle2: [(Float, Float, Float)] = []
        for i in 0..<circleSteps {
            let t = Float(i) / Float(circleSteps) * 2.0 * .pi
            let ct = cos(t), st = sin(t)
            // Circle 1: in XY-plane, centered at (0, -d, 0)
            circle1.append((r * ct, -d + r * st, 0))
            // Circle 2: in YZ-plane, centered at (0, d, 0)
            circle2.append((0, d + r * ct, r * st))
        }
        for ix in 0..<n {
            for iy in 0..<n {
                for iz in 0..<n {
                    let x = (Float(ix) - half + 0.5) * scale
                    let y = (Float(iy) - half + 0.5) * scale
                    let z = (Float(iz) - half + 0.5) * scale
                    // Find minimum distance to either circle
                    var minDist: Float = .greatestFiniteMagnitude
                    for (cx, cy, cz) in circle1 {
                        let dx = x - cx, dy = y - cy, dz = z - cz
                        let dist = (dx*dx + dy*dy + dz*dz).squareRoot()
                        if dist < minDist { minDist = dist }
                    }
                    for (cx, cy, cz) in circle2 {
                        let dx = x - cx, dy = y - cy, dz = z - cz
                        let dist = (dx*dx + dy*dy + dz*dz).squareRoot()
                        if dist < minDist { minDist = dist }
                    }
                    // Activate cells near the surface of the convex hull
                    if minDist < threshold {
                        setCell(x: ix, y: iy, z: iz, alive: true)
                    }
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
