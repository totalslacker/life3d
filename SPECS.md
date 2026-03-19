# Project Specification

## What Life3D Is

Life3D is a **3D Game of Life for Apple Vision Pro** — a mesmerizing spatial art
piece that happens to be a cellular automaton. Cells exist as luminous, translucent
volumes floating in a 3D grid rendered in your physical space. You interact with
them using your hands, watch them evolve, and lose yourself in the beauty of
emergent complexity.

## Purpose

1. **Showcase visionOS spatial computing** — volumetric rendering, hand tracking,
   spatial audio, and immersive spaces working together in a single cohesive experience
2. **Make cellular automata beautiful** — move beyond flat grids and wireframes into
   something that feels like a living art installation
3. **Demonstrate spatial interaction design** — natural, intuitive controls that
   feel native to the platform, not ported from a touchscreen

## Requirements

### Core Simulation
- 3D cellular automata on a volumetric grid (configurable size, e.g. 16x16x16 up to 64x64x64)
- Standard 3D Game of Life rules (5766 or configurable birth/survival neighbor counts)
- Step-by-step and continuous simulation modes with speed control
- Preset patterns: 3D gliders, oscillators, still lifes, and random seeds

### Visual Beauty (Core Pillar)
- Cells have **bloom, glow, and translucency** that shifts with age (newborn bright, old cells deeper/richer)
- **Color themes**: neon on black, warm amber, ocean blues, aurora borealis gradients
- **Particle effects** on birth/death — cells bloom into existence and dissolve into particles
- **Depth of field** — cells further from gaze are softly blurred
- **Light emission** — living cells cast soft light onto nearby surfaces (shared space mode)
- Smooth transitions between states (cells don't snap in/out, they animate)

### Spatial Interaction
- **Hand tracking**: pinch to toggle cells, drag to rotate/pan the grid
- **Draw mode**: place cells by pointing and pinching in 3D space
- **Scale gesture**: pinch with two hands to resize the grid volume
- **Palm-up gesture or minimal HUD**: access mid-simulation menu without breaking immersion

### Configuration & Navigation
- **Launch screen**: floating panel in shared space to choose mode, pattern, grid size, rules, color theme
- **Mid-simulation menu**: pause, reset, change pattern, tweak rules, adjust visuals, return to launch
- **Smooth transitions**: grid materializes/dissolves between launch screen and simulation

### Spatial Modes
- **Shared space** (default): tabletop-sized volume sitting in your room
- **Immersive space**: expand to fill the room, cells surround you

### Audio
- Subtle generative tones tied to cell birth/death events
- Spatially positioned audio — you hear activity where it happens in the grid
- Volume and mute controls

### Platform
- visionOS 2.0+ (Apple Vision Pro)
- Swift, SwiftUI, RealityKit, ARKit
- Target 60fps for grids up to 32x32x32

## Non-Goals

- **Not a game with win conditions** — this is a simulation/art piece, not a puzzle game
- **Not cross-platform** — visionOS only, no iOS/macOS fallback
- **Not scientifically rigorous** — beauty over accuracy when they conflict (e.g. cell shapes can be organic, not strict cubes)
- **Not multiplayer in v1** — shared experiences are a stretch goal for later
- **Not a cellular automata research tool** — no CSV export, no statistical analysis, no academic features
