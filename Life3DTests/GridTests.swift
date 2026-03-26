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

    @Test("Dying cells tracked after generation advance")
    func dyingCellsTracked() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        // Only 1 neighbor — both will die
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        #expect(model.dyingCells.isEmpty)

        model.advanceGeneration()
        #expect(model.dyingCells.count == 2)
    }

    @Test("Stable block produces no dying cells")
    func stableBlockNoDying() {
        var model = GridModel(size: 8)
        for dx in 3...4 {
            for dy in 3...4 {
                for dz in 3...4 {
                    model.setCell(x: dx, y: dy, z: dz, alive: true)
                }
            }
        }
        model.advanceGeneration()
        #expect(model.dyingCells.isEmpty)
    }

    @Test("Clear all resets dying cells")
    func clearAllResetsDying() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        model.advanceGeneration()
        #expect(!model.dyingCells.isEmpty)
        model.clearAll()
        #expect(model.dyingCells.isEmpty)
    }
}

@Suite("Born Cell Tracking Tests")
struct BornCellTests {
    @Test("Born cells tracked when new cells appear")
    func bornCellsTracked() {
        var model = GridModel(size: 8)
        // Place 5 neighbors around (4,4,4) — cell will be born
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)
        #expect(model.bornCells.isEmpty)

        model.advanceGeneration()
        #expect(model.bornCells.contains(model.index(x: 4, y: 4, z: 4)))
    }

    @Test("Stable block produces no born cells")
    func stableBlockNoBorn() {
        var model = GridModel(size: 8)
        for dx in 3...4 {
            for dy in 3...4 {
                for dz in 3...4 {
                    model.setCell(x: dx, y: dy, z: dz, alive: true)
                }
            }
        }
        model.advanceGeneration()
        #expect(model.bornCells.isEmpty)
    }

    @Test("Clear all resets born cells")
    func clearAllResetsBorn() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)
        model.advanceGeneration()
        #expect(!model.bornCells.isEmpty)
        model.clearAll()
        #expect(model.bornCells.isEmpty)
    }
}

@Suite("Performance Optimization Tests")
struct PerformanceTests {
    @Test("Optimized advanceGeneration matches neighborCount for random grid")
    func optimizedMatchesOriginal() {
        // Create a random grid and verify advanceGeneration produces correct results
        // by comparing against the public neighborCount function
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)

        // Snapshot neighbor counts using the public bounds-checked method
        var expectedAlive = [Bool](repeating: false, count: model.cellCount)
        for x in 0..<8 {
            for y in 0..<8 {
                for z in 0..<8 {
                    let neighbors = model.neighborCount(x: x, y: y, z: z)
                    let isAlive = model.isAlive(x: x, y: y, z: z)
                    if isAlive {
                        expectedAlive[model.index(x: x, y: y, z: z)] = model.survivalCounts.contains(neighbors)
                    } else {
                        expectedAlive[model.index(x: x, y: y, z: z)] = model.birthCounts.contains(neighbors)
                    }
                }
            }
        }

        // Run the optimized advanceGeneration
        model.advanceGeneration()

        // Verify results match
        for x in 0..<8 {
            for y in 0..<8 {
                for z in 0..<8 {
                    let idx = model.index(x: x, y: y, z: z)
                    #expect(model.isAlive(x: x, y: y, z: z) == expectedAlive[idx],
                            "Mismatch at (\(x),\(y),\(z))")
                }
            }
        }
    }

    @Test("Interior cell neighbor counting is correct")
    func interiorCellNeighbors() {
        // Interior cell (not on boundary) should use fast path
        var model = GridModel(size: 8)
        // Place a ring of 6 face-adjacent neighbors around interior cell (4,4,4)
        model.setCell(x: 3, y: 4, z: 4, alive: true)
        model.setCell(x: 5, y: 4, z: 4, alive: true)
        model.setCell(x: 4, y: 3, z: 4, alive: true)
        model.setCell(x: 4, y: 5, z: 4, alive: true)
        model.setCell(x: 4, y: 4, z: 3, alive: true)
        model.setCell(x: 4, y: 4, z: 5, alive: true)
        // Public method uses bounds-checked path
        #expect(model.neighborCount(x: 4, y: 4, z: 4) == 6)

        // Advance and verify cell survives (6 is in survival range)
        model.advanceGeneration()
        // (4,4,4) was dead with 6 neighbors — born since 6 is in birth range
        #expect(model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("32-cube grid advances generation without error")
    func largeGridAdvance() {
        var model = GridModel(size: 32)
        model.randomSeed(density: 0.25)
        let initialAlive = model.aliveCount
        #expect(initialAlive > 0)

        model.advanceGeneration()
        // Simulation should produce some alive cells
        #expect(model.aliveCount > 0)
    }

    // MARK: - Cell Toggle Tests

    @Test("Toggle dead cell makes it alive")
    func toggleDeadCell() {
        var model = GridModel(size: 8)
        #expect(!model.isAlive(x: 3, y: 3, z: 3))
        model.toggleCell(x: 3, y: 3, z: 3)
        #expect(model.isAlive(x: 3, y: 3, z: 3))
        #expect(model.aliveCount == 1)
    }

    @Test("Toggle alive cell makes it dead")
    func toggleAliveCell() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.aliveCount == 1)
        model.toggleCell(x: 3, y: 3, z: 3)
        #expect(!model.isAlive(x: 3, y: 3, z: 3))
        #expect(model.aliveCount == 0)
    }

    @Test("Nearest grid coords from 3D position")
    func nearestGridCoords() {
        let model = GridModel(size: 16)
        let cellSize: Float = 0.015
        let cellSpacing: Float = 0.015

        // Origin maps to center cell (7 or 8 depending on rounding)
        let center = model.nearestGridCoords(for: SIMD3<Float>(0, 0, 0), cellSize: cellSize, cellSpacing: cellSpacing)
        #expect(center.x >= 7 && center.x <= 8)
        #expect(center.y >= 7 && center.y <= 8)
        #expect(center.z >= 7 && center.z <= 8)

        // Position at cell (0,0,0) should map back correctly
        let pos = model.cellPosition(x: 5, y: 10, z: 3, cellSize: cellSize, cellSpacing: cellSpacing)
        let coords = model.nearestGridCoords(for: pos, cellSize: cellSize, cellSpacing: cellSpacing)
        #expect(coords.x == 5)
        #expect(coords.y == 10)
        #expect(coords.z == 3)
    }

    // MARK: - Alive Count Caching Tests

    @Test("aliveCount stays accurate through mutations")
    func aliveCountAccuracy() {
        var model = GridModel(size: 8)
        #expect(model.aliveCount == 0)

        model.setCell(x: 0, y: 0, z: 0, alive: true)
        #expect(model.aliveCount == 1)

        model.setCell(x: 1, y: 1, z: 1, alive: true)
        #expect(model.aliveCount == 2)

        model.setCell(x: 0, y: 0, z: 0, alive: false)
        #expect(model.aliveCount == 1)

        model.clearAll()
        #expect(model.aliveCount == 0)

        model.randomSeed(density: 0.25)
        let counted = model.cells.filter { $0 > 0 }.count
        #expect(model.aliveCount == counted)
    }
}
