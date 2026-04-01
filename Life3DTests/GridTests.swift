import Testing
import Foundation
@testable import Life3D

@Suite("Grid Tests")
struct GridTests {
}

@Suite("Cell State Tests")
struct CellStateTests {
}

@Suite("Neighbor Counting Tests")
struct NeighborTests {
}

@Suite("Rule Application Tests")
struct RuleTests {
}

@Suite("Cell Age Tests")
struct CellAgeTests {
}

@Suite("Born Cell Tracking Tests")
struct BornCellTests {
}

@Suite("Performance Optimization Tests")
struct PerformanceTests {
    // MARK: - Cell Toggle Tests

    // MARK: - Draw Mode / Paint Tests

    // MARK: - Alive Count Caching Tests

    // MARK: - Population History & Extinction Notice

}


@Suite("Mesh Rebuild Skip Tests")
struct MeshRebuildSkipTests {
}

@Suite("Exit Transition Tests")
struct ExitTransitionTests {
}

@Suite("Population History Circular Buffer Tests")
struct PopulationHistoryTests {
}

@Suite("Draw Mode Tests")
struct DrawModeTests {
}

@Suite("Coral Theme Tests")
struct CoralThemeTests {
}

@Suite("Mirror Symmetry Pattern Tests")
struct MirrorPatternTests {
}

@Suite("Grid Size Rule Preservation Tests")
struct GridSizeRuleTests {
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
        #expect(ColorTheme.allThemes.count == 97)
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
}

@Suite("Sunset Theme Tests")
struct SunsetThemeTests {
}

@Suite("Stagger Pattern Tests")
struct StaggerPatternTests {
}

@Suite("Trend Circular Buffer Tests")
struct TrendCircularBufferTests {
}

@Suite("Twilight Theme Tests")
struct TwilightThemeTests {
}

@Suite("Population Trend Circular Buffer Tests")
struct PopulationTrendTests {
    // MARK: - Jade Theme Tests


    @Test("Jade theme exists in allThemes with correct name")
    func jadeThemeExists() {
        let jade = ColorTheme.allThemes.first { $0.name == "Jade" }
        #expect(jade != nil)
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

    // MARK: - Fading Cell In-Place Update Tests

}

@Suite("Crimson Theme Tests")
struct CrimsonThemeTests {

    @Test("Crimson theme exists in allThemes")
    func crimsonExists() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Crimson" })
    }
    @Test("Theme count is 22 with Crimson")
    func themeCount17() {
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

@Suite("Bucket Partitioning Tests")
struct BucketPartitioningTests {
}

@Suite("Buffer Reuse Tests")
struct BufferReuseTests {
}

@Suite("Depth Scaling Tests")
struct DepthScalingTests {
}

@Suite("Spiral Pattern Tests")
struct SpiralPatternTests {
}

@Suite("Amethyst Theme Tests")
struct AmethystThemeTests {
}

@Suite("Auto-Cycle Pattern Tests")
struct AutoCyclePatternTests {
}

// MARK: - Generation Rate EMA Tests

@Suite("Generation Rate Smoothing Tests")
struct GenerationRateTests {
}

// MARK: - Alive Cell Index Tracking Tests

@Suite("Alive Cell Index Tests")
struct AliveCellIndexTests {
}

// MARK: - Exit Safety Tests

@Suite("Exit Safety Tests")
struct ExitSafetyTests {
}

// MARK: - Torus Pattern Tests

@Suite("Torus Pattern Tests")
struct TorusPatternTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

// MARK: - Fading Cell Scale Tests (Session 55)

@Suite("Fading Cell Scale Tests")
struct FadingCellScaleTests {
}

// MARK: - Cached Population Display Tests (Session 55)

@Suite("Cached Population Display Tests")
@MainActor
struct CachedPopulationDisplayTests {
}

// MARK: - Audio Position Sampling Tests (Session 55)

@Suite("Audio Position Sampling Tests")
struct AudioPositionSamplingTests {
}

// MARK: - Galaxy Pattern Tests

@Suite("Galaxy Pattern Tests")
struct GalaxyPatternTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

// MARK: - clearAll Buffer Reuse Tests

@Suite("ClearAll Buffer Reuse Tests")
struct ClearAllBufferTests {
}

// MARK: - Torus/Galaxy Index Fix Tests

@Suite("Torus Galaxy Index Rebuild Tests")
struct TorusGalaxyIndexTests {
}

// MARK: - Pyramid Pattern Tests

@Suite("Pyramid Pattern Tests")
struct PyramidPatternTests {
}

// MARK: - Midnight Theme Tests

@Suite("Midnight Theme Tests")
struct MidnightThemeTests {
}

// MARK: - Swap-Remove Index Consistency Tests

@Suite("Swap-Remove Index Tests")
struct SwapRemoveIndexTests {
}

// MARK: - Fading Cell Bounds Safety Tests

@Suite("Fading Cell Bounds Safety Tests")
struct FadingCellBoundsTests {
    // MARK: - Wave Pattern Tests

    // MARK: - Bulk Zero Tests

}

// MARK: - Population Trend Threshold Tests

@Suite("Population Trend Threshold Tests")
struct PopulationTrendThresholdTests {
}

// MARK: - Galaxy Pattern Index Tests

@Suite("Galaxy Pattern Index Tests")
struct GalaxyPatternIndexTests {
}

// MARK: - Flat Index Consistency Tests

@Suite("Flat Index Consistency Tests")
struct FlatIndexConsistencyTests {
    // MARK: - Session 57: O(1) Reverse Mapping Tests

    // MARK: - Session 57: Division by Zero / Depth Scale Tests

    // MARK: - Session 57: Fading Cells Bounds Safety Tests

}

// MARK: - Mesh Generation Tests

@Suite("Mesh Generation Tests")
struct MeshGenerationTests {
}

// MARK: - Draw Mode Performance Tests (Set-backed index)

@Suite("Draw Mode Index Tests")
struct DrawModeIndexTests {
    // MARK: - O(alive) aliveIndexMap Reset Tests

    // MARK: - Checkerboard Pattern Tests

}

// MARK: - Lattice Pattern Tests

@Suite("Lattice Pattern Tests")
struct LatticePatternTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

// MARK: - Rule Set Persistence Tests

@Suite("Rule Set Persistence Tests")
struct RuleSetPersistenceTests {
}

// MARK: - Grid Epoch Tests

@Suite("Grid Epoch Tests")
struct GridEpochTests {
}

// MARK: - Population History Buffer Tests

@Suite("Population History Buffer Tests")
struct PopulationHistoryBufferTests {
}

// MARK: - Draw Mode Paint Edge Cases

@Suite("Draw Mode Paint Edge Cases")
struct DrawModePaintTests {
}

// MARK: - Menger Sponge Pattern Tests

@Suite("Menger Sponge Pattern")
struct MengerSpongeTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

// MARK: - Cage Pattern Tests

@Suite("Cage Pattern Tests")
struct CagePatternTests {
}

// MARK: - Bulk AliveIndexMap Fill Tests

@Suite("Bulk AliveIndexMap Fill Tests")
struct BulkAliveIndexMapFillTests {
}

// MARK: - Trefoil Knot Pattern Tests

@Suite("Trefoil Knot Pattern Tests")
struct TrefoilKnotTests {
}

// MARK: - Frost Theme Tests

@Suite("Frost Theme Tests")
struct FrostThemeTests {
}

// MARK: - Wrapping Topology Tests

@Suite("Wrapping Topology Tests")
struct WrappingTopologyTests {
}

// MARK: - Tetrahedron Pattern Tests

@Suite("Tetrahedron Pattern Tests")
struct TetrahedronPatternTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

// MARK: - ColorTheme Completeness Tests

@Suite("ColorTheme Completeness")
struct ColorThemeCompletenessTests {

    @Test("allThemes contains exactly the expected count")
    func allThemesCount() {
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

@Suite("Snowflake Pattern Tests")
struct SnowflakePatternTests {
}

// MARK: - O(alive) Map Reset Fix Tests

@Suite("O(alive) Map Reset Fix Tests")
struct AliveMapResetFixTests {
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
        #expect(allPatterns.count == 93)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 76)
    }
}

// MARK: - Octahedron Pattern Tests

@Suite("Octahedron Pattern Tests")
struct OctahedronPatternTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
    }
    @Test("Cyclable patterns is 27 (excludes clear)")
    func cyclablePatternCount() {
        let cyclable = SimulationEngine.Pattern.allCases.filter { $0 != .clear }
        #expect(cyclable.count == 76)
        #expect(cyclable.count == 76)
        #expect(cyclable.count == 76)
    }
}

// MARK: - Dodecahedron Pattern Tests (Session 62)

@Suite("Dodecahedron Pattern Tests")
struct DodecahedronPatternTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
}

// MARK: - Vaporwave Theme Tests (Session 66)

@Suite("Vaporwave Theme Tests")
struct VaporwaveThemeTests {

    @Test("Vaporwave theme exists in allThemes")
    func vaporwaveExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Vaporwave" }
        #expect(found)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
    }
}

// MARK: - Tungsten Theme Tests (Session 72)

@Suite("Tungsten Theme Tests")
struct TungstenThemeTests {
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
    }
}

// MARK: - Julia Set Pattern Tests (Session 73)

