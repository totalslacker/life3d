import RealityKit

enum GridRenderer {
    static let cellSize: Float = 0.02
    static let cellSpacing: Float = 0.005

    /// Builds cell entities off the main thread, then assembles the scene graph on MainActor.
    @MainActor
    static func makeGridAsync(model: GridModel) async -> Entity {
        let mesh = MeshResource.generateBox(size: cellSize, cornerRadius: cellSize * 0.1)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .init(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.35))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.35))
        material.emissiveColor = .init(color: .init(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0))
        material.emissiveIntensity = 0.3

        // Compute positions off the main thread
        let positions = await Task.detached {
            var result: [(String, SIMD3<Float>)] = []
            result.reserveCapacity(model.cellCount)
            for x in 0..<model.size {
                for y in 0..<model.size {
                    for z in 0..<model.size {
                        let pos = model.cellPosition(
                            x: x, y: y, z: z,
                            cellSize: cellSize, cellSpacing: cellSpacing
                        )
                        result.append(("cell_\(x)_\(y)_\(z)", pos))
                    }
                }
            }
            return result
        }.value

        // Build scene graph on MainActor in batches to avoid blocking
        let root = Entity()
        root.name = "CellGrid"
        let batchSize = 64
        for batchStart in stride(from: 0, to: positions.count, by: batchSize) {
            let batchEnd = min(batchStart + batchSize, positions.count)
            for i in batchStart..<batchEnd {
                let (name, position) = positions[i]
                let cell = ModelEntity(mesh: mesh, materials: [material])
                cell.position = position
                cell.name = name
                root.addChild(cell)
            }
            await Task.yield()
        }

        return root
    }
}
