# TailL2

Level-2 tail-sizing static toolbox (`classdef TailL2`, `methods (Static)` only). Called as
`TailL2.method(...)`; never instantiated and not in any inheritance chain.

**Not implemented.** L2 has no equations. `size` throws `TailL2:notImplemented`.

---

## 1. Methods

| Method | Arguments | Outputs | Citation |
|---|---|---|---|
| `size` | one argument, not used | none; throws `TailL2:notImplemented` | none |

## 2. To-dos

| To-do | Status |
|---|---|
| Supply cited L2 tail-sizing equations | open |
| `size` takes an argument. Toolbox statics must not take a design object | open |