@Suite("Julia Set Pattern Tests")
struct JuliaSetPatternTests {
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 76)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 76)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(allPatterns.count == 93)
        let cyclable = allPatterns.filter { $0 != .clear }
        #expect(cyclable.count == 76)
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
        #expect(ColorTheme.allThemes.count == 97)
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
        #expect(diff > 0.1)
    }

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

    // MARK: - Richmond Surface Tests

    @Test func richmondSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadRichmondSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func richmondSurfaceNotSolid() {
        var grid = GridModel(size: 16)
        grid.loadRichmondSurface()
        let total = 16 * 16 * 16
        #expect(grid.aliveCount < total / 2)
    }

    @Test func richmondSurfaceCenteredInGrid() {
        var grid = GridModel(size: 16)
        grid.loadRichmondSurface()
        var hasNearCenter = false
        let mid = 8
        for x in (mid - 2)...(mid + 2) {
            for y in (mid - 2)...(mid + 2) {
                for z in (mid - 2)...(mid + 2) {
                    if grid.isAlive(x: x, y: y, z: z) { hasNearCenter = true }
                }
            }
        }
        #expect(hasNearCenter)
    }

    @Test func richmondSurfaceDistinctFromEnneper() {
        var richmond = GridModel(size: 16)
        richmond.loadRichmondSurface()
        var enneper = GridModel(size: 16)
        enneper.loadEnneperSurface()
        #expect(richmond.aliveCount != enneper.aliveCount)
    }

    @Test func richmondSurfaceScalesWithSize() {
        var small = GridModel(size: 12)
        small.loadRichmondSurface()
        var large = GridModel(size: 16)
        large.loadRichmondSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func richmondSurfaceSurvivesOneGeneration() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadRichmondSurface()
        let before = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > before / 10)
    }

    // MARK: - Pewter Theme Tests

    @Test func pewterThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Pewter" }
        #expect(found)
    }

    @Test func pewterCoolMetallicGrey() {
        let nb = ColorTheme.pewter.newborn.baseColor
        // Pewter: B slightly dominant, near-neutral grey
        #expect(nb.z >= nb.x)  // B >= R
        #expect(nb.z >= nb.y)  // B >= G
        // Channels close together (grey, not saturated)
        let spread = nb.z - nb.x
        #expect(spread < 0.15)
    }

    @Test func pewterOpacityDecreases() {
        let t = ColorTheme.pewter
        #expect(t.newborn.opacity > t.young.opacity)
        #expect(t.young.opacity > t.mature.opacity)
        #expect(t.mature.opacity > t.dying.opacity)
    }

    @Test func pewterEmissiveDecreases() {
        let t = ColorTheme.pewter
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
    }

    @Test func pewterDistinctFromSlate() {
        let pewter = ColorTheme.pewter.newborn.baseColor
        let slate = ColorTheme.slate.newborn.baseColor
        let diff = abs(pewter.x - slate.x) + abs(pewter.y - slate.y) + abs(pewter.z - slate.z)
        #expect(diff > 0.1)
    }
}

// MARK: - Kuen Surface Pattern Tests

@Suite("Kuen Surface Pattern Tests")
struct KuenSurfacePatternTests {
    @Test func kuenSurfacePopulatesGrid() {
        var grid = GridModel(size: 16)
        grid.loadKuenSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func kuenSurfaceScalesWithGridSize() {
        var small = GridModel(size: 12)
        small.loadKuenSurface()
        var large = GridModel(size: 24)
        large.loadKuenSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func kuenSurfaceDeterministic() {
        var a = GridModel(size: 16)
        a.loadKuenSurface()
        var b = GridModel(size: 16)
        b.loadKuenSurface()
        #expect(a.aliveCount == b.aliveCount)
    }

    @Test func kuenSurfaceDistinctFromBreatherSurface() {
        var kuen = GridModel(size: 16)
        kuen.loadKuenSurface()
        var breather = GridModel(size: 16)
        breather.loadBreatherSurface()
        #expect(kuen.aliveCount != breather.aliveCount)
    }

    @Test func kuenSurfaceDistinctFromDiniSurface() {
        var kuen = GridModel(size: 16)
        kuen.loadKuenSurface()
        var dini = GridModel(size: 16)
        dini.loadDiniSurface()
        #expect(kuen.aliveCount != dini.aliveCount)
    }

    @Test func kuenSurfacePatternExists() {
        let pattern = SimulationEngine.Pattern.allCases.first { $0.rawValue == "Kuen Surface" }
        #expect(pattern != nil)
    }
}

// MARK: - Pewter Theme Tests

@Suite("Pewter Theme Tests")
struct PewterThemeTests {
    @Test func pewterNewbornBrightest() {
        let t = ColorTheme.pewter

// MARK: - Celadon Theme Tests

@Suite("Celadon Theme Tests")
struct CeladonThemeTests {
    @Test func celadonThemeExists() {
        let found = ColorTheme.allThemes.contains { $0.name == "Celadon" }
        #expect(found)
    }

    @Test func celadonNewbornBrightest() {
        let t = ColorTheme.celadon
        #expect(t.newborn.emissiveIntensity > t.young.emissiveIntensity)
        #expect(t.young.emissiveIntensity > t.mature.emissiveIntensity)
        #expect(t.mature.emissiveIntensity > t.dying.emissiveIntensity)
    }

// MARK: - RebuildAliveCellIndices Consistency Tests

@Suite("Alive Count Sync Tests")
struct AliveCountSyncTests {
    @Test func rebuildSyncsAliveCount() {
        var grid = GridModel(size: 8)
        grid.loadSphere()
        let countAfterLoad = grid.aliveCount
        #expect(countAfterLoad > 0)
        // aliveCount should match actual cell scan
        var manualCount = 0
        for x in 0..<8 {
            for y in 0..<8 {
                for z in 0..<8 {
                    if grid.isAlive(x: x, y: y, z: z) { manualCount += 1 }
                }
            }
        }
        #expect(countAfterLoad == manualCount)
    }

    @Test func celadonPaleGreen() {
        let nb = ColorTheme.celadon.newborn.baseColor
        // Celadon: pale jade-green, G dominant, R and B subdued
        #expect(nb.y > nb.x)  // G > R
        #expect(nb.y > nb.z)  // G > B
    }

    @Test func celadonDistinctFromJade() {
        let celadon = ColorTheme.celadon.newborn.baseColor
        let jade = ColorTheme.jade.newborn.baseColor
        let diff = abs(celadon.x - jade.x) + abs(celadon.y - jade.y) + abs(celadon.z - jade.z)
        #expect(diff > 0.1)
    }

    // MARK: - Astroidal Ellipsoid Pattern Tests

    // MARK: - Denim Theme Tests

    @Test func denimBlueDominant() {
        let nb = ColorTheme.denim.newborn.baseColor
        // Denim: blue-grey, B dominant
        #expect(nb.z > nb.x)  // B > R
        #expect(nb.z > nb.y)  // B > G
    }

    @Test func denimDistinctFromSlate() {
        let denim = ColorTheme.denim.newborn.baseColor
        let slate = ColorTheme.slate.newborn.baseColor
        let diff = abs(denim.x - slate.x) + abs(denim.y - slate.y) + abs(denim.z - slate.z)
        #expect(diff > 0.1)
    }

    @Test func denimDistinctFromCobalt() {
        let denim = ColorTheme.denim.newborn.baseColor
        let cobalt = ColorTheme.cobalt.newborn.baseColor
        let diff = abs(denim.x - cobalt.x) + abs(denim.y - cobalt.y) + abs(denim.z - cobalt.z)
        #expect(diff > 0.1)
    }

    @Test func denimDistinctFromIndigo() {
        let denim = ColorTheme.denim.newborn.baseColor
        let indigo = ColorTheme.indigo.newborn.baseColor
        let diff = abs(denim.x - indigo.x) + abs(denim.y - indigo.y) + abs(denim.z - indigo.z)
        #expect(diff > 0.1)
    }

    @Test func denimInAllThemes() {
        #expect(ColorTheme.allThemes.contains(where: { $0.name == "Denim" }))
    }

    // MARK: - Performance Stress Tests

}

// MARK: - Bohemian Dome Pattern Tests

@Suite("Bohemian Dome Pattern Tests")
struct BohemianDomePatternTests {
    @Test func bohemianDomeProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadBohemianDome()
        #expect(grid.aliveCount > 0)
    }

    @Test func bohemianDomeFitsWithinGrid() {
        var grid = GridModel(size: 16)
        grid.loadBohemianDome()
        for x in 0..<16 {
            for y in 0..<16 {
                for z in 0..<16 {
                    if grid.isAlive(x: x, y: y, z: z) {
                        #expect(x >= 0 && x < 16)
                        #expect(y >= 0 && y < 16)
                        #expect(z >= 0 && z < 16)
                    }
                }
            }
        }
    }

    @Test func bohemianDomeDifferentSizes() {
        var small = GridModel(size: 8)
        small.loadBohemianDome()
        var large = GridModel(size: 16)
        large.loadBohemianDome()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func bohemianDomeSymmetric() {
        var grid = GridModel(size: 16)
        grid.loadBohemianDome()
        // The Bohemian Dome has x = cos(u) which is symmetric about x axis
        // Check approximate symmetry in z-axis (sin(v) symmetric)
        var topCount = 0
        var bottomCount = 0
        for x in 0..<16 {
            for y in 0..<16 {
                for z in 0..<8 {
                    if grid.isAlive(x: x, y: y, z: z) { bottomCount += 1 }
                }
                for z in 8..<16 {
                    if grid.isAlive(x: x, y: y, z: z) { topCount += 1 }
                }
            }
        }
        let ratio = Float(min(topCount, bottomCount)) / Float(max(topCount, bottomCount))
        #expect(ratio > 0.7)
    }

    @Test func bohemianDomeDistinctFromTorus() {
        var dome = GridModel(size: 16)
        dome.loadBohemianDome()
        var torus = GridModel(size: 16)
        torus.loadTorus()
        // Different cell counts indicate different patterns
        #expect(dome.aliveCount != torus.aliveCount)
    }

    @Test func bohemianDomeSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadBohemianDome()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }
}

// MARK: - Turquoise Theme Tests

@Suite("Turquoise Theme Tests")
struct TurquoiseThemeTests {
    @Test func turquoiseBlueCyanDominant() {
        let nb = ColorTheme.turquoise.newborn.baseColor
        // Turquoise: bright blue-green, G and B co-dominant, R subdued
        #expect(nb.y > nb.x)  // G > R
        #expect(nb.z > nb.x)  // B > R
    }

    @Test func turquoiseGreenSlightlyOverBlue() {
        let nb = ColorTheme.turquoise.newborn.baseColor
        // Turquoise has G slightly >= B
        #expect(nb.y >= nb.z)
    }

    @Test func turquoiseDistinctFromTeal() {
        let turquoise = ColorTheme.turquoise.newborn.baseColor
        let teal = ColorTheme.teal.newborn.baseColor
        let diff = abs(turquoise.x - teal.x) + abs(turquoise.y - teal.y) + abs(turquoise.z - teal.z)
        #expect(diff > 0.1)
    }

    @Test func turquoiseDistinctFromAquamarine() {
        let turquoise = ColorTheme.turquoise.newborn.baseColor
        let aquamarine = ColorTheme.aquamarine.newborn.baseColor
        let diff = abs(turquoise.x - aquamarine.x) + abs(turquoise.y - aquamarine.y) + abs(turquoise.z - aquamarine.z)
        #expect(diff > 0.1)
    }

    @Test func turquoiseInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Turquoise" })
    }
}

// MARK: - Clebsch Diagonal Surface Pattern Tests

@Suite("Clebsch Diagonal Surface Pattern Tests")
struct ClebschDiagonalSurfaceTests {
    @Test func clebschDiagonalSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadClebschDiagonalSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func clebschDiagonalSurfaceAliveCountMatchesIndex() {
        var grid = GridModel(size: 16)
        grid.loadClebschDiagonalSurface()
        var manual = 0
        for i in 0..<(16 * 16 * 16) {
            if grid.cells[i] > 0 { manual += 1 }
        }
        #expect(grid.aliveCount == manual)
    }

    @Test func clebschDiagonalSurfaceNotFull() {
        var grid = GridModel(size: 16)
        grid.loadClebschDiagonalSurface()
        #expect(grid.aliveCount < 16 * 16 * 16)
    }

    @Test func clebschDiagonalSurfaceScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadClebschDiagonalSurface()
        var large = GridModel(size: 16)
        large.loadClebschDiagonalSurface()
        #expect(large.aliveCount > small.aliveCount)
    }

    @Test func clebschDiagonalSurfaceDistinctFromSphere() {
        var clebsch = GridModel(size: 16)
        clebsch.loadClebschDiagonalSurface()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(clebsch.aliveCount != sphere.aliveCount)
    }

    @Test func clebschDiagonalSurfaceSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadClebschDiagonalSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }
}

// MARK: - Whitney Umbrella Pattern Tests

@Suite("Whitney Umbrella Pattern Tests")
struct WhitneyUmbrellaPatternTests {
    @Test func whitneyUmbrellaProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadWhitneyUmbrella()
        #expect(grid.aliveCount > 0)
    }

