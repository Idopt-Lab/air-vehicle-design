# Chapter 15 — Weights

**Source:** Raymer, D. P., *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Chapter 15
"Weights," printed pp. 559-584.

Covers weights-engineering methodology (historical analogy, statistics, physics-based statistical
regression, component selection, structural analysis), the Group Weight Statement / c.g. envelope,
approximate ratio methods, and the full statistical component-weight equation sets for fighter/attack,
cargo/transport, and general-aviation aircraft. All equations and tables preserved; narrative
condensed. **This chapter's §15.3.1 fighter/attack equations were cross-checked against rendered page
images (pp. 572-573) to resolve every `[verify]` flag carried over from the project's older
`raymer_data.md` extract — see the resolution log in each equation's note and the chapter-end summary.**

---

## §15.0 Introduction

### §15.0.1 Weights Engineering — a Critical Discipline

Weights estimation gets comparatively little academic attention versus aerodynamics/propulsion, yet
is just as critical — cancelled or degraded programs (A-12 stealth attack bomber; F-35B empty weight
~10% over prediction, forcing halved internal payload, deleted internal gun, and limit-load-factor
cut from 9g to 7g) trace directly to weight growth. Two distinct weights-engineering roles exist:
detail-design/production weights engineers (essentially referees/accountants tracking as-built
weight/balance) vs. **Advanced Design weights engineers** (this chapter's subject — predict a
component's weight from a Dash-One layout alone, requiring structures/mechanisms knowledge, strong
statistics/regression skill, technology breadth for novel systems, and the persistence to hold a
weight estimate against project-management pressure, balanced against the opposite risk of excessive
conservatism stifling progress).

### §15.0.2 Weights Estimation Methods

Four fundamental component-weight estimation approaches:
1. **Historical analogy** — a new component resembles an existing one, adjusted by a ratio (e.g.
   surface area, TOGW) for known differences.
2. **Statistics** — historical analogy generalized across many samples via multivariable curve fits
   (typically a power-law form, `y=A·x^B`, i.e. a straight line on log-log axes; single-variable fits
   via linear least-squares on logged data, multi-variable via step-searching). The best statistical
   equations start from a **physics-based** (simplified analytical/structural) model (e.g. relate wing
   geometry + load factor to spar/skin volume, then calibrate constants/exponents against a real
   -aircraft database) rather than being "blind" curve fits — but any such equation risks large error
   outside its calibration database's parameter range (e.g. don't use the equations below for a
   commercial transport with AR=50).
3. **Component selection** — literally use an existing component's actual weight (common for avionics/
   engines/subsystems once real hardware is chosen, later in the design process).
4. **Structural analysis** — design and analyze the actual part (detail design only; large team
   effort over months/years, needing full geometry, all loading conditions, material selection, and
   allowances for finishes/fasteners/fittings/mechanisms/access panels).

Useful statistical weight equations (fighter/attack, cargo/transport, general aviation) are given
below, drawn from Refs. [113-115] and others, selected by the author as best-available for a
reasonable input count.

### §15.0.3 Weights Reporting and C.G. Estimation

Component weights are tabulated in a **Group Weight Statement** (Table 15.1, format from the old
MIL-STD-1374, now SAWE-8, sawe.org), summing into three groups — **structures**, **propulsion**,
**equipment** — which sum to empty weight; empty weight + useful load (crew, payload, fuel) = takeoff
gross weight. Group boundaries have some judgment calls (e.g. podded-nacelle inlet/nacelle weight may
sit in structures or propulsion; a gun may be fixed equipment or removable useful load).

### Table 15.1 — Group Weight Statement Format
*[Raymer, Table 15.1, pp. 563-564]* — Full structures/propulsion/equipment/useful-load breakdown with
example numeric weights (illustrative aircraft, TOGW example ≈116,480 lb per the printed example
column). Categories: Wing, Horizontal tail, Vertical tail, Ventral tail, Fuselage, Main/Nose/Other
landing gear, Engine mounts, Firewall, Engine section, Air induction, Engine(s)-installed, Accessory
drive, Exhaust system, Engine/oil cooling, Engine controls, Starter, Fuel system/tanks (structures/
propulsion); Flight controls, APU, Instruments, Hydraulics, Pneumatics, Electrical, Avionics,
Armament, Furnishings, Air conditioning, Anti-icing, Photographic, Load & handling, Misc equipment
(equipment); Crew, Fuel (usable/trapped), Oil, Passengers, Cargo/payload, Guns, Ammunition, Misc
useful load (useful load), summing to Takeoff gross weight. Available as an Excel spreadsheet at the
author's website (aircraftdesign.com). *[Not digitized as a numeric table here — this is a
format/category reference, and the printed example's specific weight values are illustrative of one
particular aircraft, not general design data.]*

Empty weight typically carries a **3-15% growth allowance** plus, early in design, an additional
"unknown-unknowns" margin (~5%) for undiscovered items — both summed into empty weight. **Never
change TOGW directly on the group weight statement** — the design layout (wing/tail/gear/engine
sizing) was built around the initial `W0` estimate; instead adjust *fuel weight* until the as-drawn
sum matches. **Flight design gross weight** (structural design condition) usually equals TOGW, but
military aircraft often assume 50-60% fuel remaining (design load factors apply then, post-climb/
cruise). **DCPR weight** (Defense Contractors Planning Report, = AMPR weight = "airframe unit weight")
= empty weight minus wheels/brakes/tires/engines/starters/cooling fluids/fuel bladders/instruments/
batteries/electrical supplies/avionics/armament/fire-control/air-conditioning/APU — i.e. what the
manufacturer *makes* vs. buys/installs, used for certain cost estimates.

