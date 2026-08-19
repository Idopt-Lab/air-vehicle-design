# Appendix C — Airspeed

**Source:** Raymer, *Aircraft Design: A Conceptual Approach*, 6th ed. (AIAA, 2018), Appendix C
"Airspeed," printed pp. 969–970.

Short appendix defining the four airspeed measures used throughout the book and the
compressible-flow relations that convert between them. One reference photo (F-22), no
plotted-data figures.

---

## Airspeed Definitions

*[Raymer, Appendix C, p. 969]*

- **IAS — indicated airspeed**: read directly from cockpit instrumentation; includes cockpit
  instrument error.
- **CAS — calibrated airspeed**: indicated airspeed corrected for airspeed-instrumentation
  position error.
- **EAS — equivalent airspeed**: calibrated airspeed corrected for compressibility effects.
- **TAS — true airspeed**: equivalent airspeed corrected for the change in atmospheric density
  with altitude.

## Compressible-Flow Airspeed Relations

*[Raymer, Appendix C, p. 969]*

True airspeed from equivalent airspeed and the local-to-sea-level density ratio:

```
TAS = EAS / sqrt(rho / rho_0)
```

Equivalent airspeed from calibrated airspeed, correcting for compressibility. `qc` is the impact
pressure, `P` the local static pressure and `P_0` the sea-level static pressure:

```
EAS = CAS * sqrt(P/P_0) * [ ((qc/P   + 1)^0.286 - 1)
                          / ((qc/P_0 + 1)^0.286 - 1) ]^0.5
```

*(Corrected 2026-08-18 against a 300-dpi render of book p. 969. The earlier extract was
reconstructed from a garbled OCR text layer and had two errors: it dropped the leading
`sqrt(P/P_0)` factor, and it inverted the bracketed ratio, putting the `P_0` term in the numerator.
The corrected form reproduces the book's own worked example below: at 15,000 ft with M = 0.428 it
gives EAS/CAS = 0.9902, and the book prints EAS = 213 kt against CAS = 215 kt, i.e. 0.9907.)*

where the impact pressure `qc` (compressible Rayleigh-Pitot relation) is:

```
qc = P * [(1 + 0.2*M^2)^3.5 - 1]
```

**Mach number:**

```
M = TAS / a
```

where:
- `a` = local speed of sound
- `P_0` = pressure, sea level
- `rho_0` = density, sea level

### Worked example

*[Raymer, Appendix C, p. 969]*

The following are equivalent at 15,000 ft, 30°C day:

| Quantity | Value |
|---|---|
| M | 0.428 |
| TAS | 290 kt |
| CAS | 215 kt |
| EAS | 213 kt |

## Figure

*[Raymer, p. 970]* — Opener photograph: Lockheed Martin F-22 Raptor (U.S. Air Force photo). No
plotted data.

---

*Appendix C complete (definitions, compressible-airspeed relations, one worked example, one
reference photo). Next: Appendix D — Airfoil Data.*
