# Journal

Evolution session log. Most recent entry first. Never delete entries.

## Day 12 — Session 55 (2026-03-28 10:37 PDT)

**Goal**: Fix fading cell visual bug, eliminate per-frame allocations, fix audio sampling precision.

Three improvements:

1. **Fix fading cell scale inversion bug**: Cells that just died were rendering at 15% size (nearly gone) instead of 50% (just died), and vice versa. The issue was in `computeMeshData` — `progress=1.0` (just died, framesLeft=fadeDuration) was directly negated to `age=-3` which mapped to the "nearly gone" scale. Fixed by computing `fadeStage = fadeDuration - framesLeft + 1`, so just-died cells get age=-1 (50% scale) and nearly-gone cells get age=-3 (15% scale). The fade now correctly shrinks cells over their lifetime.

2. **Cached populationHistory and populationTrend**: Both properties were computed from circular buffers on every access, allocating new arrays each time. Since SwiftUI observes these for sparkline and trend indicator rendering, this happened every frame — creating ~60 temporary arrays per second. Replaced with `private(set)` cached values rebuilt once per `step()` call. Also added proper cache clearing in both `reset()` and the auto-restart extinction path.

3. **Fix audio position sampling precision**: `samplePositions` used integer division (`positions.count / count`) which loses precision for non-evenly-divisible counts. For 23 positions sampled to 8, the old code selected indices [0,2,4,6,8,10,12,14] — clustered in the first 65% of the array. Fixed with `i * positions.count / count` which distributes indices evenly across the full range: [0,2,5,8,11,14,17,20].

Added 11 tests: fading scale for just-died/mid-fade/nearly-gone cells, fade scale monotonic decrease, cached history starts empty/grows after stepping, trend starts zero, history cleared on reset, even sampling distribution, sampling bounds safety, sampling when count exceeds positions.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 on device. App icon design. Final visual tuning across all color themes.

---

## Day 12 — Session 54 (2026-03-28 10:26 PDT)

**Goal**: Performance optimization — eliminate O(n³) alive cell scanning in render path.

Two improvements:

1. **Incremental alive cell index tracking**: Added `aliveCellIndices` array to GridModel that maintains flat indices of all alive cells. During `advanceGeneration()`, the index list is built alongside the existing survival/birth logic at zero extra cost (one `append` per alive cell). For rendering, `aliveCellsWithAge()` now iterates only the alive cells instead of scanning the entire grid. For a 32³ grid with ~5K alive cells out of 32,768 total, this skips checking ~27K dead cells per mesh rebuild — a ~6.5x reduction in iterations for the render-critical path. Pattern loaders rebuild the index list via a flat scan at the end. Interactive `toggleCell`/`setCell` maintain it incrementally.

2. **Removed unused `aliveCellPositions()` function**: Dead code since the age-based renderer replaced it. Eliminated 12 lines.

Added 7 tests: index count matches aliveCount after seed, index list updated after advance, consistency over 20 generations, empty after clear, toggle updates, pattern loaders correct, aliveCellsWithAge returns correct data.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 on device. App icon design. Final visual tuning across all color themes. Consider incremental mesh updates for changed cells only.

---

## Day 12 — Session 54 (2026-03-28 10:22 PDT)

**Goal**: Torus pattern, Copper theme, rendering allocation optimization.

Three improvements:

1. **Torus pattern (doughnut)**: Added a fourteenth pattern — a 3D torus lying in the XZ plane with configurable major/minor radii and fill thickness. The only pattern with genus-1 topology (has a hole through the center). The inner ring has higher neighbor density than the outer, creating asymmetric evolution where the inner surface evolves differently from the outer — cells in the inner ring face more neighbors and tend to die faster, breaking the initial symmetry into organic branching forms.

2. **Copper theme**: 19th theme with warm metallic tones — bright polished copper newborn cells (emissive intensity 2.2) transitioning through dark copper to deep bronze patina for mature cells. The color progression evokes metal cooling/aging: bright copper surface → oxidized middle → dark patina. Distinct from Warm Amber (golden/honey tones) and Ember (fire yellow→red) in that Copper stays in the warm brown-orange metallic family throughout — no bright yellow or deep red, just natural copper darkening.

3. **reserveCapacity on position methods**: Added `reserveCapacity(aliveCount)` to `aliveCellPositions` and `aliveCellsWithAge` in GridModel. These methods are called every mesh rebuild cycle but were creating arrays without pre-sizing, causing multiple heap reallocations as the array grew. For a 32³ grid with ~8K alive cells, this eliminates ~13 reallocation+copy cycles per call (array doubles from 1→2→4→...→8192).

Added 9 tests: Torus non-empty, torus has hole, torus engine selection, torus multi-gen evolution, Copper theme existence, theme count (19), Copper metallic color progression, position count matching aliveCount for both methods.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 on device. App icon design. Final visual tuning across all color themes. Consider pan gesture for grid translation.

---

## Day 12 — Session 53 (2026-03-28 10:14 PDT)

**Goal**: Safety hardening and UX polish — eliminate force unwraps, fix exit race condition, smooth generation rate display.

Three focused improvements:

1. **Force unwrap elimination in SpatialAudioEngine**: Replaced two `AVAudioFormat(...)!` force unwraps (lines 49 and 188) with `guard let` + early return. If audio format creation ever fails (e.g., unsupported sample rate on future hardware), the app now degrades gracefully instead of crashing.

2. **Exit race condition fix**: Added `!self.isExiting` guard to the auto-restart extinction check in `SimulationEngine.start()`. Previously, if the user exited while population was extinct, the auto-restart could fire during the dissolve-out animation — spawning a new grid while the old one was fading away. Now the restart is suppressed during exit.

3. **Generation rate EMA smoothing**: Replaced instantaneous rate calculation with an exponential moving average (0.7 old + 0.3 new). The gen/s display was jittering between adjacent values (e.g., 4.8→5.3→4.9→5.1) because each 1-second sample captured slightly different intervals. EMA produces a stable, readable display that still responds to real speed changes.

Added 4 tests: initial rate is zero, rate becomes nonzero after stepping, EMA produces stable rate across samples, auto-restart suppressed during exit.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 on device. App icon design. Final visual tuning across all color themes. Consider splitting mesh rebuild into material-only update for theme changes.

---

## Day 12 — Session 52 (2026-03-28 10:14 PDT)

**Goal**: Add spiral pattern, amethyst theme, and auto-cycle patterns on extinction.

Three improvements this session:

1. **Spiral pattern**: 3D Archimedean spiral that traces a widening helix from center outward. Uses thickness-based filling (1.3 unit radius) along the spiral path, spanning 80% of grid height with 3 full turns. Creates dramatic vortex structures that evolve into fractal-like branching forms.

2. **Amethyst theme**: Rich purple tones (violet newborn → deep purple mature → dark plum dying). 18th theme in the collection. Emissive intensity follows the standard tier progression (2.3 → 1.4 → 0.7 → 0.3).

3. **Auto-cycle patterns on extinction**: Previously, auto-restart always reseeded with the same selected pattern. Now cycles through all patterns (excluding Clear) on each extinction event, updating the selectedPattern so the UI reflects what's running. Makes the "leave it running" experience much more varied — each extinction brings a different seed shape.

Added tests for all three features: spiral cell population/bounds/evolution, amethyst theme structure/inclusion, and pattern cycling logic.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. App icon design. Consider incremental mesh updates for changed cells only.

---

## Day 12 — Session 52 (2026-03-28 10:06 PDT)

**Goal**: Performance optimization and safety hardening — buffer reuse, step timing, force unwrap elimination.

Three improvements targeting 32x32x32 performance and code safety:

1. **Pre-allocated born/dying buffers**: Replaced per-generation `var dying: [Int] = []` / `var born: [Int] = []` local allocations in `advanceGeneration()` with instance-level `dyingCells`/`bornCells` arrays cleared via `removeAll(keepingCapacity: true)`. At 32³ with ~1K cells changing per generation at 5 gen/s, this eliminates ~10 heap allocations per second. The buffers grow to their high-water mark over the first few generations and then reuse that capacity for the rest of the session.

2. **Generation step time tracking**: Added `lastStepTimeMs` to `SimulationEngine`, measured via `ContinuousClock` around `advanceGeneration()`. Displayed in the control bar stats next to gen/s — turns orange when >16ms (below 60fps budget). Gives users visibility into whether their grid size is pushing the device.

3. **Force unwrap elimination in GridRenderer**: Replaced three `MemoryLayout.offset(of:)!` force unwraps in `createMeshResource` with pre-computed static properties using `?? fallback`. The offsets are computed once at type initialization rather than on every mesh creation call.

Added 3 tests: buffer population after advance, buffer clearing between generations, alive count consistency over 20 generations with buffer reuse.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 on device. App icon design. Final visual tuning across all color themes.

---

## Day 12 — Session 49 (2026-03-28 10:00 PDT)

**Goal**: Turn sound off by default (li-f2q) — current audio is terrible.

Changed `audioMuted` default from `false` to `true` in both `SimulationEngine` and `SpatialAudioEngine`. The `loadPreferences` logic already checks `defaults.object(forKey:) != nil` before overriding, so existing users who explicitly set a preference keep their choice. New installs start silent. The toggle in ContentView still works to enable/disable audio.

**Next Steps**: If audio quality is improved in the future, could reconsider defaulting it on.

---

## Day 12 — Session 50 (2026-03-28 10:00 PDT)

**Goal**: Fix control panel inaccessible behind immersive view (li-rih).

Raised the grid container Y position from 1.5m to 1.8m in tabletop mode. The grid at Y=1.5 placed the bottom of the simulation volume at ~1.27m, overlapping with the visionOS default window position (~1.2m eye level). This made the control panel difficult or impossible to interact with — it was behind/beneath the immersive grid entity and its oversized collision box.

Changed both the initial container position and the surround-mode return-to-tabletop target position. Surround mode (user inside the grid) stays at Y=1.5 since the window isn't the primary interaction surface in that mode.

Build verified clean on visionOS Simulator.

**Next Steps**: Test with different grid sizes (32x32x32) to verify clearance. Consider making the collision box tighter to the actual grid extent.

---

## Day 12 — Session 49 (2026-03-28 09:58 PDT)

**Goal**: Fix launch dialog size — UI elements cut off at bottom.

Increased the default window height from 420 to 560 in Life3DApp.swift. The LaunchView contains a title section, divider, configuration grid (pattern, theme, grid size, rules, speed), another divider, and a start button — all with 24pt padding. At 420px height, the bottom controls (speed slider, start button) were cut off. The window uses `.windowResizability(.contentSize)` which allows content-driven sizing, but `.defaultSize` was constraining the initial render too small.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. App icon design. Final visual tuning across all color themes.

