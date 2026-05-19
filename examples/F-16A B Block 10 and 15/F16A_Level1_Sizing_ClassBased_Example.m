% This code was generated via ChatGPT 5.4 ("extended thinking").

%% F-16A Level 1 Sizing Analysis — Class-Based Example
% This live script performs a Level 1 sizing pass for the F-16A example using
% the toolkit classes supplied with the project.
%
% Main objects used:
%   * AircraftDesign
%   * GeometryLevel1
%   * AeroLevel1
%   * PropulsionLevel1
%   * WeightLevel1
%   * MissionAnalysisLevel1
%   * ConstraintAnalysisClass
%   * Requirements
%   * SizingClassLevel1
%
% The script assumes the corresponding class files, import utilities, design
% workbook, requirements table, constraints table, and mission profile are on
% the MATLAB path.

% clear; clc; close all;

%% Project setup
% Set this to the folder containing your classes, import utilities, design
% spreadsheet/workbook, requirements file, constraints file, and mission data.
projectRoot = pwd;
addpath(projectRoot);

% Change these names only if your local files use different names.
designName       = "F-16A Block 50";
requirementsName = "Requirements";
constraintsName  = "Constraints";
missionName      = "CAP";

% Basic class availability check. This catches path/name issues before the
% design object tries to import data.
requiredClasses = [ ...
    "AircraftDesign", ...
    "GeometryLevel1", ...
    "AeroLevel1", ...
    "PropulsionLevel1", ...
    "WeightLevel1", ...
    "F16GeometryLevel1", ...
    "F16AeroLevel1", ...
    "F16PropulsionLevel1", ...
    "F16WeightLevel1", ...
    "F16MissionAnalysisLevel1", ...
    "ConstraintAnalysisClass", ...
    "Requirements", ...
    "F16SizingLevel1"];

for k = 1:numel(requiredClasses)
    assertClassOrFileExists(requiredClasses(k));
end

%% Create the aircraft design object
% AircraftDesign is the project-level object. It imports the design geometry,
% fuselage data, propulsion data, weight data, general aircraft data, and
% requirements reference.

design = AircraftDesign( ...
    designName, ...
    RequirementsName = requirementsName, ...
    ConstraintsName  = constraintsName, ...
    AutoLoad         = true);

% Keep the constraints filename explicit in case the design constructor was
% given a blank or nonstandard value.
if strlength(string(design.constraints_filename)) == 0
    design.constraints_filename = constraintsName;
end

disp("AircraftDesign object created:")
disp(design)

%% Build the Level 1 analysis objects
% These objects are intentionally lower-fidelity than the Level 3 versions.
% They rely on historical estimates, tabulated assumptions, and simple mission
% weight fractions/Breguet-style estimates.

geometry_obj     = F16GeometryLevel1(design);
weight_obj       = F16WeightLevel1(design);
aero_obj         = F16AeroLevel1("jet fighter", geometry_obj, weight_obj);
propulsion_obj   = F16PropulsionLevel1(design);
mission_obj      = F16MissionAnalysisLevel1(missionName);
constraint_obj   = ConstraintAnalysisClass(design);
requirements_obj = Requirements(design);
sizing_obj       = F16SizingLevel1();


% Compute required constraints
constraint_obj.constraint_analysis;

%% Run the project sizing class
% This calls your SizingClassLevel1 method directly. The method returns the
% converged W_TO. In the current class definition, results_table is assigned
% inside the method, but the class itself does not inherit handle, so the table
% may not persist outside the method depending on your inheritance tree.

W_TO_from_sizing_class = sizing_obj.size_aircraft( ...
    design, ...
    geometry_obj, ...
    mission_obj, ...
    weight_obj, ...
    propulsion_obj, ...
    constraint_obj, ...
    requirements_obj, ...
    aero_obj);

% Reconstruct the sizing trace using the same Level 1 objects so the plotting
% and save-back sections have concrete values to read.
[results_table, finalState] = runLevel1SizingTrace( ...
    design, ...
    geometry_obj, ...
    mission_obj, ...
    weight_obj, ...
    propulsion_obj, ...
    constraint_obj, ...
    requirements_obj, ...
    aero_obj);

disp("Persistent Level 1 sizing iteration table:")
disp(results_table)

