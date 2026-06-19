# Level-Brandt — Brandt F-16A Reference Implementation

## Purpose

A direct, faithful MATLAB reimplementation of the Brandt F-16A Excel workbook
(`GroundTruth/Brandt-F16-A.xls`).

This is **not** an approximation. Every computed value must reproduce the corresponding
Excel cell to within ±1%. It is the absolute calibration reference for Levels I–III.

## Architecture

- All classes use `methods (Static)` only — no instance state
- No inheritance from `Disciplines/` or `ComputationModels/`
- Each class corresponds to one Excel sheet

## File Map

| MATLAB Class | Excel Sheet | Responsibility |
|-------------|-------------|----------------|
| `LevelBrandt.m` | (orchestrator) | Entry point: `LevelBrandt.runF16A()` |
| `BrandtMain.m` | `Main` | Master parameters: S_ref, AR, sweep, taper, Mcrit, fixed weights |
| `BrandtGeometry.m` | `Geom` | Wing/fuselage/tail geometry, wetted areas, Amax |
| `BrandtWeights.m` | `Wt` | Structural plate-area weights → OEW |
| `BrandtEngine.m` | `Engn(s)` | Thrust lapse, TSFC mil/AB, 1.08× installed correction |
| `BrandtMission.m` | `Miss` | 7-segment mission, quadratic drag polar, CDx, fuel burn |
| `BrandtSizing.m` | `Size&Opt` | TOGW convergence loop, W/S, T/W outputs |

## Dependency Order

```
BrandtMain → BrandtGeometry → BrandtWeights
                            ↘
                              BrandtEngine → BrandtMission → BrandtSizing
```

## Key Brandt Corrections (not in standard textbooks)

1. **Quadratic drag polar:** `CD = CD0 + k1·CL² + k2·CL` (k2 = −0.00630)
2. **Installed TSFC:** uninstalled × 1.08
3. **Mission CDx:** 0.035 takeoff, 0.010 all other legs
4. **Plate-area weights:** wing=6.75 lb/ft², fuselage=5.0, pitch ctrl=6.0, vert surf=6.0
5. **Amax:** whole-aircraft cross-sections H26:H45, not fuselage-only

## Running

```matlab
results = LevelBrandt.runF16A();
```

Prints a validation table: parameter | Brandt value | computed value | % difference.

## Tolerances

All outputs must be within **±1%** of the Brandt XLS. This is enforced by the
integration test in `tests/level_brandt/test_LevelBrandt_integration.m`.

## Related Files

- **Cell map:** `GroundTruth/cell-map.md`
- **Tests:** `tests/`
- **Ground truth XLS:** `GroundTruth/Brandt-F16-A.xls`
