import RealityKit

enum GridRenderer {
    static let cellSize: Float = 0.02
    static let cellSpacing: Float = 0.005

    /// Builds the entire grid as a SINGLE merged mesh entity.
    /// Instead of one ModelEntity per cell, all cube geometry is combined
    /// into one MeshResource — one draw call for the whole grid.
    @MainActor
    static func makeGridAsync(model: GridModel) async throws -> Entity {
        // Build merged mesh data off the main thread
        let meshResource = try await Task.detached {
            try generateMergedMesh(model: model)
        }.value

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .init(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.35))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.35))
        material.emissiveColor = .init(color: .init(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0))
        material.emissiveIntensity = 0.3

        let entity = ModelEntity(mesh: meshResource, materials: [material])
        entity.name = "CellGrid"
        return entity
    }

    /// Generates a single MeshResource containing all cubes merged together.
    /// Each cube has 24 vertices (4 per face for correct normals) and 36 indices.
    private static func generateMergedMesh(model: GridModel) throws -> MeshResource {
        let cubeVertexCount = 24  // 6 faces * 4 vertices
        let cubeIndexCount = 36   // 6 faces * 2 triangles * 3 indices
        let totalVertices = model.cellCount * cubeVertexCount
        let totalIndices = model.cellCount * cubeIndexCount

        var positions: [SIMD3<Float>] = []
        var normals: [SIMD3<Float>] = []
        var uvs: [SIMD2<Float>] = []
        var indices: [UInt32] = []
        positions.reserveCapacity(totalVertices)
        normals.reserveCapacity(totalVertices)
        uvs.reserveCapacity(totalVertices)
        indices.reserveCapacity(totalIndices)

        let half = cellSize / 2.0
        let r = cellSize * 0.1  // corner radius approximation — ignored for mesh, kept for visual consistency note

        // Unit cube vertex data: 6 faces, 4 vertices each, with per-face normals
        // Face order: +X, -X, +Y, -Y, +Z, -Z
        let cubePositions: [SIMD3<Float>] = [
            // +X face
            SIMD3( half, -half, -half), SIMD3( half,  half, -half),
            SIMD3( half,  half,  half), SIMD3( half, -half,  half),
            // -X face
            SIMD3(-half, -half,  half), SIMD3(-half,  half,  half),
            SIMD3(-half,  half, -half), SIMD3(-half, -half, -half),
            // +Y face
            SIMD3(-half,  half,  half), SIMD3( half,  half,  half),
            SIMD3( half,  half, -half), SIMD3(-half,  half, -half),
            // -Y face
            SIMD3(-half, -half, -half), SIMD3( half, -half, -half),
            SIMD3( half, -half,  half), SIMD3(-half, -half,  half),
            // +Z face
            SIMD3(-half, -half,  half), SIMD3( half, -half,  half),
            SIMD3( half,  half,  half), SIMD3(-half,  half,  half),
            // -Z face
            SIMD3( half, -half, -half), SIMD3(-half, -half, -half),
            SIMD3(-half,  half, -half), SIMD3( half,  half, -half),
        ]

        let cubeNormals: [SIMD3<Float>] = [
            // +X
            SIMD3(1,0,0), SIMD3(1,0,0), SIMD3(1,0,0), SIMD3(1,0,0),
            // -X
            SIMD3(-1,0,0), SIMD3(-1,0,0), SIMD3(-1,0,0), SIMD3(-1,0,0),
            // +Y
            SIMD3(0,1,0), SIMD3(0,1,0), SIMD3(0,1,0), SIMD3(0,1,0),
            // -Y
            SIMD3(0,-1,0), SIMD3(0,-1,0), SIMD3(0,-1,0), SIMD3(0,-1,0),
            // +Z
            SIMD3(0,0,1), SIMD3(0,0,1), SIMD3(0,0,1), SIMD3(0,0,1),
            // -Z
            SIMD3(0,0,-1), SIMD3(0,0,-1), SIMD3(0,0,-1), SIMD3(0,0,-1),
        ]

        let cubeUVs: [SIMD2<Float>] = [
            // Each face gets the same UV quad
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        ]

        // Two triangles per face: 0-1-2, 0-2-3
        let cubeIndices: [UInt32] = [
             0,  1,  2,   0,  2,  3,  // +X
             4,  5,  6,   4,  6,  7,  // -X
             8,  9, 10,   8, 10, 11,  // +Y
            12, 13, 14,  12, 14, 15,  // -Y
            16, 17, 18,  16, 18, 19,  // +Z
            20, 21, 22,  20, 22, 23,  // -Z
        ]

        // Build merged geometry for all cells
        var cellIndex: UInt32 = 0
        for x in 0..<model.size {
            for y in 0..<model.size {
                for z in 0..<model.size {
                    let center = model.cellPosition(
                        x: x, y: y, z: z,
                        cellSize: cellSize, cellSpacing: cellSpacing
                    )

                    let vertexOffset = cellIndex * UInt32(cubeVertexCount)

                    // Offset cube positions by cell center
                    for pos in cubePositions {
                        positions.append(pos + center)
                    }
                    normals.append(contentsOf: cubeNormals)
                    uvs.append(contentsOf: cubeUVs)

                    // Offset indices
                    for idx in cubeIndices {
                        indices.append(idx + vertexOffset)
                    }

                    cellIndex += 1
                }
            }
        }

        // Build MeshResource from merged data
        var meshDescriptor = MeshDescriptor(name: "MergedGrid")
        meshDescriptor.positions = MeshBuffer(positions)
        meshDescriptor.normals = MeshBuffer(normals)
        meshDescriptor.textureCoordinates = MeshBuffer(uvs)
        meshDescriptor.primitives = .triangles(indices)

        return try MeshResource.generate(from: [meshDescriptor])
    }
}
