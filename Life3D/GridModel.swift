import Foundation

struct GridModel: Sendable {
    let size: Int
    /// Cell age: 0 = dead, 1+ = alive (value is age in generations)
    private(set) var cells: [Int]

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

    mutating func advanceGeneration() {
        var next = [Int](repeating: 0, count: cellCount)
        for x in 0..<size {
            for y in 0..<size {
                for z in 0..<size {
                    let neighbors = neighborCount(x: x, y: y, z: z)
                    let idx = index(x: x, y: y, z: z)
                    if cells[idx] > 0 {
                        // Surviving cell: increment age
                        next[idx] = survivalCounts.contains(neighbors) ? cells[idx] + 1 : 0
                    } else {
                        // Dead cell: born with age 1
                        next[idx] = birthCounts.contains(neighbors) ? 1 : 0
                    }
                }
            }
        }
        cells = next
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
    }
}
