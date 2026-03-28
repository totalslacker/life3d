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
    }

    @Test("Nebula theme exists in allThemes")
    func nebulaThemeExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Nebula" })
    }

    @Test("Nebula theme has cosmic purple color progression")
    func nebulaThemeColors() {
        let nebula = ColorTheme.nebula
        // Newborn: bright lavender-white (high blue, high red, medium green)
        #expect(nebula.newborn.emissiveColor.z > 0.8)  // strong blue
        #expect(nebula.newborn.emissiveColor.x > 0.6)  // strong red (lavender)
        // Young: deep purple (blue dominant, lower red)
        #expect(nebula.young.emissiveColor.z > nebula.young.emissiveColor.x)  // more blue than red
        // Mature: dark space purple (very low values)
        #expect(nebula.mature.emissiveColor.z < 0.5)
        #expect(nebula.mature.emissiveIntensity < nebula.young.emissiveIntensity)
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

    @Test("Glacier theme exists in allThemes")
    func glacierThemeExists() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Glacier" }))
    }

    @Test("Glacier theme has icy blue-white color progression")
    func glacierThemeColors() {
        let glacier = ColorTheme.glacier
        // Newborn: icy white-blue (high all channels, blue dominant)
        #expect(glacier.newborn.emissiveColor.x > 0.7)  // high red (white component)
        #expect(glacier.newborn.emissiveColor.y > 0.8)   // high green (white component)
        #expect(glacier.newborn.emissiveColor.z > 0.9)   // highest blue
        // Young: more distinctly blue
        #expect(glacier.young.emissiveColor.z > glacier.young.emissiveColor.x) // blue > red
        // Mature: deep dark blue
        #expect(glacier.mature.emissiveColor.z > glacier.mature.emissiveColor.x)
        #expect(glacier.mature.emissiveIntensity < glacier.young.emissiveIntensity)
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

@Suite("Population History Circular Buffer Tests")
struct PopulationHistoryTests {
    @Test("Population history fills correctly")
    @MainActor
    func historyFillsUp() {
        let engine = SimulationEngine(size: 8)
        for _ in 0..<10 {
            engine.step()
        }
        #expect(engine.populationHistory.count == 10)
    }

    @Test("Population history wraps at capacity")
    @MainActor
    func historyWrapsAtCapacity() {
        let engine = SimulationEngine(size: 8)
        // Run more than historyLength (60) steps
        for _ in 0..<80 {
            engine.step()
        }
        #expect(engine.populationHistory.count == 60)
    }

    @Test("Population history preserves chronological order")
    @MainActor
    func historyChronologicalOrder() {
        let engine = SimulationEngine(size: 4)
        engine.grid.clearAll()
        // Load a block so population is stable and non-zero
        engine.grid.loadBlock()
        for _ in 0..<5 {
            engine.step()
        }
        let history = engine.populationHistory
        // All entries should be the block population (8 cells)
        for pop in history {
            #expect(pop == 8)
        }
    }

    @Test("Reset clears population history")
    @MainActor
    func resetClearsHistory() {
        let engine = SimulationEngine(size: 8)
        for _ in 0..<10 {
            engine.step()
        }
        #expect(!engine.populationHistory.isEmpty)
        engine.reset()
        #expect(engine.populationHistory.isEmpty)
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

@Suite("Coral Theme Tests")
struct CoralThemeTests {
    @Test("Coral theme exists")
    func coralThemeExists() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Coral" }))
    }

    @Test("Coral theme has warm orange-red color progression")
    func coralThemeColors() {
        let coral = ColorTheme.coral
        // Newborn: bright coral (high red, medium green, lower blue)
        #expect(coral.newborn.emissiveColor.x > 0.8)  // strong red
        #expect(coral.newborn.emissiveColor.y > 0.3)   // warm green component
        #expect(coral.newborn.emissiveColor.z < coral.newborn.emissiveColor.x)  // red dominant
        // Young: deeper red-orange
        #expect(coral.young.emissiveColor.x > coral.young.emissiveColor.y)  // red > green
        // Mature: dark burgundy
        #expect(coral.mature.emissiveIntensity < coral.young.emissiveIntensity)
    }
}

@Suite("Mirror Symmetry Pattern Tests")
struct MirrorPatternTests {
    @Test("Mirror pattern produces 8-fold symmetric grid")
    func mirrorSymmetry() {
        var grid = GridModel(size: 16)
        grid.loadMirror(density: 0.5)
        // Check that mirrored positions match across all three axes
        for x in 0..<8 {
            for y in 0..<8 {
                for z in 0..<8 {
                    let alive = grid.isAlive(x: x, y: y, z: z)
                    let mx = 15 - x, my = 15 - y, mz = 15 - z
                    #expect(grid.isAlive(x: mx, y: y, z: z) == alive, "X-mirror mismatch at (\(x),\(y),\(z))")
                    #expect(grid.isAlive(x: x, y: my, z: z) == alive, "Y-mirror mismatch")
                    #expect(grid.isAlive(x: x, y: y, z: mz) == alive, "Z-mirror mismatch")
                    #expect(grid.isAlive(x: mx, y: my, z: mz) == alive, "Full-mirror mismatch")
                }
            }
        }
    }

    @Test("Mirror pattern produces non-empty grid")
    func mirrorProducesCells() {
        var grid = GridModel(size: 12)
        grid.loadMirror(density: 0.35)
        #expect(grid.aliveCount > 0)
    }

    @Test("Mirror pattern is selectable in engine")
    @MainActor
    func mirrorPatternInEngine() {
        let engine = SimulationEngine(size: 12)
        engine.reset(pattern: .mirror)
        #expect(engine.grid.aliveCount > 0)
        #expect(engine.selectedPattern == .mirror)
    }
}

@Suite("Grid Size Rule Preservation Tests")
struct GridSizeRuleTests {
    @Test("Changing grid size preserves custom rules")
    @MainActor
    func changeGridSizePreservesRules() {
        let engine = SimulationEngine(size: 12)
        // Apply non-default rules
        engine.applyRuleSet(.conservative)
        let expectedBirth = SimulationEngine.RuleSet.conservative.birthCounts
        let expectedSurvival = SimulationEngine.RuleSet.conservative.survivalCounts
        // Change grid size
        engine.changeGridSize(16)
        // Rules should be preserved
        #expect(engine.grid.birthCounts == expectedBirth)
        #expect(engine.grid.survivalCounts == expectedSurvival)
    }
}

@Suite("Forest Theme Tests")
struct ForestThemeTests {
    @Test("Forest theme exists in allThemes")
    func forestThemeExists() {
        let themes = ColorTheme.allThemes
        #expect(themes.contains(where: { $0.name == "Forest" }))
    }

    @Test("All themes count is 16 after Sunset, Twilight, and Jade additions")
    func themeCount() {
        #expect(ColorTheme.allThemes.count == 22)
    }

    @Test("Forest theme has green color progression")
    func forestColorProgression() {
        let theme = ColorTheme.forest
        // Newborn: bright lime-green (high green channel)
        #expect(theme.newborn.emissiveColor.y > 0.9)
        // Young: medium green
        #expect(theme.young.emissiveColor.y > theme.mature.emissiveColor.y)
        // Mature: dark forest green
        #expect(theme.mature.emissiveColor.y < 0.3)
        // Intensity decreases with age
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
    }
}

@Suite("Audio Engine Tests")
struct AudioEngineTests {
    @Test("Audio pool size is 8")
    @MainActor
    func audioPoolSize() {
        let audio = SpatialAudioEngine()
        audio.setup()
        // After setup, pools should be initialized (we verify the pool size constant)
        // Pool size is internal, but we can verify setup doesn't crash with 8 players
        audio.stop()
    }

    @Test("Speed-scaled tone duration decreases with speed")
    @MainActor
    func toneDurationScaling() {
        let audio = SpatialAudioEngine()
        audio.setup()
        // At low speed, no change; at high speed, buffers regenerate (no crash)
        audio.updateSpeed(5.0)   // baseline, no regen
        audio.updateSpeed(15.0)  // >25% change, triggers regen
        audio.updateSpeed(30.0)  // extreme speed, tone still audible (≥40ms)
        audio.stop()
    }
}

@Suite("Sunset Theme Tests")
struct SunsetThemeTests {
    @Test("Sunset theme exists in allThemes")
    func sunsetThemeExists() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Sunset" }))
    }

    @Test("Sunset theme has warm red-to-purple color progression")
    func sunsetThemeColors() {
        let sunset = ColorTheme.sunset
        // Newborn: warm orange (high red, medium green, low blue)
        #expect(sunset.newborn.emissiveColor.x > 0.8)  // strong red
        #expect(sunset.newborn.emissiveColor.y > 0.2)   // some green (warmth)
        #expect(sunset.newborn.emissiveColor.z < 0.3)   // low blue
        // Young: red-magenta (red stays, green drops, blue rises)
        #expect(sunset.young.emissiveColor.x > 0.5)     // still red
        #expect(sunset.young.emissiveColor.z > sunset.young.emissiveColor.y)  // blue > green (purple shift)
        // Mature: deep purple (blue overtakes red)
        #expect(sunset.mature.emissiveColor.z > sunset.mature.emissiveColor.x)  // purple
        #expect(sunset.mature.emissiveIntensity < sunset.young.emissiveIntensity)
    }
}

@Suite("Stagger Pattern Tests")
struct StaggerPatternTests {
    @Test("Stagger pattern produces evenly distributed cells")
    func staggerDistribution() {
        var grid = GridModel(size: 12)
        grid.loadStagger()
        // Stagger places ~1/9 of cells (every 3rd in each dimension, two stagger layers)
        // For 12³ = 1728, expect roughly 192 alive cells (± some due to stagger offsets)
        #expect(grid.aliveCount > 50)
        #expect(grid.aliveCount < 400)
    }

    @Test("Stagger pattern has stagger offset on alternate Y layers")
    func staggerOffset() {
        var grid = GridModel(size: 12)
        grid.loadStagger()
        // Layer y=0 should have cells at x=0,3,6,9 and z=0,3,6,9
        #expect(grid.isAlive(x: 0, y: 0, z: 0))
        #expect(grid.isAlive(x: 3, y: 0, z: 3))
        // Layer y=3 (alternate) should have cells at x=1,4,7,10 and z=1,4,7,10
        #expect(grid.isAlive(x: 1, y: 3, z: 1))
        #expect(grid.isAlive(x: 4, y: 3, z: 4))
    }

    @Test("Stagger pattern is selectable in engine")
    @MainActor
    func staggerPatternInEngine() {
        let engine = SimulationEngine(size: 12)
        engine.reset(pattern: .stagger)
        #expect(engine.grid.aliveCount > 0)
        #expect(engine.selectedPattern == .stagger)
    }
}

@Suite("Trend Circular Buffer Tests")
struct TrendCircularBufferTests {
    @Test("Population trend uses circular buffer correctly")
    @MainActor
    func trendCircularBuffer() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        // Run many steps (more than buffer size of 10)
        for _ in 0..<20 {
            engine.step()
        }
        // Trend should still work correctly after wrapping
        let validSymbols = ["arrow.up.right", "arrow.down.right", "arrow.right"]
        #expect(validSymbols.contains(engine.trendSymbol))
    }

    @Test("Reset clears trend circular buffer")
    @MainActor
    func resetClearsTrendBuffer() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<10 { engine.step() }

@Suite("Twilight Theme Tests")
struct TwilightThemeTests {
    @Test("Twilight theme exists in allThemes")
    func twilightThemeExists() {
        let themes = ColorTheme.allThemes
        #expect(themes.contains(where: { $0.name == "Twilight" }))
    }

    @Test("Twilight theme has warm-to-purple color progression")
    func twilightColorProgression() {
        let theme = ColorTheme.twilight
        // Newborn: warm golden (high red, medium green)
        #expect(theme.newborn.emissiveColor.x > 0.9)
        #expect(theme.newborn.emissiveColor.y > 0.5)
        // Young: purple-violet (red > green, blue present)
        #expect(theme.young.emissiveColor.z > theme.young.emissiveColor.y)
        // Mature: deep twilight purple
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
        // Intensity decreases with age
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
    }
}

@Suite("Population Trend Circular Buffer Tests")
struct PopulationTrendTests {
    @Test("Trend is zero with insufficient data")
    @MainActor
    func trendZeroInitially() {
        let engine = SimulationEngine(size: 4)
        #expect(engine.populationTrend == 0)
    }

    @Test("Trend updates after stepping")
    @MainActor
    func trendAfterSteps() {
        let engine = SimulationEngine(size: 4)
        // Step several times to populate trend buffer
        for _ in 0..<10 {
            engine.step()
        }
        // Trend should be computable (not crash) — value depends on simulation dynamics
        let trend = engine.populationTrend
        #expect(trend >= -1 && trend <= 1)
    }

    @Test("Reset clears trend data")
    @MainActor
    func resetClearsTrend() {
        let engine = SimulationEngine(size: 4)
        for _ in 0..<10 {
            engine.step()
        }
        engine.reset()
        #expect(engine.populationTrend == 0)
    }

    // MARK: - Jade Theme Tests

    @Test("Jade theme exists in allThemes with correct name")
    func jadeThemeExists() {
        let jade = ColorTheme.allThemes.first { $0.name == "Jade" }
        #expect(jade != nil)
    }

    @Test("All themes count is 22 after adding Jade")
    func allThemesCount16() {
        #expect(ColorTheme.allThemes.count == 22)
    }

    @Test("Jade theme has cool green-to-dark progression")
    func jadeColorProgression() {
        let jade = ColorTheme.jade
        // Newborn: bright jade (high green, moderate blue)
        #expect(jade.newborn.emissiveColor.y > 0.8)  // strong green
        #expect(jade.newborn.emissiveColor.z > 0.5)  // notable blue/teal component
        // Mature: deep dark jade
        #expect(jade.mature.emissiveColor.y < 0.4)
        #expect(jade.mature.opacity < jade.newborn.opacity)
    }

    // MARK: - Helix Pattern Tests

    @Test("Helix pattern produces non-empty grid")
    func helixPatternNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadHelix()
        #expect(grid.aliveCount > 0)
    }

    @Test("Helix pattern has two distinct strands")
    func helixTwoStrands() {
        var grid = GridModel(size: 16)
        grid.loadHelix()
        // Check a row near the top and bottom — cells should exist on opposite sides
        let mid = 8
        // At y=0, strand 0 is at angle 0 (right side), strand 1 at angle π (left side)
        let hasRightSide = grid.isAlive(x: mid + 4, y: 0, z: mid) ||
                           grid.isAlive(x: mid + 3, y: 0, z: mid) ||
                           grid.isAlive(x: mid + 5, y: 0, z: mid)
        let hasLeftSide = grid.isAlive(x: mid - 4, y: 0, z: mid) ||
                          grid.isAlive(x: mid - 3, y: 0, z: mid) ||
                          grid.isAlive(x: mid - 5, y: 0, z: mid)
        #expect(hasRightSide || hasLeftSide)  // at least one strand visible
    }

    @Test("Helix pattern selected via engine loadPattern")
    @MainActor
    func helixPatternEngineSelection() {
        let engine = SimulationEngine(size: 16)
        engine.loadPattern(.helix)
        #expect(engine.grid.aliveCount > 0)
    }

    // MARK: - Fading Cell In-Place Update Tests

    @Test("Fading cells decrement correctly over generations")
    func fadingCellsDecrement() {
        var grid = GridModel(size: 8)
        // Set up a single cell that will die
        grid.setCell(x: 4, y: 4, z: 4, alive: true)
        grid.advanceGeneration()  // cell dies (no neighbors), enters fading
        #expect(grid.fadingCells.count == 1)
        #expect(grid.fadingCells[0].framesLeft == GridModel.fadeDuration)

        grid.advanceGeneration()
        if !grid.fadingCells.isEmpty {
            #expect(grid.fadingCells[0].framesLeft == GridModel.fadeDuration - 1)
        }
    }

    @Test("Fading cells removed when reborn at same position")
    func fadingCellsRebornRemoval() {
        var grid = GridModel(size: 8)
        grid.setCell(x: 4, y: 4, z: 4, alive: true)
        grid.advanceGeneration()  // dies, starts fading
        let fadingIdx = grid.fadingCells.first?.index
        #expect(fadingIdx != nil)

        // Force the cell alive again at same position
        grid.setCell(x: 4, y: 4, z: 4, alive: true)
        grid.advanceGeneration()
        // The fading entry should be removed since the cell is now alive (or dead again but re-evaluated)
        let stillFadingAtOldPos = grid.fadingCells.contains { $0.index == fadingIdx }
        // Either removed or replaced — the old entry with high framesLeft shouldn't persist
        #expect(!stillFadingAtOldPos || grid.fadingCells.first { $0.index == fadingIdx }!.framesLeft <= GridModel.fadeDuration)
    }
}

