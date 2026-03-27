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

    // MARK: - Draw Mode / Paint Tests

    @Test("setCell alive on already alive cell preserves age")
    func setCellAlivePreservesAge() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.cellAge(x: 3, y: 3, z: 3) == 1)
        #expect(model.aliveCount == 1)
        // Setting alive again should not double-count
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.aliveCount == 1)
    }

    @Test("Multiple cells can be set alive sequentially (paint mode)")
    func paintMultipleCells() {
        var model = GridModel(size: 8)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        model.setCell(x: 2, y: 1, z: 1, alive: true)
        model.setCell(x: 3, y: 1, z: 1, alive: true)
        #expect(model.aliveCount == 3)
        #expect(model.isAlive(x: 1, y: 1, z: 1))
        #expect(model.isAlive(x: 2, y: 1, z: 1))
        #expect(model.isAlive(x: 3, y: 1, z: 1))
    }

    @Test("Default random seed uses 25% density")
    func defaultSeedDensity() {
        var model = GridModel(size: 16)
        model.randomSeed()
        // At 25% density on 16³ (4096 cells), expect ~1024 alive
        // Allow wide margin for randomness but verify it's not 10% (~410)
        #expect(model.aliveCount > 600)
    }

    // MARK: - Alive Count Caching Tests

    @Test("Fading cells persist across multiple generations")
    func fadingCellsPersist() {
        // Create a small grid with a single cell that will die (no neighbors = no survival)
        var model = GridModel(size: 4, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        #expect(model.fadingCells.isEmpty)

        // After one generation, the lone cell dies — should appear in fadingCells
        model.advanceGeneration()
        #expect(model.aliveCount == 0)
        #expect(model.fadingCells.count == 1)
        #expect(model.fadingCells[0].framesLeft == GridModel.fadeDuration)

        // After second generation, fading cell still present but decremented
        model.advanceGeneration()
        #expect(model.fadingCells.count == 1)
        #expect(model.fadingCells[0].framesLeft == GridModel.fadeDuration - 1)

        // After third generation, fading cell decremented again
        model.advanceGeneration()
        #expect(model.fadingCells.count == 1)
        #expect(model.fadingCells[0].framesLeft == GridModel.fadeDuration - 2)

        // After fourth generation (past fadeDuration=3), fading cell gone
        model.advanceGeneration()
        #expect(model.fadingCells.isEmpty)
    }

    @Test("Fading cells removed when cell is reborn")
    func fadingCellRebornRemoved() {
        // Set up conditions where a cell dies then is reborn at same position
        var model = GridModel(size: 4, birthCounts: [0], survivalCounts: [])
        // With birthCounts=[0] and survivalCounts=[], every dead cell with 0 neighbors is born,
        // and every alive cell dies. This creates a toggle pattern.
        model.setCell(x: 1, y: 1, z: 1, alive: true)

        // Gen 1: the alive cell dies (no survival), all dead cells with 0 neighbors are born
        model.advanceGeneration()
        // Cell at (1,1,1) should be fading
        let fadingIdx = model.index(x: 1, y: 1, z: 1)
        let hasFading = model.fadingCells.contains { $0.index == fadingIdx }
        #expect(hasFading)

        // Gen 2: (1,1,1) might be reborn — if so, fading entry should be removed
        model.advanceGeneration()
        if model.isAlive(x: 1, y: 1, z: 1) {
            let stillFading = model.fadingCells.contains { $0.index == fadingIdx }
            #expect(!stillFading, "Fading cell should be removed when reborn")
        }
    }

    @Test("clearAll resets fading cells")
    func clearAllResetsFading() {
        var model = GridModel(size: 4, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        model.advanceGeneration()
        #expect(!model.fadingCells.isEmpty)

        model.clearAll()
        #expect(model.fadingCells.isEmpty)
    }

    @Test("reset updates selectedPattern for auto-restart")
    @MainActor func resetUpdatesSelectedPattern() {
        let engine = SimulationEngine(size: 8)
        #expect(engine.selectedPattern == .random)

        engine.reset(pattern: .diamond)
        #expect(engine.selectedPattern == .diamond)

        engine.reset(pattern: .tube)
        #expect(engine.selectedPattern == .tube)

        // Default parameter should set to .random
        engine.reset()
        #expect(engine.selectedPattern == .random)
    }

    @Test("population trend tracks direction")
    @MainActor func populationTrend() {
        let engine = SimulationEngine(size: 8)
        // Initially no trend data
        #expect(engine.populationTrend == 0)

        // Simulate a growing population by stepping
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<6 {
            engine.step()
        }
        // Trend should have a value (can't predict exact direction with random seed)
        // but trendSymbol should be one of the valid symbols
        let validSymbols = ["arrow.up.right", "arrow.down.right", "arrow.right"]
        #expect(validSymbols.contains(engine.trendSymbol))
    }

    @Test("reset clears population trend history")
    @MainActor func resetClearsTrend() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<6 { engine.step() }
        engine.reset(pattern: .random)
        #expect(engine.populationTrend == 0)
    }

    @Test("aliveCount delta tracking matches full recount")
    func aliveCountDelta() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        for _ in 0..<10 {
            model.advanceGeneration()
            let fullCount = model.cells.filter { $0 > 0 }.count
            #expect(model.aliveCount == fullCount)
        }
    }

    @Test("Sphere pattern creates a hollow sphere shell")
    func spherePattern() {
        var model = GridModel(size: 16)
        model.loadSphere()
        // Should have a significant number of alive cells forming a shell
        #expect(model.aliveCount > 50)
        // Center of sphere should be dead (hollow)
        #expect(!model.isAlive(x: 8, y: 8, z: 8))
        // Surface of sphere should have alive cells
        // At radius ~5 from center (8,8,8), check a point on the surface
        let hasShellCell = model.isAlive(x: 8, y: 8, z: 13) || model.isAlive(x: 8, y: 8, z: 12) || model.isAlive(x: 8, y: 8, z: 11)
        #expect(hasShellCell)
    }

    @Test("Peak population tracks maximum alive count")
    @MainActor func peakPopulation() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        #expect(engine.peakPopulation == 0)

        // Step a few times to establish peak
        for _ in 0..<5 {
            engine.step()
        }
        let peak = engine.peakPopulation
        #expect(peak > 0)
        #expect(peak >= engine.grid.aliveCount)
    }

    @Test("Reset clears peak population")
    @MainActor func resetClearsPeak() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<5 { engine.step() }
        #expect(engine.peakPopulation > 0)
        engine.reset(pattern: .random)
        #expect(engine.peakPopulation == 0)
    }

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

    // MARK: - Population History & Extinction Notice

    @Test("Population history accumulates during simulation")
    @MainActor func populationHistoryAccumulates() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        #expect(engine.populationHistory.isEmpty)
        for _ in 0..<10 { engine.step() }
        #expect(engine.populationHistory.count == 10)
    }

    @Test("Population history capped at historyLength")
    @MainActor func populationHistoryCapped() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        // Step more than 60 times (history cap)
        for _ in 0..<80 { engine.step() }
        #expect(engine.populationHistory.count <= 60)
    }

    @Test("Reset clears population history")
    @MainActor func resetClearsHistory() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<5 { engine.step() }
        #expect(!engine.populationHistory.isEmpty)
        engine.reset(pattern: .random)
        #expect(engine.populationHistory.isEmpty)
    }

    @Test("Extinction notice is initially false")
    @MainActor func extinctionNoticeInitiallyFalse() {
        let engine = SimulationEngine(size: 8)
        #expect(!engine.showExtinctionNotice)
    }

    @Test("showHelp is initially false")
    @MainActor func showHelpInitiallyFalse() {
        let engine = SimulationEngine(size: 8)
        #expect(!engine.showHelp)
    }

    @Test("Reset clears extinction notice")
    @MainActor func resetClearsExtinctionNotice() {
        let engine = SimulationEngine(size: 8)
        engine.showExtinctionNotice = true
        engine.reset(pattern: .random)
        #expect(!engine.showExtinctionNotice)
    }

    @Test("Generation rate starts at zero")
    @MainActor func generationRateInitiallyZero() {
        let engine = SimulationEngine(size: 8)
        #expect(engine.generationRate == 0.0)
    }

    @Test("Reset clears generation rate")
    @MainActor func resetClearsGenerationRate() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<5 { engine.step() }
        engine.reset(pattern: .random)
        #expect(engine.generationRate == 0.0)
    }

    @Test("Array-based rule lookup matches Set-based rules")
    func arrayLookupMatchesSet() {
        // Verify that advanceGeneration with array lookups produces
        // the same results as the Set-based neighborCount
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)

        // Snapshot expected results using Set-based neighbor counting
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

        model.advanceGeneration()
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

    @Test("Infrared theme exists in allThemes")
    func infraredThemeExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Infrared" })
    }

    @Test("Bioluminescence theme exists in allThemes")
    func bioluminescenceThemeExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Bioluminescence" })
    }

    @Test("Sakura theme exists in allThemes")
    func sakuraThemeExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Sakura" })
    }

    @Test("Ember theme exists in allThemes")
    func emberThemeExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Ember" })
        #expect(ColorTheme.allThemes.count == 9)
    }

    @Test("Ember theme has fire-like color progression")
    func emberThemeColors() {
        let ember = ColorTheme.ember
        // Newborn: bright yellow-white (high red + green, lower blue)
        #expect(ember.newborn.emissiveColor.x > 0.8)  // strong red
        #expect(ember.newborn.emissiveColor.y > 0.5)   // significant green (yellow)
        #expect(ember.newborn.emissiveColor.z < 0.5)   // low blue
        // Young: orange-red (red stays high, green drops)
        #expect(ember.young.emissiveColor.x > 0.8)     // still strong red
        #expect(ember.young.emissiveColor.y < ember.newborn.emissiveColor.y) // less green = more orange
        // Mature: deep red/dark (low everything)
        #expect(ember.mature.emissiveColor.x < ember.young.emissiveColor.x) // red fades
        #expect(ember.mature.emissiveIntensity < ember.young.emissiveIntensity)
        // Higher intensity than standard themes for vivid glow
        #expect(ember.newborn.emissiveIntensity >= 2.4)
    }

    @Test("Sakura theme has warm pink emissive colors")
    func sakuraThemeColors() {
        let sakura = ColorTheme.sakura
        // Newborn should be bright pink (high red, medium-high blue, lower green)
        #expect(sakura.newborn.emissiveColor.x > 0.5)  // strong red
        #expect(sakura.newborn.emissiveColor.z > 0.5)  // strong blue
        #expect(sakura.newborn.emissiveColor.y < sakura.newborn.emissiveColor.x)  // less green than red
    }

    @Test("Double-buffered grid produces same results as single-buffer")
    func doubleBufferCorrectness() {
        // Run the same initial state through multiple generations
        // and verify aliveCount stays consistent with a full recount
        var model = GridModel(size: 12)
        model.randomSeed(density: 0.25)
        for _ in 0..<20 {
            model.advanceGeneration()
            let fullCount = model.cells.filter { $0 > 0 }.count
            #expect(model.aliveCount == fullCount,
                    "Delta-tracked aliveCount diverged from full recount after swap")
        }
    }

    @Test("Bioluminescence theme has higher emissive intensity than other themes")
    func bioluminescenceHighEmissive() {
        // Bioluminescence should be extra bright for deep-sea glow effect
        let bio = ColorTheme.bioluminescence
        #expect(bio.newborn.emissiveIntensity >= 2.5)
        #expect(bio.newborn.opacity >= 0.55)
    }
}

