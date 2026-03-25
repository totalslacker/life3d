import SwiftUI
import RealityKit

struct GridImmersiveView: View {
    @Environment(SimulationEngine.self) private var engine
    @State private var gridEntity: Entity?
    @State private var isRebuilding = false
    @State private var needsRebuild = false

    var body: some View {
        RealityView { content in
            // Empty scene — grid added via update closure
        } update: { content in
            let existing = content.entities.first { $0.name == "CellGrid" }
            if let grid = gridEntity, existing == nil {
                content.add(grid)
            } else if let grid = gridEntity, let old = existing, old !== grid {
                content.entities.removeAll { $0.name == "CellGrid" }
                content.add(grid)
            }
        }
        .task {
            await rebuildMesh()
        }
        .onChange(of: engine.generation) {
            Task { await rebuildMesh() }
        }
        .onChange(of: engine.theme) {
            Task { await rebuildMesh() }
        }
    }

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
                // Position grid at eye level, 1.5m in front of user
                grid.position = SIMD3<Float>(0, 1.5, -1.5)
                gridEntity = grid
            } catch {
                print("Failed to build grid: \(error)")
            }
        } while needsRebuild
        isRebuilding = false
    }
}
