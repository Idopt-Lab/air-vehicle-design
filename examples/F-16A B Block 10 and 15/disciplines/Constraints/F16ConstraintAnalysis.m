classdef F16ConstraintAnalysis < ConstraintBase
    % F-16 constraint analysis using Brandt-style master equation.
    %
    % Implements the constraint diagram method: sweeps W_TO/S_ref and
    % computes the required T_SL/W_TO for each performance constraint.
    % optimal_point returns the minimum T/W that satisfies all constraints.
    %
    % Master equation (from Brandt Ch 2):
    %   T0/W0 = (beta/alpha) * [q*CD0/(beta*W0S) + K*n²*(beta*W0S)/q + Ps/V]
    %
    % where:
    %   alpha   = thrust_lapse(state) = T_available/T0
    %   beta    = W/W_TO at constraint condition (weight fraction)
    %   W0S     = W_TO/S_ref (takeoff wing loading being swept)
    %   q, V    = from AircraftState at constraint alt/Mach
    %   CD0, K  = from aero.drag_polar(state)
    %   n       = load factor
    %   Ps      = specific excess power (ft/s)
    %
    % Takeoff is evaluated via balanced-field distance formula.
    % Landing is a W/S upper bound (no T/W curve).

    properties
        W_S_range   = 20:2:180   % W_TO/S_ref sweep (psf)
        beta_perf               % weight fraction at performance conditions
        conditions              % array of constraint condition structs
        takeoff                 % takeoff constraint parameters
        landing                 % landing constraint parameters
    end

    methods
        function obj = F16ConstraintAnalysis(geom_json)
            obj.beta_perf = geom_json.constraints.beta_perf;

            % Build conditions array from JSON.
            % Each condition field is a 1×N struct array (N = W/S sweep points);
            % all rows share the same flight condition, so take index (1).
            cond_names = fieldnames(geom_json.constraints.conditions);
            obj.conditions = struct([]);
            for i = 1:numel(cond_names)
                c = geom_json.constraints.conditions.(cond_names{i})(1);
                obj.conditions(i).name    = cond_names{i};
                obj.conditions(i).alt_ft  = c.alt_ft;
                obj.conditions(i).mach    = c.mach;
                obj.conditions(i).n       = c.n;
                obj.conditions(i).pct_AB  = c.pct_AB;
                obj.conditions(i).Ps_fps  = c.Ps_fps;
            end

            obj.takeoff = geom_json.constraints.takeoff(1);
            obj.landing = geom_json.constraints.landing(1);
        end

        function result = optimal_point(obj, aero, prop)
            W_S_range = obj.W_S_range;
            n_ws      = numel(W_S_range);
            n_con     = numel(obj.conditions);
            TW_table  = zeros(n_con, n_ws);

            % Performance constraints
            for i = 1:n_con
                cond  = obj.conditions(i);
                state = AircraftState(cond.alt_ft, cond.mach);
                polar = aero.drag_polar(state);
                CD0   = polar.CD0;
                K     = polar.K1 + polar.K2;  % total polar coefficient
                alpha = prop.thrust_lapse(state);
                q     = state.q;
                V     = state.V;
                n     = cond.n;
                Ps    = cond.Ps_fps;
                beta  = obj.beta_perf;

                for j = 1:n_ws
                    W0S = W_S_range(j);
                    TW_table(i,j) = F16ConstraintAnalysis.master_eq(beta, alpha, q, V, CD0, K, n, Ps, W0S);
                end
            end

            % Takeoff constraint
            TO        = obj.takeoff;
            state_to  = AircraftState(TO.alt_ft, TO.mach_liftoff);
            polar_to  = aero.drag_polar(state_to);
            CLmax_to  = aero.CLmax(state_to);
            alpha_to  = prop.thrust_lapse(state_to);
            TW_takeoff = zeros(1, n_ws);
            for j = 1:n_ws
                W0S = W_S_range(j);
                TW_takeoff(j) = F16ConstraintAnalysis.takeoff_eq(W0S, CLmax_to, polar_to.CD0, TO, alpha_to);
            end

            % Landing constraint: W/S upper bound.
            % Formula from JSON note: WS_max = S_land*rho*g*(mu_brake*CLmax_land + 0.83*CD0_land)/k_app^2
            land      = obj.landing;
            CLmax_ld  = aero.CLmax(AircraftState(0, 0.1));
            [~, ~, ~, rho_sl] = atmosisa(0);
            rho_sl_eng = rho_sl * 0.00194032033;  % kg/m³ → slug/ft³
            g_ft     = 32.174;
            mu_brake = 0.50;   % effective wheel-brake coefficient for fighter on dry runway
            k_app    = 1.30;   % approach at 1.3 × Vstall
            W_S_land = rho_sl_eng * g_ft * land.S_land_ft * ...
                       (mu_brake * CLmax_ld + 0.83 * land.CDx) / k_app^2;
            W_S_land = min(W_S_land, 200);

            % Best T/W: maximum of all constraints, T/W minimized over W/S
            TW_all     = max(TW_table, [], 1);
            TW_all     = max([TW_all; TW_takeoff], [], 1);
            TW_all(W_S_range > W_S_land) = Inf;

            [min_TW, idx] = min(TW_all);
            result.W_S = W_S_range(idx);
            result.T_W = min_TW;
        end
    end

    methods (Static)

        function TW = master_eq(beta, alpha, q, V, CD0, K, n, Ps, W0S)
            % Brandt constraint master equation: T0/W0 required.
            if V == 0; V = 1e-6; end
            betaW0S  = beta * W0S;
            TW = (beta/alpha) * (q*CD0/betaW0S + K*n^2*betaW0S/q + Ps/V);
        end

        function TW = takeoff_eq(W0S, CLmax, CD0, TO, alpha)
            % Simplified Brandt takeoff constraint.
            %   W0S      = W_TO/S_ref (psf)
            %   CLmax    = maximum lift coefficient
            %   CD0      = parasite drag (including TO flap/gear CDx)
            %   TO       = takeoff struct from JSON
            %   alpha    = thrust lapse at liftoff Mach
            g         = 32.174;
            [~, ~, ~, rho_sl] = atmosisa(0);
            rho_sl_eng = rho_sl * 0.00194032033;
            mu        = 0.04;   % rolling friction on concrete
            CDx       = TO.CDx;
            S_TO      = TO.S_TO_ft;
            V_liftoff = TO.mach_liftoff * 1116.45;  % a_SL in ft/s
            q_lo      = 0.5 * rho_sl_eng * V_liftoff^2;

            % Ground roll + rotation (Raymer Eq 17.1 simplified):
            %   T/W0 = beta² * V_lo² / (2*g*S_TO) + 0.7*(CD0+CDx)/CLmax + 0.7*mu
            TW = (V_liftoff^2 / (2*g*S_TO)) * (W0S/(q_lo*CLmax)) + ...
                 0.7*(CD0 + CDx)/CLmax + 0.7*mu;
            TW = TW / alpha;
        end

    end

end
