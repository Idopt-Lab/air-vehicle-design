%% Constraint_Estimates
% Reference Solution - Homework 2
% clear; clc; close all; % Comment out for Grader version

%% -------------------------------------------
% Load mission inputs and addt'l funcs
% thisFolder   = fileparts(mfilename('fullpath'));
% parentFolder = fileparts(thisFolder);
% %dataPath     = fullfile(parentFolder, 'F16', 'mission_inputs.mat');
% load("mission_inputs.mat");  % Loads: constraints, aero_constraints, thrust, TO, Landing

%% -------------------------------------------
% Added by Casey Chamberlain
% Load additional aircraft data from HW1&2 merge
% Landing.Distance = s_L;


function [T0_W0, W0_Sref, optimal_WS, min_TW] = Constraint_Estimates(Constraint_Table)

%% -------------------------------------------
% Main Execution
Wto_S_range = 20:7:160;

% Extract constraint names from constraint table
% constraintNames = {'MxMach', 'Cruise', 'MaxAlt', 'CmbtTm1', 'CmbtTm2', 'Ps'};
% Return name from each row
constraintNames = Constraint_Table.Row;
for i=1:length(Constraint_Table.Row)
     constraintNames{i} = string(constraintNames{i});
end

     %% -------------------------------------------
     % Extract information from Constraint_Table
     % Values should emerge from calculations
     CD0_constraints = Constraint_Table(:, "CD0");
     e_constraints = Constraint_Table(:, "e");
     q_constraints = Constraint_Table(:, "q (lbf/ft^2)");
     V_constraints = Constraint_Table(:, "V (ft/s)");
     K1_constraints = Constraint_Table(:, "K1");
     PS_constraints = Constraint_Table(:, "PS_ft_s_");
     aero_constraints = [CD0_constraints, e_constraints, q_constraints, V_constraints, K1_constraints, PS_constraints];

     thrust1 = Constraint_Table(:, "alpha_dry");
     thrust2 = Constraint_Table(:, "AB_");
     thrust3 = Constraint_Table(:, "throttleLapse");
     thrust = [thrust1, thrust2, thrust3]; % I could make this part more modular. How? Figure that out later.

     TO = Constraint_Table("Takeoff",:);

     %% -------------------------------------------
     % Create thrust loading table
     [TW_table, T_Wto_takeoff] = createThrustLoadingTable(Constraint_Table, aero_constraints, thrust, Wto_S_range, constraintNames, TO);

     % Solve for optimal W/S and T/W
     [optimal_WS, min_TW] = solveOptimalPoint(TW_table, T_Wto_takeoff, Wto_S_range);
     optimal_WS;
     min_TW;

     % Generate "landing" struct/table
     Landing = Constraint_Table("Landing",:);

     % Compute landing W/S limit
     Wto_S_landing = landing_constraint(Landing);

     % Estimate cost
     % MTOW_range = Wto_S_range.*S_ref;
     % Cost_est = 10.^(3.3191+0.8043*log(MTOW_range));

     % Add current configuration point - weight and thrust output of sizing
     % script


     % Plot full diagram
     plotConstraintDiagram(Wto_S_range, TW_table, T_Wto_takeoff, Wto_S_landing, optimal_WS, min_TW, constraintNames);

     % Display table in GUI
     showResultTable(TW_table, constraintNames, Wto_S_range);

     % % For MATLAB grader only:
     % MaxMach = TW_table(1,:);
     % Cruise = TW_table(2,:);
     % MaxAlt = TW_table(3,:);
     % CmbtTrn1 = TW_table(4,:);
     % CmbtTrn2 = TW_table(5,:);
     % Ps = TW_table(6,:);
     % Takeoff = T_Wto_takeoff;
     % Landing = Wto_S_landing;

     % Verify that these are EXACTLY what Sarojini wants. Confirm intentions,
     % then validate data.
     T0_W0 = min_TW;
     W0_Sref = optimal_WS;

end