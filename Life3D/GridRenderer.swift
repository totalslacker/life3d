import RealityKit

enum GridRenderer {
    static let cellSize: Float = 0.02
    static let cellSpacing: Float = 0.005

    /// Interleaved vertex layout for LowLevelMesh.
    struct GridVertex {
        var position: SIMD3<Float>
        var normal: SIMD3<Float>
        var uv: SIMD2<Float>
    }

    /// Pre-computed raw mesh data that can be built off the main thread.
    struct MeshData: Sendable {
        let vertices: [GridVertex]
        let indices: [UInt32]
        let gridExtent: Float
        let cellCount: Int
    }

    /// Builds a merged mesh entity for only the alive cells in the grid.
    @MainActor
    static func makeGridAsync(model: GridModel) async throws -> Entity {
        let data = await Task.detached {
            computeMeshData(model: model)
        }.value

        guard data.cellCount > 0 else {
            let entity = Entity()
            entity.name = "CellGrid"
            return entity
        }

        let meshResource = try createMeshResource(from: data)

        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: .init(red: 0.3, green: 0.8, blue: 1.0, alpha: 0.35))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.35))
        material.emissiveColor = .init(color: .init(red: 0.4, green: 0.9, blue: 1.0, alpha: 1.0))
        material.emissiveIntensity = 0.3

        let entity = ModelEntity(mesh: meshResource, materials: [material])
        entity.name = "CellGrid"
        return entity
    }

    /// Computes raw vertex and index arrays for alive cells only.
    private static func computeMeshData(model: GridModel) -> MeshData {
        let positions = model.aliveCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)
        let aliveCells = positions.count

        let cubeVertexCount = 24
        let cubeIndexCount = 36
        let totalVertices = aliveCells * cubeVertexCount
        let totalIndices = aliveCells * cubeIndexCount

        let half = cellSize / 2.0

        let cubePositions: [SIMD3<Float>] = [
            SIMD3( half, -half, -half), SIMD3( half,  half, -half),
            SIMD3( half,  half,  half), SIMD3( half, -half,  half),
            SIMD3(-half, -half,  half), SIMD3(-half,  half,  half),
            SIMD3(-half,  half, -half), SIMD3(-half, -half, -half),
            SIMD3(-half,  half,  half), SIMD3( half,  half,  half),
            SIMD3( half,  half, -half), SIMD3(-half,  half, -half),
            SIMD3(-half, -half, -half), SIMD3( half, -half, -half),
            SIMD3( half, -half,  half), SIMD3(-half, -half,  half),
            SIMD3(-half, -half,  half), SIMD3( half, -half,  half),
            SIMD3( half,  half,  half), SIMD3(-half,  half,  half),
            SIMD3( half, -half, -half), SIMD3(-half, -half, -half),
            SIMD3(-half,  half, -half), SIMD3( half,  half, -half),
        ]

        let cubeNormals: [SIMD3<Float>] = [
            SIMD3(1,0,0), SIMD3(1,0,0), SIMD3(1,0,0), SIMD3(1,0,0),
            SIMD3(-1,0,0), SIMD3(-1,0,0), SIMD3(-1,0,0), SIMD3(-1,0,0),
            SIMD3(0,1,0), SIMD3(0,1,0), SIMD3(0,1,0), SIMD3(0,1,0),
            SIMD3(0,-1,0), SIMD3(0,-1,0), SIMD3(0,-1,0), SIMD3(0,-1,0),
            SIMD3(0,0,1), SIMD3(0,0,1), SIMD3(0,0,1), SIMD3(0,0,1),
            SIMD3(0,0,-1), SIMD3(0,0,-1), SIMD3(0,0,-1), SIMD3(0,0,-1),
        ]

        let cubeUVs: [SIMD2<Float>] = [
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
            SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        ]

        let cubeIndices: [UInt32] = [
             0,  1,  2,   0,  2,  3,
             4,  5,  6,   4,  6,  7,
             8,  9, 10,   8, 10, 11,
            12, 13, 14,  12, 14, 15,
            16, 17, 18,  16, 18, 19,
            20, 21, 22,  20, 22, 23,
        ]

        guard aliveCells > 0 else {
            let stride = cellSize + cellSpacing
            let gridExtent = Float(model.size - 1) * stride / 2.0 + half
            return MeshData(vertices: [], indices: [], gridExtent: gridExtent, cellCount: 0)
        }

        var vertices = [GridVertex](
            repeating: GridVertex(position: .zero, normal: .zero, uv: .zero),
            count: totalVertices
        )
        var indices = [UInt32](repeating: 0, count: totalIndices)

        var vi = 0
        var ii = 0
        for center in positions {
            let vertexOffset = UInt32(vi)

            for j in 0..<cubeVertexCount {
                vertices[vi] = GridVertex(
                    position: cubePositions[j] + center,
                    normal: cubeNormals[j],
                    uv: cubeUVs[j]
                )
                vi += 1
            }

            for idx in cubeIndices {
                indices[ii] = idx + vertexOffset
                ii += 1
            }
        }

        let stride = cellSize + cellSpacing
        let gridExtent = Float(model.size - 1) * stride / 2.0 + half

        return MeshData(vertices: vertices, indices: indices, gridExtent: gridExtent, cellCount: aliveCells)
    }

    /// Creates a MeshResource from pre-computed mesh data using LowLevelMesh.
    @MainActor
    private static func createMeshResource(from data: MeshData) throws -> MeshResource {
        let vertexStride = MemoryLayout<GridVertex>.stride

        var descriptor = LowLevelMesh.Descriptor()
        descriptor.vertexCapacity = data.vertices.count
        descriptor.indexCapacity = data.indices.count

        descriptor.vertexAttributes = [
            .init(semantic: .position, format: .float3, layoutIndex: 0,
                  offset: MemoryLayout.offset(of: \GridVertex.position)!),
            .init(semantic: .normal, format: .float3, layoutIndex: 0,
                  offset: MemoryLayout.offset(of: \GridVertex.normal)!),
            .init(semantic: .uv0, format: .float2, layoutIndex: 0,
                  offset: MemoryLayout.offset(of: \GridVertex.uv)!),
        ]
        descriptor.vertexLayouts = [
            .init(bufferIndex: 0, bufferStride: vertexStride),
        ]
        descriptor.indexType = .uint32

        let mesh = try LowLevelMesh(descriptor: descriptor)

        mesh.withUnsafeMutableBytes(bufferIndex: 0) { buffer in
            let dest = buffer.bindMemory(to: GridVertex.self)
            for i in 0..<data.vertices.count {
                dest[i] = data.vertices[i]
            }
        }

        mesh.withUnsafeMutableIndices { buffer in
            let dest = buffer.bindMemory(to: UInt32.self)
            for i in 0..<data.indices.count {
                dest[i] = data.indices[i]
            }
        }

        let boundMin = SIMD3<Float>(repeating: -data.gridExtent)
        let boundMax = SIMD3<Float>(repeating: data.gridExtent)

        let part = LowLevelMesh.Part(
            indexCount: data.indices.count,
            topology: .triangle,
            bounds: BoundingBox(min: boundMin, max: boundMax)
        )
        mesh.parts.replaceAll([part])

        return try MeshResource(from: mesh)
    }
}
