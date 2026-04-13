# ADR 001: ParticleEmitterComponent Restart Pattern for Pooled Emitters

**Status**: Accepted  
**Date**: 2026-04-13  
**Context**: Issue #5 — particle effects stop firing after the first generation

---

## Problem

`ParticleEmitterComponent.timing = .once(warmUp:emit:)` fires a single burst and then becomes inert. The Life3D particle system pools emitter entities (10 birth, 10 death, 1 pulse) and reuses them across every generation. Once a `.once` emitter completes its cycle, subsequent calls to `entity.components.set(emitter)` with `emitter.isEmitting = true` have no effect — the timing state has already expired. This meant particles only worked for the first generation, then went permanently silent.

---

## Options Considered

### Option A: `emitter.restart()`

Call the documented `ParticleEmitterComponent.restart()` method before `isEmitting = true`.

**Rejected**: `restart()` behavior on visionOS 2 is unconfirmed. Community reports suggest it works on macOS/iOS but may behave differently on visionOS. Too risky without on-device validation.

### Option B: Re-assign the `timing` field (chosen)

Re-assign `emitter.timing` to a fresh `.once(warmUp: 0, emit: VariableDuration(duration: X))` value before every `isEmitting = true` at each trigger site.

**Chosen**: Because `ParticleEmitterComponent` is a Swift value type, re-assigning a field produces a new `timing` value with no "has-fired" state. When `entity.components.set(emitter)` replaces the component on the entity, RealityKit receives a component with clean timing — semantically equivalent to a fresh emitter, without replacing the entire component (which would strip color state).

### Option C: Full component replacement

Recreate `ParticleEmitterComponent` from scratch on each trigger, re-applying all fields including color.

**Rejected**: `updateParticleEmitterColors()` writes color to pooled emitters on every theme change, but does not track what color was last written. Replacing the component at trigger time would require re-reading `engine.theme` at the trigger site and duplicating color application logic, coupling the two code paths. Option B leaves all non-timing fields (especially color) untouched.

---

## Decision

Re-assign `emitter.timing` at every trigger site before `emitter.isEmitting = true`:

```swift
// In triggerParticles() — birth branch
emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 0.4))
emitter.isEmitting = true
emitter.burstCount = 45
entity.components.set(emitter)

// In triggerParticles() — death branch
emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 0.3))
emitter.isEmitting = true
emitter.burstCount = 28
entity.components.set(emitter)

// In triggerPulse()
emitter.timing = .once(warmUp: 0, emit: ParticleEmitterComponent.Timing.VariableDuration(duration: 0.15))
emitter.isEmitting = true
entity.components.set(emitter)
```

The duration values match those in `makeParticleEmitter()` / `setupPulseEntity()` — they are not arbitrary; use the same values.

---

## Consequences

- Pooled emitters fire correctly on every generation trigger, not just the first.
- Color state set by `updateParticleEmitterColors()` is preserved across triggers (only the `timing` field is overwritten).
- If re-assigning the `timing` field does not reset RealityKit's internal "has-fired" counter (unlikely given Swift value semantics, but possible), the fallback is Option C (full replacement) with color re-applied from `engine.theme` at trigger time.
- Future contributors must include a `timing` reset at any new trigger site that uses `.once` emitters. Omitting it causes the silent-after-first-use bug to recur.

---

## Spread Angle Companion Change

As part of the same fix, birth and death `spreadingAngle` were reduced from `.pi` / `.pi * 2/3` to `.pi / 6` for all emitter types. With 1.5–2.0 m/s² acceleration and 0.7–1.0s lifespans, the original angles produced 30–40cm lateral spread from a 1.5cm cell boundary — cross-grid spray rather than cell-localized sparkle. `.pi / 6` (30°) gives ~10cm lateral spread for birth and ~27cm for death, consistent with the "subtle, cell-scaled sparkle" intent in SPECS.md. If death particles appear too columnar, `.pi / 4` (45°) is the suggested widening.
