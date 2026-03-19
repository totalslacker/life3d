import Foundation

struct GridModel: Sendable {
    let size: Int

    var cellCount: Int { size * size * size }

    func cellPosition(x: Int, y: Int, z: Int, cellSize: Float, cellSpacing: Float) -> SIMD3<Float> {
        let stride = cellSize + cellSpacing
        let offset = Float(size - 1) * stride / 2.0
        return SIMD3<Float>(
            Float(x) * stride - offset,
            Float(y) * stride - offset,
            Float(z) * stride - offset
        )
    }
}
