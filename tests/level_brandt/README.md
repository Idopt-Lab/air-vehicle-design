# Level-Brandt Tests

Unit and integration tests for `src/level_brandt/`.

## Structure

One test file per `BrandtXxx` class + one integration test:

```
tests/level_brandt/
  test_BrandtMain.m
  test_BrandtGeometry.m
  test_BrandtWeights.m
  test_BrandtEngine.m
  test_BrandtMission.m
  test_BrandtSizing.m
  test_LevelBrandt_integration.m   ← runs runF16A() end-to-end, asserts all ±1% tolerances
```

## What Each Test Covers

For every `BrandtXxx` module:

1. **Physical bounds** — output is in a physically sensible range
2. **F-16A spot check** — with F-16A inputs, output is within ±1% of the Brandt XLS value
3. **Error handling** — invalid inputs raise the correct MATLAB error ID (`LevelBrandt:invalidInput`)

## Running Tests

```matlab
% From repo root in MATLAB:
runtests('tests/level_brandt')
```

*(Test files to be created by Vasquez under Bishop's review)*
