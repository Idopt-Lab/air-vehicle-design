classdef SizingLoopL2 < handle
%SIZINGLOOPL2  Generic Level-2 (also serves Level-3) takeoff-gross-weight
%   and sea-level-thrust sizing loop.
%
%   Two-state-variable (W_TO, T_SL) fixed-point iteration.
%   Flat orchestrator, not a discipline --
%   see SizingLoopL1.m's header for the architecture rationale (same
%   applies here).
%
%   TAIL/CONTROL-SURFACE SIZING (2026-08-03 absorption into Geometry
%   REVERTED, 2026-08-05): tail sizing and control-surface sizing are
%   separate, dependency-injected objects again, NOT methods on geom. The
%   standalone tail_sizing discipline (TailSizingBase/TailL1/L2/L3/
%   F16TailL1/L2/L3) and src/sizing/ControlSurfaceSizer.m are restored, and
%   this constructor once again takes tail (1,1) TailSizingBase and
%   ctrl (1,1) ControlSurfaceSizer as required arguments. Each iteration
%   this loop calls tail.size(S_ref, b, cbar, L_HT, L_VT) --
%   TailSizingBase's WIDEST abstract signature (see TailSizingBase.m's
%   header), read live off obj.geom -- and ctrl.size(obj.geom) (reads
%   geom.S_ref/S_ht/S_vt and, for
%   the wing flaps, geom.lambda_wing), then writes the results back into
%   obj.geom's plain S_ht/S_vt/S_ail/S_elev/S_rud/S_flaperon/S_lef/S_stab
%   properties. Production wires in F16TailL1() (shared, unmodified,
%   across BOTH design_study_02_L2.m and design_study_03_L3.m) -- NOT
%   F16TailL2 (Nicolai-coefficient alternate) or F16TailL3 (stability-and-
%   control stub), neither of which is ever wired into this loop.
%
%   S_ref IS SOLVED FOR (changed 2026-08-10; closes the 2026-08-05 TODO in
%   the loop body "change W/S and S_ref with each iteration"). Both design
%   variables are re-derived every iteration from the CURRENT constraint-
%   diagram optimum and the CURRENT W_TO guess, the same pattern
%   SizingLoopL1 uses:
%     S_ref = W_TO / WS_opt;   geom.S_ref = S_ref;
%     T_SL  = TW_opt * W_TO;   prop.T_SL  = T_SL;
%   The JSON .geometry.wing.S_ft2 value is therefore only the STARTING
%   point (what F16GeomL2/L3's constructor loads), no longer a frozen
%   input: this loop overwrites geom.S_ref on the first iteration. Every
%   S_ref-derived geometry quantity (b_wing, chords, MAC, exposed and
%   wetted areas, ...) is Dependent, so it tracks the new S_ref live with
%   no extra wiring (CLAUDE.md, F16GeomL2.m header) -- and because
%   F16AeroL2/L3 hold the same geom handle, the drag polar and therefore
%   the constraint envelope move with S_ref too. PREVIOUS BEHAVIOR (before
%   2026-08-10), kept here for reading older report numbers: S_ref was held
%   at its JSON value for the whole run and the WS_opt output of
%   optimal_point() was discarded.
%
%   UNLIKE L1, con.optimal_point() is called EVERY iteration
%   (changed 2026-08-03 -- see ConstraintAnalysis.m's "LIVE RE-EVALUATION"
%   header note; used to be called once before the loop, mirroring L1, on
%   the reasoning that S_ref never changes so the envelope can't either --
%   that reasoning missed a real feedback path: obj.prop.T_SL is assigned a
%   few lines below, and F16GeomL2/L3's T_AB_SLS_lb is Dependent on
%   prop.T_SL, sizing the nacelle diameter and therefore duct wetted area,
%   S_wet, and aero.CD0 -- which the constraints read live -- so the
%   envelope genuinely does move as this loop's T_SL state evolves). Each
%   call here sees LAST iteration's T_SL-driven wetted area, one iteration
%   lagged, since prop.T_SL is only updated to THIS iteration's value right
%   after; that lag is consistent with how W_TO/T_SL themselves lag by one
%   iteration under-relaxation. Since 2026-08-10 the per-iteration call is
%   necessary for a SECOND, stronger reason: the WS_opt output is now used
%   (see above), and obj.geom.S_ref is assigned from it, which moves the
%   wing's exposed/wetted area and therefore aero.CD0 as well -- so the
%   envelope tracks BOTH state variables, not the nacelle/duct term alone.
%   Both feedback paths are one iteration lagged in the same way, because
%   geom.S_ref and prop.T_SL are only updated to THIS iteration's values
%   right after the optimal_point() call.
%
%   Every iteration also re-sizes the tail and control surfaces from the
%   CURRENT S_ref and wing geometry (both of which now move with W_TO --
%   see above; before 2026-08-10 they were loop-invariant):
%     tail_result   = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_HT, obj.geom.L_VT);
%     obj.geom.S_ht = tail_result.S_ht;
%     obj.geom.S_vt = tail_result.S_vt;
%     cs_result     = obj.ctrl.size(obj.geom);
%     obj.geom.S_ail/S_elev/S_rud/S_flaperon/S_lef/S_stab = cs_result....
%   Both are pure functions of geom, and geom.S_ref now changes every
%   iteration, so this recompute is REQUIRED for correctness -- it is no
%   longer the cheap-but-redundant call it was before 2026-08-10. ORDERING
%   MATTERS: the tail block runs FIRST, because S_elev/S_stab/S_rud are sized
%   off S_ht/S_vt; swapping the two blocks would size them against last
%   iteration's tail.
%
%   SIX CONTROL SURFACES, not three (widened 2026-08-10). ControlSurfaceSizer
%   now also returns S_flaperon, S_lef and S_stab, and this loop writes all
%   six. Why each was missing before:
%     - S_flaperon / S_lef: the F-16 has NO separate ailerons -- its
%       trailing-edge surface is a flaperon (aileron + flap in one) and it
%       carries leading-edge flaps [f16a_ground_truth.json: "the F-16 has no
%       conventional trailing-edge flaps (flaperons + LE flaps only)"]. The
%       loop sized an aileron that does not exist and never sized either real
%       wing surface.
%     - S_stab: the horizontal tail is all-moving, so S_elev is legitimately
%       0 -- but the pitch control area is then the WHOLE S_ht, and nothing
%       carried it [Raymer 6th ed. Table 6.5 footnote].
%   For the F-16, S_ail and S_elev both come back 0 and are kept only because
%   ControlSurfaceSizer stays generic (F16SandCL3 also reads c_elev_frac off
%   it). Exactly one of (S_ail, S_flaperon) and one of (S_elev, S_stab) is
%   nonzero for any airframe; that sizer's constructor enforces it.
%
%   THE CONTROL-SURFACE AREAS ARE NO LONGER A DEAD END (2026-08-10). Until
%   this change, nothing in the framework READ S_ail/S_elev/S_rud -- they
%   reached only this loop's history struct and the two report scripts, so
%   control-surface sizing had zero feedback into convergence. Meanwhile
%   THREE FROZEN control-surface areas on F16GeomL3 did feed the weights and
%   were never updated: S_csw = 68.03 (Raymer Eq. 15.1 wing weight), S_r =
%   11.65 (Eq. 15.3 vertical tail), S_cs = 190 (Eq. 15.17 flight controls).
%   That inversion is fixed: those three are now Dependent on the six areas
%   this loop writes (S_csw = S_flaperon + S_lef; S_r = S_rud; S_cs = S_csw +
%   S_stab + S_rud), so a wing/tail rescale reaches OEW. The coupling is
%   implicit, through geom's own getters -- same mechanism as the tail's, see
%   the block comment at the assignment site.
%
%   GROUND TRUTH vs. ESTIMATE -- do not conflate. Everything this loop
%   computes is a Raymer/Roskam ESTIMATE. The real F-16's measured areas
%   (T.O. 1F-16A-1 Fig. 1-2: flaperon 31.32, LEF 36.71, rudder 11.65 ft^2)
%   SEED F16GeomL3's properties so a non-loop construction reproduces ground
%   truth exactly, and serve as comparison targets afterwards -- they are
%   never fitted backwards into the sizer's fractions. The rudder is the
%   sharpest case: Raymer's 0.30 x 0.90 x S_vt gives 16.2 ft^2 at the JSON
%   baseline against the measured 11.65, +39%, logged in
%   VnV/BrandtF16A/todo.md and reported by
%   examples/F16A/tail_sizing_brandt_comparison.m rather than calibrated away.
%
%   Closure: Raymer's TOGW iteration ("Eq. 3.4" per the user; reproduced
%   as Algorithm 1 / Eqs. 2.1-2.2 in
%   docs/reference_extracts/metabook_data.md:78-83), same form as
%   SizingLoopL1.m:
%     W_TO_new = W_payload / (1 - We/W_TO - W_fuel/W_TO)
%   with We=OEW(W_TO) and W_fuel=miss.compute_fuel(...) evaluated at the
%   CURRENT W_TO guess, under-relaxed toward W_TO; T_SL likewise
%   under-relaxed toward T_SL_new. Convergence requires BOTH
%   |W_TO_new-W_TO| < tol AND |T_SL_new-T_SL| < tol.
%   Supersedes an earlier additive closure [WeightsBase.m header] -- same
%   fixed point either way (see SizingLoopL1.m's header for the
%   derivation).
%
%   FALLBACK: Raymer's divide has a pole where the empty and fuel fractions
%   sum to 1. A high W_TO_guess can put an early iteration past that pole,
%   which makes W_TO_new negative. The loop then uses Nicolai's algebraic sum
%     W_TO_new = W_empty + W_fuel + W_fixed   [Nicolai & Carichner Eq. (5.1),
%     p. 124]
%   when the denominator is MIN_DENOM or less. W_fixed is Nicolai's payload
%   (crew + equipment + expendables) = W_payload_fixed + W_payload_expendable.
%   The two forms have the same fixed point, thus the fallback changes only
%   the path. result.n_fallback counts the iterations that use it.
%   The <0.005% multiplicative-vs-additive gap and ~2x
%   faster convergence were confirmed empirically pre-2026-08-03, when
%   con.optimal_point() was still called once before the loop (F-16A L2:
%   21,181.0 vs. 21,181.6 lbf; L3, reusing this same class: 23,039.1 vs.
%   23,039.5 lbf). Both design studies still converge cleanly with the
%   live per-iteration optimal_point() call above, but at DIFFERENT
%   absolute numbers each time the feedback set grew. With TW_opt tracking
%   the T_SL feedback but S_ref still frozen (2026-08-03 to 2026-08-10):
%   L2 W_TO=20,994.33 lbf, T_SL=14,211.13 lbf, 15 iter; L3 W_TO=22,884.83
%   lbf, T_SL=15,168.55 lbf, 15 iter. With S_ref solved as well (2026-08-10,
%   first pass): L2 W_TO=23,075.65 lbf, S_ref=174.82 ft^2, T_SL=20,086.32
%   lbf, 19 iter; L3 W_TO=23,972.46 lbf, S_ref=181.61 ft^2, T_SL=17,220.66
%   lbf, 12 iter, with WS_opt = 132 psf at both levels.
%
%   AFTER THE FLAPERON/LEF/STABILATOR WORK (2026-08-10, first pass):
%     L2  W_TO=23,120.65 lbf, S_ref=222.31 ft^2, T_SL=20,253.01 lbf, 17 iter
%     L3  W_TO=23,338.62 lbf, S_ref=210.26 ft^2, T_SL=17,245.01 lbf, 12 iter
%   WS_opt moved 132 -> 104 psf (L2) and 132 -> 111 psf (L3), diverging for
%   the first time (previously coincidentally equal, see below).
%
%   WHY THE ENVELOPE MOVED at that point, since it is a large shift and not
%   obviously related to sizing control surfaces: making ControlSurfaceSizer
%   the single source of the flaperon's chord/span fractions replaced the
%   aero classes' own eta_flap_in/out = 0.10/0.90 with 0.35/0.75 (see
%   f16a_control_surfaces.m -- 0.10/0.90 implied a 60 ft^2 flaperon against a
%   measured 31.32, and was flagged in-code as unverified). A narrower flap
%   band lowers Roskam Eq. 7.10's flapped-area ratio, which lowers
%   Delta_CLmax_flap and Delta_CD0_flap, which tightens the takeoff and
%   landing constraints, which moves WS_opt -- and S_ref = W_TO/WS_opt with
%   it. The chain is real physics, not a regression.
%
%   CURRENT (2026-08-10, LATER SAME DAY -- L2/L3 leading-edge-flap parity):
%     L2  W_TO=23,037.50 lbf, S_ref=207.55 ft^2, T_SL=20,174.15 lbf, 17 iter
%     L3  unchanged (210.26 was already this run's value; L3 was not touched)
%   WS_opt moved BACK to 111 psf at L2, matching L3 (and L1) again. Root
%   cause of the divergence just above: F16AeroL2 modeled ONLY the trailing-
%   edge flaperon's CLmax contribution, never the leading-edge flap's --
%   LandingConstraint.WS_max() reads CLmax_L straight off the injected aero
%   object, so L2's landing wall was permanently ~5.3 psf tighter than L3's
%   for a reason unrelated to either level's intended fidelity difference.
%   The PRE-flaperon-fix agreement (both at 132) was coincidental grid
%   quantization -- the two walls were never actually equal (133.02 vs
%   138.57 psf), they just floored to the same 7-psf grid point; the
%   coincidence broke once the flaperon fix shifted the whole baseline down
%   ~24 psf and the same ~5.3 psf gap crossed a grid line. Closing the LEF
%   gap in F16AeroL2 (same equations/citations/values as F16AeroL3, ported
%   verbatim) makes L2.CLmax_L equal L3.CLmax_L exactly and restores the
%   agreement on real physical grounds instead of coincidence. Both remain
%   INTERIOR points of PointPerformanceBase.WS_RANGE_BRANDT (20:7:160) and
%   exact grid points of it, so the solved S_ref is a real envelope optimum,
%   not a sweep-limit artifact. Full account: VnV/BrandtF16A/todo.md
%   2026-08-10 "CLOSED: F16AeroL2 had no leading-edge-device model at all".
%
%   The multiplicative-vs-additive comparison was never re-run against the
%   live envelope, so treat those side-by-side numbers as historical.
%
%   CORRECTIONS TO the original step-8 PSEUDOCODE -- same three as SizingLoopL1.m
%   (con.optimal_point() no-arg/two-output; prop.T_SL not prop.T0;
%   miss.compute_fuel 3 args, payload from wts not a "req" object) -- plus:
%     geom.S_HT/S_VT -> geom.S_ht/S_vt (F16GeomL2's actual property casing).
% TODO (8/3/2026): You could move this section (72 - 100) (constructor and
% properties) into some sort of base enforcer class that is also accessible
% to subclasses. Apply this to SizingLoopL1, too.
    properties (Constant)
        % Smallest (1 - f_empty - f_fuel) that Raymer's divide can use. Below
        % this the loop uses Nicolai Eq. 5.1 instead. The denominator equals
        % W_payload/W_TO at convergence, which is 0.22 for the F-16A, so this
        % limit stays clear of the converged answer.
        MIN_DENOM = 0.05
    end

    properties (SetAccess = private)
        aero
        prop
        wts
        geom
        miss
        con
        tail
        ctrl
    end

    methods

        function obj = SizingLoopL2(aero, prop, wts, geom, miss, con, tail, ctrl)
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                wts  (1,1) WeightsBase
                geom (1,1) GeometryBase
                miss (1,1) MissionAnalysisBase
                con  (1,1) ConstraintAnalysis
                tail (1,1) TailSizingBase
                ctrl (1,1) ControlSurfaceSizer
            end
            obj.aero = aero;
            obj.prop = prop;
            obj.wts  = wts;
            obj.geom = geom;
            obj.miss = miss;
            obj.con  = con;
            obj.tail = tail;
            obj.ctrl = ctrl;
        end

        function result = run(obj, W_TO_guess, T_SL_guess, opts)
        %RUN  Iterate (W_TO, T_SL) to convergence.
        %   W_TO_guess, T_SL_guess -- initial guesses, lbf. Both required,
        %     no default.
        %   opts.tol         -- lbf, convergence tolerance on BOTH
        %     |W_TO_new-W_TO| and |T_SL_new-T_SL|. Default 1.0.
        %   opts.max_iter     -- max iterations. Default 200.
        %   opts.relaxation   -- under-relaxation factor in (0,1]. Default 0.5.
        %
        %   Returns struct('W_TO', 'S_ref', 'T_SL', 'n_iter', 'converged', 'history').
        %   S_ref is a solved OUTPUT (= W_TO/WS_opt), same as SizingLoopL1's
        %   (changed 2026-08-10; it used to echo the fixed geom.S_ref input).
        %   history is a struct array, one entry per completed iteration.
            arguments
                obj
                W_TO_guess (1,1) double {mustBePositive}
                T_SL_guess (1,1) double {mustBePositive}
                opts.tol (1,1) double {mustBePositive} = 1.0
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 200
                opts.relaxation (1,1) double {mustBeInRange(opts.relaxation, 0, 1)} = 0.5
            end

            W_TO = W_TO_guess;
            T_SL = T_SL_guess;
            converged = false;
            n_fallback = 0;   % count of iterations that used Nicolai Eq. 5.1
            history = struct('iter', {}, 'W_TO', {}, 'S_ref', {}, 'T_SL', {}, 'S_ht', {}, ...
                'S_vt', {}, 'S_ail', {}, 'S_elev', {}, 'S_rud', {}, ...
                'S_flaperon', {}, 'S_lef', {}, 'S_stab', {}, 'W_fuel', {}, 'W_OEW', {});

            for iter = 1:opts.max_iter
                % Recomputed every iteration -- see header note above. Both
                % ratios are now used: S_ref comes from WS_opt (done
                % 2026-08-10, closing the former TODO here), T_SL from TW_opt.
                [WS_opt, TW_opt] = obj.con.optimal_point(); % TODO (8/10/2026): Is this ACTUALLY recomputing the optimum point, or is it just checking if the  point is phyusically feasible? It doesn't seem like it's actually recomputing it!

                S_ref = W_TO / WS_opt;
                obj.geom.S_ref = S_ref;
                % TODO (8/13/2026): Remember, if the S_ref is changing,
                % then all the wing dimensions should change from that.
                % Ensure that these updates are firing.

                T_SL_new = TW_opt * W_TO; % TODO (8/13/2026): This isn't even using the new T_SL, and this STILL BOTHERS ME.
                obj.prop.T_SL = T_SL_new;

                % TAIL/CONTROL-SURFACE -> WEIGHT COUPLING (documented
                % 2026-08-03, was a TODO asking to make this clearer): the
                % assignments below write obj.tail's/obj.ctrl's results into
                % obj.geom's own S_ht/S_vt/S_ail/S_elev/S_rud in place. There
                % is no explicit argument passing those areas into obj.wts
                % below -- the coupling is implicit, through obj.wts's OWN
                % Dependent S_ht/S_vt getters, which read
                % obj.geom.S_exposed_ht/S_exposed_vt live (see
                % F16WeightsL2.m's get.S_ht/get.S_vt). So obj.wts.OEW(W_TO),
                % a few lines down, already reflects THIS iteration's tail/
                % control-surface sizing with no extra wiring here; skipping
                % the block below would silently freeze OEW's tail/VT
                % weight terms at whatever geom last held.
                tail_result   = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_HT, obj.geom.L_VT);
                obj.geom.S_ht = tail_result.S_ht;
                obj.geom.S_vt = tail_result.S_vt;

                % Control surfaces AFTER the tail, never before: S_elev/S_stab/
                % S_rud are all sized off S_ht/S_vt, so reversing these two
                % blocks would size them against LAST iteration's tail.
                cs_result           = obj.ctrl.size(obj.geom);
                obj.geom.S_ail      = cs_result.S_ail;
                obj.geom.S_elev     = cs_result.S_elev;
                obj.geom.S_rud      = cs_result.S_rud;
                obj.geom.S_flaperon = cs_result.S_flaperon;
                obj.geom.S_lef      = cs_result.S_lef;
                obj.geom.S_stab     = cs_result.S_stab;

                W_fuel = obj.miss.compute_fuel(obj.aero, obj.prop, W_TO);
                W_OEW  = obj.wts.OEW(W_TO);
                % TODO (8/3/2026): Make a mermaid chart to see exactly what
                % data goes where during runtime. Don't forget the loop.

                obj.wts.W_TO     = W_TO;
                obj.wts.W_energy = W_fuel;

                % Raymer TOGW iteration (see header): W_TO_new = W_payload /
                % (1 - We/W_TO - W_fuel/W_TO), fractions evaluated at the
                % current W_TO guess.
                W_payload = obj.wts.W_payload_fixed + obj.wts.W_payload_expendable;
                f_empty   = W_OEW / W_TO;
                f_fuel    = W_fuel / W_TO;
                denom     = 1 - f_empty - f_fuel;

                % Raymer's form has a pole at denom = 0. Use Nicolai's
                % algebraic sum when the denominator gets too small. Both
                % forms give the same answer at convergence (see header).
                if denom > SizingLoopL2.MIN_DENOM
                    W_TO_new = W_payload / denom;                % Raymer Eq. 3.4
                else
                    W_TO_new = W_OEW + W_fuel + W_payload;       % Nicolai Eq. 5.1
                    n_fallback = n_fallback + 1;
                end

                diff_W = W_TO_new - W_TO;
                diff_T = T_SL_new - T_SL;

                history(end+1) = struct('iter', iter, 'W_TO', W_TO, 'S_ref', S_ref, 'T_SL', T_SL, ...
                    'S_ht', tail_result.S_ht, 'S_vt', tail_result.S_vt, ...
                    'S_ail', cs_result.S_ail, 'S_elev', cs_result.S_elev, 'S_rud', cs_result.S_rud, ...
                    'S_flaperon', cs_result.S_flaperon, 'S_lef', cs_result.S_lef, ...
                    'S_stab', cs_result.S_stab, ...
                    'W_fuel', W_fuel, 'W_OEW', W_OEW); %#ok<AGROW>

                if abs(diff_W) < opts.tol && abs(diff_T) < opts.tol
                    converged = true;
                    W_TO = W_TO_new;
                    T_SL = T_SL_new;
                    break;
                end

                W_TO = opts.relaxation * W_TO + (1 - opts.relaxation) * W_TO_new;
                T_SL = opts.relaxation * T_SL + (1 - opts.relaxation) * T_SL_new;
            end

            % Re-derive S_ref/T_SL/tail/control-surface state from the final
            % W_TO (the loop body above computed them from the PRE-update
            % W_TO) so the mutated geom/prop/wts objects and the returned
            % result stay consistent with the returned W_TO/T_SL. Also
            % recompute the optimum one more time here: the loop body's own
            % obj.con.optimal_point() call each iteration reads LAST
            % iteration's geom.S_ref- and prop.T_SL-driven wetted area (see
            % header note above), so on exit it is one iteration behind the
            % geom.S_ref/prop.T_SL this loop just converged to.
            [WS_opt, TW_opt] = obj.con.optimal_point();
            S_ref = W_TO / WS_opt;
            obj.geom.S_ref = S_ref;
            T_SL = TW_opt * W_TO;
            obj.prop.T_SL = T_SL;
            tail_result         = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_HT, obj.geom.L_VT);
            obj.geom.S_ht       = tail_result.S_ht;
            obj.geom.S_vt       = tail_result.S_vt;
            cs_result           = obj.ctrl.size(obj.geom);
            obj.geom.S_ail      = cs_result.S_ail;
            obj.geom.S_elev     = cs_result.S_elev;
            obj.geom.S_rud      = cs_result.S_rud;
            obj.geom.S_flaperon = cs_result.S_flaperon;
            obj.geom.S_lef      = cs_result.S_lef;
            obj.geom.S_stab     = cs_result.S_stab;
            obj.wts.W_TO = W_TO;

            result = struct('W_TO', W_TO, 'S_ref', S_ref, 'T_SL', T_SL, ...
                'n_iter', iter, 'converged', converged, 'history', history, ...
                'n_fallback', n_fallback);
        end

    end

end
