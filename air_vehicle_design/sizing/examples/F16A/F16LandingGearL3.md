# F16LandingGearL3

F-16A Block 10/15 Level-3 landing-gear student class (`classdef F16LandingGearL3 < handle`,
**F-16-only, no abstract Base/Model tier** — same rationale as `F16LandingGearL2`, see that class's
companion doc). `< handle` added 2026-08-03 for the same reason as `F16LandingGearL2` — see that
class's companion doc.

---

## 1. Role

Identical equations to `F16LandingGearL2` (Raymer 6th ed. Ch.11 Table 11.1 + the 90/10 gear load
split): tire sizing depends only on `W_TO` and the gear-load split, neither of which changes with
geometry fidelity. This class REUSES `F16LandingGearL2`'s `Static` low-level methods
(`tire_diameter`, `tire_width`, `lookup_tire_sizing_coeffs`) directly rather than duplicating the
Table 11.1 switch-case.

## 2. Inputs (4) + 1 injected object

Identical shape to `F16LandingGearL2.md` §2, read from `f16a_L3.json` `.subsystems.landing_gear`
instead of `f16a_L2.json`'s block of the same name (same values: `'Jet fighter/trainer'`, 90/10,
0.80).

**Derived-property shape (2026-08-03 correction, see `F16LandingGearL2.md` §1 for the full
rationale):** `W_main_total`, `W_nose_total`, `W_w_main`, `W_w_nose`, `tire_diameter_main`,
`tire_width_main`, `tire_diameter_nose`, and `tire_width_nose` are `properties (Dependent)` on this
class too (not methods). `bay_volume` stays a plain method (deliberately errors).

## 3. Judgment call: why a separate class exists at all

Today, `F16LandingGearL2` and `F16LandingGearL3`'s equations are **identical** — tire sizing needs
only `W_TO` (via the injected weights object) and the gear-load split, and `F16LandingGearL3` neither
injects geometry nor reads any L3-specific geometry quantity, because `bay_volume()` (the one method
that would eventually need a fuselage envelope) errors regardless of geometry tier. The two classes
are kept separate only to match the subplan's Files-to-Create table (which lists both) and the
JSON's parallel `f16a_L2.json`/`f16a_L3.json` `.subsystems.landing_gear` blocks and per-level
companion docs — **flagged explicitly as a judgment call**: if item 11 (gear bay volume) is ever
resolved with an L2-vs-L3 fidelity distinction of its own (e.g. L3 placing the bay against
`GeomL3`'s frame-integrated fuselage rather than L2's envelope ellipse, mirroring how
`SubsystemsL3.fuselage_raw_volume` refines `SubsystemsL2`'s), that is where the two classes would
first genuinely diverge.

## 4. Gear bay volume — NOT IMPLEMENTED (documented citation gap, item 11)

`bay_volume()` always errors with `F16LandingGearL3:bayVolumeNotAvailable` — its OWN error
identifier (not `F16LandingGearL2`'s), so a test/caller can tell which class's gap fired. Same
citation-gap record as `F16LandingGearL2.md` §4.

## 5. Constructor

`F16LandingGearL3(json_path, weights)` — both REQUIRED, no silent default.
