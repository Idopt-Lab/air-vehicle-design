classdef SizingLoopL2 < handle
%SIZINGLOOPL2  Generic Level-2 (also serves Level-3) takeoff-gross-weight
%   and sea-level-thrust sizing loop.
%
%   Two-state-variable (W_TO, T_SL) fixed-point iteration
%   [docs/subplans/08_sizing.md]. Flat orchestrator, not a discipline --
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
%   this loop calls tail.size(S_ref, b, cbar, L_fus) -- TailSizingBase's
%   WIDEST abstract signature (see TailSizingBase.m's header), read live off
%   obj.geom -- and ctrl.size(obj.geom) (reads geom.S_ref/S_ht/S_vt), then
%   writes the results back into obj.geom's plain S_ht/S_vt/S_ail/S_elev/
%   S_rud properties. Production wires in F16TailL1() (shared, unmodified,
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
%     tail_result   = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_fus);
%     obj.geom.S_ht = tail_result.S_ht;
%     obj.geom.S_vt = tail_result.S_vt;
%     cs_result     = obj.ctrl.size(obj.geom);
%     obj.geom.S_ail  = cs_result.S_ail;
%     obj.geom.S_elev = cs_result.S_elev;
%     obj.geom.S_rud  = cs_result.S_rud;
%   Both are pure functions of geom, and geom.S_ref now changes every
%   iteration, so this recompute is REQUIRED for correctness -- it is no
%   longer the cheap-but-redundant call it was before 2026-08-10.
%
%   Closure: Raymer's TOGW iteration ("Eq. 3.4" per the user; reproduced
%   as Algorithm 1 / Eqs. 2.1-2.2 in
%   docs/reference_extracts/metabook_data.md:78-83), same form as
%   SizingLoopL1.m:
%     W_TO_new = W_payload / (1 - We/W_TO - W_fuel/W_TO)
%   with We=OEW(W_TO) and W_fuel=miss.compute_fuel(...) evaluated at the
%   CURRENT W_TO guess, under-relaxed toward W_TO; T_SL likewise
%   under-relaxed toward T_SL_new. Convergence requires BOTH
%   |W_TO_new-W_TO| < tol AND |T_SL_new-T_SL| < tol [docs/subplans/08_sizing.md].
%   Supersedes an earlier additive closure [WeightsBase.m header] -- same
%   fixed point either way (see SizingLoopL1.m's header for the
%   derivation). The <0.005% multiplicative-vs-additive gap and ~2x
%   faster convergence were confirmed empirically pre-2026-08-03, when
%   con.optimal_point() was still called once before the loop (F-16A L2:
%   21,181.0 vs. 21,181.6 lbf; L3, reusing this same class: 23,039.1 vs.
%   23,039.5 lbf). Both design studies still converge cleanly with the
%   live per-iteration optimal_point() call above, but at DIFFERENT
%   absolute numbers each time the feedback set grew. With TW_opt tracking
%   the T_SL feedback but S_ref still frozen (2026-08-03 to 2026-08-10):
%   L2 W_TO=20,994.33 lbf, T_SL=14,211.13 lbf, 15 iter; L3 W_TO=22,884.83
%   lbf, T_SL=15,168.55 lbf, 15 iter. With S_ref solved as well
%   (2026-08-10, CURRENT): L2 W_TO=23,075.65 lbf, S_ref=174.82 ft^2,
%   T_SL=20,086.32 lbf, 19 iter; L3 W_TO=23,972.46 lbf, S_ref=181.61 ft^2,
%   T_SL=17,220.66 lbf, 12 iter. WS_opt lands on 132 psf at BOTH levels --
%   an INTERIOR point of PointPerformanceBase.WS_RANGE_BRANDT (20:7:160),
%   not a sweep edge, so the solved S_ref is a real envelope optimum rather
%   than a sweep-limit artifact. The multiplicative-vs-additive comparison
%   itself was never re-run against the live envelope, so treat the
%   side-by-side numbers above as historical, not current.
%
%   CORRECTIONS TO subplan 08's PSEUDOCODE -- same three as SizingLoopL1.m
%   (con.optimal_point() no-arg/two-output; prop.T_SL not prop.T0;
%   miss.compute_fuel 3 args, payload from wts not a "req" object) -- plus:
%     geom.S_HT/S_VT -> geom.S_ht/S_vt (F16GeomL2's actual property casing).
% TODO (8/3/2026): You could move this section (72 - 100) (constructor and
% properties) into some sort of base enforcer class that is also accessible
% to subclasses. Apply this to SizingLoopL1, too.
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
            history = struct('iter', {}, 'W_TO', {}, 'S_ref', {}, 'T_SL', {}, 'S_ht', {}, ...
                'S_vt', {}, 'S_ail', {}, 'S_elev', {}, 'S_rud', {}, 'W_fuel', {}, 'W_OEW', {});

            for iter = 1:opts.max_iter
                % Recomputed every iteration -- see header note above. Both
                % ratios are now used: S_ref comes from WS_opt (done
                % 2026-08-10, closing the former TODO here), T_SL from TW_opt.
                [WS_opt, TW_opt] = obj.con.optimal_point();

                S_ref = W_TO / WS_opt;
                obj.geom.S_ref = S_ref;

                T_SL_new = TW_opt * W_TO;
                obj.prop.T_SL = T_SL_new; % TODO (8/3/2026): These should be moved towards the end, since they interfere with using the "guess" values.
                % TODO (8/3/2026): Sanity check; OEW should be affected by
                % engine weight, which is also estimated from T_SL.

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
                tail_result   = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_fus);
                obj.geom.S_ht = tail_result.S_ht;
                obj.geom.S_vt = tail_result.S_vt;

                cs_result       = obj.ctrl.size(obj.geom);
                obj.geom.S_ail  = cs_result.S_ail;
                obj.geom.S_elev = cs_result.S_elev;
                obj.geom.S_rud  = cs_result.S_rud;

                W_fuel = obj.miss.compute_fuel(obj.aero, obj.prop, W_TO);
                W_OEW  = obj.wts.OEW(W_TO);
                % TODO (8/3/2026): Make a mermaid chart to see exactly what
                % data goes where during runtime. Don't forget the loop.
                % Also 

                obj.wts.W_TO     = W_TO;
                obj.wts.W_energy = W_fuel;

                % Raymer TOGW iteration (see header): W_TO_new = W_payload /
                % (1 - We/W_TO - W_fuel/W_TO), fractions evaluated at the
                % current W_TO guess.
                W_payload = obj.wts.W_payload_fixed + obj.wts.W_payload_expendable;
                f_empty   = W_OEW / W_TO;
                f_fuel    = W_fuel / W_TO;
                W_TO_new  = W_payload / (1 - f_empty - f_fuel);

                diff_W = W_TO_new - W_TO;
                diff_T = T_SL_new - T_SL;

                history(end+1) = struct('iter', iter, 'W_TO', W_TO, 'S_ref', S_ref, 'T_SL', T_SL, ...
                    'S_ht', tail_result.S_ht, 'S_vt', tail_result.S_vt, ...
                    'S_ail', cs_result.S_ail, 'S_elev', cs_result.S_elev, 'S_rud', cs_result.S_rud, ...
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
            tail_result     = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_fus);
            obj.geom.S_ht   = tail_result.S_ht;
            obj.geom.S_vt   = tail_result.S_vt;
            cs_result       = obj.ctrl.size(obj.geom);
            obj.geom.S_ail  = cs_result.S_ail;
            obj.geom.S_elev = cs_result.S_elev;
            obj.geom.S_rud  = cs_result.S_rud;
            obj.wts.W_TO = W_TO;

            result = struct('W_TO', W_TO, 'S_ref', S_ref, 'T_SL', T_SL, ...
                'n_iter', iter, 'converged', converged, 'history', history);
        end

    end

end
