classdef SizingLoopL1 < handle
%SIZINGLOOPL1  Level-1 (initial design framework) takeoff-gross-weight
%   sizing loop.
%
%   Single-state (W_TO) fixed-point iteration, following the initial
%   design framework [docs/reference_extracts/martins_slides_data.md --
%   Slide 6]: the design diagram is consulted ONCE, before the loop -- it
%   supplies the (W0/Sref, T0/W0) design point, and it does NOT sit inside
%   the MTOW iteration. Each iteration re-derives the absolute S_ref and
%   T_SL from those fixed ratios and the current W_TO, then closes weight
%   with the TOGW step [docs/reference_extracts/metabook_data.md -- Ch. 2,
%   "TOGW Iteration Algorithm (Algorithm 1)"; Raymer 6th ed. Eq. 3.4] via
%   SizingSteps.togw_update.
%
%   Flat orchestrator, not a discipline (same rationale as
%   ConstraintAnalysis / MissionAnalysisBase): constructor-injected with
%   six already-built objects, mutated in place (handle semantics) as the
%   loop iterates. obj.aero is stored for completeness of the injected
%   stack -- this loop never calls it directly; the mission and constraint
%   objects hold the same handle and read it live.
%
%   Recompute-on-read: nothing is cached here. Every iteration writes the
%   design variables (geom.S_ref, prop.T_SL, wts.W_TO/W_energy) into the
%   discipline objects and re-reads mission fuel and OEW fresh.

    properties (SetAccess = private)
        aero    % (1,1) AerodynamicsBase
        prop    % (1,1) PropulsionBase
        wts     % (1,1) WeightsBase
        geom    % (1,1) GeometryBase
        miss    % (1,1) MissionAnalysisBase
        con     % (1,1) ConstraintAnalysis
    end

    methods

        function obj = SizingLoopL1(aero, prop, wts, geom, miss, con)
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                wts  (1,1) WeightsBase
                geom (1,1) GeometryBase
                miss (1,1) MissionAnalysisBase
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
        %RUN  Iterate W_TO to convergence.  [martins slides Slide 6;
        %   metabook Algorithm 1 -- see class header for full citations]
        %
        %   W_TO_guess -- lbf, initial takeoff-gross-weight guess. Required
        %                 (no silent default, per repo convention).
        %   opts.tol_rel    -- relative convergence tolerance on
        %                      |W0_new - W0|/W0_new. Default 1e-6
        %                      [metabook Algorithm 1 uses the same 1e-6
        %                      relative test].
        %   opts.max_iter   -- maximum iterations. Default 200.
        %   opts.relaxation -- under-relaxation factor in (0,1]. Default 0.5.
        %
        %   Returns struct with fields:
        %     W_TO, W_fuel, W_OEW, S_ref, T_SL, WS, TW, n_iter, converged,
        %     history.
        %   history is a struct array (one row per completed iteration)
        %   with fields: iter, W0, W_OEW, W_fuel, W0_new, denom.
        %
        %   If max_iter is reached without convergence, the result is
        %   returned with converged = false and a
        %   'SizingLoopL1:notConverged' warning (no error).
        %   Errors with 'SizingLoopL1:closureInfeasible' if the TOGW
        %   closure denominator goes non-positive (empty + fuel fractions
        %   consume the whole takeoff weight).
            arguments
                obj
                W_TO_guess      (1,1) double {mustBePositive}
                opts.tol_rel    (1,1) double {mustBePositive} = 1e-6
                opts.max_iter   (1,1) double {mustBePositive, mustBeInteger} = 200
                opts.relaxation (1,1) double {mustBeInRange(opts.relaxation, 0, 1, "exclude-lower")} = 0.5
            end

            % Design diagram solved ONCE, before the loop [martins slides
            % Slide 6: the design diagram box sits outside the MTOW
            % iteration]. WS/TW are ratios; the absolutes S_ref/T_SL are
            % re-derived from them each iteration below.
            [WS, TW] = obj.con.optimal_point_continuous();

            W0 = W_TO_guess;
            converged = false;

            row_template = struct('iter', NaN, 'W0', NaN, 'W_OEW', NaN, ...
                'W_fuel', NaN, 'W0_new', NaN, 'denom', NaN);
            history = repmat(row_template, 1, opts.max_iter);

            for iter = 1:opts.max_iter
                % Wing sized by the fixed design point [Slide 6].
                obj.geom.S_ref = W0 / WS;
                if isprop(obj.geom, 'W_TO')
                    % L1 regression geometries (e.g. F16GeomL1) carry W_TO
                    % as a state variable for their S_wet/L_fus
                    % regressions; guarded write -- a planform geometry
                    % (L2/L3) has no W_TO property and skips this.
                    obj.geom.W_TO = W0;
                end
                % Engine sized by the fixed design point [Slide 6].
                obj.prop.T_SL = TW * W0;

                [W_fuel, ~] = obj.miss.total_fuel(W0);
                W_OEW = obj.wts.OEW(W0);

                % WeightsBase bookkeeping (sizing-loop state properties).
                obj.wts.W_TO     = W0;
                obj.wts.W_energy = W_fuel;

                W_payload = obj.wts.W_payload_fixed + obj.wts.W_payload_expendable;
                % TOGW closure step [metabook Algorithm 1; Raymer 6th ed.
                % Eq. 3.4 -- see SizingSteps.togw_update].
                [W0_new, denom] = SizingSteps.togw_update(W_payload, W_OEW, W_fuel, W0);
                if isnan(W0_new)
                    error('SizingLoopL1:closureInfeasible', ...
                        ['TOGW closure infeasible at iteration %d: denom = ', ...
                         '1 - W_fuel/W_TO - W_OEW/W_TO = %.4f <= 0 ', ...
                         '(W_OEW/W_TO = %.4f, W_fuel/W_TO = %.4f at W_TO = %.1f lbf). ', ...
                         'The empty and fuel fractions consume the whole takeoff ', ...
                         'weight; no positive W_TO closes the payload at this design point.'], ...
                        iter, denom, W_OEW/W0, W_fuel/W0, W0);
                end

                row = row_template;
                row.iter   = iter;
                row.W0     = W0;
                row.W_OEW  = W_OEW;
                row.W_fuel = W_fuel;
                row.W0_new = W0_new;
                row.denom  = denom;
                history(iter) = row;

                if abs(W0_new - W0) / W0_new < opts.tol_rel
                    W0 = W0_new;
                    converged = true;
                    break;
                end
                W0 = SizingSteps.relax(W0, W0_new, opts.relaxation);
            end
            history = history(1:iter);

            if ~converged
                warning('SizingLoopL1:notConverged', ...
                    ['W_TO iteration did not converge in %d iterations ', ...
                     '(last W0 = %.1f lbf, last relative step = %.3e). ', ...
                     'Returning the unconverged state (converged = false).'], ...
                    opts.max_iter, W0, abs(history(end).W0_new - history(end).W0) / history(end).W0_new);
            end

            % Final write-through at the returned W0: the loop body wrote
            % the disciplines at the PRE-update W0, so re-derive
            % S_ref/T_SL/weights once more to keep the mutated objects and
            % the result consistent with the returned W_TO.
            obj.geom.S_ref = W0 / WS;
            if isprop(obj.geom, 'W_TO')
                obj.geom.W_TO = W0;
            end
            obj.prop.T_SL = TW * W0;
            [W_fuel, ~] = obj.miss.total_fuel(W0);
            W_OEW = obj.wts.OEW(W0);
            obj.wts.W_TO     = W0;
            obj.wts.W_energy = W_fuel;

            result = struct( ...
                'W_TO',      W0, ...
                'W_fuel',    W_fuel, ...
                'W_OEW',     W_OEW, ...
                'S_ref',     obj.geom.S_ref, ...
                'T_SL',      obj.prop.T_SL, ...
                'WS',        WS, ...
                'TW',        TW, ...
                'n_iter',    iter, ...
                'converged', converged, ...
                'history',   history);
        end

    end

end