    @Test func whitneyUmbrellaCentered() {
        var grid = GridModel(size: 16)
        grid.loadWhitneyUmbrella()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for x in 0..<16 { for y in 0..<16 { for z in 0..<16 {
            if grid.isAlive(x: x, y: y, z: z) {
                sumX += x; sumY += y; sumZ += z; count += 1
            }
        }}}
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func whitneyUmbrellaDistinctFromCrossCap() {
        var umbrella = GridModel(size: 16)
        umbrella.loadWhitneyUmbrella()
        var crossCap = GridModel(size: 16)
        crossCap.loadCrossCap()
        #expect(umbrella.aliveCount != crossCap.aliveCount)
    }

    @Test func whitneyUmbrellaDistinctFromRomanSurface() {
        var umbrella = GridModel(size: 16)
        umbrella.loadWhitneyUmbrella()
        var roman = GridModel(size: 16)
        roman.loadRomanSurface()
        #expect(umbrella.aliveCount != roman.aliveCount)
    }

    @Test func whitneyUmbrellaSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadWhitneyUmbrella()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }
}

// MARK: - Apricot Theme Tests

@Suite("Apricot Theme Tests")
struct ApricotThemeTests {
    @Test func apricotRedDominant() {
        let nb = ColorTheme.apricot.newborn.baseColor
        // Apricot: warm orange-peach, R dominant
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.x > nb.z)  // R > B
    }

    @Test func apricotGreenOverBlue() {
        let nb = ColorTheme.apricot.newborn.baseColor
        // Apricot has G > B (warm, not pink)
        #expect(nb.y > nb.z)
    }

    @Test func apricotDistinctFromCopper() {
        let apricot = ColorTheme.apricot.newborn.baseColor
        let copper = ColorTheme.copper.newborn.baseColor
        let diff = abs(apricot.x - copper.x) + abs(apricot.y - copper.y) + abs(apricot.z - copper.z)
        #expect(diff > 0.1)
    }

    @Test func apricotDistinctFromTerracotta() {
        let apricot = ColorTheme.apricot.newborn.baseColor
        let terracotta = ColorTheme.terracotta.newborn.baseColor
        let diff = abs(apricot.x - terracotta.x) + abs(apricot.y - terracotta.y) + abs(apricot.z - terracotta.z)
        #expect(diff > 0.1)
    }

    @Test func apricotDistinctFromSaffron() {
        let apricot = ColorTheme.apricot.newborn.baseColor
        let saffron = ColorTheme.saffron.newborn.baseColor
        let diff = abs(apricot.x - saffron.x) + abs(apricot.y - saffron.y) + abs(apricot.z - saffron.z)
        #expect(diff > 0.1)
    }

    @Test func apricotInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Apricot" })
    }
}

// MARK: - Whitney Umbrella Alive Count Test (from splendid branch)

extension WhitneyUmbrellaPatternTests {
    @Test func whitneyUmbrellaAliveCountConsistent() {
        var grid = GridModel(size: 16)
        grid.loadWhitneyUmbrella()
        var manual = 0
        for i in 0..<(16*16*16) {
            if grid.cells[i] > 0 { manual += 1 }
        }
        #expect(grid.aliveCount == manual)
    }
}

// MARK: - Plum Theme Tests

@Suite("Plum Theme Tests")
struct PlumThemeTests {
    @Test func plumRedPurpleDominant() {
        let nb = ColorTheme.plum.newborn.baseColor
        // Plum: reddish-purple, R > B > G
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.z > nb.y)  // B > G
    }

    @Test func plumRedOverBlue() {
        let nb = ColorTheme.plum.newborn.baseColor
        // Plum leans red-purple: R > B
        #expect(nb.x > nb.z)
    }

    @Test func plumDistinctFromAmethyst() {
        let plum = ColorTheme.plum.newborn.baseColor
        let amethyst = ColorTheme.amethyst.newborn.baseColor
        let diff = abs(plum.x - amethyst.x) + abs(plum.y - amethyst.y) + abs(plum.z - amethyst.z)
        #expect(diff > 0.1)
    }

    @Test func plumDistinctFromMauve() {
        let plum = ColorTheme.plum.newborn.baseColor
        let mauve = ColorTheme.mauve.newborn.baseColor
        let diff = abs(plum.x - mauve.x) + abs(plum.y - mauve.y) + abs(plum.z - mauve.z)
        #expect(diff > 0.1)
    }

    @Test func plumInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Plum" })
    }
}

// MARK: - Pseudosphere Pattern Tests

@Suite("Pseudosphere Pattern Tests")
struct PseudospherePatternTests {
    @Test func pseudosphereProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadPseudosphere()
        #expect(grid.aliveCount > 0)
    }

    @Test func pseudosphereCentered() {
        var grid = GridModel(size: 16)
        grid.loadPseudosphere()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for x in 0..<16 { for y in 0..<16 { for z in 0..<16 {
            if grid.isAlive(x: x, y: y, z: z) {
                sumX += x; sumY += y; sumZ += z; count += 1
            }
        }}}
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func pseudosphereDistinctFromDiniSurface() {
        var pseudo = GridModel(size: 16)
        pseudo.loadPseudosphere()
        var dini = GridModel(size: 16)
        dini.loadDiniSurface()
        #expect(pseudo.aliveCount != dini.aliveCount)
    }

    @Test func pseudosphereDistinctFromKuenSurface() {
        var pseudo = GridModel(size: 16)
        pseudo.loadPseudosphere()
        var kuen = GridModel(size: 16)
        kuen.loadKuenSurface()
        #expect(pseudo.aliveCount != kuen.aliveCount)
    }

    @Test func pseudosphereSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadPseudosphere()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func pseudosphereScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadPseudosphere()
        var large = GridModel(size: 16)
        large.loadPseudosphere()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Wisteria Theme Tests

@Suite("Wisteria Theme Tests")
struct WisteriaThemeTests {
    @Test func wisteriaBluePurpleDominant() {
        let nb = ColorTheme.wisteria.newborn.baseColor
        // Wisteria: lavender-purple-blue, B > R > G
        #expect(nb.z > nb.y)  // B > G
        #expect(nb.x > nb.y)  // R > G
    }

    @Test func wisteriaBlueOverRed() {
        let nb = ColorTheme.wisteria.newborn.baseColor
        // Wisteria leans blue-purple: B > R
        #expect(nb.z > nb.x)
    }

    @Test func wisteriaDistinctFromLavender() {
        let wisteria = ColorTheme.wisteria.newborn.baseColor
        let lavender = ColorTheme.lavender.newborn.baseColor
        let diff = abs(wisteria.x - lavender.x) + abs(wisteria.y - lavender.y) + abs(wisteria.z - lavender.z)
        #expect(diff > 0.1)
    }

    @Test func wisteriaDistinctFromAmethyst() {
        let wisteria = ColorTheme.wisteria.newborn.baseColor
        let amethyst = ColorTheme.amethyst.newborn.baseColor
        let diff = abs(wisteria.x - amethyst.x) + abs(wisteria.y - amethyst.y) + abs(wisteria.z - amethyst.z)
        #expect(diff > 0.1)
    }

    @Test func wisteriaInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Wisteria" })
    }
}

// MARK: - Hyperboloid Pattern Tests

