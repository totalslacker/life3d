import SwiftUI
import RealityKit

struct GridImmersiveView: View {
    @Environment(SimulationEngine.self) private var engine
    @State private var gridEntity: Entity?
    @State private var containerEntity: Entity?
    @State private var isRebuilding = false
    @State private var needsRebuild = false

    // Particle effect entities
    @State private var birthParticleEntities: [Entity] = []
    @State private var deathParticleEntities: [Entity] = []
    private static let maxParticleEmitters = 10

    // Point light entities for ambient cell glow
    @State private var lightEntities: [Entity] = []
    private static let maxPointLights = 8

    // Toggle pulse effect
    @State private var pulseEntity: Entity?

    // Boundary wireframe entity
    @State private var wireframeEntity: Entity?

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
            container.position = SIMD3<Float>(0, 1.5, -1.5)

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
            setupParticleEmitters(in: container)
            setupPointLights(in: container)
            setupPulseEntity(in: container)
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
            triggerParticles()
            triggerAudio()
            updatePointLights()
            // Skip mesh rebuild when no cells changed (stable state or extinction)
            if !engine.grid.bornCells.isEmpty || !engine.grid.dyingCells.isEmpty || !engine.grid.fadingCells.isEmpty {
                Task { await rebuildMesh() }
            }
        }
        .onChange(of: engine.theme) {
            updatePointLights()
            updateParticleEmitterColors()
            rebuildWireframe()
            Task { await rebuildMesh() }
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
                    let cellKey = coords.x * engine.grid.size * engine.grid.size + coords.y * engine.grid.size + coords.z
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
            let delta = rotationSpeed / 30.0
            while !Task.isCancelled {
                if !isDragging {
                    yawAngle += delta
                    dragStartYaw = yawAngle
                }
                try? await Task.sleep(nanoseconds: frameInterval)
            }
        }
    }

    // MARK: - Particle Effects

    /// Creates a particle emitter entity configured for birth or death effects.
    private static func makeParticleEmitter(isBirth: Bool, themeColors: ColorTheme.TierColors) -> Entity {
        let entity = Entity()
        var emitter = ParticleEmitterComponent()

        emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 0.3))
        emitter.emitterShape = .sphere
        emitter.emitterShapeSize = SIMD3<Float>(repeating: 0.01)
        emitter.burstCount = isBirth ? 12 : 8

        emitter.mainEmitter.lifeSpan = isBirth ? 0.5 : 0.8
        emitter.mainEmitter.size = isBirth ? 0.003 : 0.002
        emitter.mainEmitter.sizeVariation = isBirth ? 0.002 : 0.001
        emitter.mainEmitter.spreadingAngle = isBirth ? .pi : (.pi * 2.0 / 3.0)
        emitter.mainEmitter.acceleration = isBirth
            ? SIMD3<Float>(0, 0.01, 0)   // Birth: particles float up
            : SIMD3<Float>(0, -0.02, 0)  // Death: particles drift down

        let color = themeColors.emissiveColor
        emitter.mainEmitter.color = .constant(.single(.init(
            red: CGFloat(color.x), green: CGFloat(color.y), blue: CGFloat(color.z), alpha: 1.0)))

        emitter.mainEmitter.opacityCurve = .linearFadeOut

        emitter.isEmitting = false
        entity.components.set(emitter)
        entity.name = isBirth ? "BirthParticles" : "DeathParticles"
        return entity
    }

    /// Sets up particle emitter entities in the container.
    private func setupParticleEmitters(in container: Entity) {
        let birthColors = engine.theme.newborn
        let deathColors = engine.theme.dying

        var birthEntities: [Entity] = []
        var deathEntities: [Entity] = []

        for _ in 0..<Self.maxParticleEmitters {
            let birthEntity = Self.makeParticleEmitter(isBirth: true, themeColors: birthColors)
            container.addChild(birthEntity)
            birthEntities.append(birthEntity)

            let deathEntity = Self.makeParticleEmitter(isBirth: false, themeColors: deathColors)
            container.addChild(deathEntity)
            deathEntities.append(deathEntity)
        }

        birthParticleEntities = birthEntities
        deathParticleEntities = deathEntities
    }

    /// Triggers particle bursts at sampled birth/death positions.
    private func triggerParticles() {
        let cellSize = GridRenderer.cellSize
        let cellSpacing = GridRenderer.cellSpacing

        let bornPositions = engine.grid.bornCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)
        let dyingPositions = engine.grid.dyingCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)

        // Sample up to maxParticleEmitters positions from births
        let birthSample = samplePositions(bornPositions, count: Self.maxParticleEmitters)
        for (i, entity) in birthParticleEntities.enumerated() {
            if i < birthSample.count {
                entity.position = birthSample[i]
                entity.isEnabled = true
                if var emitter = entity.components[ParticleEmitterComponent.self] {
                    emitter.isEmitting = true
                    emitter.burstCount = min(12, max(4, bornPositions.count / Self.maxParticleEmitters))
                    entity.components.set(emitter)
                }
            } else {
                entity.isEnabled = false
            }
        }

        // Sample death positions
        let deathSample = samplePositions(dyingPositions, count: Self.maxParticleEmitters)
        for (i, entity) in deathParticleEntities.enumerated() {
            if i < deathSample.count {
                entity.position = deathSample[i]
                entity.isEnabled = true
                if var emitter = entity.components[ParticleEmitterComponent.self] {
                    emitter.isEmitting = true
                    emitter.burstCount = min(8, max(3, dyingPositions.count / Self.maxParticleEmitters))
                    entity.components.set(emitter)
                }
            } else {
                entity.isEnabled = false
            }
        }
    }

    /// Evenly samples positions from an array.
    private func samplePositions(_ positions: [SIMD3<Float>], count: Int) -> [SIMD3<Float>] {
        guard !positions.isEmpty else { return [] }
        if positions.count <= count { return positions }
        let step = positions.count / count
        return (0..<count).map { positions[$0 * step] }
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

    /// Repositions point lights at sampled alive cell positions with theme-appropriate color.
    private func updatePointLights() {
        let cellSize = GridRenderer.cellSize
        let cellSpacing = GridRenderer.cellSpacing
        let positions = engine.grid.aliveCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)

        let sample = samplePositions(positions, count: Self.maxPointLights)
        let emissive = engine.theme.newborn.emissiveColor

        for (i, entity) in lightEntities.enumerated() {
            if i < sample.count {
                entity.position = sample[i]
                entity.isEnabled = true
                if var light = entity.components[PointLightComponent.self] {
                    light.color = .init(
                        red: CGFloat(emissive.x),
                        green: CGFloat(emissive.y),
                        blue: CGFloat(emissive.z),
                        alpha: 1.0)
                    entity.components.set(light)
                }
            } else {
                entity.isEnabled = false
            }
        }
    }

    // MARK: - Toggle Pulse Effect

    /// Sets up a reusable pulse entity with a particle emitter for tap feedback.
    private func setupPulseEntity(in container: Entity) {
        let entity = Entity()
        entity.name = "TogglePulse"
        var emitter = ParticleEmitterComponent()
        emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 0.15))
        emitter.emitterShape = .sphere
        emitter.emitterShapeSize = SIMD3<Float>(repeating: 0.005)
        emitter.burstCount = 20

        emitter.mainEmitter.lifeSpan = 0.4
        emitter.mainEmitter.size = 0.004
        emitter.mainEmitter.sizeVariation = 0.002
        emitter.mainEmitter.spreadingAngle = .pi
        emitter.mainEmitter.acceleration = SIMD3<Float>(0, 0, 0)
        emitter.mainEmitter.color = .constant(.single(.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
        emitter.mainEmitter.opacityCurve = .linearFadeOut

        emitter.isEmitting = false
        entity.components.set(emitter)
        entity.isEnabled = false
        container.addChild(entity)
        pulseEntity = entity
    }

    /// Fires a brief white particle burst at the toggled cell position.
    private func triggerPulse(at position: SIMD3<Float>) {
        guard let entity = pulseEntity else { return }
        entity.position = position
        entity.isEnabled = true

        // Set color to match current theme's newborn emissive
        let emissive = engine.theme.newborn.emissiveColor
        if var emitter = entity.components[ParticleEmitterComponent.self] {
            emitter.mainEmitter.color = .constant(.single(.init(
                red: CGFloat(emissive.x),
                green: CGFloat(emissive.y),
                blue: CGFloat(emissive.z),
                alpha: 1.0)))
            emitter.isEmitting = true
            entity.components.set(emitter)
        }

        // Disable after the effect completes
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s
            entity.isEnabled = false
        }
    }

    // MARK: - Particle Color Updates

    /// Updates all particle emitter colors to match the current theme.
    private func updateParticleEmitterColors() {
        let birthColor = engine.theme.newborn.emissiveColor
        let deathColor = engine.theme.dying.emissiveColor

        for entity in birthParticleEntities {
            if var emitter = entity.components[ParticleEmitterComponent.self] {
                emitter.mainEmitter.color = .constant(.single(.init(
                    red: CGFloat(birthColor.x), green: CGFloat(birthColor.y),
                    blue: CGFloat(birthColor.z), alpha: 1.0)))
                entity.components.set(emitter)
            }
        }

        for entity in deathParticleEntities {
            if var emitter = entity.components[ParticleEmitterComponent.self] {
                emitter.mainEmitter.color = .constant(.single(.init(
                    red: CGFloat(deathColor.x), green: CGFloat(deathColor.y),
                    blue: CGFloat(deathColor.z), alpha: 1.0)))
                entity.components.set(emitter)
            }
        }
    }

    // MARK: - Spatial Audio

    private func triggerAudio() {
        let cellSize = GridRenderer.cellSize
        let cellSpacing = GridRenderer.cellSpacing
        let birthPositions = engine.grid.bornCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)
        let deathPositions = engine.grid.dyingCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)
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
            targetPosition = SIMD3<Float>(0, 1.5, -1.5)
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

    private func rebuildWireframe() {
        guard let container = containerEntity else { return }
        wireframeEntity?.removeFromParent()
        let wireframe = GridRenderer.makeBoundaryWireframe(gridSize: engine.grid.size, theme: engine.theme)
        container.addChild(wireframe)
        wireframeEntity = wireframe
    }

    // MARK: - Materialize/Dissolve Transition

    /// Animates the grid scaling up from near-zero and fading in.
    private func materializeIn() async {
        let steps = 30  // ~0.5s at 60fps
        let frameInterval: UInt64 = 16_000_000
        for i in 1...steps {
            let t = Float(i) / Float(steps)
            // Ease-out curve for snappy entry
            let eased = 1.0 - (1.0 - t) * (1.0 - t)
            materializeScale = eased
            materializeOpacity = eased
            try? await Task.sleep(nanoseconds: frameInterval)
        }
        materializeScale = 1.0
        materializeOpacity = 1.0
    }

    /// Animates the grid dissolving away — reverse of materializeIn.
    private func dissolveOut() async {
        let steps = 25  // ~0.4s at 60fps — slightly faster than materialize for snappy exit
        let frameInterval: UInt64 = 16_000_000
        for i in 1...steps {
            let t = Float(i) / Float(steps)
            // Ease-in curve: starts slow, accelerates into disappearance
            let eased = t * t
            materializeScale = 1.0 - eased * 0.7  // shrink to 30% (don't go to zero — feels more natural)
            materializeOpacity = 1.0 - eased
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
