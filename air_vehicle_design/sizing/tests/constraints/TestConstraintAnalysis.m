classdef TestConstraintAnalysis < matlab.unittest.TestCase
%TESTCONSTRAINTANALYSIS  Unit tests for the generic ConstraintAnalysis
%   aggregator (constraint diagram + optimum design point).
%
%   ConstraintAnalysis takes a live list of PointPerformanceBase constraint
%   objects (not precomputed T/W arrays). For required_TW PRODUCERS it calls
%   required_TW(WS_range); for Only_WbyS WALLS it reads WS_max() -- see
%   ConstraintAnalysis.m's header. These tests exercise the AGGREGATION logic
%   (producer envelope, wall restriction, argmin, mixed producer/wall
%   rendering) using real LevelFlight/SustainedTurn/TakeoffConstraint/
%   LandingConstraint objects wired to F16AeroL1(f16a_spec_path(1))/
%   F16PropL2(f16a_spec_path(2)) as concrete stand-ins, the same convention
%   the per-class tests use ("not F-16-specific data, just uses the F-16
%   discipline objects as a concrete AerodynamicsBase/PropulsionBase pair") --
%   NOT re-testing each constraint class's own physics, which those files
%   already cover exhaustively.
%
%   Design-point definition: the optimum is the minimum, over W/S, of the
%   upper envelope of all supplied constraints' required_TW curves (Raymer
%   ch. 5 methodology, see ConstraintAnalysis.m header).

    methods (Test)

        function testOptimalPointMatchesIndependentEnvelopeComputation(tc)
            % Builds 2 arbitrary Master-Equation conditions (different
            % beta/n -- not F-16-specific data) and checks
            % ConstraintAnalysis.optimal_point() against an envelope/argmin
            % computed independently outside the class (looping
            % required_TW itself, exactly what ConstraintAnalysis does
            % internally) -- this exercises the aggregation wiring, not the
            % Master Equation itself (already covered by the per-class tests).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            WS_range = 20:5:160;

            c1 = LevelFlightConstraint("C1", state, aero, prop, 0.95);
            c2 = SustainedTurnConstraint("C2", state, aero, prop, 0.80, 3.0);

            ca = ConstraintAnalysis({c1, c2}, WS_range);
            [WS_opt, TW_opt] = ca.optimal_point();

            TW_table = [c1.required_TW(WS_range); c2.required_TW(WS_range)];
            envelope = max(TW_table, [], 1);
            [expectedTW, idx] = min(envelope);
            expectedWS = WS_range(idx);

            tc.verifyEqual(WS_opt, expectedWS);
            tc.verifyEqual(TW_opt, expectedTW);
        end

        function testEnvelopeRecomputedOnDemandFromConstraints(tc)
            % ConstraintAnalysis no longer caches a names/TW_table pair at
            % construction (that could go stale when an injected discipline
            % mutates -- see testOptimalPointTracksMutatedDiscipline). It
            % stores only {constraints, WS_range} and rebuilds the rows on
            % every read. This test checks the on-demand envelope() matches an
            % independent max over each constraint's own required_TW curve.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            WS_range = 20:10:180;

            c1 = LevelFlightConstraint("Cruise", state, aero, prop, 0.9);
            c2 = LevelFlightConstraint("Dash", state, aero, prop, 0.85);

            ca = ConstraintAnalysis({c1, c2}, WS_range);

            expectedEnv = max([c1.required_TW(WS_range); c2.required_TW(WS_range)], [], 1);
            tc.verifyEqual(ca.envelope(), expectedEnv);
        end

        function testOptimalPointTracksMutatedDiscipline(tc)
            % RECOMPUTE-ON-READ: because ConstraintAnalysis stores only its
            % inputs and rebuilds the rows on every read, mutating an injected
            % discipline object AFTER construction must change the next
            % optimal_point() -- the design point can no longer go stale off a
            % cached TW_table. A mutable FixedAeroStub feeds a real
            % LevelFlightConstraint; bumping its CD0 raises the A = q*CD0/alpha
            % term (the A/(W/S) branch of the Master Equation), so the required
            % T/W -- and hence the envelope minimum -- must rise.
            aero  = FixedAeroStub(1.2, 0.020, 0.10, 0.0);   % CLmax, CD0, K1, K2
            prop  = FixedPropStub(0.8);                     % alpha
            state = AircraftState(20000, 0.8);
            WS_range = 20:5:160;

            c  = LevelFlightConstraint("Toy", state, aero, prop, 0.9);
            ca = ConstraintAnalysis({c}, WS_range);

            [WS_before, TW_before] = ca.optimal_point();

            aero.CD0 = 0.060;   % triple the zero-lift drag on the SAME object

            [WS_after, TW_after] = ca.optimal_point();

            tc.verifyGreaterThan(TW_after, TW_before, ...
                'Optimum T/W must rise after CD0 is increased -- proves no stale cache.');
            tc.verifyNotEqual([WS_after, TW_after], [WS_before, TW_before], ...
                'The design point must change after the injected aero object is mutated.');
        end

        function testSingleConstraintOptimalPoint(tc)
            % A single bucket-shaped Master Equation curve -- optimal_point
            % should land at its minimum, cross-checked directly.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            WS_range = 10:2:200;

            c  = LevelFlightConstraint("Only", state, aero, prop, 0.95);
            ca = ConstraintAnalysis({c}, WS_range);
            [WS_opt, TW_opt] = ca.optimal_point();

            TW = c.required_TW(WS_range);
            [expectedTW, idx] = min(TW);
            tc.verifyEqual(TW_opt, expectedTW);
            tc.verifyEqual(WS_opt, WS_range(idx));
        end

        % --- Mixed thrust-type + wall-type (landing) constraints -----------

        function testMixedThrustAndLandingRespectsWSLimit(tc)
            % A LandingConstraint is a W/S WALL (Only_WbyS): ConstraintAnalysis
            % restricts the optimum search to W/S at or below its WS_max()
            % (T9), so the optimum can never land beyond the landing limit,
            % combined with the thrust-type producer curve through the
            % producer envelope. See ConstraintAnalysis.m's header.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.8);
            % Widened from 20:2:200 (2026-07-27): LandingConstraint now uses
            % F16AeroL1's FLAPPED get_CLmax_L()=2.10/get_Delta_CD0_L() rather
            % than clean values (see LandingConstraint.m's header), and L1's
            % Roskam Table 3.1 category-mean CLmax_L is a documented
            % overshoot vs. the real F-16 (2.10 vs. Brandt's 1.4260, +47%,
            % see aerodynamics_brandt_comparison.md) -- this pushes this toy
            % LandingConstraint's WS_max (mu=0.5, S_FR=4000 ft) to ~205 psf,
            % above the old range's 200 ceiling. 260 comfortably re-brackets
            % it; the other WS_range = 20:2:200 sites below in this file were
            % widened for the same reason.
            WS_range = 20:2:260;

            thrust  = SustainedTurnConstraint("Combat Turn", state, aero, prop, 0.95, 4.5);
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
            WS_range = 20:2:260;   % widened -- see testMixedThrustAndLandingRespectsWSLimit's comment

            thrust  = SustainedTurnConstraint("Combat Turn", state, aero, prop, 0.95, 4.5);
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
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.8);
            WS_range = 20:2:260;   % widened -- see testMixedThrustAndLandingRespectsWSLimit's comment

            thrust  = SustainedTurnConstraint("Combat Turn", state, aero, prop, 0.95, 4.5);
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
            c = LevelFlightConstraint("Toy", state, aero, prop, 0.9);

            tc.verifyError(@() ConstraintAnalysis({c, 42}, 20:10:100), ...
                'ConstraintAnalysis:InvalidConstraint');
        end

        % --- Wall handling (Only_WbyS via WS_max) -----------------------------
        %
        % T9 removed the aggregator NaN guard and the Inf-wall-in-envelope
        % hack: an Only_WbyS is now an explicit W/S wall, not a fake 0/Inf
        % curve. Each required_TW PRODUCER self-guards a non-finite term
        % (MasterEquationConstraint/TakeoffConstraint throw), so the aggregator
        % no longer needs its own NaN check. A wall never enters the producer
        % envelope at all -- it only restricts the optimum search via WS_max().

        function testWallOnlySetGivesNoProducerEnvelope(tc)
            % With a single Only_WbyS (Landing) and no producers, the producer
            % envelope is empty -> -Inf everywhere (never NaN or Inf-from-a-
            % fake-curve). The wall still bounds the feasible W/S band.
            aero    = F16AeroL1(f16a_spec_path(1));
            landing = LandingConstraint("Landing", AircraftState(0, 0.1), aero, 4000, 0.5);
            WS_range = 20:2:260;   % widened -- see testMixedThrustAndLandingRespectsWSLimit's comment

            ca  = ConstraintAnalysis({landing}, WS_range);
            env = ca.envelope();
            tc.verifyTrue(all(env == -Inf), ...
                'With no producers the envelope must be -Inf everywhere (walls add no curve).');
            tc.verifyFalse(any(isnan(env)), ...
                'The envelope must never contain NaN.');
        end

        % --- Report -----------------------------------------------------------

        function testReportDoesNotError(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            c  = LevelFlightConstraint("Toy", state, aero, prop, 0.9);
            ca = ConstraintAnalysis({c}, 20:10:200);
            tc.verifyWarningFree(@() ca.report());
        end

    end

end