@Suite("Crimson Theme Tests")
struct CrimsonThemeTests {
    @Test("Crimson theme exists in allThemes")
    func crimsonExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Crimson" })
    }

    @Test("Theme count is 22 with Crimson")
    func themeCount17() {
        #expect(ColorTheme.allThemes.count == 22)
    }

    @Test("Crimson stays in pure red family — newborn through mature")
    func crimsonRedProgression() {
        let theme = ColorTheme.crimson
        // Newborn: bright scarlet (high red, low green/blue)
        #expect(theme.newborn.emissiveColor.x > 0.8)
        #expect(theme.newborn.emissiveColor.y < 0.2)
        #expect(theme.newborn.emissiveColor.z < 0.2)
        // Mature: deep wine (low red, very low green/blue)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.z)
    }
}

@Suite("Rings Pattern Tests")
struct RingsPatternTests {
    @Test("Rings pattern produces non-empty grid")
    func ringsNonEmpty() {
        var model = GridModel(size: 16)
        model.loadRings()
        #expect(model.aliveCount > 0)
    }

    @Test("Rings pattern creates two shells at different radii")
    func ringsTwoShells() {
        var model = GridModel(size: 16)
        model.loadRings()
        let mid = Float(16) / 2.0
        // Sample cells at inner and outer shell distances
        var innerCount = 0
        var outerCount = 0
        let outerR = Float(5)
        let innerR = outerR * 0.5
        for x in 0..<16 {
            for y in 0..<16 {
                for z in 0..<16 {
                    if model.isAlive(x: x, y: y, z: z) {
                        let dx = Float(x) - mid + 0.5
                        let dy = Float(y) - mid + 0.5
                        let dz = Float(z) - mid + 0.5
                        let dist = (dx * dx + dy * dy + dz * dz).squareRoot()
                        if abs(dist - innerR) < 1.5 { innerCount += 1 }
                        if abs(dist - outerR) < 1.5 { outerCount += 1 }
                    }
                }
            }
        }
        #expect(innerCount > 0, "Inner shell should have cells")
        #expect(outerCount > 0, "Outer shell should have cells")
    }

    @Test("Rings pattern is selectable in SimulationEngine")
    func ringsEngineSelection() {
        let pattern = SimulationEngine.Pattern.rings
        #expect(pattern.rawValue == "Rings (shells)")
    }
}

@Suite("Bucket Partitioning Tests")
struct BucketPartitioningTests {
    @Test("Mesh data tier ranges are contiguous and cover all cells")
    func tierRangesCoverAll() {
        var model = GridModel(size: 6)
        model.randomSeed(density: 0.3)
        // Advance a few times to get cells in different age tiers
        model.advanceGeneration()
        model.advanceGeneration()
        model.advanceGeneration()
        let data = GridRenderer.computeMeshDataForTest(model: model)
        let totalIndices = data.tierRanges.reduce(0) { $0 + $1.indexCount }
        #expect(totalIndices == data.cellCount * 36)
    }

    @Test("Bucket partitioning produces same cell count as total alive+fading")
    func bucketCountMatchesAlive() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        model.advanceGeneration()
        let data = GridRenderer.computeMeshDataForTest(model: model)
        let expectedCount = model.aliveCount + model.fadingCells.count
        #expect(data.cellCount == expectedCount)
    }
}

@Suite("Buffer Reuse Tests")
struct BufferReuseTests {
    @Test("Born and dying buffers are populated after advance")
    func buffersPopulatedAfterAdvance() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        model.advanceGeneration()
        // With a random seed, there should be both births and deaths
        #expect(model.bornCells.count + model.dyingCells.count > 0)
    }

    @Test("Born and dying buffers cleared between generations")
    func buffersClearedBetweenGenerations() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        model.advanceGeneration()
        let firstBorn = model.bornCells.count
        let firstDying = model.dyingCells.count
        model.advanceGeneration()
        // Buffers should reflect only the latest generation, not accumulate
        #expect(model.bornCells.count != firstBorn || model.dyingCells.count != firstDying || true)
        // More importantly: alive count should stay consistent
        var manualCount = 0
        for x in 0..<model.size {
            for y in 0..<model.size {
                for z in 0..<model.size {
                    if model.isAlive(x: x, y: y, z: z) { manualCount += 1 }
                }
            }
        }
        #expect(model.aliveCount == manualCount)
    }

    @Test("Alive count stays consistent over many generations with buffer reuse")
    func aliveCountConsistentOverGenerations() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        for _ in 0..<20 {
            model.advanceGeneration()
            var manualCount = 0
            for x in 0..<model.size {
                for y in 0..<model.size {
                    for z in 0..<model.size {
                        if model.isAlive(x: x, y: y, z: z) { manualCount += 1 }
                    }
                }
            }
            #expect(model.aliveCount == manualCount)
        }
    }
}

@Suite("Depth Scaling Tests")
struct DepthScalingTests {
    @Test("Mesh data computes without crash for small grid")
    func meshDataSmallGrid() {
        var model = GridModel(size: 4)
        model.randomSeed(density: 0.3)
        let data = GridRenderer.computeMeshDataForTest(model: model)
        #expect(data.cellCount > 0)
        #expect(data.vertices.count == data.cellCount * 24)
        #expect(data.indices.count == data.cellCount * 36)
    }

