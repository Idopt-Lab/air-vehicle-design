# SandCL2

Level-2 stability & control static toolbox (`classdef SandCL2`, `methods (Static)` only). Called as
`SandCL2.method(...)`; never instantiated and not in the inheritance chain.

**It holds no statics.** The one L2 quantity, `x_cg`, is computed by
`StabControlBase.compute_weighted_cg`, because L2 and L3 both use it. See `src/base/StabControlBase.md`.

**L2 is the CG term only.** See `StabControlBase.md` and `SandCModelL2`'s header for why every other
Ch. 16 quantity is L3 only.