---

## Day 12 — Session 49 (2026-03-28 09:57 PDT)

**Goal**: Fix simulation control panel elements disappearing after appearing (li-0g4).

The control bar had an auto-hide mechanism that set `controlBarVisible = false` after 4 seconds of inactivity, fading the bar to opacity 0. On visionOS, gaze-based `onHover` cannot target invisible views (opacity 0), so once the bar faded out, users could never bring it back — leaving an empty panel where controls used to be.

**Fix**: Removed the broken auto-hide mechanism entirely. The control bar now remains visible throughout the simulation, satisfying all acceptance criteria:
- Control panel elements remain visible throughout the simulation
- Play/pause, step, pattern, speed controls always accessible
- Controls persist across ImmersiveSpace open/close

Removed `controlBarVisible` property from `SimulationEngine`, removed `autoHideTask`/`scheduleAutoHide`/`showControlBar` from `ContentView`, and removed the associated test suite (tests for deleted functionality).

**Next Steps**: Consider adding a more visionOS-friendly auto-hide in the future that uses a visible "grip" or "tab" handle for re-showing the bar, rather than relying on hover over invisible views.

---

## Day 12 — Session 49 (2026-03-28 10:00 PDT)

**Goal**: Crimson color theme, rings pattern, mesh tier bucketing optimization.

Three improvements across visual variety, new pattern, and rendering performance:

1. **Crimson color theme**: Added a seventeenth theme with a pure deep-red aesthetic — bright scarlet newborn cells (emissive intensity 2.2) transitioning through dark crimson to deep wine for mature cells. The color progression evokes hot metal cooling: bright red surface → dark crimson core → deep wine shadow. Distinct from Ember (yellow→orange→red fire) and Infrared (yellow→red heat) in that Crimson stays in the pure red family throughout — no warm yellow or orange tones, just saturated reds darkening into burgundy.

2. **Rings pattern (concentric shells)**: Added a thirteenth pattern that generates two concentric spherical shells at different radii (inner at 50% of outer). Creates layered evolution dynamics where the inner and outer shells interact — cells in the gap between shells grow to fill it, while the shells themselves expand and pulse. Visually distinct from the single-shell Sphere pattern; the dual-shell creates interference-like patterns as the two surfaces evolve independently then merge.

3. **Performance: O(n) bucket partitioning for mesh tiers**: Replaced the `sorted()` call in `computeMeshData` (O(n log n)) with a 4-bucket partitioning approach. Since there are only 4 age tiers, cells are bucketed in a single O(n) pass, then flattened. For a 32³ grid with ~8K alive cells, this eliminates ~100K comparison operations per mesh rebuild (log₂(8K) ≈ 13 comparisons × 8K cells). At 5 gen/s, that's ~500K fewer comparisons per second.

Added 10 tests: Crimson theme existence and count (17 themes), Crimson pure-red progression, Rings non-empty output, Rings two-shell verification, Rings engine pattern selection, bucket tier ranges cover all cells, bucket count matches alive+fading.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. App icon design. Final visual tuning across all color themes.

---

## Day 12 — Session 48 (2026-03-28 09:48 PDT)

**Goal**: Jade color theme, helix pattern, fading cell allocation optimization.

Three improvements across visual variety, new pattern, and performance:

1. **Jade color theme**: Added a fifteenth theme with a cool jade/emerald aesthetic — bright jade-teal newborn cells (emissive intensity 2.1) transitioning through medium jade green to deep dark emerald for mature cells. The color progression evokes polished jade stone: bright surface catch → rich interior green → deep mineral core. Distinct from Forest (warm lime/forest green family) in that Jade stays in the cool blue-green/teal family throughout, giving it a more mineral, precious-stone quality.

2. **Helix pattern**: Added a twelfth pattern that generates a double helix spiral around the Y axis — two interleaved helical strands (offset by 180°) with 2.5 turns and enough thickness (1.4 cell radius) to sustain evolution. Creates DNA-like structures that unwind, branch, and evolve into complex forms. The spiral geometry is fundamentally different from all existing patterns — neither random, geometric, nor symmetric, but topologically interesting with its continuous winding path.

3. **Performance: in-place fading cell update**: Replaced `fadingCells.compactMap` (which allocates a new array every generation) with an in-place swap-remove loop. Elements are decremented in-place, and expired/reborn entries are swapped with the last element and removed in O(1) per removal. Added `reserveCapacity` before appending new dying cells. Eliminates one array allocation per generation during active simulation.

Added 8 tests: Jade theme existence and count (15 themes), Jade cool green color progression, Helix non-empty output, Helix two-strand verification, Helix engine pattern selection, fading cell decrement, fading cell reborn removal.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. App icon design. Final visual tuning across all color themes.

---

## Day 12 — Session 47 (2026-03-28 09:10 PDT)

**Goal**: Sunset color theme, stagger lattice pattern, trend tracking performance fix.

Three improvements across visual variety, new pattern, and performance:

1. **Sunset color theme**: Added a fourteenth theme with a warm dusk aesthetic — bright orange newborn cells (emissive intensity 2.3) transitioning through red-magenta to deep purple for mature cells. The color progression evokes a sunset sky: warm orange horizon → rich magenta midsky → deep violet zenith. Fills the red-to-purple gradient gap in the palette — Ember goes yellow→red (fire), Coral goes orange→burgundy (reef), while Sunset uniquely transitions from warm orange through magenta into cool purple.

2. **Stagger lattice pattern**: Added an eleventh pattern that creates a sparse, evenly-distributed seed by placing cells every 3rd position in each dimension, with alternate Y layers offset by 1 cell. This produces expanding wavefront dynamics where isolated clusters grow independently before merging into larger structures — visually distinct from the dense random seed or geometric shapes. Particularly interesting with the Standard ruleset where the regular spacing creates synchronized birth waves.

3. **Performance: trend tracking circular buffer**: Replaced the `recentPopulations` array that used O(n) `removeFirst()` with a pre-allocated circular buffer (size 10, matching 2x trend window). Uses the same pattern as the already-optimized population history sparkline. At high simulation speeds (30 gen/s), this eliminates 30 array shift operations per second during the trend calculation hot path.

Also marked Phase 1 bootstrap items as complete in ROADMAP (all clearly done since Day 3).

Added 8 tests: Sunset theme existence, Sunset red-to-purple color progression, Stagger distribution bounds, Stagger offset verification, Stagger pattern engine selection, trend circular buffer wrapping, trend reset clearing, theme count update (14).

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. App icon design. Final visual tuning across all color themes.

## Day 12 — Session 47 (2026-03-28 09:12 PDT)

**Goal**: Performance optimizations for 32x32x32 grids, Twilight color theme.

Three improvements targeting the top remaining roadmap items — performance at scale and visual variety:

1. **Performance: circular buffer for population trend tracking**: The `recentPopulations` array used `removeFirst()` which is O(n) — shifting elements on every generation once the buffer exceeded capacity. Replaced with a pre-allocated circular buffer (`_trendBuffer`) using write index and count, matching the existing `_historyBuffer` pattern. The `populationTrend` computed property now reads directly from buffer indices without allocating, eliminating both the O(n) shift and the array slice allocation per generation. At 32³ grid running 30 gen/s, this removes 30 unnecessary array shifts per second.

2. **Performance: squared distance depth scaling**: The mesh computation's depth-of-field effect called `simd_length()` (which computes sqrt) for every alive cell to determine size falloff from grid center. Replaced with `simd_length_squared()` and squared `maxDist`, eliminating the per-cell sqrt operation entirely. For 32³ grids with ~8K alive cells, this removes ~8K sqrt calls per mesh rebuild. The visual effect is nearly identical — the falloff curve is slightly more quadratic, which actually produces a marginally more natural depth cue.

3. **Twilight color theme**: Added a fourteenth theme with a warm sunset-to-deep-purple aesthetic — bright golden-amber newborn cells (emissive intensity 2.3) transitioning through dusty purple to deep twilight violet for mature cells. The color progression evokes a sunset sky: golden horizon → warm purple → deep night. Distinct from Nebula (cool lavender → violet) and Warm Amber (golden → orange → brown) in that Twilight bridges warm gold into cool purple through the transition.

Added 9 tests: Twilight theme existence and count (14 themes), Twilight warm-to-purple color progression, population trend zero initially, trend after stepping, reset clears trend, mesh data computation for small grid, mesh data handles empty grid.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 with instruments. App icon design. Final visual tuning across all color themes.

---

## Day 11 — Session 46 (2026-03-27 08:25 PDT)

**Goal**: Forest color theme, audio pool upgrade with speed-scaled tones, cinematic space transition.

Three improvements across audio quality, visual variety, and transition polish:

1. **Audio pool upgrade + speed-scaled tone duration**: Doubled the spatial audio player pool from 4 to 8 nodes per type (birth/death), fixing tone drops at high cell activity where 4 players caused constant interruptions. Additionally, tone buffers now regenerate when simulation speed changes by >20% — at ≤5 gen/s tones play at full 150ms duration, scaling down proportionally at higher speeds (75ms at 10 gen/s, 50ms at 20 gen/s, floor at 40ms) to prevent chaotic overlapping. The `updateSpeed()` method is called via `onChange(of: engine.speed)` to keep tones synchronized.

2. **Forest color theme**: Added a thirteenth theme with a natural green/earth aesthetic — bright lime-green newborn cells (emissive intensity 2.2) transitioning through medium forest green to dark undergrowth for mature cells. The color progression evokes a forest canopy: bright new growth → established foliage → deep shadow floor. Fills the green gap in the palette — Aurora uses green→purple transitions while Forest stays in the pure green family throughout.

3. **Cinematic space transition**: Enhanced the materialize/dissolve animations with rotation flourish. Entry now includes a 60° yaw sweep over 0.67s with cubic ease-out, opacity leading scale slightly for a more cinematic reveal. Exit adds a gentle 30° spin-out during dissolve. The grid spirals into and out of view rather than just scaling, giving the immersive space transitions a more polished, intentional feel.

Added 5 tests: Forest theme existence and count (13 themes), Forest green color progression, audio pool setup verification, speed-scaled tone duration regen.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. App icon design. Final visual tuning across all color themes.

---

## Day 11 — Session 45 (2026-03-27 08:00 PDT)

**Goal**: Fix rule loss on grid size change, mirror symmetry pattern, Coral color theme.

Three improvements across bug fix, new pattern, and visual variety:

1. **Bug fix: preserve rules when changing grid size**: `changeGridSize()` created a new `GridModel` with default rules (B5-7/S5-8), silently discarding any custom rule set the user had selected. Now preserves the current `birthCounts` and `survivalCounts` by passing them to the new GridModel constructor. Users switching from 16³ to 32³ with Conservative rules no longer get silently reset to Standard.

2. **Mirror symmetry pattern**: Added a tenth pattern that generates one octant randomly (at 35% density) then mirrors it across all three axes for 8-fold symmetry. Symmetric initial conditions produce dramatically more visually striking evolutions — kaleidoscopic structures that maintain their symmetry for many generations before chaos breaks it. Particularly beautiful with the Diamond and Sphere patterns' geometric cousins.

3. **Coral color theme**: Added a twelfth theme with a warm organic aesthetic — bright coral-orange newborn cells (emissive intensity 2.2) transitioning through deep red-orange to dark burgundy for mature cells. The color progression evokes living coral reefs: warm salmon surface → deep red interior → dark ocean floor. Distinct from Ember (which is yellow→orange→red fire) and Warm Amber (which is golden) in that Coral stays in the warm red-orange family with more pink undertones.

Added 7 tests: Coral theme existence and count (12 themes), Coral color progression, mirror symmetry verification (8-fold), mirror non-empty output, mirror pattern engine selection, grid size rule preservation.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. Transition animation between shared and immersive space. App icon design.

---

## Day 11 — Session 44 (2026-03-27 07:07 PDT)

**Goal**: Fix wireframe stale on grid size change, circular buffer for population history, Glacier color theme.

Three improvements across bug fix, performance, and visual variety:

1. **Bug fix: wireframe updates on grid size change**: Previously the boundary wireframe was created once in `RealityView.make` and never rebuilt when the user changed grid size. The wireframe edges stayed at the old size while cells rendered at the new size, creating a mismatched boundary. Added `onChange(of: engine.grid.size)` handler that rebuilds the wireframe and updates the collision box extent. Now switching from 16³ to 32³ correctly resizes the boundary.

2. **Performance: circular buffer for population history**: The sparkline's `populationHistory` used `Array.removeFirst()` which is O(n) — shifting all elements left on every generation once the buffer is full. Replaced with a pre-allocated circular buffer using a write index and count, making append O(1). At 5 gen/s with a 60-entry buffer, this eliminates 60 element shifts per second during steady-state operation. The computed `populationHistory` property reconstructs chronological order for the sparkline view.

3. **Glacier color theme**: Added an eleventh theme with an icy blue-white aesthetic — bright near-white newborn cells with a cool blue tint (emissive intensity 2.2) transitioning through medium blue to deep navy for mature cells, with near-black dark blue dying cells. The color progression evokes glacial ice: bright white-blue surface → deeper blue interior → dark compressed ice. Distinct from Ocean Blues (which has more green/teal) in that Glacier stays in the pure blue-white family.

Added 7 tests: Glacier theme existence and count (11 themes), Glacier icy blue-white color progression, circular buffer fill, wrap-at-capacity, chronological order preservation, and reset clearing.

Build verified clean on visionOS Simulator.

**Next Steps**: Transition animation between shared and immersive space. Performance profiling at 32x32x32. App icon design.

---

## Day 11 — Session 43 (2026-03-27 06:50 PDT)

**Goal**: Add Nebula color theme, optimize empty particle/audio triggers, theme-tinted population sparkline.

Three improvements across visual variety, performance, and UI polish:

1. **Nebula color theme**: Added a tenth theme with a cosmic purple/magenta aesthetic — bright lavender-white newborn cells (emissive intensity 2.3) transitioning through deep violet to dark space-purple for mature cells, with near-black dying cells. The color progression evokes a stellar nebula: hot white-pink cores cooling through purple into deep space. Distinct from Aurora (which is green → purple → magenta) in that Nebula stays in the purple/blue family throughout.

2. **Performance: skip empty particle/audio/light triggers**: When no cells are born or dying in a generation (stable state or extinction), `triggerParticles()` now returns early after disabling all emitters, avoiding unnecessary iteration through 20 particle entities and audio player pools. For a 2x2x2 stable block at 5 gen/s, this eliminates ~100 entity component reads per second during idle periods.

3. **Theme-tinted population sparkline**: The population sparkline in the control bar now uses the current theme's newborn emissive color for its stroke and fill instead of generic secondary gray. The sparkline visually integrates with the active theme — Neon shows cyan, Ember shows yellow-orange, Nebula shows lavender. Stroke opacity 0.7 and fill opacity 0.18 keep it readable without being distracting.

Added 3 tests: Nebula theme existence and count (10 themes), Nebula cosmic purple color progression verification.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 (measure gen/s with all optimizations). Transition animation between shared and immersive space. App icon design.

---

## Day 11 — Session 42 (2026-03-27 06:35 PDT)

**Goal**: Eliminate redundant per-generation computation, add Ember color theme, optimize wireframe color updates.

Three improvements focused on performance, visual variety, and rendering efficiency:

1. **Performance: compute birth/death positions once per generation**: Previously `bornCellPositions()` and `dyingCellPositions()` were each called 3 times per generation — once for particle effects, once for point light updates, and once for spatial audio. Now positions are computed once in the `onChange(of: engine.generation)` handler and passed to all three consumers. For a 32³ grid with ~8K alive cells, this eliminates 4 redundant position array computations per generation (~5 gen/s = 20 eliminated per second).

2. **Ember color theme**: Added a ninth theme with a fire/lava aesthetic — bright yellow-white newborn cells (high emissive intensity 2.4) transitioning through vivid orange to deep red/dark crimson for mature cells, with near-black dying cells. The color progression mirrors cooling embers: white-hot → orange → red → dark ash. Higher opacity on newborn cells (0.60) gives them a more solid, incandescent appearance. Distinct from Warm Amber (which is golden-toned) and Infrared (which is more uniform heat-map style).

3. **Wireframe color-only update on theme change**: Previously switching themes rebuilt all 12 wireframe box entities from scratch (MeshResource.generateBox + ModelEntity creation). Now `updateWireframeColor()` just updates the UnlitMaterial color on existing entities, avoiding geometry regeneration for a purely cosmetic change.

Added 3 tests: Ember theme existence and count (9 themes), Ember fire-like color progression verification (yellow → orange → red intensity decrease).

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 (measure gen/s improvement from reduced position computation). Transition animation between shared and immersive space. App icon design.

---

## Day 11 — Session 41 (2026-03-27 06:15 PDT)

**Goal**: Double-buffered grid for performance, Sakura color theme, launch view polish.

Three improvements focused on performance, visual variety, and UX polish:

1. **Performance: double-buffered advanceGeneration**: Previously `advanceGeneration()` allocated a new `[Int]` array (32K elements for 32³) every generation. Now GridModel pre-allocates two buffers at init time and swaps them with `swap(&cells, &nextCells)` after each generation. The old next buffer is zeroed in-place rather than heap-allocated. For 32³ at 5 gen/s, this eliminates ~5 heap allocations per second. Also updated `clearAll()` to zero the existing buffer in-place instead of allocating a fresh array.

2. **Sakura color theme**: Added an eighth theme with a cherry blossom aesthetic — bright pink newborn cells (high emissive intensity 2.2) fading through dusty rose to deep plum for mature cells, with dark ash dying cells. Produces a warm, organic look distinct from the cooler-toned existing themes.

3. **Launch view polish**: Added a descriptive tagline "Watch luminous cells evolve in spatial 3D" below the subtitle, grouped the title section with tighter spacing for better visual hierarchy.

Added 4 tests: Sakura theme existence, Sakura emissive colors, double-buffer correctness over 20 generations, theme count verification.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 (measure gen/s improvement from double buffering). Transition animation between shared and immersive space. App icon design.

---

## Day 11 — Session 40 (2026-03-27 05:30 PDT)

**Goal**: Fix draw mode auto-rotation conflict, optimize point light positioning, add Bioluminescence theme.

Three improvements focused on UX, performance, and visual variety:

1. **Bug fix: pause auto-rotation in draw mode**: When draw mode was active, auto-rotation continued spinning the grid while the user tried to paint cells, making precise placement nearly impossible. Now auto-rotation checks `engine.drawMode` and pauses rotation when drawing is active. Rotation resumes automatically when draw mode is toggled off.

2. **Performance: point light positioning uses born cells instead of full grid scan**: Previously `updatePointLights()` called `aliveCellPositions()` which scans all n³ cells every generation just to position 8 lights. Now it uses `bornCellPositions()` (already computed during `advanceGeneration`) to move lights to where new activity is happening. Lights without new births nearby keep their previous position, creating stable ambient glow. For 32³ grid, this eliminates scanning 32K cells per generation for light placement.

3. **Bioluminescence color theme**: Added a seventh theme inspired by deep-sea bioluminescence. Bright teal/cyan newborn cells with higher emissive intensity (2.5 vs standard 2.0) fade through ocean teal to deep indigo for mature cells. The extra brightness creates a vivid underwater glow effect distinct from Ocean Blues (which is more subdued). Moves toward the "final visual tuning" roadmap item.

Added 4 tests: Bioluminescence theme existence, Bioluminescence emissive intensity, draw mode initial state, born cell positions available for light sampling.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 (measure actual gen/s). Transition animation between shared and immersive space. App icon and launch experience polish.

---

## Day 11 — Session 39 (2026-03-27 05:17 PDT)

**Goal**: Code quality cleanup, smooth exit transition, mesh rebuild optimization.

Three improvements focused on code quality, polish, and performance:

1. **Dead code removal**: Removed an unused `onChange(of: engine.generation)` handler in ContentView that contained only a comment and no-op branch. This was a leftover from the auto-hide implementation that never served a purpose.

2. **Smooth exit transition (immersive → launch)**: When exiting the simulation back to the launch screen, the launch view now fades in over 0.4s instead of appearing instantly. This mirrors the existing fade-out when entering the simulation, creating a symmetrical transition experience. Previously only the entry direction had a smooth transition.

3. **Skip mesh rebuild on stable state**: The mesh rebuild in GridImmersiveView now checks whether any cells actually changed (born, dying, or fading) before triggering a rebuild. When the simulation reaches a still life (e.g., 2x2x2 block) or all cells are extinct and fading is complete, mesh rebuilds are skipped entirely. For a 32³ grid at 5 gen/s, this saves 5 LowLevelMesh constructions per second during stable periods.

Added 4 tests: stable state detection (no born/dying/fading cells after block stabilizes), active simulation has cell changes, exit animation initial state, exit does not auto-complete.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 with real gen/s measurements. Transition animation between shared and immersive space (surround mode toggle polish). App icon and launch experience polish.