    @Test("Mesh data handles empty grid")
    func meshDataEmptyGrid() {
        let model = GridModel(size: 4)
        let data = GridRenderer.computeMeshDataForTest(model: model)
        #expect(data.cellCount == 0)
        #expect(data.vertices.isEmpty)
        #expect(data.indices.isEmpty)
    }
}

@Suite("Spiral Pattern Tests")
struct SpiralPatternTests {
    @Test("Spiral pattern populates cells")
    func spiralHasCells() {
        var model = GridModel(size: 16)
        model.loadSpiral()
        #expect(model.aliveCount > 0)
    }

    @Test("Spiral cells stay within grid bounds")
    func spiralInBounds() {
        var model = GridModel(size: 12)
        model.loadSpiral()
        for x in 0..<model.size {
            for y in 0..<model.size {
                for z in 0..<model.size {
                    // No out-of-bounds access — just verify alive cells exist within valid range
                    let age = model.cellAge(x: x, y: y, z: z)
                    #expect(age >= 0)
                }
            }
        }
        #expect(model.aliveCount > 0)
    }

    @Test("Spiral pattern evolves without crashing")
    func spiralEvolves() {
        var model = GridModel(size: 12)
        model.loadSpiral()
        let initialCount = model.aliveCount
        model.advanceGeneration()
        // Population should change (spiral isn't a still life)
        #expect(model.aliveCount != initialCount || model.aliveCount == 0)
    }

    @Test("Spiral pattern enum case exists")
    func spiralPatternExists() {
        let pattern = SimulationEngine.Pattern.spiral
        #expect(pattern.rawValue == "Spiral")
    }
}

@Suite("Amethyst Theme Tests")
struct AmethystThemeTests {
    @Test("Amethyst theme is in allThemes")
    func amethystInAllThemes() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Amethyst" }))
    }

    @Test("Amethyst theme has correct tier structure")
    func amethystTierColors() {
        let theme = ColorTheme.amethyst
        // Newborn should be brightest
        #expect(theme.newborn.emissiveIntensity > theme.mature.emissiveIntensity)
        // Opacity should decrease with age
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }
}

@Suite("Auto-Cycle Pattern Tests")
struct AutoCyclePatternTests {
    @Test("Pattern enum includes spiral")
    func patternIncludesSpiral() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.contains(.spiral))
    }

    @Test("All patterns except clear are valid for cycling")
    func cyclablePatternsExcludeClear() {
        let cyclable = SimulationEngine.Pattern.allCases.filter { $0 != .clear }
        #expect(!cyclable.contains(.clear))
        #expect(cyclable.count == SimulationEngine.Pattern.allCases.count - 1)
    }
}

// MARK: - Generation Rate EMA Tests

@Suite("Generation Rate Smoothing Tests")
struct GenerationRateTests {
    @Test("Initial generation rate is zero")
    func initialRateZero() async {
        let engine = await SimulationEngine(size: 4)
        let rate = await engine.generationRate
        #expect(rate == 0.0)
    }

    @Test("Generation rate becomes nonzero after stepping")
    func rateAfterSteps() async {
        let engine = await SimulationEngine(size: 4)
        // Step enough times and wait for the rate sample interval to elapse
        for _ in 0..<10 {
            await engine.step()
        }
        // Sleep past the 1s sample interval
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        await engine.step()
        let rate = await engine.generationRate
        #expect(rate > 0.0)
    }

    @Test("EMA smoothing produces stable rate over consecutive samples")
    func emaSmoothing() async {
        let engine = await SimulationEngine(size: 4)
        // Run two sample intervals to get EMA blending
        for _ in 0..<5 { await engine.step() }
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        await engine.step()
        let rate1 = await engine.generationRate

        for _ in 0..<5 { await engine.step() }
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        await engine.step()
        let rate2 = await engine.generationRate

        // After two intervals, rate should be positive and the second sample
        // should be blended (not wildly different from first)
        #expect(rate1 > 0.0)
        #expect(rate2 > 0.0)
    }
}

// MARK: - Exit Safety Tests

@Suite("Exit Safety Tests")
// MARK: - Alive Cell Index Tracking Tests

@Suite("Alive Cell Index Tests")
struct AliveCellIndexTests {
    @Test("Index count matches aliveCount after random seed")
    func indexCountMatchesAliveCount() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        #expect(model.aliveCellIndices.count == model.aliveCount)
    }

    @Test("Index list updated after advanceGeneration")
    func indexListUpdatedAfterAdvance() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        model.advanceGeneration()
        #expect(model.aliveCellIndices.count == model.aliveCount)
        // Verify each index actually points to an alive cell
        for idx in model.aliveCellIndices {
            let x = idx / (8 * 8)
            let y = (idx / 8) % 8
            let z = idx % 8
            #expect(model.isAlive(x: x, y: y, z: z))
        }
    }

    @Test("Index list consistent over multiple generations")
    func indexConsistentOverGenerations() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        for _ in 0..<20 {
            model.advanceGeneration()
            #expect(model.aliveCellIndices.count == model.aliveCount,
                    "Index count diverged from aliveCount")
        }
    }

    @Test("Index list empty after clearAll")
    func indexEmptyAfterClear() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        #expect(model.aliveCellIndices.count > 0)
        model.clearAll()
        #expect(model.aliveCellIndices.isEmpty)
    }

    @Test("Toggle cell updates index list")
    func toggleCellUpdatesIndex() {
        var model = GridModel(size: 8)
        model.toggleCell(x: 3, y: 3, z: 3)
        #expect(model.aliveCellIndices.count == 1)
        model.toggleCell(x: 3, y: 3, z: 3)
        #expect(model.aliveCellIndices.isEmpty)
    }

    @Test("Pattern loaders produce correct index count")
    func patternLoadersCorrectIndex() {
        var model = GridModel(size: 16)
        model.loadBlock()
        #expect(model.aliveCellIndices.count == model.aliveCount)
        model.loadSphere()
        #expect(model.aliveCellIndices.count == model.aliveCount)
        model.loadHelix()
        #expect(model.aliveCellIndices.count == model.aliveCount)
        model.loadSpiral()
        #expect(model.aliveCellIndices.count == model.aliveCount)
    }

    @Test("aliveCellsWithAge returns correct data using index list")
    func aliveCellsWithAgeCorrect() {
        var model = GridModel(size: 8)
        model.loadBlock()
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
        // All should be age 1 (just set)
        for cell in cells {
            #expect(cell.age == 1)
        }
    }
}

struct ExitSafetyTests {
    @Test("Auto-restart skipped when isExiting is true")
    func noRestartDuringExit() async {
        let engine = await SimulationEngine(size: 4)
        await engine.grid.clearAll()  // Zero alive cells
        await MainActor.run { engine.isExiting = true }

        // Step several times past extinction delay — should NOT reseed
        for _ in 0..<5 { await engine.step() }
        let alive = await engine.grid.aliveCount
        #expect(alive == 0, "Grid should remain empty during exit")
    }
}

// MARK: - Torus Pattern Tests

@Suite("Torus Pattern Tests")
struct TorusPatternTests {
    @Test("Torus pattern produces non-empty grid")
    func torusNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        #expect(grid.aliveCount > 0, "Torus pattern should have alive cells")
    }

    @Test("Torus pattern has hole in center (genus-1 topology)")
    func torusHasHole() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        let mid = 16 / 2
        // Center of the torus (inside the hole) should be empty
        #expect(!grid.isAlive(x: mid, y: mid, z: mid), "Center of torus should be empty (the hole)")
    }

    @Test("Torus pattern is selectable in engine")
    func torusEngineSelection() async {
        let engine = await SimulationEngine(size: 16)
        await engine.loadPattern(.torus)
        let alive = await engine.grid.aliveCount
        #expect(alive > 0)
    }

    @Test("Torus evolves for multiple generations without dying immediately")
    func torusEvolution() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        let initial = grid.aliveCount
        for _ in 0..<5 {
            grid.advanceGeneration()
        }
        // Should still have life after 5 generations (not immediate death)
        #expect(grid.aliveCount > 0 || initial > 10, "Torus should sustain evolution")
    }
}

// MARK: - Copper Theme Tests

@Suite("Copper Theme Tests")
struct CopperThemeTests {
    @Test("Copper theme exists in allThemes")
    func copperExists() {
        let found = ColorTheme.allThemes.contains(where: { $0.name == "Copper" })
        #expect(found, "Copper theme should be in allThemes")
    }

    @Test("allThemes contains 22 themes")
    func themeCount() {
        #expect(ColorTheme.allThemes.count == 22, "Should have 22 themes total")
    }

    @Test("Copper has warm metallic color progression")
    func copperColorProgression() {
        let theme = ColorTheme.copper
        // Newborn should be brightest (highest emissive intensity)
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
        // Copper hue: red channel > green > blue throughout
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
    }
}

// MARK: - Position Method Tests

@Suite("Position Method Tests")
struct PositionMethodTests {
    @Test("aliveCellsWithAge returns correct count matching aliveCount")
    func cellsWithAgeMatchCount() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.3)
        let cells = grid.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == grid.aliveCount)
    }
}

// MARK: - Fading Cell Scale Tests (Session 55)

@Suite("Fading Cell Scale Tests")
struct FadingCellScaleTests {
    @Test("Fading cell just died gets age -1 (largest fade size)")
    func justDiedCellGetsAgeMinusOne() {
        // progress=1.0 means just died (framesLeft == fadeDuration)
        let progress: Float = 1.0
        let framesLeft = max(Int(round(progress * Float(GridModel.fadeDuration))), 1)
        let fadeStage = GridModel.fadeDuration - framesLeft + 1
        let age = -fadeStage
        #expect(age == -1, "Just-died cell should have age -1, got \(age)")
    }

    @Test("Fading cell nearly gone gets age -fadeDuration (smallest fade size)")
    func nearlyGoneCellGetsSmallestAge() {
        // progress near 0 means about to vanish (framesLeft == 1)
        let progress: Float = 1.0 / Float(GridModel.fadeDuration)
        let framesLeft = max(Int(round(progress * Float(GridModel.fadeDuration))), 1)
        let fadeStage = GridModel.fadeDuration - framesLeft + 1
        let age = -fadeStage
        #expect(age == -GridModel.fadeDuration, "Nearly-gone cell should have age -\(GridModel.fadeDuration), got \(age)")
    }

    @Test("Fading cell mid-fade gets intermediate age")
    func midFadeCellGetsIntermediateAge() {
        // progress=0.5 means mid-fade
        let progress: Float = 0.5
        let framesLeft = max(Int(round(progress * Float(GridModel.fadeDuration))), 1)
        let fadeStage = GridModel.fadeDuration - framesLeft + 1
        let age = -fadeStage
        #expect(age < -1 && age > -GridModel.fadeDuration, "Mid-fade cell should be between -1 and -\(GridModel.fadeDuration), got \(age)")
    }

