function [result, objs] = design_study_02_L2(W_TO_guess, T_SL_guess)
%DESIGN_STUDY_02_L2  F-16A Level-2 sizing study.
%
%   result = design_study_02_L2(W_TO_guess, T_SL_guess) builds fresh
%   F16AeroL2/F16PropL2/F16WeightsL2/F16GeomL2/F16MissionL2 discipline
%   objects, the F-16's L2 constraint set (F16ConstraintSet.build("L2")),
%   F16TailL1, and a ControlSurfaceSizer wired to the F-16's
%   control-surface fractions (see below), then runs SizingLoopL2 to
%   convergence. Unlike L1, S_ref is a fixed JSON input here, never solved
%   for -- only T_SL updates each iteration, alongside re-sizing the tail
%   and control surfaces.
%
%   [result, objs] = design_study_02_L2(...) additionally returns the
%   handle objects (objs.aero/prop/wts/geom/miss/con/tail/ctrl) in their
%   final, converged state -- e.g. for post-processing/reporting scripts
%   (F16A_Level2_SizingReport.m) that need to call further methods on them
%   (weight/aero breakdowns) after the loop has converged. Optional and
%   additive: existing single-output callers (tests/sizing/
%   TestF16SizingStudies.m, tests/sizing/TestControlSurfaceSizer.m) are
%   unaffected.
%
%   TAIL SIZING (updated 2026-07-28): uses F16TailL1 (Raymer 7th ed. Table
%   6.4 volume-coefficient method, c_HT=0.315/c_VT=0.063, tail arm
%   0.475*L_fus), which supersedes the now-retired F16TailSizingLevel1
%   (0.40/0.07/0.5*L_fus, Raymer 6th ed.) -- SizingLoopL2's run() body still
%   calls tail.size(S_ref, b_wing, cbar_wing, L_fus), the L1 four-scalar
%   convention, so F16TailL1 is a drop-in replacement here (same interface,
%   corrected coefficients). See src/disciplines/tail_sizing/
%   TailSizing_scribe_plan.md Sec. 2 for the discrepancy-resolution record.
%   F16TailL2's Nicolai & Carichner coefficient + real-geometry method is
%   not wired into this study (would need SizingLoopL2's run() body
%   updated for L2's injected-geometry, no-scalar-argument size(obj)
%   convention -- a separate, not-yet-done follow-up).
%
%   result = design_study_02_L2() uses default initial guesses of 30,000
%   lbf / 20,000 lbf -- both deliberately off Brandt's 31,377 lb / 23,770
%   lbf targets, so a passing convergence check demonstrates the loop
%   actually converges rather than starting at the answer.
%
%   CONTROL-SURFACE FRACTIONS (user-selected 2026-07-27, since Raymer's own
%   source data is a chart/footnoted table, not a single per-category
%   number -- see ControlSurfaceSizer.m's header):
%     Aileron:  c_ail_frac=0.20, b_ail_frac=0.40 -- a representative point
%       from Fig. 6.3's historical-guidelines band (chord fraction: midpoint
%       of the text's stated typical 15-25% range; span fraction: the
%       band's typical/lower value at that chord, consistent with a
%       fighter's relatively compact aileron).
%     Elevator: c_elev_frac=0, b_elev_frac=0 -- Table 6.5's Fighter/attack
%       row (Ce/C=0.30) is itself footnoted "Supersonic usually all-moving
%       tail without separate elevator," and F16GeomL2 already models the
%       F-16's horizontal tail as an all-moving stabilator (no separate
%       elevator surface) -- so S_elev=0 here is the physically-correct
%       choice for this airframe, not a placeholder.
%     Rudder:   c_rud_frac=0.30 [Table 6.5, Fighter/attack, Cr/C],
%       b_rud_frac=0.90 [Raymer 6th ed. p.161, "extend to the tip of the
%       tail or to about 90% of the tail span"].
    arguments
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL2(f16a_spec_path(2), prop);
    aero = F16AeroL2(geom, f16a_spec_path(2));
    wts  = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
    miss = F16MissionL2();

    constraints = F16ConstraintSet.build("L2");
    con = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);

    tail = F16TailL1();
    ctrl = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl);
    result = loop.run(W_TO_guess, T_SL_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con, 'tail', tail, 'ctrl', ctrl);
end
