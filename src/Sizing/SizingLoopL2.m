classdef SizingLoopL2 < handle
    % L2 sizing loop: two state variables (W_TO, T_SL); S_ref is a fixed input.
    %
    % At each iteration:
    %   1. Constraint analysis → T/W (S_ref is fixed input, not from W/S)
    %   2. Update prop.T0 = T/W * W_TO
    %   3. Tail sizing with current geometry
    %   4. Mission fuel burn
    %   5. OEW estimate
    %   6. New W_TO = OEW + W_payload + fuel
    %
    % Convergence is checked on both W_TO and T_SL simultaneously.
    %
    % Usage:
    %   sizer = SizingLoopL2();
    %   [W_TO, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
    %
    % req struct required fields:
    %   req.W_payload  — payload weight (lbf)
    %   req.S_ref      — fixed wing reference area (ft²) — NOT updated in L2
    %   req.AR         — aspect ratio (for mission analysis)
    %   (all other req fields passed to miss.compute_fuel)
    %
    % geom must have properties: b (wingspan, ft), cbar (MAC, ft), L_fus (ft)
    % Tail results stored back into geom (geom.S_HT, geom.S_VT) after each iter.

    properties
        tol         = 1.0    % convergence tolerance for both W_TO (lbf) and T_SL (lbf)
        max_iter    = 200
        damping     = 0.5
        verbose     = false
    end

    methods
        function obj = SizingLoopL2(opts)
            if nargin > 0 && isstruct(opts)
                if isfield(opts,'tol');       obj.tol       = opts.tol;       end
                if isfield(opts,'max_iter');  obj.max_iter  = opts.max_iter;  end
                if isfield(opts,'damping');   obj.damping   = opts.damping;   end
                if isfield(opts,'verbose');   obj.verbose   = opts.verbose;   end
            end
        end

        function [W_TO, T_SL, iter] = run(obj, req, aero, prop, wts, geom, miss, con, tail)
            % Initial guesses
            if isfield(req,'W_TO_init')
                W_TO = req.W_TO_init;
            else
                W_TO = req.W_payload * 5;
            end

            S_ref = req.S_ref;  % S_ref is fixed in L2

            % Initial T/W from constraint analysis to set prop.T0 before first iter
            opt  = con.optimal_point(aero, prop);
            T_SL = opt.T_W * W_TO;
            prop.T0 = T_SL;

            if obj.verbose
                fprintf('%6s  %10s  %10s  %10s  %10s\n','Iter','W_TO','T_SL','dW_TO','dT_SL');
            end

            for iter = 1:obj.max_iter
                % 1. Constraint analysis at fixed S_ref → T/W
                opt     = con.optimal_point(aero, prop);
                T_W_new = opt.T_W;   % T/W from constraint; W_S not used here
                T_SL_new = T_W_new * W_TO;

                % 2. Update prop with new thrust level
                prop.T0 = T_SL_new;

                % 3. Tail sizing
                tail_result = tail.size(S_ref, geom.b, geom.cbar, geom.L_fus);
                geom.S_HT   = tail_result.S_HT;
                geom.S_VT   = tail_result.S_VT;

                % 4. Mission fuel
                W_fuel = miss.compute_fuel(aero, prop, W_TO, req);

                % 5. OEW
                W_OEW = wts.OEW(W_TO);

                % 6. New TOGW
                W_TO_new = W_OEW + req.W_payload + W_fuel;

                delta_W  = abs(W_TO_new - W_TO);
                delta_T  = abs(T_SL_new - T_SL);

                if obj.verbose
                    fprintf('%6d  %10.1f  %10.1f  %10.2f  %10.2f\n', ...
                        iter, W_TO, T_SL, delta_W, delta_T);
                end

                % Under-relaxed updates
                W_TO = (1 - obj.damping)*W_TO + obj.damping*W_TO_new;
                T_SL = (1 - obj.damping)*T_SL + obj.damping*T_SL_new;

                if delta_W < obj.tol && delta_T < obj.tol
                    break
                end
            end

            if iter == obj.max_iter
                warning('SizingLoopL2:no_convergence', ...
                    'Max iterations without convergence. dW=%.2f lbf, dT=%.2f lbf', delta_W, delta_T);
            end

            % Sync prop.T0 with final converged value
            prop.T0 = T_SL;
        end
    end
end
