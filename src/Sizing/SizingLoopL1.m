classdef SizingLoopL1 < handle
    % L1 sizing loop: single state variable (W_TO).
    %
    % Iterates W_TO until convergence using the discipline objects.
    % Outputs S_ref and T_SL from the converged constraint analysis.
    %
    % Usage:
    %   sizer = SizingLoopL1();
    %   [W_TO, S_ref, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con);
    %
    % Disciplines must implement their abstract interface methods:
    %   con.optimal_point(aero, prop)   → struct(W_S, T_W)
    %   miss.compute_fuel(aero, prop, W_TO, req) → scalar (lbf)
    %   wts.OEW(W_TO)                   → scalar (lbf)
    %
    % req struct required fields:
    %   req.W_payload  — payload weight (lbf)
    %   req.S_ref      — updated each iteration (ft²) for mission analysis
    %   req.AR         — aspect ratio (for L2/L3 mission analysis)
    %   (all other req fields passed through to miss.compute_fuel)

    properties
        tol         = 1.0    % convergence tolerance (lbf)
        max_iter    = 200    % maximum iterations
        damping     = 0.5    % under-relaxation (0=no relaxation, 1=fully new value)
        verbose     = false  % print iteration table
    end

    methods
        function obj = SizingLoopL1(opts)
            if nargin > 0 && isstruct(opts)
                if isfield(opts,'tol');       obj.tol       = opts.tol;       end
                if isfield(opts,'max_iter');  obj.max_iter  = opts.max_iter;  end
                if isfield(opts,'damping');   obj.damping   = opts.damping;   end
                if isfield(opts,'verbose');   obj.verbose   = opts.verbose;   end
            end
        end

        function [W_TO, S_ref, T_SL, iter] = run(obj, req, aero, prop, wts, geom, miss, con)
            % Step 0: initial guess from req or geometry
            if isfield(req,'W_TO_init')
                W_TO = req.W_TO_init;
            else
                W_TO = req.W_payload * 5;  % rough starting guess
            end

            if obj.verbose
                fprintf('%6s  %10s  %10s  %10s\n','Iter','W_TO','W_TO_new','Delta');
            end

            for iter = 1:obj.max_iter
                % Constraint analysis → optimal W/S and T/W
                opt = con.optimal_point(aero, prop);

                % Geometry update for mission analysis
                S_ref_cur     = W_TO / opt.W_S;
                geom.S_ref    = S_ref_cur;
                req.S_ref     = S_ref_cur;

                % Set thrust level for propulsion object
                T_SL_cur      = opt.T_W * W_TO;
                prop.T0       = T_SL_cur;

                % Mission fuel
                W_fuel = miss.compute_fuel(aero, prop, W_TO, req);

                % New TOGW estimate
                W_OEW    = wts.OEW(W_TO);
                W_TO_new = W_OEW + req.W_payload + W_fuel;

                delta    = abs(W_TO_new - W_TO);

                if obj.verbose
                    fprintf('%6d  %10.1f  %10.1f  %10.2f\n', iter, W_TO, W_TO_new, delta);
                end

                % Update with under-relaxation
                W_TO = (1 - obj.damping)*W_TO + obj.damping*W_TO_new;

                if delta < obj.tol
                    break
                end
            end

            if iter == obj.max_iter
                warning('SizingLoopL1:no_convergence', ...
                    'Max iterations reached without convergence. Final delta = %.2f lbf', delta);
            end

            % Compute final outputs from converged W_TO
            opt   = con.optimal_point(aero, prop);
            S_ref = W_TO / opt.W_S;
            T_SL  = opt.T_W * W_TO;

            % Update geometry and prop with final converged values
            geom.S_ref = S_ref;
            prop.T0    = T_SL;
        end
    end
end
