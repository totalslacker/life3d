import Foundation

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
        cells[idx] = alive ? 1 : 0
        if alive && !wasAlive {
            aliveCount += 1
            aliveIndexMap[idx] = aliveCellIndices.count
            aliveCellIndices.append(idx)
        } else if !alive && wasAlive {
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
        // Zero the next buffer using bulk memset — faster than per-element loop for 32K+ ints
        nextCells.withUnsafeMutableBufferPointer { buf in
            buf.update(repeating: 0)
        }
        // Reuse pre-allocated born/dying/alive buffers — removeAll(keepingCapacity:) avoids heap allocation
        dyingCells.removeAll(keepingCapacity: true)
        bornCells.removeAll(keepingCapacity: true)
        aliveCellIndices.removeAll(keepingCapacity: true)
        // Reset reverse mapping (rebuilt as we populate aliveCellIndices below)
        for i in 0..<cellCount { aliveIndexMap[i] = -1 }

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
        for i in 0..<cellCount {
            aliveIndexMap[i] = -1
        }
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
    /// Every other cell in each axis is alive, creating a checkerboard in 3D.
    /// The structure is highly symmetric with each alive cell having exactly 0 Moore neighbors
    /// that are also alive (at spacing 2), so evolution under standard rules causes immediate
    /// mass birth in the interstitial gaps, producing a dramatic first-generation explosion.
    mutating func loadLattice() {
        clearAll()
        let margin = max(1, size / 6)  // inset from edges for visual centering
        for x in stride(from: margin, to: size - margin, by: 2) {
            for y in stride(from: margin, to: size - margin, by: 2) {
                for z in stride(from: margin, to: size - margin, by: 2) {
                    setCell(x: x, y: y, z: z, alive: true)
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
        for i in 0..<cellCount { aliveIndexMap[i] = -1 }
        aliveCount = 0
    }
}
