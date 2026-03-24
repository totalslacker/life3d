import Testing
@testable import Life3D

@Suite("Grid Tests")
struct GridTests {
    @Test("Grid model reports correct cell count for 16x16x16")
    func gridDimensions16() {
        let model = GridModel(size: 16)
        #expect(model.cellCount == 16 * 16 * 16)
    }

    @Test("Grid model reports correct cell count for small grid")
    func smallGridDimensions() {
        let model = GridModel(size: 4)
        #expect(model.cellCount == 4 * 4 * 4)
    }

    @Test("Cell positions are centered around origin")
    func cellPositionsCentered() {
        let model = GridModel(size: 2)
        let cellSize: Float = 0.02
        let cellSpacing: Float = 0.005

        let p0 = model.cellPosition(x: 0, y: 0, z: 0, cellSize: cellSize, cellSpacing: cellSpacing)
        let p1 = model.cellPosition(x: 1, y: 1, z: 1, cellSize: cellSize, cellSpacing: cellSpacing)

        let epsilon: Float = 0.0001
        #expect(abs(p0.x + p1.x) < epsilon)
        #expect(abs(p0.y + p1.y) < epsilon)
        #expect(abs(p0.z + p1.z) < epsilon)
    }

    @Test("Single cell grid is at origin")
    func singleCellAtOrigin() {
        let model = GridModel(size: 1)
        let pos = model.cellPosition(x: 0, y: 0, z: 0, cellSize: 0.02, cellSpacing: 0.005)
        #expect(pos.x == 0)
        #expect(pos.y == 0)
        #expect(pos.z == 0)
    }
}

@Suite("Cell State Tests")
struct CellStateTests {
    @Test("New grid has all cells dead")
    func allDead() {
        let model = GridModel(size: 4)
        #expect(model.aliveCount == 0)
    }

    @Test("Set and get cell state")
    func setGetCell() {
        var model = GridModel(size: 4)
        model.setCell(x: 1, y: 2, z: 3, alive: true)
        #expect(model.isAlive(x: 1, y: 2, z: 3))
        #expect(!model.isAlive(x: 0, y: 0, z: 0))
    }

    @Test("Out of bounds reads return false")
    func outOfBounds() {
        let model = GridModel(size: 4)
        #expect(!model.isAlive(x: -1, y: 0, z: 0))
        #expect(!model.isAlive(x: 4, y: 0, z: 0))
        #expect(!model.isAlive(x: 0, y: -1, z: 0))
    }

    @Test("Clear all resets grid")
    func clearAll() {
        var model = GridModel(size: 4)
        model.randomSeed(density: 0.5)
        #expect(model.aliveCount > 0)
        model.clearAll()
        #expect(model.aliveCount == 0)
    }
}

@Suite("Neighbor Counting Tests")
struct NeighborTests {
    @Test("Isolated cell has zero neighbors")
    func isolatedCell() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 0)
    }

    @Test("Cell with one adjacent neighbor")
    func oneNeighbor() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 1)
        #expect(model.neighborCount(x: 5, y: 4, z: 4) == 1)
    }

    @Test("Full 2x2x2 block — each cell has 7 neighbors")
    func block2x2x2() {
        var model = GridModel(size: 8)
        for dx in 3...4 {
            for dy in 3...4 {
                for dz in 3...4 {
                    model.setCell(x: dx, y: dy, z: dz, alive: true)
                }
            }
        }
        // Each cell in a 2x2x2 block has exactly 7 neighbors (all other cells in the block)
        #expect(model.neighborCount(x: 3, y: 3, z: 3) == 7)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 7)
    }

    @Test("Corner cell neighbors don't wrap")
    func cornerNoWrap() {
        var model = GridModel(size: 4)
        // Fill neighbors at origin — only 7 possible (within bounds)
        model.setCell(x: 1, y: 0, z: 0, alive: true)
        model.setCell(x: 0, y: 1, z: 0, alive: true)
        model.setCell(x: 0, y: 0, z: 1, alive: true)
        model.setCell(x: 1, y: 1, z: 0, alive: true)
        model.setCell(x: 1, y: 0, z: 1, alive: true)
        model.setCell(x: 0, y: 1, z: 1, alive: true)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        #expect(model.neighborCount(x: 0, y: 0, z: 0) == 7)
    }
}