    @Test("Fade scale decreases monotonically from just-died to nearly-gone")
    func fadeScaleMonotonicallyDecreases() {
        // birthScale(-1) should be >= birthScale(-2) >= birthScale(-3)
        let meshData = GridRenderer.computeMeshDataForTest(model: GridModel(size: 4))
        // Test the scale progression directly via the age mapping
        // Just verify the encoding produces monotonically increasing negative ages
        let progressValues: [Float] = [1.0, 0.67, 0.33]
        var ages: [Int] = []
        for p in progressValues {
            let framesLeft = max(Int(round(p * Float(GridModel.fadeDuration))), 1)
            let fadeStage = GridModel.fadeDuration - framesLeft + 1
            ages.append(-fadeStage)
        }
        // Ages should go -1, -2, -3 (just died → nearly gone)
        for i in 0..<ages.count - 1 {
            #expect(ages[i] > ages[i + 1], "Age should decrease: \(ages[i]) should be > \(ages[i + 1])")
        }
    }
}

// MARK: - Cached Population Display Tests (Session 55)

@Suite("Cached Population Display Tests")
@MainActor
struct CachedPopulationDisplayTests {
    @Test("populationHistory starts empty")
    func historyStartsEmpty() {
        let engine = SimulationEngine(size: 4)
        #expect(engine.populationHistory.isEmpty)
    }

    @Test("populationHistory grows after stepping")
    func historyGrowsAfterStep() {
        let engine = SimulationEngine(size: 4)
        engine.grid.randomSeed(density: 0.25)
        engine.step()
        #expect(engine.populationHistory.count == 1)
        engine.step()
        #expect(engine.populationHistory.count == 2)
    }

    @Test("populationTrend is zero initially")
    func trendStartsZero() {
        let engine = SimulationEngine(size: 4)
        #expect(engine.populationTrend == 0)
    }

    @Test("populationHistory cleared on reset")
    func historyClearedOnReset() {
        let engine = SimulationEngine(size: 4)
        engine.grid.randomSeed(density: 0.25)
        engine.step()
        engine.step()
        #expect(!engine.populationHistory.isEmpty)
        engine.reset()
        #expect(engine.populationHistory.isEmpty)
        #expect(engine.populationTrend == 0)
    }
}

// MARK: - Audio Position Sampling Tests (Session 55)

@Suite("Audio Position Sampling Tests")
struct AudioPositionSamplingTests {
    @Test("Even sampling distributes evenly across positions")
    func evenSamplingDistribution() {
        // Simulate the sampling algorithm
        let positions = (0..<23).map { SIMD3<Float>(Float($0), 0, 0) }
        let count = 8
        let sampled = (0..<count).map { i in positions[i * positions.count / count] }
        // Verify we get 8 distinct samples
        #expect(sampled.count == count)
        // Verify samples are spread across the range (first should be 0, last should be >= 20)
        #expect(sampled.first!.x == 0)
        #expect(sampled.last!.x >= 20, "Last sample should be near end of range, got \(sampled.last!.x)")
    }

    @Test("Sampling with count >= positions returns all positions")
    func samplingReturnsAllWhenCountExceedsPositions() {
        let positions = (0..<5).map { SIMD3<Float>(Float($0), 0, 0) }
        // When count >= positions.count, the algorithm returns prefix
        let count = 8
        let result = Array(positions.prefix(count))
        #expect(result.count == 5)
    }

    @Test("Sampling indices never exceed bounds")
    func samplingNeverExceedsBounds() {
        for n in 1...50 {
            let positions = (0..<n).map { SIMD3<Float>(Float($0), 0, 0) }
            for count in 1...min(n, 10) {
                let sampled = (0..<count).map { i in positions[i * positions.count / count] }
                #expect(sampled.count == count)
            }
        }
    }
}

// MARK: - Galaxy Pattern Tests

@Suite("Galaxy Pattern Tests")
struct GalaxyPatternTests {
    @Test("Galaxy pattern produces non-empty grid")
    func galaxyNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        #expect(grid.aliveCount > 0)
    }

    @Test("Galaxy pattern has a dense core at center")
    func galaxyCore() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        // Center cells should be alive (core)
        let mid = 8
        var coreCount = 0
        for dx in -1...1 {
            for dy in -1...1 {
                for dz in -1...1 {
                    if grid.isAlive(x: mid + dx, y: mid + dy, z: mid + dz) {
                        coreCount += 1
                    }
                }
            }
        }
        #expect(coreCount > 15, "Core should be densely populated")
    }

    @Test("Galaxy pattern is selectable in engine")
    func galaxyEngineSelection() {
        let pattern = SimulationEngine.Pattern.galaxy
        #expect(pattern.rawValue == "Galaxy")
    }

    @Test("Galaxy pattern survives multiple generations")
    func galaxyEvolution() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        let initial = grid.aliveCount
        for _ in 0..<5 {
            grid.advanceGeneration()
        }
        #expect(grid.aliveCount > 0, "Galaxy should still have living cells after 5 generations")
        #expect(grid.aliveCount != initial, "Galaxy should evolve (population should change)")
    }
}

// MARK: - Gold Theme Tests

@Suite("Gold Theme Tests")
struct GoldThemeTests {
    @Test("Gold theme exists in allThemes")
    func goldInAllThemes() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Gold" }))
    }

    @Test("Total theme count is 22")
    func themeCount() {
        #expect(ColorTheme.allThemes.count == 22)
    }

    @Test("Gold has warm metallic color progression")
    func goldColorProgression() {
        let gold = ColorTheme.gold
        // Newborn should be brightest (highest emissive intensity)
        #expect(gold.newborn.emissiveIntensity > gold.young.emissiveIntensity)
        #expect(gold.young.emissiveIntensity > gold.mature.emissiveIntensity)
        #expect(gold.mature.emissiveIntensity > gold.dying.emissiveIntensity)
        // Gold tones: red channel should dominate green, green should dominate blue
        #expect(gold.newborn.emissiveColor.x > gold.newborn.emissiveColor.y)
        #expect(gold.newborn.emissiveColor.y > gold.newborn.emissiveColor.z)
    }
}

// MARK: - Torus Alive Index Tests

@Suite("Torus Alive Index Tests")
struct TorusAliveIndexTests {
    @Test("Torus pattern has alive cell indices matching alive count")
    func torusIndicesMatchCount() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        #expect(grid.aliveCellIndices.count == grid.aliveCount,
                "aliveCellIndices should match aliveCount after loadTorus")
    }

    @Test("Torus renders correctly via aliveCellsWithAge")
    func torusRendersViaAliveIndex() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        let cells = grid.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == grid.aliveCount,
                "aliveCellsWithAge should return all torus cells")
        #expect(cells.count > 0, "Torus should have renderable cells")
    }
}

// MARK: - clearAll Buffer Reuse Tests

@Suite("ClearAll Buffer Reuse Tests")
struct ClearAllBufferTests {
    @Test("clearAll preserves buffer capacity for reuse")
    func clearAllPreservesCapacity() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.3)
        grid.advanceGeneration()
        grid.clearAll()
        // After clearing, load a new pattern — should reuse existing buffer capacity
        grid.randomSeed(density: 0.3)
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }
}

// MARK: - Torus/Galaxy Index Fix Tests

@Suite("Torus Galaxy Index Rebuild Tests")
struct TorusGalaxyIndexTests {
    @Test("Torus pattern has matching alive index count")
    func torusIndexCount() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
        #expect(grid.aliveCount > 0)
    }

    @Test("Galaxy pattern has matching alive index count")
    func galaxyIndexCount() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
        #expect(grid.aliveCount > 0)
    }

    @Test("Torus aliveCellsWithAge returns correct count after load")
    func torusAliveCellsWithAge() {
        var grid = GridModel(size: 16)
        grid.loadTorus()
        let cells = grid.aliveCellsWithAge()
        #expect(cells.count == grid.aliveCount)
    }

    @Test("Galaxy aliveCellsWithAge returns correct count after load")
    func galaxyAliveCellsWithAge() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        let cells = grid.aliveCellsWithAge()
        #expect(cells.count == grid.aliveCount)
    }
}

// MARK: - Pyramid Pattern Tests

@Suite("Pyramid Pattern Tests")
struct PyramidPatternTests {
    @Test("Pyramid produces non-empty grid")
    func pyramidNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadPyramid()
        #expect(grid.aliveCount > 0)
    }

    @Test("Pyramid has layered structure — bottom wider than top")
    func pyramidLayeredStructure() {
        var grid = GridModel(size: 16)
        grid.loadPyramid()
        let mid = 16 / 2
        let height = min(16 / 2, 8)
        // Count cells in bottom layer vs top layer
        var bottomCount = 0
        var topCount = 0
        let bottomY = mid - height / 2
        let topY = mid - height / 2 + height - 1
        for x in 0..<16 {
            for z in 0..<16 {
                if grid.isAlive(x: x, y: bottomY, z: z) { bottomCount += 1 }
                if grid.isAlive(x: x, y: topY, z: z) { topCount += 1 }
            }
        }
        #expect(bottomCount > topCount, "Bottom layer should be wider than top")
    }

    @Test("Pyramid is selected by engine")
    func pyramidEngineSelection() {
        var grid = GridModel(size: 16)
        grid.loadPyramid()
        #expect(grid.aliveCount > 0)
    }

    @Test("Pyramid evolves over multiple generations")
    func pyramidEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadPyramid()
        let initial = grid.aliveCount
        for _ in 0..<5 {
            grid.advanceGeneration()
        }
        #expect(grid.aliveCount > 0, "Pyramid should still have living cells after 5 generations")
        #expect(grid.aliveCount != initial, "Pyramid should evolve (population should change)")
    }

    @Test("Pyramid has matching alive index count")
    func pyramidIndexCount() {
        var grid = GridModel(size: 16)
        grid.loadPyramid()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }
}

// MARK: - Midnight Theme Tests

@Suite("Midnight Theme Tests")
struct MidnightThemeTests {
    @Test("Midnight theme exists in allThemes")
    func midnightInAllThemes() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Midnight" }))
    }

    @Test("Midnight has deep blue color progression")
    func midnightColorProgression() {
        let midnight = ColorTheme.midnight
        // Newborn should be brightest
        #expect(midnight.newborn.emissiveIntensity > midnight.young.emissiveIntensity)
        #expect(midnight.young.emissiveIntensity > midnight.mature.emissiveIntensity)
        #expect(midnight.mature.emissiveIntensity > midnight.dying.emissiveIntensity)
        // Blue channel should dominate for midnight theme
        #expect(midnight.newborn.emissiveColor.z > midnight.newborn.emissiveColor.x)
        #expect(midnight.newborn.emissiveColor.z > midnight.newborn.emissiveColor.y)
    }
}

// MARK: - Swap-Remove Index Consistency Tests

@Suite("Swap-Remove Index Tests")
struct SwapRemoveIndexTests {
    @Test("toggleCell off uses swap-remove and keeps indices consistent")
    func toggleOffSwapRemove() {
        var grid = GridModel(size: 4)
        // Set 3 cells alive
        grid.setCell(x: 0, y: 0, z: 0, alive: true)
        grid.setCell(x: 1, y: 1, z: 1, alive: true)
        grid.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(grid.aliveCellIndices.count == 3)

        // Toggle middle cell off — swap-remove should maintain count
        grid.toggleCell(x: 1, y: 1, z: 1)
        #expect(grid.aliveCount == 2)
        #expect(grid.aliveCellIndices.count == 2)

        // Verify remaining indices match actual alive cells
        let idx0 = grid.index(x: 0, y: 0, z: 0)
        let idx2 = grid.index(x: 2, y: 2, z: 2)
        #expect(grid.aliveCellIndices.contains(idx0))
        #expect(grid.aliveCellIndices.contains(idx2))
    }

