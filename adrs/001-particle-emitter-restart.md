# ADR 001: ParticleEmitterComponent Restart Pattern for Pooled Emitters

**Status**: Superseded — Option E adopted
**Date**: 2026-04-13 (updated 2026-04-14)
**Context**: Issue #5 — particle effects stop firing after the first generation; Issue #7 — confirmed Option B insufficient in practice, adopted Option C; Issue #9 — confirmed Option C also insufficient, adopted Option D (remove-before-set); Issue #12 — Option D found visually insufficient; root cause identified as entity-level VFX state; destroy-and-recreate adopted

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

**Found insufficient (Issue #9)**: A freshly constructed component was expected to have no internal firing history. However, diagnostic checkpoint logging in issue #9 confirmed that checkpoints P1–P5 all continued to produce correct output (onChange fired every generation, position data was non-empty, isEmitting=true read back after set, entity.parent=true) — yet particles continued to stop firing visually. Root cause: `entity.components.set(emitter)` performs an in-place update when a component of that type already occupies the slot, and RealityKit preserves entity-side "has-fired" state even when the component struct is freshly constructed.

### Option D: Remove-before-set

Call `entity.components.remove(ParticleEmitterComponent.self)` immediately before `entity.components.set(emitter)` at every trigger site.

**Found insufficient (visual verification never obtained — confirmed via diagnostic prints only)**: Implemented in issue #9. Diagnostic checkpoint logging confirmed that `components.remove()` followed by `components.set()` ran correctly for 164+ generations (checkpoints P1–P5 all produced expected output; `isEmitting=true` read back after set, `entity.parent` non-nil). However, these prints only proved the Swift execution path ran — they did not prove RealityKit rendered a new particle burst. The user still only saw the first burst visually. The root cause is that **all Options B, C, and D reuse the same pooled `Entity`** across generations. RealityKit retains internal particle-system VFX state at the entity level that survives component removal and replacement. Clearing the component struct is insufficient because the entity object itself carries the stale state.

### Option E: Destroy-and-recreate per burst (adopted)

For each burst event, allocate a **fresh `Entity`**, attach a freshly configured `ParticleEmitterComponent`, parent it to the scene container, and schedule its removal via a `Task` after the burst lifetime elapses. A newly constructed entity has no prior VFX history.

**Adopted in Issue #12**: This is the correct fix because it eliminates entity-level state entirely. The pooled-entity model (`birthParticleEntities`, `deathParticleEntities`, `pulseEntity`) is removed. Each generation spawns 0–20 birth entities and 0–20 death entities, each self-removing after their lifetime (`birthEmitDuration + lifeSpan + 0.1s`). A concurrency cap of 40 active burst entities (birth + death combined) prevents runaway accumulation. Pulse follows the same pattern with no cap (tap-triggered, low frequency).

```swift
// spawnBurst(at:isBirth:) — called per position per generation
guard let container = containerEntity,
      activeBurstEntityCount < Self.maxActiveBurstEntities else { return }

let themeColors = isBirth ? engine.theme.newborn : engine.theme.dying
var emitter = Self.makeParticleEmitterComponent(isBirth: isBirth, themeColors: themeColors)
emitter.isEmitting = true
emitter.burstCount = isBirth ? 12 : 8

let entity = Entity()
entity.position = position
entity.components.set(emitter)
container.addChild(entity)
activeBurstEntityCount += 1

Task { @MainActor in
    try? await Task.sleep(nanoseconds: isBirth ? 1_200_000_000 : 1_400_000_000)
    entity.removeFromParent()
    activeBurstEntityCount -= 1
}
```

---

## Decision

Use Option E: destroy-and-recreate per burst. The pool infrastructure (`birthParticleEntities`, `deathParticleEntities`, `setupParticleEmitters(in:)`, `setupPulseEntity(in:)`, `updateParticleEmitterColors()`) is deleted. `triggerParticles()` and `triggerPulse()` spawn fresh entities on each call.

Duration values (`birthEmitDuration`, `deathEmitDuration`, `pulseEmitDuration`) remain as static constants. `burstCount` continues to be set by the caller at spawn time. All calibrated particle parameters (size, acceleration, spread angle) are preserved in the `makeParticleEmitterComponent()` and `makePulseEmitterComponent()` helpers.

---

## Consequences

- Each burst spawns one or more fresh entities; no entity is reused across generations.
- Entity count is bounded by the 40-entity cap plus pulse entities (which are low-frequency and uncapped).
- Theme colors are captured at spawn time from `engine.theme`; entities that are already live keep their birth-time colors through their lifetime. This is acceptable.
- `updateParticleEmitterColors()` is deleted — there is no pool to iterate.
- The `makeParticleEmitterComponent()` helper remains the single source of truth for emitter configuration. All calibrated values are preserved.
- Future contributors must use the destroy-and-recreate pattern for any `.once` particle emitter. Reintroducing a pool will cause the same silent-after-first-use bug.

---

## Spread Angle Companion Change

As part of Issue #5, birth and death `spreadingAngle` were reduced from `.pi` / `.pi * 2/3` to `.pi / 6` for all emitter types. With the original 1.5–2.0 m/s² acceleration and 0.7–1.0s lifespans, the original angles produced 30–40cm lateral spread from a 1.5cm cell boundary — cross-grid spray rather than cell-localized sparkle. `.pi / 6` (30°) gives ~10cm lateral spread for birth and ~27cm for death. If death particles appear too columnar, `.pi / 4` (45°) is the suggested widening.

## Size and Acceleration Calibration (Issue #7)

Prior emitter configuration (size 20mm, acceleration 1.5–2.0 m/s²) was calibrated when the original problem was *invisibility* (3mm particles) — those large values were deliberately chosen for visibility. After the spread angle fix they produced an explosion that obscured the grid. Issue #7 replaced them with cell-proportional values:

- `mainEmitter.size`: 6mm (birth) / 5mm (death) — visible at 1.5m (~11/9px) without obscuring cubes
- `emitterShapeSize`: 8mm — half cell diameter; particles spawn inside cell boundary
- `acceleration`: 0.12 m/s² (birth up) / 0.06 m/s² (death down) — `d = 0.5×a×t²` gives ≤ 2 cell widths travel
- `burstCount` at trigger: 12 (birth) / 8 (death) — proportional to corrected particle size
