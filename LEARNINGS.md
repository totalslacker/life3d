# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

## 3D Game of Life Rule Selection (26-neighbor Moore)

- **B5/S6-7 (5766)** requires extremely dense seeds. At 10% density, avg neighbors ≈ 2.6 — far below birth=5 threshold. Most patterns die in 1-2 generations.
- **B5-7/S5-8** works well: wide birth range (5,6,7) and survival range (5,6,7,8) produce long-lived evolution at 20-30% density.
- At 25% density on 16³: avg neighbors ≈ 6.5 → right in the birth/survival sweet spot. Random seeds sustain 100+ generations with oscillating populations (~1400-1500 cells).
- Solid cubes (3x3x3, 4x4x4) are too dense — interior cells have 17-26 neighbors, die immediately. Checkerboard patterns (alternating cells) produce better dynamics.
- 2x2x2 block is stable under both B5/S6-7 and B5-7/S5-8 (each cell has exactly 7 neighbors).
- The "blinker" (3 cells in a line) is a 2D concept — each cell has at most 2 neighbors in 3D, dies under any reasonable ruleset.
- `UnlitMaterial` with vivid color (alpha 1.0) is much more visible than `PhysicallyBasedMaterial` with transparency, especially against passthrough backgrounds.

---

## visionOS Simulator Limitations

- The visionOS Simulator boots a full xrOS runtime and is extremely resource-heavy
- On some machines it crashes the host when launched (especially with volumetric windows)
- `xcodebuild test` launches the app as test host, triggering the simulator crash
- **Workaround**: Use `xcodebuild build` for CI verification, run tests manually on device or with logic-only test targets that don't require the simulator runtime
- `.windowStyle(.volumetric)` is unreliable — causes `UIWindowSceneSessionRoleApplication` mismatch crash even with the `INFOPLIST_KEY` workaround. **Correct approach**: use a regular `WindowGroup` for 2D UI + `ImmersiveSpace` for 3D content with `.immersionStyle(.mixed)`. Share state between scenes via `.environment()` on an `@Observable` model.
- `@Environment(\.openImmersiveSpace)` / `@Environment(\.dismissImmersiveSpace)` control immersive space lifecycle from 2D views
- `.defaultSize(width:height:depth:in:)` with `.meters` unit sets the volumetric window dimensions — replaces pixel-based `.defaultSize(width:height:)`

---

## RealityView Main Thread Constraints

- RealityView's `make` closure runs on the main actor — synchronous heavy work there triggers the visionOS watchdog (kills app after ~2s hang)
- Entity/ModelEntity creation requires MainActor, so you can't fully move entity construction off-thread
- **Pattern**: compute data (positions, materials config) on a detached Task, then create entities on MainActor with pre-computed data
- Use RealityView's `update` closure + @State to add entities after async loading completes
- `.task` modifier on the view is the cleanest way to kick off async grid construction
- Even with async position computation, creating thousands of entities in a tight loop on MainActor still blocks — use batched creation with `Task.yield()` between batches (64 entities/batch works well)
- For launch performance, 8x8x8 (512 entities) is a safe grid size; 16x16x16 (4096) causes hangs even with batching on real hardware

---

## Merged Mesh Rendering (Single Draw Call)

- Creating one ModelEntity per cell does NOT scale — each is a separate scene graph node, draw call, transform, and material binding
- The fix is MeshResource.generate(from: [MeshDescriptor]) — build ALL cube geometry into one mesh with combined vertex/index buffers
- Use 24 vertices per cube (4 per face) for correct per-face normals; 36 indices per cube (6 faces * 2 triangles)
- MeshDescriptor needs positions, normals, textureCoordinates, and primitives (.triangles(indices))
- Mesh generation (vertex math) can run on a detached Task off MainActor — only the final ModelEntity creation needs MainActor
- With merged mesh, 16x16x16 (4096 cubes = 98,304 vertices, 147,456 indices) renders as ONE draw call — no scene graph overhead
- PhysicallyBasedMaterial with transparent blending and emissive works on merged mesh the same as on individual entities

---

## LowLevelMesh vs MeshResource.generate Performance

- `MeshResource.generate(from: [MeshDescriptor])` performs internal validation, vertex welding, and mesh optimization — this adds massive overhead for large meshes (30+ seconds for 98K vertices on Vision Pro)
- `LowLevelMesh` (visionOS 2.0+) provides direct GPU buffer access, bypassing all intermediate processing
- LowLevelMesh workflow: define vertex layout via Descriptor → create mesh → write data via `withUnsafeMutableBytes(bufferIndex:)` / `withUnsafeMutableIndices` → set Parts with bounds → wrap in `MeshResource(from:)`
- `LowLevelMesh(descriptor:)` is `@MainActor`-isolated in Swift 6 — compute raw data off-thread, then create LowLevelMesh on MainActor
- `LowLevelMesh.Layout` requires `bufferIndex` parameter: `.init(bufferIndex: 0, bufferStride: stride)`
- Use interleaved vertex struct (position + normal + UV) with `MemoryLayout.offset(of:)` for attribute offsets
- Must set `mesh.parts` with bounds via `replaceAll([part])` — without parts, nothing renders
- For array building: pre-allocate with `[T](repeating:, count:)` and indexed writes is faster than `reserveCapacity` + `append` (avoids bounds checks and CoW overhead)

---

## Swift 6 Concurrency with @Observable and RealityKit

- `@Observable` (from `Observation` framework) replaces `ObservableObject` in Swift 5.9+ / visionOS 2.0+
- `@Observable @MainActor class` works well for simulation state — SwiftUI views observe changes automatically
- `onChange(of:)` on `@Observable` properties triggers correctly for reactive mesh rebuilding
- `Task.sleep(nanoseconds:)` in a loop is the simplest timer for continuous simulation — avoids Timer/RunLoop complexity
- When rebuilding LowLevelMesh each generation: create new mesh from scratch rather than trying to resize buffers (LowLevelMesh capacity is fixed at creation)
- Guard against concurrent rebuilds with a simple `isRebuilding` flag — prevents mesh rebuild pile-up at high simulation speeds