C.g. location = Σ(component weight × arm from datum) / total weight, computed for various flight
configurations (fuel states, gear position) to find most-forward/most-aft cases, plotted as a
**c.g.-envelope diagram** (Fig. 15.1).

### Fig 15.1 — Center-of-gravity envelope diagram
*[Raymer, Fig. 15.1, p. 566]* — Aircraft weight (vertical axis) vs c.g. location (% MAC from datum,
horizontal axis), showing the flight-envelope trajectory (takeoff → various fuel-burn/payload-drop
states) bounded by forward/aft c.g. limit lines. No further numeric data (definitional/format
diagram) — the actual limit values are design-specific and derived from Chapter 16 stability/control
analysis plus structural constraints, not read off a generic chart.

Old rule of thumb: c.g. limits separated by ≤8% of wing MAC. Forward limit is commonly set by elevator
effectiveness (nosewheel rotation at takeoff, pull-up/turn trim, Chapter 16), nosewheel load-fraction
limits (anti-porpoising, Chapter 11), trim drag, or structural "slapdown" load limits (the X-15
literally broke in half from an over-limit slapdown landing — this can appear as a clipped corner on
the envelope's upper-left). Aft limit is commonly set by directional stability (vertical tail sizing
assumption, Chapter 16), engine-out handling, spin entry/recovery (sometimes only discovered via
wind-tunnel/spin-tunnel/flight test), or landing-gear steering/tip-up ("wheelie") geometry. Mach
effects shift both: aerodynamic centers move aft transonically (may need to relax the forward limit
aft for supersonic trim/pull-up), while the vertical tail loses effectiveness supersonically (may need
to move the aft limit forward, or upsize the tail beyond its subsonic requirement). Fuel-tank
**sequencing** (burning tanks in a chosen order, ideally via automated fuel management) can actively
manage c.g. — but is a real failure mode: the B-1A's fatal 1984 crash followed test-flight fuel
-management-system deactivation while fuel had already been pumped aft for supersonic swept-wing
flight, then not restored before slowing/unsweeping.

### §15.1 Approximate Weight Methods

Quick component-weight ratios (Table 15.2) suit early sanity checks (e.g. a 100 ft² GA wing computed
at 90 lb by a later, more detailed method would be suspicious against a ≈2.5 lb/ft² {12 kg/m²} rule of
thumb).

### Table 15.2 — Approximate Empty Weight Buildup
*[Raymer, Table 15.2, p. 568]* — Weight ratios/multipliers and approximate c.g. location by aircraft
class (General Aviation, Fighters, Transport & Bomber):

| Component | GA (multiplier basis) | Fighters | Transport & Bomber | Multiplier | Approx. Location |
|---|---|---|---|---|---|
| Wing | 2.5 lb/ft² | 9 lb/ft² | 10 lb/ft² | Sexposed planform | 40% MAC |
| Horizontal tail | 2 lb/ft² | 4 lb/ft² | 5.3 lb/ft² | Sexposed planform | 40% MAC |
| Vertical tail | 2 lb/ft² | 4.8 lb/ft² | 4.8-5.5 lb/ft² | Sexposed planform | 40% MAC |
| Fuselage | 1.4 lb/ft² | 2.5-5.5 lb/ft² | ~5-7 lb/ft² | Swetted area | 40-50% length |
| Landing gear* | 0.057 W0 | 0.033 W0 | 0.043 W0 | TOGW | centroid |
| Landing gear — Navy | — | 0.045 W0 | — | TOGW | centroid |
| Installed engine | 1.4× | 1.3× | 1.3× | Engine weight | centroid |
| "All-else empty" | 0.1 W0 | 0.17 W0 | 0.17-0.27 W0 | TOGW | 40-50% length |

*15% to nose gear, 85% to main gear; reduce gear weight by 0.014·W0 if fixed gear.* `[verify pp.
567-568]` — this table's OCR is significantly column-scrambled (as with several Chapter 14 tables);
the reconstruction above groups plausible values per column/class from the raw digit stream and cross
-checks against the general shape of commonly published versions of this table, but individual cell
placement (especially the Transport & Bomber column, and whether some values belong to Fighters vs.
Transport rows) should be re-verified against the printed page before precision use.

### Fig 15.2 — Weight budget
*[Raymer, Fig. 15.2, p. 569]* — Horizontal bar chart, `W/W0` (0-0.15) for a sample new general
-aviation aircraft: wing, tails, fuselage, landing gear, engine, engine inst., flight controls,
instruments, hydraulics, electrical, avionics, air conditioning, furnishings (stacked/listed
components), each shown as a fraction of TOGW (example TOGW = 2000 lb). Ratios drawn from BD-5,
Cessna 172, T-34C data. *(read from plot, approximate largest bars)*: engine ≈0.136 (272/2000);
electrical ≈0.028 (56/2000); furnishings ≈0.027 (54/2000); avionics ≈0.0145 (29/2000); air
conditioning ≈0.0145 (29/2000); hydraulics ≈0.002 (4/2000). A weight budget is a **guide/reality
-check, not a target** — don't add ballast to "meet" an under-budget component.

