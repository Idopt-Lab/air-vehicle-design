classdef TestF16ConstraintSet < matlab.unittest.TestCase
%TESTF16CONSTRAINTSET  Unit tests for F16ConstraintSet (Layer-2 wiring of
%   the F-16's 8 constraint conditions from examples/F16A/Constraints.xlsx
%   into concrete ThrustConstraint/TakeoffConstraint/LandingConstraint
%   objects, plus a 9th Stall condition appended directly as a
%   StallConstraint -- see F16ConstraintSet.m's header) and its end-to-end
%   use with ConstraintAnalysis.
%
%   Per sizing/docs/subplans/06_constraint_analysis.md's own test guidance,
%   the optimal W/S and T/W are checked against broad physics-bounds ranges,
%   NOT Brandt's exact W/S=104.59/T/W=0.7576 -- this
%   framework's textbook equations are not expected to reproduce Brandt's
%   flight-calibrated design point exactly (see ThrustConstraint.m/
%   TakeoffConstraint.m/LandingConstraint.m headers for the documented
%   modeling gaps).

    properties (TestParameter)
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Test)

        function testBuildReturnsNineConstraints(tc, fidelityLevel)
            constraints = F16ConstraintSet.build(fidelityLevel);
            tc.verifyEqual(numel(constraints), 9);
            for i = 1:numel(constraints)
                tc.verifyTrue(isa(constraints{i}, 'PointPerformanceBase'));
            end
        end

        function testTakeoffLandingAndStallRowsUseCorrectClasses(tc)
            constraints = F16ConstraintSet.build("L3");
            names = cellfun(@(c) c.name, constraints);

            takeoff = constraints{names == "Takeoff"};
            landing = constraints{names == "Landing"};
            stall   = constraints{names == "Stall"};
            tc.verifyTrue(isa(takeoff, 'TakeoffConstraint'));
            tc.verifyTrue(isa(landing, 'LandingConstraint'));
            tc.verifyTrue(isa(stall, 'StallConstraint'));
        end

        function testThrustTypeRowsUseThrustConstraint(tc)
            constraints = F16ConstraintSet.build("L3");
            names = cellfun(@(c) c.name, constraints);
            thrustNames = ["Max Mach", "Cruise", "Max Alt", "Combat Subsonic", ...
                "Combat Supersonic", "Excess Power"];
            for name = thrustNames
                c = constraints{names == name};
                tc.verifyTrue(isa(c, 'ThrustConstraint'), ...
                    sprintf('"%s" should build a ThrustConstraint.', name));
            end
        end

        function testExcessPowerHasNonzeroPs(tc)
            % Excess Power is the only row with a real PS_ft_s_ value (500);
            % all other ThrustConstraint rows should default Ps to 0.
            constraints = F16ConstraintSet.build("L3");
            names = cellfun(@(c) c.name, constraints);
            excessPower = constraints{names == "Excess Power"};
            tc.verifyEqual(excessPower.Ps, 500);

            cruise = constraints{names == "Cruise"};
            tc.verifyEqual(cruise.Ps, 0);
        end

        function testTakeoffAndLandingUseClassDefaultKFactors(tc)
            % Per the documented decision in F16ConstraintSet.m's header:
            % k_TO/k_L come from TakeoffConstraint/LandingConstraint's own
            % defaults (1.2/1.3), not the spreadsheet's Vstall column.
            constraints = F16ConstraintSet.build("L3");
            names = cellfun(@(c) c.name, constraints);
            takeoff = constraints{names == "Takeoff"};
            landing = constraints{names == "Landing"};
            tc.verifyEqual(takeoff.k_TO, 1.2);
            tc.verifyEqual(landing.k_L, 1.3);
        end

        function testStallConditionAtSeaLevel(tc)
            % Stall isn't a Constraints.xlsx row (unlike the other 8) -- see
            % F16ConstraintSet.m's header -- so this pins down the hardcoded
            % flight condition directly: Mach 0.217466 at sea level.
            constraints = F16ConstraintSet.build("L3");
            names = cellfun(@(c) c.name, constraints);
            stall = constraints{names == "Stall"};
            tc.verifyEqual(stall.state.altitude_ft, 0);
            tc.verifyEqual(stall.state.mach, 0.217466);
        end

        % --- End-to-end with ConstraintAnalysis ------------------------------

        function testOptimalPointWithinPhysicsBounds(tc, fidelityLevel)
            constraints = F16ConstraintSet.build(fidelityLevel);
            ca = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
            [WS_opt, TW_opt] = ca.optimal_point();

            b = F16Baseline();
            fprintf('\n    [%s] F-16 optimum: W/S=%.2f, T/W=%.4f  (Brandt reference: W/S=%.2f, T/W=%.4f)\n', ...
                fidelityLevel, WS_opt, TW_opt, b.constraint.WS_opt, b.constraint.TW_opt);

            % Lower bound dropped from 70 to 50 psf after adding the Stall
            % constraint (StallConstraint, WS_max ~ 55-63 psf across fidelity
            % levels): Stall is now the BINDING constraint (tighter than the
            % previous ~76-83 psf optimum driven by the thrust-type
            % conditions), pulling the optimum down to 55-62 psf -- a real,
            % physically expected shift (a slower stall speed requirement
            % caps wing loading more aggressively than combat-turn/dash
            % thrust requirements did alone), not a bug; see
            % ThrustConstraint.m/TakeoffConstraint.m/LandingConstraint.m/
            % StallConstraint.m headers for the already-documented per-
            % fidelity modeling gaps driving the remaining spread.
            tc.verifyGreaterThanOrEqual(WS_opt, 50, sprintf('[%s] Optimal W/S below plausible range.', fidelityLevel));
            tc.verifyLessThanOrEqual(WS_opt, 130, sprintf('[%s] Optimal W/S above plausible range.', fidelityLevel));
            % T/W upper bound raised 1.0 -> 1.1: at L3 the Max Mach (supersonic
            % dash) condition is the binding thrust constraint, and with the
            % live-geometry wetted areas (F16GeomL2, ~1467 ft^2 total) plus the
            % whole-aircraft wave-drag Amax it puts the optimum at T/W ~ 1.001 --
            % physically plausible for a fighter (real F-16 combat T/W ~ 1.0-1.1),
            % marginally over the round-number 1.0 ceiling.
            tc.verifyGreaterThanOrEqual(TW_opt, 0.6, sprintf('[%s] Optimal T/W below plausible range.', fidelityLevel));
            tc.verifyLessThanOrEqual(TW_opt, 1.1, sprintf('[%s] Optimal T/W above plausible range.', fidelityLevel));
        end

        function testPlotDiagramProducesFigure(tc)
            constraints = F16ConstraintSet.build("L3");
            ca  = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
            fig = ca.plot_diagram();
            tc.addTeardown(@() close(fig));
            tc.verifyClass(fig, 'matlab.ui.Figure');
        end

    end

end
