function [DesignTable_wings, DesignTable_fuselage, DesignTable_propulsion, DesignTable_weights] = Import_Design(DesignName)
%IMPORT_DESIGN Summary of this function goes here
%   Detailed explanation goes here

% FILE FORMAT:
% FILE NAME: design name
% SHEET NAME: geometries/specs (e.g., "wings," "propulsion," "fuselage")

% Load information from Excel sheet
% file_name = "DesignGeometries.xlsx";
% design_name = DesignName; % This will be the SHEET the program checks!
DesignTable_wings = readtable(DesignName, 'Sheet', 'Wings', 'ReadRowNames', true);
DesignTable_fuselage = readtable(DesignName, 'Sheet', 'Fuselage', 'ReadRowNames', true);
DesignTable_propulsion = readtable(DesignName, 'Sheet', 'Propulsion', 'ReadRowNames', true);


% Import weight data (components)
DesignTable_weights = readtable(DesignName, 'Sheet', 'Weights', 'ReadRowNames', true);
% Test for each one callable


end