finalSummary = table( ...
    W_TO_from_sizing_class, ...
    finalState.W_TO_lbf, ...
    finalState.W_empty_lbf, ...
    finalState.W_fixed_lbf, ...
    finalState.W_fuel_lbf, ...
    finalState.fuel_fraction, ...
    finalState.empty_weight_fraction, ...
    finalState.S_ref_ft2, ...
    finalState.S_wet_ft2, ...
    finalState.AR_wetted, ...
    finalState.LDmax, ...
    finalState.T0_lbf, ...
    'VariableNames', { ...
    'SizingClassReturnedWTO_lbf', ...
    'TraceFinalWTO_lbf', ...
    'OEW_lbf', ...
    'FixedWeight_lbf', ...
    'FuelUsed_lbf', ...
    'FuelFraction', ...
    'EmptyWeightFraction', ...
    'WingReferenceArea_ft2', ...
    'WettedArea_ft2', ...
    'WettedAspectRatio', ...
    'LDmax', ...
    'SeaLevelStaticThrust_lbf'});

disp("Final Level 1 sizing summary:")
disp(finalSummary)

figure('Name', 'Level 1 Gross Weight Convergence');
plot(1:height(results_table), results_table.WTO, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Iteration');
ylabel('W_{TO} [lbf]');
title('F-16A Level 1 Gross Weight Convergence');

%% Plot closure error

figure('Name', 'Level 1 Closure Error');
plot(1:height(results_table), results_table.Percent_Diff, '-o', 'LineWidth', 1.5);
grid on;
xlabel('Iteration');
ylabel('Percent Difference [%]');
title('F-16A Level 1 Sizing Closure Error');

%% Plot final weight breakdown

weightBreakdown = table( ...
    categorical(["OEW"; "Fuel Used"; "Fixed Weight"]), ...
    [finalState.W_empty_lbf; finalState.W_fuel_lbf; finalState.W_fixed_lbf], ...
    'VariableNames', {'Component', 'Weight_lbf'});

figure('Name', 'Level 1 Final Weight Breakdown');
bar(weightBreakdown.Component, weightBreakdown.Weight_lbf);
grid on;
ylabel('Weight [lbf]');
title('F-16A Level 1 Final Weight Breakdown');

%% Save results into the AircraftDesign object
% AircraftDesign is a handle class, so these assignments persist on the design
% object during this MATLAB session.

design.WeightResults.Level1SizingTable = results_table;
design.WeightResults.Level1Summary     = finalSummary;
design.WeightResults.W_TO              = finalState.W_TO_lbf;
design.WeightResults.OEW               = finalState.W_empty_lbf;
design.WeightResults.FuelUsed          = finalState.W_fuel_lbf;

design.AeroResults.Level1.LDmax         = finalState.LDmax;
design.AeroResults.Level1.AR_wetted     = finalState.AR_wetted;
design.AeroResults.Level1.S_wet         = finalState.S_wet_ft2;

design.PropulsionResults.Level1.T0      = finalState.T0_lbf;
design.PropulsionResults.Level1.TSFC    = propulsion_obj.TSFC;

%% Local helper functions

function assertClassOrFileExists(className)
    className = string(className);
    existsAsClass = exist(char(className), 'class') == 8;
    existsAsFile  = exist(char(className + ".m"), 'file') == 2;

    if ~(existsAsClass || existsAsFile)
        error("Required class/file '%s' was not found on the MATLAB path. Check projectRoot/addpath.", className);
    end
end

function missionSummary = summarizeMissionData(missiondata)
    segmentNames = fieldnames(missiondata);
    rows = strings(0, 1);
    mach = nan(0, 1);
    altitude = nan(0, 1);
    range = nan(0, 1);
    time = nan(0, 1);
    payloadDrop = nan(0, 1);

    for i = 1:numel(segmentNames)
        name = segmentNames{i};
        segment = missiondata.(name);

        rows(end+1, 1) = string(name);
        mach(end+1, 1) = getFieldOrNaN(segment, 'MachNumber');
        altitude(end+1, 1) = getFieldOrNaN(segment, 'Altitudeft');
        range(end+1, 1) = getFieldOrNaN(segment, 'Rangeft');
        time(end+1, 1) = getFieldOrNaN(segment, 'Timemin');
        payloadDrop(end+1, 1) = getFieldOrNaN(segment, 'PayloadDroplbf');
    end

    missionSummary = table(rows, mach, altitude, range, time, payloadDrop, ...
        'VariableNames', {'Segment', 'MachNumber', 'Altitude_ft', 'Range_ft', 'Time_min', 'PayloadDrop_lbf'});
end

function value = getFieldOrNaN(s, fieldName)
    if isstruct(s) && isfield(s, fieldName)
        value = s.(fieldName);
    elseif istable(s) && any(strcmp(s.Properties.VariableNames, fieldName))
        value = s.(fieldName);
    else
        value = NaN;
    end

    if ~isscalar(value) || ~isnumeric(value)
        value = NaN;
    end
end

function S_wet = getLevel1SWet(aircraft_type, W_TO)
    % Use the shared Level 1 geometry utility used by the F-16 wrapper class.
    % If the generic helper uses a different aircraft-type spelling locally,
    % retry with the normalized F-16 label.
    aircraft_type = string(aircraft_type);

    try
        S_wet = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
    catch
        S_wet = GeometryLevel1.get_design_S_wet("jet fighter", W_TO);
    end
end

function [results_table, finalState] = runLevel1SizingTrace(design, geometry_obj, mission_obj, weight_obj, propulsion_obj, constraint_obj, requirements_obj, aero_obj)
    %#ok<INUSD> requirements_obj is kept here to preserve the same object signature as F16SizingLevel1.
    % This trace intentionally mirrors F16SizingLevel1.size_aircraft(...)
    % statement-for-statement so the trace table matches the sizing-class
    % iteration history. Do not recompute Level 1 wetted area or refresh
    % aero_obj.LD_max here; F16SizingLevel1 does not do those operations.

    weight_obj.W_fixed = mission_obj.missiondata.Startup.PayloadFixedlbf;

    W_S = constraint_obj.optimal_WS;
    W_TO = weight_obj.W_TO_guess;
    weight_obj.W_TO = W_TO;
    tol = 1e-3;
    max_iteration = 40;
    results = [];
    T_W = constraint_obj.min_TW;

    for iteration = 1:max_iteration %#ok<NASGU>
        geometry_obj.mainwings.S_ref = W_TO / W_S;

        propulsion_obj.T0 = T_W * W_TO;

        [weight_obj.total_fuel_used, weight_obj.fuel_fraction] = mission_obj.get_mission_fuel( ...
            constraint_obj, ...
            design, ...
            geometry_obj, ...
            propulsion_obj, ...
            weight_obj, ...
            aero_obj);

        weight_obj.OEW = weight_obj.get_OEW(design.type, W_TO);
        weight_obj.OEW_frac = weight_obj.OEW / weight_obj.W_TO;

        W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW;
        difference = W_TO_new - weight_obj.W_TO;
        percent_diff = 100 * difference / weight_obj.W_TO;

        results(end+1, :) = [ ...
            weight_obj.W_TO, ...
            weight_obj.W_fixed, ...
            weight_obj.fuel_fraction, ...
            weight_obj.OEW_frac, ...
            weight_obj.OEW, ...
            W_TO_new, ...
            difference, ...
            percent_diff]; %#ok<AGROW>

        if abs(difference) < tol
            break;
        end

        weight_obj.W_TO = W_TO_new;
        W_TO = W_TO_new;
        geometry_obj.mainwings.S_ref = geometry_obj.mainwings.S_ref; %#ok<ASGSL>
    end

    results_table = array2table(results, 'VariableNames', { ...
        'WTO', ...
        'W_fixed', ...
        'Fuel_fraction', ...
        'Empty_weight_fraction', ...
        'Empty_weight', ...
        'WTO_new', ...
        'Difference', ...
        'Percent_Diff'});

    last = results_table(end, :);

    finalState = struct();
    % Match the sizing function's return behavior. F16SizingLevel1 returns
    % the current W_TO value; when convergence triggers, that value is the
    % final row's WTO, not WTO_new.
    finalState.W_TO_lbf = last.WTO;
    finalState.W_empty_lbf = last.Empty_weight;
    finalState.W_fixed_lbf = last.W_fixed;
    finalState.W_fuel_lbf = weight_obj.total_fuel_used;
    finalState.fuel_fraction = last.Fuel_fraction;
    finalState.empty_weight_fraction = last.Empty_weight_fraction;
    finalState.S_ref_ft2 = geometry_obj.mainwings.S_ref;
    finalState.S_wet_ft2 = scalarOrNaN(geometry_obj.design.S_wet);
    finalState.AR_wetted = scalarOrNaN(aero_obj.AR_wet);
    finalState.LDmax = scalarOrNaN(aero_obj.LD_max);
    finalState.T0_lbf = propulsion_obj.T0;
end

function value = scalarOrNaN(value)
    if isempty(value) || ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
        value = NaN;
    end
end


