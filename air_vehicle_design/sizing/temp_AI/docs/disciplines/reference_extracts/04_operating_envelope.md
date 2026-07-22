# Chapter 4 — Aircraft Operating Envelope

**Source:** Nicolai & Carichner, *Fundamentals of Aircraft and Airship Design, Vol. I* (AIAA, 2010), Chapter 4 "Aircraft Operating Envelope," printed pp. 101–121.

---

## §4.1 Flight Envelope

### Fig 4.1 — Aircraft flight envelope (altitude vs Mach)
*[Nicolai & Carichner, Fig. 4.1, p. 102]* — The altitude–Mach envelope is bounded by:
stall/buffet (left), maximum engine thrust (top and upper-right → absolute ceiling), maximum
dynamic pressure `q` (lower-right structural limit), and aerodynamic-heating/propulsion limits.
Diagram (see Figs 4.2, 4.3 for the quantitative boundaries).

---

## §4.2 Minimum Dynamic Pressure (stall/buffet — left boundary)

Left boundary set by stall (sudden flow separation, loss of lift) and buffet (turbulence
shaking the airframe; precedes stall, worse at higher speed). Lower wing loading, maneuver
flaps, and careful tail location move the boundary to lower speed.

### Fig 4.2 — Typical variation of maximum usable C_L with Mach — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.2, p. 103]* — LE sweep = 0–26°, LE flap deflection = 0°.
Max usable C_L ≈ C_Lmax at low speed, dropping to ½–⅓ in the transonic region *(read from plot)*:

| Mach | Max usable C_L |
|---|---|
| 0.0 | ~1.27 |
| 0.2 | ~1.22 |
| 0.4 | ~1.15 |
| 0.6 | ~1.05 |
| 0.7 | ~0.95 |
| 0.8 | ~0.70 |
| 0.9 | ~0.52 |
| 1.0 | ~0.45 |
| 1.1 | ~0.52 |

---

## §4.3 Maximum Thrust Limit (top / upper-right boundary)

Boundary where thrust available = thrust required. **Absolute ceiling** = max altitude reachable
(depends on weight & external stores). **Operational ceiling** = altitude where rate of climb = 100 ft/min.

---

## §4.4 Maximum Dynamic Pressure (structural — right boundary)

Structural limit (flutter, inlet static pressure). Current aircraft designed for `q_max ≈ 1800 psf`.
- **Eq (4.1)** — dynamic pressure: `q = ½·ρ∞·V∞² = (γ/2)·P∞·M∞²` (γ = 1.4 for air)  *[Nicolai & Carichner, Eq. (4.1), p. 104]*
- **Eq (4.2)** — isentropic total (stagnation) pressure: `P0∞ = P∞·[ 1 + ((γ−1)/2)·M∞² ]^(γ/(γ−1))`  *[Nicolai & Carichner, Eq. (4.2), p. 105]*
  (Inlet decelerates flow to M ≈ 0.4 at compressor face; static pressure there can be many × ambient.)

### Fig 4.3 — Trajectory limits of dynamic pressure and aerodynamic heating — **DATA GRAPH**
*[Nicolai & Carichner, Fig. 4.3, p. 105]* — Altitude (1000 ft) vs Mach (0–4). Solid = constant-q
lines (1000, 1500, 3000, 5000 psf); dashed = constant equilibrium-wall-temperature lines
(θw = 250, 500, 750°F; laminar, α=0, X=1 ft, ε=0.8). Constant-q altitude increases with Mach
*(read from plot)*:

| Mach | q=1000 psf | q=1500 psf | q=3000 psf | q=5000 psf |
|---|---|---|---|---|
| 2.0 | ~38k ft | ~32k ft | ~25k ft | ~18k ft |
| 3.0 | ~54k ft | ~48k ft | ~43k ft | ~37k ft |
| 4.0 | ~64k ft | ~60k ft | ~52k ft | ~48k ft |

### Table 4.1 — Inlet Static Pressures for Different Dynamic Pressure Conditions
*[Nicolai & Carichner, Table 4.1, p. 106]* (P∞ from Appendix A; `Pc` = static pressure at the
compressor face, where M = 0.4)

| q (psf) | Altitude (ft) | Mach | P∞ (psf) | P0∞ (psf) | Pc (psf) |
|---|---|---|---|---|---|
| 1700 | 25,000 | 1.75 | 786.3 | 4,180 | 3,360 |
| 5000 | 25,000 | 3.0 | 786.3 | 28,900 | 19,300 |

An inlet designed for the q=1700 psf Pc would be blown apart by the q=5000 psf static pressure.

---

## §4.5 Aerodynamic Heating

Significant at M ≥ 2 (KE → thermal energy, convected to the aircraft). Aluminum alloys degrade
above ~250°F; critical regions are stagnation points and lower surfaces.

### §4.5.1 Stagnation-point heating (nose / swept wing LE)
- **Eq (4.3)** — convective heating rate (Btu/ft²·s):
  `q̇_conv = 15·(ρ∞/R0)^0.5·(V∞/1000)³·(cos Δ)^1.5`  *[Nicolai & Carichner, Eq. (4.3), p. 106]*
  - ρ∞ = density (slug/ft³), V∞ = velocity (ft/s), R0 = nose/LE radius (ft), Δ = LE sweep (0 for body nose).
- Heat balance: `q̇_conv = q̇_radiated`, giving
- **Eq (4.4a)** — equilibrium wall temperature (°R): `θw = [ q̇_conv/(ε·v_SB) ]^(1/4)`  *[Nicolai & Carichner, Eq. (4.4a), p. 106]*
  - ε = emissivity (~0.8); v_SB = Stefan–Boltzmann constant = 0.481×10⁻¹² Btu/(ft²·s·°R⁴).

### §4.5.2 Lower-surface heating
- **Eq (4.5)** — local surface heat transfer: `q̇_surf = 3.21×10⁻⁴·C_f·ρ·V∞³`  *[Nicolai & Carichner, Eq. (4.5), p. 108]*
  - C_f = local laminar skin-friction coefficient at x ft from the LE (normally x = 1.0 ft).
- **Eq (4.4b):** `θw = [ q̇_surf/(ε·v_SB) ]^(1/4)`  *[Nicolai & Carichner, Eq. (4.4b), p. 108]*

<!-- APPEND-HERE -->