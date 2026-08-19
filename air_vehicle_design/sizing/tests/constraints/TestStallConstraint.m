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
%   "Ps" sheet, cell B10; see F16ConstraintSet.m's header note on this not
%   yet being a Constraints.xlsx row].

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

        % --- Feasibility residual --------------------------------------------

        function testConstraintResidualFeasibleAndInfeasible(tc)
            % Arbitrary flight condition (not F-16-specific data). Confirms
            % Only_WbyS.constraint_residual (shared with LandingConstraint, see
            % TestLandingConstraint.m for the fuller battery) works through
            % StallConstraint's own WS_max(): g = dp.WS - WS_max(), g <= 0
            % feasible (design at/below the stall W/S wall), g > 0 infeasible.
            % dp.TW is unused for a W/S-wall condition. Hand-computes g at one
            % FEASIBLE and one INFEASIBLE DesignPoint (a light and a heavy wing
            % loading straddling WS_max).
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.3);
            obj   = StallConstraint("Toy", state, aero);

            WS_limit = obj.WS_max();
            S_ref    = 300;

            % Feasible: WS = 0.5*WS_limit (below the wall) -> g < 0.
            W_TO_feas  = 0.5 * WS_limit * S_ref;
            dp_feas    = DesignPoint(W_TO_feas, 20000, S_ref);
            g_feas     = obj.constraint_residual(dp_feas);
            expected_g_feas = dp_feas.WS - WS_limit;

            % Infeasible: WS = 1.5*WS_limit (above the wall) -> g > 0.
            W_TO_infeas = 1.5 * WS_limit * S_ref;
            dp_infeas   = DesignPoint(W_TO_infeas, 20000, S_ref);
            g_infeas    = obj.constraint_residual(dp_infeas);
            expected_g_infeas = dp_infeas.WS - WS_limit;

            fprintf('\n    constraint_residual: feasible g=%.4f  infeasible g=%.4f  (WS_max=%.4f)\n', ...
                g_feas, g_infeas, WS_limit);

            tc.verifyEqual(g_feas, expected_g_feas, 'RelTol', 1e-10, ...
                'constraint_residual must equal dp.WS - WS_max().');
            tc.verifyLessThan(g_feas, 0, ...
                'A design below the stall W/S wall must be feasible (g < 0).');
            tc.verifyEqual(g_infeas, expected_g_infeas, 'RelTol', 1e-10, ...
                'constraint_residual must equal dp.WS - WS_max().');
            tc.verifyGreaterThan(g_infeas, 0, ...
                'A design above the stall W/S wall must be infeasible (g > 0).');
        end

        function testConstraintResidualZeroAtWall(tc)
            % A design sitting exactly on the wall (dp.WS == WS_max) is the
            % feasibility boundary: g == 0.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.3);
            obj   = StallConstraint("Toy", state, aero);

            WS_limit = obj.WS_max();
            S_ref    = 300;
            W_TO     = WS_limit * S_ref;   % dp.WS == WS_max exactly
            dp       = DesignPoint(W_TO, 20000, S_ref);

            tc.verifyEqual(obj.constraint_residual(dp), 0, 'AbsTol', 1e-9, ...
                'constraint_residual must be ~0 when dp.WS exactly equals WS_max().');
        end

        % --- W/S wall via WS_max (no required_TW) ----------------------------
        %
        % T9 removed the old 0/Inf "wall curve" required_TW encoding from
        % Only_WbyS: a stall wall now bounds W/S through WS_max() alone, and
        % has NO required_TW at all (ConstraintAnalysis restricts the optimum
        % search to W/S <= WS_max rather than folding a fake curve into the
        % max-envelope). These tests replace the deleted required_TW-encoding
        % tests.

        function testHasNoRequiredTWMethod(tc)
            % An Only_WbyS wall exposes no required_TW -- it imposes no thrust
            % demand. The method must be gone (removed in T9).
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, aero);
            tc.verifyFalse(ismethod(obj, 'required_TW'), ...
                'Only_WbyS conditions must not expose a required_TW (T9).');
        end

        function testWSMaxIsFiniteAndPositive(tc)
            % The wall is a finite, positive W/S upper bound.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.217466);
            obj   = StallConstraint("Toy", state, aero);
            WS_limit = obj.WS_max();
            tc.verifyTrue(isfinite(WS_limit) && WS_limit > 0, ...
                'The stall W/S wall must be finite and positive.');
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
                    aero = F16AeroL3(F16GeomL3(f16a_spec_path(3), F16PropL2(f16a_spec_path(2)), f16a_requirements_path()), f16a_spec_path(3));
                otherwise
                    error('TestStallConstraint:buildAero:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end

end
