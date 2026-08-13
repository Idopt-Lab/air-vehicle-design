# SubsystemsBase

Tier-1 abstract enforcer (`classdef (Abstract) SubsystemsBase < handle`) for every subsystems
discipline class. It declares the two sizing-loop-facing methods and one fidelity-independent
utility. No equations, no coefficients — those live in the `SubsystemsL1`/`L2`/`L3` static toolboxes.

---

## 1. Inheritance

```
SubsystemsBase → SubsystemsModelLN (abstract) → F16SubsystemsLN (concrete)
```

Each `SubsystemsModelLN` enforcer inherits `SubsystemsBase` **directly**, not `SubsystemsModelL(N-1)`.

The `SubsystemsL1`/`SubsystemsL2`/`SubsystemsL3` static toolboxes hold the equations and are **not**
in this chain — concrete classes delegate to them.

`F16LandingGearL2`/`F16LandingGearL3` are **not** part of this chain at all — no abstract Base/Model
tier exists for landing gear (not every airframe has conventional landing gear), per the original
step-9 subsystems design.

## 2. Abstract contract

**Properties** (added 2026-08-03 — previously independently duplicated per fidelity level across
`SubsystemsModelL1/L2/L3`; see this file's own `.m` header note for why `avionics_weight`/
`avionics_volume` are deliberately NOT included here):

| Property | Meaning | L1 answer |
|---|---|---|
| `avionics_weight_fraction` | fraction of `W_empty` [Raymer Table 11.6] | same value/citation as L2/L3 |
| `avionics_density` | avionics packing density, lb/ft³ | L1's own Raymer-range-average (~37.5); L2/L3 use Nicolai's flat 45 |
| `fuel_density` | fuel density for `obj.fuel_type`, lb/ft³ [Nicolai Table 8.6] | same value/citation as L2/L3 |
| `fuselage_raw_volume` | raw geometric fuselage-internal volume, ft³ [Raymer Eq. 7.14 at L2/L3] | **honestly 0** — no fuselage geometry exists at L1 |
| `fuel_volume` | total available (usable) fuel volume, ft³ = `fuselage_usable_fuel_volume + wing_fuel_volume` at L2/L3 | **honestly 0** — no fuel-bay geometry exists at L1 |

**Methods**:

| Method | Returns | Signature note |
|---|---|---|
| `internal_volume(obj, W_empty)` | total usable internal volume estimate, ft³ | declared at L1's widest signature (mirrors `GeometryBase.get_S_wet(obj, W_TO)`); L2/L3 concretes implement the zero-extra-arg form `internal_volume(obj)`, reading an injected weights collaborator live instead. This is a documented, deliberate arity asymmetry — MATLAB does not enforce matching arity between an abstract declaration and its override — **not** a repeat of the legacy accidental 2-arg-vs-3-arg signature drift (a legacy bug to avoid), which was undocumented. |
| `fuel_volume_check(obj, required_weight_lb)` | struct: `available_vol_ft3`, `required_vol_ft3`, `sufficient` (logical) | same asymmetry: L1 callers pass `required_weight_lb` explicitly; L2/L3 read it live from an injected `fuel_weight_source` (a `WeightsBase` object), never a hardcoded literal. |
| `fuel_volume_from_weight(obj, fuel_weight_lb)` | ft³ | the definitional weight→volume conversion specialized to the fuel path (`weight_to_volume(fuel_weight_lb, obj.fuel_density)`). Same signature at EVERY level — no widest-signature asymmetry needed, since every tier already takes an explicit weight argument for this one. NO packaging factor applied (that only applies to the geometric `fuselage_usable_fuel_volume`, a different quantity). |

**Avionics volume must be summed.** Every `internal_volume()` override at every level must actually
add its avionics-volume term into the returned total — the legacy code (`temp_Casey`) computed it and
silently dropped it (Legacy Bugs to Avoid item 1). Landing-gear bay volume is deliberately **not**
auto-summed even at L2/L3, because item 11's citation gap means that term always errors; auto-summing
it would make every `internal_volume()` call fail. See `F16SubsystemsL2.md`/`F16SubsystemsL3.md`'s
"Landing-gear bay volume" note.

**Why `avionics_weight`/`avionics_volume` are NOT lifted here even though "avionics volume" is the
same concept at every level:** MATLAB requires any member declared on a shared abstract ancestor to
be ONE kind (property XOR method) across every concrete descendant. L1 has no injected weights
object, so it must take `W_empty` as an explicit argument — only a method can do that. L2/L3 have all
the state they need and correctly implement the same-named members as `Dependent` PROPERTIES instead
(CLAUDE.md "Optimization-ready property design"; enforced by
`TestSubsystemsL2.testF16SubsystemsL2DerivedPropertiesAreReadOnly`, which requires assigning to
`avionics_volume` to fail with `MATLAB:class:noSetMethod` — a set-attempt on a plain method would fail
with a *different* error, so forcing these onto Base would silently break that guarantee). Each
`SubsystemsModelLN` therefore still declares `avionics_weight`/`avionics_volume` independently, at
whichever kind that tier actually needs.

## 3. Concrete utilities

| Method | Returns |
|---|---|
| `weight_to_volume(W_lb, density_lb_per_ft3)` | `W_lb / density_lb_per_ft3`, ft³ — the shared, definitional weight→volume identity used by every fuel-type / avionics / battery density path at every fidelity level. The citation belongs to whichever density value the caller supplies, not to this identity. |

## 4. Conventions

**Fuel-volume sufficiency, precisely** (per Casey, the original step-9 subsystems design):
`fuel_volume_check` must sum fuselage-internal **and** wing-internal volume, never just one, must
support multiple jet-fuel types each with their own cited density, and must have a parallel
battery-electric (energy-density) path rather than a special case bolted onto the liquid-fuel path.

**No Brandt ground truth exists for fuel or avionics volume** — `VnV/BrandtF16A/GroundTruth/*.json`
only has component *weights*, never volumes, for these terms. `examples/F16A/sanity_checks/subsystems_brandt_comparison.m`
carries these as `NOT MODELED` gap rows, not an agreement check.

## 5. To-dos

| Item | Guard |
|---|---|
| Battery volumetric energy density — no citable lb/ft³ or kWh/ft³ source found anywhere in-repo (only gravimetric specific energy is cited); `SubsystemsL2.battery_volume`/`SubsystemsL3.battery_volume` always `error()` | `TestSubsystemsL2.testTODO_BatteryVolumetricEnergyDensityNotInRepo` |
| Landing-gear bay-volume packaging (tire+strut stowage) — no textbook formula found anywhere in-repo; `F16LandingGearL2.bay_volume`/`F16LandingGearL3.bay_volume` always `error()` | `TestF16LandingGearL2.testTODO_GearBayVolumePackagingNotInRepo` |