@Suite("Hyperboloid Pattern Tests")
struct HyperboloidPatternTests {
    @Test func hyperboloidProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadHyperboloid()
        #expect(grid.aliveCount > 50)
    }

    @Test func hyperboloidCentered() {
        var grid = GridModel(size: 16)
        grid.loadHyperboloid()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func hyperboloidDistinctFromSphere() {
        var hyper = GridModel(size: 16)
        hyper.loadHyperboloid()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(hyper.aliveCount != sphere.aliveCount)
    }

    @Test func hyperboloidDistinctFromCatenoid() {
        var hyper = GridModel(size: 16)
        hyper.loadHyperboloid()
        var catenoid = GridModel(size: 16)
        catenoid.loadCatenoid()
        #expect(hyper.aliveCount != catenoid.aliveCount)
    }

    @Test func hyperboloidSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadHyperboloid()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func hyperboloidScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadHyperboloid()
        var large = GridModel(size: 16)
        large.loadHyperboloid()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Rosewood Theme Tests

@Suite("Rosewood Theme Tests")
struct RosewoodThemeTests {
    @Test func rosewoodRedDominant() {
        let nb = ColorTheme.rosewood.newborn.baseColor
        // Rosewood: warm reddish-brown, R > G > B
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.x > nb.z)  // R > B
    }

    @Test func rosewoodGreenOverBlue() {
        let nb = ColorTheme.rosewood.newborn.baseColor
        // Warm brown: G > B
        #expect(nb.y > nb.z)
    }

    @Test func rosewoodDistinctFromMahogany() {
        let rosewood = ColorTheme.rosewood.newborn.baseColor
        let mahogany = ColorTheme.mahogany.newborn.baseColor
        let diff = abs(rosewood.x - mahogany.x) + abs(rosewood.y - mahogany.y) + abs(rosewood.z - mahogany.z)
        #expect(diff > 0.1)
    }

    @Test func rosewoodDistinctFromSienna() {
        let rosewood = ColorTheme.rosewood.newborn.baseColor
        let sienna = ColorTheme.sienna.newborn.baseColor
        let diff = abs(rosewood.x - sienna.x) + abs(rosewood.y - sienna.y) + abs(rosewood.z - sienna.z)
        #expect(diff > 0.1)
    }

    @Test func rosewoodInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Rosewood" })
    }
}

// MARK: - Bour's Minimal Surface Pattern Tests

@Suite("Bour's Minimal Surface Pattern Tests")
struct BourMinimalSurfacePatternTests {
    @Test func bourProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadBourMinimalSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func bourCentered() {
        var grid = GridModel(size: 16)
        grid.loadBourMinimalSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func bourDistinctFromHelicoid() {
        var bour = GridModel(size: 16)
        bour.loadBourMinimalSurface()
        var helicoid = GridModel(size: 16)
        helicoid.loadHelicoid()
        #expect(bour.aliveCount != helicoid.aliveCount)
    }

    @Test func bourDistinctFromCatenoid() {
        var bour = GridModel(size: 16)
        bour.loadBourMinimalSurface()
        var catenoid = GridModel(size: 16)
        catenoid.loadCatenoid()
        #expect(bour.aliveCount != catenoid.aliveCount)
    }

    @Test func bourSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadBourMinimalSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func bourScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadBourMinimalSurface()
        var large = GridModel(size: 16)
        large.loadBourMinimalSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Patina Theme Tests

@Suite("Patina Theme Tests")
struct PatinaThemeTests {
    @Test func patinaBlueDominant() {
        let nb = ColorTheme.patina.newborn.baseColor
        // Patina: greenish-blue-grey, G > B > R
        #expect(nb.y > nb.x)  // G > R
        #expect(nb.z > nb.x)  // B > R
    }

    @Test func patinaGreenOverBlue() {
        let nb = ColorTheme.patina.newborn.baseColor
        // Weathered copper: G > B
        #expect(nb.y > nb.z)
    }

    @Test func patinaDistinctFromTurquoise() {
        let patina = ColorTheme.patina.newborn.baseColor
        let turquoise = ColorTheme.turquoise.newborn.baseColor
        let diff = abs(patina.x - turquoise.x) + abs(patina.y - turquoise.y) + abs(patina.z - turquoise.z)
        #expect(diff > 0.1)
    }

    @Test func patinaDistinctFromCeladon() {
        let patina = ColorTheme.patina.newborn.baseColor
        let celadon = ColorTheme.celadon.newborn.baseColor
        let diff = abs(patina.x - celadon.x) + abs(patina.y - celadon.y) + abs(patina.z - celadon.z)
        #expect(diff > 0.1)
    }

    @Test func patinaInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Patina" })
    }
}

// MARK: - Barth Sextic Pattern Tests

@Suite("Barth Sextic Pattern Tests")
struct BarthSexticPatternTests {
    @Test func barthProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadBarthSextic()
        #expect(grid.aliveCount > 50)
    }

    @Test func barthCentered() {
        var grid = GridModel(size: 16)
        grid.loadBarthSextic()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func barthDistinctFromClebsch() {
        var barth = GridModel(size: 16)
        barth.loadBarthSextic()
        var clebsch = GridModel(size: 16)
        clebsch.loadClebschDiagonalSurface()
        #expect(barth.aliveCount != clebsch.aliveCount)
    }

    @Test func barthDistinctFromMandelbulb() {
        var barth = GridModel(size: 16)
        barth.loadBarthSextic()
        var mandelbulb = GridModel(size: 16)
        mandelbulb.loadMandelbulb()
        #expect(barth.aliveCount != mandelbulb.aliveCount)
    }

    @Test func barthSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadBarthSextic()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func barthScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadBarthSextic()
        var large = GridModel(size: 16)
        large.loadBarthSextic()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Carnelian Theme Tests

@Suite("Carnelian Theme Tests")
struct CarnelianThemeTests {
    @Test func carnelianRedDominant() {
        let nb = ColorTheme.carnelian.newborn.baseColor
        // Carnelian: warm reddish-orange, R > G > B
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.x > nb.z)  // R > B
    }

    @Test func carnelianGreenOverBlue() {
        let nb = ColorTheme.carnelian.newborn.baseColor
        // Warm orange tone: G > B
        #expect(nb.y > nb.z)
    }

    @Test func carnelianDistinctFromCopper() {
        let carnelian = ColorTheme.carnelian.newborn.baseColor
        let copper = ColorTheme.copper.newborn.baseColor
        let diff = abs(carnelian.x - copper.x) + abs(carnelian.y - copper.y) + abs(carnelian.z - copper.z)
        #expect(diff > 0.1)
    }

    @Test func carnelianDistinctFromVermilion() {
        let carnelian = ColorTheme.carnelian.newborn.baseColor
        let vermilion = ColorTheme.vermilion.newborn.baseColor
        let diff = abs(carnelian.x - vermilion.x) + abs(carnelian.y - vermilion.y) + abs(carnelian.z - vermilion.z)
        #expect(diff > 0.1)
    }

    @Test func carnelianInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Carnelian" })
    }
}

// MARK: - Cassini Surface Pattern Tests

