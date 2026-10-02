function [hist, converged, state] = sizing_mainloop(obj, opts)
%SIZING_MAINLOOP  Iterate sizing passes until weight and power stop moving.
%
%   [hist, converged, state] = sizing_mainloop(obj, opts)
%
%   Inputs
%     obj   discipline bundle from ttpa_disciplines. MUTATED: on return it
%           holds the converged airplane (P_SL and S_ref written).
%     opts  struct
%             .W0 .P0 .S0   starting guesses [lbf, hp, ft^2]
%             .WS_sweep     wing-loading sweep for the constraint analysis
%             .tol          relative tolerance on BOTH W and P
%             .max_iter     pass limit
%             .relax        under-relaxation factor w, 0 < w <= 1
%   Outputs
%     hist       1xN struct array, one sizing_pass row per pass
%     converged  true if both residuals fell below tol
%     state      struct .W0 .P0 .S0 (the returned airplane) and .n_iter
%
%   THE ITERATION
%
%     repeat
%        row = sizing_pass(obj, W0, P0, S0, WS_sweep)
%        stop if  |W_new - W0|/W_new < tol  AND  |P_new - P0|/P_new < tol
%        otherwise relax all three states:  x <- x + w (x_new - x)
%
%   Why BOTH tests: W and P are coupled but distinct states. A weight that
%   has settled while the engine is still changing is not a sized airplane.
%   S_ref is not tested separately - it is W0/(W/S), so it settles when W0
%   and the corner do - but it is relaxed like the other two.
%
%   Why relax at all: the closure divides by 1 - W_f/W0 - OEW/W0, a small
%   number that moves fast with W0, so a full step (w = 1) overshoots by
%   roughly 2.5 times per pass and diverges. Relaxation changes the PATH,
%   never the answer: at the fixed point x_new = x, so the relaxed step is
%   x for any w.

    W0 = opts.W0;
    P0 = opts.P0;
    S0 = opts.S0;

    converged = false;

    for iter = 1:opts.max_iter
        % --- Milestone 1: one pass from the current states ---------------
        row      = ;
        row.iter = iter;
        if iter == 1
            hist = row;
        else
            hist(iter) = row;
        end

        % --- Milestone 2: stop when BOTH residuals are below opts.tol ----
        %   On convergence take the pass's own answers - no relaxation -
        %   set converged = true, and break.


        % --- Milestone 3: otherwise relax all three states ---------------
        W0 = ;
        P0 = ;
        S0 = ;
    end

    % --- Milestone 4: leave the bundle holding the airplane returned -----


    state = struct('W0', W0, 'P0', P0, 'S0', S0, 'n_iter', iter);

    if ~converged
        warning('sizing_mainloop:notConverged', ...
            ['The main loop did not close in %d passes at relaxation %.2f. ', ...
             'Last W_TO = %.1f lbf, residuals %.2e (weight), %.2e (power).'], ...
            opts.max_iter, opts.relax, W0, hist(end).res_W, hist(end).res_P);
    end
end
