classdef TestControlSurfaceSizer < matlab.unittest.TestCase
%TESTCONTROLSURFACESIZER  Unit tests for the generic control-surface area
%   estimate and its F-16 wiring (design_study_02_L2.m).
%
%   [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., AIAA, 2018,
%   p.161 (Fig. 6.3, aileron), p.162 (Table 6.5, elevator/rudder; constant-
%   percent-chord control surfaces, Fig. 6.4).]

    methods (Test)

        function testIsHandleClass(tc)
            obj = ControlSurfaceSizer(0.2, 0.4, 0.3, 0.9, 0.3, 0.9);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testConstructorStoresFractions(tc)
            obj = ControlSurfaceSizer(0.20, 0.40, 0.30, 0.90, 0.25, 0.85);
            tc.verifyEqual(obj.c_ail_frac, 0.20);
            tc.verifyEqual(obj.b_ail_frac, 0.40);
            tc.verifyEqual(obj.c_elev_frac, 0.30);
            tc.verifyEqual(obj.b_elev_frac, 0.90);
            tc.verifyEqual(obj.c_rud_frac, 0.25);
            tc.verifyEqual(obj.b_rud_frac, 0.85);
        end

        function testZeroElevatorFractionsAreAccepted(tc)
            % All-moving-stabilator aircraft (e.g. F-16): c_elev_frac=0,
            % b_elev_frac=0 must construct without error (not validated
            % positive -- see class header).
            obj = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);
            tc.verifyEqual(obj.c_elev_frac, 0);
            tc.verifyEqual(obj.b_elev_frac, 0);
        end

        function testSizeMatchesHandComputedFormula(tc)
            % Arbitrary invented scalars (not F-16 data).
            c_ail = 0.18; b_ail = 0.45;
            c_elev = 0.28; b_elev = 0.88;
            c_rud = 0.22; b_rud = 0.80;
            S_ref = 250; S_ht = 60; S_vt = 45;

            expected_S_ail  = c_ail * b_ail * S_ref;
            expected_S_elev = c_elev * b_elev * S_ht;
            expected_S_rud  = c_rud * b_rud * S_vt;

            obj = ControlSurfaceSizer(c_ail, b_ail, c_elev, b_elev, c_rud, b_rud);
            geom = struct('S_ref', S_ref, 'S_ht', S_ht, 'S_vt', S_vt);
            result = obj.size(geom);

            fprintf(['\n    S_ail: received=%.6f expected=%.6f | S_elev: received=%.6f expected=%.6f | ' ...
                     'S_rud: received=%.6f expected=%.6f\n'], ...
                result.S_ail, expected_S_ail, result.S_elev, expected_S_elev, result.S_rud, expected_S_rud);
            tc.verifyEqual(result.S_ail, expected_S_ail, 'RelTol', 1e-12);
            tc.verifyEqual(result.S_elev, expected_S_elev, 'RelTol', 1e-12);
            tc.verifyEqual(result.S_rud, expected_S_rud, 'RelTol', 1e-12);
        end

        function testResultFieldNamesMatchGeomPropertyCasing(tc)
            obj = ControlSurfaceSizer(0.2, 0.4, 0.3, 0.9, 0.3, 0.9);
            geom = struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60);
            result = obj.size(geom);
            tc.verifyTrue(isfield(result, 'S_ail'));
            tc.verifyTrue(isfield(result, 'S_elev'));
            tc.verifyTrue(isfield(result, 'S_rud'));
        end

        function testAcceptsARealF16GeomL2Object(tc)
            % duck-typed geom argument (see class header) -- confirm it
            % also works with a real F16GeomL2, not just a plain struct.
            prop = F16PropL2(f16a_spec_path(2));
            geom = F16GeomL2(f16a_spec_path(2), prop);
            obj  = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);
            result = obj.size(geom);
            fprintf('\n    F16GeomL2: S_ail=%.4f  S_elev=%.4f  S_rud=%.4f\n', ...
                result.S_ail, result.S_elev, result.S_rud);
            tc.verifyEqual(result.S_ail, 0.20 * 0.40 * geom.S_ref, 'RelTol', 1e-12);
            tc.verifyEqual(result.S_elev, 0, 'AbsTol', 1e-12, ...
                'F-16 elevator area must be 0 (all-moving stabilator, Table 6.5 footnote).');
            tc.verifyEqual(result.S_rud, 0.30 * 0.90 * geom.S_vt, 'RelTol', 1e-12);
        end

    end

end