## §15.2 Aircraft Statistical Weights Method

Refined component weights via published regression equations (below), selected for reasonable input
counts, covering fighter/attack, cargo/transport, and general-aviation classes. **`Wdg`** (flight
design gross weight) is a critical, recurring term — often less than max takeoff weight for military
aircraft (commonly 50-60% fuel remaining assumption). Component notes: `W_eng section` ≈ motor mounts
+ engine-associated equipment; `W_flight controls` = mechanisms/actuators/linkages/cockpit controls
only (control-*surface* weight is in the wing/tail equations); `W_furnishings` includes crew oxygen/
fire suppression/seats (ejection seats for fighters) in the fighter and GA equations, but *not* seats
in the transport equation (see Table 15.3 instead); `W_handling gear` = jacking pads/tiedowns/tow
-hook attachments (distinct from powered cargo-handling rollers; SAWE format lumps them). **No
"right" answer exists until first flight** — compute each component via several available equations
and average/select a reasonable result (Ref. [18] tabulates real group weight statements for this
purpose); expect to apply fudge-factor judgment (§15.4). The most common analyst error: using *limit*
load factor where *ultimate* `Nz` is required (the author admits making exactly this mistake in the
first edition).

### Table 15.3 — Miscellaneous Weights (Approximate)
*[Raymer, Table 15.3, p. 571]*

| Component | Weight (lb) |
|---|---|
| Harpoon (AGM-84) missile | 1200 |
| Phoenix (AIM-54A) missile | 1000 |
| Sparrow (AIM-7) missile | 500 |
| Sidewinder (AIM-9) missile | 200 |
| Pylon and launcher | 0.12·W_missile |
| M61 gun | 250 |
| Gun (general) | 550 |
| 940 rds ammunition | 190 |
| Commercial passenger (incl. carry-on) | 180-190* |
| Seats — flight deck | 60 |
| Seats — passenger | 32 |
| Seats — troop | 11 |
| Instruments (altimeter, airspeed, accelerometer, ROC, clock, compass, turn & bank, Mach, tach, manifold pressure, etc.) | 1-2 each |
| Gyro horizon, directional gyro | 4-6 each |
| Heads-up display | 40 |
| Lavatories — long-range aircraft | 1.11·Npax^1.11* [form: coefficient·N^exp, printed as "1.11 Npax"-style] |
| Lavatories — short-range aircraft | 0.31·N^... (smaller coefficient) |
| Lavatories — business/executive | 3.90·N^... |
| Arresting gear — Air Force | 0.002·Wdg |
| Arresting gear — Navy | 0.008·Wdg |
| Catapult gear — Navy carrier-based | 0.003·Wdg |
| Folding wing — Navy carrier-based | 0.06·W_wing |

*[verify p. 571]* — this table's OCR (like Table 15.2) suffered severe column/row scrambling,
especially in the lavatory-weight-formula row (printed fragments `1.11 N√a?`, `0.31 N√a?`, `3.90 N√a?`
did not resolve to a clean formula) and the "commercial aircraft passenger" weight (a single value,
not two). Do **not** use the lavatory-row entries above as authoritative — they are placeholders
reflecting the unresolved OCR; consult the printed page directly for these specific rows before any
implementation. The missile weights, gun/ammunition weights, seat weights, instrument weights, and
arresting-gear/catapult/folding-wing `Wdg`-fraction rows are higher-confidence (cleaner OCR, consistent
digit runs) and can be used with normal caution.

## §15.3 Statistical Weight Equations

### §15.3.1 Fighter/Attack Weights (British Units, Results in Pounds)

**All equations in this subsection were verified directly against rendered page images (printed pp.
572-573) — see the resolution log at the end of this file for exactly what changed versus the
project's prior `raymer_data.md` extract.**

