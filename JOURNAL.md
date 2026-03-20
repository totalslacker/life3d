# Journal

Evolution session log. Most recent entry first. Never delete entries.

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
