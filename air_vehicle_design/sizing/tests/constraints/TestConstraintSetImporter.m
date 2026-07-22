classdef TestConstraintSetImporter < matlab.unittest.TestCase
%TESTCONSTRAINTSETIMPORTER  Unit tests for the generic ConstraintSetImporter
%   (reads a Constraints.xlsx-style workbook into a table), exercised
%   against the F-16's examples/F16A/Constraints.xlsx.

    methods (Test)

        function testAllEightConditionRowsPresent(tc)
            T = ConstraintSetImporter.read(TestConstraintSetImporter.xlsxPath(), "Constraints");
            expectedNames = ["Max Mach", "Cruise", "Max Alt", "Combat Subsonic", ...
                "Combat Supersonic", "Excess Power", "Takeoff", "Landing"];
            tc.verifyEqual(string(T.Properties.RowNames), expectedNames(:));
        end

        function testCruiseMachAndBeta(tc)
            T = ConstraintSetImporter.read(TestConstraintSetImporter.xlsxPath(), "Constraints");
            row = T("Cruise", :);
            tc.verifyEqual(row.MachNumber, 0.87, 'AbsTol', 1e-9);
            tc.verifyEqual(row.W_Wto, 0.89967, 'AbsTol', 1e-5);
        end

        function testLandingFrictionAndDistance(tc)
            T = ConstraintSetImporter.read(TestConstraintSetImporter.xlsxPath(), "Constraints");
            row = T("Landing", :);
            tc.verifyEqual(row.SurfaceFrictionCoefficient_mu_, 0.50, 'AbsTol', 1e-9);
            tc.verifyEqual(row.Distance_ft_, 4000, 'AbsTol', 1e-9);
        end

        function testExcessPowerHasPS(tc)
            T = ConstraintSetImporter.read(TestConstraintSetImporter.xlsxPath(), "Constraints");
            row = T("Excess Power", :);
            tc.verifyEqual(row.PS_ft_s_, 500, 'AbsTol', 1e-9);
        end

    end

    methods (Static, Access = private)

        function p = xlsxPath()
            p = fullfile(fileparts(mfilename('fullpath')), '..', '..', ...
                'examples', 'F16A', 'Constraints.xlsx');
        end

    end

end
