# MBSE Example 2: F-16A Aircraft Design with Requirements Tracing

This example demonstrates Model-Based Systems Engineering (MBSE) workflows in MATLAB using the MathWorks Systems Requirements Toolbox and System Composer. It uses the F-16A Block 50 as a case study to show how requirements, source models, and tests can be linked and traced within a MATLAB project.

## What This Example Covers

- Writing and managing formal requirements in a `.slreqx` file using Simulink Requirements
- Linking requirements to implementation artifacts (source models and functions)
- Verifying requirements against tests using MATLAB-based test classes
- Organizing a project with a standard `src / tests / requirements` layout

## Project Structure

```
ex2/
├── AircraftDesign.prj       # MATLAB project file — open this first
├── requirements/
│   └── example.slreqx       # Formal requirements set (open in Requirements Editor)
├── src/
│   ├── f16a_mission.m       # F-16A mission analysis script
│   ├── f16a_mission.mat     # Saved mission data
│   ├── f100_engine_model.m  # F100 engine thrust/SFC model
│   └── lift_function.m      # Lift coefficient lookup function
└── tests/
    ├── F16ATests.m          # MATLAB test class: F-16A mission tests
    ├── LiftTest.m           # MATLAB test class: lift model unit tests
    └── LiftTest~m.slmx      # Requirements linkage overlay for LiftTest
```

## How to Run

1. Open MATLAB and open `ex2_mbse.prj` to set up the path.
2. Open `requirements/example.slreqx` in the Requirements Editor to browse the requirement set.
3. Run all tests from the command line:
   ```matlab
   results = runtests('tests');
   table(results)
   ```
4. To see requirement-test traceability, use the Requirements Editor's **Verify** panel or call:
   ```matlab
   slreq.reqSet('requirements/example.slreqx').runTests()
   ```

## Key Concepts Illustrated

| Concept | Where to Look |
|---|---|
| Requirement authoring | `requirements/example.slreqx` |
| Linking tests to requirements | `tests/LiftTest~m.slmx` |
| Programmatic requirement access | `slreq.Link`, `slreq.reqSet` docs |
| Engine/aerodynamics modeling | `src/f100_engine_model.m`, `src/lift_function.m` |

## References

- [Verify requirements with MATLAB tests (R2024b)](https://www.mathworks.com/help/releases/R2024b/slrequirements/ug/verify-requirements-with-matlab-tests.html)
- [Link to test cases from requirements](https://www.mathworks.com/help/slrequirements/gs/link-to-test-cases-from-requirements.html)
- [slreq.reqSet.runTests](https://www.mathworks.com/help/releases/R2024b/slrequirements/ref/slreq.reqset.runtests.html)
- [Small UAV System Composer example](https://www.mathworks.com/help/systemcomposer/ug/smalluav.html)