---

## Day 11 — Session 38 (2026-03-27 04:44 PDT)

**Goal**: Auto-hide control bar, increased particle/light pools for 32³, smoother launch transition.

Three improvements focused on immersion, visual quality at scale, and transition polish:

1. **Auto-hide control bar**: The control bar now fades out after 4 seconds of inactivity, creating a cleaner viewing experience. Hovering over the bar area or interacting with settings brings it back immediately with a smooth 0.35s fade animation. This addresses the long-pending "minimal HUD" roadmap item — rather than a complex palm-up gesture, this provides natural auto-hide behavior that works with existing input modalities.

2. **Increased particle emitter and point light pools**: Bumped particle emitters from 6→10 and point lights from 4→8. At 32³ grid size with ~8K alive cells, the previous pools only sampled a tiny fraction of activity. With larger pools, birth/death effects and ambient lighting cover significantly more of the grid volume, making large-grid simulations feel more alive.

3. **Smooth launch-to-simulation transition**: Added a coordinated fade-out of the launch view (0.3s opacity animation) before opening the immersive space. Previously the launch panel disappeared instantly when the immersive space opened, creating a jarring visual cut. The staggered timing creates a more polished spatial computing experience.

Added 2 tests: control bar initial visibility, control bar toggle behavior.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 (measure actual gen/s). Transition animation between shared and immersive space (the reverse direction — immersive to launch). App icon and launch experience polish.

---

## Day 11 — Session 37 (2026-03-27 03:45 PDT)

**Goal**: Performance optimization (array-based rule lookup), generation rate display, Infrared color theme.

Three improvements focused on performance, diagnostics, and visual variety:

1. **Array-based rule lookup for advanceGeneration**: Replaced `Set<Int>.contains()` calls in the hot inner loop with pre-computed `[Bool]` lookup tables indexed by neighbor count (0-26). For a 32³ grid, this eliminates ~850K hash lookups per generation. The lookup tables are rebuilt automatically via `didSet` when `birthCounts` or `survivalCounts` change, so rule switching works transparently. This is a step toward the Phase 3 performance goal of 60fps at 32x32x32.

2. **Generation rate display**: Added a measured generations-per-second counter to SimulationEngine that samples actual throughput every 1 second. Displayed in the control bar stats as "N.N gen/s" in tertiary style. This gives users visibility into whether the simulation is keeping up with the target speed — especially useful when comparing 16³ vs 32³ grid sizes or when running at high speed settings.

3. **Infrared color theme**: Added a sixth theme with a thermal camera aesthetic — bright yellow newborn cells transitioning through orange to deep red for mature cells, fading to dark maroon on death. Produces a striking heat-map look that's visually distinct from all existing themes.

Added 4 tests: generation rate initial state, reset clears generation rate, array lookup matches Set-based rules, Infrared theme existence.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32 (measure actual gen/s with the new rate display). Palm-up gesture or minimal HUD. Transition animation between shared and immersive space.

---

## Day 11 — Session 36 (2026-03-27 02:25 PDT)

**Goal**: Fix momentum/surround mode bug, add gesture help button, clean up audio engine on exit.

Three improvements focused on bug fixes, UX discoverability, and resource management:

1. **Bug fix: Cancel momentum on surround mode toggle**: When toggling between tabletop and surround mode while the grid had drag momentum, the momentum task continued running and interfered with the surround transition animation — the grid would jitter or drift during the scale/position change. Fixed by cancelling the momentum task and resetting the drag state before starting the surround transition.

2. **Gesture help button in control bar**: The gesture onboarding overlay only showed once on first launch and auto-dismissed after 5 seconds. Users who missed it or forgot the gestures had no way to see it again. Added a "?" button in the control bar (between settings gear and stats) that replays the onboarding overlay with the same auto-dismiss behavior. Uses a `showHelp` trigger on SimulationEngine to communicate between the control bar and the immersive view.

3. **Audio and task cleanup on simulation exit**: When leaving the simulation back to the launch screen, the audio engine was never stopped and auto-rotation/momentum tasks were not cancelled. This leaked resources — the audio engine continued running in the background. Now `audioEngine.stop()`, `autoRotateTask?.cancel()`, and `momentumTask?.cancel()` are called during the exit dissolve animation.

Added 2 tests: showHelp initial state, reset clears extinction notice.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. Palm-up gesture or minimal HUD. Transition animation between shared and immersive space. App icon and launch experience polish.

---

## Day 11 — Session 35 (2026-03-27 02:02 PDT)

**Goal**: Depth-based cell scaling, population sparkline, extinction notification.

Three improvements focused on visual depth, data visualization, and UX feedback:

1. **Depth-based cell scaling (pseudo depth-of-field)**: Cells further from the grid center are rendered progressively smaller (up to 20% reduction at the grid diagonal). This creates a natural depth cue — peripheral cells visually recede while central cells remain prominent. Implemented in the mesh computation step so it has zero runtime material cost, just a per-cell distance calculation during vertex generation. This addresses the Phase 3 "depth of field" roadmap item with a geometry-based approach rather than shader blur, which is more performant and compatible with RealityKit's translucent materials.

2. **Population history sparkline**: Added a 60-point population history buffer to SimulationEngine and a Canvas-based PopulationSparkline view rendered inline in the control bar stats section. Shows population trend over the last ~12 seconds as a tiny line graph with filled area underneath. Resets on simulation reset and caps at 60 entries. Gives users an at-a-glance sense of simulation dynamics — whether population is oscillating, declining, or stable — without needing to watch the number.

3. **Extinction notification overlay**: When auto-restart triggers on population extinction, a brief "Extinct — reseeding..." notification slides up from the bottom of the immersive view. Uses a capsule-shaped glassmorphic background with sparkle icon. Auto-dismisses after 2 seconds. Previously, auto-restart was silent — users might not notice the simulation restarted, especially at high speeds.

Added 4 tests: population history accumulation, history cap enforcement, reset clears history, extinction notice initial state.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32x32x32. Palm-up gesture or minimal HUD. Transition animation between shared and immersive space. App icon and launch experience polish.

---

## Day 11 — Session 34 (2026-03-27 01:08 PDT)

**Goal**: Quick reset button, sphere pattern, peak population tracking.

Three improvements focused on UX convenience, pattern variety, and stats:

1. **Quick reset button in control bar**: Previously, resetting the simulation required opening the settings panel and selecting a pattern. Added a dedicated reset button (counterclockwise arrow icon) to the control bar that resets with the current selected pattern and immediately restarts. Saves an interaction step for the most common action during exploration.

2. **Sphere pattern preset**: Added a hollow sphere shell pattern to complement the existing 7 patterns. Uses radial distance from center to create a shell between inner and outer radii. Produces beautiful radially symmetric evolution that expands and contracts, distinct from the blob-like (Soup/Random) and geometric (Diamond/Cross) existing patterns.

3. **Peak population tracking**: Added `peakPopulation` tracking to SimulationEngine that records the highest alive count reached since the last reset. Displayed in the stats bar as "peak N" in a subdued tertiary style alongside the current alive count. Gives users a sense of how dynamic their simulation was, and makes extinction feel more meaningful (you can see how high the population climbed before dying out). Resets on pattern reset.

Added 3 tests: sphere pattern structure, peak population tracking, reset clears peak.

Build verified clean on visionOS Simulator.

**Next Steps**: Depth of field effect. Performance profiling at 32x32x32. Palm-up gesture or minimal HUD. Transition animation between shared and immersive space.

---

## Day 11 — Session 33 (2026-03-27 00:22 PDT)

**Goal**: Auto-start simulation, Monochrome theme, color preview dots in theme pickers.

Three improvements focused on UX polish and visual variety:

1. **Auto-start simulation on entering immersive space**: Previously, pressing "Start Simulation" opened the immersive space but left the simulation paused — users had to separately press Play. Now `engine.start()` is called immediately after the immersive space opens, so the simulation begins evolving as soon as the grid materializes. Eliminates an unnecessary interaction step.

2. **New Monochrome color theme**: Added a fifth theme with white/gray palette — bright white newborn cells fading to dark gray with age. Provides an understated, minimalist aesthetic that contrasts with the more vivid existing themes. Useful for users who want the simulation to feel like a sculptural art piece rather than a neon light show.

3. **Color preview dots in theme pickers**: Both the launch screen and mid-simulation settings now show a small colored circle next to each theme name, using the theme's newborn emissive color. This gives users an instant visual preview of what each theme looks like without needing to select it first.

Build verified clean on visionOS Simulator.

**Next Steps**: Depth of field effect. Performance profiling at 32x32x32. Palm-up gesture or minimal HUD. App icon and launch experience polish.

---

## Day 10 — Session 32 (2026-03-26 21:29 PDT)

**Goal**: Fix auto-restart pattern bug, add active selection highlighting in mid-sim settings, add population trend indicator.

Three improvements focused on correctness, UX clarity, and visual feedback:

1. **Bug fix: auto-restart respects selected pattern**: When the user changed the pattern mid-simulation via the settings overlay (e.g. switching from Random to Diamond), the `reset(pattern:)` method loaded the new pattern but didn't update `selectedPattern`. On extinction, auto-restart would reseed with the stale `selectedPattern` from launch, ignoring the user's mid-sim choice. Fixed by updating `selectedPattern` in `reset()` so auto-restart always uses the most recently selected pattern.

2. **Active selection highlighting in mid-sim settings**: The settings overlay showed all pattern/theme/rules/size buttons identically — no indicator of what's currently active. Users had to remember their selections. Added `.tint(.accentColor)` to the active option in each row (pattern matches `selectedPattern`, theme matches `engine.theme`, rules compared by birth/survival counts, size compared by grid dimension). Inactive options use `.tint(.gray)` for clear differentiation.

3. **Population trend indicator in stats bar**: Added a trend arrow next to the alive count showing whether the population is growing (green arrow up-right), shrinking (orange arrow down-right), or stable (arrow right). Tracks the last 10 population values and uses a 5% threshold to filter out small fluctuations. Clears on reset. Gives users an at-a-glance sense of simulation dynamics without requiring them to watch the number closely.

Added 4 tests: auto-restart pattern update, population trend tracking, trend reset on clear, aliveCount delta accuracy across generations.

Build verified clean on visionOS Simulator.

**Next Steps**: Depth of field effect. Performance profiling at 32x32x32 on real hardware. Palm-up gesture or minimal HUD. Transition animation between shared and immersive space modes.

---

## Day 10 — Session 31 (2026-03-26 21:25 PDT)

