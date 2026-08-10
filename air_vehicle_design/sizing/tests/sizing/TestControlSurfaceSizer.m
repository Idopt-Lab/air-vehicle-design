classdef TestControlSurfaceSizer < matlab.unittest.TestCase
%TESTCONTROLSURFACESIZER  Unit tests for the generic control-surface area
%   estimate and its F-16 wiring (f16a_control_surfaces.m).
%
%   [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., AIAA, 2018,
%   p.161 (Fig. 6.3, aileron), p.162 (Table 6.5, elevator/rudder; constant-
%   percent-chord control surfaces, Fig. 6.4).]
%   [Roskam, "Airplane Design Part II," Eq. 7.10 -- the wing-flap span-station
%   area ratio, via AeroL2.compute_S_flapped_ratio.]
%
%   WIDENED 2026-08-10 from three surfaces to six: S_flaperon, S_lef and
%   S_stab joined S_ail/S_elev/S_rud. The F-16 has no separate ailerons (its
%   trailing-edge surface is a flaperon) and no separate elevator (all-moving
%   stabilator), so the two surfaces the old wiring reported were exactly the
%   two this airframe does not have.
%
%   HAND-COMPUTED EXPECTED VALUES for the F-16 at the JSON baseline
%   (S_ref = 300 ft^2, taper = 0.2275, S_ht = 108 ft^2, S_vt = 60 ft^2), from
%   f16a_control_surfaces()'s fractions:
%
%     Roskam Eq. 7.10 ratio = (eta_out - eta_in)
%                             * (2 - (1-lambda)*(eta_in + eta_out)) / (1 + lambda)
%
%     FLAPERON  c = 0.25, eta = 0.35 -> 0.75
%       ratio = 0.40 * (2 - 0.7725*1.10) / 1.2275 = 0.40 * 1.150250 / 1.2275
%       S_flaperon = 0.25 * 300 * ratio = 75 * 0.4601/1.2275
%                  = 345075/12275 = 28.112016293... ft^2
%     LE FLAP   c = 0.15, eta = 0.00 -> 0.98
%       ratio = 0.98 * (2 - 0.7725*0.98) / 1.2275 = 0.98 * 1.242950 / 1.2275
%       S_lef  = 0.15 * 300 * ratio = 45 * 1.218091/1.2275
%              = 54814095/1227500 = 44.655067210... ft^2
%   (Both worked as exact fractions -- an earlier decimal pass got the 7th
%   significant figure wrong and the RelTol 1e-10 assertions below caught it.)
%     STABILATOR  all-moving -> S_stab = S_ht = 108 ft^2 exactly
%     RUDDER    0.30 * 0.90 * 60 = 16.20 ft^2
%     AILERON, ELEVATOR  0 (neither exists on this airframe)
%
%   These are Raymer/Roskam ESTIMATES, deliberately NOT the measured T.O.
%   1F-16A-1 areas (flaperon 31.32, LEF 36.71, rudder 11.65 ft^2). The
%   accuracy against those is measured by
%   examples/F16A/tail_sizing_brandt_comparison.m, which is informational and
%   not pass/fail. No expected value in this file is taken from ground truth --
%   see f16a_control_surfaces.m's header for why that direction matters.

    properties (Constant)
        % F-16 baseline, for the hand-computed values documented above.
        F16_S_FLAPERON = 345075/12275     % ft^2  = 28.112016293... (0.25 * ratio(0.75,0.35,0.2275) * 300)
        F16_S_LEF      = 54814095/1227500 % ft^2  = 44.655067210... (0.15 * ratio(0.98,0.00,0.2275) * 300)
        F16_S_STAB     = 108.0                % ft^2  = S_ht (all-moving)
        F16_S_RUD      = 16.2                 % ft^2  0.30 * 0.90 * 60
    end

    methods (Test)

        % ================================================================== %
        % Construction
        % ================================================================== %

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

        function testWingFlapOptionsDefaultToZeroAndOff(tc)
            % An airframe with a conventional aileron and hinged elevator must
            % not have to mention the wing-flap options at all -- the six
            % positional arguments alone still construct, and the new surfaces
            % come back 0.
            obj = ControlSurfaceSizer(0.20, 0.40, 0.30, 0.90, 0.30, 0.90);
            tc.verifyEqual(obj.c_flaperon_frac, 0);
            tc.verifyEqual(obj.c_lef_frac, 0);
            tc.verifyFalse(obj.ht_all_moving);
            result = obj.size(struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60, 'lambda_wing', 0.2275));
            tc.verifyEqual(result.S_flaperon, 0, 'AbsTol', 1e-12);
            tc.verifyEqual(result.S_lef, 0, 'AbsTol', 1e-12);
            tc.verifyEqual(result.S_stab, 0, 'AbsTol', 1e-12);
        end

        function testConstructorStoresWingFlapOptions(tc)
            obj = ControlSurfaceSizer(0, 0, 0, 0, 0.30, 0.90, ...
                'c_flaperon_frac', 0.25, 'eta_flaperon_in', 0.35, 'eta_flaperon_out', 0.75, ...
                'c_lef_frac', 0.15, 'eta_lef_in', 0.0, 'eta_lef_out', 0.98, ...
                'ht_all_moving', true);
            tc.verifyEqual(obj.c_flaperon_frac, 0.25);
            tc.verifyEqual(obj.eta_flaperon_in, 0.35);
            tc.verifyEqual(obj.eta_flaperon_out, 0.75);
            tc.verifyEqual(obj.c_lef_frac, 0.15);
            tc.verifyEqual(obj.eta_lef_in, 0.0);
            tc.verifyEqual(obj.eta_lef_out, 0.98);
            tc.verifyTrue(obj.ht_all_moving);
        end

        function testZeroElevatorFractionsAreAccepted(tc)
            % All-moving-stabilator aircraft (e.g. F-16): c_elev_frac=0,
            % b_elev_frac=0 must construct without error (not validated
            % positive -- see class header).
            obj = ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90);
            tc.verifyEqual(obj.c_elev_frac, 0);
            tc.verifyEqual(obj.b_elev_frac, 0);
        end

        % ================================================================== %
        % Role exclusivity -- the two constructor guards
        % ================================================================== %

        function testAileronPlusFlaperonIsRejected(tc)
            % A flaperon already IS the roll surface, so declaring an aileron
            % too double-counts one physical surface -- and would silently
            % inflate S_csw and S_cs downstream rather than erroring.
            tc.verifyError(@() ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90, ...
                    'c_flaperon_frac', 0.25, 'eta_flaperon_in', 0.35, 'eta_flaperon_out', 0.75), ...
                'ControlSurfaceSizer:ailAndFlaperonBothDeclared', ...
                'Declaring both an aileron and a flaperon must be rejected.');
        end

        function testAllMovingTailPlusElevatorIsRejected(tc)
            % An all-moving stabilator has no separate hinged elevator
            % [Raymer 6th ed. Table 6.5 footnote].
            tc.verifyError(@() ControlSurfaceSizer(0, 0, 0.30, 0.90, 0.30, 0.90, ...
                    'ht_all_moving', true), ...
                'ControlSurfaceSizer:allMovingWithElevator', ...
                'An all-moving tail plus a nonzero elevator fraction must be rejected.');
        end

        % ================================================================== %
        % Formulas
        % ================================================================== %

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
            geom = struct('S_ref', S_ref, 'S_ht', S_ht, 'S_vt', S_vt, 'lambda_wing', 0.3);
            result = obj.size(geom);

            fprintf(['\n    S_ail: received=%.6f expected=%.6f | S_elev: received=%.6f expected=%.6f | ' ...
                     'S_rud: received=%.6f expected=%.6f\n'], ...
                result.S_ail, expected_S_ail, result.S_elev, expected_S_elev, result.S_rud, expected_S_rud);
            tc.verifyEqual(result.S_ail, expected_S_ail, 'RelTol', 1e-12);
            tc.verifyEqual(result.S_elev, expected_S_elev, 'RelTol', 1e-12);
            tc.verifyEqual(result.S_rud, expected_S_rud, 'RelTol', 1e-12);
        end

        function testWingFlapAreaMatchesRoskamEq710(tc)
            % Independent restatement of Roskam Part II Eq. 7.10, spelled out
            % here rather than calling AeroL2.compute_S_flapped_ratio, so this
            % test would catch a change to that static.
            c_frac = 0.22; eta_in = 0.20; eta_out = 0.80;
            S_ref  = 250;  lambda = 0.35;
            ratio    = (eta_out - eta_in) * (2 - (1 - lambda)*(eta_in + eta_out)) / (1 + lambda);
            expected = c_frac * ratio * S_ref;

            obj = ControlSurfaceSizer(0, 0, 0, 0, 0.30, 0.90, ...
                'c_flaperon_frac', c_frac, 'eta_flaperon_in', eta_in, 'eta_flaperon_out', eta_out);
            result = obj.size(struct('S_ref', S_ref, 'S_ht', 60, 'S_vt', 45, 'lambda_wing', lambda));

            fprintf('\n    S_flaperon: received=%.6f expected=%.6f (Roskam Eq. 7.10 ratio=%.6f)\n', ...
                result.S_flaperon, expected, ratio);
            tc.verifyEqual(result.S_flaperon, expected, 'RelTol', 1e-12);
        end

        function testWingFlapAreaAccountsForTaper(tc)
            % The whole reason the wing flaps use Roskam Eq. 7.10 rather than a
            % bare chord x span product: the SAME span EXTENT placed inboard vs.
            % outboard on a tapered wing gives DIFFERENT areas, because the
            % local chord shrinks outboard. A bare product cannot see that.
            common = {0, 0, 0, 0, 0.30, 0.90, 'c_flaperon_frac', 0.25};
            geom   = struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60, 'lambda_wing', 0.2275);
            inboard  = ControlSurfaceSizer(common{:}, 'eta_flaperon_in', 0.10, 'eta_flaperon_out', 0.50);
            outboard = ControlSurfaceSizer(common{:}, 'eta_flaperon_in', 0.50, 'eta_flaperon_out', 0.90);
            S_in  = inboard.size(geom).S_flaperon;
            S_out = outboard.size(geom).S_flaperon;
            fprintf('\n    Same 0.40 span extent: inboard=%.4f ft^2  outboard=%.4f ft^2\n', S_in, S_out);
            tc.verifyGreaterThan(S_in, S_out, ...
                ['An inboard flap must have MORE area than an outboard flap of the same span ' ...
                 'extent on a tapered wing. Equal areas mean the taper term was lost.']);
        end

        function testAllMovingStabilatorAreaIsTheWholeTail(tc)
            % [Raymer 6th ed. Table 6.5 footnote]: no separate elevator, so the
            % pitch control surface IS the horizontal tail.
            obj = ControlSurfaceSizer(0, 0, 0, 0, 0.30, 0.90, 'ht_all_moving', true);
            geom = struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60, 'lambda_wing', 0.2275);
            result = obj.size(geom);
            tc.verifyEqual(result.S_stab, 108, 'RelTol', 1e-12);
            tc.verifyEqual(result.S_elev, 0, 'AbsTol', 1e-12, ...
                'S_elev must stay 0 for an all-moving tail -- F16SandCL3 depends on it.');
        end

        function testStabilatorTracksTheTailArea(tc)
            % S_stab must be recomputed from S_ht on every call, not frozen:
            % SizingLoopL2 rewrites S_ht each iteration before calling size().
            obj = ControlSurfaceSizer(0, 0, 0, 0, 0.30, 0.90, 'ht_all_moving', true);
            geom = struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60, 'lambda_wing', 0.2275);
            tc.verifyEqual(obj.size(geom).S_stab, 108, 'RelTol', 1e-12);
            geom.S_ht = 61.4;
            tc.verifyEqual(obj.size(geom).S_stab, 61.4, 'RelTol', 1e-12);
        end

        function testResultFieldNamesMatchGeomPropertyCasing(tc)
            obj = ControlSurfaceSizer(0.2, 0.4, 0.3, 0.9, 0.3, 0.9);
            geom = struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60, 'lambda_wing', 0.2275);
            result = obj.size(geom);
            for f = ["S_ail", "S_elev", "S_rud", "S_flaperon", "S_lef", "S_stab"]
                tc.verifyTrue(isfield(result, f), ...
                    sprintf('size() must return a %s field, matching the geometry property name.', f));
            end
        end

        % ================================================================== %
        % F-16 wiring
        % ================================================================== %

        function testAcceptsARealF16GeomL2Object(tc)
            % duck-typed geom argument (see class header) -- confirm it also
            % works with a real F16GeomL2, not just a plain struct, and that the
            % F-16 factory reproduces the hand-computed values in the header.
            prop = F16PropL2(f16a_spec_path(2));
            geom = F16GeomL2(f16a_spec_path(2), prop);
            obj  = f16a_control_surfaces();
            result = obj.size(geom);
            fprintf(['\n    F16GeomL2 (S_ref=%.1f): S_flaperon=%.5f  S_lef=%.5f  S_stab=%.4f  ' ...
                     'S_rud=%.4f  S_ail=%.4f  S_elev=%.4f\n'], ...
                geom.S_ref, result.S_flaperon, result.S_lef, result.S_stab, ...
                result.S_rud, result.S_ail, result.S_elev);
            tc.verifyEqual(result.S_flaperon, tc.F16_S_FLAPERON, 'RelTol', 1e-10);
            tc.verifyEqual(result.S_lef,      tc.F16_S_LEF,      'RelTol', 1e-10);
            tc.verifyEqual(result.S_stab,     geom.S_ht,         'RelTol', 1e-12);
            tc.verifyEqual(result.S_rud,      tc.F16_S_RUD,      'RelTol', 1e-12);
            tc.verifyEqual(result.S_ail, 0, 'AbsTol', 1e-12, ...
                'F-16 aileron area must be 0 -- the flaperon serves the roll role.');
            tc.verifyEqual(result.S_elev, 0, 'AbsTol', 1e-12, ...
                'F-16 elevator area must be 0 (all-moving stabilator, Table 6.5 footnote).');
        end

        function testF16FactoryDeclaresTheRightSurfaces(tc)
            % The configuration the user-supplied reference confirms: flaperons,
            % leading-edge flaps, all-moving horizontal tails, a rudder -- and
            % no separate aileron or elevator.
            obj = f16a_control_surfaces();
            tc.verifyEqual(obj.c_ail_frac, 0, 'The F-16 has no separate ailerons.');
            tc.verifyEqual(obj.c_elev_frac, 0, 'The F-16 has no separate elevator.');
            tc.verifyTrue(obj.ht_all_moving, 'The F-16 horizontal tail is all-moving.');
            tc.verifyGreaterThan(obj.c_flaperon_frac, 0, 'The F-16 has flaperons.');
            tc.verifyGreaterThan(obj.c_lef_frac, 0, 'The F-16 has leading-edge flaps.');
            tc.verifyGreaterThan(obj.c_rud_frac, 0, 'The F-16 has a rudder.');
        end

        function testAllAreasScaleWithWingAndTail(tc)
            % The property SizingLoopL2 depends on: halve the wing and tail and
            % every area must halve too. A frozen area would fail here, and
            % this is the guard against the whole class of staleness bug that
            % motivated the 2026-08-10 change.
            obj  = f16a_control_surfaces();
            big   = struct('S_ref', 300, 'S_ht', 108, 'S_vt', 60, 'lambda_wing', 0.2275);
            small = struct('S_ref', 150, 'S_ht', 54,  'S_vt', 30, 'lambda_wing', 0.2275);
            rb = obj.size(big);
            rs = obj.size(small);
            for f = ["S_flaperon", "S_lef", "S_stab", "S_rud"]
                fprintf('    %-11s big=%9.4f  half-scale=%9.4f\n', f, rb.(f), rs.(f));
                tc.verifyEqual(rs.(f), rb.(f)/2, 'RelTol', 1e-12, ...
                    sprintf('%s must scale with the wing/tail it is sized from.', f));
            end
        end

    end

end