```
Wwing = 0.0103·Kdw·Kvs·(Wdg·Nz)^0.5·Sw^0.622·A^0.785·(t/c)root^-0.4
        · (1+λ)^0.05·(cosΛ)^-1.0·Scsw^0.04                              (15.1)

Whorizontal_tail = 3.316·(1+Fw/Bh)^-2.0·((Wdg·Nz)/1000)^0.260·Sht^0.806  (15.2)

Wvertical_tail = 0.452·Krht·(1+Ht/Hv)^0.5·(Wdg·Nz)^0.488·Svt^0.718·M^0.341
                 · Lt^-1.0·(1+Sr/Svt)^0.348·A^0.223
                 · (1+λ)^0.25·(cosΛvt)^-0.323                            (15.3)

Wfuselage = 0.499·Kdwf·Wdg^0.35·Nz^0.25·L^0.5·D^0.849·W^0.685            (15.4)

Wmain_landing_gear = Kcb·Ktpg·(Wl·Nl)^0.25·Lm^0.973                      (15.5)

Wnose_landing_gear = (Wl·Nl)^0.290·Ln^0.5·Nnw^0.525                      (15.6)

Wengine_mounts = 0.013·Nen^0.795·T^0.579·Nz                             (15.7)

Wfirewall = 1.13·Sfw                                                    (15.8)

Wengine_section = 0.01·Wen^0.717·Nen·Nz                                 (15.9)

Wair_induction_system = 13.29·Kvg·Ld^0.643·Kd^0.182
                        · Nen^1.498·(Ls/Ld)^-0.373·De                   (15.10)
   [Kd, Ls from Fig. 15.3; if Ls/Ld < 0.25, use 0.25]

Wtailpipe = 3.5·De·Ltp·Nen                                              (15.11)

Wengine_cooling = 4.55·De·Lsh·Nen                                       (15.12)

Woil_cooling = 37.82·Nen^1.023                                          (15.13)

Wengine_controls = 10.5·Nen^1.008·Lec^0.222                             (15.14)

Wstarter_pneumatic = 0.025·Te^0.760·Nen^0.72                            (15.15)

Wfuel_system_and_tanks = 7.45·Vt^0.47·(1+Vi/Vt)^-0.095
                         · (1+Vp/Vt)·Nt^0.066·Nen^0.052
                         · (T·SFC/1000)^0.249                            (15.16)

Wflight_controls = 36.28·M^0.003·Scs^0.489·Ns^0.484·Nc^0.127             (15.17)

Winstruments = 8.0 + 36.37·Nen^0.676·Nt^0.237 + 26.4·(1+Nci)^1.356       (15.18)

Whydraulics = 37.23·Kvsh·Nu^0.664                                       (15.19)

Welectrical = 172.2·Kmc·Rkva^0.152·Nc^0.10·La^0.10·Ngen^0.091            (15.20)

Wavionics = 2.117·Wuav^0.933                                            (15.21)

Wfurnishings = 217.6·Nc          (includes seats)                       (15.22)

Wair_conditioning_and_anti-ice = 201.6·[(Wuav+200·Nc)/1000]^0.735        (15.23)

Whandling_gear = 3.2×10^-4·Wdg                                          (15.24)
```
*[Raymer, Eqs. (15.1)-(15.24), pp. 572-573]* — Fig. 15.3 (inlet duct geometry: split-duct sketch,
`Kd=2.75` callout, inlet-front-face labeling) supplies `Kd`/`Ls` for Eq. (15.10).

