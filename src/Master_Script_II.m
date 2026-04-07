%% This script is for combining Homework 1 and 2 into a single callable MATLAB script.
% Arguments: Aircraft, mission info, constraints
% Outputs: MTOW iteration (mission analysis), sizing info (constraints)

% Written by Casey Chamberlain
% Feb 2nd, 2026

% Base the program design on what's in slide 6 of powerpoint
% "13-sizing_refinement.pptx."


% Outputs from the "combination" script:
% High-level parameters: TOGW, wing area, sea level static thrust, fuel
% burn

function Master_Script_II(Design, Mission, Requirements, Constraints)



%% ----------------------------------------------------------------------
%% utilities
level = "II"; % Added this to minimize manual changes between fidelity levels
path = cd + "\Level_" + level + "_Fidelity";
addpath(path + "\"); % Adds the "Level_N_Fidelity" folder
addpath(path + "\Constraint_Analysis\")
addpath(path + "\Mission_Analysis\")
addpath(cd + "\Operator\")
addpath(cd + "\Utilities\")
addpath(path + "\Weight_Estimation\")
addpath(path + "\Aerodynamics\")


% Utilities - what was this supposed to do, again?
% weightestimationfunction = @(a) (a+1);
% aerodynamics = @(aero_est_N)
% propulsion = @(propulsion_est_N)

% Load mission profiles
[missiondata] = Mission_Profiles(Mission);

% Load designs
[Designgeo_wings, Designgeo_fuselage, Designgeo_propulsion, DesignTable_weights] = Import_Design(Design);

% Load requirements
[Requirements] = Import_Requirements(Requirements);

% Load constraints
[Constraints] = Import_Constraints(Constraints);


%% ----------------------------------------------------------------------


% Get constraint diagram
[T0_W0, W0_Sref, optimal_WS, min_TW] = Constraint_Estimates(Constraints);
% Design diagram outputs: T0/W0, W0/S_ref


%% ----------------------------------------------------------------------
% Get TOGW, empty weight, fuel burn
% homework1_refsol_fidelity_II; % Placeholder (empty weight I, MTOW iteration, fuel fraction already incorporated into script)
[Weight_Results] = weight_est_II(missiondata, Constraints, Designgeo_wings, Designgeo_fuselage, Designgeo_propulsion, min_TW, optimal_WS, DesignTable_weights);

%% ----------------------------------------------------------------------
% Design diagram
[~, ~, ~, rho] = atmosisa(0); % Assume we land at sea level
rho = rho*0.00194032033;
rho_sl = rho;
CL_maxL = 1.4; % From Brandt, max CL during landing (idfk) (I guessed)
s_a = 450; % from raymer, assuming stol 7 deg glideslope.
s_L = 80*(Weight_Results.W_Landing/Designgeo_wings.Main("Planform area (ft^2)"))/((rho/rho_sl)*(CL_maxL)) + s_a;
% [T0_W0, W0_Sref] = Design_Diagram(CD0, K, s_L, CL_maxL, S_ref); % This seems like the constraint diagram. Code likely be similar.

% Initialize some variables
% c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
% d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
% S_wet = 10^(c) * MTOW^(d); % ft^2
S_wr = Weight_Results.S_wet/Weight_Results.S_ref; % S_wet_reference ratio

% Drag polar IV
% [CD0, K] = Drag_Polar_III(S_wr, AR, e);
[DragResults] = Drag_Polar_II(Designgeo_wings, Designgeo_fuselage, Designgeo_propulsion, Weight_Results); % Just call the script


%% ----------------------------------------------------------------------
% Sizing
[S_ref, T0] = Sizing_script(T0_W0, W0_Sref, Weight_Results.MTOW);
% Sizing outputs: S_ref, T0




%% ----------------------------------------------------------------------
% Final outputs:
% TOGW, wing area, sea level static thrust, fuel burn


% Confirmation output
disp("S_ref: " + S_ref + " ft^2")
disp("T_0: " + T0 + " lbf")
disp("W_0: " + Weight_Results.MTOW + " lbf")
disp("Fuel burned: " + Weight_Results.total_fuel_used + " lbf")


%% ----------------------------------------------------------------------
% Design comparison
% Score each design's performance relative to the requirements




%% ----------------------------------------------------------------------
% Output scoreboard


end