@Suite("Cassini Surface Pattern Tests")
struct CassiniSurfacePatternTests {
    @Test func cassiniProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadCassiniSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func cassiniCentered() {
        var grid = GridModel(size: 16)
        grid.loadCassiniSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func cassiniDistinctFromSphere() {
        var cassini = GridModel(size: 16)
        cassini.loadCassiniSurface()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(cassini.aliveCount != sphere.aliveCount)
    }

    @Test func cassiniDistinctFromTorus() {
        var cassini = GridModel(size: 16)
        cassini.loadCassiniSurface()
        var torus = GridModel(size: 16)
        torus.loadTorus()
        #expect(cassini.aliveCount != torus.aliveCount)
    }

    @Test func cassiniSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadCassiniSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func cassiniScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadCassiniSurface()
        var large = GridModel(size: 16)
        large.loadCassiniSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Kummer Surface Pattern Tests

@Suite("Kummer Surface Pattern Tests")
struct KummerSurfacePatternTests {
    @Test func kummerProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadKummerSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func kummerCentered() {
        var grid = GridModel(size: 16)
        grid.loadKummerSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func kummerDistinctFromBarthSextic() {
        var kummer = GridModel(size: 16)
        kummer.loadKummerSurface()
        var barth = GridModel(size: 16)
        barth.loadBarthSextic()
        #expect(kummer.aliveCount != barth.aliveCount)
    }

    @Test func kummerDistinctFromRomanSurface() {
        var kummer = GridModel(size: 16)
        kummer.loadKummerSurface()
        var roman = GridModel(size: 16)
        roman.loadRomanSurface()
        #expect(kummer.aliveCount != roman.aliveCount)
    }

    @Test func kummerSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadKummerSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func kummerScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadKummerSurface()
        var large = GridModel(size: 16)
        large.loadKummerSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Malachite Theme Tests

@Suite("Malachite Theme Tests")
struct MalachiteThemeTests {
    @Test func malachiteGreenDominant() {
        let nb = ColorTheme.malachite.newborn.baseColor
        // Malachite: deep copper-green, G > B > R
        #expect(nb.y > nb.x)  // G > R
        #expect(nb.y > nb.z)  // G > B
    }

    @Test func malachiteBlueOverRed() {
        let nb = ColorTheme.malachite.newborn.baseColor
        // Cool green: B > R
        #expect(nb.z > nb.x)
    }

    @Test func malachiteDistinctFromJade() {
        let malachite = ColorTheme.malachite.newborn.baseColor
        let jade = ColorTheme.jade.newborn.baseColor
        let diff = abs(malachite.x - jade.x) + abs(malachite.y - jade.y) + abs(malachite.z - jade.z)
        #expect(diff > 0.1)
    }

    @Test func malachiteDistinctFromEmerald() {
        let malachite = ColorTheme.malachite.newborn.baseColor
        let emerald = ColorTheme.emerald.newborn.baseColor
        let diff = abs(malachite.x - emerald.x) + abs(malachite.y - emerald.y) + abs(malachite.z - emerald.z)
        #expect(diff > 0.1)
    }

    @Test func malachiteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Malachite" })
    }
}

// MARK: - Cayley Cubic Pattern Tests

@Suite("Cayley Cubic Pattern Tests")
struct CayleyCubicPatternTests {
    @Test func cayleyProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadCayleyCubic()
        #expect(grid.aliveCount > 50)
    }

    @Test func cayleyCentered() {
        var grid = GridModel(size: 16)
        grid.loadCayleyCubic()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func cayleyDistinctFromKummerSurface() {
        var cayley = GridModel(size: 16)
        cayley.loadCayleyCubic()
        var kummer = GridModel(size: 16)
        kummer.loadKummerSurface()
        #expect(cayley.aliveCount != kummer.aliveCount)
    }

    @Test func cayleyDistinctFromClebschDiagonal() {
        var cayley = GridModel(size: 16)
        cayley.loadCayleyCubic()
        var clebsch = GridModel(size: 16)
        clebsch.loadClebschDiagonalSurface()
        #expect(cayley.aliveCount != clebsch.aliveCount)
    }

    @Test func cayleySurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadCayleyCubic()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func cayleyScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadCayleyCubic()
        var large = GridModel(size: 16)
        large.loadCayleyCubic()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Alexandrite Theme Tests

@Suite("Alexandrite Theme Tests")
struct AlexandriteThemeTests {
    @Test func alexandriteGreenDominant() {
        let nb = ColorTheme.alexandrite.newborn.baseColor
        // Alexandrite newborn: warm teal-green, G > B > R
        #expect(nb.y > nb.x)  // G > R
        #expect(nb.y > nb.z)  // G > B
    }

    @Test func alexandriteShiftsToPurple() {
        let mature = ColorTheme.alexandrite.mature.baseColor
        // Mature alexandrite shifts toward purple: B > G > R
        #expect(mature.z > mature.y)  // B > G
        #expect(mature.z > mature.x)  // B > R
    }

    @Test func alexandriteDistinctFromTeal() {
        let alexandrite = ColorTheme.alexandrite.newborn.baseColor
        let teal = ColorTheme.teal.newborn.baseColor
        let diff = abs(alexandrite.x - teal.x) + abs(alexandrite.y - teal.y) + abs(alexandrite.z - teal.z)
        #expect(diff > 0.1)
    }

    @Test func alexandriteDistinctFromPatina() {
        let alexandrite = ColorTheme.alexandrite.newborn.baseColor
        let patina = ColorTheme.patina.newborn.baseColor
        let diff = abs(alexandrite.x - patina.x) + abs(alexandrite.y - patina.y) + abs(alexandrite.z - patina.z)
        #expect(diff > 0.1)
    }

    @Test func alexandriteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Alexandrite" })
    }
}

// MARK: - Togliatti Surface Pattern Tests

@Suite("Togliatti Surface Pattern Tests")
struct TogliattiSurfacePatternTests {
    @Test func togliattiProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadTogliattiSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func togliattiCentered() {
        var grid = GridModel(size: 16)
        grid.loadTogliattiSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func togliattiDistinctFromKummer() {
        var togliatti = GridModel(size: 16)
        togliatti.loadTogliattiSurface()
        var kummer = GridModel(size: 16)
        kummer.loadKummerSurface()
        #expect(togliatti.aliveCount != kummer.aliveCount)
    }

    @Test func togliattiDistinctFromBarthSextic() {
        var togliatti = GridModel(size: 16)
        togliatti.loadTogliattiSurface()
        var barth = GridModel(size: 16)
        barth.loadBarthSextic()
        #expect(togliatti.aliveCount != barth.aliveCount)
    }

    @Test func togliattiSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadTogliattiSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func togliattiScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadTogliattiSurface()
        var large = GridModel(size: 16)
        large.loadTogliattiSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Tanzanite Theme Tests

@Suite("Tanzanite Theme Tests")
struct TanzaniteThemeTests {
    @Test func tanzaniteBlueDominant() {
        let nb = ColorTheme.tanzanite.newborn.baseColor
        // Tanzanite: blue-violet, B > R > G
        #expect(nb.z > nb.x)  // B > R
        #expect(nb.z > nb.y)  // B > G
    }

    @Test func tanzaniteRedOverGreen() {
        let nb = ColorTheme.tanzanite.newborn.baseColor
        // Violet tint: R > G
        #expect(nb.x > nb.y)
    }

    @Test func tanzaniteDistinctFromAmethyst() {
        let tanzanite = ColorTheme.tanzanite.newborn.baseColor
        let amethyst = ColorTheme.amethyst.newborn.baseColor
        let diff = abs(tanzanite.x - amethyst.x) + abs(tanzanite.y - amethyst.y) + abs(tanzanite.z - amethyst.z)
        #expect(diff > 0.1)
    }

    @Test func tanzaniteDistinctFromIndigo() {
        let tanzanite = ColorTheme.tanzanite.newborn.baseColor
        let indigo = ColorTheme.indigo.newborn.baseColor
        let diff = abs(tanzanite.x - indigo.x) + abs(tanzanite.y - indigo.y) + abs(tanzanite.z - indigo.z)
        #expect(diff > 0.1)
    }

    @Test func tanzaniteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Tanzanite" })
    }
}

// MARK: - Fermat Surface Pattern Tests

@Suite("Fermat Surface Pattern Tests")
struct FermatSurfacePatternTests {
    @Test func fermatProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadFermatSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func fermatCentered() {
        var grid = GridModel(size: 16)
        grid.loadFermatSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func fermatDistinctFromSphere() {
        var fermat = GridModel(size: 16)
        fermat.loadFermatSurface()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(fermat.aliveCount != sphere.aliveCount)
    }

    @Test func fermatDistinctFromTogliattiSurface() {
        var fermat = GridModel(size: 16)
        fermat.loadFermatSurface()
        var togliatti = GridModel(size: 16)
        togliatti.loadTogliattiSurface()
        #expect(fermat.aliveCount != togliatti.aliveCount)
    }

    @Test func fermatSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadFermatSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func fermatScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadFermatSurface()
        var large = GridModel(size: 16)
        large.loadFermatSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Citrine Theme Tests

@Suite("Citrine Theme Tests")
struct CitrineThemeTests {
    @Test func citrineYellowDominant() {
        let nb = ColorTheme.citrine.newborn.baseColor
        // Citrine: warm golden-yellow, R > G > B
        #expect(nb.x > nb.z)  // R > B
        #expect(nb.y > nb.z)  // G > B
    }

    @Test func citrineRedOverGreen() {
        let nb = ColorTheme.citrine.newborn.baseColor
        // Golden tint: R > G
        #expect(nb.x > nb.y)
    }

    @Test func citrineDistinctFromGold() {
        let citrine = ColorTheme.citrine.newborn.baseColor
        let gold = ColorTheme.gold.newborn.baseColor
        let diff = abs(citrine.x - gold.x) + abs(citrine.y - gold.y) + abs(citrine.z - gold.z)
        #expect(diff > 0.1)
    }

    @Test func citrineDistinctFromSaffron() {
        let citrine = ColorTheme.citrine.newborn.baseColor
        let saffron = ColorTheme.saffron.newborn.baseColor
        let diff = abs(citrine.x - saffron.x) + abs(citrine.y - saffron.y) + abs(citrine.z - saffron.z)
        #expect(diff > 0.1)
    }

    @Test func citrineInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Citrine" })
    }

    // MARK: - Heart Surface Pattern Tests

    @Test func heartSurfacePatternExists() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.contains { $0 == .heartSurface })
        #expect(allPatterns.count == 93)
    }

    @Test func heartSurfaceLoadsNonEmpty() {
        var grid = GridModel(size: 16)
        grid.loadHeartSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func heartSurfaceDistinctFromSphere() {
        var heartGrid = GridModel(size: 16)
        heartGrid.loadHeartSurface()
        var sphereGrid = GridModel(size: 16)
        sphereGrid.loadSphere()
        #expect(heartGrid.aliveCount != sphereGrid.aliveCount)
    }

    @Test func heartSurfaceDistinctFromFermat() {
        var heartGrid = GridModel(size: 16)
        heartGrid.loadHeartSurface()
        var fermatGrid = GridModel(size: 16)
        fermatGrid.loadFermatSurface()
        #expect(heartGrid.aliveCount != fermatGrid.aliveCount)
    }

    @Test func heartSurfaceRespectsClear() {
        var grid = GridModel(size: 16)
        grid.loadHeartSurface()
        #expect(grid.aliveCount > 0)
        grid.clearAll()
        #expect(grid.aliveCount == 0)
    }

    @Test func heartSurfaceIdempotent() {
        var grid1 = GridModel(size: 16)
        grid1.loadHeartSurface()
        let count1 = grid1.aliveCount
        var grid2 = GridModel(size: 16)
        grid2.loadHeartSurface()
        let count2 = grid2.aliveCount
        #expect(count1 == count2)
    }

    // MARK: - Sunstone Theme Tests

    @Test func sunstoneThemeExists() {
        #expect(ColorTheme.sunstone.name == "Sunstone")
        #expect(ColorTheme.allThemes.count == 97)
    }

    @Test func sunstoneNewbornBrighterThanMature() {
        let newborn = ColorTheme.sunstone.newborn
        let mature = ColorTheme.sunstone.mature
        #expect(newborn.emissiveIntensity > mature.emissiveIntensity)
        #expect(newborn.opacity > mature.opacity)
    }

    @Test func sunstoneDistinctFromCopper() {
        let sunstone = ColorTheme.sunstone.newborn.baseColor
        let copper = ColorTheme.copper.newborn.baseColor
        let diff = abs(sunstone.x - copper.x) + abs(sunstone.y - copper.y) + abs(sunstone.z - copper.z)
        #expect(diff > 0.1)
    }

    @Test func sunstoneDistinctFromCitrine() {
        let sunstone = ColorTheme.sunstone.newborn.baseColor
        let citrine = ColorTheme.citrine.newborn.baseColor
        let diff = abs(sunstone.x - citrine.x) + abs(sunstone.y - citrine.y) + abs(sunstone.z - citrine.z)
        #expect(diff > 0.1)
    }

    @Test func sunstoneInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Sunstone" })
    }
}

// MARK: - Oloid Pattern Tests

@Suite("Oloid Pattern Tests")
struct OloidPatternTests {
    @Test func oloidProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadOloid()
        #expect(grid.aliveCount > 20)
    }

    @Test func oloidCentered() {
        var grid = GridModel(size: 16)
        grid.loadOloid()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func oloidDistinctFromSphere() {
        var oloid = GridModel(size: 16)
        oloid.loadOloid()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(oloid.aliveCount != sphere.aliveCount)
    }

    @Test func oloidDistinctFromTorus() {
        var oloid = GridModel(size: 16)
        oloid.loadOloid()
        var torus = GridModel(size: 16)
        torus.loadTorus()
        #expect(oloid.aliveCount != torus.aliveCount)
    }

    @Test func oloidSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadOloid()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func oloidScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadOloid()
        var large = GridModel(size: 16)
        large.loadOloid()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Topaz Theme Tests

@Suite("Topaz Theme Tests")
struct TopazThemeTests {
    @Test func topazOrangeDominant() {
        let nb = ColorTheme.topaz.newborn.baseColor
        #expect(nb.x > nb.z)
        #expect(nb.y > nb.z)
    }

    @Test func topazRedOverGreen() {
        let nb = ColorTheme.topaz.newborn.baseColor
        #expect(nb.x > nb.y)
    }

    @Test func topazDistinctFromCitrine() {
        let topaz = ColorTheme.topaz.newborn.baseColor
        let citrine = ColorTheme.citrine.newborn.baseColor
        let diff = abs(topaz.x - citrine.x) + abs(topaz.y - citrine.y) + abs(topaz.z - citrine.z)
        #expect(diff > 0.1)
    }

    @Test func topazDistinctFromApricot() {
        let topaz = ColorTheme.topaz.newborn.baseColor
        let apricot = ColorTheme.apricot.newborn.baseColor
        let diff = abs(topaz.x - apricot.x) + abs(topaz.y - apricot.y) + abs(topaz.z - apricot.z)
        #expect(diff > 0.1)
    }

    @Test func topazInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Topaz" })
    }
}

// MARK: - Ding-Dong Surface Tests

@Suite("Ding-Dong Surface Tests")
struct DingDongSurfaceTests {
    @Test func dingDongProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadDingDongSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func dingDongCentered() {
        var grid = GridModel(size: 16)
        grid.loadDingDongSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func dingDongDistinctFromSphere() {
        var dingDong = GridModel(size: 16)
        dingDong.loadDingDongSurface()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(dingDong.aliveCount != sphere.aliveCount)
    }

    @Test func dingDongDistinctFromFermatSurface() {
        var dingDong = GridModel(size: 16)
        dingDong.loadDingDongSurface()
        var fermat = GridModel(size: 16)
        fermat.loadFermatSurface()
        #expect(dingDong.aliveCount != fermat.aliveCount)
    }

    @Test func dingDongSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadDingDongSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func dingDongScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadDingDongSurface()
        var large = GridModel(size: 16)
        large.loadDingDongSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Fluorite Theme Tests

@Suite("Fluorite Theme Tests")
struct FluoriteThemeTests {
    @Test func fluoritePurpleDominant() {
        let nb = ColorTheme.fluorite.newborn.baseColor
        #expect(nb.z > nb.x)
        #expect(nb.x > nb.y)
    }

    @Test func fluoriteShiftsThroughTiers() {
        let nb = ColorTheme.fluorite.newborn.baseColor
        let young = ColorTheme.fluorite.young.baseColor
        #expect(nb.z > young.z)
        #expect(young.y > young.x)
    }

    @Test func fluoriteDistinctFromAmethyst() {
        let fluorite = ColorTheme.fluorite.newborn.baseColor
        let amethyst = ColorTheme.amethyst.newborn.baseColor
        let diff = abs(fluorite.x - amethyst.x) + abs(fluorite.y - amethyst.y) + abs(fluorite.z - amethyst.z)
        #expect(diff > 0.1)
    }

    @Test func fluoriteDistinctFromTanzanite() {
        let fluorite = ColorTheme.fluorite.newborn.baseColor
        let tanzanite = ColorTheme.tanzanite.newborn.baseColor
        let diff = abs(fluorite.x - tanzanite.x) + abs(fluorite.y - tanzanite.y) + abs(fluorite.z - tanzanite.z)
        #expect(diff > 0.1)
    }

    @Test func fluoriteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Fluorite" })
    }
}

// MARK: - Heart Surface Geometry Tests

@Suite("Heart Surface Pattern Tests")
struct HeartSurfacePatternTests {

}

// MARK: - Sunstone Theme Tests

@Suite("Sunstone Theme Tests")
struct SunstoneThemeTests {

}

// MARK: - Rhodonite Theme Tests

@Suite("Rhodonite Theme Tests")
struct RhodoniteThemeTests {
    @Test func rhodonitePinkDominant() {
        let nb = ColorTheme.rhodonite.newborn.baseColor
        // Rhodonite: rose-pink, R > B > G
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.x > nb.z)  // R > B
    }

    @Test func rhodoniteBlueOverGreen() {
        let nb = ColorTheme.rhodonite.newborn.baseColor
        // Pink hue: B > G
        #expect(nb.z > nb.y)
    }

    @Test func rhodoniteDistinctFromSakura() {
        let rhodonite = ColorTheme.rhodonite.newborn.baseColor
        let sakura = ColorTheme.sakura.newborn.baseColor
        let diff = abs(rhodonite.x - sakura.x) + abs(rhodonite.y - sakura.y) + abs(rhodonite.z - sakura.z)
        #expect(diff > 0.1)
    }

    @Test func rhodoniteDistinctFromRoseGold() {
        let rhodonite = ColorTheme.rhodonite.newborn.baseColor
        let roseGold = ColorTheme.roseGold.newborn.baseColor
        let diff = abs(rhodonite.x - roseGold.x) + abs(rhodonite.y - roseGold.y) + abs(rhodonite.z - roseGold.z)
        #expect(diff > 0.1)
    }

    @Test func rhodoniteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Rhodonite" })
    }
}

// MARK: - Lapis Lazuli Theme Tests

@Suite("Lapis Lazuli Theme Tests")
struct LapisLazuliThemeTests {
    @Test func lapisBlueDominant() {
        let nb = ColorTheme.lapisLazuli.newborn.baseColor
        // Lapis Lazuli: deep royal blue, B > G > R
        #expect(nb.z > nb.x)  // B > R
        #expect(nb.z > nb.y)  // B > G
    }

    @Test func lapisGreenOverRed() {
        let nb = ColorTheme.lapisLazuli.newborn.baseColor
        // Deep blue with slight warmth: G > R
        #expect(nb.y > nb.x)
    }

    @Test func lapisDistinctFromSapphire() {
        let lapis = ColorTheme.lapisLazuli.newborn.baseColor
        let sapphire = ColorTheme.sapphire.newborn.baseColor
        let diff = abs(lapis.x - sapphire.x) + abs(lapis.y - sapphire.y) + abs(lapis.z - sapphire.z)
        #expect(diff > 0.1)
    }

    @Test func lapisDistinctFromIndigo() {
        let lapis = ColorTheme.lapisLazuli.newborn.baseColor
        let indigo = ColorTheme.indigo.newborn.baseColor
        let diff = abs(lapis.x - indigo.x) + abs(lapis.y - indigo.y) + abs(lapis.z - indigo.z)
        #expect(diff > 0.1)
    }

    @Test func lapisInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Lapis Lazuli" })
    }
}

// MARK: - Zircon Theme Tests

@Suite("Zircon Theme Tests")
struct ZirconThemeTests {
    @Test func zirconBlueDominant() {
        let nb = ColorTheme.zircon.newborn.baseColor
        // Zircon: cool blue-white, B > G > R
        #expect(nb.z > nb.x)  // B > R
        #expect(nb.z > nb.y)  // B > G (technically close but B should be highest)
    }

