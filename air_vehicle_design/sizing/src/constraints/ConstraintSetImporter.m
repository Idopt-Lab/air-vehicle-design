classdef ConstraintSetImporter
%CONSTRAINTSETIMPORTER  Reads a constraint-conditions table from a
%   Constraints.xlsx-style workbook.
%
%   Generic Layer-1 utility: any aircraft's constraint requirements (one row
%   per point-performance/field condition -- altitude, Mach, weight fraction,
%   load factor, specific excess power, field length, friction coefficient --
%   see sizing/docs/subplans/06_constraint_analysis.md's F-16 Constraint
%   Conditions tables for the column meanings) can be read with this, as
%   long as the sheet follows the same row/column layout the F-16
%   Constraints.xlsx uses (examples/F16A/Constraints.xlsx). Aircraft-specific
%   wiring of each row into a concrete constraint object (ThrustConstraint,
%   TakeoffConstraint, LandingConstraint) is a Layer-2 concern -- see
%   examples/F16A/F16ConstraintSet.m.
%
%   Deliberately thin: unlike the legacy Import_Constraints.m/ConstraintUtils.m
%   this framework's predecessor used, this does NOT compute or append
%   atmosphere columns (temperature, density, dynamic pressure, ...) --
%   AircraftState already derives those from altitude+Mach with its own
%   citations (Mattingly Eq. 2.52), so recomputing them here would duplicate
%   that logic. This class only reads the raw per-condition requirement
%   columns as they appear in the workbook.

    methods (Static)

        function T = read(filepath, sheet)
        %READ  Read one sheet of a constraints workbook into a table,
        %   indexed by condition name (row names).
        %   filepath -- path to the .xlsx workbook.
        %   sheet    -- sheet name, e.g. "Constraints".
            arguments
                filepath (1,1) string
                sheet    (1,1) string
            end
            T = readtable(filepath, 'Sheet', sheet, 'ReadRowNames', true, ...
                'VariableNamingRule', 'modify');
        end

    end

end
