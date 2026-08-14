function [result, objs] = f16_sizing_brandt_L2(W_TO_guess, T_SL_guess)
%F16_SIZING_BRANDT_L2  L2 sizing loop over the Brandt validation stack.
%
%   result = f16_sizing_brandt_L2(W_TO_guess, T_SL_guess) builds the
%   Brandt-discipline validation stack (f16_brandt_stack: Brandt
%   disciplines through the FRAMEWORK mission/constraint analyses -- see
%   that builder's header) and runs SizingLoopL2 on it: two-state
%   (W_TO, T_SL) fixed point with tail resizing and a per-iteration
%   constraint re-solve.
%
%   [result, objs] = f16_sizing_brandt_L2(...) additionally returns the
%   stack struct (objs.aero/prop/wts/geom/miss/con/tail), mutated in place
%   to the converged state, for post-processing (e.g. sanity_checks/
%   sizing_brandt_comparison.m).
%
%   Default guesses 28,000 / 20,000 lbf are deliberately off Brandt's
%   31,377 / 23,770 lbf targets, so convergence is demonstrated rather than
%   assumed (same rationale as f16_sizing_L2.m).
%
%   TAIL SIZING IS NOT BRANDT-CONSISTENT (corrected 2026-08-14).
%   F16TailL1's volume-coefficient method predicts S_ht ~ 48.4 /
%   S_vt ~ 25.7 ft^2 at the Brandt planform (c_HT = 0.315, c_VT = 0.063,
%   arm 0.475*L_fus = 22.09 ft) -- less than HALF the actual F-16A's
%   108 / 60 ft^2 [Brandt Main!C18/H18]. That is a tail-sizing-DISCIPLINE
%   gap (the statistical volume-coefficient method vs the real, oversized
%   F-16 stabilator), not a loop bug; it lightens OEW and pulls this
%   rung's W_TO down. Interpreted in sizing_brandt_comparison.m and in
%   TestSizingVsBrandt.m's header.
%
%   GEOMETRY MUTATION IS LIVE. Each iteration writes geom.S_ref = W0/(W/S)*
%   through BrandtMissionGeomAdapter's setter, which re-analyzes
%   BrandtGeometry and its registered dependents (aero, weight), so S_ref
%   converges to W0/(W/S)* -- near, but not exactly, Brandt's 300 ft^2
%   (the small W_TO offset inherited from the mission -- see below --
%   scales it).
%
%   EXPECTED RESULT -- same BY-DESIGN mission offset as
%   f16_sizing_brandt_L1.m: the framework L2 mission burns ~6,532 lb vs the
%   Miss-tab 6,000.43 (+8.9%, see sanity_checks/mission_brandt_comparison.m),
%   so W_TO converges ~1.5-2% ABOVE Brandt's 31,377 lbf; the design point
%   should reproduce W/S ~ 104.59 psf, T/W ~ 0.7576 [Brandt Size&Opt sheet;
%   VnV/BrandtF16A/GroundTruth/cell-map.md Size!W_S / Size!T_W].
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 28000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    objs = f16_brandt_stack();
    loop = SizingLoopL2(objs.aero, objs.prop, objs.wts, objs.geom, ...
        objs.miss, objs.con, objs.tail);
    result = loop.run(W_TO_guess, T_SL_guess);
end
