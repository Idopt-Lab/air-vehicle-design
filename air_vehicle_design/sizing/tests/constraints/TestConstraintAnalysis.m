classdef TestConstraintAnalysis < matlab.unittest.TestCase
%TESTCONSTRAINTANALYSIS  Unit tests for the generic ConstraintAnalysis
%   aggregator (constraint diagram + optimum design point).
%
%   ConstraintAnalysis takes a live list of PointPerformanceBase constraint
%   objects (not precomputed T/W arrays) and calls required_TW(WS_range) on
%   each itself -- see ConstraintAnalysis.m's header. These tests exercise
%   the AGGREGATION logic (envelope, argmin, mixed thrust/wall-type
%   rendering) using real ThrustConstraint/TakeoffConstraint/LandingConstraint
%   objects wired to F16AeroL1()/F16PropL2() as concrete stand-ins, the same
%   convention TestThrustConstraint/TestTakeoffConstraint/TestLandingConstraint
%   use ("not F-16-specific data, just uses the F-16 discipline objects as a
%   concrete AerodynamicsBase/PropulsionBase pair") -- NOT re-testing each
%   constraint class's own physics, which those files already cover
%   exhaustively.
%
%   Design-point definition: the optimum is the minimum, over W/S, of the
%   upper envelope of all supplied constraints' required_TW curves (Raymer
%   ch. 5 methodology, see ConstraintAnalysis.m header).

    methods (Test)

        function testOptimalPointMatchesIndependentEnvelopeComputation(tc)
            % Builds 2 arbitrary ThrustConstraint conditions (different
            % beta/n/Ps -- not F-16-specific data) and checks
            % ConstraintAnalysis.optimal_point() against an envelope/argmin
            % computed independently outside the class (looping
            % required_TW itself, exactly what ConstraintAnalysis does
            % internally) -- this exercises the aggregation wiring, not the
            % Master Equation itself (already covered by TestThrustConstraint).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            WS_range = 20:5:160;

            c1 = ThrustConstraint("C1", state, aero, prop, 0.95, 1.0, 0.0);
            c2 = ThrustConstraint("C2", state, aero, prop, 0.80, 3.0, 0.0);

            ca = ConstraintAnalysis({c1, c2}, WS_range);
            [WS_opt, TW_opt] = ca.optimal_point();

            TW_table = [c1.required_TW(WS_range); c2.required_TW(WS_range)];
            envelope = max(TW_table, [], 1);
            [expectedTW, idx] = min(envelope);
            expectedWS = WS_range(idx);

            tc.verifyEqual(WS_opt, expectedWS);
            tc.verifyEqual(TW_opt, expectedTW);
        end

        function testNamesAndTWTableCachedFromConstraints(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            WS_range = 20:10:180;

            c1 = ThrustConstraint("Cruise", state, aero, prop, 0.9);
            c2 = ThrustConstraint("Dash", state, aero, prop, 0.85, 1.0, 0.0);

            ca = ConstraintAnalysis({c1, c2}, WS_range);

            tc.verifyEqual(ca.names, ["Cruise", "Dash"]);
            tc.verifyEqual(ca.TW_table(1,:), c1.required_TW(WS_range));
            tc.verifyEqual(ca.TW_table(2,:), c2.required_TW(WS_range));
        end

        function testSingleConstraintOptimalPoint(tc)
            % A single bucket-shaped Master Equation curve -- optimal_point
            % should land at its minimum, cross-checked directly.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            WS_range = 10:2:200;

            c  = ThrustConstraint("Only", state, aero, prop, 0.95, 1.0, 0.0);
            ca = ConstraintAnalysis({c}, WS_range);
            [WS_opt, TW_opt] = ca.optimal_point();

            TW = c.required_TW(WS_range);
            [expectedTW, idx] = min(TW);
            tc.verifyEqual(TW_opt, expectedTW);
            tc.verifyEqual(WS_opt, WS_range(idx));
        end

        % --- Mixed thrust-type + wall-type (landing) constraints -----------

        function testMixedThrustAndLandingRespectsWSLimit(tc)
            % A LandingConstraint's vertical-wall required_TW (0 below its
            % WS_max, Inf above) must exclude infeasible W/S from the
            % optimum, combined uniformly with a thrust-type curve through
            % the same max-envelope -- no special-casing needed for
            % correctness (see LandingConstraint.m's header).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.8);
            WS_range = 20:2:200;

            thrust  = ThrustConstraint("Combat Turn", state, aero, prop, 0.95, 4.5, 0.0);
            landing = LandingConstraint("Landing", AircraftState(0, 0.1), aero, 4000, 0.5);

            ca = ConstraintAnalysis({thrust, landing}, WS_range);
            [WS_opt, TW_opt] = ca.optimal_point();

            tc.verifyLessThanOrEqual(WS_opt, landing.WS_max(), ...
                'Optimum W/S must not exceed the landing wing-loading limit.');
            tc.verifyTrue(isfinite(TW_opt), 'Optimum T/W must be finite (feasible).');
        end

        function testPlotDiagramRendersWallConstraintAsVerticalLine(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.8);
            WS_range = 20:2:200;

            thrust  = ThrustConstraint("Combat Turn", state, aero, prop, 0.95, 4.5, 0.0);
            landing = LandingConstraint("Landing", AircraftState(0, 0.1), aero, 4000, 0.5);

            ca  = ConstraintAnalysis({thrust, landing}, WS_range);
            fig = ca.plot_diagram();
            tc.addTeardown(@() close(fig));

            tc.verifyClass(fig, 'matlab.ui.Figure');
            ax = fig.CurrentAxes;
            % 1 thrust curve + 1 landing vertical line + 1 optimum marker
            tc.verifyEqual(numel(ax.Children), 3);
            tc.verifyTrue(any(arrayfun(@(h) isa(h, 'matlab.graphics.chart.decoration.ConstantLine'), ax.Children)), ...
                'Landing should render as a vertical ConstantLine (xline), not a regular curve.');
        end

        % --- Input validation -----------------------------------------------

        function testNonPointPerformanceBaseElementErrors(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            c = ThrustConstraint("Toy", state, aero, prop, 0.9);

            tc.verifyError(@() ConstraintAnalysis({c, 42}, 20:10:100), ...
                'ConstraintAnalysis:InvalidConstraint');
        end

        % --- Report -----------------------------------------------------------

        function testReportDoesNotError(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            c  = ThrustConstraint("Toy", state, aero, prop, 0.9);
            ca = ConstraintAnalysis({c}, 20:10:200);
            tc.verifyWarningFree(@() ca.report());
        end

    end

end