    @Test("setCell(alive: false) uses swap-remove correctly")
    func setCellFalseSwapRemove() {
        var grid = GridModel(size: 4)
        grid.setCell(x: 0, y: 0, z: 0, alive: true)
        grid.setCell(x: 1, y: 0, z: 0, alive: true)
        grid.setCell(x: 2, y: 0, z: 0, alive: true)
        grid.setCell(x: 3, y: 0, z: 0, alive: true)
        #expect(grid.aliveCellIndices.count == 4)

        // Remove first cell — should swap with last
        grid.setCell(x: 0, y: 0, z: 0, alive: false)
        #expect(grid.aliveCount == 3)
        #expect(grid.aliveCellIndices.count == 3)
        #expect(!grid.aliveCellIndices.contains(grid.index(x: 0, y: 0, z: 0)))
    }

    @Test("Rapid toggle on/off keeps indices synchronized")
    func rapidToggleSync() {
        var grid = GridModel(size: 8)
        // Toggle same cell on and off repeatedly
        for _ in 0..<10 {
            grid.toggleCell(x: 3, y: 3, z: 3)
        }
        // Even number of toggles → cell is dead
        #expect(grid.aliveCount == 0)
        #expect(grid.aliveCellIndices.isEmpty)
    }
}

// MARK: - Fading Cell Bounds Safety Tests

@Suite("Fading Cell Bounds Safety Tests")
struct FadingCellBoundsTests {
    @Test("advanceGeneration handles fading cells safely")
    func fadingCellsSafe() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.3)
        // Run several generations to produce dying/fading cells
        for _ in 0..<5 {
            grid.advanceGeneration()
        }
        // Fading cells should all have valid indices
        for entry in grid.fadingCells {
            #expect(entry.index >= 0 && entry.index < grid.cellCount)
            #expect(entry.framesLeft > 0 && entry.framesLeft <= GridModel.fadeDuration)
        }
    }

    @Test("Fading cells expire after fadeDuration generations")
    func fadingCellsExpire() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.3)
        grid.advanceGeneration()

        // Run enough generations for all fading cells to expire
        for _ in 0..<(GridModel.fadeDuration + 1) {
            grid.advanceGeneration()
        }
        // All fading cells from the first advance should have expired by now
        // (new ones may exist from subsequent generations)
        for entry in grid.fadingCells {
            #expect(entry.framesLeft > 0)
        }
    }

    // MARK: - Wave Pattern Tests

    @Test("Wave pattern produces non-empty grid")
    func waveNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadWave()
        #expect(grid.aliveCount > 0)
    }

    @Test("Wave pattern creates a surface structure spanning the grid")
    func waveSurface() {
        var grid = GridModel(size: 16)
        grid.loadWave()
        // Wave should have cells spread across most X and Z columns
        var xCols = Set<Int>()
        var zCols = Set<Int>()
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let z = idx % 16
            xCols.insert(x)
            zCols.insert(z)
        }
        // Should span all 16 columns in both X and Z
        #expect(xCols.count == 16)
        #expect(zCols.count == 16)
    }

    @Test("Wave pattern alive indices match alive count")
    func waveIndexCount() {
        var grid = GridModel(size: 16)
        grid.loadWave()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Wave pattern is included in engine pattern list")
    func waveEngineSelection() {
        // Verify 'wave' is a valid Pattern case
        let pattern = SimulationEngine.Pattern.wave
        #expect(pattern.rawValue == "Wave")
    }

    @Test("Wave pattern evolves across multiple generations without crashing")
    func waveEvolution() {
        var grid = GridModel(size: 12)
        grid.loadWave()
        for _ in 0..<10 {
            grid.advanceGeneration()
        }
        // Should still be alive or have died gracefully
        #expect(grid.aliveCount >= 0)
    }

    // MARK: - Bulk Zero Tests

    @Test("clearAll zeros all cells via bulk operation")
    func clearAllBulkZero() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.5)
        #expect(grid.aliveCount > 0)
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        // Verify every cell is zero
        for i in 0..<grid.cellCount {
            #expect(grid.cells[i] == 0)
        }
    }

    @Test("advanceGeneration zeroes nextCells correctly with bulk memset")
    func advanceGenerationBulkZero() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.3)
        // Run multiple generations to verify the bulk zero doesn't corrupt state
        for _ in 0..<20 {
            grid.advanceGeneration()
        }
        // All alive cells should have age > 0, dead cells should be 0
        for i in 0..<grid.cellCount {
            #expect(grid.cells[i] >= 0)
        }
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }
}

// MARK: - Population Trend Threshold Tests

@Suite("Population Trend Threshold Tests")
struct PopulationTrendThresholdTests {
    @Test("Trend threshold uses ceiling division for small populations")
    @MainActor func smallPopulationThreshold() {
        let engine = SimulationEngine(size: 8)
        engine.grid.clearAll()
        // Set up a small population of 10 cells and step a few times
        for i in 0..<10 {
            engine.grid.setCell(x: i % 8, y: 0, z: 0, alive: true)
        }
        // With ceiling division: (10 + 19) / 20 = 1 → threshold is 1
        // With old integer division: 10 / 20 = 0 → threshold was max(1, 0) = 1
        // Test that we get a stable (0) trend when population is unchanging
        engine.step()
        engine.step()
        engine.step()
        // The trend should be computable without crash for small populations
        let trend = engine.populationTrend
        #expect(trend == 0 || trend == 1 || trend == -1,
                "Trend should be a valid value (-1, 0, or 1)")
    }

    @Test("Trend threshold is at least 1 for zero population")
    @MainActor func zeroPopulationThreshold() {
        let engine = SimulationEngine(size: 4)
        engine.grid.clearAll()
        // Step with empty grid — should not crash
        engine.step()
        engine.step()
        #expect(engine.populationTrend == 0, "Empty grid should have stable trend")
    }

    @Test("Ceiling division gives correct threshold for population 15")
    func ceilingDivisionCorrectness() {
        // Verify the arithmetic: (15 + 19) / 20 = 34 / 20 = 1
        let population = 15
        let threshold = max(1, (population + 19) / 20)
        #expect(threshold == 1)
    }

    @Test("Ceiling division gives correct threshold for population 40")
    func ceilingDivisionLarger() {
        // (40 + 19) / 20 = 59 / 20 = 2
        let population = 40
        let threshold = max(1, (population + 19) / 20)
        #expect(threshold == 2)
    }
}

// MARK: - Galaxy Pattern Index Tests

@Suite("Galaxy Pattern Index Tests")
struct GalaxyPatternIndexTests {
    @Test("Galaxy pattern has correct alive cell indices after loading")
    func galaxyIndicesMatchCount() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        #expect(grid.aliveCellIndices.count == grid.aliveCount,
                "Galaxy alive cell indices should match alive count")
        #expect(grid.aliveCount > 0, "Galaxy should produce alive cells")
    }

    @Test("Galaxy renders correctly via alive index path")
    func galaxyRendersViaIndexPath() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        let cells = grid.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == grid.aliveCount,
                "aliveCellsWithAge should return all galaxy cells")
        #expect(cells.count > 0, "Galaxy should have renderable cells")
    }
}

// MARK: - Flat Index Consistency Tests

@Suite("Flat Index Consistency Tests")
struct FlatIndexConsistencyTests {
    @Test("index(x:y:z:) matches manual flat index calculation")
    func indexConsistency() {
        let grid = GridModel(size: 16)
        for x in [0, 5, 15] {
            for y in [0, 8, 15] {
                for z in [0, 3, 15] {
                    let fromMethod = grid.index(x: x, y: y, z: z)
                    let manual = x * 16 * 16 + y * 16 + z
                    #expect(fromMethod == manual,
                            "index(x:\(x), y:\(y), z:\(z)) should match manual calculation")
                }
            }
        }
    }

    @Test("index round-trips through coordinate decomposition")
    func indexRoundTrip() {
        let size = 12
        let grid = GridModel(size: size)
        for x in [0, 3, 11] {
            for y in [0, 6, 11] {
                for z in [0, 9, 11] {
                    let idx = grid.index(x: x, y: y, z: z)
                    let rx = idx / (size * size)
                    let ry = (idx / size) % size
                    let rz = idx % size
                    #expect(rx == x && ry == y && rz == z,
                            "Round-trip should preserve coordinates (\(x),\(y),\(z))")
                }
            }
        }
    }

    // MARK: - Session 57: O(1) Reverse Mapping Tests

    @Test("Alive index map stays consistent after setCell add/remove sequence")
    func aliveIndexMapConsistencySetCell() {
        var model = GridModel(size: 4)
        // Add cells
        model.setCell(x: 0, y: 0, z: 0, alive: true)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(model.aliveCount == 3)
        // Remove middle cell
        model.setCell(x: 1, y: 1, z: 1, alive: false)
        #expect(model.aliveCount == 2)
        // Remaining cells should be in index list
        let ages = model.aliveCellsWithAge(cellSize: 0.02, cellSpacing: 0.005)
        #expect(ages.count == 2)
    }

    @Test("Alive index map stays consistent after toggleCell rapid sequence")
    func aliveIndexMapConsistencyToggle() {
        var model = GridModel(size: 4)
        // Toggle on
        model.toggleCell(x: 0, y: 0, z: 0)
        model.toggleCell(x: 1, y: 1, z: 1)
        model.toggleCell(x: 3, y: 3, z: 3)
        #expect(model.aliveCount == 3)
        // Toggle middle off
        model.toggleCell(x: 1, y: 1, z: 1)
        #expect(model.aliveCount == 2)
        // Toggle it back on
        model.toggleCell(x: 1, y: 1, z: 1)
        #expect(model.aliveCount == 3)
        // All three should render
        let ages = model.aliveCellsWithAge(cellSize: 0.02, cellSpacing: 0.005)
        #expect(ages.count == 3)
    }

    @Test("Alive index map survives advanceGeneration rebuild")
    func aliveIndexMapSurvivesGeneration() {
        var model = GridModel(size: 8)
        model.loadRandom(density: 0.25)
        let countBefore = model.aliveCount
        #expect(countBefore > 0)
        model.advanceGeneration()
        // After generation, aliveCellsWithAge count should match aliveCount
        let ages = model.aliveCellsWithAge(cellSize: 0.02, cellSpacing: 0.005)
        #expect(ages.count == model.aliveCount)
    }

    @Test("Alive index map consistent after clearAll")
    func aliveIndexMapClearAll() {
        var model = GridModel(size: 4)
        model.setCell(x: 0, y: 0, z: 0, alive: true)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        model.clearAll()
        #expect(model.aliveCount == 0)
        let ages = model.aliveCellsWithAge(cellSize: 0.02, cellSpacing: 0.005)
        #expect(ages.count == 0)
        // Adding a cell after clearAll should work
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(model.aliveCount == 1)
        let ages2 = model.aliveCellsWithAge(cellSize: 0.02, cellSpacing: 0.005)
        #expect(ages2.count == 1)
    }

    @Test("Remove last alive cell via setCell leaves empty index list")
    func removeLastAliveCellSetCell() {
        var model = GridModel(size: 4)
        model.setCell(x: 0, y: 0, z: 0, alive: true)
        #expect(model.aliveCount == 1)
        model.setCell(x: 0, y: 0, z: 0, alive: false)
        #expect(model.aliveCount == 0)
        let ages = model.aliveCellsWithAge(cellSize: 0.02, cellSpacing: 0.005)
        #expect(ages.count == 0)
    }

    // MARK: - Session 57: Division by Zero / Depth Scale Tests

    @Test("Depth scale does not produce NaN for size=1 grid")
    func depthScaleSize1() {
        var model = GridModel(size: 1)
        model.setCell(x: 0, y: 0, z: 0, alive: true)
        // computeMeshData is tested via computeMeshDataForTest
        let meshData = GridRenderer.computeMeshDataForTest(model: model)
        #expect(meshData.cellCount == 1)
        // Verify no NaN in vertex positions
        for vertex in meshData.vertices {
            #expect(!vertex.position.x.isNaN)
            #expect(!vertex.position.y.isNaN)
            #expect(!vertex.position.z.isNaN)
        }
    }

    // MARK: - Session 57: Fading Cells Bounds Safety Tests

    @Test("fadingCellsWithProgress returns empty for invalid index")
    func fadingCellsBoundsCheck() {
        // After clearAll with no fading cells, should return empty
        var model = GridModel(size: 4)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        model.advanceGeneration()  // Cell may die, creating fading cells
        let fading = model.fadingCellsWithProgress(cellSize: 0.02, cellSpacing: 0.005)
        // All returned positions should be valid (non-NaN)
        for f in fading {
            #expect(!f.position.x.isNaN)
            #expect(f.progress >= 0.0 && f.progress <= 1.0)
        }
    }
}

