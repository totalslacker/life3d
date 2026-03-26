import RealityKit
import CoreGraphics

/// Color theme defining material properties for each age tier.
struct ColorTheme: Sendable, Identifiable, Hashable {
    let name: String
    var id: String { name }

    struct TierColors: Sendable, Hashable {
        let baseColor: SIMD4<Float>      // RGBA
        let emissiveColor: SIMD3<Float>  // RGB
        let emissiveIntensity: Float
        let opacity: Float
    }

    let newborn: TierColors
    let young: TierColors
    let mature: TierColors
    let dying: TierColors

    func colors(for tier: GridRenderer.AgeTier) -> TierColors {
        switch tier {
        case .newborn: return newborn
        case .young: return young
        case .mature: return mature
        case .dying: return dying
        }
    }

    // MARK: - Preset Themes

    static let neon = ColorTheme(
        name: "Neon",
        newborn: TierColors(
            baseColor: SIMD4(0.0, 0.95, 1.0, 1.0),
            emissiveColor: SIMD3(0.0, 0.9, 1.0),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.0, 0.6, 0.9, 1.0),
            emissiveColor: SIMD3(0.0, 0.5, 0.8),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.3, 0.1, 0.8, 1.0),
            emissiveColor: SIMD3(0.2, 0.05, 0.6),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.1, 0.3, 0.5, 1.0),
            emissiveColor: SIMD3(0.05, 0.2, 0.4),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let warmAmber = ColorTheme(
        name: "Warm Amber",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.85, 0.2, 1.0),
            emissiveColor: SIMD3(1.0, 0.7, 0.1),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(1.0, 0.5, 0.1, 1.0),
            emissiveColor: SIMD3(0.9, 0.4, 0.05),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.7, 0.2, 0.05, 1.0),
            emissiveColor: SIMD3(0.5, 0.1, 0.02),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.4, 0.15, 0.05, 1.0),
            emissiveColor: SIMD3(0.3, 0.08, 0.02),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let oceanBlues = ColorTheme(
        name: "Ocean Blues",
        newborn: TierColors(
            baseColor: SIMD4(0.3, 0.9, 1.0, 1.0),
            emissiveColor: SIMD3(0.2, 0.8, 1.0),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.1, 0.5, 0.9, 1.0),
            emissiveColor: SIMD3(0.05, 0.4, 0.8),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.0, 0.2, 0.5, 1.0),
            emissiveColor: SIMD3(0.0, 0.1, 0.4),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.0, 0.1, 0.25, 1.0),
            emissiveColor: SIMD3(0.0, 0.05, 0.2),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let aurora = ColorTheme(
        name: "Aurora",
        newborn: TierColors(
            baseColor: SIMD4(0.2, 1.0, 0.5, 1.0),
            emissiveColor: SIMD3(0.1, 0.9, 0.4),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.5, 0.3, 1.0, 1.0),
            emissiveColor: SIMD3(0.4, 0.2, 0.9),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.8, 0.1, 0.5, 1.0),
            emissiveColor: SIMD3(0.6, 0.05, 0.4),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.3, 0.05, 0.2, 1.0),
            emissiveColor: SIMD3(0.2, 0.02, 0.15),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let allThemes: [ColorTheme] = [.neon, .warmAmber, .oceanBlues, .aurora]
}

enum GridRenderer {
    static let cellSize: Float = 0.015
    static let cellSpacing: Float = 0.015

    /// Age tier for visual differentiation
    enum AgeTier: Int, CaseIterable {
        case newborn = 0  // age 1-2: bright, high opacity
        case young = 1    // age 3-5: medium
        case mature = 2   // age 6+: deep, low opacity
        case dying = 3    // just died: fading out

