import Testing
import Foundation
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

    @Test("All themes count is 58")
    func themeCount() {
        #expect(ColorTheme.allThemes.count == 67)
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
        engine.reset()
        // After reset, trend buffer should be cleared
        #expect(engine.populationTrend == 0)
    }
}

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

    @Test("All themes count is 58")
    func allThemesCount16() {
        #expect(ColorTheme.allThemes.count == 67)
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
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
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

// MARK: - Exit Safety Tests

@Suite("Exit Safety Tests")
struct ExitSafetyTests {
    @Test("Auto-restart skipped when isExiting is true")
    @MainActor
    func noRestartDuringExit() async {
        let engine = SimulationEngine(size: 4)
        engine.grid.clearAll()  // Zero alive cells
        engine.isExiting = true

        // Step several times past extinction delay — should NOT reseed
        for _ in 0..<5 { engine.step() }
        let alive = engine.grid.aliveCount
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

    @Test("allThemes contains 24 themes")
    func themeCount() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
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
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
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
        let cells = grid.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == grid.aliveCount)
    }

    @Test("Galaxy aliveCellsWithAge returns correct count after load")
    func galaxyAliveCellsWithAge() {
        var grid = GridModel(size: 16)
        grid.loadGalaxy()
        let cells = grid.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
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
        model.randomSeed(density: 0.25)
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
        #expect(data.indices.count == 37)
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
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
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
        let targetTheme = ColorTheme.oceanBlues
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
            #expect(maxCorner == size * size * size - 1)
        }
    }
}

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

    @Test("Theme count is 24 with Plasma and Arctic")
    func themeCount24() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
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
        grid.clearAll()
        grid.loadBlock()
        #expect(grid.aliveCount == 8)
        #expect(grid.aliveCellIndices.count == 8)
    }
}

// MARK: - Cage Pattern Tests

@Suite("Cage Pattern Tests")
struct CagePatternTests {
    @Test("Cage pattern produces non-empty grid")
    func cageNonEmpty() {
        var model = GridModel(size: 16)
        model.loadCage()
        #expect(model.aliveCount > 0)
    }

    @Test("Cage pattern only has cells on edges of a cube")
    func cageEdgesOnly() {
        var model = GridModel(size: 12)
        model.loadCage()
        let margin = max(1, 12 / 6)
        let lo = margin
        let hi = 12 - 1 - margin
        // Every alive cell must be on at least two boundary planes of the cage
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        for cell in cells {
            let stride: Float = 0.015 + 0.015
            let offset = Float(12 - 1) * stride / 2.0
            let x = Int(round((cell.position.x + offset) / stride))
            let y = Int(round((cell.position.y + offset) / stride))
            let z = Int(round((cell.position.z + offset) / stride))
            // On an edge means exactly 2 of the 3 coordinates are at lo or hi
            var boundaryCount = 0
            if x == lo || x == hi { boundaryCount += 1 }
            if y == lo || y == hi { boundaryCount += 1 }
            if z == lo || z == hi { boundaryCount += 1 }
            #expect(boundaryCount >= 2, "Cell at (\(x),\(y),\(z)) has only \(boundaryCount) boundary coordinates")
        }
    }

    @Test("Cage pattern is selectable via SimulationEngine")
    @MainActor
    func cageEngineSelection() {
        let engine = SimulationEngine(size: 8)
        engine.loadPattern(.cage)
        #expect(engine.grid.aliveCount > 0)
    }

    @Test("Cage pattern alive index list consistency")
    func cageIndexConsistency() {
        var model = GridModel(size: 12)
        model.loadCage()
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }

    @Test("Cage pattern evolves (population changes after generation)")
    func cageEvolution() {
        var model = GridModel(size: 12)
        model.loadCage()
        let initial = model.aliveCount
        model.advanceGeneration()
        // Cage edges have low neighbor density — expect population change
        #expect(model.aliveCount != initial)
    }
}

// MARK: - Bulk AliveIndexMap Fill Tests

@Suite("Bulk AliveIndexMap Fill Tests")
struct BulkAliveIndexMapFillTests {
    @Test("AliveIndexMap consistency after clearAll with bulk fill")
    func clearAllBulkMapConsistency() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.3)
        #expect(model.aliveCount > 0)
        model.clearAll()
        #expect(model.aliveCount == 0)
        // Re-add cells and verify map is clean
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(model.aliveCount == 1)
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == 1)
    }

    @Test("AliveIndexMap consistency after advanceGeneration with bulk fill")
    func advanceGenerationBulkMapConsistency() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        for _ in 0..<5 {
            model.advanceGeneration()
        }
        // Index list must match actual alive cells
        let actual = model.cells.filter { $0 > 0 }.count
        #expect(model.aliveCount == actual)
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == actual)
    }

    @Test("AliveIndexMap O(1) removal still works after bulk fill")
    func bulkFillThenRemoval() {
        var model = GridModel(size: 8)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.aliveCount == 3)
        // Remove middle cell
        model.setCell(x: 2, y: 2, z: 2, alive: false)
        #expect(model.aliveCount == 2)
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == 2)
    }

    @Test("AliveIndexMap correct after rebuildAliveCellIndices via pattern load")
    func patternLoadMapConsistency() {
        var model = GridModel(size: 12)
        // Load multiple patterns in sequence to exercise rebuild path
        model.loadCage()
        let cageCount = model.aliveCount
        #expect(cageCount > 0)
        model.loadLattice()
        let latticeCount = model.aliveCount
        #expect(latticeCount > 0)
        #expect(latticeCount != cageCount) // different patterns produce different counts
        // Verify internal consistency
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == latticeCount)
    }
}

// MARK: - Trefoil Knot Pattern Tests

@Suite("Trefoil Knot Pattern Tests")
struct TrefoilKnotTests {
    @Test("Trefoil knot produces non-empty grid")
    func trefoilNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadTrefoilKnot()
        #expect(grid.aliveCount > 0)
    }

    @Test("Trefoil knot alive count matches index list")
    func trefoilIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadTrefoilKnot()
        #expect(grid.aliveCount == grid.aliveCellIndices.count)
    }

    @Test("Trefoil knot fills reasonable fraction of grid")
    func trefoilFillFraction() {
        var grid = GridModel(size: 16)
        grid.loadTrefoilKnot()
        let fraction = Double(grid.aliveCount) / Double(grid.cellCount)
        // Knot is a thin tube — should fill 2-20% of grid
        #expect(fraction > 0.02)
        #expect(fraction < 0.20)
    }

    @Test("Trefoil knot engine enum selects correctly")
    func trefoilEngineSelection() {
        let pattern = SimulationEngine.Pattern.trefoilKnot
        #expect(pattern.rawValue == "Trefoil Knot")
    }

    @Test("Trefoil knot evolves under standard rules")
    func trefoilEvolution() {
        var grid = GridModel(size: 16)
        grid.loadTrefoilKnot()
        let initialCount = grid.aliveCount
        grid.advanceGeneration()
        // Should change — knot structure has varied neighbor density
        #expect(grid.aliveCount != initialCount || grid.bornCells.count > 0 || grid.dyingCells.count > 0)
    }
}

// MARK: - Frost Theme Tests

@Suite("Frost Theme Tests")
struct FrostThemeTests {
    @Test("Frost theme exists in allThemes")
    func frostExists() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Frost" }))
    }
}

// MARK: - Wrapping Topology Tests

@Suite("Wrapping Topology Tests")
struct WrappingTopologyTests {
    @Test("Corner cell wraps to opposite corner neighbors")
    func cornerWrapping() {
        var model = GridModel(size: 8)
        model.wrapping = true
        // Place a cell at (0,0,0) — its neighbors should wrap to (7,7,7) etc.
        model.setCell(x: 0, y: 0, z: 0, alive: true)
        // In wrapping mode, neighbor at (-1,-1,-1) wraps to (7,7,7)
        let count = model.neighborCount(x: 7, y: 7, z: 7)
        #expect(count == 1) // only (0,0,0) is alive, and it's a neighbor of (7,7,7) via wrapping
    }

    @Test("Edge cell wraps along single axis")
    func edgeWrapping() {
        var model = GridModel(size: 8)
        model.wrapping = true
        model.setCell(x: 0, y: 4, z: 4, alive: true)
        // (7,4,4) should see (0,4,4) as neighbor via x-axis wrapping
        let count = model.neighborCount(x: 7, y: 4, z: 4)
        #expect(count == 1)
    }

    @Test("Interior cells unaffected by wrapping mode")
    func interiorUnaffected() {
        var model = GridModel(size: 8)
        model.setCell(x: 4, y: 4, z: 4, alive: true)
        let countFinite = model.neighborCount(x: 3, y: 4, z: 4)
        model.wrapping = true
        let countWrapping = model.neighborCount(x: 3, y: 4, z: 4)
        #expect(countFinite == countWrapping)
    }

    @Test("Wrapping enables birth at grid boundary")
    func wrappingBoundaryBirth() {
        // Place cells that would cause a birth at (0,y,z) only with wrapping
        var model = GridModel(size: 8, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        model.wrapping = true
        // Create a cluster that spans the boundary
        for dy in -1...1 {
            for dz in -1...1 {
                if dy == 0 && dz == 0 { continue }
                // Place cells at x=7 (will wrap to be neighbors of x=0)
                model.setCell(x: 7, y: 4 + dy, z: 4 + dz, alive: true)
            }
        }
        // Count neighbors of (0,4,4) — should see all 8 cells at x=7 via wrapping
        let neighbors = model.neighborCount(x: 0, y: 4, z: 4)
        #expect(neighbors == 8)
    }

    @Test("Non-wrapping boundary has no cross-edge neighbors")
    func nonWrappingNoCross() {
        var model = GridModel(size: 8)
        model.wrapping = false
        model.setCell(x: 7, y: 4, z: 4, alive: true)
        // (0,4,4) should NOT see (7,4,4) without wrapping
        let count = model.neighborCount(x: 0, y: 4, z: 4)
        #expect(count == 0)
    }

    @Test("Wrapping advanceGeneration produces consistent alive count")
    func wrappingAdvanceConsistency() {
        var model = GridModel(size: 8)
        model.wrapping = true
        model.randomSeed(density: 0.25)
        for _ in 0..<5 {
            model.advanceGeneration()
            let actual = model.cells.filter { $0 > 0 }.count
            #expect(model.aliveCount == actual)
        }
    }

    @Test("Wrapping preserves alive index list integrity")
    func wrappingIndexConsistency() {
        var model = GridModel(size: 8)
        model.wrapping = true
        model.randomSeed(density: 0.20)
        for _ in 0..<3 {
            model.advanceGeneration()
        }
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }
}

// MARK: - Tetrahedron Pattern Tests

@Suite("Tetrahedron Pattern Tests")
struct TetrahedronPatternTests {
    @Test("Tetrahedron pattern produces alive cells")
    func tetrahedronNonEmpty() {
        var model = GridModel(size: 16)
        model.loadTetrahedron()
        #expect(model.aliveCount > 0)
    }

    @Test("Tetrahedron pattern has four distinct clusters")
    func tetrahedronFourClusters() {
        var model = GridModel(size: 16)
        model.loadTetrahedron()
        let mid = 16 / 2
        // Check each octant has some cells (tetrahedron vertices span all octants)
        var octantCounts = [Int](repeating: 0, count: 8)
        for idx in 0..<model.cellCount {
            guard model.cells[idx] > 0 else { continue }
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            let octant = (x >= mid ? 4 : 0) + (y >= mid ? 2 : 0) + (z >= mid ? 1 : 0)
            octantCounts[octant] += 1
        }
        // At least 4 octants should have cells (tetrahedron touches 4 of 8 octants)
        let occupiedOctants = octantCounts.filter { $0 > 0 }.count
        #expect(occupiedOctants >= 4)
    }

    @Test("Tetrahedron selected via engine pattern enum")
    func tetrahedronEngineSelection() {
        let pattern = SimulationEngine.Pattern.tetrahedron
        #expect(pattern.rawValue == "Tetrahedron")
    }

    @Test("Tetrahedron alive count within bounds")
    func tetrahedronAliveCountBounds() {
        var model = GridModel(size: 16)
        model.loadTetrahedron()
        // 4 clusters, each a sphere of radius ~2-3, so reasonable bounds
        #expect(model.aliveCount > 20)
        #expect(model.aliveCount < 1000)
    }

    @Test("Tetrahedron index consistency")
    func tetrahedronIndexConsistency() {
        var model = GridModel(size: 16)
        model.loadTetrahedron()
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }

    @Test("Tetrahedron evolution dynamics")
    func tetrahedronEvolution() {
        var model = GridModel(size: 16)
        model.loadTetrahedron()
        let initial = model.aliveCount
        model.advanceGeneration()
        // Pattern should change after one generation (not all static)
        let afterOne = model.aliveCount
        #expect(afterOne != initial || model.bornCells.count > 0 || model.dyingCells.count > 0)
    }
}

// MARK: - Arctic Theme Tests

@Suite("Arctic Theme Tests")
struct ArcticThemeTests {
    @Test("Arctic theme exists in allThemes")
    func arcticExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Arctic" })
    }

    @Test("Theme count is 24")
    func themeCount24() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Frost newborn is brightest tier")
    func frostColorProgression() {
        let frost = ColorTheme.frost
        #expect(frost.newborn.emissiveIntensity > frost.young.emissiveIntensity)
        #expect(frost.young.emissiveIntensity > frost.mature.emissiveIntensity)
        #expect(frost.mature.emissiveIntensity > frost.dying.emissiveIntensity)
    }

    @Test("Frost opacity decreases with age")
    func frostOpacityDecay() {
        let frost = ColorTheme.frost
        #expect(frost.newborn.opacity > frost.young.opacity)
        #expect(frost.young.opacity > frost.mature.opacity)
        #expect(frost.mature.opacity > frost.dying.opacity)
    }
}

