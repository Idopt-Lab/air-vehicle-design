classdef SizingLoopL2 < handle
%SIZINGLOOPL2  Generic Level-2 (also serves Level-3) takeoff-gross-weight
%   and sea-level-thrust sizing loop.
%
%   Two-state-variable (W_TO, T_SL) fixed-point iteration
%   [docs/subplans/08_sizing.md]. Flat orchestrator, not a discipline --
%   see SizingLoopL1.m's header for the architecture rationale (same
%   applies here). Also drives tail sizing (an injected TailSizingBase
%   object, e.g. F16TailL1 -- see src/disciplines/tail_sizing/) and
%   control-surface sizing (ControlSurfaceSizer) every iteration, since
%   both feed geometry that this loop's aero/mission objects read.
%
%   TAIL TYPE (updated 2026-07-28): tail is typed (1,1) TailSizingBase, the
%   Tier-1 abstract enforcer shared by F16TailL1/F16TailL2/F16TailL3
%   (formerly the concrete TailSizingLevel1, before that class was
%   superseded by the tail-sizing three-tier discipline -- see
%   src/disciplines/tail_sizing/TailSizing_scribe_plan.md Sec. 3). The
%   run() body below still calls tail.size(S_ref, b_wing, cbar_wing, L_fus)
%   -- the L1 four-scalar convention -- so only an L1-signature tail object
%   (e.g. F16TailL1) is actually usable through THIS loop today; wiring an
%   L2/L3 tail object (whose size(obj) takes no scalar arguments) through
%   SizingLoopL2 is a separate, not-yet-done follow-up.
%
%   KEY DIFFERENCE FROM L1: S_ref is FIXED here, never touched by this
%   loop -- it is a genuine input to L2/L3 geometry (read from JSON), not
%   solved for. Only T_SL is derived from a fixed ratio and the evolving
%   W_TO, exactly mirroring L1's S_ref/T_SL derivation pattern:
%     T_SL = TW_opt * W_TO;   prop.T_SL = T_SL;
%   [TW_opt] = con.optimal_point() is called ONCE, before the loop, for the
%   same reason as SizingLoopL1 (see that class's header): since S_ref
%   never changes during this loop, the constraint envelope cannot depend
%   on the loop's state at all, so it's correct and cheap to compute once.
%   The W/S output of optimal_point() is unused here (S_ref is fixed by
%   the JSON input, not derived from W/S).
%
%   Every iteration also re-sizes the tail and control surfaces from the
%   FIXED S_ref and the wing geometry (which also never changes during
%   this loop, since only S_ref and geometry derived from it are touched
%   by SizingLoopL1, not L2/L3):
%     tail_result = tail.size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
%     geom.S_ht = tail_result.S_ht;  geom.S_vt = tail_result.S_vt;
%     cs_result = ctrl.size(geom);
%     geom.S_ail = cs_result.S_ail;  geom.S_elev = cs_result.S_elev;  geom.S_rud = cs_result.S_rud;
%   These do not depend on W_TO/T_SL either, so they are technically
%   loop-invariant too (see ControlSurfaceSizer.m / the tail-sizing TailLN
%   toolboxes -- both are pure functions of geom's fixed inputs) --
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
%   derivation), confirmed empirically on both the F-16A L2 design study
%   (21,181.0 vs. 21,181.6 lbf, additive form) and the L3 study, which
%   reuses this same class (23,039.1 vs. 23,039.5 lbf) -- in both cases a
%   <0.005% gap, with this form converging in about half the iterations.
%
%   CORRECTIONS TO subplan 08's PSEUDOCODE -- same three as SizingLoopL1.m
%   (con.optimal_point() no-arg/two-output; prop.T_SL not prop.T0;
%   miss.compute_fuel 3 args, payload from wts not a "req" object) -- plus:
%     geom.S_HT/S_VT -> geom.S_ht/S_vt (F16GeomL2's actual property casing).

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

            [~, TW_opt] = obj.con.optimal_point();

            W_TO = W_TO_guess;
            T_SL = T_SL_guess;
            converged = false;
            history = struct('iter', {}, 'W_TO', {}, 'T_SL', {}, 'S_ht', {}, ...
                'S_vt', {}, 'S_ail', {}, 'S_elev', {}, 'S_rud', {}, 'W_fuel', {}, 'W_OEW', {});

            for iter = 1:opts.max_iter
                T_SL_new = TW_opt * W_TO;
                obj.prop.T_SL = T_SL_new;

                tail_result = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_fus);
                obj.geom.S_ht = tail_result.S_ht;
                obj.geom.S_vt = tail_result.S_vt;

                cs_result = obj.ctrl.size(obj.geom);
                obj.geom.S_ail  = cs_result.S_ail;
                obj.geom.S_elev = cs_result.S_elev;
                obj.geom.S_rud  = cs_result.S_rud;

                W_fuel = obj.miss.compute_fuel(obj.aero, obj.prop, W_TO);
                W_OEW  = obj.wts.OEW(W_TO);

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
            % stay consistent with the returned W_TO/T_SL.
            T_SL = TW_opt * W_TO;
            obj.prop.T_SL = T_SL;
            tail_result = obj.tail.size(obj.geom.S_ref, obj.geom.b_wing, obj.geom.cbar_wing, obj.geom.L_fus);
            obj.geom.S_ht = tail_result.S_ht;
            obj.geom.S_vt = tail_result.S_vt;
            cs_result = obj.ctrl.size(obj.geom);
            obj.geom.S_ail  = cs_result.S_ail;
            obj.geom.S_elev = cs_result.S_elev;
            obj.geom.S_rud  = cs_result.S_rud;
            obj.wts.W_TO = W_TO;

            result = struct('W_TO', W_TO, 'S_ref', obj.geom.S_ref, 'T_SL', T_SL, ...
                'n_iter', iter, 'converged', converged, 'history', history);
        end

    end

end
