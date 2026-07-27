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
            % 1 feasible-region fill + 1 thrust curve + 1 landing vertical line + 1 optimum marker
            tc.verifyEqual(numel(ax.Children), 4);
            tc.verifyTrue(any(arrayfun(@(h) isa(h, 'matlab.graphics.chart.decoration.ConstantLine'), ax.Children)), ...
                'Landing should render as a vertical ConstantLine (xline), not a regular curve.');
            tc.verifyTrue(any(arrayfun(@(h) isa(h, 'matlab.graphics.primitive.Patch'), ax.Children)), ...
                'Feasible region should render as a shaded Patch (fill).');
        end

        function testPlotDiagramFeasibleRegionStopsAtLandingWall(tc)
            % The feasible-region fill's top edge is the envelope, capped at
            % a fixed ceiling wherever a wall constraint drives it to Inf --
            % so the fill should have zero height (top == bottom) at W/S
            % values beyond the landing wall's limit, and positive height
            % below it.
            aero  = F16AeroL1();
            prop  = F16PropL2();
            state = AircraftState(20000, 0.8);
            WS_range = 20:2:200;

            thrust  = ThrustConstraint("Combat Turn", state, aero, prop, 0.95, 4.5, 0.0);
            landing = LandingConstraint("Landing", AircraftState(0, 0.1), aero, 4000, 0.5);

            ca  = ConstraintAnalysis({thrust, landing}, WS_range);
            fig = ca.plot_diagram();
            tc.addTeardown(@() close(fig));

            ax    = fig.CurrentAxes;
            patch = ax.Children(arrayfun(@(h) isa(h, 'matlab.graphics.primitive.Patch'), ax.Children));
            n     = numel(WS_range);
            ydata = patch.YData;
            % XData/YData are [WS_range, fliplr(WS_range)]: bottom edge (the
            % capped envelope) is the first n points, top edge (the ceiling)
            % is the last n points, reversed to match.
            bottom = ydata(1:n);
            top    = fliplr(ydata(n+1:end));

            beyondWall = WS_range > landing.WS_max();
            tc.verifyTrue(all(bottom(beyondWall) == top(beyondWall)), ...
                'Fill should have zero height beyond the landing wall (infeasible).');
            tc.verifyTrue(any(bottom(~beyondWall) < top(~beyondWall)), ...
                'Fill should have positive height below the landing wall (feasible).');
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

        % --- NaN vs Inf in a required_TW curve --------------------------------
        %
        % Inf and NaN are NOT interchangeable here. Inf is the documented way a
        % wall-type constraint says "infeasible above my W/S limit"
        % (LandingConstraint.m) and must keep working. NaN means the condition
        % could not be evaluated, and must be rejected -- see the next test for
        % why silence is the worst outcome.

        function testNaNConstraintCurveErrorsAtConstruction(tc)
            % Uses NaNCurveStub rather than a real ThrustConstraint on purpose:
            % Both_WbyS_TbyW.required_TW would throw first and the aggregator's
            % own guard would never be reached. Constraint categories outside
            % the Master Equation have no such upstream check, which is exactly
            % why ConstraintAnalysis needs this one.
            tc.verifyError(@() ConstraintAnalysis({NaNCurveStub("Bad", 3)}, 20:10:100), ...
                'ConstraintAnalysis:nanConstraintCurve');
        end

        function testNaNIsRejectedEvenAlongsideValidConstraints(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            good  = ThrustConstraint("Good", state, aero, prop, 0.9);

            tc.verifyError(@() ConstraintAnalysis({good, NaNCurveStub("Bad", 2)}, 20:10:100), ...
                'ConstraintAnalysis:nanConstraintCurve');
        end

        function testNaNWouldOtherwiseVanishFromTheEnvelope(tc)
            % Documents the failure mode the guard exists to prevent: MATLAB's
            % max() OMITS NaN by default, so an unevaluable constraint would
            % silently drop out of max(TW_table,[],1) and the design point would
            % be computed as though it had never been supplied -- no warning,
            % plausible-looking answer. This asserts the MATLAB behaviour
            % directly, so the test stays meaningful if the guard is ever moved.
            table_with_nan = [1 2 3; NaN NaN NaN];
            tc.verifyEqual(max(table_with_nan, [], 1), [1 2 3], ...
                'max() omits NaN -- an unguarded NaN row vanishes from the envelope.');
        end

        function testInfConstraintCurveIsStillAccepted(tc)
            % The guard must be NaN-only. A LandingConstraint returns Inf above
            % its W/S limit by design, so a ~isfinite() check here would break
            % every wall-type constraint.
            aero    = F16AeroL1(f16a_spec_path(1));
            landing = LandingConstraint("Landing", AircraftState(0, 0.1), aero, 4000, 0.5);
            WS_range = 20:2:200;

            ca = ConstraintAnalysis({landing}, WS_range);
            tc.verifyTrue(any(isinf(ca.TW_table(1,:))), ...
                'Precondition: this landing wall must produce Inf somewhere in the sweep.');
            tc.verifyFalse(any(isnan(ca.TW_table(1,:))), ...
                'A wall constraint must encode infeasibility as Inf, never NaN.');
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
