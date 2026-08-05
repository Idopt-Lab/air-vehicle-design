classdef SizingLoopL1 < handle
%SIZINGLOOPL1  Generic Level-1 takeoff-gross-weight sizing loop.
%
%   Single-state-variable (W_TO) fixed-point iteration [docs/subplans/08_sizing.md].
%   Flat orchestrator, not a discipline: constructor-injected with six
%   already-built discipline/analysis objects, mutated in place (handle
%   semantics) as the loop iterates -- create fresh objects for each design
%   study, per subplan 08's Design Notes. No abstract Base/ModelLN split
%   (matches how ConstraintAnalysis, the other system-level piece, was
%   built): sizing has no per-fidelity equation set of its own to vary.
%
%   ALGORITHM. [WS_opt, TW_opt] = con.optimal_point() is called ONCE,
%   before the loop starts, not every iteration: these are the
%   constraint-diagram-optimal wing-loading and thrust-to-weight RATIOS,
%   fixed quantities that do not depend on W_TO. At L1, F16AeroL1 is
%   explicitly geometry-free (its own header) so changing geom.S_ref cannot
%   perturb its drag polar, and PropulsionBase.thrust_lapse is already a
%   self-normalized ratio T(alt,M)/T_SL, so changing prop.T_SL cannot
%   perturb it either -- the constraint envelope is therefore invariant to
%   the W_TO iteration, so computing it once is both correct and cheap. It
%   is also therefore safe even if a caller built con's constraints from a
%   SEPARATE aero/prop pair rather than sharing handles with this loop's
%   aero/prop (design_study_01_L1.m in fact shares them, via
%   F16ConstraintSet.build(aero, prop) -- see that class's header) -- con's
%   frozen snapshot stays valid regardless. If a future L1 aero model
%   becomes geometry-coupled, or the constraint envelope is ever made to
%   depend on W_TO, this must be revisited.
%
%   Every iteration re-derives the ABSOLUTE S_ref and T_SL from those FIXED
%   ratios and the CURRENT W_TO guess:
%     S_ref = W_TO / WS_opt;   geom.S_ref = S_ref;
%     T_SL  = TW_opt * W_TO;   prop.T_SL  = T_SL;
%   -- both scale with the converging weight, matching subplan 08's
%   pseudocode and the legacy F-16 L1 driver script
%   (temp_Casey/.../F16A_Level1_Sizing_ClassBased_Example.m:284,286).
%
%   Closure: Raymer's TOGW iteration ("Eq. 3.4" per the user; reproduced
%   as Algorithm 1 / Eqs. 2.1-2.2 in
%   docs/reference_extracts/metabook_data.md:78-83):
%     W_TO_new = W_payload / (1 - We/W_TO - W_fuel/W_TO)
%   with We=OEW(W_TO) and W_fuel=miss.compute_fuel(...) evaluated at the
%   CURRENT W_TO guess, under-relaxed toward the prior W_TO. Supersedes an
%   earlier additive closure [WeightsBase.m header: W_TO_new = OEW(W_TO) +
%   W_payload_fixed + W_payload_expendable + W_fuel] -- both solve
%   w = W_payload + we(w) + wf(w) for w, just rearranged, so they share the
%   same fixed point (confirmed empirically on the F-16A L1 design study:
%   41,437.5 lbf vs. the additive form's 41,433.1 lbf, a 0.01% gap). This
%   form converges in far fewer iterations (8 vs. 81 on that same study).
%
%   CORRECTIONS TO subplan 08's PSEUDOCODE (verified against the as-built
%   APIs):
%     con.optimal_point() takes NO arguments and returns TWO outputs
%       ([WS_opt, TW_opt]), not a struct from optimal_point(aero, prop).
%     prop.T_SL (not prop.T0) is PropulsionBase's abstract sea-level-thrust
%       property.
%     miss.compute_fuel(aero, prop, W_TO) takes 3 args (MissionBase), not 4
%       -- there is no "req" object with W_payload/S_ref fields anywhere in
%       this codebase; payload comes from wts.W_payload_fixed/
%       W_payload_expendable (WeightsBase abstract properties).
% TODO (8/3/2026): Remember to remove extra documentation during final
% pass. Should store the decisions and rationalization in some kind of
% archive later. Include timestamp of comment creation.

    properties (SetAccess = private)
        aero
        prop
        wts
        geom
        miss
        con
    end

    methods

        function obj = SizingLoopL1(aero, prop, wts, geom, miss, con)
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                wts  (1,1) WeightsBase
                geom (1,1) GeometryBase
                miss (1,1) MissionBase
                con  (1,1) ConstraintAnalysis
            end
            obj.aero = aero;
            obj.prop = prop;
            obj.wts  = wts;
            obj.geom = geom;
            obj.miss = miss;
            obj.con  = con;
        end

        function result = run(obj, W_TO_guess, opts)
        %RUN  Iterate W_TO to convergence.
        %   W_TO_guess -- initial takeoff-gross-weight guess, lbf. Required,
        %     no default (this codebase's convention: no silent defaults).
        %   opts.tol         -- lbf, |W_TO_new-W_TO| convergence tolerance. Default 1.0.
        %   opts.max_iter     -- max iterations. Default 200.
        %   opts.relaxation   -- under-relaxation factor in (0,1]. Default 0.5.
        %
        %   Returns struct('W_TO', 'S_ref', 'T_SL', 'n_iter', 'converged', 'history').
        %   history is a struct array, one entry per completed iteration.
            arguments
                obj
                W_TO_guess (1,1) double {mustBePositive}
                opts.tol (1,1) double {mustBePositive} = 1.0
                opts.max_iter (1,1) double {mustBePositive, mustBeInteger} = 200
                opts.relaxation (1,1) double {mustBeInRange(opts.relaxation, 0, 1)} = 0.5
            end

            [WS_opt, TW_opt] = obj.con.optimal_point();

            W_TO = W_TO_guess;
            converged = false;
            history = struct('iter', {}, 'W_TO', {}, 'S_ref', {}, 'T_SL', {}, 'W_fuel', {}, 'W_OEW', {});

            for iter = 1:opts.max_iter
                S_ref = W_TO / WS_opt;
                obj.geom.S_ref = S_ref;

                T_SL = TW_opt * W_TO;
                obj.prop.T_SL = T_SL;

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
                difference = W_TO_new - W_TO;

                history(end+1) = struct('iter', iter, 'W_TO', W_TO, 'S_ref', S_ref, ...
                    'T_SL', T_SL, 'W_fuel', W_fuel, 'W_OEW', W_OEW); %#ok<AGROW>

                if abs(difference) < opts.tol
                    converged = true;
                    W_TO = W_TO_new;
                    break;
                end

                W_TO = opts.relaxation * W_TO + (1 - opts.relaxation) * W_TO_new;
                % Note to self (Casey): Slightly different form from what I
                % was taught, but still the same. Usually we do "W_TO =
                % W_TO_new", but we're shaving off a little bit of weight
                % to accelerate convergence.
            end

            % Re-derive S_ref/T_SL from the final W_TO (the loop body above
            % computed them from the PRE-update W_TO) so the mutated
            % geom/prop/wts objects and the returned result stay consistent
            % with the returned W_TO.
            S_ref = W_TO / WS_opt;
            obj.geom.S_ref = S_ref;
            T_SL = TW_opt * W_TO;
            obj.prop.T_SL = T_SL;
            obj.wts.W_TO = W_TO;

            result = struct('W_TO', W_TO, 'S_ref', S_ref, 'T_SL', T_SL, ...
                'n_iter', iter, 'converged', converged, 'history', history);
        end

    end

end
