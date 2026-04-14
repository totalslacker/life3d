# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

## Swift Circular Buffer: Avoiding Per-Tick Allocations

- `Array(slice) + Array(slice)` for unwrapping a circular buffer allocates 2 temporary arrays and a final concatenated array — 3 heap allocs per call
- For O(0) allocation, pre-size the output array once and use `withUnsafeMutableBufferPointer` + `update(from:count:)` to copy in-place
- `update(from:count:)` compiles to `memmove` — single operation vs N element copies
- `removeAll(keepingCapacity: true)` preserves backing allocation for the empty case
- At 5-30 gen/s, eliminating per-generation allocations reduces GC pressure measurably on visionOS where frame budgets are tight (16.6ms at 60fps)

---

## ParticleEmitterComponent in visionOS RealityKit

- `ParticleEmitterComponent` has no top-level `birthRate` property — particle properties live on `mainEmitter`
- `spreadingAngle` takes a Float in radians, not `.degrees()` — use `.pi` for 180°
- `speed` and `speedVariation` exist on `ParticleEmitterComponent` (top-level struct); they do **not** exist on the nested `ParticleEmitterComponent.ParticleEmitter` (`mainEmitter`). Control directional velocity via `mainEmitter.acceleration` (SIMD3<Float>); control initial scalar speed via the top-level `emitter.speed`. ⚠️ Prior entry incorrectly stated "No `speed`/`speedVariation` on `ParticleEmitter`" — that was accurate for the nested type but misleading as it implied the properties don't exist at all. Default `speed` is ~0.5 m/s; for cell-localized effects set `speed = 0.02` so bursts stay within 2 cell widths of the source.
- Color: `emitter.mainEmitter.color = .constant(.single(.init(red:green:blue:alpha:)))` for solid color
- Timing: `.once(warmUp:emit:)` with `VariableDuration(duration:)` for single burst effects
- `burstCount` controls how many particles per burst event
- `opacityCurve = .linearFadeOut` for natural particle fading
- Per-cell emitters don't scale — with thousands of births/deaths per generation, use a small pool (6-12 emitters) positioned at sampled locations
- Emitters attached to a container entity inherit its transform (rotation/scale) — particles move with the grid
- **Particle visibility at 1.5m viewing distance**: A 3mm particle subtends ~5 angular pixels — essentially invisible in passthrough. For cell-localized sparkle effects, 5–6mm (≈ ⅓–⅖ cell size) is clearly visible (~9–11px at 1.5m) without obscuring the cells. ⚠️ Prior entry stated "minimum 15–20mm (1–1.5× cell size)" — that was calibrated when the problem was invisibility; those values combined with 0.7–1.0s lifespan caused an explosion that hid the grid. For travel: `d = 0.5 × a × t²` — use 0.12 m/s² (birth, 0.7s) and 0.06 m/s² (death, 1.0s) to keep particles within 2 cell widths (0.030m).
- **Dynamic burstCount antipattern**: Scaling `burstCount = count / maxEmitters` causes near-zero particle counts during low-activity generations. Fixed counts (12 birth, 8 death) ensure consistent visual sparkle. ⚠️ Prior values (45/28) were calibrated for 20mm particles; at 6mm, 12/8 produce the equivalent visual density.
- **`.once` timing expiry and restart pattern (Options C + D)**: `emitter.timing = .once(...)` fires a single burst and then becomes inert. Re-assigning `emitter.timing` to a fresh `.once(...)` value (Option B) was found insufficient — RealityKit maintains internal "has-fired" state on the entity that is not reset by field re-assignment alone. Option C (full component replacement via a fresh `makeParticleEmitterComponent()`) was also found insufficient on its own — confirmed via diagnostic checkpoint logging on 164 generations (issue #9): checkpoints P1–P5 all passed correctly (onChange fired every generation, data was non-empty, isEmitting=true read back, entity.parent=true), yet particles stopped firing visually. **Root cause (confirmed from logs)**: RealityKit treats `components.set(emitter)` as an in-place update when a component of that type already occupies the slot, preserving entity-side "has-fired" state even when the component struct is freshly constructed. **Option D fix**: call `entity.components.remove(ParticleEmitterComponent.self)` immediately before `entity.components.set(emitter)` at every trigger site. This forces RealityKit to fully detach and re-attach the component, clearing all entity-side state. Confirmed effective: particles fired continuously through 164+ generations in the visionOS Simulator. This pattern applies to ALL emitter types in this project — birth/death (`makeParticleEmitterComponent`) and pulse (`makePulseEmitterComponent`). `burstCount` is NOT set inside the helper; the trigger site sets it explicitly so the trigger remains the sole source of truth. See ADR 001.
- **Spread angle vs cell scale**: Birth particles at `.pi` (180°) with 1.5 m/s² upward acceleration over 0.7s travel ~37cm vertically and can spray 30–40cm laterally — well beyond the 1.5cm cell boundary. `.pi / 6` (30°) gives ~10cm lateral spread, keeping effects cell-localized. Death particles at 2.0 m/s² over 1.0s with `.pi / 6` give ~27cm spread. If death particles look too columnar, widen to `.pi / 4`.

---

## PhysicallyBasedMaterial PBR Parameters in RealityKit

- Default roughness ≈ 0.5 (matte), metallic = 0.0 (fully diffuse) — produces flat "blue cubes" appearance with no specular differentiation across faces
- **Low roughness (0.18)**: Creates sharp specular highlights that differentiate cube faces based on lighting angle, revealing 3D form without geometry changes
- **Slight metallic (0.15)**: Adds reflective depth across lighting environments without making cells look metallic
- **Clearcoat (0.4)**: Adds a gloss layer for a "luminous surface" appearance — achievable via `mat.clearcoat = .init(floatLiteral: 0.4)` on `PhysicallyBasedMaterial`
- **PBR constants scope decision**: Set roughness/metallic/clearcoat as constants in `makeAgeMaterials`, not as `TierColors` fields. All 152 themes benefit from the same specular surface quality ("glowing volume" is a rendering invariant, not a per-theme aesthetic). If per-theme control is ever needed, it's a future additive change — adding fields to TierColors would require updating all 608 call sites.
- Opacity boost for newborn (×1.31 capped at 0.85): More overlapping transparency creates richer volumetric layering without full opacity

---

## Density-Based Coloring via LowLevelMesh Material Slots

- **Option A (implemented)**: Expand from 4 to 8 material slots (4 age × 2 density bands). `LowLevelMesh.Part.materialIndex` is just an Int — expanding from 4 to 8 Parts is safe; vertex/index buffer sizes unchanged.
- **Density threshold = 11 neighbors**: In the 26-neighbor Moore neighborhood, ≥11 neighbors indicates interior cluster position. Fewer = surface or isolated. This threshold visually separates cluster interior from surface structure.
- **Double-buffer pattern for neighborCounts**: Must use same swap idiom as `cells/nextCells`. Zero `nextNeighborCounts` before the generation loop, write alive cells' counts, swap at end. Skipping the swap causes stale counts in dead cells' slots.
- **Fading cells lose density info**: They die before next generation, so their `neighborCounts` go to 0. Assign fading cells to sparse band in the renderer — visually acceptable and simplest.
- **`aliveCellIndices` as the lookup key**: In `computeMeshData`, iterate `model.aliveCellIndices` directly (not `aliveCellsWithAge`) to get the flat index needed for `neighborCounts` lookup. Compute position inline via `model.cellPosition(x:y:z:cellSize:cellSpacing:)`.

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

---

## AVAudioPlayerNode Pool Sizing and Tone Duration Scaling

- Pool size of 4 per type (birth/death) causes audible drops when >4 cells are born/dying per generation — common at 16³+ grids
- Pool size of 8 gives enough headroom for high-activity generations without excessive resource use
- Fixed-duration tones (150ms) overlap chaotically at high simulation speeds (>10 gen/s) — tones from consecutive generations pile up
- Scale tone duration inversely with speed: `max(40ms, 150ms * (5 / speed))` keeps tones distinct per generation
- Regenerate `AVAudioPCMBuffer` only when speed changes by >20% — avoids per-frame buffer allocation while staying responsive
- Floor of 40ms ensures tones remain perceptible even at 30 gen/s (the UI maximum)

---

## Circular Buffers for Per-Generation Tracking

- Any per-generation data accumulation (population trend, history, etc.) should use pre-allocated circular buffers
- `Array.removeFirst()` is O(n) — shifts all elements left. At 30 gen/s with a 10-element buffer, that's 300 element moves/second
- Circular buffer pattern: fixed-size array + write index + count. Append is `buffer[writeIndex] = value; writeIndex = (writeIndex + 1) % capacity`
- Reading chronological order from a circular buffer: `buffer[start..<capacity] + buffer[0..<start]` where `start = writeIndex`
- When multiple circular buffers exist in the same class, reset ALL of them in `reset()` — easy to miss one and get stale data

## Squared Distance Optimization for Depth Scaling

- `simd_length()` computes sqrt which is expensive in tight loops over thousands of cells
- `simd_length_squared()` returns the squared magnitude without sqrt — same monotonic ordering
- For depth-of-field scaling where the exact distance ratio isn't critical (visual effect), squared distance is a valid substitute: `distSq / maxDistSq` instead of `dist / maxDist`
- The visual difference is a slightly more aggressive quadratic falloff at grid edges, which actually looks marginally more natural
- For 32³ grids with ~8K alive cells, this eliminates ~8K sqrt calls per mesh rebuild cycle
- Same pattern applies to any per-element distance-based effect: sorting by distance, LOD selection, etc.

---

## Bucket Partitioning vs Sorting for Small Category Counts

- When partitioning elements into a small fixed number of categories (e.g., 4 age tiers), O(n) bucket sort beats O(n log n) comparison sort
- Pattern: create K empty arrays, iterate once assigning each element to its bucket, then `flatMap` to recombine
- For n=8K elements and K=4 categories, this saves ~100K comparisons (n × log₂n ≈ 8K × 13)
- `flatMap` on small K arrays is effectively free compared to the sort's comparison overhead
- Swift's `sorted()` uses introsort which has good constant factors, but for K ≤ ~8 the bucket approach is simpler and faster
- General rule: if the sort key maps to a small enum/integer range, prefer bucketing

---

## Buffer Reuse with removeAll(keepingCapacity:)

- `removeAll(keepingCapacity: true)` zeroes the count but keeps the underlying buffer allocation
- For arrays that grow to a steady-state size (like born/dying cell lists), this avoids heap allocation after the first few generations
- Pattern: promote local `var arr: [T] = []` to instance property, call `arr.removeAll(keepingCapacity: true)` at start of each cycle
- At 32³ with ~1K elements per generation at 5 gen/s, this eliminates ~10 allocations/second
- `reserveCapacity` is still useful for the first use or when appending to a cleared buffer that needs to grow beyond its previous high-water mark

---

## Incremental Index Tracking for Sparse Grid Iteration

- In 3D cellular automata, alive cells are typically 5-25% of total grid cells — scanning the full grid to find them is wasteful
- Maintaining a flat index list (`aliveCellIndices`) alongside the cells array converts render-path iteration from O(n³) to O(alive)
- During `advanceGeneration()`, the index list can be built in the same loop that computes survival/birth — one `append` per alive cell adds negligible overhead
- For pattern loaders that call `setCell` many times, append incrementally during loading and optionally rebuild at the end for safety
- Interactive `toggleCell` maintains the list with `append`/`removeAll { $0 == idx }` — O(alive) removal is acceptable for single-cell edits
- The decomposition from flat index back to (x,y,z) is: `x = idx / (size*size), y = (idx / size) % size, z = idx % size`
- For 32³ grid with ~5K alive: 5K iterations vs 32K = ~6.5x fewer iterations in the render-critical mesh build path

---

## ContinuousClock for Performance Measurement

- `ContinuousClock.now` provides monotonic time suitable for measuring code execution
- Duration components: `.components.attoseconds` gives raw attosecond count (Int64)
- Convert to milliseconds: `attoseconds / 1_000_000_000_000_000.0`
- Preferred over `Date()` for timing because it's monotonic (not affected by wall clock changes)
- Lightweight: no allocation, just reads the system monotonic clock

---

## @Observable Computed Properties and SwiftUI Frame Allocation

- `@Observable` computed properties (no backing `var`) are re-evaluated on every SwiftUI view access — potentially every frame at 60fps
- Circular buffer properties that reconstruct arrays (`Array(slice) + Array(slice)`) allocate on every access
- Pattern: replace computed properties with `private(set) var` + explicit rebuild function called at the mutation site (e.g., once per `step()`)
- For display-only data (sparklines, trend indicators), rebuilding once per generation is sufficient — no visual difference vs per-frame
- Must also clear the cached value at every reset/restart path to avoid stale data

---

## Bulk Array Zeroing with withUnsafeMutableBufferPointer

- `for i in 0..<count { array[i] = 0 }` performs per-element indexed writes with Swift bounds checking
- `array.withUnsafeMutableBufferPointer { $0.update(repeating: 0) }` compiles down to a single `memset` call — no bounds checks, no loop overhead
- For `[Int]` arrays, this zeroes `count * MemoryLayout<Int>.stride` bytes in one operation
- At 32³ grid (32,768 ints = 262KB), the difference is measurable in the hot path of `advanceGeneration()`
- Also applies to `clearAll()` and any bulk reset operation on pre-allocated buffers
- `withUnsafeMutableBytes { $0.initializeMemory(as: UInt8.self, repeating: 0) }` is an alternative but `update(repeating:)` is type-safe and clearer
- **Swift exclusivity caveat**: accessing `self` properties inside the closure creates overlapping access with the mutable buffer pointer. Fix by capturing needed values (like `cellCount`) as locals before the closure

---

## Static Template Arrays for Repeated Mesh Builds

- Constant template data (cube vertex positions, normals, UVs, indices) allocated as local `let` inside a hot function creates heap allocations per call
- Moving to `static let` on the enclosing type allocates once and shares across all calls
- Unit coordinates (±0.5) with runtime scaling by `cellSize` keeps the template generic while avoiding per-call recomputation
- At 5 mesh rebuilds/second, this eliminates ~20 array allocations/second for 4 template arrays

---

## Set-Backed Index for O(1) Interactive Cell Removal

- Maintaining `aliveCellIndices: [Int]` alongside a `aliveCellIndexSet: Set<Int>` gives O(alive) iteration for rendering AND O(1) membership/removal for interactive edits
- `Array.removeAll { $0 == idx }` is O(n) — unacceptable during drag-to-paint where many cells toggle per frame
- Swap-remove pattern: `array.swapRemove(at: i)` swaps element with last and removes — O(1) but doesn't preserve order
- For mesh rendering, order doesn't matter (cells are bucket-sorted by age tier anyway), so unordered removal is safe
- The set must be maintained in ALL mutation paths: `setCell`, `toggleCell`, `advanceGeneration`, `rebuildAliveCellIndices`, `clearAll`
- In `advanceGeneration`, inserting into the set during the main loop adds minimal overhead since the set already has capacity from `removeAll(keepingCapacity:)`

---

## O(alive) Reverse Map Reset for Sparse Index Tracking

- When maintaining a reverse-mapping array (`aliveIndexMap[cellIndex] → position`) alongside an index list, the map must be reset each generation
- Naive approach: `for i in 0..<cellCount { map[i] = -1 }` is O(n³) for an n³ grid — 32K iterations at 32³
- Optimized: iterate the old `aliveCellIndices` before clearing it — reset only entries that were actually set to non-(-1) values
- For typical 3D cellular automata with 5-25% alive, this is 3-6x fewer resets (e.g., 5K vs 32K at 32³)
- Critical ordering: reset map entries BEFORE `removeAll(keepingCapacity:)` on the index list, since we need the old indices to know which map entries to clear
- Same optimization applies to `clearAll()` in principle, but `clearAll` also zeros the cells array in O(n³), so the map reset isn't the bottleneck there

---

## AVAudioEngine Player Pool Lifecycle

- `AVAudioPlayerNode` references are NOT invalidated by `AVAudioEngine.stop()` — the player objects and arrays persist
- If `setup()` appends new players without clearing old arrays, the arrays grow by poolSize each setup/stop cycle
- Only the last poolSize players are attached to the new engine; earlier entries reference detached players
- Fix: clear all player arrays, buffers, and node references in `stop()` before setting `isSetup = false`
- Same pattern applies to any engine-attached resource pool (environment nodes, mixer nodes, etc.)

---

## visionOS Immersive Space Error Handling

- `openImmersiveSpace(id:)` returns `OpenImmersiveSpaceAction.Result` with `.opened`, `.userCancelled`, `.error` cases
- Must check the result — silent failure leaves the app in a broken state (simulation bar visible but no 3D content)
- On failure, reset navigation state and fade the launch view back in for a graceful recovery
- Always include `@unknown default` case for future-proofing against new result types

---

## Toroidal (Wrapping) Grid Topology

- Wrapping boundary cells use `(coord + delta + size) % size` — the `+ size` prevents negative modulo in Swift (which preserves sign: `-1 % 8 = -1`, not `7`)
- Interior cells (distance >1 from any face) are unaffected by topology — the fast-path offset-based neighbor counting works identically in both modes
- For 32³, only 18% of cells (boundary cells) take the wrapping path — performance impact is minimal since the fast interior path dominates
- Wrapping changes simulation dynamics significantly: edge-effect extinction is eliminated, patterns that die at boundaries now sustain and flow across, and stable oscillators are more likely at smaller grid sizes
- The `advanceGeneration` boundary code path splits into two branches (wrapping vs finite) rather than a single branch with conditional wrapping — avoids a per-neighbor conditional in the hot loop

---

## Bulk Fill for Non-Zero Values with withUnsafeMutableBufferPointer

- `withUnsafeMutableBufferPointer { $0.update(repeating: value) }` works for any `value`, not just zero — unlike `memset` which only writes byte patterns
- For `aliveIndexMap` (sentinel value `-1`), this replaces a per-element `for i in 0..<count { arr[i] = -1 }` loop that has Swift bounds checking overhead
- The compiler can auto-vectorize `update(repeating:)` into SIMD stores, which is especially effective for `-1` (all-bits-set pattern)
- Same pattern as the `cells`/`nextCells` bulk zeroing, but proves the technique generalizes to any fill value
- No exclusivity issues since no `self` properties are captured inside the closure (the buffer pointer owns the memory for the duration)
