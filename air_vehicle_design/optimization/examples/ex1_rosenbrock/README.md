# Optimization Example 1: Rosenbrock Function

This example introduces gradient-based optimization and surrogate-model-based optimization using the Rosenbrock function as a benchmark problem. It is a self-contained, four-script sequence intended to be run in order (scripts `a` through `d`).

## The Rosenbrock Function

The 2D Rosenbrock function is defined as:

```
f(x1, x2) = (1 - x1)^2 + 100*(x2 - x1^2)^2
```

It is a classic optimization test problem because its global minimum lies inside a long, narrow, curved (banana-shaped) valley. The minimum is at **x* = (1, 1)** with **f(x*) = 0**, but finding it is non-trivial because the gradient along the valley floor is very small while the gradient across it is large.

## Script Sequence

Run the scripts in alphabetical order. Each builds on the previous.

### `a_plotting_rosenbrock_function.m` — Visualize the landscape

Plots the Rosenbrock function as both a 3D surface and a 2D contour map over the domain x1 ∈ [-2, 2], x2 ∈ [-1, 3]. Marks the true minimum at (1, 1). Run this first to build intuition for why the problem is challenging.

### `b_fmincon_unconstrained.m` — Gradient-based optimization

Minimizes the Rosenbrock function directly using MATLAB's `fmincon` (interior-point algorithm) starting from x0 = (-1.2, 1.0). Records the full iteration history and plots the optimizer's path on top of the contour map, showing how the solver navigates the narrow valley to converge on the true minimum.

Key settings: box bounds lb = (-2, -1), ub = (2, 3); no nonlinear constraints.

### `c_surrogate_model.m` — Build a response surface (surrogate model)

Demonstrates the surrogate modeling workflow:

1. **Design of Experiments**: generates 100 Latin Hypercube Sampling (LHS) points spread across the design space (75 training / 25 test split).
2. **Function evaluations**: evaluates the true Rosenbrock function at each DoE point.
3. **Model fitting**: fits and compares four polynomial response surfaces — quadratic, cubic, quartic, and a problem-informed quadratic using the feature transformation t = x2 - x1². The transformed model leverages knowledge that the Rosenbrock valley aligns with the parabola x2 = x1², achieving a much better fit than a generic polynomial of the same degree.
4. **Validation**: evaluates all models on the held-out test set (R², RMSE, MAE, max error).
5. **Save**: saves the best surrogate (`mdl_t2`) to `rosenbrock_surrogate.mat`.

### `d_use_surrogate_for_optimization.m` — Optimize using the surrogate

Loads the saved surrogate and runs `fmincon` against it instead of the true function. Because the surrogate is a cheap-to-evaluate polynomial, this represents the pattern used in engineering design when the true objective is expensive (e.g., a CFD solver or structural FEA). Plots the surrogate surface and reports how close the surrogate-optimal point is to the true minimum at (1, 1).

## Files

| File | Purpose |
|---|---|
| `rosenbrock_function.m` | The objective function — called by all scripts |
| `rosenbrock_surrogate.mat` | Saved surrogate model produced by script `c` |
| `a_plotting_rosenbrock_function.m` | Visualization |
| `b_fmincon_unconstrained.m` | Direct gradient-based optimization |
| `c_surrogate_model.m` | DoE + response surface fitting + model comparison |
| `d_use_surrogate_for_optimization.m` | Surrogate-based optimization |

## How to Run

Open MATLAB, navigate to this folder, and run in sequence:

```matlab
run('a_plotting_rosenbrock_function.m')
run('b_fmincon_unconstrained.m')
run('c_surrogate_model.m')
run('d_use_surrogate_for_optimization.m')
```

Script `d` depends on `rosenbrock_surrogate.mat` produced by script `c`. All other scripts are independent.

## Learning Objectives

- Understand why the Rosenbrock function is a hard benchmark (narrow curved valley, ill-conditioned Hessian near the optimum)
- Apply `fmincon` with box constraints and track convergence history
- Perform a full surrogate modeling workflow: DoE → evaluation → fitting → validation → optimization
- Recognize when feature engineering (the `t = x2 - x1²` transform) outperforms brute-force polynomial expansion
- Understand the surrogate optimization pattern used when evaluating the true objective is expensive