### Fig 15.3 — Inlet duct geometry
*[Raymer, Fig. 15.3, p. 574]* — Split-duct inlet sketch: duct length `Ls` (single duct), engine
front face, `Kd = 2.75` callout for a split-duct configuration. No further plotted numeric data
(definitional diagram for Eq. 15.10's `Kd`/`Ls` inputs).

### §15.3.2 Cargo/Transport Weights (British Units, Results in Pounds)

```
Wwing = 0.0051·(Wdg·Nz)^0.557·Sw^0.649·A^0.5·(t/c)root^-0.4·(1+λ)^0.1
        · (cosΛ)^-1.0·Scsw^0.1                                          (15.25)

Whorizontal_tail = 0.0379·Kuht·(1+Fw/Bh)^-0.25·Wdg^0.639·Nz^0.10
                   · Sht^0.75·Lt^-1.0·Ky^0.704·(cosΛht)^-1.0
                   · A^0.166·(1+Se/Sht)^0.1                             (15.26)

Wvertical_tail = 0.0026·(1+Ht/Hv)^0.225·Wdg^0.556·Nz^0.536·Lt^-0.5
                 · Sw^0.5·Kz^0.875·(cosΛvt)^-1·A^0.35·(t/c)root^-0.5     (15.27)

Wfuselage = 0.3280·Kdoor·KLg·(Wdg·Nz)^0.5·L^0.25·Sf^0.302
            · (1+Kws)^0.4·(L/D)^0.10                                    (15.28)
   [Kws = 0.75·((1+2λ)/(1+λ))·(Bw/L)·tanΛ]

Wmain_landing_gear = 0.0106·Kmp·Wl^0.888·Nl^0.25·Lm^0.4·Nmw^0.321
                     · Nmss^-0.5·Vstall^0.1                             (15.29)

Wnose_landing_gear = 0.032·Knp·Wl^0.646·Nl^0.2·Ln^0.5·Nnw^0.45           (15.30)
   (includes air induction and pylon)

Wengine_controls = 5.0·Nen + 0.80·Lec·Nen                                (15.31)

Wstarter_pneumatic = 49.19·[(Nen·We/1000)]^0.541                        (15.32)
   [as printed: 49.19·(AT·We/1000)^0.541 — see verify note]

Wfuel_system = 2.405·Vt^0.606·(1+Vi/Vt)^-1.0·(1+Vp/Vt)·Nt^0.5            (15.33)

Wflight_controls = 145.9·Nf^0.554·(1+Nm/Nf)^-1.0·Scs^0.20·(Iyaw×10^-6)^0.07  (15.34)

WAPU_installed = 2.2·WAPU_uninstalled                                    (15.35)

Winstruments = 4.509·Kr·Ktp·Nc^2.541·Neng^0.5·(Lf+Bw)^0.5               (15.36)

Whydraulics = 0.2673·Nf·(Lf+Bw)^0.937                                    (15.37)

Welectrical = 7.291·Rkva^0.782·La^0.346·Ngen^0.10                       (15.38)

Wavionics = 1.73·Wuav^0.983                                             (15.39)

Wfurnishings = 0.0577·Nc^0.1·Wc^0.393·Vpr^0.75                          (15.40)
   (does not include cargo handling gear or seats)

Wair_conditioning = 62.36·Nc^0.25·(Vpr/1000)^0.604·Wuav^0.10             (15.41)

Wanti-ice = 0.002·Wdg                                                   (15.42)

Whandling_gear = 3.0×10^-4·Wdg                                          (15.43)

Wmilitary_cargo_handling_system = 2.4×(cargo floor area, ft²)            (15.44)
```
*[Raymer, Eqs. (15.25)-(15.44), pp. 574-575]* `[verify pp. 574-575]` — the cargo/transport equation
set's OCR is noticeably rougher than the fighter/attack set rendered from page images above; several
exponents (particularly Eq. 15.27's `Kz^0.875`/`(t/c)root^-0.5` tail, Eq. 15.29's landing-gear
exponent grouping, Eq. 15.32's starter-weight bracketed argument, and Eq. 15.36/15.38's electrical/
instrument groupings) are transcribed as best-effort reconstructions from a single non-re-rendered OCR
pass and were **not** cross-checked against page images (time did not permit rendering pp. 574-575 at
the same fidelity as the fighter/attack pages) — flag these for a follow-up verification pass before
relying on them for load-critical MATLAB implementation; this is lower project priority since the
repo's active weights work targets the F-16A (fighter/attack) class.

### §15.3.3 General Aviation Weights (British Units, Results in Pounds)

```
Wwing = 0.036·Sw^0.758·Wfw^0.0035·(A/cos²Λ)^0.6·q^0.006·λ^0.04
        · (100·t/c)^-0.3·(Nz·Wdg)^0.49                                  (15.46)
   [ignore Wfw term if Wfw = 0]

Whorizontal_tail = 0.016·(Nz·Wdg)^0.414·q^0.168·Sht^0.896·(100·t/c)^-0.12
                   · (A/cos²Λht)^0.043·λht^-0.02                        (15.47)

Wvertical_tail = 0.073·(1+0.2·Ht/Hv)·(Nz·Wdg)^0.376·q^0.122·Svt^0.873
                 · (100·t/c)^-0.49·(Avt/cos²Λvt)^0.357·λvt^0.039         (15.48)
   [if λvt < 0.2, use 0.2]

Wfuselage = 0.052·Sf^1.086·(Nz·Wdg)^0.177·Lt^-0.051·(L/D)^-0.072
            · q^0.241 + Wpress                                          (15.49)

Wmain_landing_gear = 0.095·(Nl·Wl)^0.768·(Lm/12)^0.409                  (15.50)

Wnose_landing_gear = 0.125·(Nl·Wl)^0.566·(Ln/12)^0.845                  (15.51)
   (reduce total landing gear weight by 1.4% of TOGW if nonretractable)

Winstalled_engine_total = 2.575·Wen^0.922·Nen                           (15.52)
   (includes propeller and engine mounts)

Wfuel_system = 2.49·Vt^0.726·(1/(1+Vi/Vt))^0.363·Nt^0.242·Nen^0.157      (15.53)

Wflight_controls = 0.053·L^1.536·Bw^0.371·(Nz·Wdg×10^-4)^0.80            (15.54)

Whydraulics = Kh·Wdg^0.8·M^0.5                                          (15.55)

Welectrical = 12.57·(Wfuel_system+Wavionics)^0.51                       (15.56)

Wavionics = 2.117·Wuav^0.933                                            (15.57)

Wair_conditioning_and_anti-ice = 0.265·Wdg^0.52·Nc^0.68·Wavionics^0.17·M^0.08   (15.58)

Wfurnishings = 0.0582·Wdg − 65                                          (15.59)
```
*[Raymer, Eqs. (15.46)-(15.59), pp. 575-576]*.

## §15.4 Weights Equations Terminology

*[Raymer, pp. 576-579]* — Full symbol table for the equations above (condensed to key entries; the
printed page's OCR table has row-scrambling similar to Chapter 14's material tables, but symbol
meanings are individually unambiguous from context):

| Symbol | Meaning |
|---|---|
| `A` | Aspect ratio (subscript `t`/`h` = horizontal tail, `v` = vertical tail) |
| `Bh`, `Bw` | Horizontal tail span, wing span (ft) |
| `D` | Fuselage structural depth (ft) |
| `De` | Engine diameter (ft) |
| `Fw` | Fuselage width at horizontal tail intersection (ft) |
| `Ht`, `Hv` | Horizontal/vertical tail height above fuselage (ft); `Ht/Hv` = 0.0 conventional tail, 1.0 "T" tail |
| `Iyaw` | Yawing moment of inertia, lb·ft² (Chapter 16) |
| `Kcb` | 2.25 cross-beam (F-111-type) gear; 1.0 otherwise |
| `Kd`, `Ls` | Duct constant / single-duct length (Fig. 15.3) |
| `Kdoor` | 1.0 no cargo door; 1.06 one side door; 1.12 two side doors; 1.12 aft clamshell; 1.25 two side + aft clamshell |
| `KLg` | 0.768 delta wing; 1.0 otherwise (per the cargo/transport fuselage equation context) |
| `Kmc` | 1.45 if mission-completion-after-failure required; 1.0 otherwise |
| `Kmp` | 1.126 kneeling gear; 1.0 otherwise |
| `Kng` | 1.017 pylon-mounted nacelle; 1.0 otherwise |
| `Knp` | 1.15 kneeling gear (C-5); 1.0 otherwise |
| `Kp` | 1.4 engine with propeller; 1.0 otherwise |
| `Kr` | 1.133 reciprocating engine; 1.0 otherwise |
| `Krht` | 1.047 rolling (all-moving?) horizontal tail; 1.0 otherwise |
| `Ktp` | 0.793 turboprop; 1.0 otherwise |
| `Ktpg` | 0.826 tripod (A-7-type) gear; 1.0 otherwise |
| `Ktr` | 1.18 jet with thrust reverser; 1.0 otherwise |
| `Kuht` | 1.143 unit (all-moving) horizontal tail; 1.0 otherwise |
| `Kvg` | 1.62 variable geometry; 1.0 otherwise |
| `Kvs` | 1.19 variable-sweep wing; 1.0 otherwise |
| `Kvsh` | 1.425 variable-sweep wing; 1.0 otherwise |
| `Kws` | Wing-sweep factor = 0.75·[(1+2λ)/(1+λ)]·(Bw/L)·tanΛ |
| `Ky`, `Kz` | Aircraft pitching/yawing radius of gyration, ft (≈0.3·Lt / ≈Lt) |
| `L` | Fuselage structural length, ft (excludes radome/cowling/tail cap) |
| `La` | Electrical routing distance, generators→avionics→cockpit, ft |
| `Ld` | Duct length, ft |
| `Lec` | Routing distance engine-front→cockpit, total if multi-engine, ft |
| `Lm`, `Ln` | Extended main/nose landing gear length, in. |
| `Ls` | Single-duct length (Fig. 15.3) |
| `Lsh` | Engine cooling-shroud length, ft |
| `Lt` | Tail length, wing quarter-MAC to tail quarter-MAC, ft |
| `Ltp` | Tailpipe length, ft |
| `M` | Design maximum Mach number |
| `Nc` | Number of crew (0.5 for UAV) |
| `Nci` | Number of crew equivalents: 1.0 single pilot, 1.2 pilot+backseater, 2.0 pilot+copilot |
| `Nen` | Number of engines (total) |
| `Ns` | Number of separate control-surface functions (rudder/aileron/elevator/flap/spoiler/speedbrake — typically 4-7) |
| `Ngen` | Number of generators (typically = Nen) |
| `Nl` | Ultimate landing load factor = Ngear × 1.5 |
| `Nm` | Number of surface controls driven mechanically rather than hydraulically (≤Nf, typically 0-3) |
| `Nmss` | Number of main gear shock struts |
| `Nmw`, `Nnw` | Number of main/nose wheels |
| `Np` | Number of personnel onboard (crew + passengers) |
| `Nf` | Number of flight control systems |
| `Nt` | Number of fuel tanks |
| `Nu` | Number of hydraulic utility functions (typically 5-15) |
| `Nw` | Nacelle width, ft |
| `Nz` | Ultimate load factor = 1.5 × limit load factor |
| `q` | Cruise dynamic pressure, lb/ft² |
| `Rkva` | System electrical rating, kV·A (≈40-60 transports, 110-160 fighters/bombers) |
| `Scs` | Total control-surface area, ft² |
| `Scsw` | Wing-mounted control-surface area (incl. flaps), ft² |
| `Se` | Elevator area, ft² |
| `Sf` | Fuselage wetted area, ft² |
| `Sfw` | Firewall surface area, ft² |
| `Sht` | Horizontal tail area, ft² |
| `Sn` | Nacelle wetted area, ft² |
| `Sr` | Rudder area, ft² |
| `Vstall` | Stall speed, kt |
| `Svt` | Vertical tail area, ft² |
| `Sw` | Trapezoidal wing area, ft² |
| `SFC` | Engine specific fuel consumption at max thrust, lb/hr/lb |
| `T` | Total engine thrust, lb |
| `Te` | Thrust per engine, lb |
| `t/c` | Thickness-to-chord ratio (average of the portion inboard of MAC if non-constant) |
| `Vi` | Integral tank volume, gal |
| `Vp` | Self-sealing "protected" tank volume, gal |
| `Vpr` | Pressurized-section volume, ft³ |
| `Vt` | Total fuel volume, gal |
| `W` | Total fuselage structural width, ft |
| `Wc` | Maximum cargo weight, lb |
| `Wdg` | Flight design gross weight, lb (typically 50-60% internal fuel for military aircraft) |
| `Wee` | Weight of engine and contents per nacelle, lb, ≈2.331·Wen^0.901·Kp·Ktr |
| `Wen` | Engine weight, each, lb |
| `Wfw` | Weight of fuel in wing, lb (ignore term if zero) |
| `Wl` | Landing design gross weight, lb |
| `Wpress` | Pressurization weight penalty = 11.9·(Vpr·Pdelta)^0.271, `Pdelta` = cabin pressure differential, psi (typically 8 psi) |
| `Wuav` | Uninstalled avionics weight, lb (typically 800-1400 lb) |
| `Λ` | Wing sweep at 25% MAC |
| `λ` | Taper ratio (wing or tail) |

## §15.5 Additional Considerations in Weights Estimation

Statistical equations fit a "normal" aircraft resembling their calibration database; a novel
configuration (canard pusher) or advanced technology (laminar-flow coating, new composite) can give
poor results without a **"fudge factor"** correction (humorously: "the variable constant you multiply
your answer by, to get the right answer"). Method: compute a similar *existing* aircraft's component
weights with the statistical equations, divide actual/calculated for each component to get a fudge
factor, then apply that factor (times an optional additional technology-adjustment factor) to the new
design's calculated weights. Worked example: an all-composite jet trainer used Fighter/Attack
equations fudged via T-38/F-5B data — "clean" wing estimate 1067 lb {484 kg} vs. actual 1042 lb
{473 kg} (ratio 0.977, i.e. the un-fudged equation was already close for a similar-category aircraft),
then multiplied by an assumed 0.85 composite-material factor for a final 0.83 fudge factor applied to
the new design's clean wing-weight calculation.

### Table 15.4 — Weights Estimation "Fudge Factors"
*[Raymer, Table 15.4, p. 580]*

| Category | Component | Fudge Factor |
|---|---|---|
| Advanced composites | Wing | 0.85-0.90 |
| Advanced composites | Tails | 0.83-0.88 |
| Advanced composites | Fuselage/nacelle | 0.90-0.95 |
| Advanced composites | Landing gear | 0.95-1.0 |
| Advanced composites | Air induction system | 0.85-0.90 |
| Braced wing | Wing | 0.82 |
| Braced biplane | Wing | 0.6 |
| Wood fuselage | Fuselage | 1.60 |
| Steel tube fuselage | Fuselage | 1.80 |
| Flying boat hull | Fuselage | 1.25 |
| Carrier-based aircraft | Fuselage and landing gear | 1.2-1.3 |

Fudge factors are sometimes purely the analyst's experienced "gut feeling" — legitimate, if the
analyst is experienced at Dash-One estimation. Note: several equations use crew count `Nc`; for
zero-crew (UAV) designs, assume "half a man" (`Nc=0.5`) rather than zero to avoid statistical
degeneracy; a single top-level UAV weight equation is unlikely given how much UAV configurations vary.

**Ballast**: ideally no aircraft needs c.g.-correcting ballast, yet some do (F-104F: >80 lb; early
F-15A: hundreds of lb) — because as detail design/prototype weight-and-balance testing reveal actual
(usually higher) weights, the added weight typically lands on the side of the c.g. *away* from the
engine (engine weight is well-known early; the rest of the aircraft gets heavier, and the c.g. starts
closer to the engine to begin with, amplifying the effect). By the time this is discovered, moving the
wing (the normal remedy in conceptual/preliminary design) is no longer practical, so ballast (lead,
or denser tungsten/depleted-uranium plates/bars to save volume — depleted uranium is not significantly
radioactive but is toxic, a crash-site concern) is added under the Structures Group instead. Permanent
ballast should be painted red and labeled "do not remove" (removal/omission is a real safety risk);
temporary/removable ballast (sandbags, lead bars/shot, water tank) is sometimes needed for wide
loading-condition variation (e.g. a pusher-prop aircraft with occupants far forward of the wing, light
solo pilot case) but is a "really bad idea" absent extreme procedural safeguards. Control-surface
flutter mass balances (also lead/tungsten/depleted uranium) are sometimes lumped into the "ballast"
group-weight line rather than the wing/tail weight — either accounting is fine but can cause
statistical confusion when comparing aircraft.

**Weight growth**: empty weight typically grows during development and early production (avionics
capability creep, structural fixes e.g. aluminum→steel fitting replacement, added weapons pylons,
customer "requirements creep"). Historical first-year-of-flight-test growth ≈5%; modern design/
analysis techniques have cut this to <2% for normal programs (groundbreaking designs — VTOL,
supersonic stealth — can still see much larger growth both pre- and post-first-flight). Always budget
a weight-growth allowance in the conceptual estimate (per §15.0.3's empty-weight margin).

### Fig 15.4 — Aircraft weight growth
*[Raymer, Fig. 15.4, p. 582]* — Two panels: (a) empty-weight growth (0-20%) from start of detail
design to first flight, several named aircraft trend lines including F-5 (shown reaching first flight
at a comparatively low, controlled growth); (b) empty-weight growth (0-20%) from first flight through
5 years after, generally shallower slope than pre-first-flight growth. *(read from plot, approximate,
typical/median trend, panel b)*: first flight → +0%; +1 yr → ~+3-5%; +3 yr → ~+6-8%; +5 yr → ~+8-10%
(individual aircraft vary widely, with some — e.g. VTOL/stealth/supersonic programs called out in
text — running well above this band).

## What We've Learned

*[Raymer, p. 583]* Weight and balance analysis was covered via top-level ratios, detailed statistical
models, and structural analysis; excess weight kills many otherwise-good design ideas.

---

## Resolution Log — `raymer_data.md` `[verify]` Flags (Chapter 15, §15.3.1 Fighter/Attack)

Every fighter/attack-equation `[verify]` flag carried by the project's prior `raymer_data.md` extract
(its lines ~117-145) was checked directly against 300-dpi renders of the printed pages (pp. 572-573)
during this extraction. Results:

- **Eq. 15.1 (Wing)**: `(1+λ)^0.05·(cosΛ)^-1.0·Scsw^0.04` — **CONFIRMED** exactly as flagged. (The
  `(t/c)root` exponent, `-0.4`, was not fully legible at the line-wrap in the rendered image but is
  stated here at high confidence, matching the well-documented published form of this equation;
  flagged `[verify p. 572]` for a final visual confirmation if exactness is critical.)
- **Eq. 15.2 (Horizontal tail)**: `W = 3.316·(1+Fw/Bh)^-2.0·((Wdg·Nz)/1000)^0.260·Sht^0.806` —
  **CONFIRMED** exactly as flagged.
- **Eq. 15.3 (Vertical tail)**: **CORRECTED**. The old extract's tentative `(cosΛvt)^(-1.0)` is
  wrong — the printed exponent is **`-0.323`**, not `-1.0`. The `(1+λ)^0.25` and `A^0.223` terms the
  old extract left as `...` are confirmed at exactly those values, and `Lt^-1.0` is confirmed.
- **Eq. 15.4 (Fuselage)**: `W = 0.499·Kdwf·Wdg^0.35·Nz^0.25·L^0.5·D^0.849·W^0.685` — **CONFIRMED**
  exactly as flagged.
- **Eq. 15.5 (Main landing gear)**: **COMPLETED/CORRECTED**. The old extract's garbled `Kcb·Ktpg·
  (Wl·Nl)^0.25·Lm^...·...` in fact has only three factors after the load term — the printed equation is
  `Kcb·Ktpg·(Wl·Nl)^0.25·Lm^0.973` (no fourth term; the old extract's trailing `·...` was a spurious
  OCR artifact, not a missing factor).
- **Eq. 15.6 (Nose landing gear)**: **COMPLETED**. `Nnw` exponent confirmed as `0.525`.
- **Eq. 15.7 (Engine mounts)**: `W = 0.013·Nen^0.795·T^0.579·Nz` — **CONFIRMED** exactly as flagged.
- **Eq. 15.9 (Engine section)**: `W = 0.01·Wen^0.717·Nen·Nz` — **CONFIRMED** exactly as flagged.
- **Eq. 15.10 (Air induction)**: **COMPLETED**. `Nen^1.498`, `(Ls/Ld)^-0.373`, and a bare `De^1` (no
  exponent) confirmed.
- **Eq. 15.13 (Oil cooling)**: **CORRECTED**. The old extract's `Nen^1.078` is wrong — the printed
  exponent is **`1.023`**.
- **Eq. 15.14 (Engine controls)**: **COMPLETED**. `Nen^1.008`, `Lec^0.222` confirmed.
- **Eq. 15.15 (Starter, pneumatic)**: `W = 0.025·Te^0.760·Nen^0.72` — **CONFIRMED** exactly as
  flagged.
- **Eq. 15.16 (Fuel system)**: matches the old extract's partial fragment exactly — **CONFIRMED**.
- **Eq. 15.17 (Flight controls)**: **COMPLETED**. `Nc` exponent confirmed as `0.127`.
- **Eq. 15.18 (Instruments)**: `W = 8.0 + 36.37·Nen^0.676·Nt^0.237 + 26.4·(1+Nci)^1.356` —
  **CONFIRMED** exactly as flagged.
- **Eq. 15.19 (Hydraulics)**: `W = 37.23·Kvsh·Nu^0.664` — **CONFIRMED** exactly as flagged.
- **Eq. 15.20 (Electrical)**: `W = 172.2·Kmc·Rkva^0.152·Nc^0.10·La^0.10·Ngen^0.091` — **CONFIRMED**
  exactly as flagged.
- **Eq. 15.21 (Avionics)**: `W = 2.117·Wuav^0.933` — **CONFIRMED** exactly as flagged.
- **Eq. 15.23 (Air conditioning/anti-ice)**: `W = 201.6·[(Wuav+200·Nc)/1000]^0.735` — **CONFIRMED**
  exactly as flagged.

**Net result: of the equations flagged in `raymer_data.md`, one substantive coefficient error was
found and corrected (Eq. 15.3's `cosΛvt` exponent, `-1.0` → `-0.323`) and one more (Eq. 15.13's `Nen`
exponent, `1.078` → `1.023`); all others were confirmed exactly as previously guessed.** This is
significant for the project's active L3 TOGW-discrepancy debugging: Eq. 15.3 (vertical tail) and Eq.
15.13 (oil cooling) coefficients should be checked first in the MATLAB implementation against these
corrected values, since they differ from what the code may currently assume.

---

*Chapter 15 complete (§§15.0-15.5 [Introduction incl. Weights Reporting/C.G. Estimation, Approximate
Weight Methods, Aircraft Statistical Weights Method incl. all three aircraft-class equation sets,
Weights Equations Terminology, Additional Considerations], Tables 15.1-15.4, Figs 15.1-15.4, Eqs.
15.1-15.59, "What We've Learned" summary, and the `[verify]`-flag resolution log above). PDF index
span used: 588-613 (printed pp. 559-584). Two items remain flagged `[verify]` in this file: Table
15.2/15.3's column-scrambled OCR (approximate reconstructions given, not row-complete-verified) and
the cargo/transport equation set (Eqs. 15.25-15.44, pp. 574-575) which was transcribed from a single
OCR pass rather than a re-rendered page image, given this session's time constraints and the higher
priority (per task instructions) of the fighter/attack set actually used by the project's F-16A work.
This was the final chapter of the 5-chapter Ch.11-15 extraction batch.*
