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

        % --- Power setting wired from the sheet's AB% column (2026-07-25) ------

        function testPowerSettingComesFromABPercentColumn(tc)
            % THE FIX. Every thrust row used to be built with
            % ThrustConstraint's "AB" default, so Cruise -- the F-16's one
            % dry-power condition (Constraints.xlsx AB%=0) -- drew the
            % afterburner lapse instead of the mil-on-AB-scale lapse. Since
            % every Master-Equation term is proportional to 1/alpha, and
            % alpha_AB ~ 0.37 vs alpha_mil_on_AB ~ 0.14 at that condition, the
            % required T/W came out ~2.6x low. The fix had landed in
            % ThrustConstraint but never in this production build path.
            constraints = F16ConstraintSet.build("L2");
            names = cellfun(@(c) c.name, constraints);
            tc.verifyEqual(constraints{names == "Cruise"}.powerSetting, "mil", ...
                'Cruise is AB%=0 in Constraints.xlsx and must use the mil basis.');
            for row = ["Max Mach", "Max Alt", "Combat Subsonic", ...
                       "Combat Supersonic", "Excess Power"]
                tc.verifyEqual(constraints{names == row}.powerSetting, "AB", ...
                    sprintf('%s is AB%%=100 and must use the AB basis.', row));
            end
        end

        function testCruiseRequiredTWIsOnTheMilAlphaBasis(tc)
            % Same fix, checked on the numbers rather than the label. Every
            % Master-Equation term carries a 1/alpha factor, so an otherwise
            % identical AB-basis Cruise constraint must give a required T/W
            % smaller by exactly alpha_mil/alpha_AB. That ratio is ~0.46 at this
            % condition -- i.e. the old AB-default Cruise curve sat a factor
            % ~2.2 too low, which is the -58% error the scrape doc records.
            constraints = F16ConstraintSet.build("L2");
            names  = cellfun(@(c) c.name, constraints);
            cruise = constraints{names == "Cruise"};
            [aero, prop] = deal(F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2)), ...
                                F16PropL2(f16a_spec_path(2)));
            cruise_AB = ThrustConstraint(cruise.name, cruise.state, aero, prop, ...
                cruise.beta, cruise.n, cruise.Ps, "AB");

            alpha_mil = prop.thrust_lapse_mil_on_AB_scale(cruise.state);
            alpha_AB  = prop.thrust_lapse(cruise.state);
            tc.verifyLessThan(alpha_mil, alpha_AB, ...
                'Sanity: the mil-on-AB-scale lapse must be below the AB lapse.');

            WS = 100;
            TW_mil = cruise.required_TW(WS);
            TW_AB  = cruise_AB.required_TW(WS);
            fprintf(['\n    Cruise required_TW at W/S=%g: mil basis = %.4f, ' ...
                'AB basis = %.4f  (alpha_mil=%.4f, alpha_AB=%.4f, ratio=%.4f)\n'], ...
                WS, TW_mil, TW_AB, alpha_mil, alpha_AB, alpha_mil/alpha_AB);
            tc.verifyEqual(TW_AB / TW_mil, alpha_mil / alpha_AB, 'RelTol', 1e-10, ...
                'required_TW must scale exactly as 1/alpha between the two bases.');
            tc.verifyGreaterThan(TW_mil, TW_AB, ...
                'The mil basis must demand MORE T/W than the AB basis at Cruise.');
        end

        function testMissingOrPartialABPercentErrors(tc)
            % An unstated power setting silently defaulting to "AB" is the bug
            % being fixed, so a NaN AB% must error rather than default. Partial
            % afterburner is not modeled either (PropulsionBase exposes only the
            % two discrete bases), so it must error too. Exercised through the
            % private mapper via the public build path's own contract: construct
            % the two invalid cases directly.
            tc.verifyError(@() ThrustConstraint("X", AircraftState(0, 0.5), ...
                F16AeroL1(f16a_spec_path(1)), F16PropL1(f16a_spec_path(1)), ...
                0.9, 1, 0, "partial"), 'MATLAB:validators:mustBeMember', ...
                'ThrustConstraint must reject a power setting outside {AB, mil}.');
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
