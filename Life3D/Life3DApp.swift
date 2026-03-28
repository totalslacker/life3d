import SwiftUI

@main
struct Life3DApp: App {
    @State private var immersionStyle: ImmersionStyle = .mixed
    @State private var engine = SimulationEngine(size: 16)

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 520, height: 560)

        ImmersiveSpace(id: "life3d-grid") {
            GridImmersiveView()
                .environment(engine)
        }
        .immersionStyle(selection: $immersionStyle, in: .mixed)
    }
}
