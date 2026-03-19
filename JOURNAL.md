# Journal

Evolution session log. Most recent entry first. Never delete entries.

---

## Session 1 — Bootstrap visionOS app with RealityKit 3D grid (li-gg1)

Created the initial visionOS app target with RealityKit rendering. Polecat: furiosa.

Changes:
- Xcode project with visionOS app target (Life3D)
- Life3DApp.swift — SwiftUI app entry point with WindowGroup
- ContentView.swift — Main view with RealityView
- GridModel.swift — 3D grid data structure (16x16x16)
- GridRenderer.swift — RealityKit cube rendering with semi-transparent emissive material
- GridTests.swift — Logic-only unit tests for grid dimensions
- Volumetric window style causes runtime crash on visionOS 2.1 sim — used plain WindowGroup with RealityView instead
- visionOS Simulator crashes host machine — build-verify only, no test execution in CI

Lesson: visionOS Simulator is too heavy for automated test runs on this machine. Need build-only verification or a lighter test strategy.

---
