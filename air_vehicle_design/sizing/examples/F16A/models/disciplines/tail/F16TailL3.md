# F16TailL3

F-16A Level-3 (stability-and-control) tail sizing. `classdef F16TailL3 < TailSizingModelL3`.
**DOCUMENTED-TODO STUB** — ships now as a citation-missing failure structure, not real equations. See
`TailL3.md` for the full citation-gap record and the intended future contract.

---

## 1. Constructor

```matlab
t3 = F16TailL3();
```

No arguments. Nothing is deferred-and-omitted here beyond what `TailL3.md` Sec. 3 already documents
as intentionally not-yet-added (CG range, target static margin, target `C_n_beta`, crosswind design
condition, a Tail→aero DI pattern) — none of those exist as inputs anywhere in this framework yet, so
there is nothing to inject or configure at construction time.

## 2. size(obj, varargin)

Always errors, `TailL3:citationNotAvailable`, regardless of how many arguments are passed (accepts
and ignores extra arguments so it fails the same clear way whether called with L1's four-scalar
convention or L2/L3's injected-object convention):

```matlab
t3 = F16TailL3();
t3.size()              % errors: TailL3:citationNotAvailable
t3.size(300, 30, 11, 46.5)   % also errors: TailL3:citationNotAvailable
```

This is a **deliberate, expected failure** — not a bug. Raymer Ch. 16's stability-and-control
tail-sizing equations are not verifiable from anything in this repository (full record: `TailL3.md`
Sec. 1; `VnV/BrandtF16A/todo.md` Finding 3, status RESOLVED-DEFERRED).

## 3. Why this class exists at all

`F16TailL3` is real and constructible so that:

1. `SizingLoopL2`'s `tail (1,1) TailSizingBase` type check is satisfiable by an L3 tail object, should
   a future L3 sizing loop want one.
2. The three-tier structure is complete and uniform across L1/L2/L3, matching every other discipline
   in this framework.
3. Calling into it surfaces a **loud, labeled, expected** error rather than either (a) silently
   returning a plausible-looking fabricated number, or (b) not existing at all and forcing every
   caller to special-case "L3 tail sizing isn't implemented yet."

## 4. To-dos

| Item | Guard |
|---|---|
| Raymer Ch. 16 stability-and-control tail-sizing equations are not verifiable from anything in this repository | `TailL3:citationNotAvailable`, always raised by `size(...)`; a companion deliberately-red test (test-writer's responsibility) should assert this |
