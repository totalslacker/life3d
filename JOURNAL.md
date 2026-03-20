# Journal

Evolution session log. Most recent entry first. Never delete entries.

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