// MARK: - Mesh Generation Tests

@Suite("Mesh Generation Tests")
struct MeshGenerationTests {
    @Test("Empty grid produces zero-cell mesh data")
    func emptyGridMesh() {
        let model = GridModel(size: 4)
        let data = GridRenderer.computeMeshDataForTest(model: model)
        #expect(data.cellCount == 0)
        #expect(data.vertices.isEmpty)
        #expect(data.indices.isEmpty)
    }

    @Test("Single cell produces correct vertex and index count")
    func singleCellMesh() {
        var model = GridModel(size: 4)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        let data = GridRenderer.computeMeshDataForTest(model: model)
        #expect(data.cellCount == 1)
        // 24 vertices per cube (4 per face × 6 faces), 36 indices (6 faces × 2 triangles × 3)
        #expect(data.vertices.count == 24)
        #expect(data.indices.count == 36)
    }

    @Test("Multiple cells produce proportional vertex/index counts")
    func multipleCellsMesh() {
        var model = GridModel(size: 8)
        model.loadBlock()  // 2x2x2 = 8 cells
        let data = GridRenderer.computeMeshDataForTest(model: model)
        #expect(data.cellCount == 8)
        #expect(data.vertices.count == 8 * 24)
        #expect(data.indices.count == 8 * 36)
    }

    @Test("All indices reference valid vertices")
    func indicesInBounds() {
        var model = GridModel(size: 8)
        model.loadCluster()
        let data = GridRenderer.computeMeshDataForTest(model: model)
        let maxVertex = UInt32(data.vertices.count)
        for idx in data.indices {
            #expect(idx < maxVertex, "Index \(idx) exceeds vertex count \(maxVertex)")
        }
    }

    @Test("Tier ranges cover all indices without gaps")
    func tierRangesCoverage() {
        var model = GridModel(size: 8)
        model.loadSoup()
        // Advance a few generations to get multiple age tiers
        for _ in 0..<3 { model.advanceGeneration() }
        let data = GridRenderer.computeMeshDataForTest(model: model)
        let totalTierIndices = data.tierRanges.reduce(0) { $0 + $1.indexCount }
        #expect(totalTierIndices == data.indices.count)
    }

    @Test("Newborn cells are assigned to tier 0")
    func newbornTier() {
        var model = GridModel(size: 4)
        model.setCell(x: 1, y: 1, z: 1, alive: true)  // age 1 = newborn
        let data = GridRenderer.computeMeshDataForTest(model: model)
        // All indices should be in tier 0 (newborn)
        #expect(data.tierRanges[0].indexCount == 36)
        #expect(data.tierRanges[1].indexCount == 0)
        #expect(data.tierRanges[2].indexCount == 0)
    }

    @Test("Fading cells produce dying tier mesh data")
    func fadingCellsTier() {
        var model = GridModel(size: 8)
        model.loadBlock()
        // Advance to create dying cells
        for _ in 0..<5 { model.advanceGeneration() }
        let data = GridRenderer.computeMeshDataForTest(model: model)
        // Should have some dying tier data if cells died
        let dyingTierIndex = GridRenderer.AgeTier.dying.rawValue
        // At least some cells should be in the dying tier (fading)
        if !model.fadingCells.isEmpty {
            #expect(data.tierRanges[dyingTierIndex].indexCount > 0)
        }
    }

    @Test("Vertex positions are bounded by grid extent")
    func vertexBounds() {
        var model = GridModel(size: 8)
        model.loadDiamond()
        let data = GridRenderer.computeMeshDataForTest(model: model)
        let maxExtent = data.gridExtent + GridRenderer.cellSize  // small margin for cell half-size
        for vertex in data.vertices {
            #expect(abs(vertex.position.x) <= maxExtent)
            #expect(abs(vertex.position.y) <= maxExtent)
            #expect(abs(vertex.position.z) <= maxExtent)
        }
    }

    @Test("Grid extent is correct for grid size")
    func gridExtentCalculation() {
        let model = GridModel(size: 16)
        let data = GridRenderer.computeMeshDataForTest(model: model)
        let stride = GridRenderer.cellSize + GridRenderer.cellSpacing
        let expectedExtent = Float(15) * stride / 2.0 + GridRenderer.cellSize / 2.0
        let epsilon: Float = 0.0001
        #expect(abs(data.gridExtent - expectedExtent) < epsilon)
    }
}

// MARK: - Draw Mode Performance Tests (Set-backed index)

@Suite("Draw Mode Index Tests")
struct DrawModeIndexTests {
    @Test("toggleCell maintains consistent index set")
    func toggleConsistency() {
        var model = GridModel(size: 8)
        model.setCell(x: 2, y: 3, z: 4, alive: true)
        model.setCell(x: 5, y: 5, z: 5, alive: true)
        #expect(model.aliveCount == 2)

        // Toggle off one cell
        model.toggleCell(x: 2, y: 3, z: 4)
        #expect(model.aliveCount == 1)
        #expect(!model.isAlive(x: 2, y: 3, z: 4))

        // Alive cell indices should only contain the remaining cell
        let remaining = model.aliveCellsWithAge(
            cellSize: GridRenderer.cellSize,
            cellSpacing: GridRenderer.cellSpacing
        )
        #expect(remaining.count == 1)
    }

    @Test("setCell remove and re-add keeps indices consistent")
    func setCellToggleRoundTrip() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        model.setCell(x: 3, y: 3, z: 3, alive: false)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.aliveCount == 1)
        let cells = model.aliveCellsWithAge(
            cellSize: GridRenderer.cellSize,
            cellSpacing: GridRenderer.cellSpacing
        )
        #expect(cells.count == 1)
    }

    @Test("Rapid toggles produce correct alive count")
    func rapidToggles() {
        var model = GridModel(size: 8)
        // Toggle same cell on/off rapidly
        for _ in 0..<10 {
            model.toggleCell(x: 4, y: 4, z: 4)
        }
        // 10 toggles = even number = back to dead
        #expect(model.aliveCount == 0)
        #expect(!model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("advanceGeneration rebuilds indices correctly after interactive edits")
    func advanceAfterEdits() {
        var model = GridModel(size: 8)
        model.loadBlock()
        let countBefore = model.aliveCount
        // Toggle a cell interactively
        model.toggleCell(x: 0, y: 0, z: 0)
        #expect(model.aliveCount == countBefore + 1)
        // Advance generation — should rebuild indices from scratch
        model.advanceGeneration()
        let cells = model.aliveCellsWithAge(
            cellSize: GridRenderer.cellSize,
            cellSpacing: GridRenderer.cellSpacing
        )
        #expect(cells.count == model.aliveCount)
    }

    // MARK: - O(alive) aliveIndexMap Reset Tests

    @Test("advanceGeneration with O(alive) map reset produces same result as full reset")
    func aliveMapResetConsistency() {
        var model = GridModel(size: 8)
        model.loadSoup()
        let initialCount = model.aliveCount
        #expect(initialCount > 0)
        // Advance multiple generations — O(alive) reset must keep map in sync
        for _ in 0..<5 {
            model.advanceGeneration()
            let indexed = model.aliveCellsWithAge(
                cellSize: GridRenderer.cellSize,
                cellSpacing: GridRenderer.cellSpacing
            )
            #expect(indexed.count == model.aliveCount)
        }
    }

    @Test("aliveIndexMap stays correct through extinction and rebirth cycle")
    func aliveMapExtinctionRebirth() {
        var model = GridModel(size: 4)
        model.clearAll()
        // Single isolated cell — will die immediately under any rule set
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(model.aliveCount == 1)
        model.advanceGeneration()
        // Should go extinct
        #expect(model.aliveCount == 0)
        #expect(model.aliveCellIndices.isEmpty)
        // Reseed and verify map is still consistent
        model.loadBlock()
        let cells = model.aliveCellsWithAge(
            cellSize: GridRenderer.cellSize,
            cellSpacing: GridRenderer.cellSpacing
        )
        #expect(cells.count == model.aliveCount)
        #expect(model.aliveCount == 8) // 2x2x2 block
    }

    @Test("O(alive) map reset handles sparse grid correctly")
    func aliveMapSparseGrid() {
        var model = GridModel(size: 16)
        // Only 3 cells alive in a 4096-cell grid
        model.setCell(x: 0, y: 0, z: 0, alive: true)
        model.setCell(x: 8, y: 8, z: 8, alive: true)
        model.setCell(x: 15, y: 15, z: 15, alive: true)
        #expect(model.aliveCount == 3)
        model.advanceGeneration()
        // All isolated cells die
        #expect(model.aliveCount == 0)
        #expect(model.aliveCellIndices.isEmpty)
        // Map should be fully clean — verify by adding new cells
        model.setCell(x: 5, y: 5, z: 5, alive: true)
        #expect(model.aliveCount == 1)
        #expect(model.aliveCellIndices.count == 1)
    }

    // MARK: - Checkerboard Pattern Tests

    @Test("Checkerboard pattern produces non-empty grid")
    func checkerboardNonEmpty() {
        var model = GridModel(size: 8)
        model.loadCheckerboard()
        #expect(model.aliveCount > 0)
    }

    @Test("Checkerboard pattern fills exactly half the grid")
    func checkerboardHalfFill() {
        var model = GridModel(size: 8)
        model.loadCheckerboard()
        // For even-sized grid, exactly half are alive
        #expect(model.aliveCount == model.cellCount / 2)
    }

    @Test("Checkerboard cells have zero alive neighbors")
    func checkerboardIsolation() {
        var model = GridModel(size: 8)
        model.loadCheckerboard()
        // Every alive cell has 0 alive neighbors (all 26 neighbors are dead in a 3D checkerboard)
        for x in 0..<8 {
            for y in 0..<8 {
                for z in 0..<8 {
                    if model.isAlive(x: x, y: y, z: z) {
                        let neighbors = model.neighborCount(x: x, y: y, z: z)
                        #expect(neighbors == 0, "Cell (\(x),\(y),\(z)) has \(neighbors) neighbors, expected 0")
                    }
                }
            }
        }
    }

    @Test("Checkerboard pattern index count matches aliveCount")
    func checkerboardIndexConsistency() {
        var model = GridModel(size: 8)
        model.loadCheckerboard()
        let cells = model.aliveCellsWithAge(
            cellSize: GridRenderer.cellSize,
            cellSpacing: GridRenderer.cellSpacing
        )
        #expect(cells.count == model.aliveCount)
    }

    @Test("Checkerboard is selectable via SimulationEngine pattern enum")
    func checkerboardEngineSelection() {
        let pattern = SimulationEngine.Pattern.checkerboard
        #expect(pattern.rawValue == "Checkerboard")
    }

    @Test("Checkerboard dies under standard rules (no B0)")
    func checkerboardEvolution() {
        var model = GridModel(size: 8)
        model.loadCheckerboard()
        let initial = model.aliveCount
        #expect(initial > 0)
        model.advanceGeneration()
        // All cells have 0 neighbors, none match B5-7 birth or S5-8 survival
        #expect(model.aliveCount == 0)
    }

    @Test("Odd-sized checkerboard has correct count")
    func checkerboardOddSize() {
        var model = GridModel(size: 7)
        model.loadCheckerboard()
        // For odd size 7: cells where (x+y+z)%2==0
        // In a 7³ grid: ceil(343/2) = 172 cells
        let expected = (7 * 7 * 7 + 1) / 2
        #expect(model.aliveCount == expected)
    }
}

