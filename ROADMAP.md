# Roadmap

Living document. Updated each evolution session. Items come from three sources:
- SPECS.md (the project's requirements)
- GitHub issues from the community
- Self-assessment during evolution sessions

## Phase 1 — Bootstrap (Day 0-3)

- [ ] Create visionOS app target with SwiftUI + RealityKit
- [ ] Render a static 3D grid of cubes in a volumetric window
- [ ] Basic shared space placement (grid appears on a surface in front of you)
- [ ] Set up project structure: simulation engine, rendering, UI layers
- [ ] Add unit test target and first test (grid initialization)
- [ ] CI: Xcode build for visionOS simulator

## Phase 2 — Simulation Engine (Day 4-7)

- [ ] Implement 3D cellular automata grid data structure
- [ ] 3D neighbor counting (26 neighbors per cell in a cube)
- [ ] Standard 3D Game of Life rules (5766: born with 5, survive with 6-7, in 26-neighbor Moore neighborhood)
- [ ] Configurable birth/survival rule sets
- [ ] Step-by-step simulation mode (tap to advance one generation)
- [ ] Continuous simulation with adjustable speed (generations per second)
- [ ] Preset patterns: 3D gliders, oscillators, still lifes, random seed
- [ ] Tests: rule correctness, pattern stability, neighbor counting edge cases

## Phase 3 — Visual Beauty (Day 8-14)

- [ ] Replace plain cubes with translucent, glowing cell meshes
- [ ] Age-based visual evolution: newborn cells bright, old cells deeper/richer
- [ ] Bloom and glow post-processing via RealityKit materials
- [ ] Particle effects on cell birth (bloom into existence)
- [ ] Particle effects on cell death (dissolve into particles)
- [ ] Color themes: neon on black, warm amber, ocean blues, aurora borealis
- [ ] Depth of field: cells further from gaze softly blurred
- [ ] Light emission: living cells cast soft light onto nearby surfaces
- [ ] Smooth animation between cell states (no snap in/out)
- [ ] Performance: maintain 60fps at 32x32x32 grid

## Phase 4 — Spatial Interaction (Day 15-20)

- [ ] Hand tracking: pinch to toggle individual cells on/off
- [ ] Drag gesture to rotate the grid volume
- [ ] Two-hand pinch to scale the grid up/down
- [ ] Draw mode: point and pinch to paint cells in 3D space
- [ ] Visual feedback on hover (cell highlights before selection)
- [ ] Haptic-style visual pulse on cell toggle
- [ ] Tests: gesture recognition, cell toggle accuracy

## Phase 5 — Configuration & Navigation (Day 21-25)

- [ ] Launch screen: floating SwiftUI panel with mode, pattern, grid size, rules, color theme selection
- [ ] Mid-simulation menu: pause, reset, change pattern, tweak rules, adjust visuals
- [ ] Return to launch screen from simulation
- [ ] Smooth transition: grid materializes from launch screen, dissolves on exit
- [ ] Palm-up gesture or minimal persistent HUD to invoke menu
- [ ] Persist user preferences (last used theme, grid size, rules)

## Phase 6 — Audio & Polish (Day 26-30)

- [ ] Generative spatial audio: tones on cell birth/death, positioned in 3D
- [ ] Audio follows activity density (busier regions are louder)
- [ ] Volume control and mute toggle
- [ ] Immersive space mode: expand grid to fill the room
- [ ] Transition animation between shared and immersive space
- [ ] Performance profiling and optimization pass
- [ ] App icon and launch experience polish
- [ ] Final visual tuning across all color themes