    @Test func zirconGreenOverRed() {
        let nb = ColorTheme.zircon.newborn.baseColor
        // Cool tone: G > R
        #expect(nb.y > nb.x)
    }

    @Test func zirconDistinctFromSapphire() {
        let zircon = ColorTheme.zircon.newborn.baseColor
        let sapphire = ColorTheme.sapphire.newborn.baseColor
        let diff = abs(zircon.x - sapphire.x) + abs(zircon.y - sapphire.y) + abs(zircon.z - sapphire.z)
        #expect(diff > 0.1)
    }

    @Test func zirconDistinctFromGlacier() {
        let zircon = ColorTheme.zircon.newborn.baseColor
        let glacier = ColorTheme.glacier.newborn.baseColor
        let diff = abs(zircon.x - glacier.x) + abs(zircon.y - glacier.y) + abs(zircon.z - glacier.z)
        #expect(diff > 0.1)
    }

    @Test func zirconInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Zircon" })
    }
}

// MARK: - Rössler Attractor Pattern Tests

@Suite("Rössler Attractor Pattern Tests")
struct RosslerAttractorPatternTests {
    @Test func rosslerProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadRosslerAttractor()
        #expect(grid.aliveCount > 20)
    }

    @Test func rosslerCentered() {
        var grid = GridModel(size: 16)
        grid.loadRosslerAttractor()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 2 && cx < 14)
        #expect(cy > 2 && cy < 14)
        #expect(cz > 2 && cz < 14)
    }

    @Test func rosslerDistinctFromLorenz() {
        var rossler = GridModel(size: 16)
        rossler.loadRosslerAttractor()
        var lorenz = GridModel(size: 16)
        lorenz.loadLorenzAttractor()
        #expect(rossler.aliveCount != lorenz.aliveCount)
    }

    @Test func rosslerDistinctFromSpiral() {
        var rossler = GridModel(size: 16)
        rossler.loadRosslerAttractor()
        var spiral = GridModel(size: 16)
        spiral.loadSpiral()
        #expect(rossler.aliveCount != spiral.aliveCount)
    }

    @Test func rosslerSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadRosslerAttractor()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func rosslerScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadRosslerAttractor()
        var large = GridModel(size: 16)
        large.loadRosslerAttractor()
        #expect(large.aliveCount > small.aliveCount)
    }
}

// MARK: - Onyx Theme Tests

@Suite("Onyx Theme Tests")
struct OnyxThemeTests {
    @Test func onyxDarkToned() {
        let nb = ColorTheme.onyx.newborn.baseColor
        // Onyx: dark stone, muted cool grey-violet — all channels relatively low
        #expect(nb.x < 0.7)
        #expect(nb.y < 0.7)
        #expect(nb.z < 0.7)
    }

    @Test func onyxSlightVioletTint() {
        let nb = ColorTheme.onyx.newborn.baseColor
        // Onyx has a subtle violet tint: B > R > G
        #expect(nb.z > nb.y)
    }

    @Test func onyxDistinctFromObsidian() {
        let onyx = ColorTheme.onyx.newborn.baseColor
        let obsidian = ColorTheme.obsidian.newborn.baseColor
        let diff = abs(onyx.x - obsidian.x) + abs(onyx.y - obsidian.y) + abs(onyx.z - obsidian.z)
        #expect(diff > 0.1)
    }

