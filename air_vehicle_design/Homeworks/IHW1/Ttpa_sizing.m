classdef SizingLoop
%SIZINGLOOPL1  Level-1 takeoff-gross-weight sizing loop.
%
%   Single-state (W_TO) fixed-point iteration [martins_slides_data.md
%   Slide 6]: the design diagram is consulted ONCE, before the loop, and
%   supplies the (W0/Sref, T0/W0) design point. Each iteration re-derives
%   S_ref and T_SL from those fixed ratios and the current W_TO, then
%   closes weight with the TOGW step [metabook_data.md Ch. 2 "TOGW
%   Iteration Algorithm (Algorithm 1)"; Raymer 6th ed. Eq. 3.4] via
%   SizingSteps.togw_update.
%
%   Flat orchestrator, not a discipline: constructor-injected with six
%   built objects, mutated in place (handle semantics). obj.aero is stored
%   but never called directly; the mission/constraint objects read it live.
%   Nothing is cached (recompute-on-read).

    % TODO (8/3/2026): Remember to remove extra documentation during final
    % pass. Should store the decisions and rationalization in some kind of
    % archive later. Include timestamp of comment creation.
    properties (SetAccess = private)
        aero    % (1,1) AerodynamicsBase
        prop    % (1,1) PropulsionBase
        wts     % (1,1) WeightsBase
        miss    % (1,1) MissionAnalysisBase
    end

    methods

        function obj = SizingLoopL1(aero, prop, wts, miss)
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                wts  (1,1) WeightsBase
                miss (1,1) MissionAnalysisBase
            end
            obj.aero = aero;
            obj.prop = prop;
            obj.wts  = wts;
            obj.miss = miss;
        end

        function result = run(obj, W_TO_guess, opts)




%% Function: Main Mission Analysis
function [W_TO_final, beta, results_table, fuel_fraction,...
    empty_weight_fraction, empty_weight, fuel_burned, segment_weight, segment_wf]...
    = missionAnalysis(mission, propulsion, air, constant, W_TO, WTO_S)

    
    W_payload = constant.W_fixed; 
    tol = 0.1;
    max_iteration = 25;
    results = [];
    
    % ---------------------------------------------------------------------
    % Iteration Loop
    for ii = 1:max_iteration       
                
        [W1, f1, WF1] = segment_takeoff(W_TO);
        
        [W2, f2, WF2] = segment_climb(W1);

        [W3, f3, WF3] = segment_cruise(W2,...
            propulsion.Cruise, mission.Cruise, constant);

        [W4, f4, WF4] = segment_descent(W3);

        [W5, f5, WF5] = segment_climb(W4);

        [W6, f6, WF6] = segment_loiter(W5, W_TO, WTO_S,...
            propulsion.Loiter, mission.Loiter, air.Loiter, constant);

        [W7, f7, WF7] = segment_descent(W6);

        [W8, f8, WF8] = segment_landing(W7);

        
        fuel_burned(ii, :) = [f1, f2, f3, f4, f5, f6, f7, f8];
        segment_weight(ii, :) = [W_TO, W1, W2, W3, W4, W5, W6, W7, W8];
        segment_wf(ii, :) = [WF1, WF2, WF3, WF4, WF5, WF6, WF7, WF8];

        fuel_fraction = sum(fuel_burned(ii,:))* 1.06 / W_TO; % 1.06 accounts for trapped/unusable fuel
        empty_weight_fraction = 0.911 * W_TO^(-0.053); % Nicolai's Light Prop Airplane WF
        empty_weight = empty_weight_fraction * W_TO;
        fuel_weight = fuel_fraction*W_TO;

        W_TO_new = W_payload / (1 - fuel_fraction - empty_weight_fraction);
        difference = W_TO_new - W_TO;
        percent_diff = 100 * difference / W_TO;

        results(end+1, :) = [W_TO, empty_weight, fuel_weight, empty_weight_fraction, fuel_fraction, W_TO_new, difference, percent_diff];

        if abs(difference) < tol
            break;
        end

        W_TO = W_TO_new;
        % disp(fuel_burned)
    end

    beta = 1 - (sum(fuel_burned) / (2 * W_TO));
    W_TO_final = W_TO;
    results_table = array2table(results, 'VariableNames', {'W_TO', 'Empty_weight', 'Fuel_weight', 'Empty_weight_fraction','Fuel_fraction', 'WTO_new', 'Difference', 'Percent_Diff'});
end

%% Supporting Functions
% Compute L/D ratio
function [LD_ratio] = compute_LD_ratio(CD0, K)
    LD_ratio = 1/(2*sqrt(CD0*K)); % L/D_max estimation
end

% Simplified WF calculation function
function [fuel_used, W_out] = simple_WF(WF, W_in)
    fuel_used = (1 - WF) * W_in;
    W_out = W_in * WF;
end

%% Segment Functions 
% Takeoff
function [W_out, fuel_used, WF] = segment_takeoff(W_in)
    % Includes Startup, Taxi and Takeoff
    WF = 0.984; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Climb
function [W_out, fuel_used, WF] = segment_climb(W_in)
    WF = 0.990; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Cruise
function [W_out, fuel_used, WF] = segment_cruise(W_in, propulsion, mission, constant)
    range = mission.Distance*1.15077945; % nm -> mi
    LD = compute_LD_ratio(constant.CD0, constant.k1); 
    WF = exp(-range*propulsion.C_bhp/(375*propulsion.eta_p*LD)); % Distance must be in MILES
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Descent
function [W_out, fuel_used, WF] = segment_descent(W_in)
    WF = 0.992; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Loiter
function [W_out, fuel_used, WF] = segment_loiter(W_in, W_TO, WTO_S, propulsion, mission, air, constant)
    % -- VERIFY THAT INPUTS MATCH UNITS -- %
    time = mission.Time_min/60; %min -> hr 
    % LD = compute_LD_ratio(air.q, constant.CD0, W_in, W_TO, WTO_S, constant.e, constant.AR);
    LD = 0.866 * compute_LD_ratio(constant.CD0, constant.k1); % not at L/D max
    WF = exp(-time*air.V*propulsion.C_bhp/(LD*550*propulsion.eta_p)); % Velocity must be in ft/s and time in Hrs
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

% Landing
function [W_out, fuel_used, WF] = segment_landing(W_in)
    % Includes: Landing, Taxi and Shutdown
    WF = 0.992; % Roskam Part 1 Table 2.2
    [fuel_used, W_out] = simple_WF(WF, W_in);
end

