import SwiftUI
import RealityKit

struct GridImmersiveView: View {
    @Environment(SimulationEngine.self) private var engine
    @State private var gridEntity: Entity?
    @State private var containerEntity: Entity?
    @State private var isRebuilding = false
    @State private var needsRebuild = false

    // Burst entity concurrency tracking
    @State private var activeBurstEntityCount: Int = 0
    private static let maxActiveBurstEntities = 40

    // Point light entities for ambient cell glow
    @State private var lightEntities: [Entity] = []
    private static let maxPointLights = 8

    // Particle emit durations — kept as constants so setup and trigger-site reset always match.
    // If these drift, the .once timing reset in triggerParticles/triggerPulse silently breaks.
    private static let birthEmitDuration: TimeInterval = 0.4
    private static let deathEmitDuration: TimeInterval = 0.3
    private static let pulseEmitDuration: TimeInterval = 0.15

    // Boundary wireframe entity
    @State private var wireframeEntity: Entity?
    // Wireframe material for color-only updates (avoids rebuilding 12 entities)
    @State private var wireframeMaterial: UnlitMaterial?

    // Spatial audio engine
    @State private var audioEngine = SpatialAudioEngine()

    // Rotation state
    @State private var yawAngle: Float = 0
    @State private var pitchAngle: Float = 0
    @State private var dragStartYaw: Float = 0
    @State private var dragStartPitch: Float = 0

    // Draw mode state — tracks which cells were already painted during this drag
    @State private var paintedCells: Set<Int> = []

    // Scale state
    @State private var currentScale: Float = 1.0
    @State private var magnifyStartScale: Float = 1.0

    // Auto-rotation and momentum state
    @State private var isDragging = false
    @State private var autoRotateTask: Task<Void, Never>?
    @State private var momentumTask: Task<Void, Never>?
    @State private var yawVelocity: Float = 0
    @State private var pitchVelocity: Float = 0
    @State private var lastDragTranslation: CGSize = .zero

    // Materialize/dissolve transition
    @State private var materializeScale: Float = 0.01
    @State private var materializeOpacity: Float = 0.0

    // Gesture onboarding overlay
    @State private var showOnboarding = false

    var body: some View {
        RealityView { content in
            let container = Entity()
            container.name = "GridContainer"
            container.position = SIMD3<Float>(0, 1.8, -1.5)

            // Collision box sized to actual grid extent for accurate gesture targeting
            let stride = GridRenderer.cellSize + GridRenderer.cellSpacing
            let gridExtent = Float(engine.grid.size - 1) * stride / 2.0 + GridRenderer.cellSize / 2.0
            container.components.set(InputTargetComponent())
            container.components.set(CollisionComponent(
                shapes: [.generateBox(size: SIMD3<Float>(repeating: gridExtent * 2.5))]
            ))
            // Hover effect: spotlight follows gaze, giving spatial feedback on where you're looking
            container.components.set(HoverEffectComponent())

            // Add boundary wireframe
            let wireframe = GridRenderer.makeBoundaryWireframe(gridSize: engine.grid.size, theme: engine.theme)
            container.addChild(wireframe)
            wireframeEntity = wireframe

            content.add(container)
            containerEntity = container
            setupPointLights(in: container)
        } update: { content in
            guard let container = containerEntity else { return }

            // Update rotation transform
            let yawRotation = simd_quatf(angle: yawAngle, axis: SIMD3<Float>(0, 1, 0))
            let pitchRotation = simd_quatf(angle: pitchAngle, axis: SIMD3<Float>(1, 0, 0))
            container.orientation = yawRotation * pitchRotation
            container.scale = SIMD3<Float>(repeating: currentScale * materializeScale)
            container.components[OpacityComponent.self] = OpacityComponent(opacity: materializeOpacity)

            // Swap grid entity if updated
            if let grid = gridEntity {
                let existing = container.children.first { $0.name == "CellGrid" }
                if existing == nil {
                    container.addChild(grid)
                } else if let old = existing, old !== grid {
                    old.removeFromParent()
                    container.addChild(grid)
                }
            }
        }
        .gesture(spatialTapGesture)
        .gesture(dragGesture)
        .gesture(magnifyGesture)
        .task {
            await rebuildMesh()
        }
        .task {
            startAutoRotation()
            audioEngine.setup()
            // Materialize animation: scale up and fade in over ~0.6s
            await materializeIn()
            // Show gesture onboarding on first launch
            if !UserDefaults.standard.bool(forKey: "life3d.hasSeenOnboarding") {
                withAnimation(.easeIn(duration: 0.4)) {
                    showOnboarding = true
                }
                UserDefaults.standard.set(true, forKey: "life3d.hasSeenOnboarding")
                // Auto-dismiss after 5 seconds
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                withAnimation(.easeOut(duration: 0.3)) {
                    showOnboarding = false
                }
            }
        }
        .onChange(of: engine.generation) {
            // Compute birth/death positions once per generation (used by particles, lights, and audio)
            let cellSize = GridRenderer.cellSize
            let cellSpacing = GridRenderer.cellSpacing
            let birthPositions = engine.grid.bornCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)
            let deathPositions = engine.grid.dyingCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)