@Suite("Control Bar Auto-Hide Tests")
struct ControlBarTests {
    @Test("Control bar starts visible")
    @MainActor
    func controlBarInitiallyVisible() {
        let engine = SimulationEngine(size: 4)
        #expect(engine.controlBarVisible == true)
    }

    @Test("Control bar visibility can be toggled")
    @MainActor
    func controlBarToggle() {
        let engine = SimulationEngine(size: 4)
        engine.controlBarVisible = false
        #expect(engine.controlBarVisible == false)
        engine.controlBarVisible = true
        #expect(engine.controlBarVisible == true)
    }
}

@Suite("Mesh Rebuild Skip Tests")
struct MeshRebuildSkipTests {
    @Test("Stable state has no born, dying, or fading cells")
    func stableStateNoCellChanges() {
        // A 2x2x2 block is stable under B5-7/S5-8 — each cell has 7 neighbors
        var grid = GridModel(size: 8)
        grid.loadBlock()
        grid.advanceGeneration()
        // After one generation, block is stable: no births, deaths, or fading
        // (initial step may have some fading from cells outside block that were never alive)
        grid.advanceGeneration()
        grid.advanceGeneration()
        grid.advanceGeneration()
        // After several stable generations, all fading should have expired
        #expect(grid.bornCells.isEmpty)
        #expect(grid.dyingCells.isEmpty)
        #expect(grid.fadingCells.isEmpty)
    }

