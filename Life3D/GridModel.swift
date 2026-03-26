import Foundation

struct GridModel: Sendable {
    let size: Int
    /// Cell age: 0 = dead, 1+ = alive (value is age in generations)
    private(set) var cells: [Int]
    /// Cells that died in the most recent generation (positions stored for fade-out rendering)
    private(set) var dyingCells: [Int] = []
    /// Cells born in the most recent generation (for particle effects)
    private(set) var bornCells: [Int] = []

    /// Rule configuration: born when neighbor count is in birthCounts, survives when in survivalCounts
    var birthCounts: Set<Int>
    var survivalCounts: Set<Int>

    var cellCount: Int { size * size * size }

    init(size: Int, birthCounts: Set<Int> = [5, 6, 7], survivalCounts: Set<Int> = [5, 6, 7, 8]) {
        self.size = size
        self.cells = [Int](repeating: 0, count: size * size * size)
        self.birthCounts = birthCounts
        self.survivalCounts = survivalCounts
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
        cells[index(x: x, y: y, z: z)] = alive ? 1 : 0
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
        let offsets = Self.neighborOffsets(size: size)
        var next = [Int](repeating: 0, count: cellCount)
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
                        if survivalCounts.contains(neighbors) {
                            next[idx] = cells[idx] + 1
                        } else {
                            next[idx] = 0
                            dying.append(idx)
                        }
                    } else {
                        if birthCounts.contains(neighbors) {
                            next[idx] = 1
                            born.append(idx)
                        }
                    }
                }
            }
        }
        cells = next
        dyingCells = dying
        bornCells = born
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

    /// Returns positions of cells born this generation (for particle effects).
    func bornCellPositions(cellSize: Float, cellSpacing: Float) -> [SIMD3<Float>] {
        bornCells.map { idx in
            let x = idx / (size * size)
            let y = (idx / size) % size
            let z = idx % size
            return cellPosition(x: x, y: y, z: z, cellSize: cellSize, cellSpacing: cellSpacing)
        }
    }

    var aliveCount: Int {
        cells.filter { $0 > 0 }.count
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

    mutating func clearAll() {
        cells = [Int](repeating: 0, count: cellCount)
        dyingCells = []
        bornCells = []
    }
}
