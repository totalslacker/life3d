import RealityKit

@MainActor
enum GridRenderer {
    static let cellSize: Float = 0.02
    static let cellSpacing: Float = 0.005

    static func makeGrid(model: GridModel) -> Entity {
        let root = Entity()
        root.name = "CellGrid"

        let mesh = MeshResource.generateBox(size: cellSize, cornerRadius: cellSize * 0.1)
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .init(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.35))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.35))
        material.emissiveColor = .init(color: .init(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0))
        material.emissiveIntensity = 0.3

        for x in 0..<model.size {
            for y in 0..<model.size {
                for z in 0..<model.size {
                    let cell = ModelEntity(mesh: mesh, materials: [material])
                    cell.position = model.cellPosition(
                        x: x, y: y, z: z,
                        cellSize: cellSize, cellSpacing: cellSpacing
                    )
                    cell.name = "cell_\(x)_\(y)_\(z)"
                    root.addChild(cell)
                }
            }
        }

        return root
    }
}
