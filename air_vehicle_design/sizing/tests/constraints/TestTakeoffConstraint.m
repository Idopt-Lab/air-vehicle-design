classdef TestTakeoffConstraint < matlab.unittest.TestCase
%TESTTAKEOFFCONSTRAINT  Unit tests for the generic TakeoffConstraint class
%   (Mattingly Master Equation, ground-roll/takeoff case) and its F-16
%   "Takeoff" instantiation.
%
%   Equation [Mattingly, Heiser, Pratt, "Aircraft Engine Design," 2nd ed.,
%   AIAA, 2002, Master Equation specialized to ground roll (T_SL>>D+R,
%   dh/dt=0), plus Brandt's own ground-roll drag/rolling-friction correction
%   (F-16A.xls Consts-sheet row 32, matching temp_Casey's takeoff_constraint.m
%   term2); B term matches NPTEL_Fighter_Aircraft_Sizing.ipynb's Takeoff class
%   (cells 32-33) -- NOT Raymer ch. 5, which gives only the graphical TOP
%   method, per TakeoffConstraint.m's header], as TakeoffConstraint.m
%   implements it:
%
%     T_SL/W_TO = (beta^2/alpha) * (k_TO^2 / (rho*g*CLmax_TO)) * (W_TO/S) / S_G
%                 + 0.7*CD0_TO/(beta*CLmax_TO) + mu
%
%   testRequiredTWMatchesHandComputedEquation checks required_TW against an
%   independently written form of the same equation (not a copy of
%   TakeoffConstraint's own algebra) using the same aero/prop discipline
%   outputs (get_CLmax_TO, get_Delta_CD0_TO, drag_polar, thrust_lapse --
%   each already unit-tested elsewhere). testEquationReproducesBrandtTakeoffPoint
%   drives the actual production code path with Brandt's own inputs (mu,
%   CD0, CLmax_TO, alpha_AB) and checks it reproduces his tabulated value
%   directly.
%
%   The F-16 Takeoff field condition [subplans/06_constraint_analysis.md
%   "Field constraints" table]: sea level, k_TO=1.2, S_G=4,000 ft, mu=0.03,
%   beta=1.0. F16Baseline's b.constraints.takeoff.TW_Takeoff is Brandt's full
%   21-point Consts-sheet row 32; testF16TakeoffRequiredTWTable prints our
%   per-fidelity-level values alongside it as a diagnostic (not an
%   exact-match assertion, same spirit as ThrustConstraint's
%   testF16MaxMachRequiredTWTable) -- this framework's own aero/prop
%   fidelity-level gaps (documented in F16AeroLN/F16PropLN) still drive some
%   spread even though the equation itself now matches Brandt's.

    properties (TestParameter)
        % Aero/prop discipline pairing per fidelity level. No F16PropL3
        % exists yet, so L3 pairs F16AeroL3 with F16PropL2 (highest
        % propulsion fidelity available), matching TestThrustConstraint.
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaPointPerformanceBase(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaBothWbySTbyW(tc)
            % TakeoffConstraint belongs to the Both_WbyS_TbyW category, same
            % as ThrustConstraint -- see TakeoffConstraint.m/
            % Both_WbyS_TbyW.m headers.
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Takeoff", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyEqual(obj.name, "Takeoff");
        end

        function testDefaultBetaAndKTO(tc)
            % beta and k_TO default to 1.0 and 1.2 (field constraints, per
            % subplans/06_constraint_analysis.md) when omitted.
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyEqual(obj.beta, 1.0);
            tc.verifyEqual(obj.k_TO, 1.2);
        end

        % --- Equation assembly (generic, hand-computed) ---------------------

        function testRequiredTWMatchesHandComputedEquation(tc)
            % Arbitrary field length / margin (not F-16-specific data, just
            % uses the F-16 discipline objects as a concrete
            % AerodynamicsBase/PropulsionBase pair). Independently derived
            % form of the same equation, not a copy of TakeoffConstraint's
            % own algebra. Uses the FLAPPED takeoff CLmax/CD0
            % (get_CLmax_TO(), drag_polar(state).CD0 + get_Delta_CD0_TO())
            % since that is what compute_B/compute_C now call -- see
            % TakeoffConstraint.m's header. F16AeroL1's get_Delta_CD0_TO
            % takes no state argument (only F16AeroL3's does).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            S_G   = 3500;
            mu    = 0.03;
            beta  = 0.98;
            k_TO  = 1.15;
            WS    = 90;

            CLmax_TO = aero.get_CLmax_TO();
            CD0_TO   = aero.drag_polar(state).CD0 + aero.get_Delta_CD0_TO();
            alpha    = prop.thrust_lapse(state);
            rho      = state.rho;
            g        = 32.174;

            expected = (beta^2 / alpha) * (k_TO^2 / (rho * g * CLmax_TO)) * WS / S_G ...
                + 0.7 * CD0_TO / (beta * CLmax_TO) + mu;

            obj      = TakeoffConstraint("Toy", state, aero, prop, S_G, mu, beta, k_TO);
            received = obj.required_TW(WS);

            fprintf('\n    required_TW(WS=%d): received=%.6f  hand-computed=%.6f\n', WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'required_TW must equal the hand-computed takeoff equation.');
        end

        function testEquationReproducesBrandtTakeoffPoint(tc)
            % Plugs Brandt's own takeoff inputs directly into the same
            % equation TakeoffConstraint.m implements (B term + the
            % 0.7*CD0_TO/(beta*CLmax_TO) + mu correction) and checks it lands
            % within 0.5% of F16Baseline's b.constraints.takeoff.TW_Takeoff
            % at W/S=90 (index 11 of the 20:7:160 sweep) [Brandt F-16A.xls
            % Consts sheet, row 32]. This validates the equation itself
            % against Brandt's worksheet -- separate from
            % testRequiredTWMatchesHandComputedEquation's generic algebra
            % check and from testF16TakeoffRequiredTWTable's aero-driven
            % (textbook flapped CLmax_TO/CD0_TO per fidelity level, not
            % expected to match exactly) comparison.
            b = F16Baseline();

            mu       = 0.03;
            CLmax_TO = b.brandt.CLmax_TO;               % 1.2785 [Brandt L9]
            CD0_TO   = b.constraints.takeoff.CD0;       % 0.052 [Brandt Consts row 32]
            alpha_AB = b.engine.val.brandt_alpha_AB_SLS_M12;   % 0.955053 [Brandt Consts row 32, col AT]
            S_G      = 4000;
            k_TO     = 1.2;
            beta     = 1.0;
            WS       = 90;   % b.constraints.takeoff.WS_psf(11)

            % Drive the actual production code path (TakeoffConstraint.required_TW,
            % which internally calls aero.get_CLmax_TO()/(aero.drag_polar(state).CD0
            % + aero.get_Delta_CD0_TO()) and prop.thrust_lapse(state)) via
            % fixed-value aero/prop stubs carrying Brandt's own already-
            % flapped numbers directly (FixedAeroStub's
            % get_CLmax_TO/get_Delta_CD0_TO just echo the constructor's
            % CLmax/CD0 and 0, respectively -- see FixedAeroStub.m's header),
            % rather than re-deriving the equation by hand in the test --
            % this way the test would catch a bug in TakeoffConstraint.m's
            % own algebra.
            aeroStub = FixedAeroStub(CLmax_TO, CD0_TO);
            propStub = FixedPropStub(alpha_AB);
            state    = AircraftState(0, 0.1);
            obj      = TakeoffConstraint("Takeoff", state, aeroStub, propStub, S_G, mu, beta, k_TO);

            received = obj.required_TW(WS);
            expected = b.constraints.takeoff.TW_Takeoff(11);

            fprintf('\n    Takeoff required_TW at WS=%d (Brandt inputs): received=%.6f  Brandt=%.6f\n', ...
                WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 5e-3, ...
                'The takeoff equation, fed Brandt''s own inputs, should reproduce Brandt''s TW_Takeoff to within 0.5%.');
        end

        % --- Available/margin ------------------------------------------------

        function testTWMarginMatchesHandComputedFormula(tc)
            % Arbitrary field length/design point (not F-16-specific data).
            % Confirms Both_WbyS_TbyW.TW_margin (shared with ThrustConstraint,
            % see TestThrustConstraint.m) works correctly through
            % TakeoffConstraint's own required_TW/get_alpha (affine in W/S,
            % A=D=0, B and C nonzero -- a different code path than
            % ThrustConstraint's bucket-shaped curve): margin = alpha*(T_SL/W_TO -
            % required_TW(WS_actual)), where alpha is TakeoffConstraint's own
            % get_alpha() (plain AB-basis lapse, no mil/AB distinction).
            % Requests TW_margin's 2nd/3rd (available/required) outputs
            % directly so both underlying constraint values are
            % independently verified, not just their combined margin.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 3500, 0.03, 0.98, 1.15);

            WS_actual = 90;
            T_SL      = 25000;
            W_TO      = 32000;

            alpha              = prop.thrust_lapse(state);
            expected_required  = alpha * obj.required_TW(WS_actual);
            expected_available = alpha * (T_SL / W_TO);
            expected_margin    = expected_available - expected_required;

            [received_margin, received_available, received_required] = obj.TW_margin(WS_actual, T_SL, W_TO);

            fprintf(['\n    TW_margin: required=%.6f  available=%.6f  margin=%.6f  ' ...
                '(hand-computed: required=%.6f  available=%.6f  margin=%.6f)\n'], ...
                received_required, received_available, received_margin, ...
                expected_required, expected_available, expected_margin);
            tc.verifyEqual(received_required, expected_required, 'RelTol', 1e-10, ...
                'TW_margin''s required output must equal alpha*required_TW(WS_actual).');
            tc.verifyEqual(received_available, expected_available, 'RelTol', 1e-10, ...
                'TW_margin''s available output must equal alpha*T_SL/W_TO.');
            tc.verifyEqual(received_margin, expected_margin, 'RelTol', 1e-10, ...
                'TW_margin must equal available minus required.');
        end

        function testRequiredTWVectorizedOverWS(tc)
            % Constraint diagrams sweep W/S -- required_TW must vectorize
            % cleanly and stay finite over a physically reasonable range.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 4000, 0.03);

            WS_range = 20:10:180;
            TW       = obj.required_TW(WS_range);

            tc.verifyEqual(numel(TW), numel(WS_range));
            tc.verifyTrue(all(isfinite(TW)), 'required_TW must be finite over the W/S sweep.');
        end

        function testRequiredTWAffineInWS(tc)
            % Unlike the Mattingly Master Equation (bucket-shaped), the
            % simplified takeoff relation is strictly linear in W/S:
            % required_TW = coeff * WS / S_G, so doubling WS must double TW.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 4000, 0.03);

            WS = 60;
            d  = 20;
            TW_0 = obj.required_TW(WS);
            TW_1 = obj.required_TW(WS + d);
            TW_2 = obj.required_TW(WS + 2*d);

            tc.verifyEqual(TW_1 - TW_0, TW_2 - TW_1, 'RelTol', 1e-10, ...
                'required_TW must be affine in W/S (equal W/S steps -> equal T/W steps).');
        end

        function testRequiredTWIncreasesWithGroundRoll(tc)
            % A shorter required ground roll demands a higher T/W at fixed
            % W/S (harder field-length requirement -> more thrust needed).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            WS    = 90;

            obj_short = TakeoffConstraint("Short field", state, aero, prop, 2000, 0.03);
            obj_long  = TakeoffConstraint("Long field", state, aero, prop, 6000, 0.03);

            tc.verifyGreaterThan(obj_short.required_TW(WS), obj_long.required_TW(WS), ...
                'A shorter ground-roll requirement must demand a higher required T/W.');
        end

        % --- F-16 Takeoff field condition -----------------------------------
        % Sea level, k_TO=1.2, S_G=4,000 ft, beta=1.0
        % [subplans/06_constraint_analysis.md "Field constraints" table]

        function testF16TakeoffRequiredTWPhysicalRange(tc)
            % Sanity check only -- no Brandt TW_Takeoff table to compare
            % against (see class header note). Confirms the F-16 discipline
            % objects produce a plausible, finite, positive required T/W at
            % a representative W/S.
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Takeoff", state, aero, prop, 4000, 0.03, 1.0, 1.2);

            WS = 80;
            TW = obj.required_TW(WS);
            fprintf('\n    Takeoff required_TW at WS=%.2f: %.4f (CLmax_TO used=%.4f)\n', ...
                WS, TW, aero.get_CLmax_TO());
            tc.verifyGreaterThan(TW, 0, 'required_TW must be positive.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        function testF16TakeoffRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Takeoff condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [F16Baseline b.constraints.takeoff.TW_Takeoff].
            % Now that the equation itself includes Brandt's drag/rolling-
            % friction correction (see class header), the remaining diff is
            % from this framework's own textbook flapped-CLmax_TO/CD0_TO
            % estimate vs. Brandt's flight-calibrated values (same class of
            % per-fidelity gap as Landing, see LandingConstraint.m's header)
            % -- diagnostic only, not an exact-match assertion.
            [aero, prop] = TestTakeoffConstraint.buildDisciplines(fidelityLevel);

            b     = F16Baseline();
            state = AircraftState(0, 0.1);   % sea level, near-zero Mach (avoids M=0 edge cases)
            obj   = TakeoffConstraint("Takeoff", state, aero, prop, 4000, 0.03, 1.0, 1.2);

            WS_range      = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_takeoff = b.constraints.takeoff.TW_Takeoff;
            TW            = obj.required_TW(WS_range);

            fprintf('\n    [%s]  %6s  %12s  %12s  %10s\n', fidelityLevel, 'W/S', 'Our T/W', 'Brandt T/W', 'diff %');
            for i = 1:numel(WS_range)
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%\n', WS_range(i), TW(i), brandt_takeoff(i), ...
                    100*(TW(i) - brandt_takeoff(i))/brandt_takeoff(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
        end

    end

    methods (Static, Access = private)

        function [aero, prop] = buildDisciplines(fidelityLevel)
        %BUILDDISCIPLINES  F-16 aero/prop discipline pair for a fidelity level.
        %   No F16PropL3 exists yet, so L3 pairs F16AeroL3 with F16PropL2.
            switch fidelityLevel
                case 'L1'
                    aero = F16AeroL1(f16a_spec_path(1));
                    prop = F16PropL1(f16a_spec_path(1));
                case 'L2'
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
                    prop = F16PropL2(f16a_spec_path(2));
                case 'L3'
                    aero = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
                    prop = F16PropL2(f16a_spec_path(2));
                otherwise
                    error('TestTakeoffConstraint:buildDisciplines:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end

end