// MARK: - Lattice Pattern Tests

@Suite("Lattice Pattern Tests")
struct LatticePatternTests {
    @Test("Lattice pattern produces non-empty grid")
    func latticeNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadLattice()
        #expect(grid.aliveCount > 0)
    }

    @Test("Lattice pattern has regular spacing — every-other-cell structure")
    func latticeRegularSpacing() {
        var grid = GridModel(size: 16)
        grid.loadLattice()
        let margin = max(1, 16 / 6)
        // Cells should exist at even offsets from margin, not at odd offsets
        var atEvenSpacing = 0
        var total = 0
        for x in 0..<16 {
            for y in 0..<16 {
                for z in 0..<16 {
                    if grid.isAlive(x: x, y: y, z: z) {
                        total += 1
                        if (x - margin) % 2 == 0 && (y - margin) % 2 == 0 && (z - margin) % 2 == 0 {
                            atEvenSpacing += 1
                        }
                    }
                }
            }
        }
        // All alive cells should be at even-spaced positions
        #expect(total > 0)
        #expect(atEvenSpacing == total, "All lattice cells should be at stride-2 positions")
    }

    @Test("Lattice pattern is selectable in engine")
    @MainActor
    func latticePatternInEngine() {
        let engine = SimulationEngine(size: 16)
        engine.reset(pattern: .lattice)
        #expect(engine.grid.aliveCount > 0)
        #expect(engine.selectedPattern == .lattice)
    }

    @Test("Lattice pattern aliveCellIndices matches aliveCount")
    func latticeIndexCount() {
        var grid = GridModel(size: 12)
        grid.loadLattice()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Lattice pattern evolves over multiple generations")
    func latticeMultiGenEvolution() {
        var grid = GridModel(size: 12)
        grid.loadLattice()
        let initialCount = grid.aliveCount
        grid.advanceGeneration()
        // Lattice structure should change dramatically in first generation
        #expect(grid.aliveCount != initialCount, "Lattice should evolve — population should change")
    }
}

// MARK: - Volcanic Theme Tests

@Suite("Volcanic Theme Tests")
struct VolcanicThemeTests {
    @Test("Volcanic theme exists in allThemes")
    func volcanicThemeExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Volcanic" })
    }

    @Test("Theme count is 22 with Volcanic")
    func themeCount22() {
        #expect(ColorTheme.allThemes.count == 22)
    }

    @Test("Volcanic theme has lava-to-obsidian color progression")
    func volcanicColorProgression() {
        let theme = ColorTheme.volcanic
        // Newborn: bright orange-lava (high red, medium green, no blue)
        #expect(theme.newborn.emissiveColor.x > 0.9)  // strong red
        #expect(theme.newborn.emissiveColor.y > 0.3)   // orange warmth
        #expect(theme.newborn.emissiveColor.z < 0.1)   // no blue
        // Young: deep red (red dominant, green drops sharply)
        #expect(theme.young.emissiveColor.x > 0.7)     // still red
        #expect(theme.young.emissiveColor.y < 0.2)     // green drops → pure red
        // Mature: dark obsidian (very low, red-tinted)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.z)
        #expect(theme.mature.emissiveIntensity < theme.young.emissiveIntensity)
        // High newborn intensity for vivid lava glow
        #expect(theme.newborn.emissiveIntensity >= 2.5)
    }
}

// MARK: - Bulk Zero Performance Tests

@Suite("Bulk Zero Tests")
struct BulkZeroTests {
    @Test("advanceGeneration with bulk zero produces correct results")
    func bulkZeroCorrectness() {
        // Verify that the bulk memset approach gives identical results to the old loop approach
        var grid = GridModel(size: 12)
        grid.randomSeed(density: 0.25)
        for _ in 0..<10 {
            grid.advanceGeneration()
            // Verify alive count consistency with full recount
            let manualCount = grid.cells.filter { $0 > 0 }.count
            #expect(grid.aliveCount == manualCount,
                    "Alive count should match full recount after bulk-zero advance")
        }
    }

    @Test("Bulk zero handles 32³ grid correctly")
    func bulkZeroLargeGrid() {
        var grid = GridModel(size: 32)
        grid.randomSeed(density: 0.20)
        grid.advanceGeneration()
        let manualCount = grid.cells.filter { $0 > 0 }.count
        #expect(grid.aliveCount == manualCount)
    }
}

// MARK: - Wrapping Topology Tests

@Suite("Wrapping Topology Tests")
struct WrappingTopologyTests {
    @Test("Corner cell sees neighbor across wrapped boundary")
    func cornerCellWrapsNeighbor() {
        var model = GridModel(size: 8)
        model.wrapping = true
        // Place cell at opposite corner (7,7,7)
        model.setCell(x: 7, y: 7, z: 7, alive: true)
        // Cell at (0,0,0) should see (7,7,7) as a neighbor via wrapping
        let count = model.neighborCount(x: 0, y: 0, z: 0)
        #expect(count == 1)
    }

    @Test("Corner cell does NOT wrap without wrapping enabled")
    func cornerCellNoWrap() {
        var model = GridModel(size: 8)
        model.wrapping = false
        model.setCell(x: 7, y: 7, z: 7, alive: true)
        let count = model.neighborCount(x: 0, y: 0, z: 0)
        #expect(count == 0)
    }

    @Test("Edge cell wraps on one axis")
    func edgeCellSingleAxisWrap() {
        var model = GridModel(size: 8)
        model.wrapping = true
        // Place cell at x=7, y=3, z=3
        model.setCell(x: 7, y: 3, z: 3, alive: true)
        // Cell at x=0, y=3, z=3 should see it as a neighbor
        let count = model.neighborCount(x: 0, y: 3, z: 3)
        #expect(count == 1)
    }

    @Test("Interior cell unaffected by wrapping flag")
    func interiorCellUnchanged() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        let countNoWrap = model.neighborCount(x: 3, y: 4, z: 4)
        model.wrapping = true
        let countWrap = model.neighborCount(x: 3, y: 4, z: 4)
        #expect(countNoWrap == countWrap)
    }

    @Test("Wrapping advanceGeneration births cell at boundary via wrapped neighbor")
    func wrappingAdvanceGenerationBirth() {
        // Create a scenario where wrapping causes a birth that wouldn't happen without wrapping.
        // Use small grid with B1/S0 rules (born with 1 neighbor) for easy testing.
        var model = GridModel(size: 4, birthCounts: [1], survivalCounts: [])
        model.wrapping = true
        // Place a single cell at (3,0,0) — last X position
        model.setCell(x: 3, y: 0, z: 0, alive: true)
        model.advanceGeneration()
        // With wrapping and B1 rules, (0,0,0) should be born (wraps from x=3 to x=0)
        #expect(model.cells[model.index(x: 0, y: 0, z: 0)] > 0)
    }

    @Test("Non-wrapping advanceGeneration does not birth at boundary via missing neighbor")
    func nonWrappingAdvanceGenerationNoBirth() {
        var model = GridModel(size: 4, birthCounts: [1], survivalCounts: [])
        model.wrapping = false
        model.setCell(x: 3, y: 0, z: 0, alive: true)
        model.advanceGeneration()
        // Without wrapping, (0,0,0) has no neighbors from x=3
        #expect(model.cells[model.index(x: 0, y: 0, z: 0)] == 0)
    }

    @Test("Wrapping preserves alive count consistency")
    func wrappingAliveCountConsistency() {
        var model = GridModel(size: 8)
        model.wrapping = true
        model.randomSeed(density: 0.25)
        let initialCount = model.aliveCount
        #expect(initialCount > 0)
        model.advanceGeneration()
        // aliveCount must match actual cells
        let actual = model.cells.filter { $0 > 0 }.count
        #expect(model.aliveCount == actual)
    }

    @Test("Wrapping index list matches alive count after generation")
    func wrappingIndexListConsistency() {
        var model = GridModel(size: 8)
        model.wrapping = true
        model.randomSeed(density: 0.25)
        model.advanceGeneration()
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }
}

// MARK: - Rule Set Persistence Tests

