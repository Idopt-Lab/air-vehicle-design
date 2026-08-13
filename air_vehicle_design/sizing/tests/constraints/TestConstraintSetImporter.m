classdef TestConstraintSetImporter < matlab.unittest.TestCase
%TESTCONSTRAINTSETIMPORTER  Unit tests for the generic ConstraintSetImporter
%   (reads constraint conditions from a requirements JSON into a struct
%   array), exercised against the F-16's
%   examples/F16A/inputs/f16a_requirements.json.
%
%   Rewritten 2026-08-04 (subplan 06-refactor T3): the importer now reads the
%   requirements JSON's constraints.conditions block with explicit keys, not
%   the retired Constraints.xlsx workbook with mangled column names.

    methods (Test)

        function testAllEightConditionsPresent(tc)
            cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());
            tc.verifyEqual(numel(cond), 8);
            names = arrayfun(@(c) string(c.name), cond);
            expectedNames = ["Max Mach", "Cruise", "Max Alt", ...
                "Combat Turn 1 (subsonic)", "Combat Turn 2 (supersonic)", ...
                "Excess Power", "Takeoff", "Landing"];
            tc.verifyEqual(names(:), expectedNames(:));
        end

        function testCruiseMachPowerAndBeta(tc)
            cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());
            cruise = TestConstraintSetImporter.byName(cond, "Cruise");
            tc.verifyEqual(cruise.mach, 0.87, 'AbsTol', 1e-9);
            tc.verifyEqual(string(cruise.power_setting), "mil");
            tc.verifyEqual(cruise.beta, 0.89966696, 'AbsTol', 1e-8);
        end

        function testExcessPowerPs(tc)
            cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());
            ep = TestConstraintSetImporter.byName(cond, "Excess Power");
            tc.verifyEqual(ep.Ps_fps, 500, 'AbsTol', 1e-9);
            tc.verifyEqual(string(ep.power_setting), "AB");
        end

        function testTakeoffFieldFieldsAndLiftoffMach(tc)
            % mach_liftoff = 0.2 is the T3 change (was a hardcoded 0.1 state in
            % F16ConstraintSet) -- the real V_liftoff/a_SL, Brandt Consts!AT32.
            cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());
            to = TestConstraintSetImporter.byName(cond, "Takeoff");
            tc.verifyEqual(to.distance_ft, 4000, 'AbsTol', 1e-9);
            tc.verifyEqual(to.mu, 0.03, 'AbsTol', 1e-9);
            tc.verifyEqual(to.mach_liftoff, 0.2, 'AbsTol', 1e-9);
            % Takeoff carries no power_setting (always full AB).
            tc.verifyFalse(isfield(to, 'power_setting') && ~isempty(to.power_setting));
        end

        function testLandingFrictionAndDistance(tc)
            cond = ConstraintSetImporter.read_conditions(f16a_requirements_path());
            la = TestConstraintSetImporter.byName(cond, "Landing");
            tc.verifyEqual(la.distance_ft, 4000, 'AbsTol', 1e-9);
            tc.verifyEqual(la.mu, 0.50, 'AbsTol', 1e-9);
        end

        function testMissingConstraintsBlockErrors(tc)
            % A requirements file with no constraints.conditions block must
            % error clearly, not return an empty result.
            tmp = [tempname, '.json'];
            fid = fopen(tmp, 'w');
            fprintf(fid, '%s', '{"cruise": {"altitude_ft": 36000, "mach": 0.87}}');
            fclose(fid);
            tc.addTeardown(@() delete(tmp));
            tc.verifyError(@() ConstraintSetImporter.read_conditions(tmp), ...
                'ConstraintSetImporter:missingConstraintsBlock');
        end

    end

    methods (Static, Access = private)

        function c = byName(cond, name)
            names = arrayfun(@(x) string(x.name), cond);
            c = cond(names == name);
        end

    end

end
