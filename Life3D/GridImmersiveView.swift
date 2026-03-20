import SwiftUI
import RealityKit

struct GridImmersiveView: View {
    @Environment(SimulationEngine.self) private var engine
    @State private var gridEntity: Entity?
    @State private var isRebuilding = false

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
            if engine.isRunning {
                Task { await rebuildMesh() }
            }
        }
    }

    private func rebuildMesh() async {
        guard !isRebuilding else { return }
        isRebuilding = true
        do {
            let grid = try await GridRenderer.makeGridAsync(model: engine.grid)
            gridEntity = grid
        } catch {
            print("Failed to build grid: \(error)")
        }
        isRebuilding = false
    }
}
