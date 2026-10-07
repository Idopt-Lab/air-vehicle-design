# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Scope of this folder

`Homeworks/IHW1/Iteration Methods/` compares iteration methods for the IHW1 takeoff-gross-weight (W_TO) sizing loop of the TTPA (Test Twin Propeller Aircraft).

| File | Method |
| --- | --- |
| `FixedPoint.m` | W_{k+1} = g(W_k) |
| `Aitken_accel.m` | Fixed-point iteration plus pure Aitken Δ² applied to the sequence. The base iterates are not changed. |
| `Broyden.m` | Broyden update with B_0 = −1. In 1-D this is the secant method, and the first step is a fixed-point step. |
| `Newton.m` | Newton on r(W) = g(W) − W. r′ is a central finite difference with h = 1e-4·W. |
| `compare_iteration_methods.m` | Runs all four and compares their iterate, residual, cost and error histories. |

Each method script comes from `../TtpaSizing.m` (the IHW1 reference solution). It keeps the template layout: header, discipline loading, `obj`/`opts`, a local `missionAnalysis` function. Each script also has local `eval_g` and `record_iter` functions. These two functions are the same in all four files, so each script stays self-contained. If you change the equations in one copy, change all four copies and `residual` in the comparison script.

The rules in the repo-root `CLAUDE.md` are for `air_vehicle_design/sizing/`. This folder does not use that framework (no `run_all_tests`, no tier pattern, no `src/` path). Work only in this folder. Do not modify the parent `IHW1/` files.

## Running

There is no build step and there are no tests. From MATLAB:

```matlab
FixedPoint                   % or Aitken_accel, Broyden, Newton
compare_iteration_methods    % runs all four, prints summary, saves output/iteration_methods_comparison.png
```

From a shell: `matlab -batch "cd('<this folder>'); compare_iteration_methods"`. MATLAB R2025b is at `/c/Program Files/MATLAB/R2025b/bin/matlab`.

Each script finds `IHW1/` from its own location (`fileparts(fileparts(mfilename('fullpath')))`) and calls `addpath` on it. The current folder does not change. Each script starts with `clear`, so it deletes the variables of its caller. `compare_iteration_methods` calls each script through `run` inside a local function (`run_method`). It then reads the variables with `eval('iter_hist')` and similar calls: a direct reference to a variable that only the script creates is not resolved in a function. Do not name that variable `hist` in a function, because `hist` is a built-in function.

## What the scripts use from `../`

A change in a parent file changes the result of every script.

- `Ttpa_requirements.json` — requirements and mission profile (`'std_mission'`).
- `TtpaAero`, `TtpaGeom`, `TtpaProp`, `TtpaWeights`, `MissionProfileReader`. They are packed in `obj` as fields `aero`, `prop`, `wts`, `geom`, `miss`.
- `run_mission(W_TO, obj)` — eight segments. It returns fuel per segment, weights and weight fractions.

## The equation

```
W_f/W_TO = 1.06 * sum(fuel_burned) / W_TO      % 1.06 = trapped/unusable fuel
W_e      = 0.911 * W_TO^0.947                   % TtpaWeights.OEW
g(W_TO)  = W_payload_fixed / (1 - W_f/W_TO - W_e/W_TO),  W_payload_fixed = 1200 lbf
r(W_TO)  = g(W_TO) - W_TO
```

All segment fractions in `run_mission.m` are independent of W, so W_f/W_TO is a constant and only the OEW term is nonlinear. g′ ≈ −0.137 at the root (the observed fixed-point error ratio). Thus fixed-point iteration converges linearly and oscillates.

## Common settings and outputs

- W_0 = 5000 lbf, `tol = 0.1` lbf, `max_iter = 25` in every script.
- Stopping rule: |W_{k+1} − W_k| < tol. The script returns the newest iterate. For Aitken, the test applies to successive accelerated values, and the script returns the last accelerated value. A loop that reaches `max_iter` without convergence shows a `warning`.
  - `../TtpaSizing.m` returns the old guess. Thus it differs from `FixedPoint.m` by less than tol (5353.90 vs 5353.88 lbs).
- `missionAnalysis` keeps the reference signature and adds a 9th output, `iter_hist`. This struct has one value per iteration in each of these fields: `k`, `W`, `g`, `r`, `dW`, `n_eval` (cumulative `run_mission` calls). It also has `W_final` and `converged`. Each method adds its own fields:
  - Newton: `drdW`
  - Broyden: `B`
  - Aitken: `k_acc`, `W_acc`, `r_acc`, `n_eval_acc`, `n_eval_diag`
- Aitken evaluates r(A_k) only for the residual history. These calls are counted in `n_eval_diag`, not in `n_eval`.
- `results_table` keeps the 8 reference columns and adds `Residual` and `N_eval`. Aitken also adds `W_acc` and `Residual_acc`.

## Results (as verified 2026-10-06)

W_ref = 5353.878085 lbs. W_ref comes from a Newton solve to round-off in the comparison script.

| Method | Iterations | `run_mission` calls | Observed order |
| --- | --- | --- | --- |
| Fixed point | 6 | 6 | 1.0 |
| Aitken | 4 | 4 (+3 diagnostic) | ≈1, with a much smaller rate constant |
| Broyden | 4 | 4 | 1.38 (asymptotic order 1.618) |
| Newton | 3 | 9 | 2.0 |

Pure Aitken on a linearly convergent sequence is still linear. Only the rate constant becomes smaller. To get quadratic convergence, use Steffensen's method: restart from A_k.
