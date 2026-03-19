import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        RealityView { content in
            let gridEntity = GridRenderer.makeGrid(model: GridModel(size: 16))
            content.add(gridEntity)
        }
    }
}
