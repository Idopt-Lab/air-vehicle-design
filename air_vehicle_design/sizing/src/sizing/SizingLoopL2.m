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
%   KEY DIFFERENCE FROM L1: S_ref is FIXED here, never touched by this
%   loop -- it is a genuine input to L2/L3 geometry (read from JSON), not
%   solved for. Only T_SL is derived from a fixed ratio and the evolving
%   W_TO, exactly mirroring L1's S_ref/T_SL derivation pattern:
%     T_SL = TW_opt * W_TO;   prop.T_SL = T_SL;
%   UNLIKE L1, [TW_opt] = con.optimal_point() is called EVERY iteration
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
%   iteration under-relaxation. Tail/control-surface areas (S_ht/S_vt/etc.,
%   sized below) do NOT contribute to this feedback -- they are pure
%   functions of geom's fixed inputs, not of W_TO/T_SL (see the next
%   paragraph) -- the nacelle/duct term is the only wetted-area component
%   that moves during this loop. The W/S output of optimal_point() is still
%   unused here (S_ref is fixed by the JSON input, not derived from W/S).
%
%   Every iteration also re-sizes the tail and control surfaces from the
%   FIXED S_ref and the wing geometry (which also never changes during
%   this loop, since only S_ref and geometry derived from it are touched
%   by SizingLoopL1, not L2/L3):
%     tail_result   = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_fus);
%     obj.geom.S_ht = tail_result.S_ht;
%     obj.geom.S_vt = tail_result.S_vt;
%     cs_result     = obj.ctrl.size(obj.geom);
%     obj.geom.S_ail  = cs_result.S_ail;
%     obj.geom.S_elev = cs_result.S_elev;
%     obj.geom.S_rud  = cs_result.S_rud;
%   Neither tail nor ctrl depend on W_TO/T_SL, so they are technically
%   loop-invariant too (both are pure functions of geom's fixed inputs) --
%   recomputed every iteration anyway to mirror subplan 08's documented
%   call sequence and because they are cheap; a future geom-dependent
%   tail/control-surface method would need this recompute for correctness.
%
%   Closure: Raymer's TOGW iteration ("Eq. 3.4" per the user; reproduced
%   as Algorithm 1 / Eqs. 2.1-2.2 in temp_AI/docs/disciplines/
%   reference_extracts/metabook_data.md:78-83), same form as
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
%   absolute numbers now that TW_opt tracks the T_SL feedback (L2:
%   W_TO=20,994.33 lbf, T_SL=14,211.13 lbf, 15 iter; L3: W_TO=22,884.83
%   lbf, T_SL=15,168.55 lbf, 15 iter) -- the multiplicative-vs-additive
%   comparison itself was never re-run against the live envelope, so
%   treat the old side-by-side numbers above as historical, not current.
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
                miss (1,1) MissionBase
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
        %   S_ref is simply obj.geom.S_ref (fixed input, echoed for parity
        %   with SizingLoopL1's result shape). history is a struct array,
        %   one entry per completed iteration.
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
            history = struct('iter', {}, 'W_TO', {}, 'T_SL', {}, 'S_ht', {}, ...
                'S_vt', {}, 'S_ail', {}, 'S_elev', {}, 'S_rud', {}, 'W_fuel', {}, 'W_OEW', {});

            for iter = 1:opts.max_iter
                 % TODO (8/5/2026): Switch to the metabook's method; change
                 % W/S and S_ref with each iteration.
                % Recomputed every iteration -- see header note above.
                [~, TW_opt] = obj.con.optimal_point();
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

                history(end+1) = struct('iter', iter, 'W_TO', W_TO, 'T_SL', T_SL, ...
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

            % Re-derive T_SL/tail/control-surface state from the final W_TO
            % (the loop body above computed them from the PRE-update W_TO)
            % so the mutated geom/prop/wts objects and the returned result
            % stay consistent with the returned W_TO/T_SL. Also recompute
            % TW_opt one more time here: the loop body's own
            % [~, TW_opt] = obj.con.optimal_point() call each iteration
            % reads LAST iteration's prop.T_SL-driven wetted area (see
            % header note above), so on exit it is one iteration behind the
            % prop.T_SL this loop just converged to.
            [~, TW_opt] = obj.con.optimal_point();
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

            result = struct('W_TO', W_TO, 'S_ref', obj.geom.S_ref, 'T_SL', T_SL, ...
                'n_iter', iter, 'converged', converged, 'history', history);
        end

    end

end