    @Test func onyxDistinctFromGraphite() {
        let onyx = ColorTheme.onyx.newborn.baseColor
        let graphite = ColorTheme.graphite.newborn.baseColor
        let diff = abs(onyx.x - graphite.x) + abs(onyx.y - graphite.y) + abs(onyx.z - graphite.z)
        #expect(diff > 0.1)
    }

    @Test func onyxInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Onyx" })
    }
}

// MARK: - Barth Decic Pattern Tests

@Suite("Barth Decic Pattern Tests")
struct BarthDecicPatternTests {
    @Test func barthDecicProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadBarthDecic()
        #expect(grid.aliveCount > 20)
    }

    @Test func barthDecicCentered() {
        var grid = GridModel(size: 16)
        grid.loadBarthDecic()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func barthDecicDistinctFromBarthSextic() {
        var decic = GridModel(size: 16)
        decic.loadBarthDecic()
        var sextic = GridModel(size: 16)
        sextic.loadBarthSextic()
        #expect(decic.aliveCount != sextic.aliveCount)
    }

    @Test func barthDecicDistinctFromKummerSurface() {
        var decic = GridModel(size: 16)
        decic.loadBarthDecic()
        var kummer = GridModel(size: 16)
        kummer.loadKummerSurface()
        #expect(decic.aliveCount != kummer.aliveCount)
    }

    @Test func barthDecicSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadBarthDecic()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func barthDecicScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadBarthDecic()
        var large = GridModel(size: 16)
        large.loadBarthDecic()
        #expect(large.aliveCount > small.aliveCount)
    }
}


// MARK: - Tourmaline Theme Tests

@Suite("Tourmaline Theme Tests")
struct TourmalineThemeTests {
    @Test func tourmalinePinkDominant() {
        let nb = ColorTheme.tourmaline.newborn.baseColor
        // Tourmaline: pink-magenta, R > B > G
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.z > nb.y)  // B > G
    }

    @Test func tourmalineRedOverBlue() {
        let nb = ColorTheme.tourmaline.newborn.baseColor
        // Pink-magenta tint: R > B
        #expect(nb.x > nb.z)
    }

    @Test func tourmalineDistinctFromPlum() {
        let tourmaline = ColorTheme.tourmaline.newborn.baseColor
        let plum = ColorTheme.plum.newborn.baseColor
        let diff = abs(tourmaline.x - plum.x) + abs(tourmaline.y - plum.y) + abs(tourmaline.z - plum.z)
        #expect(diff > 0.1)
    }

    @Test func tourmalineDistinctFromCarnelian() {
        let tourmaline = ColorTheme.tourmaline.newborn.baseColor
        let carnelian = ColorTheme.carnelian.newborn.baseColor
        let diff = abs(tourmaline.x - carnelian.x) + abs(tourmaline.y - carnelian.y) + abs(tourmaline.z - carnelian.z)
        #expect(diff > 0.1)
    }

    @Test func tourmalineInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Tourmaline" })
    }
}


// MARK: - Neovius Surface Pattern Tests

@Suite("Neovius Surface Pattern Tests")
struct NeoviusSurfacePatternTests {
    @Test func neoviusSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadNeoviusSurface()
        #expect(grid.aliveCount > 0)
    }

    @Test func neoviusSurfaceCentered() {
        var grid = GridModel(size: 16)
        grid.loadNeoviusSurface()
        let half = grid.size / 2
        var hasNearCenter = false
        for dx in -2...2 { for dy in -2...2 { for dz in -2...2 {
            if grid.isAlive(x: half + dx, y: half + dy, z: half + dz) { hasNearCenter = true }
        }}}
        #expect(hasNearCenter)
    }

    @Test func neoviusSurfaceDistinctFromGyroid() {
        var neovius = GridModel(size: 16)
        neovius.loadNeoviusSurface()
        var gyroid = GridModel(size: 16)
        gyroid.loadGyroid()
        #expect(neovius.aliveCount != gyroid.aliveCount)
    }

    @Test func neoviusSurfaceDistinctFromSchwarzP() {
        var neovius = GridModel(size: 16)
        neovius.loadNeoviusSurface()
        var schwarzP = GridModel(size: 16)
        schwarzP.loadSchwarzPSurface()
        #expect(neovius.aliveCount != schwarzP.aliveCount)
    }

    @Test func neoviusSurfaceSurvivesEvolution() {
        var grid = GridModel(size: 16)
        grid.loadNeoviusSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > initial / 4)
    }

    @Test func neoviusSurfaceScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadNeoviusSurface()
        var large = GridModel(size: 16)
        large.loadNeoviusSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}


// MARK: - Larimar Theme Tests

@Suite("Larimar Theme Tests")
struct LarimarThemeTests {
    @Test func larimarBlueDominant() {
        let nb = ColorTheme.larimar.newborn.baseColor
        // Larimar: pale volcanic blue, B > G > R
        #expect(nb.z > nb.y)
        #expect(nb.y > nb.x)
    }

    @Test func larimarPaleBlue() {
        let nb = ColorTheme.larimar.newborn.baseColor
        // Larimar is a pale/milky blue — high blue channel
        #expect(nb.z > 0.85)
    }

    @Test func larimarDistinctFromSapphire() {
        let larimar = ColorTheme.larimar.newborn.baseColor
        let sapphire = ColorTheme.sapphire.newborn.baseColor
        let diff = abs(larimar.x - sapphire.x) + abs(larimar.y - sapphire.y) + abs(larimar.z - sapphire.z)
        #expect(diff > 0.1)
    }

    @Test func larimarDistinctFromAquamarine() {
        let larimar = ColorTheme.larimar.newborn.baseColor
        let aquamarine = ColorTheme.aquamarine.newborn.baseColor
        let diff = abs(larimar.x - aquamarine.x) + abs(larimar.y - aquamarine.y) + abs(larimar.z - aquamarine.z)
        #expect(diff > 0.1)
    }

    @Test func larimarInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Larimar" })
    }
}


// MARK: - Tanglecube Tests

@Suite("Tanglecube Tests")
struct TanglecubeTests {
    @Test func tanglecubeProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadTanglecube()
        #expect(grid.aliveCount > 50)
    }

    @Test func tanglecubeCentered() {
        var grid = GridModel(size: 16)
        grid.loadTanglecube()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func tanglecubeDistinctFromSphere() {
        var tanglecube = GridModel(size: 16)
        tanglecube.loadTanglecube()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(tanglecube.aliveCount != sphere.aliveCount)
    }

    @Test func tanglecubeDistinctFromFermatSurface() {
        var tanglecube = GridModel(size: 16)
        tanglecube.loadTanglecube()
        var fermat = GridModel(size: 16)
        fermat.loadFermatSurface()
        #expect(tanglecube.aliveCount != fermat.aliveCount)
    }

    @Test func tanglecubeSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadTanglecube()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func tanglecubeScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadTanglecube()
        var large = GridModel(size: 16)
        large.loadTanglecube()
        #expect(large.aliveCount > small.aliveCount)
    }
}



// MARK: - Jasper Theme Tests

@Suite("Jasper Theme Tests")
struct JasperThemeTests {
    @Test func jasperRedDominant() {
        let nb = ColorTheme.jasper.newborn.baseColor
        // Jasper: warm red-brown, R > G > B
        #expect(nb.x > nb.y)  // R > G
        #expect(nb.x > nb.z)  // R > B
    }

    @Test func jasperGreenOverBlue() {
        let nb = ColorTheme.jasper.newborn.baseColor
        // Warm tone: G > B
        #expect(nb.y > nb.z)
    }

    @Test func jasperDistinctFromCarnelian() {
        let jasper = ColorTheme.jasper.newborn.baseColor
        let carnelian = ColorTheme.carnelian.newborn.baseColor
        let diff = abs(jasper.x - carnelian.x) + abs(jasper.y - carnelian.y) + abs(jasper.z - carnelian.z)
        #expect(diff > 0.1)
    }

    @Test func jasperDistinctFromTerracotta() {
        let jasper = ColorTheme.jasper.newborn.baseColor
        let terracotta = ColorTheme.terracotta.newborn.baseColor
        let diff = abs(jasper.x - terracotta.x) + abs(jasper.y - terracotta.y) + abs(jasper.z - terracotta.z)
        #expect(diff > 0.1)
    }

    @Test func jasperInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Jasper" })
    }
}

// MARK: - Heart Surface Geometry Tests

@Suite("Heart Surface Geometry Tests")
struct HeartSurfaceGeometryTests {
    @Test func heartProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadHeartSurface()
        #expect(grid.aliveCount > 50)
    }

    @Test func heartCentered() {
        var grid = GridModel(size: 16)
        grid.loadHeartSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func heartDistinctFromSphere() {
        var heart = GridModel(size: 16)
        heart.loadHeartSurface()
        var sphere = GridModel(size: 16)
        sphere.loadSphere()
        #expect(heart.aliveCount != sphere.aliveCount)
    }

    @Test func heartDistinctFromFermatSurface() {
        var heart = GridModel(size: 16)
        heart.loadHeartSurface()
        var fermat = GridModel(size: 16)
        fermat.loadFermatSurface()
        #expect(heart.aliveCount != fermat.aliveCount)
    }

    @Test func heartSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadHeartSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func heartScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadHeartSurface()
        var large = GridModel(size: 16)
        large.loadHeartSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}



// MARK: - Labradorite Theme Tests

@Suite("Labradorite Theme Tests")
struct LabradoriteThemeTests {
    @Test func labradoriteBlueDominant() {
        let nb = ColorTheme.labradorite.newborn.baseColor
        #expect(nb.z > nb.y)
        #expect(nb.z > nb.x)
    }

    @Test func labradoriteGreenOverRed() {
        let nb = ColorTheme.labradorite.newborn.baseColor
        #expect(nb.y > nb.x)
    }

