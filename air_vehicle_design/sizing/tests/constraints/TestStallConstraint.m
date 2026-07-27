classdef TestStallConstraint < matlab.unittest.TestCase
%TESTSTALLCONSTRAINT  Unit tests for the generic StallConstraint class
%   (stall-speed upper bound on wing loading) and its F-16 "Stall"
%   instantiation.
%
%   Equation [level, unaccelerated flight at CLmax -- Raymer 6th ed. ch. 5
%   Eq. 5.5 rearranged for W/S; matches NPTEL_Fighter_Aircraft_Sizing.ipynb's
%   Stall class, per StallConstraint.m's header], as StallConstraint.m
%   implements it:
%
%     W_TO/S <= q * CLmax
%
%   testWSMaxMatchesHandComputedEquation checks WS_max against an
%   independently written form of the same equation (not a copy of
%   StallConstraint's own algebra) using the same aero discipline output
%   (get_CLmax -- already unit-tested elsewhere).
%
%   The F-16 Stall condition: Mach 0.217466 at sea level [Brandt F-16A.xls,
%   "Ps" sheet, cell B10 -- see F16Baseline.m's b.constraints.stall.mach;
%   see F16ConstraintSet.m's header note on this not yet being a
%   Constraints.xlsx row].

    properties (TestParameter)
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaPointPerformanceBase(tc)
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)));
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaOnlyWbyS(tc)
            % Stall belongs to the Only_WbyS category, same as
            % LandingConstraint -- see StallConstraint.m/Only_WbyS.m headers.
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)));
            tc.verifyTrue(isa(obj, 'Only_WbyS'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)));
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Stall", state, F16AeroL1(f16a_spec_path(1)));
            tc.verifyEqual(obj.name, "Stall");
        end

        % --- Equation assembly (generic, hand-computed) ---------------------

        function testWSMaxMatchesHandComputedEquation(tc)
            % Arbitrary flight condition (not F-16-specific data, just uses
            % an F-16 discipline object as a concrete AerodynamicsBase).
            % Independently derived form of the same equation, not a copy of
            % StallConstraint's own algebra.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.3);

            CLmax    = aero.get_CLmax(state);
            expected = state.q * CLmax;

            obj      = StallConstraint("Toy", state, aero);
            received = obj.WS_max();

            fprintf('\n    WS_max: received=%.4f  hand-computed=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'WS_max must equal the hand-computed stall equation.');
        end

        function testWSMaxIncreasesWithStallSpeed(tc)
            % A higher stall-speed requirement (higher Mach, same altitude)
            % permits a higher wing loading -- more dynamic pressure at CLmax.
            aero = F16AeroL1(f16a_spec_path(1));

            obj_slow = StallConstraint("Slow", AircraftState(0, 0.15), aero);
            obj_fast = StallConstraint("Fast", AircraftState(0, 0.30), aero);

            tc.verifyGreaterThan(obj_fast.WS_max(), obj_slow.WS_max(), ...
                'A higher stall-speed requirement must permit a higher WS_max.');
        end

        % --- Available/margin ------------------------------------------------

        function testWSMarginMatchesHandComputedFormula(tc)
            % Arbitrary flight condition (not F-16-specific data). Confirms
            % Only_WbyS.WS_margin (shared with LandingConstraint, see
            % TestLandingConstraint.m for the fuller battery of margin tests)
            % works correctly through StallConstraint's own WS_max():
            % margin = WS_required - WS_available, WS_required = WS_max(),
            % WS_available = W_TO/S_ref. Requests WS_margin's 2nd/3rd
            % (available/required) outputs directly so both underlying
            % constraint values are independently verified, not just their
            % combined margin.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.3);
            obj   = StallConstraint("Toy", state, aero);

            W_TO  = 30000;
            S_ref = 300;

            expected_required  = obj.WS_max();
            expected_available = W_TO / S_ref;
            expected_margin    = expected_required - expected_available;

            [received_margin, received_available, received_required] = obj.WS_margin(W_TO, S_ref);

            fprintf(['\n    WS_margin: required=%.4f  available=%.4f  margin=%.4f  ' ...
                '(hand-computed: required=%.4f  available=%.4f  margin=%.4f)\n'], ...
                received_required, received_available, received_margin, ...
                expected_required, expected_available, expected_margin);
            tc.verifyEqual(received_required, expected_required, 'RelTol', 1e-10, ...
                'WS_margin''s required output must equal WS_max().');
            tc.verifyEqual(received_available, expected_available, 'RelTol', 1e-10, ...
                'WS_margin''s available output must equal W_TO/S_ref.');
            tc.verifyEqual(received_margin, expected_margin, 'RelTol', 1e-10, ...
                'WS_margin must equal required minus available.');
        end

        % --- Vertical-wall required_TW encoding -----------------------------

        function testRequiredTWZeroAtOrBelowLimit(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, aero);
            WS_limit = obj.WS_max();

            tc.verifyEqual(obj.required_TW(WS_limit), 0);
            tc.verifyEqual(obj.required_TW(WS_limit * 0.5), 0);
        end

        function testRequiredTWInfAboveLimit(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, aero);
            WS_limit = obj.WS_max();

            tc.verifyEqual(obj.required_TW(WS_limit * 1.01), Inf);
            tc.verifyEqual(obj.required_TW(WS_limit * 5), Inf);
        end

        function testRequiredTWVectorizedOverWS(tc)
            % Constraint diagrams sweep W/S -- required_TW must vectorize
            % cleanly, staying finite below the limit and Inf above it.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, aero);
            WS_limit = obj.WS_max();

            WS_range = linspace(WS_limit * 0.2, WS_limit * 1.8, 21);
            TW = obj.required_TW(WS_range);

            tc.verifyEqual(numel(TW), numel(WS_range));
            tc.verifyTrue(all(TW(WS_range <= WS_limit) == 0), ...
                'required_TW must be 0 at or below the stall WS limit.');
            tc.verifyTrue(all(isinf(TW(WS_range > WS_limit))), ...
                'required_TW must be Inf above the stall WS limit.');
        end

        % --- F-16 Stall condition --------------------------------------------
        % Sea level, Mach 0.217466 (assignment stall-speed requirement)

        function testF16StallWSMaxByFidelityLevel(tc, fidelityLevel)
            % Sanity check only -- no Brandt Consts-sheet stall row to
            % compare against (Stall isn't part of Brandt's F-16A.xls
            % constraint set the way it appears in the NPTEL notebook).
            % Confirms the F-16 discipline objects produce a plausible,
            % finite, positive WS_max at the stall-speed flight condition.
            aero  = TestStallConstraint.buildAero(fidelityLevel);
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Stall", state, aero);

            WS_computed = obj.WS_max();
            fprintf('\n    [%s] Stall WS_max = %.3f lbf/ft^2 (CLmax used=%.4f)\n', ...
                fidelityLevel, WS_computed, aero.get_CLmax(state));

            tc.verifyGreaterThan(WS_computed, 0, sprintf('[%s] WS_max must be positive.', fidelityLevel));
            tc.verifyLessThan(WS_computed, 500, sprintf('[%s] WS_max implausibly high -- check for a gross error.', fidelityLevel));
        end

    end

    methods (Static, Access = private)

        function aero = buildAero(fidelityLevel)
        %BUILDAERO  F-16 aerodynamics discipline object for a fidelity level.
            switch fidelityLevel
                case 'L1'
                    aero = F16AeroL1(f16a_spec_path(1));
                case 'L2'
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
                case 'L3'
                    aero = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
                otherwise
                    error('TestStallConstraint:buildAero:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end

end
