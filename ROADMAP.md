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

- [x] Implement 3D cellular automata grid data structure
- [x] 3D neighbor counting (26 neighbors per cell in a cube)
- [x] Standard 3D Game of Life rules (5766: born with 5, survive with 6-7, in 26-neighbor Moore neighborhood)
- [x] Configurable birth/survival rule sets
- [x] Step-by-step simulation mode (tap to advance one generation)
- [x] Continuous simulation with adjustable speed (generations per second)
- [x] Preset patterns: 3D gliders, oscillators, still lifes, random seed, diamond, cross, tube, sphere (session 34)
- [x] Tests: rule correctness, pattern stability, neighbor counting edge cases

## Phase 3 — Visual Beauty (Day 8-14)

- [x] Replace plain cubes with translucent, glowing cell meshes
- [x] Age-based visual evolution: newborn cells bright, old cells deeper/richer
- [x] Bloom and glow post-processing via RealityKit materials
- [x] Particle effects on cell birth (bloom into existence) — burst emitters at sampled positions (session 20)
- [x] Particle effects on cell death (dissolve into particles) — drift-down emitters at sampled positions (session 20)
- [x] Color themes: neon on black, warm amber, ocean blues, aurora borealis
- [ ] Depth of field: cells further from gaze softly blurred
- [x] Light emission: living cells cast soft light via sampled PointLight entities (session 22)
- [x] Smooth animation between cell states (death fade-out via dying tier, birth scale-up via age-based sizing)
- [ ] Performance: maintain 60fps at 32x32x32 grid (neighbor counting optimized — session 19)

## Phase 4 — Spatial Interaction (Day 15-20)

- [x] Hand tracking: pinch to toggle individual cells on/off — spatial tap gesture (session 21)
- [x] Drag gesture to rotate the grid volume
- [x] Two-hand pinch to scale the grid up/down
- [x] Draw mode: drag to paint cells in 3D space with rotate/draw toggle (session 23)
- [x] Visual feedback on hover — HoverEffectComponent on grid container (session 25)
- [x] Haptic-style visual pulse on cell toggle — particle burst at tap position (session 22)
- [ ] Tests: gesture recognition, cell toggle accuracy

## Phase 5 — Configuration & Navigation (Day 21-25)

- [x] Launch screen: floating SwiftUI panel with mode, pattern, grid size, rules, color theme selection (session 26)
- [x] Mid-simulation menu: settings overlay with pattern, theme, rules, size — gear icon toggle (session 27)
- [x] Return to launch screen from simulation (session 26)
- [x] Smooth transition: grid materializes with scale+opacity animation on entry (session 27)
- [x] Smooth transition: dissolve-out animation on exit (session 28)
- [ ] Palm-up gesture or minimal persistent HUD to invoke menu
- [x] Persist user preferences (theme, grid size, rules, speed, audio muted) via UserDefaults (session 25)

## Phase 6 — Audio & Polish (Day 26-30)

- [x] Generative spatial audio: tones on cell birth/death, positioned in 3D (session 24)
- [x] Audio follows activity density (busier regions are louder) (session 24)
- [x] Volume control and mute toggle (session 24)
- [x] Immersive space mode: expand grid to fill the room — surround mode toggle (session 24)
- [ ] Transition animation between shared and immersive space
- [ ] Performance profiling and optimization pass
- [ ] App icon and launch experience polish
- [ ] Final visual tuning across all color themes