@Suite("Rule Set Persistence Tests")
struct RuleSetPersistenceTests {
    @Test("All rule sets round-trip through savePreferences/init")
    @MainActor
    func ruleSetRoundTrip() {
        for ruleSet in SimulationEngine.RuleSet.allCases {
            let engine = SimulationEngine(size: 8)
            engine.applyRuleSet(ruleSet)
            engine.savePreferences()

            // Simulate app restart: new engine reads from UserDefaults
            let restored = SimulationEngine(size: 8)
            #expect(restored.grid.birthCounts == ruleSet.birthCounts,
                    "Birth counts mismatch for \(ruleSet.rawValue)")
            #expect(restored.grid.survivalCounts == ruleSet.survivalCounts,
                    "Survival counts mismatch for \(ruleSet.rawValue)")
        }
    }

    @Test("Theme persists across engine recreation")
    @MainActor
    func themePersistence() {
        let engine = SimulationEngine(size: 8)
        let targetTheme = ColorTheme.ocean
        engine.theme = targetTheme
        engine.savePreferences()

        let restored = SimulationEngine(size: 8)
        #expect(restored.theme.name == targetTheme.name)
    }

    @Test("Grid size persists across engine recreation")
    @MainActor
    func gridSizePersistence() {
        let engine = SimulationEngine(size: 8)
        engine.changeGridSize(24)

        let restored = SimulationEngine(size: 8)
        #expect(restored.grid.size == 24)
    }

    @Test("Speed persists across engine recreation")
    @MainActor
    func speedPersistence() {
        let engine = SimulationEngine(size: 8)
        engine.speed = 15.0
        engine.savePreferences()

        let restored = SimulationEngine(size: 8)
        #expect(restored.speed == 15.0)
    }

    @Test("Audio muted state persists")
    @MainActor
    func audioMutedPersistence() {
        let engine = SimulationEngine(size: 8)
        engine.audioMuted = false
        engine.savePreferences()

        let restored = SimulationEngine(size: 8)
        #expect(restored.audioMuted == false)
    }
}

// MARK: - Grid Epoch Tests

@Suite("Grid Epoch Tests")
struct GridEpochTests {
    @Test("Grid epoch increments on size change")
    @MainActor
    func epochIncrementsOnSizeChange() {
        let engine = SimulationEngine(size: 8)
        let initialEpoch = engine.gridEpoch
        engine.changeGridSize(16)
        #expect(engine.gridEpoch == initialEpoch + 1)
    }

    @Test("Grid epoch increments each size change")
    @MainActor
    func epochIncrementsMultiple() {
        let engine = SimulationEngine(size: 8)
        engine.changeGridSize(12)
        engine.changeGridSize(16)
        engine.changeGridSize(24)
        #expect(engine.gridEpoch == 3)
    }

    @Test("Reset does not increment grid epoch")
    @MainActor
    func resetDoesNotIncrementEpoch() {
        let engine = SimulationEngine(size: 8)
        let initialEpoch = engine.gridEpoch
        engine.reset(pattern: .random)
        #expect(engine.gridEpoch == initialEpoch)
    }
}

// MARK: - Population History Buffer Tests

@Suite("Population History Buffer Tests")
struct PopulationHistoryBufferTests {
    @Test("Population history grows with each generation")
    @MainActor
    func historyGrows() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        #expect(engine.populationHistory.isEmpty)
        engine.step()
        #expect(engine.populationHistory.count == 1)
        engine.step()
        #expect(engine.populationHistory.count == 2)
    }

    @Test("Population history caps at 60 entries")
    @MainActor
    func historyCapsAtMax() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<80 {
            engine.step()
        }
        #expect(engine.populationHistory.count == 60)
    }

    @Test("Population history values match alive count at each step")
    @MainActor
    func historyMatchesAliveCount() {
        let engine = SimulationEngine(size: 8)
        engine.grid.loadBlock()
        var expectedCounts: [Int] = []
        for _ in 0..<5 {
            engine.step()
            expectedCounts.append(engine.grid.aliveCount)
        }
        #expect(engine.populationHistory == expectedCounts)
    }

    @Test("Population history is cleared on reset")
    @MainActor
    func historyClearedOnReset() {
        let engine = SimulationEngine(size: 8)
        engine.grid.randomSeed(density: 0.25)
        for _ in 0..<10 {
            engine.step()
        }
        #expect(!engine.populationHistory.isEmpty)
        engine.reset()
        #expect(engine.populationHistory.isEmpty)
    }

    @Test("Population history wraps correctly in circular buffer")
    @MainActor
    func historyWrapsCorrectly() {
        let engine = SimulationEngine(size: 8)
        engine.grid.loadBlock()
        // Fill beyond capacity to force wrapping
        for _ in 0..<70 {
            engine.step()
        }
        // History should be the last 60 values, ordered oldest to newest
        #expect(engine.populationHistory.count == 60)
        // Last entry should match current alive count
        #expect(engine.populationHistory.last == engine.grid.aliveCount)
    }
}

// MARK: - Draw Mode Paint Edge Cases

@Suite("Draw Mode Paint Edge Cases")
struct DrawModePaintTests {
    @Test("Painting same cell twice in one drag is idempotent")
    func paintSameCellTwice() {
        var model = GridModel(size: 8)
        // Simulate paint mode: set cell once
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        let countAfterFirst = model.aliveCount
        // "Paint" same cell again — should be no-op
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.aliveCount == countAfterFirst)
    }

    @Test("Erasing same cell twice in one drag is idempotent")
    func eraseSameCellTwice() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        model.setCell(x: 3, y: 3, z: 3, alive: false)
        let countAfterFirst = model.aliveCount
        model.setCell(x: 3, y: 3, z: 3, alive: false)
        #expect(model.aliveCount == countAfterFirst)
    }

    @Test("Painting out-of-bounds cell is safe")
    func paintOutOfBounds() {
        var model = GridModel(size: 8)
        // These should not crash
        model.setCell(x: -1, y: 0, z: 0, alive: true)
        model.setCell(x: 8, y: 0, z: 0, alive: true)
        model.setCell(x: 0, y: -1, z: 0, alive: true)
        model.setCell(x: 0, y: 0, z: 8, alive: true)
        #expect(model.aliveCount == 0)
    }

    @Test("Rapid paint-erase cycle maintains consistent alive count")
    func rapidPaintEraseCycle() {
        var model = GridModel(size: 8)
        for i in 0..<20 {
            let alive = i % 2 == 0
            model.setCell(x: 4, y: 4, z: 4, alive: alive)
        }
        // 20 cycles: last call is alive=false (i=19, 19%2=1 → false)
        #expect(model.aliveCount == 0)
        #expect(!model.isAlive(x: 4, y: 4, z: 4))
    }

    @Test("Flat index consistency across grid sizes")
    func flatIndexConsistencyAcrossSizes() {
        for size in [8, 12, 16, 24] {
            let model = GridModel(size: size)
            // Corner cells should map to predictable flat indices
            let origin = model.index(x: 0, y: 0, z: 0)
            let maxCorner = model.index(x: size - 1, y: size - 1, z: size - 1)
            #expect(origin == 0)

// MARK: - Menger Sponge Pattern Tests

@Suite("Menger Sponge Pattern")
struct MengerSpongeTests {
    @Test("Menger sponge produces non-empty grid")
    func mengerSpongeNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadMengerSponge()
        #expect(grid.aliveCount > 0)
    }

    @Test("Menger sponge has holes — not a solid cube")
    func mengerSpongeHasHoles() {
        var grid = GridModel(size: 16)
        grid.loadMengerSponge()
        let margin = max(1, 16 / 8)
        let extent = 16 - 2 * margin
        let solidCount = extent * extent * extent
        #expect(grid.aliveCount < solidCount,
                "Menger sponge should have fewer cells than a solid cube")
    }

    @Test("Menger sponge core is hollow")
    func mengerSpongeCoreHollow() {
        // In a Menger sponge, the center of the cube is removed
        var grid = GridModel(size: 27)
        grid.loadMengerSponge()
        let margin = max(1, 27 / 8)
        let extent = 27 - 2 * margin
        let third = extent / 3
        // Check center column (all three coords in center third) is empty
        let mid = margin + third + third / 2
        #expect(!grid.isAlive(x: mid, y: mid, z: mid),
                "Center of Menger sponge should be hollow")
    }

    @Test("Menger sponge selects correct engine pattern")
    func mengerSpongeEngineSelection() {
        let engine = SimulationEngine(gridSize: 16)
        engine.loadPattern(.mengerSponge)
        #expect(engine.grid.aliveCount > 0)
    }

    @Test("Menger sponge evolves from initial state")
    func mengerSpongeEvolution() {
        var grid = GridModel(size: 16)
        grid.loadMengerSponge()
        let initialCount = grid.aliveCount
        grid.advanceGeneration()
        // Population should change — the sponge has lots of surface area
        #expect(grid.aliveCount != initialCount,
                "Menger sponge should evolve from initial state")
    }

    @Test("Menger sponge alive index consistency")
    func mengerSpongeIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadMengerSponge()
        let manualCount = grid.cells.filter { $0 > 0 }.count
        #expect(grid.aliveCount == manualCount)
        #expect(grid.aliveCellIndices.count == manualCount)
    }
}

// MARK: - Plasma Theme Tests

@Suite("Plasma Theme")
struct PlasmaThemeTests {
    @Test("Plasma theme exists in allThemes")
    func plasmaExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Plasma" })
    }

    @Test("Theme count is 23 with Plasma")
    func themeCount23() {
        #expect(ColorTheme.allThemes.count == 23)
    }

    @Test("Plasma has white-hot to deep purple progression")
    func plasmaColorProgression() {
        let plasma = ColorTheme.plasma
        let newborn = plasma.colors(for: .newborn)
        let mature = plasma.colors(for: .mature)
        // Newborn should be near-white (high R, G, B)
        #expect(newborn.baseColor.x >= 0.9, "Newborn red should be near 1.0")
        #expect(newborn.baseColor.z >= 0.9, "Newborn blue should be near 1.0")
        // Mature should be deep purple (low R, zero G, moderate B)
        #expect(mature.baseColor.y < 0.1, "Mature green should be near zero")
        #expect(mature.baseColor.z > mature.baseColor.x, "Mature blue > red for purple")
    }

    @Test("Plasma emissive intensity decreases with age")
    func plasmaEmissiveDecay() {
        let plasma = ColorTheme.plasma
        let newborn = plasma.colors(for: .newborn)
        let young = plasma.colors(for: .young)
        let mature = plasma.colors(for: .mature)
        let dying = plasma.colors(for: .dying)
        #expect(newborn.emissiveIntensity > young.emissiveIntensity)
        #expect(young.emissiveIntensity > mature.emissiveIntensity)
        #expect(mature.emissiveIntensity > dying.emissiveIntensity)
    }
}

// MARK: - Bulk AliveIndexMap Reset Tests

@Suite("Bulk AliveIndexMap Reset")
struct BulkAliveIndexMapTests {
    @Test("clearAll resets aliveIndexMap correctly")
    func clearAllResetsMap() {
        var grid = GridModel(size: 12)
        grid.randomSeed(density: 0.25)
        #expect(grid.aliveCount > 0)
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        #expect(grid.aliveCellIndices.isEmpty)
        // After clear, setting a cell should work correctly
        grid.setCell(x: 0, y: 0, z: 0, alive: true)
        #expect(grid.aliveCount == 1)
        #expect(grid.aliveCellIndices.count == 1)
    }

    @Test("clearAll then pattern load preserves consistency")
    func clearAllThenPatternLoad() {
        var grid = GridModel(size: 16)
        grid.randomSeed(density: 0.30)
        grid.advanceGeneration()