        static func tier(for age: Int) -> AgeTier {
            switch age {
            case ...0: return .dying
            case 1...2: return .newborn
            case 3...5: return .young
            default: return .mature
            }
        }
    }

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
        /// Index ranges per age tier (start index count, index count)
        let tierRanges: [(startIndex: Int, indexCount: Int)]
    }

    /// Builds a merged mesh entity for alive cells with age-based translucent materials.
    @MainActor
    static func makeGridAsync(model: GridModel, theme: ColorTheme = .neon) async throws -> Entity {
        let data = await Task.detached {
            computeMeshData(model: model)
        }.value

        guard data.cellCount > 0 else {
            let entity = Entity()
            entity.name = "CellGrid"
            return entity
        }

        let meshResource = try createMeshResource(from: data)
        let materials = makeAgeMaterials(theme: theme)

        let entity = ModelEntity(mesh: meshResource, materials: materials)
        entity.name = "CellGrid"
        return entity
    }

    /// Creates PhysicallyBasedMaterial for each age tier from a color theme.
    @MainActor
    private static func makeAgeMaterials(theme: ColorTheme) -> [RealityKit.Material] {
        AgeTier.allCases.map { tier -> RealityKit.Material in
            let colors = theme.colors(for: tier)
            var mat = PhysicallyBasedMaterial()
            mat.baseColor = .init(tint: .init(
                red: CGFloat(colors.baseColor.x), green: CGFloat(colors.baseColor.y),
                blue: CGFloat(colors.baseColor.z), alpha: CGFloat(colors.baseColor.w)))
            mat.emissiveColor = .init(color: .init(
                red: CGFloat(colors.emissiveColor.x), green: CGFloat(colors.emissiveColor.y),
                blue: CGFloat(colors.emissiveColor.z), alpha: 1.0))
            mat.emissiveIntensity = colors.emissiveIntensity
            mat.blending = .transparent(opacity: PhysicallyBasedMaterial.Opacity(scale: colors.opacity))
            mat.faceCulling = .none
            return mat
        }
    }

    /// Scale factor for birth animation — cells grow over their first few generations.
    private static func birthScale(for age: Int) -> Float {
        switch age {
        case ...0: return 0.5   // dying cells: shrunk
        case 1: return 0.5      // just born: half size
        case 2: return 0.75     // growing
        case 3: return 0.9      // almost full
        default: return 1.0     // mature: full size
        }
    }

    /// Computes raw vertex and index arrays for alive cells + dying cells, sorted by age tier.
    private static func computeMeshData(model: GridModel) -> MeshData {
        var cellsWithAge = model.aliveCellsWithAge(cellSize: cellSize, cellSpacing: cellSpacing)
        // Add dying cells with a sentinel age of -1 (mapped to .dying tier)
        let dyingPositions = model.dyingCellPositions(cellSize: cellSize, cellSpacing: cellSpacing)
        for pos in dyingPositions {
            cellsWithAge.append((position: pos, age: -1))
        }
        let aliveCells = cellsWithAge.count

        let half = cellSize / 2.0
        let stride = cellSize + cellSpacing
        let gridExtent = Float(model.size - 1) * stride / 2.0 + half

        guard aliveCells > 0 else {
            return MeshData(vertices: [], indices: [], gridExtent: gridExtent, cellCount: 0,
                          tierRanges: AgeTier.allCases.map { _ in (0, 0) })
        }

        // Sort cells by age tier so we can create contiguous mesh parts
        let sorted = cellsWithAge.sorted { AgeTier.tier(for: $0.age).rawValue < AgeTier.tier(for: $1.age).rawValue }

        let cubeVertexCount = 24
        let cubeIndexCount = 36
        let totalVertices = aliveCells * cubeVertexCount
        let totalIndices = aliveCells * cubeIndexCount

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

        var vertices = [GridVertex](
            repeating: GridVertex(position: .zero, normal: .zero, uv: .zero),
            count: totalVertices
        )
        var indices = [UInt32](repeating: 0, count: totalIndices)

        // Track tier boundaries for mesh parts
        var tierCounts = [Int](repeating: 0, count: AgeTier.allCases.count)

        var vi = 0
        var ii = 0
        for cell in sorted {
            let tier = AgeTier.tier(for: cell.age)
            tierCounts[tier.rawValue] += 1

            let scale = birthScale(for: cell.age)
            let vertexOffset = UInt32(vi)
            for j in 0..<cubeVertexCount {
                vertices[vi] = GridVertex(
                    position: cubePositions[j] * scale + cell.position,
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

        // Build tier ranges
        var tierRanges: [(startIndex: Int, indexCount: Int)] = []
        var indexOffset = 0
        for tierIdx in 0..<AgeTier.allCases.count {
            let count = tierCounts[tierIdx] * cubeIndexCount
            tierRanges.append((startIndex: indexOffset, indexCount: count))
            indexOffset += count
        }

        return MeshData(vertices: vertices, indices: indices, gridExtent: gridExtent,
                       cellCount: aliveCells, tierRanges: tierRanges)
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
        let bounds = BoundingBox(min: boundMin, max: boundMax)

        // Create separate mesh parts for each age tier (different material index)
        var parts: [LowLevelMesh.Part] = []
        for (tierIdx, range) in data.tierRanges.enumerated() {
            if range.indexCount > 0 {
                var part = LowLevelMesh.Part(
                    indexCount: range.indexCount,
                    topology: .triangle,
                    bounds: bounds
                )
                part.indexOffset = range.startIndex
                part.materialIndex = tierIdx
                parts.append(part)
            }
        }

        mesh.parts.replaceAll(parts)

        return try MeshResource(from: mesh)
    }
}