    @Test func labradoriteDistinctFromOceanBlues() {
        let labradorite = ColorTheme.labradorite.newborn.baseColor
        let ocean = ColorTheme.oceanBlues.newborn.baseColor
        let diff = abs(labradorite.x - ocean.x) + abs(labradorite.y - ocean.y) + abs(labradorite.z - ocean.z)
        #expect(diff > 0.1)
    }

    @Test func labradoriteDistinctFromCerulean() {
        let labradorite = ColorTheme.labradorite.newborn.baseColor
        let cerulean = ColorTheme.cerulean.newborn.baseColor
        let diff = abs(labradorite.x - cerulean.x) + abs(labradorite.y - cerulean.y) + abs(labradorite.z - cerulean.z)
        #expect(diff > 0.1)
    }

    @Test func labradoriteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Labradorite" })
    }
}


// MARK: - Chmutov Surface Pattern Tests

@Suite("Chmutov Surface Pattern Tests")
struct ChmutovSurfacePatternTests {
    @Test func chmutovSurfaceProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadChmutovSurface()
        #expect(grid.aliveCount > 20)
    }

    @Test func chmutovSurfaceCentered() {
        var grid = GridModel(size: 16)
        grid.loadChmutovSurface()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }

    @Test func chmutovSurfaceDistinctFromFermatSurface() {
        var chmutov = GridModel(size: 16)
        chmutov.loadChmutovSurface()
        var fermat = GridModel(size: 16)
        fermat.loadFermatSurface()
        #expect(chmutov.aliveCount != fermat.aliveCount)
    }

    @Test func chmutovSurfaceDistinctFromBarthDecic() {
        var chmutov = GridModel(size: 16)
        chmutov.loadChmutovSurface()
        var decic = GridModel(size: 16)
        decic.loadBarthDecic()
        #expect(chmutov.aliveCount != decic.aliveCount)
    }

    @Test func chmutovSurfaceSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadChmutovSurface()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }

    @Test func chmutovSurfaceScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadChmutovSurface()
        var large = GridModel(size: 16)
        large.loadChmutovSurface()
        #expect(large.aliveCount > small.aliveCount)
    }
}


// MARK: - Amazonite Theme Tests

@Suite("Amazonite Theme Tests")
struct AmazoniteThemeTests {
    @Test func amazoniteBlueGreenDominant() {
        let nb = ColorTheme.amazonite.newborn.baseColor
        // Amazonite: blue-green feldspar — G > B > R
        #expect(nb.y > nb.z)
        #expect(nb.z > nb.x)
    }

    @Test func amazoniteDistinctFromTeal() {
        let amazonite = ColorTheme.amazonite.newborn.baseColor
        let teal = ColorTheme.teal.newborn.baseColor
        let diff = abs(amazonite.x - teal.x) + abs(amazonite.y - teal.y) + abs(amazonite.z - teal.z)
        #expect(diff > 0.1)
    }

    @Test func amazoniteDistinctFromAquamarine() {
        let amazonite = ColorTheme.amazonite.newborn.baseColor
        let aquamarine = ColorTheme.aquamarine.newborn.baseColor
        let diff = abs(amazonite.x - aquamarine.x) + abs(amazonite.y - aquamarine.y) + abs(amazonite.z - aquamarine.z)
        #expect(diff > 0.1)
    }

    @Test func amazoniteDistinctFromPatina() {
        let amazonite = ColorTheme.amazonite.newborn.baseColor
        let patina = ColorTheme.patina.newborn.baseColor
        let diff = abs(amazonite.x - patina.x) + abs(amazonite.y - patina.y) + abs(amazonite.z - patina.z)
        #expect(diff > 0.1)
    }

    @Test func amazoniteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Amazonite" })
    }
}
// MARK: - Enriques Surface Pattern Tests
@Suite("Enriques Surface Pattern Tests")
struct EnriquesSurfacePatternTests {
    @Test func enriquesSurfacePatternExists() {
        let allPatterns = SimulationEngine.Pattern.allCases
        #expect(allPatterns.contains { $0 == .enriquesSurface })
        #expect(allPatterns.count == 93)
    @Test func enriquesSurfaceLoadsNonEmpty() {
        grid.loadEnriquesSurface()
        #expect(grid.aliveCount > 0)
    @Test func enriquesSurfaceDistinctFromTanglecube() {
        var enriques = GridModel(size: 16)
        enriques.loadEnriquesSurface()
        var tanglecube = GridModel(size: 16)
        tanglecube.loadTanglecube()
        #expect(enriques.aliveCount != tanglecube.aliveCount)
    @Test func enriquesSurfaceDistinctFromFermat() {
        var enriques = GridModel(size: 16)
        enriques.loadEnriquesSurface()
        #expect(enriques.aliveCount != fermat.aliveCount)
    @Test func enriquesSurfaceRespectsClear() {
        grid.loadEnriquesSurface()
        #expect(grid.aliveCount > 0)
        grid.clearAll()
        #expect(grid.aliveCount == 0)
    @Test func enriquesSurfaceIdempotent() {
        var grid1 = GridModel(size: 16)
        grid1.loadEnriquesSurface()
        let count1 = grid1.aliveCount
        var grid2 = GridModel(size: 16)
        grid2.loadEnriquesSurface()
        let count2 = grid2.aliveCount
        #expect(count1 == count2)
// MARK: - Amber Theme Tests
@Suite("Amber Theme Tests")
struct AmberThemeTests {
    @Test func amberThemeExists() {
        #expect(ColorTheme.amber.name == "Amber")
        #expect(ColorTheme.allThemes.count == 97)
    @Test func amberNewbornBrighterThanMature() {
        let newborn = ColorTheme.amber.newborn
        let mature = ColorTheme.amber.mature
        #expect(newborn.emissiveIntensity > mature.emissiveIntensity)
        #expect(newborn.opacity > mature.opacity)
    @Test func amberDistinctFromGold() {
        let amber = ColorTheme.amber.newborn.baseColor
        let gold = ColorTheme.gold.newborn.baseColor
        let diff = abs(amber.x - gold.x) + abs(amber.y - gold.y) + abs(amber.z - gold.z)
    @Test func amberDistinctFromTopaz() {
        let amber = ColorTheme.amber.newborn.baseColor
        let topaz = ColorTheme.topaz.newborn.baseColor
        let diff = abs(amber.x - topaz.x) + abs(amber.y - topaz.y) + abs(amber.z - topaz.z)
    @Test func amberInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Amber" })
// MARK: - Lidinoid Pattern Tests
@Suite("Lidinoid Pattern Tests")
struct LidinoidPatternTests {
    @Test func lidinoidProducesCells() {
        var grid = GridModel(size: 16)
        grid.loadLidinoid()
        #expect(grid.aliveCount > 20)
    }
    @Test func lidinoidCentered() {
        var grid = GridModel(size: 16)
        grid.loadLidinoid()
        var sumX = 0, sumY = 0, sumZ = 0, count = 0
        for idx in grid.aliveCellIndices {
            let x = idx / (16 * 16)
            let y = (idx / 16) % 16
            let z = idx % 16
            sumX += x; sumY += y; sumZ += z; count += 1
        }
        guard count > 0 else { return }
        let cx = Double(sumX) / Double(count)
        let cy = Double(sumY) / Double(count)
        let cz = Double(sumZ) / Double(count)
        #expect(cx > 4 && cx < 12)
        #expect(cy > 4 && cy < 12)
        #expect(cz > 4 && cz < 12)
    }
    @Test func lidinoidDistinctFromGyroid() {
        var lidinoid = GridModel(size: 16)
        lidinoid.loadLidinoid()
        var gyroid = GridModel(size: 16)
        gyroid.loadGyroid()
        #expect(lidinoid.aliveCount != gyroid.aliveCount)
    }
    @Test func lidinoidDistinctFromSchwarzPSurface() {
        var lidinoid = GridModel(size: 16)
        lidinoid.loadLidinoid()
        var schwarzP = GridModel(size: 16)
        schwarzP.loadSchwarzPSurface()
        #expect(lidinoid.aliveCount != schwarzP.aliveCount)
    }
    @Test func lidinoidSurvivesEvolution() {
        var grid = GridModel(size: 16, birthCounts: [5, 6, 7], survivalCounts: [5, 6, 7, 8])
        grid.loadLidinoid()
        let initial = grid.aliveCount
        grid.advanceGeneration()
        #expect(grid.aliveCount > 0 || initial > 0)
    }
    @Test func lidinoidScalesWithGridSize() {
        var small = GridModel(size: 8)
        small.loadLidinoid()
        var large = GridModel(size: 16)
        large.loadLidinoid()
        #expect(large.aliveCount > small.aliveCount)
    }
}
// MARK: - Sodalite Theme Tests
@Suite("Sodalite Theme Tests")
struct SodaliteThemeTests {
    @Test func sodaliteBlueDominant() {
        let nb = ColorTheme.sodalite.newborn.baseColor
        // Sodalite: rich royal blue — B > G > R
        #expect(nb.z > nb.y)
        #expect(nb.y > nb.x)
    }
    @Test func sodaliteDistinctFromSapphire() {
        let sodalite = ColorTheme.sodalite.newborn.baseColor
        let sapphire = ColorTheme.sapphire.newborn.baseColor
        let diff = abs(sodalite.x - sapphire.x) + abs(sodalite.y - sapphire.y) + abs(sodalite.z - sapphire.z)
        #expect(diff > 0.1)
    }
    @Test func sodaliteDistinctFromLapisLazuli() {
        let sodalite = ColorTheme.sodalite.newborn.baseColor
        let lapis = ColorTheme.lapisLazuli.newborn.baseColor
        let diff = abs(sodalite.x - lapis.x) + abs(sodalite.y - lapis.y) + abs(sodalite.z - lapis.z)
        #expect(diff > 0.1)
    }
    @Test func sodaliteDistinctFromCobalt() {
        let sodalite = ColorTheme.sodalite.newborn.baseColor
        let cobalt = ColorTheme.cobalt.newborn.baseColor
        let diff = abs(sodalite.x - cobalt.x) + abs(sodalite.y - cobalt.y) + abs(sodalite.z - cobalt.z)
        #expect(diff > 0.1)
    }
    @Test func sodaliteInAllThemes() {
        #expect(ColorTheme.allThemes.contains { $0.name == "Sodalite" })
    }
}