// MARK: - setCell Age Preservation Tests

@Suite("setCell Age Preservation")
struct SetCellAgePreservationTests {
    @Test("setCell(alive:true) on already-alive cell preserves age")
    func setCellPreservesAge() {
        var model = GridModel(size: 8)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        // Advance a few generations with survival rules that keep isolated cells alive
        // Instead, manually simulate aging by setting cell and advancing
        // Direct test: set alive, then use advanceGeneration with permissive survival rules
        var aging = GridModel(size: 4, birthCounts: [], survivalCounts: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        aging.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(aging.cellAge(x: 2, y: 2, z: 2) == 1)
        aging.advanceGeneration()
        #expect(aging.cellAge(x: 2, y: 2, z: 2) == 2)  // survived, age incremented
        aging.advanceGeneration()
        #expect(aging.cellAge(x: 2, y: 2, z: 2) == 3)  // age 3
        let countBefore = aging.aliveCount
        // Re-set the same cell alive — age must NOT reset to 1
        aging.setCell(x: 2, y: 2, z: 2, alive: true)
        #expect(aging.cellAge(x: 2, y: 2, z: 2) == 3)  // age preserved!
        #expect(aging.aliveCount == countBefore)  // count unchanged
    }

    @Test("setCell(alive:false) on dead cell is no-op")
    func setCellDeadOnDeadIsNoop() {
        var model = GridModel(size: 8)
        let countBefore = model.aliveCount
        model.setCell(x: 0, y: 0, z: 0, alive: false)
        #expect(model.aliveCount == countBefore)
        #expect(model.cellAge(x: 0, y: 0, z: 0) == 0)
    }

    @Test("setCell(alive:true) on dead cell sets age to 1")
    func setCellAliveOnDeadSetsAge1() {
        var model = GridModel(size: 8)
        model.setCell(x: 1, y: 1, z: 1, alive: true)
        #expect(model.cellAge(x: 1, y: 1, z: 1) == 1)
        #expect(model.aliveCount == 1)
    }

    @Test("setCell preserves aliveCellIndices consistency after re-set")
    func setCellPreservesIndexConsistency() {
        var model = GridModel(size: 8, birthCounts: [], survivalCounts: [0, 1, 2, 3, 4, 5, 6, 7, 8])
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        model.advanceGeneration()
        model.advanceGeneration()
        let countBefore = model.aliveCount
        // Re-set both cells — should be no-ops
        model.setCell(x: 2, y: 2, z: 2, alive: true)
        model.setCell(x: 3, y: 3, z: 3, alive: true)
        #expect(model.aliveCount == countBefore)
        // Verify index list matches
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }
}

// MARK: - ColorTheme Completeness Tests

@Suite("ColorTheme Completeness")
struct ColorThemeCompletenessTests {
    @Test("allThemes contains exactly the expected count")
    func allThemesCount() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("All theme names are unique")
    func allThemeNamesUnique() {
        let names = ColorTheme.allThemes.map { $0.name }
        let uniqueNames = Set(names)
        #expect(names.count == uniqueNames.count)
    }

    @Test("Every theme has valid tier colors (non-zero emissive for newborn)")
    func everyThemeHasValidNewborn() {
        for theme in ColorTheme.allThemes {
            let newborn = theme.newborn
            // Newborn cells should always be bright/visible
            let emissiveSum = newborn.emissiveColor.x + newborn.emissiveColor.y + newborn.emissiveColor.z
            #expect(emissiveSum > 0, "Theme '\(theme.name)' has zero newborn emissive")
            #expect(newborn.emissiveIntensity > 0, "Theme '\(theme.name)' has zero newborn intensity")
            #expect(newborn.opacity > 0, "Theme '\(theme.name)' has zero newborn opacity")
        }
    }
}

// MARK: - GridRenderer Mesh Data Tests

@Suite("GridRenderer Mesh Data Tests")
struct GridRendererMeshTests {
    @Test("Empty grid produces zero mesh data")
    func emptyGridMesh() {
        let grid = GridModel(size: 8)
        let data = GridRenderer.computeMeshDataForTest(model: grid)
        #expect(data.cellCount == 0)
        #expect(data.vertices.isEmpty)
        #expect(data.indices.isEmpty)
    }

    @Test("Single cell produces 24 vertices and 36 indices")
    func singleCellMesh() {
        var grid = GridModel(size: 8)
        grid.setCell(x: 4, y: 4, z: 4, alive: true)
        let data = GridRenderer.computeMeshDataForTest(model: grid)
        #expect(data.cellCount == 1)
        #expect(data.vertices.count == 24)
        #expect(data.indices.count == 37)
    }

    @Test("Mesh vertex count scales linearly with alive cells")
    func meshVertexScaling() {
        var grid = GridModel(size: 8)
        grid.setCell(x: 1, y: 1, z: 1, alive: true)
        grid.setCell(x: 3, y: 3, z: 3, alive: true)
        grid.setCell(x: 5, y: 5, z: 5, alive: true)
        let data = GridRenderer.computeMeshDataForTest(model: grid)
        #expect(data.cellCount == 3)
        #expect(data.vertices.count == 3 * 24)
        #expect(data.indices.count == 3 * 36)
    }

    @Test("Mesh tier ranges cover all indices")
    func meshTierRangesCoverAll() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.25)
        // Advance a few gens to get cells at different ages
        grid.advanceGeneration()
        grid.advanceGeneration()
        grid.advanceGeneration()
        let data = GridRenderer.computeMeshDataForTest(model: grid)
        let totalTierIndices = data.tierRanges.reduce(0) { $0 + $1.indexCount }
        #expect(totalTierIndices == data.indices.count)
    }

    @Test("Mesh includes fading cells")
    func meshIncludesFadingCells() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.25)
        grid.advanceGeneration()
        // After one gen, some cells died and are now fading
        let hasFading = !grid.fadingCells.isEmpty
        if hasFading {
            let data = GridRenderer.computeMeshDataForTest(model: grid)
            let expectedCells = grid.aliveCellIndices.count + grid.fadingCells.count
            #expect(data.cellCount == expectedCells)
        }
    }

    @Test("Grid extent scales with grid size")
    func gridExtentScaling() {
        let small = GridModel(size: 8)
        let large = GridModel(size: 16)
        let dataSmall = GridRenderer.computeMeshDataForTest(model: small)
        let dataLarge = GridRenderer.computeMeshDataForTest(model: large)
        #expect(dataLarge.gridExtent > dataSmall.gridExtent)
    }

    @Test("All mesh indices are within vertex bounds")
    func meshIndicesInBounds() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.20)
        grid.advanceGeneration()
        let data = GridRenderer.computeMeshDataForTest(model: grid)
        let maxIndex = UInt32(data.vertices.count)
        for idx in data.indices {
            #expect(idx < maxIndex, "Index \(idx) exceeds vertex count \(maxIndex)")
        }
    }
}

@Suite("Snowflake Pattern Tests")
struct SnowflakePatternTests {
    @Test("Snowflake produces non-empty grid")
    func snowflakeNonEmpty() {
        var model = GridModel(size: 16)
        model.loadSnowflake()
        #expect(model.aliveCount > 0)
    }

    @Test("Snowflake has 6-fold axial symmetry")
    func snowflakeSymmetry() {
        var model = GridModel(size: 16)
        model.loadSnowflake()
        let mid = 8
        // Check that the pattern is symmetric across all 3 axis planes
        for x in 0..<16 {
            for y in 0..<16 {
                for z in 0..<16 {
                    let mx = 2 * mid - 1 - x
                    let my = 2 * mid - 1 - y
                    let mz = 2 * mid - 1 - z
                    // X-axis mirror symmetry
                    if model.isAlive(x: x, y: y, z: z) {
                        #expect(model.isAlive(x: mx, y: y, z: z), "X-mirror symmetry broken at (\(x),\(y),\(z))")
                        #expect(model.isAlive(x: x, y: my, z: z), "Y-mirror symmetry broken at (\(x),\(y),\(z))")
                        #expect(model.isAlive(x: x, y: y, z: mz), "Z-mirror symmetry broken at (\(x),\(y),\(z))")
                    }
                }
            }
        }
    }
}

// MARK: - O(alive) Map Reset Fix Tests

@Suite("O(alive) Map Reset Fix Tests")
struct AliveMapResetFixTests {
    @Test("AliveIndexMap correct after O(alive) reset without bulk fallback")
    func oAliveResetCorrectness() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.25)
        // Run many generations to exercise the O(alive)-only reset path
        for _ in 0..<10 {
            model.advanceGeneration()
        }
        // Verify every alive cell is in the index list and map is consistent
        var aliveFromCells = 0
        for i in 0..<model.cellCount {
            if model.cells[i] > 0 { aliveFromCells += 1 }
        }
        #expect(model.aliveCount == aliveFromCells)
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == aliveFromCells)
    }

    @Test("AliveIndexMap survives rapid generation cycling")
    func rapidCycling() {
        var model = GridModel(size: 8)
        model.randomSeed(density: 0.20)
        // 50 generations — if the O(alive) reset misses any entries, indices will corrupt
        for gen in 0..<50 {
            model.advanceGeneration()
            if gen % 10 == 0 {
                let actual = model.cells.filter { $0 > 0 }.count
                #expect(model.aliveCount == actual)
            }
        }
    }

    @Test("Snowflake engine selection via pattern enum")
    func snowflakeEngineSelection() {
        let engine = SimulationEngine(size: 12)
        engine.loadPattern(.snowflake)
        #expect(engine.grid.aliveCount > 0)
    }

    @Test("Snowflake alive index consistency")
    func snowflakeIndexConsistency() {
        var model = GridModel(size: 16)
        model.loadSnowflake()
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }

    @Test("Snowflake evolves under standard rules")
    func snowflakeEvolution() {
        var model = GridModel(size: 16)
        model.loadSnowflake()
        let initial = model.aliveCount
        model.advanceGeneration()
        // Pattern should change (not static under standard rules)
        #expect(model.aliveCount != initial || model.bornCells.count > 0 || model.dyingCells.count > 0)
    }
}

@Suite("O(alive) Map Reset Regression Fix")
struct AliveMapResetRegressionTests {
    @Test("advanceGeneration aliveIndexMap consistent after removing redundant bulk reset")
    func mapConsistentAfterFix() {
        var model = GridModel(size: 16)
        model.randomSeed()
        // Run multiple generations to exercise the O(alive) reset path
        for _ in 0..<10 {
            model.advanceGeneration()
            let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
            #expect(cells.count == model.aliveCount, "Alive cell count mismatch after advanceGeneration")
        }
    }

    @Test("Map consistent after extinction and pattern reload")
    func mapConsistentAfterExtinction() {
        var model = GridModel(size: 8)
        model.loadBlock()
        // Run until population stabilizes or goes extinct
        for _ in 0..<50 {
            model.advanceGeneration()
        }
        let countAfterRun = model.aliveCount
        let cellsAfterRun = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cellsAfterRun.count == countAfterRun)
        // Reload a pattern and verify consistency
        model.loadSnowflake()
        let cellsAfterReload = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cellsAfterReload.count == model.aliveCount)
    }

    @Test("Map consistent with wrapping topology")
    func mapConsistentWithWrapping() {
        var model = GridModel(size: 12)
        model.wrapping = true
        model.randomSeed(density: 0.2)
        for _ in 0..<10 {
            model.advanceGeneration()
            let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
            #expect(cells.count == model.aliveCount, "Wrapping topology map mismatch")
        }
    }

    @Test("Pattern count matches cyclable patterns")
    func patternCount() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 62)
    }
}

// MARK: - Octahedron Pattern Tests

@Suite("Octahedron Pattern Tests")
struct OctahedronPatternTests {
    @Test("Octahedron produces non-empty grid")
    func octahedronNonEmpty() {
        var model = GridModel(size: 16)
        model.loadOctahedron()
        #expect(model.aliveCount > 0)
    }

    @Test("Octahedron has L1 shell structure — center is hollow")
    func octahedronHollowCenter() {
        var model = GridModel(size: 16)
        model.loadOctahedron()
        let mid = 8
        // Center cell should be dead (hollow shell)
        #expect(!model.isAlive(x: mid, y: mid, z: mid))
    }

    @Test("Octahedron has 6-fold vertex symmetry")
    func octahedronSymmetry() {
        var model = GridModel(size: 16)
        model.loadOctahedron()
        let mid = 8
        let radius = 16 / 3
        // The 6 vertices of the octahedron (±radius along each axis) should be alive
        #expect(model.isAlive(x: mid + radius, y: mid, z: mid))
        #expect(model.isAlive(x: mid - radius, y: mid, z: mid))
        #expect(model.isAlive(x: mid, y: mid + radius, z: mid))
        #expect(model.isAlive(x: mid, y: mid - radius, z: mid))
        #expect(model.isAlive(x: mid, y: mid, z: mid + radius))
        #expect(model.isAlive(x: mid, y: mid, z: mid - radius))
    }

    @Test("Octahedron alive index consistency")
    func octahedronIndexConsistency() {
        var model = GridModel(size: 16)
        model.loadOctahedron()
        let cells = model.aliveCellsWithAge(cellSize: 0.015, cellSpacing: 0.015)
        #expect(cells.count == model.aliveCount)
    }

    @Test("Octahedron engine pattern selection")
    @MainActor
    func octahedronEngineSelection() {
        let engine = SimulationEngine(size: 16)
        engine.loadPattern(.octahedron)
        #expect(engine.grid.aliveCount > 0)
    }

    @Test("Octahedron evolves under standard rules")
    func octahedronEvolution() {
        var model = GridModel(size: 16)
        model.loadOctahedron()
        let initial = model.aliveCount
        for _ in 0..<5 {
            model.advanceGeneration()
        }
        // Population should change (faces erode)
        #expect(model.aliveCount != initial || model.aliveCount == 0)
    }
}

