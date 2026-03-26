# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

## ParticleEmitterComponent in visionOS RealityKit

- `ParticleEmitterComponent` has no top-level `birthRate` property — particle properties live on `mainEmitter`
- `spreadingAngle` takes a Float in radians, not `.degrees()` — use `.pi` for 180°
- No `speed`/`speedVariation` on `ParticleEmitter` — control velocity via `acceleration` (SIMD3<Float>)
- Color: `emitter.mainEmitter.color = .constant(.single(.init(red:green:blue:alpha:)))` for solid color
- Timing: `.once(warmUp:emit:)` with `VariableDuration(duration:)` for single burst effects
- `burstCount` controls how many particles per burst event
- `opacityCurve = .linearFadeOut` for natural particle fading
- Per-cell emitters don't scale — with thousands of births/deaths per generation, use a small pool (6-12 emitters) positioned at sampled locations
- Emitters attached to a container entity inherit its transform (rotation/scale) — particles move with the grid

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

## Translucency and Age-Based Materials in RealityKit

- `PhysicallyBasedMaterial` with `.transparent(opacity:)` blending gives translucent cells that reveal inner 3D structure
- Previous attempt with alpha 0.35 + emissive 0.3 was too faint — need emissiveIntensity ≥ 0.8 and opacity ≥ 0.25 to be visible against passthrough
- `faceCulling = .none` is essential for translucent cubes — without it, back faces are invisible when viewed through front faces
- Multi-material via `LowLevelMesh.Part.materialIndex`: sort cells by category, create contiguous index ranges per category, assign different materialIndex to each Part. ModelEntity materials array maps by index.
- Age tracking in GridModel (Int instead of Bool) is cheap — same memory layout, simple increment on survival, reset to 0 on death, set to 1 on birth
- Three age tiers (newborn/young/mature) with distinct color + opacity creates a natural depth cue: bright new cells pop against faded old ones

---

## Swift 6 Concurrency with @Observable and RealityKit

- `@Observable` (from `Observation` framework) replaces `ObservableObject` in Swift 5.9+ / visionOS 2.0+
- `@Observable @MainActor class` works well for simulation state — SwiftUI views observe changes automatically
- `onChange(of:)` on `@Observable` properties triggers correctly for reactive mesh rebuilding
- `Task.sleep(nanoseconds:)` in a loop is the simplest timer for continuous simulation — avoids Timer/RunLoop complexity
- When rebuilding LowLevelMesh each generation: create new mesh from scratch rather than trying to resize buffers (LowLevelMesh capacity is fixed at creation)
- Guard against concurrent rebuilds with a simple `isRebuilding` flag — prevents mesh rebuild pile-up at high simulation speeds

---

## Entity Gestures in visionOS ImmersiveSpace

- Entities need `InputTargetComponent` and `CollisionComponent` to receive gestures
- `DragGesture().targetedToAnyEntity()` provides `EntityTargetValue<DragGesture.Value>` — access 2D `translation` (CGSize with `.width`/`.height`), NOT `translation3D` (doesn't exist on `DragGesture.Value`)
- `MagnifyGesture().targetedToAnyEntity()` provides `magnification` (CGFloat scale factor)
- Container entity pattern: put the grid inside a parent entity, apply rotation/scale to the parent, rebuild the grid mesh independently — this separates transform state from mesh state
- `CollisionComponent(shapes: [.generateBox(size:)])` — use a generous box size (larger than actual grid) for easy grab targeting
- Yaw/pitch from 2D drag: horizontal → yaw (Y-axis rotation), vertical → pitch (X-axis rotation). Clamp pitch to ±π/2 to prevent flipping

## Neighbor Counting Optimization

- The naive `neighborCount()` with bounds checking via `isAlive()` has high overhead: function call + 4 comparisons per neighbor × 26 neighbors × n³ cells per generation
- Pre-computing the 26 neighbor offsets as flat array index deltas (`dx * size² + dy * size + dz`) avoids recomputing them for each cell
- Interior cells (distance >1 from any face) are guaranteed to have all 26 neighbors in bounds — skip all bounds checking and use direct `cells[idx + offset]` access
- For a 32³ grid, 82% of cells are interior (30³/32³). For 16³, 73% (14³/16³). The fast path dominates.
- Swift's `&+` (overflow-safe addition) avoids integer overflow checks in tight loops — small but measurable win at scale

---

## Cell Spacing for 3D Grid Readability

- Cell-to-gap ratio matters more than absolute sizes for readability
- Original 4:1 ratio (cellSize 0.02, spacing 0.005) made cells blend together, especially inner layers invisible
- 1:1 ratio (cellSize 0.015, spacing 0.015) gives clear cell differentiation while keeping grid compact (~45cm for 16³)
- Total grid extent formula: `(size - 1) * stride / 2 + cellSize / 2` where `stride = cellSize + spacing`
