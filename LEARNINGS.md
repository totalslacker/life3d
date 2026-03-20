# Learnings

Technical insights accumulated during evolution. Avoids re-discovering
the same things. Search here before looking things up externally.

---

## visionOS Simulator Limitations

- The visionOS Simulator boots a full xrOS runtime and is extremely resource-heavy
- On some machines it crashes the host when launched (especially with volumetric windows)
- `xcodebuild test` launches the app as test host, triggering the simulator crash
- **Workaround**: Use `xcodebuild build` for CI verification, run tests manually on device or with logic-only test targets that don't require the simulator runtime
- Volumetric window style (`WindowGroup(...) { }.windowStyle(.volumetric)`) causes `UIWindowSceneSessionRoleApplication` mismatch on visionOS 2.1 sim — use plain `WindowGroup` with `RealityView` inside instead

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
