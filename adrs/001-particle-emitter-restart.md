# ADR 001: ParticleEmitterComponent Restart Pattern for Pooled Emitters

**Status**: Accepted (revised — Option C adopted)
**Date**: 2026-04-13 (updated 2026-04-13)
**Context**: Issue #5 — particle effects stop firing after the first generation; Issue #7 — confirmed Option B insufficient in practice, adopted Option C

---

## Problem

`ParticleEmitterComponent.timing = .once(warmUp:emit:)` fires a single burst and then becomes inert. The Life3D particle system pools emitter entities (10 birth, 10 death, 1 pulse) and reuses them across every generation. Once a `.once` emitter completes its cycle, subsequent calls to `entity.components.set(emitter)` with `emitter.isEmitting = true` have no effect — the timing state has already expired. This meant particles only worked for the first generation, then went permanently silent.

---

## Options Considered

### Option A: `emitter.restart()`

Call the documented `ParticleEmitterComponent.restart()` method before `isEmitting = true`.

**Rejected**: `restart()` behavior on visionOS 2 is unconfirmed. Community reports suggest it works on macOS/iOS but may behave differently on visionOS. Too risky without on-device validation.

### Option B: Re-assign the `timing` field

Re-assign `emitter.timing` to a fresh `.once(warmUp: 0, emit: VariableDuration(duration: X))` value before every `isEmitting = true` at each trigger site.

**Attempted, found insufficient in practice**: Implemented in `triggerParticles()` and `triggerPulse()` during Issue #5. Despite `ParticleEmitterComponent` being a Swift value type (which should produce a clean timing value on re-assignment), the fix did not work — particles continued to fire only on the first generation. RealityKit appears to maintain internal "has-fired" state on the entity/component that is not reset by field re-assignment alone.

### Option C: Full component replacement

Recreate `ParticleEmitterComponent` from scratch on each trigger via a shared `makeParticleEmitterComponent(isBirth:themeColors:)` helper, re-applying all fields including color from `engine.theme` at trigger time.

**Adopted**: A freshly constructed component has no internal firing history. The concern about stripping color state (the original reason Option C was initially rejected) is addressed by re-reading `engine.theme` at the trigger site — this also ensures trigger-time color accuracy regardless of `updateParticleEmitterColors()` call timing.

---

## Decision

Use `makeParticleEmitterComponent(isBirth:themeColors:)` to construct a fresh component at every trigger site:

```swift
// In triggerParticles() — birth branch (Option C: fresh construction each trigger)
var emitter = Self.makeParticleEmitterComponent(isBirth: true, themeColors: engine.theme.newborn)
emitter.isEmitting = true
emitter.burstCount = 12
entity.components.set(emitter)

// In triggerParticles() — death branch
var emitter = Self.makeParticleEmitterComponent(isBirth: false, themeColors: engine.theme.dying)
emitter.isEmitting = true
emitter.burstCount = 8
entity.components.set(emitter)
```

The `makeParticleEmitterComponent()` helper is also called by `makeParticleEmitter()` at pool initialization time, so both code paths share the same configuration. Duration values (`birthEmitDuration`, `deathEmitDuration`) are static constants to prevent setup/trigger drift.

---

## Consequences

- Pooled emitters fire correctly on every generation trigger, not just the first.
- Color at trigger time comes from `engine.theme` directly — `updateParticleEmitterColors()` writes between triggers are superseded on the next trigger. This is acceptable; the trigger path is authoritative.
- The `makeParticleEmitterComponent()` helper is the single source of truth for emitter configuration. Changes to emitter parameters (size, acceleration, burst count) need only be made in one place.
- Future contributors must use `makeParticleEmitterComponent()` at any new trigger site that uses `.once` emitters. Omitting it (or regressing to Option B) causes the silent-after-first-use bug to recur.
- `triggerPulse()` uses the same `.once` timing pattern. If it exhibits the same stopping bug, apply the same Option C fix: extract `makePulseEmitterComponent()` and call it at trigger time.

---

## Spread Angle Companion Change

As part of Issue #5, birth and death `spreadingAngle` were reduced from `.pi` / `.pi * 2/3` to `.pi / 6` for all emitter types. With the original 1.5–2.0 m/s² acceleration and 0.7–1.0s lifespans, the original angles produced 30–40cm lateral spread from a 1.5cm cell boundary — cross-grid spray rather than cell-localized sparkle. `.pi / 6` (30°) gives ~10cm lateral spread for birth and ~27cm for death. If death particles appear too columnar, `.pi / 4` (45°) is the suggested widening.

## Size and Acceleration Calibration (Issue #7)

Prior emitter configuration (size 20mm, acceleration 1.5–2.0 m/s²) was calibrated when the original problem was *invisibility* (3mm particles) — those large values were deliberately chosen for visibility. After the spread angle fix they produced an explosion that obscured the grid. Issue #7 replaced them with cell-proportional values:

- `mainEmitter.size`: 6mm (birth) / 5mm (death) — visible at 1.5m (~11/9px) without obscuring cubes
- `emitterShapeSize`: 8mm — half cell diameter; particles spawn inside cell boundary
- `acceleration`: 0.12 m/s² (birth up) / 0.06 m/s² (death down) — `d = 0.5×a×t²` gives ≤ 2 cell widths travel
- `burstCount` at trigger: 12 (birth) / 8 (death) — proportional to corrected particle size
