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

## PointLightComponent in visionOS RealityKit

- `PointLightComponent` provides real-time point lighting on nearby entities
- `intensity` is in lumens — 50 lumens gives a soft ambient glow without washing out translucent materials
- `attenuationRadius` controls how far the light reaches — 0.15m works well for cell-scale grids
- `color` accepts a platform color (UIColor/CGColor) — match to theme emissive for cohesive look
- Point lights are cheap in small quantities (4-8) but expensive at scale — use a sampling pool like particle emitters
- Lights attached to a container entity inherit its transform (rotation/scale), so they move with the grid automatically

---

## Cell Spacing for 3D Grid Readability

- Cell-to-gap ratio matters more than absolute sizes for readability
- Original 4:1 ratio (cellSize 0.02, spacing 0.005) made cells blend together, especially inner layers invisible
- 1:1 ratio (cellSize 0.015, spacing 0.015) gives clear cell differentiation while keeping grid compact (~45cm for 16³)
- Total grid extent formula: `(size - 1) * stride / 2 + cellSize / 2` where `stride = cellSize + spacing`

---

## HoverEffectComponent in visionOS RealityKit

- `HoverEffectComponent()` with default style provides system-standard gaze highlight on entities
- Requires `InputTargetComponent` and `CollisionComponent` on the same entity to work
- Works on container entities — the highlight applies to all visible child entities in the subtree
- For merged mesh grids, per-cell hover isn't practical; container-level hover gives "this is interactive" feedback
- No additional gesture configuration needed — visionOS handles gaze tracking automatically

---

## Wireframe Boundary with MeshResource.generateBox

- 12 thin `MeshResource.generateBox` entities (one per cube edge) is a simple way to render a wireframe boundary
- Edge thickness of 0.0008m (0.8mm) is visible but unobtrusive at typical grid scales
- `UnlitMaterial` with low alpha (0.3) keeps the wireframe subtle against translucent cell rendering
- Using theme's mature emissive color for wireframe makes it feel integrated with the visual style
- 12 entities is lightweight — no measurable performance impact on visionOS

---

## AVAudioEngine Spatial Audio for visionOS

- `AVAudioEnvironmentNode` provides HRTF-based 3D audio positioning — attach player nodes to it for spatial sound
- `AVAudioPlayerNode.renderingAlgorithm = .HRTFHQ` gives high-quality head-related transfer function on Vision Pro
- `AVAudioPlayerNode.sourceMode = .pointSource` makes the audio emanate from a specific 3D point
- `AVAudioPlayerNode.position = AVAudio3DPoint(x:y:z:)` positions the sound source; multiply by ~5 for audible separation at grid scale (cells are ~1.5cm apart)
- Programmatic tone generation: create `AVAudioPCMBuffer` with mono format, write sine wave samples with envelope shaping
- Bell curve envelope (Gaussian) works well for birth tones — smooth attack and decay with no click
- Linear fade-out envelope works for death tones — immediate onset with gradual decay
- Pool of 4 player nodes per type is sufficient — `.interrupts` option prevents overlapping the same player
- Volume should scale with activity density to create a natural "busier = louder" soundscape
- Death tones at ~60% volume of birth tones gives a natural feel — births are events, deaths are fading away

---

## Multi-Generation Death Fade

- Single-frame dying cell rendering looks jarring — cells "pop" out of existence, breaking the organic feel
- Tracking `fadingCells: [(index: Int, framesLeft: Int)]` on GridModel gives smooth multi-frame dissolve
- 3 generations is the sweet spot for fade duration — visible but not lingering. At 5 gen/s this is ~0.6s
- Fading cells must be removed when reborn at the same position, otherwise you get ghost cubes overlapping live cells
- Encoding fade progress as negative age values (−1 = just died, −3 = nearly gone) in the render pipeline avoids changing the vertex struct or adding a new mesh part type
- Progressive scale reduction (50% → 30% → 15%) reads better than opacity-only fade because translucent materials are already low-opacity

---

## Auto-Restart on Extinction

- Many 3D cellular automata configurations die within 50-100 generations, leaving an empty grid
- Waiting for `aliveCount == 0 && fadingCells.isEmpty` ensures the last cells finish their dissolve before reseed
- A brief delay (3 empty generations) between extinction and reseed creates a natural "breath" — the grid goes dark, pauses, then blooms fresh
- Using `randomSeed()` for restart gives maximum variety; pattern-cycling would be an alternative for curated experiences

---

## Array-Based Rule Lookup Performance

- `Set<Int>.contains()` in Swift is O(1) amortized but involves hashing overhead per call
- For the 3D Game of Life inner loop (n³ cells × 26 neighbors), this adds up: 32³ = 32K cells means ~850K contains() calls per generation
- Replacing with a pre-computed `[Bool]` lookup table indexed by neighbor count (0-26) eliminates all hashing — direct array subscript is a single pointer offset
- `didSet` on the `birthCounts`/`survivalCounts` properties automatically rebuilds the lookup tables when rules change, keeping the optimization transparent
- Combined with the existing interior-cell fast path (no bounds checking for 82% of cells), this makes `advanceGeneration` significantly tighter

---

## Double-Buffered Grid Generation

- `advanceGeneration()` originally allocated `[Int](repeating: 0, count: cellCount)` every generation — heap alloc + zero-fill of 32K ints at 32³
- Pre-allocating two buffers (`cells` and `nextCells`) at init and using `swap(&cells, &nextCells)` eliminates per-generation allocation entirely
- The "next" buffer must be zeroed before use (`for i in 0..<cellCount { nextCells[i] = 0 }`) — this is a memset equivalent that's faster than heap allocation
- After the swap, `cells` holds the new generation and `nextCells` (now pointing to old data) will be zeroed on the next call
- `clearAll()` was also updated to zero in-place instead of allocating, since the buffer sizes never change
- References to the old `next` array in post-swap code (e.g., fading cell logic) must use `cells` instead, since `cells` is the new data after swap
