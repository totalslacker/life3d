import SwiftUI
import RealityKit

struct ContentView: View {
    @State private var gridEntity: Entity?

    var body: some View {
        ZStack {
            RealityView { content in
                // Empty scene — grid added via update closure
            } update: { content in
                // Sync: add grid entity once it's ready
                let existing = content.entities.first { $0.name == "CellGrid" }
                if let grid = gridEntity, existing == nil {
                    content.add(grid)
                }
            }

            if gridEntity == nil {
                ProgressView("Building grid…")
                    .font(.title2)
                    .foregroundStyle(.white)
            }
        }
        .task {
            let grid = await GridRenderer.makeGridAsync(model: GridModel(size: 8))
            gridEntity = grid
        }
    }
}