            triggerParticles(birthPositions: birthPositions, deathPositions: deathPositions)
            triggerAudio(birthPositions: birthPositions, deathPositions: deathPositions)
            updatePointLights(birthPositions: birthPositions)
            // Skip mesh rebuild when no cells changed (stable state or extinction)
            if !engine.grid.bornCells.isEmpty || !engine.grid.dyingCells.isEmpty || !engine.grid.fadingCells.isEmpty {
                Task { await rebuildMesh() }
            }
        }
        .onChange(of: engine.theme) {
            updatePointLights(birthPositions: [])
            updateWireframeColor()
            Task { await rebuildMesh() }
        }
        .onChange(of: engine.grid.size) {
            rebuildWireframe()
        }
        .onChange(of: engine.gridEpoch) {
            // Grid was replaced (e.g. size change) — clear stale draw mode indices
            paintedCells.removeAll()
        }
        .onChange(of: engine.surroundMode) {
            applySurroundMode()
        }
        .onChange(of: engine.isExiting) {
            if engine.isExiting {
                Task {
                    audioEngine.stop()
                    autoRotateTask?.cancel()
                    momentumTask?.cancel()
                    await dissolveOut()
                    engine.exitAnimationComplete = true
                }
            }
        }
        .onChange(of: engine.audioMuted) {
            audioEngine.isMuted = engine.audioMuted
        }
        .onChange(of: engine.speed) {
            audioEngine.updateSpeed(engine.speed)
        }
        .onChange(of: engine.showHelp) {
            if engine.showHelp {
                engine.showHelp = false
                withAnimation(.easeIn(duration: 0.4)) {
                    showOnboarding = true
                }
                Task {
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    withAnimation(.easeOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                }
            }
        }
        .overlay {
            if showOnboarding {
                GestureOnboardingOverlay()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            showOnboarding = false
                        }
                    }
            }
        }
        .overlay(alignment: .bottom) {
            if engine.showExtinctionNotice {
                ExtinctionNoticeView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 40)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: engine.showExtinctionNotice)
        .onDisappear {
            autoRotateTask?.cancel()
            momentumTask?.cancel()
            audioEngine.stop()
        }
    }

    // MARK: - Gestures

    private var spatialTapGesture: some Gesture {
        SpatialTapGesture()
            .targetedToAnyEntity()
            .onEnded { value in
                guard let container = containerEntity else { return }
                // location3D is in the tapped entity's local coordinate space
                // The entity with collision is the container, so this is already in grid space
                let localPos = value.convert(value.location3D, from: .local, to: .scene)
                // Transform scene position into container's local space
                let containerWorldTransform = container.transformMatrix(relativeTo: nil)
                let inverseTransform = containerWorldTransform.inverse
                let localPoint = inverseTransform * SIMD4<Float>(localPos.x, localPos.y, localPos.z, 1.0)
                let togglePos = SIMD3<Float>(localPoint.x, localPoint.y, localPoint.z)
                engine.toggleCell(at: togglePos)
                triggerPulse(at: togglePos)
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                if engine.drawMode {
                    // Draw mode: convert drag position to cell coordinates and paint
                    guard let container = containerEntity else { return }
                    isDragging = true
                    let scenePos = value.convert(value.location3D, from: .local, to: .scene)
                    let containerWorldTransform = container.transformMatrix(relativeTo: nil)
                    let inverseTransform = containerWorldTransform.inverse
                    let localPoint = inverseTransform * SIMD4<Float>(scenePos.x, scenePos.y, scenePos.z, 1.0)
                    let pos = SIMD3<Float>(localPoint.x, localPoint.y, localPoint.z)
                    let coords = engine.grid.nearestGridCoords(for: pos, cellSize: GridRenderer.cellSize, cellSpacing: GridRenderer.cellSpacing)
                    let cellKey = engine.grid.index(x: coords.x, y: coords.y, z: coords.z)
                    if !paintedCells.contains(cellKey) {
                        paintedCells.insert(cellKey)
                        let isAlive = engine.grid.isAlive(x: coords.x, y: coords.y, z: coords.z)
                        if engine.eraserMode {
                            // Eraser: remove cells
                            if isAlive {
                                engine.grid.setCell(x: coords.x, y: coords.y, z: coords.z, alive: false)
                                engine.generation += 1
                            }
                        } else {
                            // Paint: add cells
                            if !isAlive {
                                engine.grid.setCell(x: coords.x, y: coords.y, z: coords.z, alive: true)
                                engine.generation += 1
                            }
                        }
                        triggerPulse(at: pos)
                    }
                } else {
                    // Rotate mode: normal rotation behavior
                    isDragging = true
                    momentumTask?.cancel()
                    let sensitivity: Float = 0.005
                    let newYaw = dragStartYaw + Float(value.translation.width) * sensitivity
                    let newPitch = dragStartPitch - Float(value.translation.height) * sensitivity
                    yawVelocity = Float(value.translation.width - lastDragTranslation.width) * sensitivity
                    pitchVelocity = Float(-(value.translation.height - lastDragTranslation.height)) * sensitivity
                    lastDragTranslation = value.translation
                    yawAngle = newYaw
                    pitchAngle = min(max(newPitch, -.pi / 2), .pi / 2)
                }
            }
            .onEnded { _ in
                isDragging = false
                if engine.drawMode {
                    paintedCells.removeAll()
                } else {
                    dragStartYaw = yawAngle
                    dragStartPitch = pitchAngle
                    lastDragTranslation = .zero
                    startMomentum()
                }
            }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                let scale = Float(value.magnification)
                currentScale = magnifyStartScale * scale
                currentScale = min(max(currentScale, 0.3), 5.0)
            }
            .onEnded { _ in
                magnifyStartScale = currentScale
            }
    }

    // MARK: - Drag Momentum

    private func startMomentum() {
        let threshold: Float = 0.0005
        guard abs(yawVelocity) > threshold || abs(pitchVelocity) > threshold else { return }
        momentumTask = Task {
            let friction: Float = 0.92
            let frameInterval: UInt64 = 16_000_000  // ~60fps
            while !Task.isCancelled {
                yawVelocity *= friction
                pitchVelocity *= friction
                if abs(yawVelocity) < threshold && abs(pitchVelocity) < threshold { break }
                yawAngle += yawVelocity
                pitchAngle += pitchVelocity
                pitchAngle = min(max(pitchAngle, -.pi / 2), .pi / 2)
                dragStartYaw = yawAngle
                dragStartPitch = pitchAngle
                try? await Task.sleep(nanoseconds: frameInterval)
            }
        }
    }

    // MARK: - Auto-Rotation

    private func startAutoRotation() {
        autoRotateTask = Task {
            let rotationSpeed: Float = 0.1  // radians per second (~6°/s)
            let frameInterval: UInt64 = 33_000_000  // ~30fps
            var lastTime = ContinuousClock.now
            while !Task.isCancelled {
                let now = ContinuousClock.now
                let elapsed = now - lastTime
                lastTime = now
                let dt = Float(elapsed.components.attoseconds) / 1e18  // seconds
                if !isDragging && !engine.drawMode {
                    yawAngle += rotationSpeed * dt
                    dragStartYaw = yawAngle
                }
                try? await Task.sleep(nanoseconds: frameInterval)
            }
        }
    }

    // MARK: - Particle Effects

    /// Returns a freshly configured ParticleEmitterComponent for birth or death effects.
    ///
    /// Used at spawn time — each call site creates a fresh Entity and attaches this component.
    /// Cell size = 0.015m; kinematics: d = 0.5 × a × t² keeps particles ≤ 2 cell widths.
    private static func makeParticleEmitterComponent(isBirth: Bool, themeColors: ColorTheme.TierColors) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        // Cap initial speed so bursts stay near the source cell (~2 cell widths). Default ~0.5 m/s
        // would send particles across the full grid; 0.02 m/s limits travel to ~2–5 cm over lifespan.
        emitter.speed = 0.02
        emitter.speedVariation = 0.01

        emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: isBirth ? Self.birthEmitDuration : Self.deathEmitDuration))
        emitter.emitterShape = .sphere
        // ~½ cell diameter — particles spawn within the cell boundary (cell = 0.015m)
        emitter.emitterShapeSize = SIMD3<Float>(repeating: 0.008)
        // burstCount is set by the caller at trigger time — trigger site is the sole source of truth.

        emitter.mainEmitter.lifeSpan = isBirth ? 0.7 : 1.0
        // 40%/33% of cell size; clearly visible (~11/9px) at 1.5m without obscuring cubes
        emitter.mainEmitter.size = isBirth ? 0.006 : 0.005
        emitter.mainEmitter.sizeVariation = 0.002   // min effective: birth 0.004m, death 0.003m
        emitter.mainEmitter.spreadingAngle = .pi / 6
        emitter.mainEmitter.acceleration = isBirth
            ? SIMD3<Float>(0, 0.12, 0)   // d = 0.5×0.12×0.7² = 0.029m ≈ 2 cell widths
            : SIMD3<Float>(0, -0.06, 0)  // d = 0.5×0.06×1.0² = 0.030m ≈ 2 cell widths

        let color = themeColors.emissiveColor
        emitter.mainEmitter.color = .constant(.single(.init(
            red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: 1.0)))

        emitter.mainEmitter.opacityCurve = .linearFadeOut
        emitter.isEmitting = false
        return emitter
    }

    /// Spawns a fresh burst entity at the given position and schedules its self-removal.
    ///
    /// Each call allocates a new Entity — no entity is ever reused across burst cycles.
    /// A newly constructed entity carries no prior VFX "has-fired" state (see ADR 001, Option E).
    private func spawnBurst(at position: SIMD3<Float>, isBirth: Bool) {
        guard let container = containerEntity,
              activeBurstEntityCount < Self.maxActiveBurstEntities else { return }

        let themeColors = isBirth ? engine.theme.newborn : engine.theme.dying
        var emitter = Self.makeParticleEmitterComponent(isBirth: isBirth, themeColors: themeColors)
        emitter.isEmitting = true
        emitter.burstCount = isBirth ? 12 : 8

        let entity = Entity()
        entity.name = isBirth ? "BirthBurst" : "DeathBurst"
        entity.position = position
        entity.components.set(emitter)
        container.addChild(entity)

        activeBurstEntityCount += 1
        // birth: 0.4s emit + 0.7s lifeSpan + 0.1s buffer = 1.2s
        // death: 0.3s emit + 1.0s lifeSpan + 0.1s buffer = 1.4s
        let delayNanos: UInt64 = isBirth ? 1_200_000_000 : 1_400_000_000
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: delayNanos)
            entity.removeFromParent()
            activeBurstEntityCount -= 1
        }
    }

    /// Triggers particle bursts at sampled birth/death positions.
    private func triggerParticles(birthPositions bornPositions: [SIMD3<Float>], deathPositions dyingPositions: [SIMD3<Float>]) {
        let birthSample = samplePositions(bornPositions, count: 20)
        for position in birthSample {
            spawnBurst(at: position, isBirth: true)
        }

        let deathSample = samplePositions(dyingPositions, count: 20)
        for position in deathSample {
            spawnBurst(at: position, isBirth: false)
        }
    }

    /// Evenly samples positions from an array using multiply-then-divide for uniform distribution.
    private func samplePositions(_ positions: [SIMD3<Float>], count: Int) -> [SIMD3<Float>] {
        guard !positions.isEmpty, count > 0 else { return [] }
        if positions.count <= count { return Array(positions.prefix(count)) }
        return (0..<count).map { i in positions[i * positions.count / count] }
    }

    // MARK: - Point Lights

    /// Sets up a pool of point light entities that will be positioned at alive cell locations.
    private func setupPointLights(in container: Entity) {
        var lights: [Entity] = []
        for _ in 0..<Self.maxPointLights {
            let lightEntity = Entity()
            lightEntity.name = "CellLight"
            var light = PointLightComponent()
            light.intensity = 50  // lumens — soft ambient glow
            light.attenuationRadius = 0.15  // light fades within 15cm
            lightEntity.components.set(light)
            lightEntity.isEnabled = false
            container.addChild(lightEntity)
            lights.append(lightEntity)
        }
        lightEntities = lights
    }

    /// Repositions point lights at born cell positions (avoids scanning all n³ cells).
    /// Lights that have no new births nearby keep their previous position, creating
    /// a stable ambient glow that gradually shifts with simulation activity.
    private func updatePointLights(birthPositions: [SIMD3<Float>]) {
        let emissive = engine.theme.newborn.emissiveColor

        // Place lights at newly born cell positions (most visually active areas)
        let sample = samplePositions(birthPositions, count: Self.maxPointLights)

        for (i, entity) in lightEntities.enumerated() {
            if i < sample.count {
                // New birth position: move light there
                entity.position = sample[i]
                entity.isEnabled = true
            } else if engine.grid.aliveCount == 0 {
                // No alive cells: disable lights
                entity.isEnabled = false
            }
            // Otherwise: keep previous position (stable ambient glow)

            // Update color for all enabled lights (theme may have changed)
            if entity.isEnabled {
                if var light = entity.components[PointLightComponent.self] {
                    light.color = .init(
                        red: CGFloat(emissive.x),
                        green: CGFloat(emissive.y),
                        blue: CGFloat(emissive.z),
                        alpha: 1.0)
                    entity.components.set(light)
                }
            }
        }
    }

    // MARK: - Toggle Pulse Effect

    /// Returns a freshly configured ParticleEmitterComponent for tap-feedback pulse effects.
    ///
    /// Used at spawn time — `triggerPulse(at:)` creates a fresh Entity and attaches this component.
    private static func makePulseEmitterComponent(themeColor: SIMD3<Float>) -> ParticleEmitterComponent {
        var emitter = ParticleEmitterComponent()
        // Cap initial speed to keep pulse burst within ~1 cell of the tap point (zero acceleration
        // here, so speed alone drives travel: 0.02 m/s × 0.4 s ≈ 0.8 cm max radius).
        emitter.speed = 0.02
        emitter.speedVariation = 0.01
        emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: Self.pulseEmitDuration))
        emitter.emitterShape = .sphere
        emitter.emitterShapeSize = SIMD3<Float>(repeating: 0.005)
        emitter.burstCount = 20

        emitter.mainEmitter.lifeSpan = 0.4
        emitter.mainEmitter.size = 0.004
        emitter.mainEmitter.sizeVariation = 0.002
        emitter.mainEmitter.spreadingAngle = .pi / 6
        emitter.mainEmitter.acceleration = SIMD3<Float>(0, 0, 0)
        emitter.mainEmitter.color = .constant(.single(.init(
            red: CGFloat(themeColor.x),
            green: CGFloat(themeColor.y),
            blue: CGFloat(themeColor.z),
            alpha: 1.0)))
        emitter.mainEmitter.opacityCurve = .linearFadeOut
        emitter.isEmitting = false
        return emitter
    }

    /// Fires a brief particle burst at the toggled cell position.
    ///
    /// Each tap spawns a fresh entity — same destroy-and-recreate rationale as spawnBurst.
    /// Pulse is excluded from the activeBurstEntityCount cap (tap-triggered, low frequency).
    private func triggerPulse(at position: SIMD3<Float>) {
        guard let container = containerEntity else { return }

        let entity = Entity()
        entity.name = "TogglePulse"
        entity.position = position

        var emitter = Self.makePulseEmitterComponent(themeColor: engine.theme.newborn.emissiveColor)
        emitter.isEmitting = true
        entity.components.set(emitter)
        container.addChild(entity)

        // pulse: 0.15s emit + 0.4s lifeSpan + 0.1s buffer = 0.65s
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 650_000_000)
            entity.removeFromParent()
        }
    }

    // MARK: - Spatial Audio

    private func triggerAudio(birthPositions: [SIMD3<Float>], deathPositions: [SIMD3<Float>]) {
        audioEngine.triggerTones(birthPositions: birthPositions, deathPositions: deathPositions)
    }

    // MARK: - Surround Mode

    private func applySurroundMode() {
        guard let container = containerEntity else { return }
        // Cancel any active drag momentum to prevent interference with transition
        momentumTask?.cancel()
        isDragging = false
        let targetPosition: SIMD3<Float>
        let targetScale: Float
        if engine.surroundMode {
            targetPosition = SIMD3<Float>(0, 1.5, 0)
            targetScale = 3.0
        } else {
            targetPosition = SIMD3<Float>(0, 1.8, -1.5)
            targetScale = 1.0
        }
        Task {
            await animateSurroundTransition(container: container, targetPosition: targetPosition, targetScale: targetScale)
        }
    }

    /// Smoothly interpolates position and scale for surround mode transitions.
    private func animateSurroundTransition(container: Entity, targetPosition: SIMD3<Float>, targetScale: Float) async {
        let steps = 25  // ~0.4s at 60fps
        let frameInterval: UInt64 = 16_000_000
        let startPosition = container.position
        let startScale = currentScale

        for i in 1...steps {
            let t = Float(i) / Float(steps)
            // Ease-in-out curve: smooth acceleration and deceleration
            let eased = t * t * (3.0 - 2.0 * t)
            container.position = startPosition + (targetPosition - startPosition) * eased
            currentScale = startScale + (targetScale - startScale) * eased
            try? await Task.sleep(nanoseconds: frameInterval)
        }
        container.position = targetPosition
        currentScale = targetScale
        magnifyStartScale = targetScale
    }

    // MARK: - Wireframe

    /// Rebuilds the wireframe boundary to match the current grid size.
    private func rebuildWireframe() {
        guard let container = containerEntity else { return }
        wireframeEntity?.removeFromParent()
        let wireframe = GridRenderer.makeBoundaryWireframe(gridSize: engine.grid.size, theme: engine.theme)
        container.addChild(wireframe)
        wireframeEntity = wireframe

        // Update collision box to match new grid extent
        let stride = GridRenderer.cellSize + GridRenderer.cellSpacing
        let gridExtent = Float(engine.grid.size - 1) * stride / 2.0 + GridRenderer.cellSize / 2.0
        container.components.set(CollisionComponent(
            shapes: [.generateBox(size: SIMD3<Float>(repeating: gridExtent * 2.5))]
        ))
    }

    /// Updates wireframe edge colors to match the current theme without rebuilding entities.
    private func updateWireframeColor() {
        guard let wireframe = wireframeEntity else { return }
        let emissive = engine.theme.mature.emissiveColor
        var mat = UnlitMaterial()
        mat.color = .init(tint: .init(
            red: CGFloat(emissive.x), green: CGFloat(emissive.y),
            blue: CGFloat(emissive.z), alpha: 0.3))
        for child in wireframe.children {
            if let modelEntity = child as? ModelEntity {
                modelEntity.model?.materials = [mat]
            }
        }
    }

    // MARK: - Materialize/Dissolve Transition

    /// Animates the grid scaling up from near-zero and fading in with a gentle rotation flourish.
    /// The rotation adds cinematic presence — the grid spirals into view rather than just popping.
    private func materializeIn() async {
        let steps = 40  // ~0.67s at 60fps — slightly longer for the rotation to read
        let frameInterval: UInt64 = 16_000_000
        let rotationSweep: Float = .pi / 3  // 60° rotation during entry
        let startYaw = yawAngle - rotationSweep

        for i in 1...steps {
            let t = Float(i) / Float(steps)
            // Ease-out cubic for snappy entry that settles smoothly
            let eased = 1.0 - (1.0 - t) * (1.0 - t) * (1.0 - t)
            materializeScale = eased
            // Opacity leads slightly: fully visible by 80% of animation
            materializeOpacity = min(1.0, eased * 1.25)
            // Rotation flourish: sweep from offset to current yaw
            yawAngle = startYaw + rotationSweep * eased
            dragStartYaw = yawAngle
            try? await Task.sleep(nanoseconds: frameInterval)
        }
        materializeScale = 1.0
        materializeOpacity = 1.0
    }

    /// Animates the grid dissolving away with a slight spin-out and scale shrink.
    private func dissolveOut() async {
        let steps = 30  // ~0.5s at 60fps
        let frameInterval: UInt64 = 16_000_000
        let startYaw = yawAngle

        for i in 1...steps {
            let t = Float(i) / Float(steps)
            // Ease-in curve: starts slow, accelerates into disappearance
            let eased = t * t
            materializeScale = 1.0 - eased * 0.7  // shrink to 30%
            materializeOpacity = 1.0 - eased
            // Gentle spin during exit (30° over the dissolve)
            yawAngle = startYaw + eased * (.pi / 6)
            try? await Task.sleep(nanoseconds: frameInterval)
        }
        materializeScale = 0.01
        materializeOpacity = 0.0
    }

    // MARK: - Mesh Building

    private func rebuildMesh() async {
        guard !isRebuilding else {
            needsRebuild = true
            return
        }
        isRebuilding = true
        repeat {
            needsRebuild = false
            do {
                let grid = try await GridRenderer.makeGridAsync(model: engine.grid, theme: engine.theme)
                // Grid is centered at origin — container handles world position
                gridEntity = grid
            } catch {
                print("Failed to build grid: \(error)")
            }
        } while needsRebuild
        isRebuilding = false
    }
}

/// Brief overlay showing available gestures on first simulation launch.
struct GestureOnboardingOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Gestures")
                .font(.headline)

            HStack(spacing: 24) {
                gestureHint(icon: "hand.tap", label: "Tap to toggle")
                gestureHint(icon: "hand.draw", label: "Drag to rotate")
                gestureHint(icon: "arrow.up.left.and.arrow.down.right", label: "Pinch to zoom")
            }

            Text("Tap anywhere to dismiss")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func gestureHint(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.primary)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 90)
    }
}

/// Brief notification shown when population goes extinct before auto-restart.
struct ExtinctionNoticeView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.callout)
            Text("Extinct — reseeding...")
                .font(.callout)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
        .foregroundStyle(.secondary)
    }
}
