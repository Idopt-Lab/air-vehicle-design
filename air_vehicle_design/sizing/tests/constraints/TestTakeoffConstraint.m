classdef TestTakeoffConstraint < matlab.unittest.TestCase
%TESTTAKEOFFCONSTRAINT  Unit tests for the generic TakeoffConstraint class
%   (Mattingly Master Equation, ground-roll/takeoff case) and its F-16
%   "Takeoff" instantiation.
%
%   Equation [Mattingly, Heiser, Pratt, "Aircraft Engine Design," 2nd ed.,
%   AIAA, 2002, Master Equation specialized to ground roll (T_SL>>D+R,
%   dh/dt=0); matches NPTEL_Fighter_Aircraft_Sizing.ipynb's Takeoff class
%   (cells 32-33) -- NOT Raymer ch. 5, which gives only the graphical TOP
%   method, per TakeoffConstraint.m's header], as TakeoffConstraint.m
%   implements it:
%
%     T_SL/W_TO = (beta^2/alpha) * (k_TO^2 / (rho*g*CLmax_TO)) * (W_TO/S) / S_G
%
%   testRequiredTWMatchesHandComputedEquation checks required_TW against an
%   independently written form of the same equation (not a copy of
%   TakeoffConstraint's own algebra) using the same aero/prop discipline
%   outputs (get_CLmax, thrust_lapse -- each already unit-tested elsewhere).
%
%   The F-16 Takeoff field condition [subplans/06_constraint_analysis.md
%   "Field constraints" table]: sea level, k_TO=1.2, S_G=4,000 ft, beta=1.0.
%   F16Baseline's b.constraints.takeoff.TW_Takeoff is Brandt's full 21-point
%   Consts-sheet row 32 -- but that row comes from his *unsimplified* takeoff
%   equation (drag/rolling-friction term included, per temp_Casey's
%   takeoff_constraint.m term2) which TakeoffConstraint.m intentionally does
%   not implement (see class header). So testF16TakeoffRequiredTWTable
%   prints our values alongside Brandt's for reference only -- diagnostic,
%   not an exact-match assertion, same spirit as ThrustConstraint's
%   testF16MaxMachRequiredTWTable.

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
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(), F16PropL2(), 4000);
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaBothWbySTbyW(tc)
            % TakeoffConstraint belongs to the Both_WbyS_TbyW category, same
            % as ThrustConstraint -- see TakeoffConstraint.m/
            % Both_WbyS_TbyW.m headers.
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(), F16PropL2(), 4000);
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(), F16PropL2(), 4000);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Takeoff", state, F16AeroL1(), F16PropL2(), 4000);
            tc.verifyEqual(obj.name, "Takeoff");
        end

        function testDefaultBetaAndKTO(tc)
            % beta and k_TO default to 1.0 and 1.2 (field constraints, per
            % subplans/06_constraint_analysis.md) when omitted.
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(), F16PropL2(), 4000);
            tc.verifyEqual(obj.beta, 1.0);
            tc.verifyEqual(obj.k_TO, 1.2);
        end

        % --- Equation assembly (generic, hand-computed) ---------------------

        function testRequiredTWMatchesHandComputedEquation(tc)
            % Arbitrary field length / margin (not F-16-specific data, just
            % uses the F-16 discipline objects as a concrete
            % AerodynamicsBase/PropulsionBase pair). Independently derived
            % form of the same equation, not a copy of TakeoffConstraint's
            % own algebra.
            aero  = F16AeroL1();
            prop  = F16PropL2();
            state = AircraftState(0, 0.1);
            S_G   = 3500;
            beta  = 0.98;
            k_TO  = 1.15;
            WS    = 90;

            CLmax_TO = aero.get_CLmax(state);
            alpha    = prop.thrust_lapse(state);
            rho      = state.rho;
            g        = 32.174;

            expected = (beta^2 / alpha) * (k_TO^2 / (rho * g * CLmax_TO)) * WS / S_G;

            obj      = TakeoffConstraint("Toy", state, aero, prop, S_G, beta, k_TO);
            received = obj.required_TW(WS);

            fprintf('\n    required_TW(WS=%d): received=%.6f  hand-computed=%.6f\n', WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'required_TW must equal the hand-computed takeoff equation.');
        end

        % --- Available/margin ------------------------------------------------

        function testTWMarginMatchesHandComputedFormula(tc)
            % Arbitrary field length/design point (not F-16-specific data).
            % Confirms Both_WbyS_TbyW.TW_margin (shared with ThrustConstraint,
            % see TestThrustConstraint.m) works correctly through
            % TakeoffConstraint's own required_TW/get_alpha (pure linear in
            % W/S, A=C=D=0 -- a different code path than ThrustConstraint's
            % bucket-shaped curve): margin = alpha*(T_SL/W_TO -
            % required_TW(WS_actual)), where alpha is TakeoffConstraint's own
            % get_alpha() (plain AB-basis lapse, no mil/AB distinction).
            % Requests TW_margin's 2nd/3rd (available/required) outputs
            % directly so both underlying constraint values are
            % independently verified, not just their combined margin.
            aero  = F16AeroL1();
            prop  = F16PropL2();
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 3500, 0.98, 1.15);

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
            aero  = F16AeroL1();
            prop  = F16PropL2();
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 4000);

            WS_range = 20:10:180;
            TW       = obj.required_TW(WS_range);

            tc.verifyEqual(numel(TW), numel(WS_range));
            tc.verifyTrue(all(isfinite(TW)), 'required_TW must be finite over the W/S sweep.');
        end

        function testRequiredTWLinearInWS(tc)
            % Unlike the Mattingly Master Equation (bucket-shaped), the
            % simplified takeoff relation is strictly linear in W/S:
            % required_TW = coeff * WS / S_G, so doubling WS must double TW.
            aero  = F16AeroL1();
            prop  = F16PropL2();
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 4000);

            WS    = 60;
            TW_1x = obj.required_TW(WS);
            TW_2x = obj.required_TW(2 * WS);

            tc.verifyEqual(TW_2x, 2 * TW_1x, 'RelTol', 1e-10, ...
                'required_TW must scale linearly with W/S.');
        end

        function testRequiredTWIncreasesWithGroundRoll(tc)
            % A shorter required ground roll demands a higher T/W at fixed
            % W/S (harder field-length requirement -> more thrust needed).
            aero  = F16AeroL1();
            prop  = F16PropL2();
            state = AircraftState(0, 0.1);
            WS    = 90;

            obj_short = TakeoffConstraint("Short field", state, aero, prop, 2000);
            obj_long  = TakeoffConstraint("Long field", state, aero, prop, 6000);

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
            aero  = F16AeroL3();
            prop  = F16PropL2();
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Takeoff", state, aero, prop, 4000, 1.0, 1.2);

            WS = 80;
            TW = obj.required_TW(WS);
            fprintf('\n    Takeoff required_TW at WS=%.2f: %.4f (CLmax used=%.4f)\n', ...
                WS, TW, aero.get_CLmax(state));
            tc.verifyGreaterThan(TW, 0, 'required_TW must be positive.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        function testF16TakeoffRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Takeoff condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [F16Baseline b.constraints.takeoff.TW_Takeoff].
            % Expect our values to read LOW vs. Brandt across the board:
            % Brandt's row includes the drag/rolling-friction term this
            % class's simplified equation omits (see class header) -- known
            % modeling gap, not a TakeoffConstraint bug.
            [aero, prop] = TestTakeoffConstraint.buildDisciplines(fidelityLevel);

            b     = F16Baseline();
            state = AircraftState(0, 0.1);   % sea level, near-zero Mach (avoids M=0 edge cases)
            obj   = TakeoffConstraint("Takeoff", state, aero, prop, 4000, 1.0, 1.2);

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
                    aero = F16AeroL1();
                    prop = F16PropL1();
                case 'L2'
                    aero = F16AeroL2();
                    prop = F16PropL2();
                case 'L3'
                    aero = F16AeroL3();
                    prop = F16PropL2();
                otherwise
                    error('TestTakeoffConstraint:buildDisciplines:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end

end
