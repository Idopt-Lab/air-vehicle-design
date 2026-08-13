function [result, objs] = design_study_02_L2(W_TO_guess, T_SL_guess)
%DESIGN_STUDY_02_L2  F-16A Level-2 sizing study.
%
%   result = design_study_02_L2(W_TO_guess, T_SL_guess) builds fresh
%   F16AeroL2/F16PropL2/F16WeightsL2/F16GeomL2 discipline objects, the L2
%   mission analysis (MissionAnalysisL2.from_requirements over the CAP profile),
%   and the F-16's L2 constraint set (ConstraintAnalysis.from_requirements
%   with the F-16 map F16ConstraintSet.constraint_map(), sharing this study's
%   own aero/prop objects rather than a separate internal copy), then runs
%   SizingLoopL2 to convergence. As of 2026-08-10 BOTH S_ref and T_SL are
%   solved for each iteration, the same as at L1 (S_ref = W_TO/(W/S)_opt) --
%   the JSON .geometry.wing.S_ft2 = 300 ft^2 is only F16GeomL2's starting
%   value, no longer a frozen input. The tail and control surfaces are
%   re-sized each iteration too, via the separate, dependency-injected
%   tail/ctrl objects built below (see TAIL SIZING further down this
%   header), and now genuinely change with S_ref.
%
%   [result, objs] = design_study_02_L2(...) additionally returns the
%   handle objects (objs.aero/prop/wts/geom/miss/con) in their
%   final, converged state -- e.g. for post-processing/reporting scripts
%   (run_sizing_report_L2.m) that need to call further methods on them
%   (weight/aero breakdowns) after the loop has converged. Optional and
%   additive: existing single-output callers (tests/sizing/
%   TestF16SizingStudies.m) are unaffected.
%
%   TAIL SIZING (2026-08-03 absorption into Geometry REVERTED, 2026-08-05):
%   tail sizing and control-surface sizing are separate, dependency-injected
%   objects again -- F16TailL1() (Raymer 7th ed. Table 6.4 volume-
%   coefficient method, 0.315/0.063; hardcoded, no
%   arguments) and ControlSurfaceSizer(...). SizingLoopL2's run() body calls
%   tail.size(S_ref, b_wing, cbar_wing, L_HT, L_VT) every iteration (reading
%   those five scalars live off geom) and writes the result into
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
%   CONTROL-SURFACE FRACTIONS moved 2026-08-10 into f16a_control_surfaces(),
%   now the single place the F-16A's control-surface wiring lives -- see that
%   function for every fraction's provenance and its accuracy against the T.O.
%   measured areas. The literal ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30,
%   0.90) call it replaces had been typed out here and at four other sites.
%   What changed substantively at the same time:
%     - The wing carries a FLAPERON plus LEADING-EDGE FLAPS, not an "aileron".
%       The F-16 has no separate ailerons, so the old 0.20/0.40 aileron pair
%       sized a surface this aircraft does not have, while neither of its two
%       real wing surfaces was sized at all.
%     - The all-moving stabilator now reports S_stab = S_ht. c_elev_frac stays
%       0 -- Table 6.5's Fighter/attack row is itself footnoted "Supersonic
%       usually all-moving tail without separate elevator", so S_elev = 0
%       remains the physically-correct answer for this airframe. But "no
%       elevator" is not "no pitch control surface", and the tail's own area
%       was previously carried nowhere.
%     - Rudder fractions are unchanged: 0.30 [Table 6.5, Fighter/attack, Cr/C]
%       and 0.90 [Raymer 6th ed. p.161, "extend to the tip of the tail or to
%       about 90% of the tail span"].
    arguments
         % TODO (7/31/2026): These should not be hardcoded.
         % 8/13/2026: These values appear to not be hardcoded, and are
         % overwritten by the function arguments.
        W_TO_guess (1,1) double {mustBePositive} = 30000
        T_SL_guess (1,1) double {mustBePositive} = 20000
    end

    % Initialize some objects of each discipline class.
    prop = F16PropL2(f16a_spec_path(2));
    geom = F16GeomL2(f16a_spec_path(2), prop);
    % ctrl BEFORE aero: F16AeroL2 takes it by DI now (the flaperon's chord/span
    % fractions live on it, so one flaperon description drives both the
    % high-lift deltas and the sized area).
    ctrl = f16a_control_surfaces();
    aero = F16AeroL2(geom, f16a_spec_path(2), ctrl);
    wts  = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
    miss = MissionAnalysisL2.from_requirements(aero, prop, geom, f16a_requirements_path(), "cap");
    tail = F16TailL1();

    con = ConstraintAnalysis.from_requirements(aero, prop, f16a_requirements_path(), ...
        F16ConstraintSet.constraint_map(), PointPerformanceBase.WS_RANGE_SIZING);

    loop = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl); % Initializes "loop" object of class "SizingLoopL2."
    result = loop.run(W_TO_guess, T_SL_guess); % Runs the loop.

    objs = struct('aero', aero, 'prop', prop, 'wts', wts, 'geom', geom, ...
        'miss', miss, 'con', con);
end
