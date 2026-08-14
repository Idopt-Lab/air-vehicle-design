function [result, objs] = f16_sizing_brandt_L1(W_TO_guess)
%F16_SIZING_BRANDT_L1  L1 sizing loop over the Brandt validation stack.
%
%   result = f16_sizing_brandt_L1(W_TO_guess) builds the Brandt-discipline
%   validation stack (f16_brandt_stack: Brandt disciplines through the
%   FRAMEWORK mission/constraint analyses -- see that builder's header) and
%   runs SizingLoopL1 on it: single-state W_TO fixed point with the design
%   diagram solved once before the loop.
%
%   [result, objs] = f16_sizing_brandt_L1(...) additionally returns the
%   stack struct (objs.aero/prop/wts/geom/miss/con/tail), mutated in place
%   to the converged state, for post-processing (e.g. sanity_checks/
%   sizing_brandt_comparison.m).
%
%   The default guess of 28,000 lbf is deliberately off Brandt's 31,377 lbf
%   target, so a passing convergence check demonstrates the loop converges
%   rather than starting at the answer (same rationale as the framework
%   studies, f16_sizing_L1.m).
%
%   EXPECTED RESULT -- the BY-DESIGN mission offset. The framework L2
%   mission x brandt_14seg over the Brandt disciplines burns ~6,532 lb at
%   W_TO = 31,377, +8.9% vs the Brandt Miss-tab ground truth of 6,000.43 lb
%   (the L2 form generalizes Brandt's accel/climb method -- see
%   sanity_checks/mission_brandt_comparison.m's header for the two causes).
%   Feeding that heavier fuel through the TOGW closure converges W_TO
%   ~1.5-2% ABOVE Brandt's 31,377 lbf. That offset is mission-fidelity
%   by design, NOT a loop bug. The design point itself should reproduce
%   Brandt: W/S ~ 104.59 psf, T/W ~ 0.7576 [Brandt Size&Opt sheet;
%   VnV/BrandtF16A/GroundTruth/cell-map.md Size!W_S / Size!T_W].
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 28000
    end

    objs = f16_brandt_stack();
    loop = SizingLoopL1(objs.aero, objs.prop, objs.wts, objs.geom, ...
        objs.miss, objs.con);
    result = loop.run(W_TO_guess);
end