    @Test("Active simulation has born or dying cells")
    func activeSimulationHasCellChanges() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.25)
        grid.advanceGeneration()
        // A random seed at 25% density should have activity
        let hasActivity = !grid.bornCells.isEmpty || !grid.dyingCells.isEmpty
        #expect(hasActivity)
    }
}

@Suite("Exit Transition Tests")
struct ExitTransitionTests {
    @Test("Exit animation flags start in correct state")
    @MainActor
    func exitAnimationInitialState() {
        let engine = SimulationEngine(size: 4)
        #expect(engine.isExiting == false)
        #expect(engine.exitAnimationComplete == false)
    }

    @Test("Setting isExiting does not auto-complete")
    @MainActor
    func exitDoesNotAutoComplete() {
        let engine = SimulationEngine(size: 4)
        engine.isExiting = true
        #expect(engine.isExiting == true)
        #expect(engine.exitAnimationComplete == false)
    }
}

@Suite("Draw Mode Tests")
struct DrawModeTests {
    @Test("Draw mode is initially disabled")
    @MainActor
    func drawModeInitiallyFalse() {
        let engine = SimulationEngine(size: 4)
        #expect(engine.drawMode == false)
        #expect(engine.eraserMode == false)
    }

    @Test("Born cell positions are available for light sampling")
    func bornCellPositionsAvailable() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.25)
        grid.advanceGeneration()
        let positions = grid.bornCellPositions(cellSize: 0.015, cellSpacing: 0.015)
        // After a generation from random seed, there should be born cells
        #expect(positions.count == grid.bornCells.count)
    }
}