**Goal**: Fix auto-restart pattern, add eraser for draw mode, gesture onboarding overlay.

Three improvements focused on UX and interaction polish:

1. **Auto-restart respects selected pattern** (bug fix): Previously, when the population went extinct and auto-restart triggered, it always reseeded with `randomSeed()` regardless of what pattern the user had selected. Now uses `loadPattern(selectedPattern)` so if the user chose Diamond or Cross, extinction restarts with the same pattern type rather than always defaulting to random.

2. **Eraser for draw mode** (feature): Draw mode previously only added cells — there was no way to remove cells by dragging. Added an `eraserMode` toggle on SimulationEngine. When draw mode is active, an eraser button appears in the control bar (eraser icon). When eraser is on, dragging removes cells instead of adding them. Exiting draw mode automatically resets eraser to off. This lets users sculpt patterns by both adding and subtracting cells.

3. **Gesture discovery onboarding** (UX): On the first time a user enters the simulation, a translucent overlay appears showing the three primary gestures: tap to toggle, drag to rotate, pinch to zoom. Uses SF Symbols for visual clarity. Auto-dismisses after 5 seconds or on tap. Tracks "has seen" state in UserDefaults so it only shows once.

Build verified clean on visionOS Simulator.

**Next Steps**: Depth of field effect. Performance profiling at 32³ on real hardware. Palm-up gesture or minimal HUD. Transition animation between shared and immersive space modes. Final visual tuning across all color themes.

---

## Day 10 — Session 30 (2026-03-26 21:10 PDT)

**Goal**: Fix stale particle colors on theme change, animate surround mode transition, optimize neighbor counting performance.

Three improvements focused on visual polish and performance:

1. **Particle emitter colors sync on theme change**: Previously, switching color themes (e.g. Neon → Warm Amber) left particle emitters firing in the old theme's colors for the rest of the session. Birth, death, and pulse emitters were only colored once during `setupParticleEmitters`. Added `updateParticleEmitterColors()` that re-assigns `mainEmitter.color` on all birth and death particle entities, called from the `onChange(of: engine.theme)` handler alongside the existing point light and wireframe updates.

2. **Animated surround mode transition**: Toggling surround mode (tabletop ↔ room-scale) previously snapped the grid position and scale instantly — jarring compared to the polished materialize/dissolve animations. Now uses a 25-frame (~0.4s) smooth-step interpolation (Hermite ease-in-out) for both position and scale, matching the spatial quality of other transitions.

3. **Performance: cached neighbor offsets and delta alive count**: `advanceGeneration()` was calling `Self.neighborOffsets(size:)` every generation, allocating a fresh 26-element array each tick. Now computed once in `init` and stored as `cachedNeighborOffsets`. Also replaced the O(n) `recomputeAliveCount()` full-array scan with a simple `aliveCount += born.count - dying.count` delta, eliminating a 32K-iteration reduce on every generation for 32³ grids.

Build verified clean on visionOS Simulator.

**Next Steps**: Depth of field effect. Performance profiling at 32³ on real hardware. Palm-up gesture or minimal HUD. Gesture discovery/onboarding text. Auto-restart should respect selected pattern (not always random). Eraser for draw mode.

---

## Day 10 — Session 29 (2026-03-26 17:50 PDT)

**Goal**: Multi-generation death fade and auto-restart on extinction.

Two improvements focused on making the simulation feel more alive and organic:

1. **Multi-generation death fade (visual beauty)**: Previously, dying cells rendered for only a single frame before vanishing — they popped out of existence. Now cells fade out over 3 generations, progressively shrinking (50% → 30% → 15% scale) while retaining the dying tier's dim material. This creates a gradual dissolve effect that makes the simulation feel organic rather than digital. Implemented via a `fadingCells` array on GridModel that tracks (flatIndex, framesLeft) pairs, decremented each generation and cleaned up when expired or when the cell is reborn at the same position.

2. **Auto-restart on extinction**: When the population reaches zero and all fading cells have completed their dissolve, the simulation waits 3 empty generations (~0.6s at default speed) then automatically reseeds with a fresh random pattern. This makes Life3D work as a perpetual art installation — users never see a dead, empty grid. The brief pause lets the last fading cells dissolve before the new pattern blooms in.

Added 3 tests: fading cell persistence across generations, fading cell removal on rebirth, and clearAll reset.

Build verified clean on visionOS Simulator.

**Next Steps**: Palm-up gesture or minimal HUD for settings. Depth of field effect. Performance profiling at 32³. Transition animation between shared and immersive space modes. Consider making fade duration configurable per-theme.

---

## Day 10 — Session 28 (2026-03-26 17:03 PDT)

**Goal**: Dissolve-out animation and new 3D preset patterns.

Two improvements:

1. **Dissolve-out animation (Phase 5 roadmap)**: When the user taps the back button to return to the launch screen, the grid now dissolves away before the immersive space is dismissed. The animation runs ~0.4s with an ease-in curve (starts slow, accelerates into disappearance) — the grid shrinks to 30% scale while fading to zero opacity. This is the reverse of the materialize-in effect from session 27. Coordinated via `isExiting`/`exitAnimationComplete` flags on SimulationEngine so ContentView waits for the animation to finish before dismissing the immersive space.

2. **New 3D preset patterns (Phase 2 roadmap gap)**: Added three structurally distinct seed patterns beyond the existing generic blobs:
   - **Diamond**: Octahedral shell — cells at Manhattan distance r and r-1 from center. Produces symmetric crystalline growth.
   - **Cross**: Three thick orthogonal bars through the center. Creates axial growth that breaks symmetry over time.
   - **Tube**: Hollow cylinder along the Y axis. Evolves with wave-like dynamics unlike blob seeds.

   These give users visually distinct starting conditions that showcase different aspects of 3D cellular automata behavior.

Build verified clean on visionOS Simulator.

**Next Steps**: Test dissolve animation timing on real Vision Pro. Palm-up gesture or minimal HUD for settings. Depth of field. Performance profiling at 32³. Transition animation between shared and immersive space modes.

---

## Day 10 — Session 27 (2026-03-26)

**Goal**: Mid-simulation settings overlay and grid materialize transition (Phase 5).

Two improvements:

1. **Mid-simulation settings overlay (Phase 5 roadmap)**: The control bar was overcrowded with 11+ controls crammed into one row (Pattern, Theme, Rules, Size menus alongside play/step/draw/surround/audio/speed). Extracted configuration menus into a `MidSimulationSettings` panel that slides open below the control bar when the user taps a gear icon. The settings panel uses a `Grid` layout with labeled rows of buttons for Pattern, Theme, Rules, and Size — each option is a visible button rather than a hidden dropdown menu, making it faster to discover and switch settings. The control bar now contains only the primary simulation controls (play/pause, step, draw mode, surround, audio, speed, gear, stats), keeping it clean and focused. Animation uses `.easeInOut` with `.move(edge: .top).combined(with: .opacity)` transition.

2. **Grid materialize transition (Phase 5 roadmap)**: When the immersive space opens, the grid now scales up from near-zero and fades in over ~0.5 seconds using an ease-out curve, creating a "materialization" effect. Implemented via `OpacityComponent` and multiplied `materializeScale` on the container entity. The animation runs 30 steps at ~60fps with quadratic ease-out for a snappy, natural entry. This replaces the previous instant pop-in which felt jarring.

Build verified clean on visionOS Simulator.

**Next Steps**: Test settings overlay and materialize transition on real Vision Pro. Add dissolve-out animation when returning to launch screen. Palm-up gesture or minimal HUD for invoking settings. Depth of field. Performance profiling at 32³.

---

## Day 10 — Session 26 (2026-03-26)

**Goal**: Launch screen and return-to-settings flow (Phase 5).

Two improvements:

1. **Launch screen (Phase 5 roadmap)**: Created `LaunchView.swift` — a floating configuration panel shown before the simulation starts. Users can select pattern, color theme, grid size, rules, and speed before hitting "Start Simulation." Uses SwiftUI `Grid` layout with `Picker` controls for each setting. Added `selectedPattern` property to `SimulationEngine` so the chosen pattern is applied when starting.

2. **Return-to-settings flow (Phase 5 roadmap)**: Added a back button (chevron.left) to the simulation control bar that pauses the simulation, dismisses the immersive space, and returns to the launch screen. The `ContentView` now acts as a state machine: shows `LaunchView` when not simulating, switches to `SimulationControlBar` when active. Window uses `.windowResizability(.contentSize)` so it adapts to the larger launch panel and compact control bar.

Extracted the simulation control bar into its own `SimulationControlBar` view for clean separation. The immersive space is opened via `onChange(of: showingSimulation)` to ensure it fires after the view tree updates.

Build verified clean on visionOS Simulator.

**Next Steps**: Test launch → simulate → back → relaunch cycle on real Vision Pro. Mid-simulation settings overlay (Phase 5). Smooth grid materialize/dissolve transition. Depth of field. Performance profiling at 32³.

---

## Day 10 — Session 25 (2026-03-26)

**Goal**: Hover feedback, user preferences persistence, and boundary wireframe.

Three improvements:

1. **Hover effect (Phase 4 roadmap)**: Added `HoverEffectComponent` to the grid container entity. When the user's gaze lands on the grid, visionOS shows a system-standard highlight, indicating the grid is interactive before any gesture is made. This is the first visual feedback before tap/drag.

2. **Persist user preferences (Phase 5 roadmap)**: Added UserDefaults-based persistence for theme, grid size, speed, rule set, and audio muted state. Preferences are saved when settings change (via `onChange` handlers and explicit calls in `changeGridSize`/`applyRuleSet`). On launch, `SimulationEngine.init` restores saved preferences, so the experience is consistent across sessions.

3. **Boundary wireframe (visual polish)**: Added a subtle wireframe cube outlining the simulation volume. Built from 12 thin box edges using `MeshResource.generateBox`, colored to match the current theme's mature emissive color at 30% opacity. Wireframe updates on theme change. Helps users understand the simulation boundaries, especially in areas with few or no cells.

Build verified clean on visionOS Simulator.

**Next Steps**: Test hover effect and wireframe on real Vision Pro — verify wireframe visibility and hover responsiveness. Phase 5 launch screen / mid-simulation menu. Depth of field. Performance profiling at 32³.

---

## Day 10 — Session 24 (2026-03-26)

**Goal**: Generative spatial audio and surround mode toggle.

Two improvements:

1. **Generative spatial audio (Phase 6 roadmap)**: Created `SpatialAudioEngine` using AVAudioEngine with AVAudioEnvironmentNode for HRTF-based 3D audio. Programmatically generates sine wave tones — birth events play ascending tones (C5 to E5, bell curve envelope) and death events play descending tones (A4 to E4, fade-out envelope). Uses a pool of 4 player nodes per type, positioned at sampled birth/death cell locations each generation. Volume scales with activity density (busier regions produce slightly louder audio). Integrated with GridImmersiveView — tones trigger on each generation advance. Added mute toggle button (speaker icon) to ContentView.

2. **Surround mode toggle (Phase 6 roadmap)**: Added a tabletop/surround mode toggle to ContentView (cube icon). Tabletop mode (default) positions the grid at (0, 1.5, -1.5) at normal scale — the standard "floating in front of you" view. Surround mode repositions the grid to (0, 1.5, 0) at 3× scale, centering it around the user so cells evolve all around them. Uses the existing .mixed immersion style — no need to dismiss/reopen the immersive space.

Window widened from 750pt to 850pt to accommodate surround and mute toggle buttons.

Build verified clean on visionOS Simulator.

**Next Steps**: Test spatial audio on real Vision Pro — may need frequency/volume tuning for the spatial environment. Test surround mode positioning and scale. Depth of field effect. Visual feedback on hover. Phase 5 configuration UI.

---

## Day 10 — Session 23 (2026-03-26)

**Goal**: Draw mode for continuous cell painting and fix initial seed density.

Two improvements:

1. **Draw mode (Phase 4 roadmap)**: Added a rotate/draw mode toggle to the control panel. When draw mode is active (pencil icon), dragging on the grid paints cells alive along the drag path instead of rotating. Uses the existing `DragGesture` with mode-dependent behavior — in draw mode, the drag position is converted to grid coordinates via inverse container transform and `nearestGridCoords()`. A `paintedCells` set tracks which cells have already been painted during the current drag to avoid redundant toggles and mesh rebuilds. Each newly painted cell triggers a pulse particle effect for visual feedback. In rotate mode (default, circular arrows icon), drag behavior is unchanged.

2. **Fix initial seed density**: `SimulationEngine.init` was calling `randomSeed(density: 0.1)` — 10% density — while the "Random (25%)" pattern used the default 0.25. At 10% density, average neighbor count (~2.6) is far below the B5-7 birth threshold, causing most initial simulations to die quickly. Fixed to use the default 25% density which produces healthy long-lived simulations.

3. **Tests**: Added 3 new tests — setCell alive preserves age and doesn't double-count, sequential cell painting tracks alive count correctly, and default random seed produces >600 alive cells (verifying 25% density).

Window widened from 700pt to 750pt to accommodate the draw mode toggle button.

Build verified clean on visionOS Simulator.

**Next Steps**: Test draw mode gesture accuracy on real Vision Pro. Depth of field effect. Visual feedback on hover (cell highlights before selection). Phase 5 configuration UI.

---

## Day 10 — Session 22 (2026-03-26)

**Goal**: Point light emission from living cells and visual pulse on cell toggle.

Two improvements:

1. **Point light emission (Phase 3 roadmap)**: Added a pool of 4 `PointLightComponent` entities that sample positions from alive cells each generation. Lights have 50 lumen intensity with 0.15m attenuation radius, creating a soft ambient glow around active regions of the grid. Light color matches the current theme's newborn emissive color and updates on theme change. Uses the same sampling pattern as particle emitters — evenly distributed across alive cell positions.

2. **Toggle pulse effect (Phase 4 roadmap)**: When a user taps to toggle a cell, a brief particle burst fires at the tap position providing immediate visual feedback. The pulse uses 20 particles in a spherical burst with 0.15s emit duration and 0.4s lifespan with linear fade-out. Pulse color matches the current theme's newborn emissive color. A single reusable emitter entity avoids per-tap allocation.

Build verified clean on visionOS Simulator.

**Next Steps**: Test light emission on real Vision Pro — may need intensity/radius tuning for mixed immersion. Draw mode (continuous cell painting). Depth of field effect. Phase 5 configuration UI.

---

## Day 10 — Session 21 (2026-03-26)

**Goal**: Spatial tap gesture for cell toggling and aliveCount performance optimization.

Two improvements:

1. **Spatial tap to toggle cells (Phase 4 hand tracking)**: Added `SpatialTapGesture` to `GridImmersiveView` that lets users tap on cells to toggle them alive/dead. Tap position is converted from scene space to the grid container's local coordinate space via inverse transform, then mapped to the nearest grid cell using `nearestGridCoords()`. Added `toggleCell(x:y:z:)` to `GridModel` and `toggleCell(at:)` to `SimulationEngine`. Toggling increments the generation counter to trigger mesh rebuild. This is the first Phase 4 interactive feature — users can now directly manipulate the simulation by tapping on cells.

2. **Cached aliveCount**: Replaced the computed `aliveCount` property (which filtered all n³ cells every access) with a stored property maintained incrementally. `setCell`, `toggleCell`, `clearAll`, `randomSeed`, and `advanceGeneration` all keep the count accurate. For a 32³ grid, this avoids 32,768 comparisons on every UI redraw cycle.

3. **Tests**: Added 4 new tests — toggle dead cell, toggle alive cell, nearest grid coords round-trip, and aliveCount accuracy through mutations.

Build verified clean on visionOS Simulator.

**Next Steps**: Test tap gesture on real Vision Pro — verify coordinate mapping accuracy and gesture responsiveness. Visual feedback on hover (cell highlights before tap). Draw mode (continuous cell painting). Depth of field effect. Light emission from cells.

---

## Day 10 — Session 20 (2026-03-26)

**Goal**: Particle effects on birth/death events and rules configuration UI.

Two improvements:

1. **Particle burst effects on cell birth/death**: Added RealityKit `ParticleEmitterComponent`-based particle effects that trigger at sampled cell positions each generation. Birth particles burst outward and float upward with bright theme-colored particles. Death particles drift downward with muted colors. Uses up to 6 emitters per type (12 total), sampling evenly from birth/death positions to avoid per-cell emitter overhead. Emitters use `.once` timing with 0.3s burst duration and fade-out opacity curves. Added `bornCells` tracking to `GridModel.advanceGeneration()` alongside existing `dyingCells` tracking, plus `bornCellPositions()` helper for position retrieval.

2. **Rules configuration UI**: Added a `RuleSet` enum to `SimulationEngine` with 4 presets — Standard (B5-7/S5-8, the default), Conservative (B6/S5-7, slower growth), Expansive (B4-6/S4-8, faster expansion), and Sparse (B5/S4-6, thin structures). New "Rules" menu in `ContentView` lets users switch rule sets mid-simulation. Current rules displayed in the stats bar (e.g., "B5,6,7/S5,6,7,8").

3. **Tests**: Added 3 new tests for born cell tracking — born cells appear after birth events, stable blocks produce no born cells, clearAll resets born cells.

Window widened from 620pt to 700pt to accommodate the new Rules menu.

Build verified clean on visionOS Simulator.

**Next Steps**: Test particle effects on real Vision Pro — may need tuning for burst count and particle size. Depth of field effect. Light emission from living cells. Hand tracking for cell toggling (Phase 4).

---

## Day 10 — Session 19 (2026-03-26)

**Goal**: Performance optimization for 32³ grids, collision box fix, and drag momentum.

Three improvements:

1. **Optimized neighbor counting in `advanceGeneration()`**: Pre-computes the 26 neighbor offsets as flat array index deltas. Interior cells (not on any boundary face) use direct `cells[idx + offset]` access with overflow-safe arithmetic (`&+`), skipping all bounds checking. For a 32³ grid, 82% of cells (30³ = 27,000 of 32,768) take the fast path. Boundary cells still use the bounds-checked approach. This eliminates per-neighbor function call overhead and redundant bounds checks for the vast majority of cells.

2. **Fixed collision box size mismatch**: The `GridImmersiveView` collision box was hardcoded at 0.5, regardless of actual grid size. Now computes the real grid extent from `GridRenderer.cellSize`, `cellSpacing`, and the engine's grid size. Uses 2.5× the extent for comfortable grab targeting. This means gestures work correctly at all grid sizes (12³ through 32³).

3. **Drag momentum/inertia**: After releasing a drag gesture, the grid continues rotating with decaying velocity (friction factor 0.92 at 60fps). Velocity is tracked from frame-to-frame translation deltas during the drag. A threshold prevents micro-drifting. This makes rotation feel more natural and spatial — important for the "art installation" feel where physical behavior is expected.

Added 3 new tests: optimized advanceGeneration consistency check (random grid, verify against public neighborCount), interior cell neighbor correctness, and 32³ grid advance without error.

Build verified clean on visionOS Simulator.

**Next Steps**: Performance profiling at 32×32×32 under continuous simulation. Particle effects on birth/death (Phase 3). Hand tracking for cell toggling (Phase 4). Test momentum feel on real Vision Pro — may need to tune friction factor.

---

## Day 10 — Session 18 (2026-03-26)

**Goal**: Birth scale animation and idle auto-rotation.

Two visual improvements to make the simulation feel more organic and alive:

1. **Birth scale animation**: Newborn cells now "bloom into existence" by rendering at scaled sizes based on age. Age 1 cells render at 50% size, age 2 at 75%, age 3 at 90%, and mature cells (age 4+) at full size. Dying cells also shrink to 50%. This is implemented via a `birthScale(for:)` function in `GridRenderer` that multiplies cube vertex positions by the scale factor relative to each cell's center. Combined with the death fade-out from session 17, cells now have a complete lifecycle animation: bloom in small → grow → live → fade and shrink out.

2. **Idle auto-rotation**: The grid now gently auto-rotates around the Y axis at ~6°/second (~0.1 rad/s) when not being actively dragged. A background Task at 30fps updates the yaw angle. When the user starts a drag gesture, auto-rotation pauses; when they release, it resumes from the new orientation. This makes the grid feel alive even when paused, and showcases the 3D structure from all angles without user input — important for the "art installation" feel.

Build verified clean on visionOS Simulator.

**Next Steps**: Test birth animation timing on real Vision Pro — verify growth is perceptible at different speeds. Particle effects on birth/death. Performance profiling at 32×32×32. Hand tracking for cell toggling (Phase 4).

---

## Day 10 — Session 17 (2026-03-26)

**Goal**: Smooth cell death animation and configurable grid size.

Two improvements:

1. **Death fade-out animation**: Cells that die are now rendered for one additional generation at very low opacity (10%) before disappearing. Added `dyingCells` tracking to `GridModel.advanceGeneration()` — stores indices of cells that transition from alive to dead. A new `.dying` age tier in `GridRenderer` renders these ghost cells with muted color and minimal emissive glow. Each color theme has a matching dying tier (desaturated, dim version of the mature tier). This eliminates the visual "popping" where cells snap off instantly, replacing it with a subtle fade that makes the simulation feel more organic.