@Suite("Rule Application Tests")
struct RuleTests {
    @Test("Dead cell with 5 neighbors is born (5766 rule)")
    func birthRule() {
        var model = GridModel(size: 8)
        // Place 5 neighbors around (4,4,4) — the cell itself is dead
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 5)
        #expect(!model.isAlive(x: 4, y: 4, z: 4))

        model.advanceGeneration()
        #expect(model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("Live cell with 6 neighbors survives (5766 rule)")
    func survivalRule6() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)
        model.setCell(x: 4, y: 4, z: 5, alive: true)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 6)

        model.advanceGeneration()
        #expect(model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("Live cell with 7 neighbors survives (5766 rule)")
    func survivalRule7() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)
        model.setCell(x: 4, y: 4, z: 5, alive: true)
        model.setCell(x: 3, y: 3, z: 4, alive: true)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 7)

        model.advanceGeneration()
        #expect(model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("Live cell with <6 neighbors dies")
    func deathUnderpopulation() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        model.setCell(x: 3, y: 4, z: 4, alive: true) // 1 neighbor
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 1)

        model.advanceGeneration()
        #expect(!model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("2x2x2 block is stable under 5766 rules")
    func blockStability() {
        var model = GridModel(size: 8)
        for dx in 3...4 {
            for dy in 3...4 {
                for dz in 3...4 {
                    model.setCell(x: dx, y: dy, z: dz, alive: true)
                }
            }
        }
        let before = model.aliveCount
        model.advanceGeneration()
        // All cells have 7 neighbors (survive), no dead cell has exactly 5 alive neighbors
        #expect(model.aliveCount == before)
        // Verify the same cells are still alive
        for dx in 3...4 {
            for dy in 3...4 {
                for dz in 3...4 {
                    #expect(model.isAlive(x: dx, y: dy, z: dz))
                }
            }
        }
    }

    @Test("Dead cell with 4 neighbors is NOT born")
    func noBirthWith4() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 4)

        model.advanceGeneration()
        #expect(!model.isAlive(x: 4, y: 4, z: 4))
    }
}

@Suite("Cell Age Tests")
struct CellAgeTests {
    @Test("New cell starts at age 1")
    func newCellAge() {
        var model = GridModel(size: 4)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        #expect(model.cellAge(x: 1, y: 1, z: 1) == 1)
    }

    @Test("Dead cell has age 0")
    func deadCellAge() {
        let model = GridModel(size: 4)
        #expect(model.cellAge(x: 0, y: 0, z: 0) == 0)
    }

    @Test("Surviving cell increments age each generation")
    func ageIncrements() {
        // 2x2x2 block is stable — each cell survives every generation
        var model = GridModel(size: 8)
        for dx in 3...4 {
            for dy in 3...4 {
                for dz in 3...4 {
                    model.setCell(x: dx, y: dy, z: dz, alive: true)
                }
            }
        }
        #expect(model.cellAge(x: 3, y: 3, z: 3) == 1) // Initial age

        model.advanceGeneration()
        #expect(model.cellAge(x: 3, y: 3, z: 3) == 2)

        model.advanceGeneration()
        #expect(model.cellAge(x: 3, y: 3, z: 3) == 3)
    }

    @Test("Newborn cell from birth rule has age 1")
    func birthAge() {
        var model = GridModel(size: 8)
        // Place 5 neighbors around (4,4,4) — cell is dead, will be born
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)

        model.advanceGeneration()
        #expect(model.isAlive(x: 4, y: 4, z: 4))
        #expect(model.cellAge(x: 4, y: 4, z: 4) == 1)
    }

    @Test("Dying cell resets age to 0")
    func deathResetsAge() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        // Only 1 neighbor — will die
        model.setCell(x: 3, y: 4, z: 4, alive: true)

        model.advanceGeneration()
        #expect(!model.isAlive(x: 4, y: 4, z: 4))
        #expect(model.cellAge(x: 4, y: 4, z: 4) == 0)
    }
}