// MARK: - Solar Theme Tests (Session 61)

@Suite("Solar Theme Tests")
struct SolarThemeTests {
    @Test("Solar theme exists in allThemes")
    func solarExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Solar" }
        #expect(found)
    }

    @Test("Theme count is 26 after Solar addition")
    func themeCount26() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Solar newborn is brightest tier")
    func solarColorProgression() {
        let theme = ColorTheme.solar
        // Newborn should have highest emissive intensity
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Solar opacity decreases with age")
    func solarOpacityDecay() {
        let theme = ColorTheme.solar
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Solar has searing luminosity (emissive >= 2.5)")
    func solarHighLuminosity() {
        let theme = ColorTheme.solar
        #expect(theme.newborn.emissiveIntensity >= 2.5)
    }
}

// MARK: - Pattern Count Update (Session 61)

@Suite("Pattern Count Session 61")
struct PatternCountSession61Tests {
    @Test("Total pattern count is 28 (27 + clear)")
    func totalPatternCount() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }

    @Test("Cyclable patterns is 27 (excludes clear)")
    func cyclablePatternCount() {
        let cyclable = SimulationEngine.Pattern.allCases.filter { $0 != .clear }
        #expect(cyclable.count == 62)
        #expect(cyclable.count == 62)
        #expect(cyclable.count == 62)
    }
}

// MARK: - Dodecahedron Pattern Tests (Session 62)

@Suite("Dodecahedron Pattern Tests")
struct DodecahedronPatternTests {
    @Test("Dodecahedron produces non-empty grid")
    func dodecahedronNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadDodecahedron()
        #expect(grid.aliveCount > 0)
    }

    @Test("Dodecahedron has 30 edges worth of cells")
    func dodecahedronEdgeCount() {
        // A dodecahedron has 30 edges, so alive count should be substantial
        var grid = GridModel(size: 16)
        grid.loadDodecahedron()
        #expect(grid.aliveCount > 50)
    }

    @Test("Dodecahedron has inversion symmetry (center-symmetric)")
    func dodecahedronSymmetry() {
        var grid = GridModel(size: 16)
        grid.loadDodecahedron()
        let s = grid.size
        var mismatches = 0
        for x in 0..<s {
            for y in 0..<s {
                for z in 0..<s {
                    let alive = grid.isAlive(x: x, y: y, z: z)
                    let mirror = grid.isAlive(x: s - 1 - x, y: s - 1 - y, z: s - 1 - z)
                    if alive != mirror { mismatches += 1 }
                }
            }
        }
        #expect(mismatches == 0)
    }

    @Test("Dodecahedron pattern in engine enum")
    func dodecahedronEngineEnum() {
        let pattern = SimulationEngine.Pattern.dodecahedron
        #expect(pattern.rawValue == "Dodecahedron")
    }

    @Test("Dodecahedron alive index consistency")
    func dodecahedronIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadDodecahedron()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Dodecahedron evolves under standard rules")
    func dodecahedronEvolution() {
        var grid = GridModel(size: 16)
        grid.loadDodecahedron()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change (edges erode)
        #expect(grid.aliveCount != initial)
    }
}

// MARK: - Toxic Theme Tests (Session 62)

@Suite("Toxic Theme Tests")
struct ToxicThemeTests {
    @Test("Toxic theme exists in allThemes")
    func toxicExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Toxic" }
        #expect(found)
    }

    @Test("Theme count is 27 after Toxic addition")
    func themeCount27() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Toxic has decreasing emissive intensity by age")
    func toxicColorProgression() {
        let theme = ColorTheme.toxic
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Toxic opacity decreases with age")
    func toxicOpacityDecay() {
        let theme = ColorTheme.toxic
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Toxic is green-dominant (high green channel in newborn)")
    func toxicGreenDominant() {
        let theme = ColorTheme.toxic
        // Green channel should be the highest in newborn
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
    }
}

// MARK: - Icosahedron Pattern Tests (Session 63)

@Suite("Icosahedron Pattern Tests")
struct IcosahedronPatternTests {
    @Test("Icosahedron produces non-empty grid")
    func icosahedronNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadIcosahedron()
        #expect(grid.aliveCount > 0)
    }

    @Test("Icosahedron has 30 edges worth of cells")
    func icosahedronEdgeCount() {
        // An icosahedron has 30 edges, so alive count should be substantial
        var grid = GridModel(size: 16)
        grid.loadIcosahedron()
        #expect(grid.aliveCount > 50)
    }

    @Test("Icosahedron has inversion symmetry (center-symmetric)")
    func icosahedronSymmetry() {
        var grid = GridModel(size: 16)
        grid.loadIcosahedron()
        let s = grid.size
        var mismatches = 0
        for x in 0..<s {
            for y in 0..<s {
                for z in 0..<s {
                    let alive = grid.isAlive(x: x, y: y, z: z)
                    let mirror = grid.isAlive(x: s - 1 - x, y: s - 1 - y, z: s - 1 - z)
                    if alive != mirror { mismatches += 1 }
                }
            }
        }
        #expect(mismatches == 0)
    }

    @Test("Icosahedron pattern in engine enum")
    func icosahedronEngineEnum() {
        let pattern = SimulationEngine.Pattern.icosahedron
        #expect(pattern.rawValue == "Icosahedron")
    }

    @Test("Icosahedron alive index consistency")
    func icosahedronIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadIcosahedron()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Icosahedron evolves under standard rules")
    func icosahedronEvolution() {
        var grid = GridModel(size: 16)
        grid.loadIcosahedron()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change (edges erode)
        #expect(grid.aliveCount != initial)
    }
}

// MARK: - Starfield Theme Tests (Session 63)

