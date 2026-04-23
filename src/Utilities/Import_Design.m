function [DesignTable_wings, DesignTable_fuselage, DesignTable_propulsion, DesignTable_weights, DesignTable_general] = Import_Design(DesignName)
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

% Import general design information.
general_raw = readcell(DesignName, 'Sheet', 'General', 'Range', 'C6:D20');

DesignTable_general = struct();

for i = 1:size(general_raw, 1)
     key = general_raw{i, 1};
     value = general_raw{i, 2};

     if isempty(key)
          break
     end
     if ismissing(key)
          break
     end

     key = matlab.lang.makeValidName(string(key));

     if isstring(value) || ischar(value)
          value = erase(string(value), '"');
     end

     DesignTable_general.(key) = value;
end

% Import weight data (components)
DesignTable_weights = readtable(DesignName, 'Sheet', 'Weights', 'ReadRowNames', true);
% Test for each one callable

% THESE ARE STRUCTS NOW
DesignTable_wings = tableToNestedStruct(DesignTable_wings, Orientation="variables");
DesignTable_fuselage = tableToNestedStruct(DesignTable_fuselage, Orientation="variables");
DesignTable_propulsion = tableToNestedStruct(DesignTable_propulsion, Orientation="rows");
DesignTable_weights = tableToNestedStruct(DesignTable_weights, Orientation="variables");

end