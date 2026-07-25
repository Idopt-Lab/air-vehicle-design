classdef F16ConstraintSet
%F16CONSTRAINTSET  Builds the F-16's 9 point-performance/field/stall
%   constraint objects: 8 from examples/F16A/Constraints.xlsx, plus a Stall
%   condition not yet present in that workbook (see STALL_MACH below).
%
%   Layer-2 (aircraft-specific) wiring: reads the F-16's constraint
%   conditions (altitude, Mach, weight fraction, load factor, specific
%   excess power for the 6 point-performance rows; field length, friction
%   coefficient for the 2 field rows) via ConstraintSetImporter, then
%   instantiates the matching generic Layer-1 constraint class per row --
%   ThrustConstraint (Mattingly Master Equation) for every row except
%   Takeoff/Landing, TakeoffConstraint/LandingConstraint (ground-roll
%   equations) for those two -- wired to the F-16 aero/prop discipline
%   objects for the requested fidelity level. A 9th constraint, Stall
%   (StallConstraint), is appended directly rather than read from the sheet
%   (see STALL_MACH's comment for why).
%
%   See sizing/docs/subplans/06_constraint_analysis.md, "F-16 Constraint
%   Conditions" tables, for the condition data; the constraint equations
%   themselves are cited in ThrustConstraint.m/TakeoffConstraint.m/
%   LandingConstraint.m/StallConstraint.m, not repeated here.
%
%   NOT WIRED FROM THE SHEET (intentional, documented gaps -- out of scope
%   here):
%     AB_    -- percent afterburner. PropulsionBase.thrust_lapse always
%               returns the AB-basis lapse regardless of condition; there is
%               no mil/dry-basis alternative to select (see
%               TestThrustConstraint.m's "NOTE ON ALPHA BASIS" header).
%     Vstall -- would-be k_TO/k_L touchdown/liftoff speed margins. The sheet
%               currently disagrees with TakeoffConstraint/LandingConstraint's
%               documented defaults (k_TO=1.2, k_L=1.3, per subplan 06's
%               Field Constraints table) -- Takeoff's Vstall=1.3, Landing's
%               is blank -- so this class keeps those classes' own defaults
%               rather than reading a value that may not be finalized.

    properties (Constant, Access = private)
        %STALL_MACH  Mach number of the F-16 stall-speed requirement, sea
        %   level [Brandt F-16A.xls, "Ps" sheet, cell B10 -- see F16Baseline.m's
        %   b.constraints.stall.mach, same value]. examples/F16A/Constraints.xlsx
        %   has no Stall row yet (unlike the other 8 conditions), so this is
        %   hardcoded here rather than read via ConstraintSetImporter; flag
        %   for spreadsheet backfill.
        STALL_MACH = 0.217466
    end

    methods (Static)

        function constraints = build(fidelityLevel)
        %BUILD  Construct the F-16's constraint objects for one fidelity
        %   level. Returns a 1xN cell array of PointPerformanceBase objects,
        %   in Constraints.xlsx row order, ready to hand to ConstraintAnalysis
        %   (as-is, or trimmed/reordered by the caller first).
            arguments
                fidelityLevel (1,1) string {mustBeMember(fidelityLevel, ["L1", "L2", "L3"])} = "L3"
            end

            [aero, prop] = F16ConstraintSet.buildDisciplines(fidelityLevel);

            thisFile = mfilename('fullpath');
            xlsxPath = fullfile(fileparts(thisFile), 'Constraints.xlsx');
            T = ConstraintSetImporter.read(xlsxPath, "Constraints");

            names = string(T.Properties.RowNames);
            constraints = cell(1, numel(names) + 1);
            for i = 1:numel(names)
                name = names(i);
                row  = T(i, :);
                switch name
                    case "Takeoff"
                        state = AircraftState(0, 0.1);
                        constraints{i} = TakeoffConstraint(name, state, aero, prop, ...
                            row.Distance_ft_, row.W_Wto);
                    case "Landing"
                        state = AircraftState(0, 0.1);
                        constraints{i} = LandingConstraint(name, state, aero, ...
                            row.Distance_ft_, row.SurfaceFrictionCoefficient_mu_, row.W_Wto);
                    otherwise
                        state = AircraftState(row.Altitude_ft_, row.MachNumber);
                        Ps = row.PS_ft_s_;
                        if isnan(Ps)
                            Ps = 0;
                        end
                        constraints{i} = ThrustConstraint(name, state, aero, prop, ...
                            row.W_Wto, row.n, Ps);
                end
            end

            stallState = AircraftState(0, F16ConstraintSet.STALL_MACH);
            constraints{end} = StallConstraint("Stall", stallState, aero);
        end

    end

    methods (Static, Access = private)

        function [aero, prop] = buildDisciplines(fidelityLevel)
        %BUILDDISCIPLINES  F-16 aero/prop discipline pair for a fidelity
        %   level. No F16PropL3 exists yet, so L3 pairs F16AeroL3 with
        %   F16PropL2 -- same pairing TestThrustConstraint/TestTakeoffConstraint
        %   /TestLandingConstraint use.
            switch fidelityLevel
                case "L1"
                    aero = F16AeroL1(f16a_spec_path(1));
                    prop = F16PropL1(f16a_spec_path(1));
                case "L2"
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(2));
                    prop = F16PropL2(f16a_spec_path(2));
                case "L3"
                    aero = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
                    prop = F16PropL2(f16a_spec_path(2));
            end
        end

    end

end
