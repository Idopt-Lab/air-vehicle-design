%% Master Script - Fidelity Level IV
% Written by Casey Chamberlain
% Feb 2nd, 2026
%
% Purpose: Script intended to enable rapid comparison of students'
% preliminary designs.

% Parameters:
% Performance constraints
% Mission segments
% Aircraft specs
%    Geometry
%    Engine

% Outputs:
% Constraint analysis
%    Constraint diagram
%    Optimum design configuration
%         Min TW
%         Optimum W/S
% Weight estimation
%    TOGW
%    Empty
%    Fuel
% Comparison:
%    Design performance
%    Exceeding requirements
%    Cost


% Outputs from the "combination" script:
% High-level parameters: TOGW, wing area, sea level static thrust, fuel
% burn



%% ----------------------------------------------------------------------
% Functional script starts here

%% ----------------------------------------------------------------------
% Utilities
% clear
function Master_Script_IV(Design_Name, Mission, Requirements, Constraints)
% Set up the path
level = "IV"; % Added this to minimize manual changes between fidelity levels
path = cd + "\Level_" + level + "_Fidelity";
addpath(path + "\"); % Adds the "Level_N_Fidelity" folder
addpath(path + "\Constraint_Analysis\")
addpath(path + "\Mission_Analysis\")
addpath(cd + "\Operator\")
addpath(cd + "\Utilities\")
addpath(path + "\Volume_Est\")
addpath(path + "\Weight_Estimation\")
addpath(path + "\Weight_Estimation\Subsystems\")
addpath(path + "\Aerodynamics\")
addpath(path + "\Propulsion\")

% Utilities - what was this supposed to do, again? Ask Sarojini.
% weightestimationfunction = @(a) (a+1);
% aerodynamics = @(aero_est_N)
% propulsion = @(propulsion_est_N)



% Initialize some kind of design object
design = AircraftDesign;
design.Name = Design_Name;
% Load object with design data
% Do the rest of the script...



% Load mission profiles
[missiondata] = Mission_Profiles(Mission);

% Load designs
[design.geom.wings, design.geom.fuselage, design.propulsion, design.weights] = Import_Design(Design_Name);

% design.geom.wings = Designgeo_wings;
% design.geom.fuselage = Designgeo_fuselage;
% design.propulsion = Designgeo_propulsion;
% design.weights = DesignTable_weights;

% Load requirements
[design.requirements] = Import_Requirements(Requirements);

% Load constraints
[design.constraints] = Import_Constraints(Constraints);




%% ----------------------------------------------------------------------
% Get constraint diagram (pass constraints table)
[T0_W0, W0_Sref, optimal_WS, min_TW] = Constraint_Estimates(design.constraints);
% Design diagram outputs: T0/W0, W0/S_ref
% don't produce diagram during optimization



%% ----------------------------------------------------------------------
% Get TOGW, empty weight, fuel burn
[design.WeightResults] = weight_est_IV(missiondata, design.constraints, design.geom.wings, design.geom.fuselage, design.propulsion, min_TW, optimal_WS, design.weights);
% Divorce mission fuel analysis from this

% Future - add state vector (x-bar = [u; v; w; p; q; r; x; y; z; phi;
% theta; psi])

%% ----------------------------------------------------------------------
% Drag polar IV
% [CD0, K] = Drag_Polar_III(S_wr, AR, e);
[design.DragResults] = Drag_Polar_IV(design.geom.wings, design.geom.fuselage,  design.propulsion, design.WeightResults, missiondata, Requirements); % Just call the script


%% ----------------------------------------------------------------------
% Sizing
[S_ref, T0] = Sizing_script(T0_W0, W0_Sref, design.WeightResults.MTOW);
% Sizing outputs: S_ref, T0

% Fuel volume check
[design.internalvolume] = fuelcheck(design.geom.fuselage, design.WeightResults.total_fuel_used, design.geom.wings, design.WeightResults);


%% ----------------------------------------------------------------------
% Final outputs:
% TOGW, wing area, sea level static thrust, fuel burn


% Confirmation output
disp("S_ref: " + S_ref + " ft^2")
disp("T_0: " + T0 + " lbf")
disp("W_0: " + Weight_Results.MTOW + " lbf")
disp("Fuel burned: " + Weight_Results.total_fuel_used + " lbf")
disp("Fuel volume required: " + internalvolume.fuel_required + " gal")
disp("Internal volume est: " + internalvolume.internalvolume + " gal")
disp("CD0 sub: " + DragResults.CD0_sub)
disp("CD0 sup: " + DragResults.CD0_sup)
disp("M_DD: " + DragResults.M_DD)


%% ----------------------------------------------------------------------
% Design comparison
% Score each design's performance relative to the requirements




%% ----------------------------------------------------------------------
% Output scoreboard


end