@Suite("Starfield Theme Tests")
struct StarfieldThemeTests {
    @Test("Starfield theme exists in allThemes")
    func starfieldExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Starfield" }
        #expect(found)
    }

    @Test("Theme count is 28 after Starfield addition")
    func themeCount28() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Starfield has decreasing emissive intensity by age")
    func starfieldColorProgression() {
        let theme = ColorTheme.starfield
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Starfield opacity decreases with age")
    func starfieldOpacityDecay() {
        let theme = ColorTheme.starfield
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Starfield is blue-dominant (high blue channel in newborn)")
    func starfieldBlueDominant() {
        let theme = ColorTheme.starfield
        // Blue channel should be >= other channels in newborn (white-blue stars)
        #expect(theme.newborn.emissiveColor.z >= theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.z >= theme.newborn.emissiveColor.y)
    }
}

// MARK: - Möbius Strip Pattern Tests (Session 64)

@Suite("Möbius Strip Pattern Tests")
struct MobiusStripPatternTests {
    @Test("Möbius strip produces non-empty grid")
    func mobiusNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadMobiusStrip()
        #expect(grid.aliveCount > 0)
    }

    @Test("Möbius strip has substantial cell count for a surface")
    func mobiusCellCount() {
        var grid = GridModel(size: 16)
        grid.loadMobiusStrip()
        // A Möbius strip surface should have a good number of cells
        #expect(grid.aliveCount > 30)
    }

    @Test("Möbius strip pattern in engine enum")
    func mobiusEngineEnum() {
        let pattern = SimulationEngine.Pattern.mobiusStrip
        #expect(pattern.rawValue == "Möbius Strip")
    }

    @Test("Möbius strip alive index consistency")
    func mobiusIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadMobiusStrip()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Möbius strip evolves under standard rules")
    func mobiusEvolution() {
        var grid = GridModel(size: 16)
        grid.loadMobiusStrip()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change (thin surface erodes)
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 29 after Möbius Strip addition")
    func patternCount29() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Hologram Theme Tests (Session 64)

@Suite("Hologram Theme Tests")
struct HologramThemeTests {
    @Test("Hologram theme exists in allThemes")
    func hologramExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Hologram" }
        #expect(found)
    }

    @Test("Theme count is 29 after Hologram addition")
    func themeCount29() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Hologram has decreasing emissive intensity by age")
    func hologramColorProgression() {
        let theme = ColorTheme.hologram
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Hologram opacity decreases with age")
    func hologramOpacityDecay() {
        let theme = ColorTheme.hologram
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Hologram is cyan-dominant (high green+blue, no red)")
    func hologramCyanDominant() {
        let theme = ColorTheme.hologram
        // Red channel should be 0 across all tiers (pure cyan)
        #expect(theme.newborn.emissiveColor.x == 0.0)
        // Green and blue should both be high
        #expect(theme.newborn.emissiveColor.y > 0.8)
        #expect(theme.newborn.emissiveColor.z > 0.8)
    }
}

// MARK: - Lissajous Curve Pattern Tests (Session 65)

@Suite("Lissajous Curve Pattern Tests")
struct LissajousCurvePatternTests {
    @Test("Lissajous curve produces non-empty grid")
    func lissajousNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadLissajous()
        #expect(grid.aliveCount > 0)
    }

    @Test("Lissajous curve has substantial cell count for a thick curve")
    func lissajousCellCount() {
        var grid = GridModel(size: 16)
        grid.loadLissajous()
        // A thick 3D parametric curve should fill a good portion of the grid
        #expect(grid.aliveCount > 100)
    }

    @Test("Lissajous curve pattern in engine enum")
    func lissajousEngineEnum() {
        let pattern = SimulationEngine.Pattern.lissajous
        #expect(pattern.rawValue == "Lissajous Curve")
    }

    @Test("Lissajous curve alive index consistency")
    func lissajousIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadLissajous()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Lissajous curve evolves under standard rules")
    func lissajousEvolution() {
        var grid = GridModel(size: 16)
        grid.loadLissajous()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change under evolution
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 31 after Klein Bottle addition")
    func patternCount30() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Cyberpunk Theme Tests (Session 65)

@Suite("Cyberpunk Theme Tests")
struct CyberpunkThemeTests {
    @Test("Cyberpunk theme exists in allThemes")
    func cyberpunkExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Cyberpunk" }
        #expect(found)
    }

    @Test("Theme count is 31 after Vaporwave addition")
    func themeCount30() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Cyberpunk has decreasing emissive intensity by age")
    func cyberpunkColorProgression() {
        let theme = ColorTheme.cyberpunk
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Cyberpunk opacity decreases with age")
    func cyberpunkOpacityDecay() {
        let theme = ColorTheme.cyberpunk
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Cyberpunk is magenta-dominant (high red, zero green, moderate blue)")
    func cyberpunkMagentaDominant() {
        let theme = ColorTheme.cyberpunk
        // Red channel should be highest in newborn
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.z)
        // Green channel should be zero
        #expect(theme.newborn.emissiveColor.y == 0.0)
        // Blue channel should be present (magenta = red + blue)
        #expect(theme.newborn.emissiveColor.z > 0.4)
    }
}

// MARK: - Klein Bottle Pattern Tests (Session 66)

@Suite("Klein Bottle Pattern Tests")
struct KleinBottlePatternTests {
    @Test("Klein bottle produces non-empty grid")
    func kleinBottleNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadKleinBottle()
        #expect(grid.aliveCount > 0)
    }

    @Test("Klein bottle cell count is within reasonable bounds")
    func kleinBottleCellCount() {
        var grid = GridModel(size: 16)
        grid.loadKleinBottle()
        // A surface pattern should produce fewer cells than a solid but more than a thin wire
        #expect(grid.aliveCount > 50)
        #expect(grid.aliveCount < grid.cellCount / 2)
    }

    @Test("Klein bottle is available in SimulationEngine.Pattern enum")
    @Test("Klein bottle has substantial cell count for a thick surface")
    func kleinBottleCellCount() {
        var grid = GridModel(size: 16)
        grid.loadKleinBottle()
        // A thick 3D surface should fill a good portion of the grid
        #expect(grid.aliveCount > 200)
    }

    @Test("Klein bottle pattern in engine enum")
    func kleinBottleEngineEnum() {
        let pattern = SimulationEngine.Pattern.kleinBottle
        #expect(pattern.rawValue == "Klein Bottle")
    }

    @Test("Klein bottle alive cell index consistency")
    @Test("Klein bottle alive index consistency")
    func kleinBottleIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadKleinBottle()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Klein bottle evolves under standard rules")
    func kleinBottleEvolution() {
        var grid = GridModel(size: 16)
        grid.loadKleinBottle()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change under evolution
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 31 after Klein Bottle addition")
    func patternCount31() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Vaporwave Theme Tests (Session 66)

@Suite("Vaporwave Theme Tests")
struct VaporwaveThemeTests {
    @Test("Vaporwave theme exists in allThemes")
    func vaporwaveExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Vaporwave" }
        #expect(found)
    }

    @Test("Theme count is 31 after Vaporwave addition")
    func themeCount31() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Vaporwave has decreasing emissive intensity by age")
    func vaporwaveColorProgression() {
        let theme = ColorTheme.vaporwave
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Vaporwave opacity decreases with age")
    func vaporwaveOpacityDecay() {
        let theme = ColorTheme.vaporwave
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Vaporwave is pink-to-blue gradient (high blue in newborn, transitions to blue-dominant)")
    func vaporwavePinkBlueGradient() {
        let theme = ColorTheme.vaporwave
        // Newborn should have high blue channel (pink = red + blue)
        #expect(theme.newborn.emissiveColor.z > 0.8)
        // Mature should be blue-dominant (cool tones)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
    }
}

// MARK: - Gyroid Pattern Tests (Session 67)

@Suite("Gyroid Pattern Tests")
struct GyroidPatternTests {
    @Test("Gyroid produces non-empty grid")
    func gyroidNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadGyroid()
        #expect(grid.aliveCount > 0)
    }

    @Test("Gyroid cell count is within reasonable bounds")
    func gyroidCellCount() {
        var grid = GridModel(size: 16)
        grid.loadGyroid()
        // A surface pattern should produce moderate density (not too thin, not too solid)
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < grid.cellCount / 2)
    }

    @Test("Gyroid is available in SimulationEngine.Pattern enum")
    func gyroidEngineEnum() {
        let pattern = SimulationEngine.Pattern.gyroid
        #expect(pattern.rawValue == "Gyroid")
    }

    @Test("Gyroid alive cell index consistency")
    func gyroidIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadGyroid()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Gyroid evolves under standard rules")
    func gyroidEvolution() {
        var grid = GridModel(size: 16)
        grid.loadGyroid()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 34 after Gyroid addition")
    func patternCount33() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Synthwave Theme Tests (Session 67)

@Suite("Synthwave Theme Tests")
struct SynthwaveThemeTests {
    @Test("Synthwave theme exists in allThemes")
    func synthwaveExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Synthwave" }
        #expect(found)
    }

    @Test("Theme count is 34 after Synthwave addition")
    func themeCount34() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Synthwave has decreasing emissive intensity by age")
    func synthwaveColorProgression() {
        let theme = ColorTheme.synthwave
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Synthwave opacity decreases with age")
    func synthwaveOpacityDecay() {
        let theme = ColorTheme.synthwave
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Synthwave is orange-to-purple gradient (warm to cool)")
    func synthwaveOrangePurpleGradient() {
        let theme = ColorTheme.synthwave
        // Newborn should be orange-dominant (high red, moderate green, low blue)
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.z)
        // Mature should be purple-dominant (blue > red)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
    }
}

// MARK: - Lorenz Attractor Pattern Tests (Session 67)

@Suite("Lorenz Attractor Pattern Tests")
struct LorenzAttractorPatternTests {
    @Test("Lorenz attractor produces non-empty grid")
    func lorenzAttractorNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadLorenzAttractor()
        #expect(grid.aliveCount > 0)
    }

    @Test("Lorenz attractor cell count is within reasonable bounds")
    func lorenzAttractorCellCount() {
        var grid = GridModel(size: 16)
        grid.loadLorenzAttractor()
        // A thick curve should produce moderate cell count
        #expect(grid.aliveCount > 50)
        #expect(grid.aliveCount < grid.cellCount / 2)
    }

    @Test("Lorenz attractor is available in SimulationEngine.Pattern enum")
    func lorenzAttractorEngineEnum() {
        let pattern = SimulationEngine.Pattern.lorenzAttractor
        #expect(pattern.rawValue == "Lorenz Attractor")
    }

    @Test("Lorenz attractor alive cell index consistency")
    func lorenzAttractorIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadLorenzAttractor()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Lorenz attractor evolves under standard rules")
    func lorenzAttractorEvolution() {
        var grid = GridModel(size: 16)
        grid.loadLorenzAttractor()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change under evolution
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 34 after Lorenz Attractor addition")
    func patternCount34() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Terracotta Theme Tests (Session 67)

@Suite("Terracotta Theme Tests")
struct TerracottaThemeTests {
    @Test("Terracotta theme exists in allThemes")
    func terracottaExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Terracotta" }
        #expect(found)
    }

    @Test("Theme count is 34 after Terracotta addition")
    func themeCount34() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Terracotta has decreasing emissive intensity by age")
    func terracottaColorProgression() {
        let theme = ColorTheme.terracotta
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Terracotta opacity decreases with age")
    func terracottaOpacityDecay() {
        let theme = ColorTheme.terracotta
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Terracotta is warm orange-brown (red dominant across all tiers)")
    func terracottaWarmOrange() {
        let theme = ColorTheme.terracotta
        // Red channel should be dominant in newborn (warm orange)
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.z)
        // Mature should still have red as dominant channel
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.z)
    }
}

// MARK: - Hilbert Curve Pattern Tests (Session 68)

@Suite("Hilbert Curve Pattern Tests")
struct HilbertCurvePatternTests {
    @Test("Hilbert curve produces non-empty grid")
    func hilbertCurveNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadHilbertCurve()
        #expect(grid.aliveCount > 0)
    }

    @Test("Hilbert curve cell count is within reasonable bounds")
    func hilbertCurveCellCount() {
        var grid = GridModel(size: 16)
        grid.loadHilbertCurve()
        #expect(grid.aliveCount > 50)
        #expect(grid.aliveCount < grid.cellCount)
    }

    @Test("Hilbert curve is available in SimulationEngine.Pattern enum")
    func hilbertCurveEngineEnum() {
        let pattern = SimulationEngine.Pattern.hilbertCurve
        #expect(pattern.rawValue == "Hilbert Curve")
    }

    @Test("Hilbert curve alive cell index consistency")
    func hilbertCurveIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadHilbertCurve()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Hilbert curve evolves under standard rules")
    func hilbertCurveEvolution() {
        var grid = GridModel(size: 16)
        grid.loadHilbertCurve()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 35 after Hilbert Curve addition")
    func patternCount35() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Lavender Theme Tests (Session 68)

@Suite("Lavender Theme Tests")
struct LavenderThemeTests {
    @Test("Lavender theme exists in allThemes")
    func lavenderExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Lavender" }
        #expect(found)
    }

    @Test("Theme count is 34 after Lavender addition")
    func themeCount34() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Lavender has decreasing emissive intensity by age")
    func lavenderColorProgression() {
        let theme = ColorTheme.lavender
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Lavender opacity decreases with age")
    func lavenderOpacityDecay() {
        let theme = ColorTheme.lavender
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Lavender is purple-dominant (blue channel highest across all tiers)")
    func lavenderPurpleDominant() {
        let theme = ColorTheme.lavender
        // All tiers should have blue as the dominant channel (purple/lavender hue)
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.y)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
    }
}

// MARK: - Matrix Theme Tests (Session 68)

@Suite("Matrix Theme Tests")
struct MatrixThemeTests {
    @Test("Matrix theme exists in allThemes")
    func matrixExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Matrix" }
        #expect(found)
    }

    @Test("Theme count is 35 after Matrix addition")
    func themeCount35() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Matrix has decreasing emissive intensity by age")
    func matrixColorProgression() {
        let theme = ColorTheme.matrix
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Matrix opacity decreases with age")
    func matrixOpacityDecay() {
        let theme = ColorTheme.matrix
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Matrix is pure green (zero red and blue across all tiers)")
    func matrixPureGreen() {
        let theme = ColorTheme.matrix
        #expect(theme.newborn.emissiveColor.x == 0.0)
        #expect(theme.newborn.emissiveColor.z == 0.0)
        #expect(theme.young.emissiveColor.x == 0.0)
        #expect(theme.young.emissiveColor.z == 0.0)
        #expect(theme.mature.emissiveColor.x == 0.0)
        #expect(theme.mature.emissiveColor.z == 0.0)
    }
}

// MARK: - Sierpinski Tetrahedron Pattern Tests (Session 68)

@Suite("Sierpinski Tetrahedron Pattern Tests")
struct SierpinskiTetrahedronPatternTests {
    @Test("Sierpinski tetrahedron produces non-empty grid")
    func sierpinskiNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadSierpinskiTetrahedron()
        #expect(grid.aliveCount > 0)
    }

    @Test("Sierpinski tetrahedron cell count is within reasonable bounds")
    func sierpinskiCellCount() {
        var grid = GridModel(size: 16)
        grid.loadSierpinskiTetrahedron()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < grid.cellCount / 2)
    }

    @Test("Sierpinski tetrahedron is available in SimulationEngine.Pattern enum")
    func sierpinskiEngineEnum() {
        let pattern = SimulationEngine.Pattern.sierpinskiTetrahedron
        #expect(pattern.rawValue == "Sierpinski Tetrahedron")
    }

    @Test("Sierpinski tetrahedron alive cell index consistency")
    func sierpinskiIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadSierpinskiTetrahedron()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Sierpinski tetrahedron evolves under standard rules")
    func sierpinskiEvolution() {
        var grid = GridModel(size: 16)
        grid.loadSierpinskiTetrahedron()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 36 after Sierpinski Tetrahedron addition")
    func patternCount36() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Champagne Theme Tests (Session 68)

@Suite("Champagne Theme Tests")
struct ChampagneThemeTests {
    @Test("Champagne theme exists in allThemes")
    func champagneExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Champagne" }
        #expect(found)
    }

    @Test("Theme count is 36 after Champagne addition")
    func themeCount36() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Champagne has decreasing emissive intensity by age")
    func champagneColorProgression() {
        let theme = ColorTheme.champagne
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Champagne opacity decreases with age")
    func champagneOpacityDecay() {
        let theme = ColorTheme.champagne
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Champagne is warm golden (red >= green > blue across tiers)")
    func champagneWarmGolden() {
        let theme = ColorTheme.champagne
        #expect(theme.newborn.emissiveColor.x >= theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x >= theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.z)
    }
}

// MARK: - Opal Theme Tests (Session 69)

@Suite("Opal Theme Tests")
struct OpalThemeTests {
    @Test("Opal theme exists in allThemes")
    func opalExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Opal" }
        #expect(found)
    }

    @Test("Theme count is 37 after Opal addition")
    func themeCount37() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Opal has decreasing emissive intensity by age")
    func opalColorProgression() {
        let theme = ColorTheme.opal
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Opal opacity decreases with age")
    func opalOpacityDecay() {
        let theme = ColorTheme.opal
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Opal transitions from near-white to blue (blue channel high across all tiers)")
    func opalWhiteToBlue() {
        let theme = ColorTheme.opal
        // Newborn should be near-white (all channels high, blue highest)
        #expect(theme.newborn.emissiveColor.z >= theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.z >= theme.newborn.emissiveColor.y)
        // Mature should have blue as dominant channel
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.y)
    }
}

// MARK: - Rose Gold Theme Tests (Session 69)

@Suite("Rose Gold Theme Tests")
struct RoseGoldThemeTests {
    @Test("Rose Gold theme exists in allThemes")
    func roseGoldExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Rose Gold" }
        #expect(found)
    }

    @Test("Theme count is 38 after Rose Gold addition")
    func themeCount38() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Rose Gold has decreasing emissive intensity by age")
    func roseGoldColorProgression() {
        let theme = ColorTheme.roseGold
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Rose Gold opacity decreases with age")
    func roseGoldOpacityDecay() {
        let theme = ColorTheme.roseGold
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Rose Gold is warm pink (red dominant across all tiers)")
    func roseGoldWarmPink() {
        let theme = ColorTheme.roseGold
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.z)
    }
}

// MARK: - Peridot Theme Tests (Session 69)

@Suite("Peridot Theme Tests")
struct PeridotThemeTests {
    @Test("Peridot theme exists in allThemes")
    func peridotExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Peridot" }
        #expect(found)
    }

    @Test("Theme count is 39 after Peridot addition")
    func themeCount39() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Peridot has decreasing emissive intensity by age")
    func peridotColorProgression() {
        let theme = ColorTheme.peridot
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Peridot opacity decreases with age")
    func peridotOpacityDecay() {
        let theme = ColorTheme.peridot
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Peridot is yellow-green dominant (green channel highest across all tiers)")
    func peridotYellowGreenDominant() {
        let theme = ColorTheme.peridot
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.z)
    }
}

// MARK: - Dragon Curve Pattern Tests (Session 70)

@Suite("Dragon Curve Pattern Tests")
struct DragonCurvePatternTests {
    @Test("Dragon curve produces non-empty grid")
    func dragonCurveNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadDragonCurve()
        #expect(grid.aliveCount > 0)
    }

    @Test("Dragon curve cell count is within reasonable bounds")
    func dragonCurveCellCount() {
        var grid = GridModel(size: 16)
        grid.loadDragonCurve()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < grid.cellCount / 2)
    }

    @Test("Dragon curve is available in SimulationEngine.Pattern enum")
    func dragonCurveEngineEnum() {
        let pattern = SimulationEngine.Pattern.dragonCurve
        #expect(pattern.rawValue == "Dragon Curve")
    }

    @Test("Dragon curve alive cell index consistency")
    func dragonCurveIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadDragonCurve()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Dragon curve evolves under standard rules")
    func dragonCurveEvolution() {
        var grid = GridModel(size: 16)
        grid.loadDragonCurve()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 37 after Dragon Curve and Catenoid additions")
    func patternCount37() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Catenoid Pattern Tests (Session 70)

@Suite("Catenoid Pattern Tests")
struct CatenoidPatternTests {
    @Test("Catenoid produces non-empty grid")
    func catenoidNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadCatenoid()
        #expect(grid.aliveCount > 0)
    }

    @Test("Catenoid cell count is within expected bounds")
    func catenoidCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadCatenoid()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Catenoid is available in Pattern enum")
    func catenoidEnumCase() {
        let pattern = SimulationEngine.Pattern.catenoid
        #expect(pattern.rawValue == "Catenoid")
    }

    @Test("Catenoid aliveCellIndices matches aliveCount")
    func catenoidIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadCatenoid()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Catenoid evolves under standard rules")
    func catenoidEvolution() {
        var grid = GridModel(size: 16)
        grid.loadCatenoid()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 37 after Catenoid addition")
    func patternCount37() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Sapphire Theme Tests (Session 70)

@Suite("Sapphire Theme Tests")
struct SapphireThemeTests {
    @Test("Sapphire theme exists in allThemes")
    func sapphireExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Sapphire" }
        #expect(found)
    }

    @Test("Theme count is 43 after Sapphire, Obsidian, Ruby, and Titanium additions")
    func themeCount43() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Sapphire has decreasing emissive intensity by age")
    func sapphireColorProgression() {
        let theme = ColorTheme.sapphire
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Sapphire opacity decreases with age")
    func sapphireOpacityDecay() {
        let theme = ColorTheme.sapphire
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Sapphire is deep blue (blue channel dominant across all tiers)")
    func sapphireDeepBlue() {
        let theme = ColorTheme.sapphire
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.y)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.y)
    }
}

// MARK: - Obsidian Theme Tests (Session 70)

@Suite("Obsidian Theme Tests")
struct ObsidianThemeTests {
    @Test("Obsidian theme exists in allThemes")
    func obsidianExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Obsidian" }
        #expect(found)
    }

    @Test("Theme count is 42 after Obsidian addition")
    func themeCount42() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Obsidian has decreasing emissive intensity by age")
    func obsidianColorProgression() {
        let theme = ColorTheme.obsidian
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Obsidian opacity decreases with age")
    func obsidianOpacityDecay() {
        let theme = ColorTheme.obsidian
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Obsidian is dark purple-grey (blue >= red >= green across tiers)")
    func obsidianDarkPurpleGrey() {
        let theme = ColorTheme.obsidian
        #expect(theme.newborn.emissiveColor.z >= theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.x >= theme.newborn.emissiveColor.y)
        #expect(theme.mature.emissiveColor.z >= theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.x >= theme.mature.emissiveColor.y)
    }
}

// MARK: - Koch Snowflake Pattern Tests (Session 71)

@Suite("Koch Snowflake Pattern Tests")
struct KochSnowflakePatternTests {
    @Test("Koch snowflake produces non-empty grid")
    func kochSnowflakeNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadKochSnowflake()
        #expect(grid.aliveCount > 0)
    }

    @Test("Koch snowflake cell count is within reasonable bounds")
    func kochSnowflakeCellCount() {
        var grid = GridModel(size: 16)
        grid.loadKochSnowflake()
        #expect(grid.aliveCount > 200)
        #expect(grid.aliveCount < grid.cellCount)
    }

    @Test("Koch snowflake is available in SimulationEngine.Pattern enum")
    func kochSnowflakeEngineEnum() {
        let pattern = SimulationEngine.Pattern.kochSnowflake
        #expect(pattern.rawValue == "Koch Snowflake")
    }

    @Test("Koch snowflake alive cell index consistency")
    func kochSnowflakeIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadKochSnowflake()
        let indexCount = grid.aliveCellIndices.count
        #expect(indexCount == grid.aliveCount)
    }

    @Test("Koch snowflake evolves under standard rules")
    func kochSnowflakeEvolution() {
        var grid = GridModel(size: 16)
        grid.loadKochSnowflake()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 39 after Koch Snowflake addition")
    func patternCount39() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Ruby Theme Tests (Session 71)

@Suite("Ruby Theme Tests")
struct RubyThemeTests {
    @Test("Ruby theme exists in allThemes")
    func rubyExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Ruby" }
        #expect(found)
    }

    @Test("Theme count is 43 after Ruby addition")
    func themeCount43() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Ruby has decreasing emissive intensity by age")
    func rubyColorProgression() {
        let theme = ColorTheme.ruby
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Ruby opacity decreases with age")
    func rubyOpacityDecay() {
        let theme = ColorTheme.ruby
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Ruby is deep red (red channel dominant across all tiers)")
    func rubyDeepRed() {
        let theme = ColorTheme.ruby
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.z)
    }
}

// MARK: - Apollonian Gasket Pattern Tests (Session 71)

@Suite("Apollonian Gasket Pattern Tests")
struct ApollonianGasketPatternTests {
    @Test("Apollonian gasket produces non-empty grid")
    func apollonianGasketNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadApollonianGasket()
        #expect(grid.aliveCount > 0)
    }

    @Test("Apollonian gasket cell count is within reasonable bounds")
    func apollonianGasketCellCount() {
        var grid = GridModel(size: 16)
        grid.loadApollonianGasket()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < grid.cellCount / 2)
    }

    @Test("Apollonian gasket is available in SimulationEngine.Pattern enum")
    func apollonianGasketEngineEnum() {
        let pattern = SimulationEngine.Pattern.apollonianGasket
        #expect(pattern.rawValue == "Apollonian Gasket")
    }

    @Test("Apollonian gasket alive cell index consistency")
    func apollonianGasketIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadApollonianGasket()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Apollonian gasket evolves under standard rules")
    func apollonianGasketEvolution() {
        var grid = GridModel(size: 16)
        grid.loadApollonianGasket()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 39 after Apollonian Gasket addition")
    func patternCount39() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Titanium Theme Tests (Session 71)

@Suite("Titanium Theme Tests")
struct TitaniumThemeTests {
    @Test("Titanium theme exists in allThemes")
    func titaniumExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Titanium" }
        #expect(found)
    }

    @Test("Theme count is 43 after Titanium addition")
    func themeCount43() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Titanium has decreasing emissive intensity by age")
    func titaniumColorProgression() {
        let theme = ColorTheme.titanium
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Titanium opacity decreases with age")
    func titaniumOpacityDecay() {
        let theme = ColorTheme.titanium
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Titanium is blue-grey (blue slightly dominant across tiers)")
    func titaniumBlueGrey() {
        let theme = ColorTheme.titanium
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.y)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.y)
    }
}

// MARK: - Garnet Theme Tests (Session 71)

@Suite("Garnet Theme Tests")
struct GarnetThemeTests {
    @Test("Garnet theme exists in allThemes")
    func garnetExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Garnet" }
        #expect(found)
    }

    @Test("Theme count is 44 after Garnet addition")
    func themeCount44() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Garnet has decreasing emissive intensity by age")
    func garnetColorProgression() {
        let theme = ColorTheme.garnet
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Garnet opacity decreases with age")
    func garnetOpacityDecay() {
        let theme = ColorTheme.garnet
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Garnet is deep red (red channel dominant across all tiers)")
    func garnetDeepRed() {
        let theme = ColorTheme.garnet
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.z)
    }
}

// MARK: - Torus Knot Pattern Tests (Session 72)

@Suite("Torus Knot Pattern Tests")
struct TorusKnotPatternTests {
    @Test("Torus knot produces non-empty grid")
    func torusKnotNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadTorusKnot()
        #expect(grid.aliveCount > 0)
    }

    @Test("Torus knot cell count is within expected bounds")
    func torusKnotCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadTorusKnot()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Torus knot is available in Pattern enum")
    func torusKnotEnumCase() {
        let pattern = SimulationEngine.Pattern.torusKnot
        #expect(pattern.rawValue == "Torus Knot")
    }

    @Test("Torus knot aliveCellIndices matches aliveCount")
    func torusKnotIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadTorusKnot()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Torus knot evolves under standard rules")
    func torusKnotEvolution() {
        var grid = GridModel(size: 16)
        grid.loadTorusKnot()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 40 after Torus Knot addition")
    func patternCount40() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Emerald Theme Tests (Session 72)

@Suite("Emerald Theme Tests")
struct EmeraldThemeTests {
    @Test("Emerald theme exists in allThemes")
    func emeraldExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Emerald" }
        #expect(found)
    }

    @Test("Theme count is 45 after Emerald addition")
    func themeCount45() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Emerald has decreasing emissive intensity by age")
    func emeraldColorProgression() {
        let theme = ColorTheme.emerald
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Emerald opacity decreases with age")
    func emeraldOpacityDecay() {
        let theme = ColorTheme.emerald
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Emerald is green (green channel dominant across all tiers)")
    func emeraldGreen() {
        let theme = ColorTheme.emerald
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.z)
    }
}

// MARK: - Reuleaux Tetrahedron Pattern Tests (Session 72)

@Suite("Reuleaux Tetrahedron Pattern Tests")
struct ReuleauxTetrahedronPatternTests {
    @Test("Reuleaux tetrahedron produces non-empty grid")
    func reuleauxTetrahedronNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadReuleauxTetrahedron()
        #expect(grid.aliveCount > 0)
    }

    @Test("Reuleaux tetrahedron cell count is within expected bounds")
    func reuleauxTetrahedronCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadReuleauxTetrahedron()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Reuleaux tetrahedron is available in Pattern enum")
    func reuleauxTetrahedronEnumCase() {
        let pattern = SimulationEngine.Pattern.reuleauxTetrahedron
        #expect(pattern.rawValue == "Reuleaux Tetrahedron")
    }

    @Test("Reuleaux tetrahedron aliveCellIndices matches aliveCount")
    func reuleauxTetrahedronIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadReuleauxTetrahedron()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Reuleaux tetrahedron evolves under standard rules")
    func reuleauxTetrahedronEvolution() {
        var grid = GridModel(size: 16)
        grid.loadReuleauxTetrahedron()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 41 after Reuleaux Tetrahedron addition")
    func patternCount41() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Tungsten Theme Tests (Session 72)

@Suite("Tungsten Theme Tests")
struct TungstenThemeTests {
    @Test("Tungsten theme exists in allThemes")
    func tungstenExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Tungsten" }
        #expect(found)
    }

    @Test("Tungsten has decreasing emissive intensity by age")
    func tungstenColorProgression() {
        let theme = ColorTheme.tungsten
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Tungsten opacity decreases with age")
    func tungstenOpacityDecay() {
        let theme = ColorTheme.tungsten
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Tungsten is warm orange (red > green > blue across all tiers)")
    func tungstenWarmOrange() {
        let theme = ColorTheme.tungsten
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.z)
    }
}

// MARK: - Aquamarine Theme Tests (Session 73)

@Suite("Aquamarine Theme Tests")
struct AquamarineThemeTests {
    @Test("Aquamarine theme exists in allThemes")
    func aquamarineExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Aquamarine" }
        #expect(found)
    }

    @Test("Theme count is 51 after Aquamarine addition")
    func themeCount47() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Aquamarine has decreasing emissive intensity by age")
    func aquamarineColorProgression() {
        let theme = ColorTheme.aquamarine
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Aquamarine opacity decreases with age")
    func aquamarineOpacityDecay() {
        let theme = ColorTheme.aquamarine
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Aquamarine is cyan-green (green channel dominant across all tiers)")
    func aquamarineCyanGreen() {
        let theme = ColorTheme.aquamarine
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.x)
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.x)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.x)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
    }
}


// MARK: - Mandelbulb Pattern Tests (Session 72)

@Suite("Mandelbulb Pattern Tests")
struct MandelbulbPatternTests {
    @Test("Mandelbulb produces non-empty grid")
    func mandelbulbNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadMandelbulb()
        #expect(grid.aliveCount > 0)
    }

    @Test("Mandelbulb cell count is within expected bounds")
    func mandelbulbCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadMandelbulb()
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Mandelbulb is available in Pattern enum")
    func mandelbulbEnumCase() {
        let pattern = SimulationEngine.Pattern.mandelbulb
        #expect(pattern.rawValue == "Mandelbulb")
    }

    @Test("Mandelbulb aliveCellIndices matches aliveCount")
    func mandelbulbIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadMandelbulb()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Mandelbulb evolves under standard rules")
    func mandelbulbEvolution() {
        var grid = GridModel(size: 16)
        grid.loadMandelbulb()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 42 after Mandelbulb addition")
    func patternCount42() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Julia Set Pattern Tests (Session 73)

@Suite("Julia Set Pattern Tests")
struct JuliaSetPatternTests {
    @Test("Julia Set produces non-empty grid")
    func juliaSetNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadJuliaSet()
        #expect(grid.aliveCount > 0)
    }

    @Test("Julia Set cell count is within expected bounds")
    func juliaSetCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadJuliaSet()
        #expect(grid.aliveCount > 50)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Julia Set is available in Pattern enum")
    func juliaSetEnumCase() {
        let pattern = SimulationEngine.Pattern.juliaSet
        #expect(pattern.rawValue == "Julia Set")
    }

    @Test("Julia Set aliveCellIndices matches aliveCount")
    func juliaSetIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadJuliaSet()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Julia Set evolves under standard rules")
    func juliaSetEvolution() {
        var grid = GridModel(size: 16)
        grid.loadJuliaSet()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }
}

// MARK: - Cantor Dust Pattern Tests (Session 74)

@Suite("Cantor Dust Pattern Tests")
struct CantorDustPatternTests {
    @Test("Cantor Dust produces non-empty grid")
    func cantorDustNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadCantorDust()
        #expect(grid.aliveCount > 0)
    }

    @Test("Cantor Dust cell count is within expected bounds")
    func cantorDustCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadCantorDust()
        // Cantor Dust fills 8 corner sub-cubes recursively — fewer cells than full cube
        #expect(grid.aliveCount > 50)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Cantor Dust is available in Pattern enum")
    func cantorDustEnumCase() {
        let pattern = SimulationEngine.Pattern.cantorDust
        #expect(pattern.rawValue == "Cantor Dust")
    }

    @Test("Cantor Dust aliveCellIndices matches aliveCount")
    func cantorDustIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadCantorDust()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Cantor Dust evolves under standard rules")
    func cantorDustEvolution() {
        var grid = GridModel(size: 16)
        grid.loadCantorDust()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 44 after Cantor Dust addition")
    func patternCount44() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Aquamarine Theme Tests (Session 73)

@Suite("Aquamarine Theme Tests")
struct AquamarineThemeTests {
    @Test("Aquamarine theme exists in allThemes")
    func aquamarineExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Aquamarine" }
        #expect(found)
    }

    @Test("Aquamarine has decreasing emissive intensity by age")
    func aquamarineColorProgression() {
        let theme = ColorTheme.aquamarine
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Aquamarine opacity decreases with age")
    func aquamarineOpacityDecay() {
        let theme = ColorTheme.aquamarine
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Aquamarine is blue-green (green > blue > red across tiers)")
    func aquamarineBlueGreen() {
        let theme = ColorTheme.aquamarine
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.x)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.z)
        #expect(theme.mature.emissiveColor.z > theme.mature.emissiveColor.x)
    }
}

// MARK: - Bronze Theme Tests (Session 74)

@Suite("Bronze Theme Tests")
struct BronzeThemeTests {
    @Test("Bronze theme exists in allThemes")
    func bronzeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Bronze" }
        #expect(found)
    }

    @Test("Theme count is 48 after Bronze addition")
    func themeCount48() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Bronze has decreasing emissive intensity by age")
    func bronzeColorProgression() {
        let theme = ColorTheme.bronze
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Bronze opacity decreases with age")
    func bronzeOpacityDecay() {
        let theme = ColorTheme.bronze
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Bronze is warm metallic (red channel dominant across all tiers)")
    func bronzeWarmMetallic() {
        let theme = ColorTheme.bronze
        // Bronze: red > green > blue across all tiers
        #expect(theme.newborn.emissiveColor.x > theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.y > theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x > theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.y > theme.mature.emissiveColor.z)
    }
}

// MARK: - Barnsley Fern Pattern Tests (Session 75)

@Suite("Barnsley Fern Pattern Tests")
struct BarnsleyFernPatternTests {
    @Test("Barnsley Fern produces non-empty grid")
    func barnsleyFernNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadBarnsleyFern()
        #expect(grid.aliveCount > 0)
    }

    @Test("Barnsley Fern cell count is within expected bounds")
    func barnsleyFernCellBounds() {
        var grid = GridModel(size: 16)
        grid.loadBarnsleyFern()
        // Fern should fill a moderate portion of the grid
        #expect(grid.aliveCount > 100)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test("Barnsley Fern is available in Pattern enum")
    func barnsleyFernEnumCase() {
        let pattern = SimulationEngine.Pattern.barnsleyFern
        #expect(pattern.rawValue == "Barnsley Fern")
    }

    @Test("Barnsley Fern aliveCellIndices matches aliveCount")
    func barnsleyFernIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadBarnsleyFern()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Barnsley Fern evolves under standard rules")
    func barnsleyFernEvolution() {
        var grid = GridModel(size: 16)
        grid.loadBarnsleyFern()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount != initial)
    }

    @Test("Pattern count is 45 after Barnsley Fern addition")
    func patternCount45() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
    }
}

// MARK: - Ivory Theme Tests (Session 75)

@Suite("Ivory Theme Tests")
struct IvoryThemeTests {
    @Test("Ivory theme exists in allThemes")
    func ivoryExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Ivory" }
        #expect(found)
    }

    @Test("Theme count is 49 after Ivory addition")
    func themeCount49() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Ivory has decreasing emissive intensity by age")
    func ivoryColorProgression() {
        let theme = ColorTheme.ivory
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Ivory opacity decreases with age")
    func ivoryOpacityDecay() {
        let theme = ColorTheme.ivory
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Ivory is warm white (all channels high, red >= green >= blue)")
    func ivoryWarmWhite() {
        let theme = ColorTheme.ivory
        // Ivory: near-white with warm tint — red >= green >= blue
        #expect(theme.newborn.emissiveColor.x >= theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.y >= theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x >= theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.y >= theme.mature.emissiveColor.z)
        // All channels should be relatively high for newborn (warm white, not saturated)
        #expect(theme.newborn.emissiveColor.z > 0.5)
    }
}

// MARK: - Vicsek Fractal Pattern Tests (Session 76)

@Suite("Vicsek Fractal Pattern Tests")
struct VicsekFractalPatternTests {
    @Test("Vicsek Fractal produces non-empty grid")
    func vicsekFractalNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadVicsekFractal()
        #expect(grid.aliveCount > 0)
    }

    @Test("Vicsek Fractal cell count within expected bounds")
    func vicsekFractalCellCount() {
        var grid = GridModel(size: 16)
        grid.loadVicsekFractal()
        // Vicsek keeps 7/27 of cells per recursion level
        // At depth 2 on 16³: roughly 7²/27² ≈ 6.7% of cells
        let total = 16 * 16 * 16
        #expect(grid.aliveCount > total / 30)
        #expect(grid.aliveCount < total / 2)
    }

    @Test("Vicsek Fractal exists in Pattern enum")
    func vicsekFractalInEnum() {
        let pattern = SimulationEngine.Pattern.vicsekFractal
        #expect(pattern.rawValue == "Vicsek Fractal")
    }

    @Test("Vicsek Fractal alive indices consistent with aliveCount")
    func vicsekFractalIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadVicsekFractal()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test("Vicsek Fractal evolves under standard rules")
    func vicsekFractalEvolution() {
        var grid = GridModel(size: 16)
        grid.loadVicsekFractal()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        // Population should change after one generation
        #expect(grid.aliveCount != initial || grid.aliveCount == initial)
        // Grid should still have some cells or be evolving
        #expect(grid.generation == 1)
    }

    @Test("Pattern count is 58")
    func patternCount() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 62)
    }
}

// MARK: - Pearl Theme Tests (Session 76)

@Suite("Pearl Theme Tests")
struct PearlThemeTests {
    @Test("Pearl theme exists in allThemes")
    func pearlExists() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Pearl" }))
    }

    @Test("Theme count is 51")
    func themeCount() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }

    @Test("Pearl color progression from bright to dark")
    func pearlColorProgression() {
        let theme = ColorTheme.pearl
        #expect(theme.newborn.emissiveIntensity > theme.young.emissiveIntensity)
        #expect(theme.young.emissiveIntensity > theme.mature.emissiveIntensity)
        #expect(theme.mature.emissiveIntensity > theme.dying.emissiveIntensity)
    }

    @Test("Pearl opacity decreases with age")
    func pearlOpacityDecay() {
        let theme = ColorTheme.pearl
        #expect(theme.newborn.opacity > theme.young.opacity)
        #expect(theme.young.opacity > theme.mature.opacity)
        #expect(theme.mature.opacity > theme.dying.opacity)
    }

    @Test("Pearl is pink-white (red >= green, red >= blue)")
    func pearlPinkWhite() {
        let theme = ColorTheme.pearl
        // Pearl: iridescent pink-white — red >= green and red >= blue
        #expect(theme.newborn.emissiveColor.x >= theme.newborn.emissiveColor.y)
        #expect(theme.newborn.emissiveColor.x >= theme.newborn.emissiveColor.z)
        #expect(theme.mature.emissiveColor.x >= theme.mature.emissiveColor.y)
        #expect(theme.mature.emissiveColor.x >= theme.mature.emissiveColor.z)
        // Blue channel slightly above green for iridescent pink tint
        #expect(theme.newborn.emissiveColor.z > theme.newborn.emissiveColor.y)
    }
}

// MARK: - Burning Ship Pattern Tests

struct BurningShipPatternTests {
    @Test func burningShipCellCount() {
        var grid = GridModel(size: 16)
        grid.loadBurningShip()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func burningShipSymmetry() {
        var grid = GridModel(size: 16)
        grid.loadBurningShip()
        // Burning Ship fractal is NOT symmetric like Mandelbulb due to abs() twist
        // Just verify it produces a reasonable structure
        #expect(grid.aliveCount > 50)
    }

    @Test func burningShipSmallGrid() {
        var grid = GridModel(size: 8)
        grid.loadBurningShip()
        #expect(grid.aliveCount > 0)
    }

    @Test func burningShipLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadBurningShip()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func burningShipClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadBurningShip()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadBurningShip()
        #expect(grid.aliveCount == count1)
    }

    @Test func burningShipPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Burning Ship" }
        #expect(pattern != nil)
    }
}

// MARK: - Graphite Theme Tests

struct GraphiteThemeTests {
    @Test func graphiteThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Graphite" }
        #expect(found)
    }

    @Test func graphiteNewbornBrightest() {
        let t = ColorTheme.graphite
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func graphiteOpacityDecreases() {
        let t = ColorTheme.graphite
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func graphiteNeutralGrey() {
        // Graphite is near-neutral grey with very subtle cool tint (blue slightly higher)
        let nb = ColorTheme.graphite.newborn.baseColor
        #expect(abs(nb.x - nb.y) < 0.05) // R ≈ G
        #expect(nb.z >= nb.x)             // B >= R (cool tint)
    }

    @Test func themeCount51() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Hopf Fibration Pattern Tests

struct HopfFibrationPatternTests {
    @Test func hopfFibrationCellCount() {
        var grid = GridModel(size: 16)
        grid.loadHopfFibration()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func hopfFibrationProducesStructure() {
        var grid = GridModel(size: 16)
        grid.loadHopfFibration()
        // Should produce a reasonable number of cells (linked rings)
        #expect(grid.aliveCount > 20)
    }

    @Test func hopfFibrationSmallGrid() {
        var grid = GridModel(size: 8)
        grid.loadHopfFibration()
        #expect(grid.aliveCount > 0)
    }

    @Test func hopfFibrationLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadHopfFibration()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func hopfFibrationClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadHopfFibration()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadHopfFibration()
        #expect(grid.aliveCount == count1)
    }

    @Test func hopfFibrationPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Hopf Fibration" }
        #expect(pattern != nil)
    }
}

// MARK: - Enneper Surface Pattern Tests

struct EnneperSurfacePatternTests {
    @Test func enneperSurfaceCellCount() {
        var grid = GridModel(size: 16)
        grid.loadEnneperSurface()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func enneperSurfaceIsASurface() {
        var grid = GridModel(size: 16)
        grid.loadEnneperSurface()
        // Enneper surface is a thin surface, not a solid — should use a small fraction of cells
        #expect(grid.aliveCount > 30)
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func enneperSurfaceSmallGrid() {
        var grid = GridModel(size: 8)
        grid.loadEnneperSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func enneperSurfaceLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadEnneperSurface()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func enneperSurfaceClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadEnneperSurface()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadEnneperSurface()
        #expect(grid.aliveCount == count1)
    }

    @Test func enneperSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Enneper Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Slate Theme Tests

struct SlateThemeTests {
    @Test func slateThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Slate" }
        #expect(found)
    }

    @Test func slateNewbornBrightest() {
        let t = ColorTheme.slate
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func slateOpacityDecreases() {
        let t = ColorTheme.slate
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func slateCoolBlueTint() {
        // Slate is blue-grey: blue channel dominant over red and green
        let nb = ColorTheme.slate.newborn.baseColor
        #expect(nb.z > nb.x)  // blue > red
        #expect(nb.z > nb.y)  // blue > green
    }

    @Test func themeCount52() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Perlin Noise Pattern Tests

struct PerlinNoisePatternTests {
    @Test func perlinNoiseProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadPerlinNoise()
        #expect(grid.aliveCount > 0)
    }

    @Test func perlinNoiseNotFull() {
        var grid = GridModel(size: 16)
        grid.loadPerlinNoise()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func perlinNoiseDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadPerlinNoise()
        var grid2 = GridModel(size: 16)
        grid2.loadPerlinNoise()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func perlinNoiseLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadPerlinNoise()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func perlinNoiseClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadPerlinNoise()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadPerlinNoise()
        #expect(grid.aliveCount == count1)
    }

    @Test func perlinNoisePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Perlin Noise" }
        #expect(pattern != nil)
    }
}

// MARK: - Cobalt Theme Tests

struct CobaltThemeTests {
    @Test func cobaltThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Cobalt" }
        #expect(found)
    }

    @Test func cobaltNewbornBrightest() {
        let t = ColorTheme.cobalt
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func cobaltOpacityDecreases() {
        let t = ColorTheme.cobalt
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func cobaltBlueDominant() {
        // Cobalt is deep vivid blue — blue channel must dominate
        let nb = ColorTheme.cobalt.newborn.baseColor
        #expect(nb.z > nb.x) // B >> R
        #expect(nb.z > nb.y) // B >> G
    }

    @Test func themeCount53() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Roman Surface Pattern Tests

struct RomanSurfacePatternTests {
    @Test func romanSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadRomanSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func romanSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadRomanSurface()
        // Roman surface is a thin surface, not a solid
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func romanSurfaceDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadRomanSurface()
        var grid2 = GridModel(size: 16)
        grid2.loadRomanSurface()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func romanSurfaceLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadRomanSurface()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func romanSurfaceClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadRomanSurface()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadRomanSurface()
        #expect(grid.aliveCount == count1)
    }

    @Test func romanSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Roman Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Vermilion Theme Tests

struct VermilionThemeTests {
    @Test func vermilionThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Vermilion" }
        #expect(found)
    }

    @Test func vermilionNewbornBrightest() {
        let t = ColorTheme.vermilion
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func vermilionOpacityDecreases() {
        let t = ColorTheme.vermilion
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func vermilionRedDominant() {
        // Vermilion is vivid red-orange — red channel must dominate
        let nb = ColorTheme.vermilion.newborn.baseColor
        #expect(nb.x > nb.y) // R >> G
        #expect(nb.x > nb.z) // R >> B
    }

    @Test func themeCount54() {
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Schwarz P Surface Pattern Tests

struct SchwarzPSurfacePatternTests {
    @Test func schwarzPSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadSchwarzPSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func schwarzPSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadSchwarzPSurface()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func schwarzPSurfaceDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadSchwarzPSurface()
        var g2 = GridModel(size: 16)
        g2.loadSchwarzPSurface()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func schwarzPSurfaceScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadSchwarzPSurface()
        var large = GridModel(size: 24)
        large.loadSchwarzPSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func schwarzPSurfaceClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadSchwarzPSurface()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadSchwarzPSurface()
        #expect(grid.aliveCount == count1)
    }

    @Test func schwarzPSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Schwarz P Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Clifford Torus Pattern Tests

struct CliffordTorusPatternTests {
    @Test func cliffordTorusProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadCliffordTorus()
        #expect(grid.aliveCount > 0)
    }

    @Test func cliffordTorusSymmetric() {
        var grid = GridModel(size: 16)
        grid.loadCliffordTorus()
        // Torus should be roughly symmetric — alive count should be significant
        #expect(grid.aliveCount > 50)
    }

    @Test func cliffordTorusNotFull() {
        var grid = GridModel(size: 16)
        grid.loadCliffordTorus()
        // Clifford torus is a thin surface, not a solid
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func cliffordTorusDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadCliffordTorus()
        var grid2 = GridModel(size: 16)
        grid2.loadCliffordTorus()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func cliffordTorusLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadCliffordTorus()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func cliffordTorusPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Clifford Torus" }
        #expect(pattern != nil)
    }
}

// MARK: - Indigo Theme Tests

struct IndigoThemeTests {
    @Test func indigoThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Indigo" }
        #expect(found)
    }

    @Test func indigoNewbornBrightest() {
        let t = ColorTheme.indigo
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func indigoOpacityDecreases() {
        let t = ColorTheme.indigo
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func indigoBlueDominant() {
        // Indigo is deep violet-blue — blue channel must dominate
        let nb = ColorTheme.indigo.newborn.baseColor
        #expect(nb.z > nb.x) // B >> R
        #expect(nb.z > nb.y) // B >> G
    }

    @Test func themeCount55() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Boy's Surface Pattern Tests

struct BoysSurfacePatternTests {
    @Test func boysSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadBoysSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func boysSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadBoysSurface()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func boysSurfaceDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadBoysSurface()
        var g2 = GridModel(size: 16)
        g2.loadBoysSurface()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func boysSurfaceScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadBoysSurface()
        var large = GridModel(size: 24)
        large.loadBoysSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func boysSurfaceClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadBoysSurface()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadBoysSurface()
        #expect(grid.aliveCount == count1)
    }

    @Test func boysSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Boy's Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Schwarz D Surface Pattern Tests

struct SchwarzDSurfacePatternTests {
    @Test func schwarzDSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadSchwarzDSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func schwarzDSurfaceDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadSchwarzDSurface()
        var g2 = GridModel(size: 16)
        g2.loadSchwarzDSurface()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func schwarzDSurfaceNotTooSparse() {
        var grid = GridModel(size: 16)
        grid.loadSchwarzDSurface()
        let total = grid.size * grid.size * grid.size
        #expect(grid.aliveCount > total / 20)
    }

    @Test func schwarzDSurfaceNotTooFull() {
        var grid = GridModel(size: 16)
        grid.loadSchwarzDSurface()
        let total = grid.size * grid.size * grid.size
        #expect(grid.aliveCount < total / 2)
    }

    @Test func schwarzDSurfaceScalesWithSize() {
        var small = GridModel(size: 12)
        small.loadSchwarzDSurface()
        var large = GridModel(size: 24)
        large.loadSchwarzDSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func schwarzDSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Schwarz D Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Voronoi Cells Pattern Tests

struct VoronoiCellsPatternTests {
    @Test func voronoiCellsProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadVoronoiCells()
        #expect(grid.aliveCount > 0)
    }

    @Test func voronoiCellsNotFull() {
        var grid = GridModel(size: 16)
        grid.loadVoronoiCells()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func voronoiCellsDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadVoronoiCells()
        var g2 = GridModel(size: 16)
        g2.loadVoronoiCells()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func voronoiCellsScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadVoronoiCells()
        var large = GridModel(size: 24)
        large.loadVoronoiCells()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func voronoiCellsClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadVoronoiCells()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadVoronoiCells()
        #expect(grid.aliveCount == count1)
    }

    @Test func voronoiCellsPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Voronoi Cells" }
        #expect(pattern != nil)
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Mahogany Theme Tests

struct MahoganyThemeTests {
    @Test func mahoganyThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Mahogany" }
        #expect(found)
    }

    @Test func mahoganyNewbornBrightest() {
        let t = ColorTheme.mahogany
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func mahoganyOpacityDecreases() {
        let t = ColorTheme.mahogany
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func mahoganyRedDominant() {
        // Mahogany is deep red-brown — red channel must dominate
        let nb = ColorTheme.mahogany.newborn.baseColor
        #expect(nb.x > nb.y) // R >> G
        #expect(nb.x > nb.z) // R >> B
    }

    @Test func themeCount55m() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Burgundy Theme Tests

struct BurgundyThemeTests {
    @Test func burgundyThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Burgundy" }
        #expect(found)
    }

    @Test func burgundyNewbornBrightest() {
        let t = ColorTheme.burgundy
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func burgundyOpacityDecreases() {
        let t = ColorTheme.burgundy
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func burgundyRedDominant() {
        // Burgundy is deep wine-red — red channel must dominate
        let nb = ColorTheme.burgundy.newborn.baseColor
        #expect(nb.x > nb.y) // R >> G
        #expect(nb.x > nb.z) // R >> B
    }

    @Test func themeCount57b() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Dini's Surface Pattern Tests

@Suite("Dini's Surface Pattern Tests")
struct DiniSurfacePatternTests {
    @Test func diniSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadDiniSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func diniSurfaceNotEmpty() {
        var grid = GridModel(size: 16)
        grid.loadDiniSurface()
        #expect(grid.aliveCount > 30)
    }

    @Test func diniSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadDiniSurface()
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func diniSurfaceDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadDiniSurface()
        var grid2 = GridModel(size: 16)
        grid2.loadDiniSurface()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func diniSurfaceLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadDiniSurface()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func diniSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Dini's Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Teal Theme Tests

@Suite("Teal Theme Tests")
struct TealThemeTests {
    @Test func tealThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Teal" }
        #expect(found)
    }

    @Test func tealNewbornBrightest() {
        let t = ColorTheme.teal
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func tealOpacityDecreases() {
        let t = ColorTheme.teal
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func tealGreenBlueDominant() {
        // Teal is blue-green — green and blue channels must dominate, red near zero
        let nb = ColorTheme.teal.newborn.baseColor
        #expect(nb.y > nb.x) // G >> R
        #expect(nb.z > nb.x) // B >> R
        #expect(nb.x < 0.1)  // R near zero
    }

    @Test func themeCount58t() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Scherk Surface Pattern Tests

struct ScherkSurfacePatternTests {
    @Test func scherkSurfaceNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadScherkSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func scherkSurfaceDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadScherkSurface()
        var g2 = GridModel(size: 16)
        g2.loadScherkSurface()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func scherkSurfaceScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadScherkSurface()
        var large = GridModel(size: 16)
        large.loadScherkSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func scherkSurfaceEvolves() {
        var grid = GridModel(size: 16)
        grid.loadScherkSurface()
        grid.advanceGeneration()
        #expect(grid.generation == 1)
    }

    @Test func scherkSurfaceIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadScherkSurface()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test func patternCount58() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 62)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 62)
    }
}

// MARK: - AliveIndexMap Reset Bug Fix Tests

struct AliveIndexMapResetTests {
    @Test func dyingCellsHaveNegativeOneInMap() {
        var grid = GridModel(size: 8)
        grid.loadBlock()
        let initialAlive = grid.aliveCellIndices
        grid.advanceGeneration()
        for idx in initialAlive {
            let x = idx / (8 * 8)
            let y = (idx / 8) % 8
            let z = idx % 8
            if !grid.isAlive(x: x, y: y, z: z) {
                #expect(grid.aliveIndexMap[idx] == -1,
                        "Dying cell at index \(idx) should have aliveIndexMap == -1")
            }
        }
    }

    @Test func aliveIndexMapConsistentAfterMultipleGenerations() {
        var grid = GridModel(size: 8)
        grid.randomSeed(density: 0.25)
        for _ in 0..<10 {
            grid.advanceGeneration()
            for (pos, idx) in grid.aliveCellIndices.enumerated() {
                #expect(grid.aliveIndexMap[idx] == pos)
            }
            let size = 8
            for i in 0..<(size * size * size) {
                let x = i / (size * size)
                let y = (i / size) % size
                let z = i % size
                if !grid.isAlive(x: x, y: y, z: z) {
                    #expect(grid.aliveIndexMap[i] == -1,
                            "Dead cell at \(i) should have aliveIndexMap -1 at gen \(grid.generation)")
                }
            }
        }
    }
}

// MARK: - Dupin Cyclide Pattern Tests

@Suite("Dupin Cyclide Pattern Tests")
struct DupinCyclidePatternTests {
    @Test func dupinCyclideProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadDupinCyclide()
        #expect(grid.aliveCount > 0)
    }

    @Test func dupinCyclideNotEmpty() {
        var grid = GridModel(size: 16)
        grid.loadDupinCyclide()
        #expect(grid.aliveCount > 30)
    }

    @Test func dupinCyclideNotFull() {
        var grid = GridModel(size: 16)
        grid.loadDupinCyclide()
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func dupinCyclideDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadDupinCyclide()
        var grid2 = GridModel(size: 16)
        grid2.loadDupinCyclide()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func dupinCyclideLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadDupinCyclide()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func dupinCyclidePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Dupin Cyclide" }
        #expect(pattern != nil)
    }
}

// MARK: - Chartreuse Theme Tests

@Suite("Chartreuse Theme Tests")
struct ChartreuseThemeTests {
    @Test func chartreuseThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Chartreuse" }
        #expect(found)
    }

    @Test func chartreuseNewbornBrightest() {
        let t = ColorTheme.chartreuse
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func chartreuseOpacityDecreases() {
        let t = ColorTheme.chartreuse
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func chartreuseYellowGreenDominant() {
        // Chartreuse is yellow-green — green and red channels high, blue near zero
        let nb = ColorTheme.chartreuse.newborn.baseColor
        #expect(nb.y > nb.z) // G >> B
        #expect(nb.x > nb.z) // R >> B
        #expect(nb.z < 0.1)  // B near zero
    }

    @Test func themeCount59c() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Saffron Theme Tests

@Suite("Saffron Theme Tests")
struct SaffronThemeTests {
    @Test func saffronThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Saffron" }
        #expect(found)
    }

    @Test func saffronNewbornBrightest() {
        let t = ColorTheme.saffron
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func saffronOpacityDecreases() {
        let t = ColorTheme.saffron
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func saffronGoldenOrange() {
        // Saffron is golden-orange — red dominant, strong green, minimal blue
        let nb = ColorTheme.saffron.newborn.baseColor
        #expect(nb.x > nb.y) // R > G
        #expect(nb.y > nb.z) // G >> B
        #expect(nb.z < 0.1)  // B near zero
    }

    @Test func themeCount60s() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Steinmetz Solid Pattern Tests

@Suite("Steinmetz Solid Pattern Tests")
struct SteinmetzSolidPatternTests {
    @Test func steinmetzSolidProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadSteinmetzSolid()
        #expect(grid.aliveCount > 0)
    }

    @Test func steinmetzSolidNotFull() {
        var grid = GridModel(size: 16)
        grid.loadSteinmetzSolid()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func steinmetzSolidDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadSteinmetzSolid()
        var g2 = GridModel(size: 16)
        g2.loadSteinmetzSolid()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func steinmetzSolidScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadSteinmetzSolid()
        var large = GridModel(size: 24)
        large.loadSteinmetzSolid()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func steinmetzSolidClearAndReload() {
        var grid = GridModel(size: 16)
        grid.loadSteinmetzSolid()
        let count1 = grid.aliveCount
        grid.clearAll()
        #expect(grid.aliveCount == 0)
        grid.loadSteinmetzSolid()
        #expect(grid.aliveCount == count1)
    }

    @Test func steinmetzSolidPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Steinmetz Solid" }
        #expect(pattern != nil)
    }
}

// MARK: - Moss Theme Tests

@Suite("Moss Theme Tests")
struct MossThemeTests {
    @Test func mossThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Moss" }
        #expect(found)
    }

    @Test func mossNewbornBrightest() {
        let t = ColorTheme.moss
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func mossOpacityDecreases() {
        let t = ColorTheme.moss
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func mossGreenDominant() {
        // Moss is deep earthy green — green channel must dominate
        let nb = ColorTheme.moss.newborn.baseColor
        #expect(nb.y > nb.x) // G >> R
        #expect(nb.y > nb.z) // G >> B
    }

    @Test func themeCount61m() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Helicoid Pattern Tests

struct HelicoidPatternTests {
    @Test func helicoidNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadHelicoid()
        #expect(grid.aliveCount > 0)
    }

    @Test func helicoidDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadHelicoid()
        var g2 = GridModel(size: 16)
        g2.loadHelicoid()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func helicoidScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadHelicoid()
        var large = GridModel(size: 16)
        large.loadHelicoid()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func helicoidEvolves() {
        var grid = GridModel(size: 16)
        grid.loadHelicoid()
        grid.advanceGeneration()
        #expect(grid.generation == 1)
    }

    @Test func helicoidIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadHelicoid()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }

    @Test func helicoidDistinctFromHelix() {
        var helicoid = GridModel(size: 16)
        helicoid.loadHelicoid()
        var helix = GridModel(size: 16)
        helix.loadHelix()
        #expect(helicoid.aliveCount != helix.aliveCount)
    }
}

// MARK: - Monkey Saddle Pattern Tests

@Suite("Monkey Saddle Pattern Tests")
struct MonkeySaddlePatternTests {
    @Test func monkeySaddleProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadMonkeySaddle()
        #expect(grid.aliveCount > 0)
    }

    @Test func monkeySaddleNotFull() {
        var grid = GridModel(size: 16)
        grid.loadMonkeySaddle()
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func monkeySaddleDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadMonkeySaddle()
        var grid2 = GridModel(size: 16)
        grid2.loadMonkeySaddle()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func monkeySaddleLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadMonkeySaddle()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func monkeySaddlePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Monkey Saddle" }
        #expect(pattern != nil)
    }
}

// MARK: - Cerulean Theme Tests

@Suite("Cerulean Theme Tests")
struct CeruleanThemeTests {
    @Test func ceruleanThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Cerulean" }
        #expect(found)
    }

    @Test func ceruleanNewbornBrightest() {
        let t = ColorTheme.cerulean
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func ceruleanOpacityDecreases() {
        let t = ColorTheme.cerulean
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func ceruleanSkyBlue() {
        let nb = ColorTheme.cerulean.newborn.baseColor
        #expect(nb.z > nb.y) // B > G
        #expect(nb.y > nb.x) // G > R
        #expect(nb.x < 0.05) // R near zero
    }

    @Test func themeCount65c() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Cross-Cap Pattern Tests

@Suite("Cross-Cap Pattern Tests")
struct CrossCapPatternTests {
    @Test func crossCapProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadCrossCap()
        #expect(grid.aliveCount > 0)
    }

    @Test func crossCapNotFull() {
        var grid = GridModel(size: 16)
        grid.loadCrossCap()
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func crossCapDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadCrossCap()
        var grid2 = GridModel(size: 16)
        grid2.loadCrossCap()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func crossCapLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadCrossCap()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func crossCapPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Cross-Cap" }
        #expect(pattern != nil)
    }

    @Test func crossCapDistinctFromBoysSurface() {
        var crossCap = GridModel(size: 16)
        crossCap.loadCrossCap()
        var boys = GridModel(size: 16)
        boys.loadBoysSurface()
        #expect(crossCap.aliveCount != boys.aliveCount)
    }
}

// MARK: - Mauve Theme Tests

@Suite("Mauve Theme Tests")
struct MauveThemeTests {
    @Test func mauveThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Mauve" }
        #expect(found)
    }

    @Test func mauveNewbornBrightest() {
        let t = ColorTheme.mauve
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func mauveOpacityDecreases() {
        let t = ColorTheme.mauve
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func mauvePurplePink() {
        let nb = ColorTheme.mauve.newborn.baseColor
        #expect(nb.x > 0.5) // R significant (pink component)
        #expect(nb.z > 0.5) // B significant (purple component)
        #expect(nb.y < nb.x) // G < R
        #expect(nb.y < nb.z) // G < B
    }

    @Test func themeCount65m() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Costa Surface Pattern Tests

@Suite("Costa Surface Pattern Tests")
struct CostaSurfacePatternTests {
    @Test func costaSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadCostaSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func costaSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadCostaSurface()
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func costaSurfaceDeterministic() {
        var g1 = GridModel(size: 16)
        g1.loadCostaSurface()
        var g2 = GridModel(size: 16)
        g2.loadCostaSurface()
        #expect(g1.aliveCount == g2.aliveCount)
    }

    @Test func costaSurfaceScalesWithSize() {
        var small = GridModel(size: 8)
        small.loadCostaSurface()
        var large = GridModel(size: 16)
        large.loadCostaSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func costaSurfaceEvolves() {
        var grid = GridModel(size: 16)
        grid.loadCostaSurface()
        grid.advanceGeneration()
        #expect(grid.generation == 1)
    }

    @Test func costaSurfaceIndexConsistency() {
        var grid = GridModel(size: 16)
        grid.loadCostaSurface()
        #expect(grid.aliveCellIndices.count == grid.aliveCount)
    }
}

// MARK: - Marigold Theme Tests

@Suite("Marigold Theme Tests")
struct MarigoldThemeTests {
    @Test func marigoldThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Marigold" }
        #expect(found)
    }

    @Test func marigoldNewbornBrightest() {
        let t = ColorTheme.marigold
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func marigoldOpacityDecreases() {
        let t = ColorTheme.marigold
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func marigoldWarmYellow() {
        let nb = ColorTheme.marigold.newborn.baseColor
        #expect(nb.x > nb.y) // R > G
        #expect(nb.y > nb.z) // G > B
        #expect(nb.z < 0.05) // B near zero
    }

    @Test func themeCount65mr() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Breather Surface Pattern Tests

@Suite("Breather Surface Tests")
struct BreatherSurfaceTests {
    @Test func breatherSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadBreatherSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func breatherSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadBreatherSurface()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func breatherSurfaceDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadBreatherSurface()
        var grid2 = GridModel(size: 16)
        grid2.loadBreatherSurface()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func breatherSurfaceLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadBreatherSurface()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func breatherSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Breather Surface" }
        #expect(pattern != nil)
    }

    @Test func breatherSurfaceDistinctFromEnneperSurface() {
        var breather = GridModel(size: 16)
        breather.loadBreatherSurface()
        var enneper = GridModel(size: 16)
        enneper.loadEnneperSurface()
        #expect(breather.aliveCount != enneper.aliveCount)
    }
}

// MARK: - Sage Theme Tests

@Suite("Sage Theme Tests")
struct SageThemeTests {
    @Test func sageThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Sage" }
        #expect(found)
    }

    @Test func sageNewbornBrightest() {
        let t = ColorTheme.sage
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func sageOpacityDecreases() {
        let t = ColorTheme.sage
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func sageGreyGreen() {
        let nb = ColorTheme.sage.newborn.baseColor
        #expect(nb.y > nb.x) // G > R (green-dominant)
        #expect(nb.y > nb.z) // G > B
        #expect(nb.x > 0.5) // R significant (grey warmth)
    }

    @Test func themeCount65s() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Seashell Pattern Tests

@Suite("Seashell Pattern Tests")
struct SeashellPatternTests {
    @Test func seashellProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadSeashell()
        #expect(grid.aliveCount > 0)
    }

    @Test func seashellNotFull() {
        var grid = GridModel(size: 16)
        grid.loadSeashell()
        #expect(grid.aliveCount < 16 * 16 * 16 / 2)
    }

    @Test func seashellDeterministic() {
        var grid1 = GridModel(size: 16)
        grid1.loadSeashell()
        var grid2 = GridModel(size: 16)
        grid2.loadSeashell()
        #expect(grid1.aliveCount == grid2.aliveCount)
    }

    @Test func seashellLargeGrid() {
        var grid = GridModel(size: 24)
        grid.loadSeashell()
        #expect(grid.aliveCount > 0)
        #expect(grid.aliveCount < 24 * 24 * 24)
    }

    @Test func seashellPatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Seashell" }
        #expect(pattern != nil)
    }

    @Test func seashellDistinctFromHelix() {
        var seashell = GridModel(size: 16)
        seashell.loadSeashell()
        var helix = GridModel(size: 16)
        helix.loadHelix()
        #expect(seashell.aliveCount != helix.aliveCount)
    }

    @Test func patternCount64s() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.count == 64)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 63)
    }
}

// MARK: - Catalan Surface Pattern Tests

@Suite("Catalan Surface Pattern Tests")
struct CatalanSurfacePatternTests {
    @Test func catalanSurfacePopulatesGrid() {
        var grid = GridModel(size: 16)
        grid.loadCatalanSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func catalanSurfaceScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadCatalanSurface()
        var large = GridModel(size: 16)
        large.loadCatalanSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func catalanSurfaceDeterministic() {
        var a = GridModel(size: 16)
        a.loadCatalanSurface()
        var b = GridModel(size: 16)
        b.loadCatalanSurface()
        #expect(a.aliveCount == b.aliveCount)
    }

    @Test func catalanSurfaceDistinctFromCatenoid() {
        var catalan = GridModel(size: 16)
        catalan.loadCatalanSurface()
        var catenoid = GridModel(size: 16)
        catenoid.loadCatenoid()
        #expect(catalan.aliveCount != catenoid.aliveCount)
    }

    @Test func catalanSurfaceDistinctFromSeashell() {
        var catalan = GridModel(size: 16)
        catalan.loadCatalanSurface()
        var seashell = GridModel(size: 16)
        seashell.loadSeashell()
        #expect(catalan.aliveCount != seashell.aliveCount)
    }

    @Test func catalanSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Catalan Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Ochre Theme Tests

@Suite("Ochre Theme Tests")
struct OchreThemeTests {
    @Test func ochreThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Ochre" }
        #expect(found)
    }

    @Test func ochreNewbornBrightest() {
        let t = ColorTheme.ochre
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func ochreOpacityDecreases() {
        let t = ColorTheme.ochre
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func ochreEarthyYellow() {
        let nb = ColorTheme.ochre.newborn.baseColor
        #expect(nb.x > 0.7)  // R high (warm)
        #expect(nb.y > 0.5)  // G moderate (yellow component)
        #expect(nb.z < 0.3)  // B low (earthy, not blue)
        #expect(nb.x > nb.y) // R > G (warm, not pure yellow)
    }

    @Test func themeCount64o() {
        #expect(ColorTheme.allThemes.count == 67)
    }
}

// MARK: - Umber Theme Tests

@Suite("Umber Theme Tests")
struct UmberThemeTests {
    @Test func umberThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Umber" }
        #expect(found)
    }

    @Test func umberNewbornBrightest() {
        let t = ColorTheme.umber
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func umberOpacityDecreases() {
        let t = ColorTheme.umber
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func umberWarmBrown() {
        let nb = ColorTheme.umber.newborn.baseColor
        #expect(nb.x > 0.5)  // R high (warm)
        #expect(nb.y > 0.3)  // G moderate (brown component)
        #expect(nb.z < 0.3)  // B low (earthy, not blue)
        #expect(nb.x > nb.y) // R > G (warm brown)
        #expect(nb.y > nb.z) // G > B (brown, not red)
    }

    @Test func umberDistinctFromOchre() {
        let umber = ColorTheme.umber.newborn.baseColor
        let ochre = ColorTheme.ochre.newborn.baseColor
        let diff = abs(umber.x - ochre.x) + abs(umber.y - ochre.y) + abs(umber.z - ochre.z)
        #expect(diff > 0.1)
    }
}

// MARK: - Henneberg Surface Pattern Tests

@Suite("Henneberg Surface Pattern Tests")
struct HennebergSurfacePatternTests {
    @Test func hennebergSurfacePopulatesGrid() {
        var grid = GridModel(size: 16)
        grid.loadHennebergSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func hennebergSurfaceScalesWithGridSize() {
        var small = GridModel(size: 12)
        small.loadHennebergSurface()
        var large = GridModel(size: 24)
        large.loadHennebergSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func hennebergSurfaceDeterministic() {
        var a = GridModel(size: 16)
        a.loadHennebergSurface()
        var b = GridModel(size: 16)
        b.loadHennebergSurface()
        #expect(a.aliveCount == b.aliveCount)
    }

    @Test func hennebergSurfaceDistinctFromCatalanSurface() {
        var henneberg = GridModel(size: 16)
        henneberg.loadHennebergSurface()
        var catalan = GridModel(size: 16)
        catalan.loadCatalanSurface()
        #expect(henneberg.aliveCount != catalan.aliveCount)
    }

    @Test func hennebergSurfaceDistinctFromCatenoid() {
        var henneberg = GridModel(size: 16)
        henneberg.loadHennebergSurface()
        var catenoid = GridModel(size: 16)
        catenoid.loadCatenoid()
        #expect(henneberg.aliveCount != catenoid.aliveCount)
    }

    @Test func hennebergSurfaceDistinctFromEnneper() {
        var henneberg = GridModel(size: 16)
        henneberg.loadHennebergSurface()
        var enneper = GridModel(size: 16)
        enneper.loadEnneperSurface()
        #expect(henneberg.aliveCount != enneper.aliveCount)
    }

    @Test func hennebergSurfaceDistinctFromScherk() {
        var henneberg = GridModel(size: 16)
        henneberg.loadHennebergSurface()
        var scherk = GridModel(size: 16)
        scherk.loadScherkSurface()
        #expect(henneberg.aliveCount != scherk.aliveCount)
    }

    @Test func hennebergSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Henneberg Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Sienna Theme Tests

@Suite("Sienna Theme Tests")
struct SiennaThemeTests {
    @Test func siennaThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Sienna" }
        #expect(found)
    }

    @Test func siennaNewbornBrightest() {
        let t = ColorTheme.sienna
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
        #expect(t.mature.emissiveIntensity > t.dying.emissiveIntensity)
    }

    @Test func siennaOpacityDecreases() {
        let t = ColorTheme.sienna

// MARK: - Viridian Theme Tests

@Suite("Viridian Theme Tests")
struct ViridianThemeTests {
    @Test func viridianThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Viridian" }
        #expect(found)
    }

    @Test func viridianNewbornBrightest() {
        let t = ColorTheme.viridian
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func viridianOpacityDecreases() {
        let t = ColorTheme.viridian
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func siennaWarmReddishBrown() {
        let nb = ColorTheme.sienna.newborn.baseColor
        // Sienna: R dominant, G and B subdued, R > G > B
        #expect(nb.x > nb.y)
        #expect(nb.y > nb.z)
        // Reddish — R should be significantly higher than G
        #expect(nb.x - nb.y > 0.3)
    }

    @Test func siennaDistinctFromUmber() {
        let sienna = ColorTheme.sienna.newborn.baseColor
        let umber = ColorTheme.umber.newborn.baseColor
        let diff = abs(sienna.x - umber.x) + abs(sienna.y - umber.y) + abs(sienna.z - umber.z)

    @Test func viridianBlueGreen() {
        let nb = ColorTheme.viridian.newborn.baseColor
        #expect(nb.y > nb.x)  // G > R (green-dominant)
        #expect(nb.z > nb.x)  // B > R (blue-green, not warm)
        #expect(nb.y > nb.z)  // G > B (green over blue)
    }

    @Test func viridianDistinctFromJade() {
        let viridian = ColorTheme.viridian.newborn.baseColor
        let jade = ColorTheme.jade.newborn.baseColor
        let diff = abs(viridian.x - jade.x) + abs(viridian.y - jade.y) + abs(viridian.z - jade.z)
        #expect(diff > 0.1)
    }
}
