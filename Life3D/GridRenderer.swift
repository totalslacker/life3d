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

    static let monochrome = ColorTheme(
        name: "Monochrome",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 1.0, 1.0, 1.0),
            emissiveColor: SIMD3(1.0, 1.0, 1.0),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.75, 0.75, 0.75, 1.0),
            emissiveColor: SIMD3(0.7, 0.7, 0.7),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.4, 0.4, 0.4, 1.0),
            emissiveColor: SIMD3(0.3, 0.3, 0.3),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.2, 0.2, 0.2, 1.0),
            emissiveColor: SIMD3(0.15, 0.15, 0.15),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let infrared = ColorTheme(
        name: "Infrared",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 1.0, 0.2, 1.0),
            emissiveColor: SIMD3(1.0, 0.95, 0.1),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(1.0, 0.4, 0.0, 1.0),
            emissiveColor: SIMD3(1.0, 0.3, 0.0),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.8, 0.0, 0.1, 1.0),
            emissiveColor: SIMD3(0.6, 0.0, 0.05),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.3, 0.0, 0.15, 1.0),
            emissiveColor: SIMD3(0.2, 0.0, 0.1),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let bioluminescence = ColorTheme(
        name: "Bioluminescence",
        newborn: TierColors(
            baseColor: SIMD4(0.0, 1.0, 0.8, 1.0),
            emissiveColor: SIMD3(0.0, 1.0, 0.7),
            emissiveIntensity: 2.5, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.0, 0.6, 0.7, 1.0),
            emissiveColor: SIMD3(0.0, 0.5, 0.6),
            emissiveIntensity: 1.4, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.05, 0.15, 0.4, 1.0),
            emissiveColor: SIMD3(0.02, 0.1, 0.35),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.02, 0.05, 0.2, 1.0),
            emissiveColor: SIMD3(0.01, 0.03, 0.15),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let sakura = ColorTheme(
        name: "Sakura",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.7, 0.85, 1.0),
            emissiveColor: SIMD3(1.0, 0.6, 0.8),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.45, 0.6, 1.0),
            emissiveColor: SIMD3(0.8, 0.35, 0.55),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.45, 0.1, 0.35, 1.0),
            emissiveColor: SIMD3(0.35, 0.05, 0.25),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.25, 0.1, 0.15, 1.0),
            emissiveColor: SIMD3(0.15, 0.05, 0.1),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let ember = ColorTheme(
        name: "Ember",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.95, 0.4, 1.0),
            emissiveColor: SIMD3(1.0, 0.85, 0.2),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(1.0, 0.35, 0.05, 1.0),
            emissiveColor: SIMD3(1.0, 0.25, 0.0),
            emissiveIntensity: 1.6, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.6, 0.05, 0.0, 1.0),
            emissiveColor: SIMD3(0.4, 0.02, 0.0),
            emissiveIntensity: 0.7, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.2, 0.02, 0.0, 1.0),
            emissiveColor: SIMD3(0.12, 0.01, 0.0),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let nebula = ColorTheme(
        name: "Nebula",
        newborn: TierColors(
            baseColor: SIMD4(0.9, 0.7, 1.0, 1.0),
            emissiveColor: SIMD3(0.85, 0.6, 1.0),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.5, 0.2, 0.9, 1.0),
            emissiveColor: SIMD3(0.4, 0.15, 0.85),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.15, 0.05, 0.45, 1.0),
            emissiveColor: SIMD3(0.1, 0.02, 0.35),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.05, 0.02, 0.2, 1.0),
            emissiveColor: SIMD3(0.03, 0.01, 0.12),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let glacier = ColorTheme(
        name: "Glacier",
        newborn: TierColors(
            baseColor: SIMD4(0.85, 0.95, 1.0, 1.0),
            emissiveColor: SIMD3(0.8, 0.92, 1.0),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.4, 0.7, 0.95, 1.0),
            emissiveColor: SIMD3(0.3, 0.6, 0.9),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.1, 0.25, 0.55, 1.0),
            emissiveColor: SIMD3(0.05, 0.18, 0.45),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.05, 0.1, 0.25, 1.0),
            emissiveColor: SIMD3(0.02, 0.06, 0.18),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let coral = ColorTheme(
        name: "Coral",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.55, 0.4, 1.0),
            emissiveColor: SIMD3(1.0, 0.45, 0.3),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.9, 0.3, 0.25, 1.0),
            emissiveColor: SIMD3(0.85, 0.2, 0.18),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.45, 0.12, 0.15, 1.0),
            emissiveColor: SIMD3(0.35, 0.08, 0.1),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.2, 0.06, 0.08, 1.0),
            emissiveColor: SIMD3(0.12, 0.03, 0.05),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let forest = ColorTheme(
        name: "Forest",
        newborn: TierColors(
            baseColor: SIMD4(0.6, 1.0, 0.3, 1.0),
            emissiveColor: SIMD3(0.5, 0.95, 0.2),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.2, 0.7, 0.15, 1.0),
            emissiveColor: SIMD3(0.15, 0.6, 0.1),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.1, 0.35, 0.08, 1.0),
            emissiveColor: SIMD3(0.06, 0.25, 0.04),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.15, 0.05, 1.0),
            emissiveColor: SIMD3(0.04, 0.1, 0.02),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let sunset = ColorTheme(
        name: "Sunset",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.5, 0.2, 1.0),
            emissiveColor: SIMD3(1.0, 0.4, 0.1),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.15, 0.35, 1.0),
            emissiveColor: SIMD3(0.8, 0.1, 0.3),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.05, 0.45, 1.0),
            emissiveColor: SIMD3(0.25, 0.02, 0.38),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.02, 0.2, 1.0),
            emissiveColor: SIMD3(0.08, 0.01, 0.12),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let twilight = ColorTheme(
        name: "Twilight",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.75, 0.4, 1.0),
            emissiveColor: SIMD3(1.0, 0.65, 0.3),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.7, 0.3, 0.6, 1.0),
            emissiveColor: SIMD3(0.6, 0.2, 0.55),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.2, 0.1, 0.4, 1.0),
            emissiveColor: SIMD3(0.15, 0.06, 0.3),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.04, 0.18, 1.0),
            emissiveColor: SIMD3(0.05, 0.02, 0.12),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let jade = ColorTheme(
        name: "Jade",
        newborn: TierColors(
            baseColor: SIMD4(0.4, 1.0, 0.85, 1.0),
            emissiveColor: SIMD3(0.3, 0.95, 0.75),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.1, 0.7, 0.55, 1.0),
            emissiveColor: SIMD3(0.08, 0.6, 0.45),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.05, 0.35, 0.3, 1.0),
            emissiveColor: SIMD3(0.03, 0.25, 0.2),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.02, 0.15, 0.12, 1.0),
            emissiveColor: SIMD3(0.01, 0.08, 0.06),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let crimson = ColorTheme(
        name: "Crimson",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.15, 0.15, 1.0),
            emissiveColor: SIMD3(1.0, 0.1, 0.1),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.75, 0.05, 0.1, 1.0),
            emissiveColor: SIMD3(0.65, 0.03, 0.08),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.02, 0.08, 1.0),
            emissiveColor: SIMD3(0.25, 0.01, 0.05),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.01, 0.04, 1.0),
            emissiveColor: SIMD3(0.08, 0.005, 0.02),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let amethyst = ColorTheme(
        name: "Amethyst",
        newborn: TierColors(
            baseColor: SIMD4(0.85, 0.6, 1.0, 1.0),
            emissiveColor: SIMD3(0.75, 0.45, 1.0),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.55, 0.2, 0.85, 1.0),
            emissiveColor: SIMD3(0.45, 0.12, 0.75),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.3, 0.08, 0.5, 1.0),
            emissiveColor: SIMD3(0.2, 0.04, 0.4),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.03, 0.22, 1.0),
            emissiveColor: SIMD3(0.06, 0.015, 0.14),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let copper = ColorTheme(
        name: "Copper",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.72, 0.45, 1.0),
            emissiveColor: SIMD3(1.0, 0.65, 0.35),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.8, 0.42, 0.2, 1.0),
            emissiveColor: SIMD3(0.72, 0.35, 0.14),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.45, 0.22, 0.12, 1.0),
            emissiveColor: SIMD3(0.35, 0.15, 0.08),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.2, 0.12, 0.08, 1.0),
            emissiveColor: SIMD3(0.12, 0.07, 0.04),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let gold = ColorTheme(
        name: "Gold",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.88, 0.3, 1.0),
            emissiveColor: SIMD3(1.0, 0.84, 0.2),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.65, 0.12, 1.0),
            emissiveColor: SIMD3(0.78, 0.58, 0.08),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.55, 0.38, 0.08, 1.0),
            emissiveColor: SIMD3(0.45, 0.3, 0.05),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.28, 0.18, 0.05, 1.0),
            emissiveColor: SIMD3(0.18, 0.1, 0.03),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let midnight = ColorTheme(
        name: "Midnight",
        newborn: TierColors(
            baseColor: SIMD4(0.4, 0.5, 1.0, 1.0),
            emissiveColor: SIMD3(0.3, 0.4, 1.0),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.2, 0.25, 0.75, 1.0),
            emissiveColor: SIMD3(0.15, 0.2, 0.65),
            emissiveIntensity: 1.3, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.1, 0.08, 0.4, 1.0),
            emissiveColor: SIMD3(0.06, 0.05, 0.3),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.04, 0.03, 0.18, 1.0),
            emissiveColor: SIMD3(0.02, 0.02, 0.1),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    static let volcanic = ColorTheme(
        name: "Volcanic",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.6, 0.0, 1.0),
            emissiveColor: SIMD3(1.0, 0.5, 0.0),
            emissiveIntensity: 2.5, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.9, 0.15, 0.0, 1.0),
            emissiveColor: SIMD3(0.8, 0.1, 0.0),
            emissiveIntensity: 1.5, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.02, 0.02, 1.0),
            emissiveColor: SIMD3(0.25, 0.01, 0.01),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.02, 0.02, 1.0),
            emissiveColor: SIMD3(0.08, 0.01, 0.01),
            emissiveIntensity: 0.25, opacity: 0.06)
    )

    static let plasma = ColorTheme(
        name: "Plasma",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.95, 1.0, 1.0),
            emissiveColor: SIMD3(1.0, 0.85, 1.0),
            emissiveIntensity: 2.8, opacity: 0.65),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.2, 0.95, 1.0),
            emissiveColor: SIMD3(0.75, 0.15, 0.9),
            emissiveIntensity: 1.5, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.4, 0.0, 0.55, 1.0),
            emissiveColor: SIMD3(0.3, 0.0, 0.45),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.0, 0.2, 1.0),
            emissiveColor: SIMD3(0.08, 0.0, 0.12),
            emissiveIntensity: 0.25, opacity: 0.06)
    )

    static let frost = ColorTheme(
        name: "Frost",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.98, 1.0, 1.0),
            emissiveColor: SIMD3(0.85, 0.92, 1.0),
            emissiveIntensity: 2.5, opacity: 0.62),
        young: TierColors(
            baseColor: SIMD4(0.6, 0.8, 0.95, 1.0),
            emissiveColor: SIMD3(0.5, 0.7, 0.9),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.2, 0.35, 0.55, 1.0),
            emissiveColor: SIMD3(0.12, 0.25, 0.45),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.15, 0.28, 1.0),
            emissiveColor: SIMD3(0.04, 0.08, 0.18),
            emissiveIntensity: 0.3, opacity: 0.08)
    )


    static let arctic = ColorTheme(
        name: "Arctic",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.98, 1.0, 1.0),
            emissiveColor: SIMD3(0.85, 0.95, 1.0),
            emissiveIntensity: 2.2, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.5, 0.75, 0.95, 1.0),
            emissiveColor: SIMD3(0.4, 0.65, 0.9),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.15, 0.35, 0.6, 1.0),
            emissiveColor: SIMD3(0.1, 0.25, 0.5),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.05, 0.12, 0.25, 1.0),
            emissiveColor: SIMD3(0.02, 0.08, 0.18),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    /// Solar — brilliant white-gold newborn cells through molten orange to deep crimson,
    /// evoking the surface of a star. Highest emissive intensity among warm themes (2.5)
    /// for a searing brightness. Distinct from Warm Amber (amber/brown) and Ember (orange/charcoal)
    /// — Solar stays in the white-gold-to-crimson range with extreme luminosity.
    static let solar = ColorTheme(
        name: "Solar",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.98, 0.85, 1.0),
            emissiveColor: SIMD3(1.0, 0.95, 0.7),
            emissiveIntensity: 2.5, opacity: 0.62),
        young: TierColors(
            baseColor: SIMD4(1.0, 0.7, 0.15, 1.0),
            emissiveColor: SIMD3(1.0, 0.6, 0.1),
            emissiveIntensity: 1.5, opacity: 0.42),
        mature: TierColors(
            baseColor: SIMD4(0.85, 0.25, 0.05, 1.0),
            emissiveColor: SIMD3(0.7, 0.15, 0.02),
            emissiveIntensity: 0.9, opacity: 0.28),
        dying: TierColors(
            baseColor: SIMD4(0.4, 0.08, 0.02, 1.0),
            emissiveColor: SIMD3(0.25, 0.04, 0.01),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    /// Toxic — vivid radioactive green newborn cells through acid yellow-green to dark
    /// sludge green, evoking nuclear waste and bioluminescent decay. High initial intensity
    /// (2.4) gives a harsh, unnatural glow. Distinct from Forest (earthy green tones) and
    /// Bioluminescence (teal/aqua) — Toxic stays in the pure neon green-to-black range
    /// with a synthetic, hazardous feel.
    static let toxic = ColorTheme(
        name: "Toxic",
        newborn: TierColors(
            baseColor: SIMD4(0.4, 1.0, 0.1, 1.0),
            emissiveColor: SIMD3(0.3, 1.0, 0.05),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.6, 0.85, 0.0, 1.0),
            emissiveColor: SIMD3(0.5, 0.75, 0.0),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.15, 0.4, 0.02, 1.0),
            emissiveColor: SIMD3(0.1, 0.3, 0.01),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.05, 0.15, 0.02, 1.0),
            emissiveColor: SIMD3(0.03, 0.1, 0.01),
            emissiveIntensity: 0.3, opacity: 0.08)
    )

    /// Deep space aesthetic — brilliant white newborn stars through blue-white young to
    /// dim cool blue mature to near-black void. Distinct from Glacier (icy teal), Frost
    /// (pale crystalline), and Midnight (dark blue-purple) — Starfield stays in the
    /// white-to-deep-blue range with high luminosity contrast, evoking scattered stars
    /// against the void of space.
    static let starfield = ColorTheme(
        name: "Starfield",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.97, 1.0, 1.0),
            emissiveColor: SIMD3(0.95, 0.97, 1.0),
            emissiveIntensity: 2.6, opacity: 0.65),
        young: TierColors(
            baseColor: SIMD4(0.5, 0.65, 0.95, 1.0),
            emissiveColor: SIMD3(0.4, 0.55, 0.9),
            emissiveIntensity: 1.5, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.1, 0.15, 0.4, 1.0),
            emissiveColor: SIMD3(0.08, 0.12, 0.35),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.02, 0.03, 0.12, 1.0),
            emissiveColor: SIMD3(0.01, 0.02, 0.08),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let hologram = ColorTheme(
        name: "Hologram",
        newborn: TierColors(
            baseColor: SIMD4(0.0, 1.0, 0.95, 1.0),
            emissiveColor: SIMD3(0.0, 1.0, 0.95),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.0, 0.7, 0.85, 1.0),
            emissiveColor: SIMD3(0.0, 0.6, 0.8),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.0, 0.3, 0.5, 1.0),
            emissiveColor: SIMD3(0.0, 0.25, 0.45),
            emissiveIntensity: 0.7, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.0, 0.1, 0.2, 1.0),
            emissiveColor: SIMD3(0.0, 0.08, 0.15),
            emissiveIntensity: 0.25, opacity: 0.07)
    )

    static let cyberpunk = ColorTheme(
        name: "Cyberpunk",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.0, 0.6, 1.0),
            emissiveColor: SIMD3(1.0, 0.0, 0.6),
            emissiveIntensity: 2.5, opacity: 0.62),
        young: TierColors(
            baseColor: SIMD4(0.8, 0.0, 0.5, 1.0),
            emissiveColor: SIMD3(0.7, 0.0, 0.55),
            emissiveIntensity: 1.5, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.0, 0.4, 1.0),
            emissiveColor: SIMD3(0.3, 0.0, 0.35),
            emissiveIntensity: 0.7, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.0, 0.15, 1.0),
            emissiveColor: SIMD3(0.1, 0.0, 0.12),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let vaporwave = ColorTheme(
        name: "Vaporwave",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.4, 0.9, 1.0),
            emissiveColor: SIMD3(0.9, 0.3, 0.95),
            emissiveIntensity: 2.3, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.5, 0.3, 0.9, 1.0),
            emissiveColor: SIMD3(0.4, 0.25, 0.85),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.15, 0.35, 0.65, 1.0),
            emissiveColor: SIMD3(0.1, 0.3, 0.55),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.12, 0.25, 1.0),
            emissiveColor: SIMD3(0.05, 0.08, 0.2),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let synthwave = ColorTheme(
        name: "Synthwave",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.6, 0.1, 1.0),
            emissiveColor: SIMD3(1.0, 0.5, 0.05),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.8, 0.2, 0.5, 1.0),
            emissiveColor: SIMD3(0.7, 0.15, 0.45),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.2, 0.08, 0.45, 1.0),
            emissiveColor: SIMD3(0.15, 0.05, 0.4),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.06, 0.03, 0.18, 1.0),
            emissiveColor: SIMD3(0.04, 0.02, 0.12),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let terracotta = ColorTheme(
        name: "Terracotta",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.55, 0.25, 1.0),
            emissiveColor: SIMD3(0.95, 0.5, 0.2),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.75, 0.35, 0.15, 1.0),
            emissiveColor: SIMD3(0.7, 0.3, 0.1),
            emissiveIntensity: 1.3, opacity: 0.36),
        mature: TierColors(
            baseColor: SIMD4(0.4, 0.2, 0.1, 1.0),
            emissiveColor: SIMD3(0.35, 0.15, 0.08),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.08, 0.04, 1.0),
            emissiveColor: SIMD3(0.1, 0.05, 0.02),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let lavender = ColorTheme(
        name: "Lavender",
        newborn: TierColors(
            baseColor: SIMD4(0.75, 0.55, 1.0, 1.0),
            emissiveColor: SIMD3(0.7, 0.5, 1.0),
            emissiveIntensity: 2.2, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.5, 0.4, 0.85, 1.0),
            emissiveColor: SIMD3(0.45, 0.35, 0.8),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.3, 0.25, 0.6, 1.0),
            emissiveColor: SIMD3(0.25, 0.2, 0.55),
            emissiveIntensity: 0.65, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.1, 0.25, 1.0),
            emissiveColor: SIMD3(0.08, 0.06, 0.18),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let matrix = ColorTheme(
        name: "Matrix",
        newborn: TierColors(
            baseColor: SIMD4(0.0, 1.0, 0.0, 1.0),
            emissiveColor: SIMD3(0.0, 1.0, 0.0),
            emissiveIntensity: 2.5, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.0, 0.65, 0.0, 1.0),
            emissiveColor: SIMD3(0.0, 0.6, 0.0),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.0, 0.2, 0.0, 1.0),
            emissiveColor: SIMD3(0.0, 0.15, 0.0),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.0, 0.06, 0.0, 1.0),
            emissiveColor: SIMD3(0.0, 0.04, 0.0),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let champagne = ColorTheme(
        name: "Champagne",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.95, 0.8, 1.0),
            emissiveColor: SIMD3(1.0, 0.92, 0.7),
            emissiveIntensity: 2.3, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.75, 0.5, 1.0),
            emissiveColor: SIMD3(0.8, 0.7, 0.4),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.55, 0.45, 0.25, 1.0),
            emissiveColor: SIMD3(0.5, 0.4, 0.2),
            emissiveIntensity: 0.65, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.2, 0.16, 0.08, 1.0),
            emissiveColor: SIMD3(0.15, 0.12, 0.05),
            emissiveIntensity: 0.18, opacity: 0.06)
    )

    static let opal = ColorTheme(
        name: "Opal",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.92, 1.0, 1.0),
            emissiveColor: SIMD3(0.9, 0.88, 1.0),
            emissiveIntensity: 2.5, opacity: 0.62),
        young: TierColors(
            baseColor: SIMD4(0.6, 0.75, 0.95, 1.0),
            emissiveColor: SIMD3(0.55, 0.7, 0.9),
            emissiveIntensity: 1.5, opacity: 0.40),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.5, 0.7, 1.0),
            emissiveColor: SIMD3(0.3, 0.45, 0.65),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.18, 0.28, 1.0),
            emissiveColor: SIMD3(0.1, 0.12, 0.2),
            emissiveIntensity: 0.18, opacity: 0.05)
    )

    static let roseGold = ColorTheme(
        name: "Rose Gold",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.6, 0.65, 1.0),
            emissiveColor: SIMD3(1.0, 0.55, 0.6),
            emissiveIntensity: 2.3, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.75, 0.42, 0.45, 1.0),
            emissiveColor: SIMD3(0.7, 0.38, 0.4),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.45, 0.25, 0.28, 1.0),
            emissiveColor: SIMD3(0.4, 0.22, 0.25),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.1, 0.11, 1.0),
            emissiveColor: SIMD3(0.12, 0.06, 0.07),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let peridot = ColorTheme(
        name: "Peridot",
        newborn: TierColors(
            baseColor: SIMD4(0.6, 1.0, 0.1, 1.0),
            emissiveColor: SIMD3(0.55, 1.0, 0.05),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.4, 0.7, 0.05, 1.0),
            emissiveColor: SIMD3(0.35, 0.65, 0.02),
            emissiveIntensity: 1.3, opacity: 0.36),
        mature: TierColors(
            baseColor: SIMD4(0.15, 0.3, 0.02, 1.0),
            emissiveColor: SIMD3(0.1, 0.25, 0.01),
            emissiveIntensity: 0.7, opacity: 0.22),
        dying: TierColors(
            baseColor: SIMD4(0.05, 0.1, 0.01, 1.0),
            emissiveColor: SIMD3(0.03, 0.06, 0.0),
            emissiveIntensity: 0.2, opacity: 0.06)
    )

    static let sapphire = ColorTheme(
        name: "Sapphire",
        newborn: TierColors(
            baseColor: SIMD4(0.15, 0.35, 1.0, 1.0),
            emissiveColor: SIMD3(0.1, 0.3, 1.0),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.08, 0.2, 0.7, 1.0),
            emissiveColor: SIMD3(0.05, 0.15, 0.65),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.03, 0.08, 0.35, 1.0),
            emissiveColor: SIMD3(0.02, 0.05, 0.3),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.01, 0.03, 0.12, 1.0),
            emissiveColor: SIMD3(0.005, 0.02, 0.08),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let obsidian = ColorTheme(
        name: "Obsidian",
        newborn: TierColors(
            baseColor: SIMD4(0.55, 0.5, 0.6, 1.0),
            emissiveColor: SIMD3(0.5, 0.45, 0.55),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.3, 0.28, 0.35, 1.0),
            emissiveColor: SIMD3(0.25, 0.22, 0.3),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.12, 0.1, 0.15, 1.0),
            emissiveColor: SIMD3(0.08, 0.06, 0.12),
            emissiveIntensity: 0.5, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.04, 0.03, 0.06, 1.0),
            emissiveColor: SIMD3(0.02, 0.01, 0.04),
            emissiveIntensity: 0.1, opacity: 0.04)
    )

    static let ruby = ColorTheme(
        name: "Ruby",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.08, 0.15, 1.0),
            emissiveColor: SIMD3(1.0, 0.05, 0.12),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.7, 0.04, 0.12, 1.0),
            emissiveColor: SIMD3(0.65, 0.03, 0.1),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.02, 0.08, 1.0),
            emissiveColor: SIMD3(0.3, 0.01, 0.06),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.01, 0.04, 1.0),
            emissiveColor: SIMD3(0.08, 0.005, 0.03),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let titanium = ColorTheme(
        name: "Titanium",
        newborn: TierColors(
            baseColor: SIMD4(0.75, 0.78, 0.85, 1.0),
            emissiveColor: SIMD3(0.7, 0.73, 0.82),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.45, 0.48, 0.55, 1.0),
            emissiveColor: SIMD3(0.4, 0.43, 0.52),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.2, 0.22, 0.28, 1.0),
            emissiveColor: SIMD3(0.15, 0.17, 0.24),
            emissiveIntensity: 0.5, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.09, 0.12, 1.0),
            emissiveColor: SIMD3(0.04, 0.05, 0.08),
            emissiveIntensity: 0.12, opacity: 0.04)
    )

    static let garnet = ColorTheme(
        name: "Garnet",
        newborn: TierColors(
            baseColor: SIMD4(0.85, 0.12, 0.2, 1.0),
            emissiveColor: SIMD3(0.9, 0.08, 0.15),
            emissiveIntensity: 2.2, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.55, 0.06, 0.15, 1.0),
            emissiveColor: SIMD3(0.5, 0.04, 0.12),
            emissiveIntensity: 1.2, opacity: 0.36),
        mature: TierColors(
            baseColor: SIMD4(0.28, 0.02, 0.08, 1.0),
            emissiveColor: SIMD3(0.22, 0.01, 0.06),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.1, 0.01, 0.03, 1.0),
            emissiveColor: SIMD3(0.06, 0.005, 0.02),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let emerald = ColorTheme(
        name: "Emerald",
        newborn: TierColors(
            baseColor: SIMD4(0.05, 1.0, 0.35, 1.0),
            emissiveColor: SIMD3(0.04, 1.0, 0.3),
            emissiveIntensity: 2.4, opacity: 0.60),
        young: TierColors(
            baseColor: SIMD4(0.03, 0.65, 0.22, 1.0),
            emissiveColor: SIMD3(0.02, 0.6, 0.18),
            emissiveIntensity: 1.3, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.02, 0.32, 0.12, 1.0),
            emissiveColor: SIMD3(0.01, 0.28, 0.09),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.01, 0.1, 0.05, 1.0),
            emissiveColor: SIMD3(0.005, 0.07, 0.03),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let tungsten = ColorTheme(
        name: "Tungsten",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.78, 0.3, 1.0),
            emissiveColor: SIMD3(1.0, 0.75, 0.25),
            emissiveIntensity: 2.4, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.8, 0.5, 0.15, 1.0),
            emissiveColor: SIMD3(0.75, 0.45, 0.1),
            emissiveIntensity: 1.4, opacity: 0.38),
        mature: TierColors(
            baseColor: SIMD4(0.4, 0.22, 0.06, 1.0),
            emissiveColor: SIMD3(0.35, 0.18, 0.04),
            emissiveIntensity: 0.6, opacity: 0.20),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.08, 0.02, 1.0),
            emissiveColor: SIMD3(0.1, 0.05, 0.01),
            emissiveIntensity: 0.15, opacity: 0.05)
    )

    static let aquamarine = ColorTheme(
        name: "Aquamarine",
        newborn: TierColors(
            baseColor: SIMD4(0.1, 0.95, 0.85, 1.0),
            emissiveColor: SIMD3(0.08, 0.95, 0.8),
            emissiveIntensity: 2.3, opacity: 0.58),
        young: TierColors(
            baseColor: SIMD4(0.05, 0.6, 0.55, 1.0),
            emissiveColor: SIMD3(0.04, 0.55, 0.5),
            emissiveIntensity: 1.2, opacity: 0.36),
        mature: TierColors(
            baseColor: SIMD4(0.02, 0.3, 0.28, 1.0),
            emissiveColor: SIMD3(0.01, 0.25, 0.22),
            emissiveIntensity: 0.5, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.01, 0.1, 0.09, 1.0),
            emissiveColor: SIMD3(0.005, 0.06, 0.05),
            emissiveIntensity: 0.12, opacity: 0.04)
    )

    static let bronze = ColorTheme(
        name: "Bronze",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.7, 0.3, 1.0),
            emissiveColor: SIMD3(0.9, 0.65, 0.25),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.6, 0.4, 0.15, 1.0),
            emissiveColor: SIMD3(0.55, 0.35, 0.12),
            emissiveIntensity: 1.1, opacity: 0.34),
        mature: TierColors(
            baseColor: SIMD4(0.3, 0.2, 0.08, 1.0),
            emissiveColor: SIMD3(0.25, 0.15, 0.05),
            emissiveIntensity: 0.45, opacity: 0.16),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.08, 0.03, 1.0),
            emissiveColor: SIMD3(0.06, 0.04, 0.01),
            emissiveIntensity: 0.1, opacity: 0.03)
    )

    static let ivory = ColorTheme(
        name: "Ivory",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.97, 0.88, 1.0),
            emissiveColor: SIMD3(1.0, 0.96, 0.85),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.8, 0.68, 1.0),
            emissiveColor: SIMD3(0.8, 0.75, 0.62),
            emissiveIntensity: 1.0, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.55, 0.5, 0.4, 1.0),
            emissiveColor: SIMD3(0.45, 0.4, 0.32),
            emissiveIntensity: 0.4, opacity: 0.17),
        dying: TierColors(
            baseColor: SIMD4(0.25, 0.22, 0.18, 1.0),
            emissiveColor: SIMD3(0.12, 0.1, 0.08),
            emissiveIntensity: 0.1, opacity: 0.03)
    )

    static let pearl = ColorTheme(
        name: "Pearl",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.95, 0.96, 1.0),
            emissiveColor: SIMD3(1.0, 0.92, 0.95),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.88, 0.82, 0.85, 1.0),
            emissiveColor: SIMD3(0.82, 0.75, 0.8),
            emissiveIntensity: 1.0, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.6, 0.55, 0.58, 1.0),
            emissiveColor: SIMD3(0.48, 0.42, 0.46),
            emissiveIntensity: 0.4, opacity: 0.17),
        dying: TierColors(
            baseColor: SIMD4(0.3, 0.27, 0.28, 1.0),
            emissiveColor: SIMD3(0.14, 0.12, 0.13),
            emissiveIntensity: 0.1, opacity: 0.03)
    )

    static let graphite = ColorTheme(
        name: "Graphite",
        newborn: TierColors(
            baseColor: SIMD4(0.7, 0.7, 0.72, 1.0),
            emissiveColor: SIMD3(0.65, 0.65, 0.68),
            emissiveIntensity: 1.8, opacity: 0.50),
        young: TierColors(
            baseColor: SIMD4(0.42, 0.42, 0.44, 1.0),
            emissiveColor: SIMD3(0.38, 0.38, 0.40),
            emissiveIntensity: 0.9, opacity: 0.30),
        mature: TierColors(
            baseColor: SIMD4(0.22, 0.22, 0.24, 1.0),
            emissiveColor: SIMD3(0.18, 0.18, 0.20),
            emissiveIntensity: 0.35, opacity: 0.15),
        dying: TierColors(
            baseColor: SIMD4(0.10, 0.10, 0.11, 1.0),
            emissiveColor: SIMD3(0.05, 0.05, 0.06),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let slate = ColorTheme(
        name: "Slate",
        newborn: TierColors(
            baseColor: SIMD4(0.55, 0.58, 0.65, 1.0),
            emissiveColor: SIMD3(0.50, 0.54, 0.62),
            emissiveIntensity: 1.9, opacity: 0.52),
        young: TierColors(
            baseColor: SIMD4(0.35, 0.38, 0.45, 1.0),
            emissiveColor: SIMD3(0.30, 0.34, 0.42),
            emissiveIntensity: 0.95, opacity: 0.32),
        mature: TierColors(
            baseColor: SIMD4(0.20, 0.22, 0.28, 1.0),
            emissiveColor: SIMD3(0.16, 0.18, 0.24),
            emissiveIntensity: 0.38, opacity: 0.16),
        dying: TierColors(
            baseColor: SIMD4(0.10, 0.11, 0.14, 1.0),
            emissiveColor: SIMD3(0.05, 0.06, 0.08),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let cobalt = ColorTheme(
        name: "Cobalt",
        newborn: TierColors(
            baseColor: SIMD4(0.15, 0.30, 1.0, 1.0),
            emissiveColor: SIMD3(0.10, 0.25, 1.0),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.08, 0.18, 0.72, 1.0),
            emissiveColor: SIMD3(0.06, 0.15, 0.65),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.04, 0.10, 0.45, 1.0),
            emissiveColor: SIMD3(0.03, 0.08, 0.38),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.02, 0.04, 0.20, 1.0),
            emissiveColor: SIMD3(0.01, 0.02, 0.12),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let vermilion = ColorTheme(
        name: "Vermilion",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.30, 0.05, 1.0),
            emissiveColor: SIMD3(1.0, 0.25, 0.04),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.78, 0.18, 0.03, 1.0),
            emissiveColor: SIMD3(0.70, 0.14, 0.02),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.50, 0.10, 0.02, 1.0),
            emissiveColor: SIMD3(0.42, 0.08, 0.01),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.22, 0.05, 0.01, 1.0),
            emissiveColor: SIMD3(0.12, 0.03, 0.005),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let indigo = ColorTheme(
        name: "Indigo",
        newborn: TierColors(
            baseColor: SIMD4(0.30, 0.08, 1.0, 1.0),
            emissiveColor: SIMD3(0.25, 0.06, 1.0),
            emissiveIntensity: 2.2, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.20, 0.04, 0.72, 1.0),
            emissiveColor: SIMD3(0.16, 0.03, 0.65),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.12, 0.02, 0.45, 1.0),
            emissiveColor: SIMD3(0.10, 0.015, 0.38),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.06, 0.01, 0.20, 1.0),
            emissiveColor: SIMD3(0.03, 0.005, 0.12),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let mahogany = ColorTheme(
        name: "Mahogany",
        newborn: TierColors(
            baseColor: SIMD4(0.75, 0.22, 0.08, 1.0),
            emissiveColor: SIMD3(0.70, 0.18, 0.06),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.52, 0.14, 0.05, 1.0),
            emissiveColor: SIMD3(0.45, 0.10, 0.03),
            emissiveIntensity: 1.0, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.32, 0.08, 0.03, 1.0),
            emissiveColor: SIMD3(0.25, 0.06, 0.02),
            emissiveIntensity: 0.35, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.04, 0.02, 1.0),
            emissiveColor: SIMD3(0.08, 0.02, 0.008),
            emissiveIntensity: 0.07, opacity: 0.03)
    )

    static let burgundy = ColorTheme(
        name: "Burgundy",
        newborn: TierColors(
            baseColor: SIMD4(0.85, 0.08, 0.18, 1.0),
            emissiveColor: SIMD3(0.80, 0.06, 0.16),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.55, 0.04, 0.14, 1.0),
            emissiveColor: SIMD3(0.48, 0.03, 0.12),
            emissiveIntensity: 1.0, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.32, 0.02, 0.10, 1.0),
            emissiveColor: SIMD3(0.26, 0.015, 0.08),
            emissiveIntensity: 0.38, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.14, 0.01, 0.05, 1.0),
            emissiveColor: SIMD3(0.08, 0.005, 0.03),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let teal = ColorTheme(
        name: "Teal",
        newborn: TierColors(
            baseColor: SIMD4(0.0, 0.85, 0.75, 1.0),
            emissiveColor: SIMD3(0.0, 0.85, 0.75),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.0, 0.58, 0.52, 1.0),
            emissiveColor: SIMD3(0.0, 0.52, 0.46),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.0, 0.35, 0.32, 1.0),
            emissiveColor: SIMD3(0.0, 0.30, 0.27),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.0, 0.15, 0.13, 1.0),
            emissiveColor: SIMD3(0.0, 0.08, 0.07),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let chartreuse = ColorTheme(
        name: "Chartreuse",
        newborn: TierColors(
            baseColor: SIMD4(0.75, 1.0, 0.0, 1.0),
            emissiveColor: SIMD3(0.75, 1.0, 0.0),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.52, 0.70, 0.0, 1.0),
            emissiveColor: SIMD3(0.48, 0.65, 0.0),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.32, 0.42, 0.0, 1.0),
            emissiveColor: SIMD3(0.28, 0.38, 0.0),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.14, 0.18, 0.0, 1.0),
            emissiveColor: SIMD3(0.07, 0.09, 0.0),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let saffron = ColorTheme(
        name: "Saffron",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.75, 0.0, 1.0),
            emissiveColor: SIMD3(1.0, 0.75, 0.0),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.85, 0.55, 0.0, 1.0),
            emissiveColor: SIMD3(0.78, 0.48, 0.0),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.55, 0.32, 0.0, 1.0),
            emissiveColor: SIMD3(0.45, 0.25, 0.0),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.25, 0.14, 0.0, 1.0),
            emissiveColor: SIMD3(0.12, 0.07, 0.0),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let moss = ColorTheme(
        name: "Moss",
        newborn: TierColors(
            baseColor: SIMD4(0.25, 0.62, 0.15, 1.0),
            emissiveColor: SIMD3(0.22, 0.60, 0.12),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.15, 0.42, 0.10, 1.0),
            emissiveColor: SIMD3(0.12, 0.38, 0.08),
            emissiveIntensity: 1.0, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.08, 0.25, 0.06, 1.0),
            emissiveColor: SIMD3(0.06, 0.20, 0.04),
            emissiveIntensity: 0.38, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.04, 0.12, 0.03, 1.0),
            emissiveColor: SIMD3(0.02, 0.06, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let cerulean = ColorTheme(
        name: "Cerulean",
        newborn: TierColors(
            baseColor: SIMD4(0.0, 0.65, 1.0, 1.0),
            emissiveColor: SIMD3(0.0, 0.65, 1.0),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.0, 0.48, 0.82, 1.0),
            emissiveColor: SIMD3(0.0, 0.42, 0.72),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.0, 0.28, 0.55, 1.0),
            emissiveColor: SIMD3(0.0, 0.22, 0.45),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.0, 0.12, 0.25, 1.0),
            emissiveColor: SIMD3(0.0, 0.06, 0.12),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let mauve = ColorTheme(
        name: "Mauve",
        newborn: TierColors(
            baseColor: SIMD4(0.88, 0.55, 0.88, 1.0),
            emissiveColor: SIMD3(0.88, 0.55, 0.88),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.68, 0.38, 0.72, 1.0),
            emissiveColor: SIMD3(0.58, 0.32, 0.62),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.45, 0.20, 0.50, 1.0),
            emissiveColor: SIMD3(0.35, 0.15, 0.40),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.20, 0.08, 0.22, 1.0),
            emissiveColor: SIMD3(0.10, 0.04, 0.12),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let marigold = ColorTheme(
        name: "Marigold",
        newborn: TierColors(
            baseColor: SIMD4(1.0, 0.80, 0.0, 1.0),
            emissiveColor: SIMD3(1.0, 0.80, 0.0),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.90, 0.55, 0.0, 1.0),
            emissiveColor: SIMD3(0.82, 0.48, 0.0),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.60, 0.30, 0.0, 1.0),
            emissiveColor: SIMD3(0.50, 0.22, 0.0),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.28, 0.14, 0.0, 1.0),
            emissiveColor: SIMD3(0.14, 0.07, 0.0),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let sage = ColorTheme(
        name: "Sage",
        newborn: TierColors(
            baseColor: SIMD4(0.68, 0.78, 0.65, 1.0),
            emissiveColor: SIMD3(0.68, 0.78, 0.65),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.48, 0.58, 0.45, 1.0),
            emissiveColor: SIMD3(0.42, 0.52, 0.40),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.30, 0.38, 0.28, 1.0),
            emissiveColor: SIMD3(0.22, 0.30, 0.20),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.12, 0.16, 0.11, 1.0),
            emissiveColor: SIMD3(0.06, 0.08, 0.05),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let ochre = ColorTheme(
        name: "Ochre",
        newborn: TierColors(
            baseColor: SIMD4(0.92, 0.72, 0.20, 1.0),
            emissiveColor: SIMD3(0.92, 0.72, 0.20),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.72, 0.52, 0.14, 1.0),
            emissiveColor: SIMD3(0.62, 0.44, 0.10),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.48, 0.32, 0.08, 1.0),
            emissiveColor: SIMD3(0.38, 0.25, 0.06),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.22, 0.14, 0.04, 1.0),
            emissiveColor: SIMD3(0.12, 0.08, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let umber = ColorTheme(
        name: "Umber",
        newborn: TierColors(
            baseColor: SIMD4(0.72, 0.45, 0.20, 1.0),
            emissiveColor: SIMD3(0.72, 0.45, 0.20),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.52, 0.30, 0.14, 1.0),
            emissiveColor: SIMD3(0.45, 0.26, 0.10),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.34, 0.20, 0.08, 1.0),
            emissiveColor: SIMD3(0.26, 0.15, 0.06),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.16, 0.09, 0.03, 1.0),
            emissiveColor: SIMD3(0.08, 0.05, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let sienna = ColorTheme(
        name: "Sienna",
        newborn: TierColors(
            baseColor: SIMD4(0.80, 0.38, 0.18, 1.0),
            emissiveColor: SIMD3(0.80, 0.38, 0.18),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.58, 0.26, 0.12, 1.0),
            emissiveColor: SIMD3(0.50, 0.22, 0.10),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.38, 0.16, 0.07, 1.0),
            emissiveColor: SIMD3(0.30, 0.12, 0.05),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.07, 0.02, 1.0),
            emissiveColor: SIMD3(0.09, 0.04, 0.01),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let viridian = ColorTheme(
        name: "Viridian",
        newborn: TierColors(
            baseColor: SIMD4(0.25, 0.72, 0.55, 1.0),
            emissiveColor: SIMD3(0.25, 0.72, 0.55),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.18, 0.52, 0.40, 1.0),
            emissiveColor: SIMD3(0.14, 0.45, 0.34),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.10, 0.34, 0.26, 1.0),
            emissiveColor: SIMD3(0.08, 0.26, 0.20),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.04, 0.16, 0.12, 1.0),
            emissiveColor: SIMD3(0.02, 0.08, 0.06),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let pewter = ColorTheme(
        name: "Pewter",
        newborn: TierColors(
            baseColor: SIMD4(0.70, 0.72, 0.75, 1.0),
            emissiveColor: SIMD3(0.70, 0.72, 0.75),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.50, 0.52, 0.56, 1.0),
            emissiveColor: SIMD3(0.45, 0.47, 0.52),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.32, 0.34, 0.38, 1.0),
            emissiveColor: SIMD3(0.25, 0.27, 0.32),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.16, 0.19, 1.0),
            emissiveColor: SIMD3(0.08, 0.08, 0.10),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let celadon = ColorTheme(
        name: "Celadon",
        newborn: TierColors(
            baseColor: SIMD4(0.68, 0.85, 0.72, 1.0),
            emissiveColor: SIMD3(0.68, 0.85, 0.72),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.50, 0.68, 0.54, 1.0),
            emissiveColor: SIMD3(0.42, 0.60, 0.46),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.32, 0.48, 0.36, 1.0),
            emissiveColor: SIMD3(0.24, 0.38, 0.28),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.14, 0.22, 0.16, 1.0),
            emissiveColor: SIMD3(0.06, 0.12, 0.08),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let turquoise = ColorTheme(
        name: "Turquoise",
        newborn: TierColors(
            baseColor: SIMD4(0.15, 0.88, 0.82, 1.0),
            emissiveColor: SIMD3(0.15, 0.88, 0.82),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.10, 0.68, 0.65, 1.0),
            emissiveColor: SIMD3(0.08, 0.58, 0.55),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.06, 0.45, 0.44, 1.0),
            emissiveColor: SIMD3(0.04, 0.35, 0.34),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.02, 0.20, 0.19, 1.0),
            emissiveColor: SIMD3(0.01, 0.10, 0.09),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let denim = ColorTheme(
        name: "Denim",
        newborn: TierColors(
            baseColor: SIMD4(0.40, 0.55, 0.78, 1.0),
            emissiveColor: SIMD3(0.40, 0.55, 0.78),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.28, 0.40, 0.62, 1.0),
            emissiveColor: SIMD3(0.22, 0.34, 0.56),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.16, 0.24, 0.42, 1.0),
            emissiveColor: SIMD3(0.10, 0.18, 0.34),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.12, 0.22, 1.0),
            emissiveColor: SIMD3(0.04, 0.06, 0.14),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let apricot = ColorTheme(
        name: "Apricot",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.65, 0.38, 1.0),
            emissiveColor: SIMD3(0.95, 0.65, 0.38),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.82, 0.48, 0.25, 1.0),
            emissiveColor: SIMD3(0.72, 0.40, 0.20),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.55, 0.28, 0.14, 1.0),
            emissiveColor: SIMD3(0.42, 0.20, 0.10),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.30, 0.14, 0.06, 1.0),
            emissiveColor: SIMD3(0.18, 0.08, 0.03),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let plum = ColorTheme(
        name: "Plum",
        newborn: TierColors(
            baseColor: SIMD4(0.72, 0.22, 0.55, 1.0),
            emissiveColor: SIMD3(0.72, 0.22, 0.55),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.52, 0.14, 0.42, 1.0),
            emissiveColor: SIMD3(0.46, 0.10, 0.36),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.32, 0.08, 0.28, 1.0),
            emissiveColor: SIMD3(0.24, 0.04, 0.22),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.16, 0.04, 0.14, 1.0),
            emissiveColor: SIMD3(0.08, 0.02, 0.08),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let wisteria = ColorTheme(
        name: "Wisteria",
        newborn: TierColors(
            baseColor: SIMD4(0.70, 0.55, 0.90, 1.0),
            emissiveColor: SIMD3(0.70, 0.55, 0.90),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.50, 0.38, 0.72, 1.0),
            emissiveColor: SIMD3(0.44, 0.32, 0.66),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.30, 0.20, 0.50, 1.0),
            emissiveColor: SIMD3(0.22, 0.14, 0.40),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.10, 0.25, 1.0),
            emissiveColor: SIMD3(0.08, 0.05, 0.14),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let rosewood = ColorTheme(
        name: "Rosewood",
        newborn: TierColors(
            baseColor: SIMD4(0.80, 0.35, 0.22, 1.0),
            emissiveColor: SIMD3(0.80, 0.35, 0.22),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.55, 0.22, 0.14, 1.0),
            emissiveColor: SIMD3(0.48, 0.18, 0.10),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.12, 0.08, 1.0),
            emissiveColor: SIMD3(0.28, 0.08, 0.05),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.06, 0.04, 1.0),
            emissiveColor: SIMD3(0.10, 0.03, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let patina = ColorTheme(
        name: "Patina",
        newborn: TierColors(
            baseColor: SIMD4(0.45, 0.78, 0.72, 1.0),
            emissiveColor: SIMD3(0.45, 0.78, 0.72),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.32, 0.58, 0.55, 1.0),
            emissiveColor: SIMD3(0.28, 0.50, 0.48),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.20, 0.40, 0.38, 1.0),
            emissiveColor: SIMD3(0.15, 0.32, 0.30),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.10, 0.22, 0.20, 1.0),
            emissiveColor: SIMD3(0.06, 0.14, 0.12),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let carnelian = ColorTheme(
        name: "Carnelian",
        newborn: TierColors(
            baseColor: SIMD4(0.88, 0.32, 0.15, 1.0),
            emissiveColor: SIMD3(0.88, 0.32, 0.15),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.65, 0.20, 0.10, 1.0),
            emissiveColor: SIMD3(0.58, 0.16, 0.08),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.42, 0.12, 0.06, 1.0),
            emissiveColor: SIMD3(0.34, 0.08, 0.04),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.22, 0.06, 0.03, 1.0),
            emissiveColor: SIMD3(0.12, 0.03, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let malachite = ColorTheme(
        name: "Malachite",
        newborn: TierColors(
            baseColor: SIMD4(0.18, 0.75, 0.42, 1.0),
            emissiveColor: SIMD3(0.18, 0.75, 0.42),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.10, 0.52, 0.28, 1.0),
            emissiveColor: SIMD3(0.08, 0.45, 0.24),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.05, 0.32, 0.16, 1.0),
            emissiveColor: SIMD3(0.04, 0.25, 0.12),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.02, 0.16, 0.08, 1.0),
            emissiveColor: SIMD3(0.01, 0.08, 0.04),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let alexandrite = ColorTheme(
        name: "Alexandrite",
        newborn: TierColors(
            baseColor: SIMD4(0.32, 0.68, 0.58, 1.0),
            emissiveColor: SIMD3(0.32, 0.68, 0.58),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.20, 0.42, 0.50, 1.0),
            emissiveColor: SIMD3(0.18, 0.38, 0.46),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.18, 0.22, 0.38, 1.0),
            emissiveColor: SIMD3(0.15, 0.18, 0.32),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.06, 0.14, 1.0),
            emissiveColor: SIMD3(0.04, 0.03, 0.08),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let tanzanite = ColorTheme(
        name: "Tanzanite",
        newborn: TierColors(
            baseColor: SIMD4(0.45, 0.28, 0.92, 1.0),
            emissiveColor: SIMD3(0.45, 0.28, 0.92),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.30, 0.18, 0.68, 1.0),
            emissiveColor: SIMD3(0.25, 0.14, 0.58),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.18, 0.10, 0.42, 1.0),
            emissiveColor: SIMD3(0.14, 0.08, 0.35),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.08, 0.04, 0.20, 1.0),
            emissiveColor: SIMD3(0.04, 0.02, 0.10),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let citrine = ColorTheme(
        name: "Citrine",
        newborn: TierColors(
            baseColor: SIMD4(0.92, 0.78, 0.18, 1.0),
            emissiveColor: SIMD3(0.92, 0.78, 0.18),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.72, 0.55, 0.12, 1.0),
            emissiveColor: SIMD3(0.65, 0.48, 0.10),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.45, 0.32, 0.08, 1.0),
            emissiveColor: SIMD3(0.38, 0.26, 0.06),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.20, 0.14, 0.04, 1.0),
            emissiveColor: SIMD3(0.10, 0.07, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let topaz = ColorTheme(
        name: "Topaz",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.62, 0.15, 1.0),
            emissiveColor: SIMD3(0.95, 0.62, 0.15),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.78, 0.42, 0.10, 1.0),
            emissiveColor: SIMD3(0.70, 0.36, 0.08),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.52, 0.25, 0.06, 1.0),
            emissiveColor: SIMD3(0.42, 0.20, 0.04),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.25, 0.12, 0.03, 1.0),
            emissiveColor: SIMD3(0.12, 0.06, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let fluorite = ColorTheme(
        name: "Fluorite",
        newborn: TierColors(
            baseColor: SIMD4(0.55, 0.28, 0.92, 1.0),
            emissiveColor: SIMD3(0.55, 0.28, 0.92),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.30, 0.55, 0.72, 1.0),
            emissiveColor: SIMD3(0.25, 0.48, 0.65),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.18, 0.42, 0.35, 1.0),
            emissiveColor: SIMD3(0.14, 0.35, 0.28),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.10, 0.18, 0.15, 1.0),
            emissiveColor: SIMD3(0.05, 0.09, 0.07),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let sunstone = ColorTheme(
        name: "Sunstone",
        newborn: TierColors(
            baseColor: SIMD4(0.95, 0.62, 0.20, 1.0),
            emissiveColor: SIMD3(0.95, 0.62, 0.20),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.78, 0.42, 0.14, 1.0),
            emissiveColor: SIMD3(0.70, 0.38, 0.12),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.52, 0.28, 0.10, 1.0),
            emissiveColor: SIMD3(0.42, 0.22, 0.08),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.24, 0.12, 0.05, 1.0),
            emissiveColor: SIMD3(0.12, 0.06, 0.03),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let rhodonite = ColorTheme(
        name: "Rhodonite",
        newborn: TierColors(
            baseColor: SIMD4(0.88, 0.42, 0.55, 1.0),
            emissiveColor: SIMD3(0.88, 0.42, 0.55),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.68, 0.28, 0.40, 1.0),
            emissiveColor: SIMD3(0.60, 0.24, 0.35),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.42, 0.15, 0.25, 1.0),
            emissiveColor: SIMD3(0.35, 0.12, 0.20),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.07, 0.12, 1.0),
            emissiveColor: SIMD3(0.10, 0.04, 0.06),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let lapisLazuli = ColorTheme(
        name: "Lapis Lazuli",
        newborn: TierColors(
            baseColor: SIMD4(0.15, 0.25, 0.85, 1.0),
            emissiveColor: SIMD3(0.15, 0.25, 0.85),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.10, 0.16, 0.62, 1.0),
            emissiveColor: SIMD3(0.08, 0.14, 0.55),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.06, 0.10, 0.38, 1.0),
            emissiveColor: SIMD3(0.04, 0.08, 0.30),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.03, 0.05, 0.18, 1.0),
            emissiveColor: SIMD3(0.02, 0.03, 0.09),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let zircon = ColorTheme(
        name: "Zircon",
        newborn: TierColors(
            baseColor: SIMD4(0.72, 0.82, 0.95, 1.0),
            emissiveColor: SIMD3(0.72, 0.82, 0.95),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.48, 0.58, 0.78, 1.0),
            emissiveColor: SIMD3(0.42, 0.52, 0.72),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.25, 0.32, 0.52, 1.0),
            emissiveColor: SIMD3(0.20, 0.26, 0.45),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.10, 0.14, 0.25, 1.0),
            emissiveColor: SIMD3(0.05, 0.07, 0.12),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let onyx = ColorTheme(
        name: "Onyx",
        newborn: TierColors(
            baseColor: SIMD4(0.55, 0.52, 0.58, 1.0),
            emissiveColor: SIMD3(0.55, 0.52, 0.58),
            emissiveIntensity: 1.8, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.32, 0.30, 0.35, 1.0),
            emissiveColor: SIMD3(0.28, 0.26, 0.32),
            emissiveIntensity: 1.0, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.15, 0.14, 0.18, 1.0),
            emissiveColor: SIMD3(0.12, 0.11, 0.15),
            emissiveIntensity: 0.35, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.06, 0.05, 0.08, 1.0),
            emissiveColor: SIMD3(0.03, 0.02, 0.04),
            emissiveIntensity: 0.06, opacity: 0.03)
    )


    static let tourmaline = ColorTheme(
        name: "Tourmaline",
        newborn: TierColors(
            baseColor: SIMD4(0.88, 0.22, 0.58, 1.0),
            emissiveColor: SIMD3(0.88, 0.22, 0.58),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.68, 0.15, 0.52, 1.0),
            emissiveColor: SIMD3(0.60, 0.12, 0.45),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.42, 0.08, 0.35, 1.0),
            emissiveColor: SIMD3(0.32, 0.06, 0.28),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.20, 0.04, 0.16, 1.0),
            emissiveColor: SIMD3(0.10, 0.02, 0.08),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let larimar = ColorTheme(
        name: "Larimar",
        newborn: TierColors(
            baseColor: SIMD4(0.55, 0.82, 0.92, 1.0),
            emissiveColor: SIMD3(0.55, 0.82, 0.92),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.38, 0.62, 0.78, 1.0),
            emissiveColor: SIMD3(0.32, 0.55, 0.70),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.22, 0.42, 0.58, 1.0),
            emissiveColor: SIMD3(0.18, 0.35, 0.48),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.10, 0.20, 0.30, 1.0),
            emissiveColor: SIMD3(0.05, 0.10, 0.15),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let jasper = ColorTheme(
        name: "Jasper",
        newborn: TierColors(
            baseColor: SIMD4(0.82, 0.35, 0.18, 1.0),
            emissiveColor: SIMD3(0.82, 0.35, 0.18),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.58, 0.22, 0.12, 1.0),
            emissiveColor: SIMD3(0.52, 0.18, 0.10),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.35, 0.12, 0.08, 1.0),
            emissiveColor: SIMD3(0.28, 0.10, 0.06),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.15, 0.05, 0.03, 1.0),
            emissiveColor: SIMD3(0.08, 0.03, 0.02),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let labradorite = ColorTheme(
        name: "Labradorite",
        newborn: TierColors(
            baseColor: SIMD4(0.22, 0.65, 0.85, 1.0),
            emissiveColor: SIMD3(0.22, 0.65, 0.85),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.18, 0.50, 0.62, 1.0),
            emissiveColor: SIMD3(0.15, 0.45, 0.55),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.12, 0.30, 0.38, 1.0),
            emissiveColor: SIMD3(0.10, 0.25, 0.30),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.06, 0.14, 0.18, 1.0),
            emissiveColor: SIMD3(0.03, 0.07, 0.09),
            emissiveIntensity: 0.08, opacity: 0.03)
    )


    static let amazonite = ColorTheme(
        name: "Amazonite",
        newborn: TierColors(
            baseColor: SIMD4(0.30, 0.85, 0.78, 1.0),
            emissiveColor: SIMD3(0.28, 0.82, 0.75),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.20, 0.58, 0.55, 1.0),
            emissiveColor: SIMD3(0.18, 0.52, 0.50),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.10, 0.32, 0.30, 1.0),
            emissiveColor: SIMD3(0.08, 0.28, 0.26),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.04, 0.15, 0.14, 1.0),
            emissiveColor: SIMD3(0.02, 0.10, 0.09),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let amber = ColorTheme(
        name: "Amber",
        newborn: TierColors(
            baseColor: SIMD4(0.90, 0.65, 0.10, 1.0),
            emissiveColor: SIMD3(0.90, 0.65, 0.10),
            emissiveIntensity: 2.1, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.68, 0.42, 0.08, 1.0),
            emissiveColor: SIMD3(0.60, 0.38, 0.06),
            emissiveIntensity: 1.1, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.42, 0.24, 0.05, 1.0),
            emissiveColor: SIMD3(0.32, 0.18, 0.04),
            emissiveIntensity: 0.40, opacity: 0.18),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.10, 0.02, 1.0),
            emissiveColor: SIMD3(0.10, 0.05, 0.01),
            emissiveIntensity: 0.08, opacity: 0.03)
    )

    static let sodalite = ColorTheme(
        name: "Sodalite",
        newborn: TierColors(
            baseColor: SIMD4(0.22, 0.32, 0.88, 1.0),
            emissiveColor: SIMD3(0.20, 0.30, 0.85),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.14, 0.22, 0.62, 1.0),
            emissiveColor: SIMD3(0.12, 0.20, 0.58),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.08, 0.12, 0.35, 1.0),
            emissiveColor: SIMD3(0.06, 0.10, 0.32),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.03, 0.05, 0.16, 1.0),
            emissiveColor: SIMD3(0.02, 0.04, 0.12),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let rhodochrosite = ColorTheme(
        name: "Rhodochrosite",
        newborn: TierColors(
            baseColor: SIMD4(0.92, 0.45, 0.55, 1.0),
            emissiveColor: SIMD3(0.90, 0.42, 0.52),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.65, 0.28, 0.38, 1.0),
            emissiveColor: SIMD3(0.60, 0.25, 0.35),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.38, 0.15, 0.22, 1.0),
            emissiveColor: SIMD3(0.32, 0.12, 0.18),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.06, 0.10, 1.0),
            emissiveColor: SIMD3(0.12, 0.04, 0.07),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let kunzite = ColorTheme(
        name: "Kunzite",
        newborn: TierColors(
            baseColor: SIMD4(0.88, 0.52, 0.82, 1.0),
            emissiveColor: SIMD3(0.85, 0.48, 0.78),
            emissiveIntensity: 2.0, opacity: 0.55),
        young: TierColors(
            baseColor: SIMD4(0.62, 0.32, 0.58, 1.0),
            emissiveColor: SIMD3(0.58, 0.28, 0.54),
            emissiveIntensity: 1.2, opacity: 0.35),
        mature: TierColors(
            baseColor: SIMD4(0.38, 0.15, 0.35, 1.0),
            emissiveColor: SIMD3(0.32, 0.12, 0.30),
            emissiveIntensity: 0.8, opacity: 0.25),
        dying: TierColors(
            baseColor: SIMD4(0.18, 0.06, 0.16, 1.0),
            emissiveColor: SIMD3(0.12, 0.04, 0.10),
            emissiveIntensity: 0.4, opacity: 0.10)
    )

    static let allThemes: [ColorTheme] = [.neon, .warmAmber, .oceanBlues, .aurora, .monochrome, .infrared, .bioluminescence, .sakura, .ember, .nebula, .glacier, .coral, .forest, .sunset, .twilight, .jade, .crimson, .amethyst, .copper, .gold, .midnight, .volcanic, .plasma, .frost, .arctic, .solar, .toxic, .starfield, .hologram, .cyberpunk, .vaporwave, .synthwave, .terracotta, .lavender, .matrix, .champagne, .opal, .roseGold, .peridot, .sapphire, .obsidian, .ruby, .titanium, .garnet, .emerald, .tungsten, .aquamarine, .bronze, .ivory, .pearl, .graphite, .slate, .cobalt, .vermilion, .indigo, .mahogany, .burgundy, .teal, .chartreuse, .saffron, .moss, .cerulean, .mauve, .marigold, .sage, .ochre, .umber, .sienna, .viridian, .pewter, .celadon, .turquoise, .denim, .apricot, .plum, .wisteria, .rosewood, .patina, .carnelian, .malachite, .alexandrite, .tanzanite, .citrine, .topaz, .fluorite, .sunstone, .rhodonite, .lapisLazuli, .zircon, .onyx, .tourmaline, .larimar, .jasper, .labradorite, .amazonite, .amber, .sodalite, .rhodochrosite, .kunzite]
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

    /// Scale factor for birth animation and death fade.
    /// Positive ages: cells grow over their first few generations.
    /// Negative ages: fading cells shrink (-1 = just died/largest, -3 = nearly gone/smallest).
    private static func birthScale(for age: Int) -> Float {
        switch age {
        case ...(-3): return 0.15  // nearly gone
        case -2: return 0.3        // mid-fade
        case -1: return 0.5        // just died
        case 0: return 0.5         // dead (shouldn't render, but safe fallback)
        case 1: return 0.5         // just born: half size
        case 2: return 0.75        // growing
        case 3: return 0.9         // almost full
        default: return 1.0        // mature: full size
        }
    }

    /// Test-accessible wrapper for mesh data computation.
    static func computeMeshDataForTest(model: GridModel) -> MeshData {
        computeMeshData(model: model)
    }

    // MARK: - Cube Template (static, allocated once)

    private static let cubeVertexCount = 24
    private static let cubeIndexCount = 36

    /// Unit cube positions (±0.5) — scaled per-cell at build time.
    private static let cubeUnitPositions: [SIMD3<Float>] = [
        SIMD3( 0.5, -0.5, -0.5), SIMD3( 0.5,  0.5, -0.5),
        SIMD3( 0.5,  0.5,  0.5), SIMD3( 0.5, -0.5,  0.5),
        SIMD3(-0.5, -0.5,  0.5), SIMD3(-0.5,  0.5,  0.5),
        SIMD3(-0.5,  0.5, -0.5), SIMD3(-0.5, -0.5, -0.5),
        SIMD3(-0.5,  0.5,  0.5), SIMD3( 0.5,  0.5,  0.5),
        SIMD3( 0.5,  0.5, -0.5), SIMD3(-0.5,  0.5, -0.5),
        SIMD3(-0.5, -0.5, -0.5), SIMD3( 0.5, -0.5, -0.5),
        SIMD3( 0.5, -0.5,  0.5), SIMD3(-0.5, -0.5,  0.5),
        SIMD3(-0.5, -0.5,  0.5), SIMD3( 0.5, -0.5,  0.5),
        SIMD3( 0.5,  0.5,  0.5), SIMD3(-0.5,  0.5,  0.5),
        SIMD3( 0.5, -0.5, -0.5), SIMD3(-0.5, -0.5, -0.5),
        SIMD3(-0.5,  0.5, -0.5), SIMD3( 0.5,  0.5, -0.5),
    ]

    private static let cubeNormals: [SIMD3<Float>] = [
        SIMD3(1,0,0), SIMD3(1,0,0), SIMD3(1,0,0), SIMD3(1,0,0),
        SIMD3(-1,0,0), SIMD3(-1,0,0), SIMD3(-1,0,0), SIMD3(-1,0,0),
        SIMD3(0,1,0), SIMD3(0,1,0), SIMD3(0,1,0), SIMD3(0,1,0),
        SIMD3(0,-1,0), SIMD3(0,-1,0), SIMD3(0,-1,0), SIMD3(0,-1,0),
        SIMD3(0,0,1), SIMD3(0,0,1), SIMD3(0,0,1), SIMD3(0,0,1),
        SIMD3(0,0,-1), SIMD3(0,0,-1), SIMD3(0,0,-1), SIMD3(0,0,-1),
    ]

    private static let cubeUVs: [SIMD2<Float>] = [
        SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
        SIMD2(0,0), SIMD2(0,1), SIMD2(1,1), SIMD2(1,0),
    ]

    private static let cubeTemplateIndices: [UInt32] = [
         0,  1,  2,   0,  2,  3,
         4,  5,  6,   4,  6,  7,
         8,  9, 10,   8, 10, 11,
        12, 13, 14,  12, 14, 15,
        16, 17, 18,  16, 18, 19,
        20, 21, 22,  20, 22, 23,
    ]

    /// Computes raw vertex and index arrays for alive cells + fading cells, sorted by age tier.
    /// Applies depth-based scaling: cells further from grid center are slightly smaller,
    /// creating a natural depth-of-field effect without shader-level blur.
    private static func computeMeshData(model: GridModel) -> MeshData {
        var cellsWithAge = model.aliveCellsWithAge(cellSize: cellSize, cellSpacing: cellSpacing)
        // Add fading cells with negative age sentinel (mapped to .dying tier).
        let fadingCells = model.fadingCellsWithProgress(cellSize: cellSize, cellSpacing: cellSpacing)
        for fading in fadingCells {
            let framesLeft = max(Int(round(fading.progress * Float(GridModel.fadeDuration))), 1)
            let fadeStage = GridModel.fadeDuration - framesLeft + 1
            cellsWithAge.append((position: fading.position, age: -fadeStage))
        }
        let aliveCells = cellsWithAge.count

        let half = cellSize / 2.0
        let stride = cellSize + cellSpacing
        let gridExtent = Float(model.size - 1) * stride / 2.0 + half

        guard aliveCells > 0 else {
            return MeshData(vertices: [], indices: [], gridExtent: gridExtent, cellCount: 0,
                          tierRanges: AgeTier.allCases.map { _ in (0, 0) })
        }

        // Bucket cells by age tier in O(n) instead of O(n log n) sort — only 4 buckets needed
        var buckets: [[(position: SIMD3<Float>, age: Int)]] = Array(repeating: [], count: AgeTier.allCases.count)
        for cell in cellsWithAge {
            buckets[AgeTier.tier(for: cell.age).rawValue].append(cell)
        }
        let sorted = buckets.flatMap { $0 }

        // Pre-compute depth scale: cells at the grid edge are slightly smaller (80% of full size)
        // This creates a pseudo depth-of-field effect — peripheral cells recede visually
        // Uses squared distance to avoid per-cell sqrt() — visual difference is negligible
        let depthFalloff: Float = 0.2  // 20% size reduction at maximum distance
        let maxDistSq: Float = max(gridExtent * gridExtent * 3.0, .leastNonzeroMagnitude)  // guard div-by-zero for size=1

        let totalVertices = aliveCells * cubeVertexCount
        let totalIndices = aliveCells * cubeIndexCount

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

            let ageScale = birthScale(for: cell.age)
            // Depth-based scale: cells further from center shrink slightly (squared distance — no sqrt)
            let distSq = simd_length_squared(cell.position)
            let depthScale: Float = 1.0 - depthFalloff * min(distSq / maxDistSq, 1.0)
            let scale = ageScale * depthScale
            let vertexOffset = UInt32(vi)
            for j in 0..<cubeVertexCount {
                vertices[vi] = GridVertex(
                    position: cubeUnitPositions[j] * cellSize * scale + cell.position,
                    normal: cubeNormals[j],
                    uv: cubeUVs[j]
                )
                vi += 1
            }
            for idx in cubeTemplateIndices {
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

    /// Creates a wireframe boundary cube entity showing the simulation volume.
    @MainActor
    static func makeBoundaryWireframe(gridSize: Int, theme: ColorTheme) -> Entity {
        let stride = cellSize + cellSpacing
        let extent = Float(gridSize - 1) * stride / 2.0 + cellSize / 2.0 + cellSpacing * 0.5
        let edgeThickness: Float = 0.0008

        let entity = Entity()
        entity.name = "BoundaryWireframe"

        // 12 edges of a cube: 4 along each axis
        struct Edge { var start: SIMD3<Float>; var end: SIMD3<Float> }
        let e = extent
        let corners: [(Float, Float)] = [(-e, -e), (-e, e), (e, -e), (e, e)]
        var edges: [Edge] = []

        // X-axis edges (along x, at 4 y/z corners)
        for (y, z) in corners {
            edges.append(Edge(start: SIMD3(-e, y, z), end: SIMD3(e, y, z)))
        }
        // Y-axis edges (along y, at 4 x/z corners)
        for (x, z) in corners {
            edges.append(Edge(start: SIMD3(x, -e, z), end: SIMD3(x, e, z)))
        }
        // Z-axis edges (along z, at 4 x/y corners)
        for (x, y) in corners {
            edges.append(Edge(start: SIMD3(x, y, -e), end: SIMD3(x, y, e)))
        }

        let emissive = theme.mature.emissiveColor
        var mat = UnlitMaterial()
        mat.color = .init(tint: .init(
            red: CGFloat(emissive.x), green: CGFloat(emissive.y),
            blue: CGFloat(emissive.z), alpha: 0.3))

        for edge in edges {
            let mid = (edge.start + edge.end) / 2.0
            let diff = edge.end - edge.start
            let length = simd_length(diff)
            let mesh = MeshResource.generateBox(
                width: abs(diff.x) > 0.001 ? length : edgeThickness,
                height: abs(diff.y) > 0.001 ? length : edgeThickness,
                depth: abs(diff.z) > 0.001 ? length : edgeThickness
            )
            let edgeEntity = ModelEntity(mesh: mesh, materials: [mat])
            edgeEntity.position = mid
            entity.addChild(edgeEntity)
        }

        return entity
    }

    /// Creates a MeshResource from pre-computed mesh data using LowLevelMesh.
    /// Pre-computed vertex attribute offsets (computed once, avoids repeated MemoryLayout calls).
    private static let positionOffset = MemoryLayout<GridVertex>.offset(of: \.position) ?? 0
    private static let normalOffset = MemoryLayout<GridVertex>.offset(of: \.normal) ?? MemoryLayout<SIMD3<Float>>.stride
    private static let uvOffset = MemoryLayout<GridVertex>.offset(of: \.uv) ?? MemoryLayout<SIMD3<Float>>.stride * 2

    @MainActor
    private static func createMeshResource(from data: MeshData) throws -> MeshResource {
        let vertexStride = MemoryLayout<GridVertex>.stride

        var descriptor = LowLevelMesh.Descriptor()
        descriptor.vertexCapacity = data.vertices.count
        descriptor.indexCapacity = data.indices.count

        descriptor.vertexAttributes = [
            .init(semantic: .position, format: .float3, layoutIndex: 0,
                  offset: positionOffset),
            .init(semantic: .normal, format: .float3, layoutIndex: 0,
                  offset: normalOffset),
            .init(semantic: .uv0, format: .float2, layoutIndex: 0,
                  offset: uvOffset),
        ]
        descriptor.vertexLayouts = [
            .init(bufferIndex: 0, bufferStride: vertexStride),
        ]
        descriptor.indexType = .uint32

        let mesh = try LowLevelMesh(descriptor: descriptor)

        mesh.withUnsafeMutableBytes(bufferIndex: 0) { buffer in
            data.vertices.withUnsafeBufferPointer { src in
                buffer.copyMemory(from: UnsafeRawBufferPointer(src))
            }
        }

        mesh.withUnsafeMutableIndices { buffer in
            data.indices.withUnsafeBufferPointer { src in
                buffer.copyMemory(from: UnsafeRawBufferPointer(src))
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
