import SwiftUI
import RealityKit

struct GridImmersiveView: View {
    @Environment(SimulationEngine.self) private var engine
    @State private var gridEntity: Entity?
    @State private var containerEntity: Entity?
    @State private var isRebuilding = false
    @State private var needsRebuild = false

    // Rotation state
    @State private var yawAngle: Float = 0
    @State private var pitchAngle: Float = 0
    @State private var dragStartYaw: Float = 0
    @State private var dragStartPitch: Float = 0

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

            content.add(container)
            containerEntity = container
        } update: { content in
            guard let container = containerEntity else { return }

            // Update rotation transform
            let yawRotation = simd_quatf(angle: yawAngle, axis: SIMD3<Float>(0, 1, 0))
            let pitchRotation = simd_quatf(angle: pitchAngle, axis: SIMD3<Float>(1, 0, 0))
            container.orientation = yawRotation * pitchRotation
            container.scale = SIMD3<Float>(repeating: currentScale)

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
        .gesture(dragGesture)
        .gesture(magnifyGesture)
        .task {
            await rebuildMesh()
        }
        .task {
            startAutoRotation()
        }
        .onChange(of: engine.generation) {
            Task { await rebuildMesh() }
        }
        .onChange(of: engine.theme) {
            Task { await rebuildMesh() }
        }
    }

    // MARK: - Gestures

    private var dragGesture: some Gesture {
        DragGesture()
            .targetedToAnyEntity()
            .onChanged { value in
                isDragging = true
                momentumTask?.cancel()
                let sensitivity: Float = 0.005
                let newYaw = dragStartYaw + Float(value.translation.width) * sensitivity
                let newPitch = dragStartPitch - Float(value.translation.height) * sensitivity
                // Track velocity from frame-to-frame translation delta
                yawVelocity = Float(value.translation.width - lastDragTranslation.width) * sensitivity
                pitchVelocity = Float(-(value.translation.height - lastDragTranslation.height)) * sensitivity
                lastDragTranslation = value.translation
                yawAngle = newYaw
                pitchAngle = min(max(newPitch, -.pi / 2), .pi / 2)
            }
            .onEnded { _ in
                isDragging = false
                dragStartYaw = yawAngle
                dragStartPitch = pitchAngle
                lastDragTranslation = .zero
                startMomentum()
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
