function [W_TO, beta] = runMissionAnalysis(mission, propulsion, aero, air, W_fixed, AR, S)
% runMissionAnalysis Estimates Takeoff Gross Weight (W_TO) and fuel usage factor beta
%
% Inputs:
%   mission     - Struct with mission segments (Climb, Cruise, Dash, Combat, etc.)
%   propulsion  - Struct with TSFCs for each segment
%   aero        - Struct with aerodynamic data (CD0, e, etc.) for each segment
%   air         - Struct with air data (q, a) for each segment
%   W_fixed     - Fixed weight of payload, crew, structure (lbs)
%   AR          - Aspect ratio
%   S           - Wing area (ft^2)
%
% Outputs:
%   W_TO        - Converged Takeoff Gross Weight
%   beta        - Fuel efficiency factor: 1 - (fuel_used / 2 / W_TO)
    
    % Initialization
    W_TO = 45000;  % Initial guess
    W_fixed = 5100;
    max_iteration = 40;
    S = 104.59; % Commented this out in MATLAB Grader
    tol = 1e-3;

    for iteration = 1:max_iteration
        W_S = W_TO / S;
        total_fuel_used = 0;

        % Segment Calculations
        [W_Takeoff, fuel_used_Takeoff] = segment_takeoff(W_TO);
        total_fuel_used = total_fuel_used + fuel_used_Takeoff;

        [W_Climb, fuel_used_Climb] = segment_climb(W_TO, W_Takeoff, mission.Climb.Mach);
        total_fuel_used = total_fuel_used + fuel_used_Climb;

        [W_Cruise, fuel_used_Cruise] = segment_cruise(W_Climb, W_S, propulsion.Cruise.TSFC, ...
            mission.Cruise.Distance, mission.Cruise.Mach, air.Cruise.a, air.Cruise.q, ...
            aero.Cruise.CD0, aero.Cruise.e, AR, W_TO);
        total_fuel_used = total_fuel_used + fuel_used_Cruise;

        [W_Dash, fuel_used_Dash] = segment_dash(W_Cruise, W_TO, W_S, air.Dash.q, ...
            aero.Dash.CD0, aero.Dash.e, AR, propulsion.Dash.TSFC, ...
            mission.Dash.Distance, mission.Dash.Mach * air.Dash.a);
        total_fuel_used = total_fuel_used + fuel_used_Dash;

        [W_Combat, fuel_used_Combat] = segment_combat(W_Dash, mission.Combat.Time_min, ...
            propulsion.Combat.TSFC, mission.Combat.DropPayload_lb);
        total_fuel_used = total_fuel_used + fuel_used_Combat;

        [W_Cruise2, fuel_used_Cruise2] = segment_cruise(W_Combat, W_S, propulsion.Cruise2.TSFC, ...
            mission.Cruise2.Distance, mission.Cruise2.Mach, air.Cruise2.a, air.Cruise2.q, ...
            aero.Cruise2.CD0, aero.Cruise2.e, AR, W_TO);
        total_fuel_used = total_fuel_used + fuel_used_Cruise2;

        [W_Loiter, fuel_used_Loiter] = segment_loiter(W_TO, W_Cruise2, W_S, ...
            air.Loiter.q, aero.Loiter.CD0, aero.Loiter.e, AR, ...
            mission.Loiter.Time_min, propulsion.Loiter.TSFC);
        total_fuel_used = total_fuel_used + fuel_used_Loiter;

        [W_Landing, fuel_used_Landing] = segment_landing(W_Loiter, W_TO);
        total_fuel_used = total_fuel_used + fuel_used_Landing;

        % Update W_TO
        fuel_fraction = total_fuel_used * 1.06 / W_TO;
        W_TO_new = W_fixed / (1 - fuel_fraction);

        fprintf('Iteration %d: W_TO = %.2f lbs, Fuel Used = %.2f lbs, Fuel Fraction = %.4f\n', ...
            iteration, W_TO, total_fuel_used, fuel_fraction);

        if abs(W_TO_new - W_TO) < tol
            break;
        end

        W_TO = W_TO_new;
    end

    % Output beta
    beta = 1 - (total_fuel_used / (2 * W_TO));

end