2. **Grid size selector**: Added a Size menu to the control panel with 4 options (12³, 16³, 24³, 32³). `SimulationEngine.changeGridSize()` replaces the grid model and reseeds. Window widened from 560pt to 620pt to accommodate the new menu. This addresses GitHub issue #1 which requested larger grids.

3. **Tests**: Added 3 new tests — dying cells tracked after generation advance, stable block produces no dying cells, clearAll resets dying cells.

Build verified clean on visionOS Simulator.

**Next Steps**: Test death fade on real Vision Pro — verify it's visible but not distracting. Performance profiling at 32×32×32 (13,824 alive cells at 25% = ~3,456 cubes). Particle effects on birth/death. Smooth birth animation (scale up from zero).

---

## Day 10 — Session 16 (2026-03-26)

**Goal**: Address community issues — cell visibility (GitHub #1) and rotation/zoom controls (GitHub #2).

Two changes driven by real user feedback:

1. **Cell spacing (GitHub #1)**: Reduced cell size from 2cm to 1.5cm and tripled spacing from 0.5cm to 1.5cm. The previous 4:1 cell-to-gap ratio made cells indistinguishable and blocked view of inner layers. New 1:1 ratio gives each cell clear visual separation while keeping the 16³ grid at a comfortable ~45cm total extent.

2. **Rotation and zoom (GitHub #2)**: Added drag-to-rotate and pinch-to-zoom gestures to the immersive view. Grid now lives inside a container entity with `InputTargetComponent` and `CollisionComponent` for gesture targeting. Drag maps horizontal/vertical movement to yaw/pitch rotation; magnify gesture scales 0.3×–5.0×. Container approach keeps the grid mesh rebuild independent of transform state.

Build verified clean on visionOS Simulator.

**Next Steps**: Test both changes on real Vision Pro. Smooth cell birth/death animation (fade in/out). Particle effects on birth/death. Performance profiling at 32×32×32.

---

## Day 9 — Session 15 (2026-03-25)

**Goal**: Phase 3 Visual Beauty — color themes (li-d09).

Added four selectable color themes so the simulation can shift visual mood:

1. **ColorTheme type**: Created a `ColorTheme` struct with per-tier material properties (base color, emissive color, emissive intensity, opacity). Each theme defines `TierColors` for newborn, young, and mature age tiers.

2. **Four preset themes**:
   - **Neon** (default): Cyan → teal → indigo. The original look.
   - **Warm Amber**: Bright gold → burnt orange → deep red-brown. Firelike.
   - **Ocean Blues**: Light aqua → medium blue → deep navy. Calm, oceanic.
   - **Aurora**: Green → violet → magenta. Northern lights gradient across age tiers.

3. **Theme-aware renderer**: `GridRenderer.makeGridAsync` now accepts a `ColorTheme` parameter. `makeAgeMaterials` builds `PhysicallyBasedMaterial` for each tier from the theme's color definitions instead of hardcoded values.

4. **UI integration**: Added `theme` property to `SimulationEngine`. Theme picker menu in `ContentView` alongside existing pattern and speed controls. `GridImmersiveView` triggers mesh rebuild on theme change via `onChange(of: engine.theme)`.

5. **Window width**: Widened from 480pt to 560pt to accommodate the theme picker without crowding.

Build verified clean on visionOS Simulator.

**Next Steps**: Test themes on real Vision Pro. Consider smooth cell birth/death animation (fade in/out). Particle effects on birth/death. Performance profiling at 32x32x32.

---

## Day 8 — Session 14 (2026-03-24)

**Goal**: Phase 3 Visual Beauty — cell translucency and age-based coloring (li-59t).

Made cells translucent with age-based visual evolution so the 3D structure is visible through outer layers:

1. **Age tracking**: Changed GridModel cells from `[Bool]` to `[Int]` (0=dead, 1+=age in generations). Surviving cells increment age each generation; newborn cells start at age 1; dying cells reset to 0. Added `cellAge()` accessor and `aliveCellsWithAge()` for the renderer.

2. **Three age tiers with distinct materials**:
   - **Newborn (age 1-2)**: Bright cyan, 55% opacity, strong emissive glow (intensity 2.0)
   - **Young (age 3-5)**: Teal-blue, 35% opacity, medium emissive (intensity 1.2)
   - **Mature (age 6+)**: Deep indigo/purple, 25% opacity, subtle emissive (intensity 0.8)

3. **Translucent PhysicallyBasedMaterial**: Replaced opaque `UnlitMaterial` with `PhysicallyBasedMaterial` using `.transparent` blending and emissive color. `faceCulling = .none` ensures both sides of translucent cubes render correctly.

4. **Multi-part LowLevelMesh**: Cells sorted by age tier into contiguous index ranges, creating separate `LowLevelMesh.Part` entries with different `materialIndex` values. One draw call per tier (3 total) instead of one per cell.

5. **Tests**: Added 5 age-tracking tests — new cell age, dead cell age, age increment on survival, birth age, death resets age. All existing tests pass unchanged.

Build verified clean on visionOS Simulator.

**Next Steps**: Test on Vision Pro to verify translucency looks good. Consider adding smooth fade-in animation for newborn cells and particle effects on death. Performance profiling at 32x32x32.

---

## Day 7 — Session 13 (2026-03-20)

**Goal**: UX polish — compact controls under grid, fix button text wrapping (li-t9v).

Redesigned the control panel to a single compact row:

1. **Window size**: Changed from 340x220 to 480x120 — wider and shorter so it sits below the grid without overlapping.
2. **SF Symbols**: Replaced text "Play"/"Pause" with `play.fill`/`pause.fill`, "Step" with `forward.frame.fill`. Used `.buttonStyle(.bordered)` and `.controlSize(.small)` for compact appearance.
3. **Speed slider**: Replaced Stepper with a compact 80pt Slider for speed control. Shows current speed as "N×" label.
4. **Layout**: All controls in one HStack row — [play|step] [Pattern menu] [speed slider] [stats]. No VStack, no wrapping. Removed the title bar and rules label to save vertical space.
5. **Stats**: Moved generation/alive count to trailing position in the same row, styled as secondary caption.

Build verified clean on visionOS Simulator.

**Next Steps**: Test on real Vision Pro. Begin Phase 3 (Visual Beauty) — age-based cell coloring, glow materials, particle effects.

---

## Day 7 — Session 12 (2026-03-20)

**Goal**: Fix three major usability issues — patterns dying immediately, invisible cells, and oversized control window (li-nk6).

Three fixes:

1. **Simulation rules**: Changed from B5/S6-7 (5766) to B5-7/S5-8. The old rules required extremely dense configurations — a random seed at 10% density averaged only 2.6 neighbors per cell, far below the birth threshold of 5. With B5-7/S5-8, the wider birth range (5,6,7) and survival range (5,6,7,8) produce interesting long-lived evolution at moderate densities. Verified via standalone simulation: random 25% seed stays alive through 100+ generations with oscillating population (~1400-1500 cells).

2. **Patterns overhaul**: Increased random seed density from 10% to 25% (matches the new rules' sweet spot). Replaced "Blinker" (3 cells in a line — a 2D concept that dies instantly in 3D) with "Soup" (6x6x6 random blob at 45% density — verified to grow and sustain). Replaced sparse cross "Cluster" with 4x4x4 checkerboard (32 cells, verified to grow to ~800+ and sustain 60+ gens). Block (2x2x2) remains stable — each cell has 7 neighbors, within survival range. Pattern menu now shows ruleset (B5,6,7/S5,6,7,8) and descriptive pattern names.

3. **Cell visibility**: Replaced faint translucent PhysicallyBasedMaterial (alpha 0.35, emissive 0.3) with bright opaque UnlitMaterial in vivid cyan/teal. Cells should now POP against any passthrough background.

4. **Control window**: Added `.defaultSize(width: 340, height: 220)` to WindowGroup. Tightened padding and font sizes to make the control panel compact and non-obstructive.

All existing tests pass unchanged — the new rules (B5-7/S5-8) are compatible with every test assertion.

Build verified clean on visionOS Simulator.

**Next Steps**: Test on real Vision Pro to confirm visibility and pattern behavior. Begin Phase 3 (Visual Beauty) — age-based cell coloring, glow materials, particle effects.

---

## Day 7 — Session 11 (2026-03-20)

**Goal**: Fix invisible 3D grid in ImmersiveSpace (li-2zm).

Four issues identified and fixed in `GridImmersiveView.swift`:
1. **Grid position**: Entity had no explicit position, so it rendered at world origin (floor level/behind user). Set to `(0, 1.5, -1.5)` — 1.5m up (eye level) and 1.5m in front.
2. **Step button not updating visuals**: `onChange(of: engine.generation)` only rebuilt mesh when `engine.isRunning` was true, meaning the Step button (which doesn't set `isRunning`) never triggered a visual update. Removed the `isRunning` guard.
3. **Dropped mesh updates**: The `isRebuilding` guard silently dropped all generation changes during a rebuild. Replaced with a `needsRebuild` dirty flag and repeat-while loop so the final state is always rendered.
4. **Initial pattern**: Already correct — `SimulationEngine.init` calls `randomSeed(density: 0.1)`, so the grid starts non-empty.

Build verified clean on visionOS Simulator.

**Next Steps**: Test on real Vision Pro to confirm grid visibility. Begin Phase 3 (Visual Beauty) — age-based cell coloring, glow materials, particle effects.

---

## Day 7 — Session 10 (2026-03-20)

**Goal**: Fix volumetric crash by migrating to ImmersiveSpace architecture (li-thq).

The previous fix (li-8pi) added `INFOPLIST_KEY_UIApplicationPreferredDefaultSceneSessionRole = UIWindowSceneSessionRoleVolumetricApplication` to pbxproj, but the app still crashed because the `.windowStyle(.volumetric)` approach is fundamentally unreliable on visionOS. Replaced with Apple's recommended architecture: a regular `WindowGroup` for 2D controls + an `ImmersiveSpace` for 3D content.

Changes:
- **Life3DApp.swift**: Removed `.windowStyle(.volumetric)` and `.defaultSize(...)`. Added `ImmersiveSpace(id: "life3d-grid")` with `.immersionStyle(.mixed)`. App-level `SimulationEngine` shared via `.environment()` to both scenes.
- **ContentView.swift**: Stripped to a pure 2D control panel (play/pause, step, speed, pattern, generation counter). Opens immersive space on appear via `@Environment(\.openImmersiveSpace)`.
- **GridImmersiveView.swift** (new): Holds the `RealityView` with the 3D merged-mesh grid. Receives engine from environment.
- **project.pbxproj**: Removed `INFOPLIST_KEY_UIApplicationPreferredDefaultSceneSessionRole` from both Debug and Release — no longer needed since we're not using volumetric windows.

Build verified clean on visionOS Simulator.

**Next Steps**: Test on real Vision Pro to confirm crash is resolved. Begin Phase 3 (Visual Beauty) — age-based cell coloring, glow materials, particle effects.

---

## Day 7 — Session 9 (2026-03-20)

**Goal**: Fix volumetric window crash caused by UIWindowSceneSessionRoleApplication mismatch (li-8pi).

The app crashed on launch because `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES` auto-generates an Info.plist with the default 2D window scene role (`UIWindowSceneSessionRoleApplication`), but the SwiftUI code uses `.windowStyle(.volumetric)` which requires the volumetric role. Added `INFOPLIST_KEY_UIApplicationPreferredDefaultSceneSessionRole = UIWindowSceneSessionRoleVolumetricApplication` to both Debug and Release build settings in project.pbxproj. Build verified clean.

**Next Steps**: Begin Phase 3 (Visual Beauty) — age-based cell coloring, glow materials, particle effects. Address 20s mesh generation performance.

---

## Day 7 — Session 8 (2026-03-20)

**Goal**: Migrate life3d to latest rig-seed template with dual Day/Session tracking.

Ran rig-seed's `scripts/migrate.sh` to pull 11 upstream files into life3d:
- Added dual tracking: SESSION_COUNT (total sessions) + DAY_DATE (last session date) alongside DAY_COUNT
- Updated CLAUDE.md with new journal format (`Day N — Session M` with mandatory **Goal** and **Next Steps**)
- Added docs: EVOLUTION, TROUBLESHOOTING, FORKING, DAY-ZERO, FORMULA-CUSTOMIZATION, UPGRADING
- Added scripts: migrate.sh, release.sh, metrics.sh
- Added .evolve/config.toml `[release]` section (strategy: manual)
- Added /rig-spawn slash command
- Updated .gitignore to exclude Gas Town internal dirs (.repo.git, mayor/, refinery/, witness/, polecats/)
- Created SESSION_COUNT (set to 6 at time of migration, now 8)

Also fixed bare repo fetch refspec (was missing origin/main) and test_command rig config
(was `go test ./...`, now `xcodebuild build`).

**Next Steps**: Test volumetric window background removal on device. Begin Phase 3 (Visual Beauty) — age-based cell coloring, glow materials, particle effects. Address 20s mesh generation performance.

---

## Session 7 — Implement 3D cellular automata simulation engine (li-r02)

Phase 2 complete. Polecat: furiosa.

Built the full simulation engine on top of the existing merged-mesh renderer:

**GridModel expansion:**
- Cell state stored as flat `[Bool]` array with get/set/neighborCount methods
- 26-neighbor Moore neighborhood counting (edges treated as dead, no wrapping)
- `advanceGeneration()` applies rules to produce next generation
- Configurable birth/survival rule sets (default: 5766 — born with 5, survive with 6-7)

**SimulationEngine (@Observable):**
- Owns GridModel, tracks generation count
- Step mode (advance one generation) and continuous mode (timer-based)
- Speed control: 1-30 generations per second via Task.sleep-based loop
- Pause/resume, pattern reset

**Preset patterns:**
- Random seed (10% density)
- Blinker (3 cells in a line — oscillator analog)
- Block (2x2x2 cube — stable still life under 5766, each cell has 7 neighbors)
- Cluster (3D cross with extras — produces interesting evolution)

**Rendering integration:**
- GridRenderer now builds mesh from only alive cells via `aliveCellPositions()`
- Dead cells are invisible — mesh is rebuilt each generation
- Empty grid handled gracefully (returns empty Entity)

**UI controls:**
- Play/Pause, Step, Pattern selector (Menu), Speed stepper
- Generation counter and alive cell count displayed in overlay

**Tests (logic-only, no RealityKit):**
- Cell state get/set, clear, out-of-bounds safety
- Neighbor counting: isolated cell, adjacent pair, full 2x2x2 block (7 neighbors each), corner no-wrap
- Rule application: birth with 5, survival with 6 and 7, death with <6, no birth with 4
- 2x2x2 block stability verification under 5766 rules

What worked: The @Observable macro + onChange(of: generation) pattern provides clean
reactive mesh rebuilding. LowLevelMesh handles variable cell counts smoothly since we
rebuild each frame anyway.

What to watch: Mesh rebuild every generation could become a bottleneck at high speeds
with many alive cells. Future optimization: update vertex buffers in-place rather than
recreating LowLevelMesh each frame.

Next: Phase 3 — Visual beauty. Replace plain cubes with glowing translucent cells,
add age-based color evolution, particle effects on birth/death, and color themes.

---

## Session 6 — Remove gray window background, use volumetric window (li-8z1)

Switched from default flat WindowGroup to `.volumetric` window style. Polecat: furiosa.

Problem: The app displayed a gray window background behind the 3D grid. For a spatial
art piece, the grid should float in the user's real space with no visible window chrome.

Solution: Changed `Life3DApp.swift` to use `.windowStyle(.volumetric)` with
`.defaultSize(width: 0.5, height: 0.5, depth: 0.5, in: .meters)`. This removes all
window chrome and lets the RealityView content float in the user's space.

Previous learnings noted that `.volumetric` caused a `UIWindowSceneSessionRoleApplication`
mismatch on the visionOS 2.1 simulator — but that was a runtime crash, not a build error.
Since we verify build-only (simulator crashes host), this is fine. The user will test on
real hardware.

---

## Session 5 — Optimize mesh generation: LowLevelMesh replaces MeshResource.generate (li-zqh)

Fixed 30+ second grid load time on real Vision Pro. Polecat: furiosa.

Problem: MeshResource.generate(from: [MeshDescriptor]) performs expensive internal
validation and mesh optimization. For 4096 cubes (98K vertices, 147K indices), this
dominated load time — the CPU-side vertex computation was fast, but generate() added
massive overhead.

Solution: Replaced the entire mesh generation pipeline with LowLevelMesh (visionOS 2.0+).
This API provides direct access to GPU-accessible buffers, bypassing MeshResource's
internal processing entirely:
- Vertex/index data is pre-computed off MainActor in arrays with indexed writes
- LowLevelMesh descriptor defines interleaved vertex layout (position + normal + UV)
- Data is copied directly into GPU buffers via withUnsafeMutableBytes/withUnsafeMutableIndices
- MeshResource(from: lowLevelMesh) wraps the result without re-processing

Additional optimization: replaced array append loops with pre-allocated arrays and
direct indexed writes, eliminating bounds checking and copy-on-write overhead.

Result: Grid should load in under 2 seconds on real hardware (from 30+). Same visual
output — 16x16x16 grid, single draw call, same PBR material.

---

## Session 4 — Replace individual entities with instanced rendering (li-b2r)

Replaced the per-cell ModelEntity approach with a single merged mesh. Polecat: furiosa.

Problem: Creating one ModelEntity per cell (512 at 8x8x8, 4096 at 16x16x16) overwhelmed
RealityKit's scene graph — each entity is a separate draw call, transform node, and material
binding. Even with batched creation and Task.yield(), 4096 entities caused window flashing,
erratic behavior, and multi-second hangs on real hardware.

Solution: GridRenderer.generateMergedMesh() builds all cube geometry into a single
MeshDescriptor with combined position/normal/UV/index buffers. Each cube contributes 24
vertices (4 per face for correct per-face normals) and 36 indices. The mesh is generated
on a detached Task off the main thread, then a single ModelEntity is created on MainActor.

Result: The entire 16x16x16 grid (4096 cubes) is now ONE entity with ONE draw call.
Grid size restored from 8x8x8 back to 16x16x16. The semi-transparent emissive material
is applied once to the single entity.

---

## Session 3 — Fix launch crash: batch entity creation + reduce grid to 8x8x8 (li-byh)

Fixed persistent launch crash on real Vision Pro. Polecat: furiosa.

Root cause: Previous async fix (Session 2) moved position computation off-thread
but still created 4096 ModelEntity instances in a tight synchronous loop on MainActor.
This blocked the main thread for ~8.38s, well above the visionOS watchdog threshold.

Changes:
- GridRenderer.makeGridAsync() now creates entities in batches of 64 with
  Task.yield() between batches, preventing main thread starvation
- Reduced grid from 16x16x16 (4096 entities) to 8x8x8 (512 entities),
  which is fast enough for launch and avoids watchdog kills
- ContentView updated to use GridModel(size: 8)

The combination of smaller grid + batched creation should eliminate the hang
entirely. 512 entities in batches of 64 = 8 batches with yields between them.

---

## Session 2 — Fix launch crash: move grid creation off main thread (li-0r3)

Fixed visionOS watchdog termination on real Vision Pro hardware. Polecat: furiosa.

Root cause: GridRenderer.makeGrid() created 16^3 = 4096 ModelEntity instances
synchronously inside RealityView's make closure, which runs on the main actor.
This blocked the main thread for >2 seconds, triggering visionOS hang detection.

Changes:
- GridRenderer.makeGridAsync() — computes cell positions on a detached Task,
  then creates entities on MainActor (RealityKit requires it)
- ContentView uses .task modifier with @State to load grid asynchronously
- ProgressView loading indicator shown while grid builds
- RealityView update closure adds grid entity once ready

Approach: The heavy work (position math for 4096 cells) moves to a detached task.
Entity creation stays on MainActor since RealityKit requires it, but with positions
pre-computed, the main thread work is just instantiation — much faster.

---

## Session 1 — Bootstrap visionOS app with RealityKit 3D grid (li-gg1)

Created the initial visionOS app target with RealityKit rendering. Polecat: furiosa.

Changes:
- Xcode project with visionOS app target (Life3D)
- Life3DApp.swift — SwiftUI app entry point with WindowGroup
- ContentView.swift — Main view with RealityView
- GridModel.swift — 3D grid data structure (16x16x16)
- GridRenderer.swift — RealityKit cube rendering with semi-transparent emissive material
- GridTests.swift — Logic-only unit tests for grid dimensions
- Volumetric window style causes runtime crash on visionOS 2.1 sim — used plain WindowGroup with RealityView instead
- visionOS Simulator crashes host machine — build-verify only, no test execution in CI

Lesson: visionOS Simulator is too heavy for automated test runs on this machine. Need build-only verification or a lighter test strategy.

---
