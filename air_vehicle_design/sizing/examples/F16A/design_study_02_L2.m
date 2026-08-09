function [result, objs] = design_study_02_L2(W_TO_guess, T_SL_guess)
%DESIGN_STUDY_02_L2  F-16A Level-2 sizing study.
%
%   result = design_study_02_L2(W_TO_guess, T_SL_guess) builds fresh
%   F16AeroL2/F16PropL2/F16WeightsL2/F16GeomL2 discipline objects, the L2
%   mission analysis (MissionAnalysisL2.from_requirements over the CAP profile),
%   and the F-16's L2 constraint set (ConstraintAnalysis.from_requirements
%   with the F-16 map F16ConstraintSet.constraint_map(), sharing this study's
%   own aero/prop objects rather than a separate internal copy), then runs
%   SizingLoopL2 to convergence. Unlike
%   L1, S_ref is a fixed JSON input here, never solved for -- only T_SL
%   updates each iteration, alongside re-sizing the tail and control
%   surfaces via the separate, dependency-injected tail/ctrl objects built
%   below (see TAIL SIZING further down this header).
%
%   [result, objs] = design_study_02_L2(...) additionally returns the
%   handle objects (objs.aero/prop/wts/geom/miss/con) in their
%   final, converged state -- e.g. for post-processing/reporting scripts
%   (F16A_Level2_SizingReport.m) that need to call further methods on them
%   (weight/aero breakdowns) after the loop has converged. Optional and
%   additive: existing single-output callers (tests/sizing/
%   TestF16SizingStudies.m) are unaffected.
%
%   TAIL SIZING (2026-08-03 absorption into Geometry REVERTED, 2026-08-05):
%   tail sizing and control-surface sizing are separate, dependency-injected
%   objects again -- F16TailL1() (Raymer 7th ed. Table 6.4 volume-
%   coefficient method, 0.315/0.063, tail arm 0.475*L_fus; hardcoded, no
%   arguments) and ControlSurfaceSizer(...). SizingLoopL2's run() body calls
%   tail.size(S_ref, b_wing, cbar_wing, L_fus) every iteration (reading
%   those four scalars live off geom) and writes the result into
%   geom.S_ht/S_vt. F16TailL1 is the SAME object shared, unmodified, across
%   both this study and design_study_03_L3.m -- see SizingLoopL2.m's header
%   for why only an L1-shaped tail object is ever wired into production.
%   F16TailL2 (Nicolai & Carichner F-16-specific coefficients) is NOT used
%   here -- it was only ever a SECONDARY, non-mutating comparison alternate.
%
%   result = design_study_02_L2() uses default initial guesses of 30,000
%   lbf / 20,000 lbf -- both deliberately off Brandt's 31,377 lb / 23,770
%   lbf targets, so a passing convergence check demonstrates the loop
%   actually converges rather than starting at the answer.
%
%   CONTROL-SURFACE FRACTIONS (user-selected 2026-07-27, since Raymer's own
%   source data is a chart/footnoted table, not a single per-category
%   number). Passed into the injected ControlSurfaceSizer's constructor:
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
         % TODO (7/31/2026): These should not be hardcoded.
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL2(f16a_spec_path(2), prop);
    aero = F16AeroL2(geom, f16a_spec_path(2));
    wts  = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, f16a_requirements_path(), "cap");
    tail = F16TailL1();
    ctrl = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);

    con = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
        F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_BRANDT);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl);
    result = loop.run(W_TO_guess, T_SL_guess);

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con);
end
