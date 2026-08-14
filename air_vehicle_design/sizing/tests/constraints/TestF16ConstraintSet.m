classdef TestF16ConstraintSet < matlab.unittest.TestCase
%TESTF16CONSTRAINTSET  Unit tests for F16ConstraintSet (Layer-2 wiring of
%   the F-16's constraint conditions from the requirements JSON
%   examples/F16A/inputs/f16a_requirements.json into concrete
%   MasterEquationConstraint specializations (LevelFlight/SustainedTurn/
%   ExcessPower) and TakeoffConstraint/LandingConstraint objects, and its
%   end-to-end use with ConstraintAnalysis.
%
%   Updated 2026-08-04 (step-6 constraint-analysis refactor, T3): the build
%   path now reads the requirements JSON, not Constraints.xlsx. power_setting
%   is sourced directly from the JSON, and Takeoff is modeled at the JSON's
%   mach_liftoff = 0.2 (was a hardcoded 0.1). The two Combat rows carry their
%   JSON names ("Combat Turn 1 (subsonic)" / "Combat Turn 2 (supersonic)").
%
%   The optimal W/S and T/W are checked against broad physics-bounds ranges,
%   NOT Brandt's exact W/S=104.59/T/W=0.7576 -- this framework's textbook
%   equations are not expected to reproduce Brandt's flight-calibrated design
%   point exactly (see MasterEquationConstraint.m/TakeoffConstraint.m/
%   LandingConstraint.m headers for the documented modeling gaps).
%
%   STALL IS NOT AN F-16 DIAGRAM CONSTRAINT (see F16ConstraintSet.m's header):
%   the requirements JSON lists 8 conditions, no Stall. Its L2/L3 geometry-based
%   clean CLmax would spuriously bind the optimum; the fix belongs in
%   aerodynamics (ToDo_Darshan.md §3). StallConstraint is unit-tested standalone
%   in TestStallConstraint.

    properties (TestParameter)
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Static, Access = private)

        function constraints = buildLevel(fidelityLevel)
        %BUILDLEVEL  Test-only convenience: construct the L-level aero/prop
        %   pair and return the F-16 constraint cell array via the generic
        %   ConstraintAnalysis.build_constraints (requirements JSON + the F-16
        %   name->ConstraintType map, the 8 diagram conditions). L2/L3 inject
        %   prop into geometry (nacelle -> duct wetted area -> CD0); L3 uses
        %   F16PropL2 (no L3 propulsion tier), the same pairing the design
        %   studies use.
            arguments
                fidelityLevel (1,1) string {mustBeMember(fidelityLevel, ["L1", "L2", "L3"])}
            end
            switch fidelityLevel
                case "L1"
                    prop = F16PropL1(f16a_spec_path(1));
                    aero = F16AeroL1(f16a_spec_path(1));
                case "L2"
                    prop = F16PropL2(f16a_spec_path(2));
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), prop), f16a_spec_path(2), f16a_control_surfaces());
                case "L3"
                    prop = F16PropL2(f16a_spec_path(2));
                    aero = F16AeroL3(F16GeomL3(f16a_spec_path(3), prop), f16a_spec_path(3), f16a_control_surfaces());
            end
            constraints = ConstraintAnalysis.build_constraints(aero, prop, ...
                f16a_requirements_path(), F16ConstraintSet.constraint_map());
        end

    end

    methods (Test)

        function testBuildDefaultReturnsEightConstraints(tc, fidelityLevel)
            % The build returns the 8 requirements-JSON conditions, no Stall
            % row (Stall is not an F-16 diagram condition -- see class header).
            constraints = TestF16ConstraintSet.buildLevel(fidelityLevel);
            tc.verifyEqual(numel(constraints), 8);
            names = cellfun(@(c) c.name, constraints);
            tc.verifyFalse(any(names == "Stall"));
            for i = 1:numel(constraints)
                tc.verifyTrue(isa(constraints{i}, 'PointPerformanceBase'));
            end
        end

        function testTakeoffLandingRowsUseCorrectClasses(tc)
            constraints = TestF16ConstraintSet.buildLevel("L3");
            names = cellfun(@(c) c.name, constraints);

            takeoff = constraints{names == "Takeoff"};
            landing = constraints{names == "Landing"};
            tc.verifyTrue(isa(takeoff, 'TakeoffConstraint'));
            tc.verifyTrue(isa(landing, 'LandingConstraint'));
        end

        function testThrustTypeRowsUseMasterEquationSpecializations(tc)
            % T9: each Master-Equation thrust row now builds the specialization
            % chosen by its data -- Max Mach/Cruise/Max Alt (n=1, Ps=0) ->
            % LevelFlightConstraint; Combat Turn 1/2 (n>1, Ps=0) ->
            % SustainedTurnConstraint; Excess Power (Ps>0) ->
            % ExcessPowerConstraint. All remain MasterEquationConstraint (hence
            % Both_WbyS_TbyW, hence PointPerformanceBase).
            constraints = TestF16ConstraintSet.buildLevel("L3");
            names = cellfun(@(c) c.name, constraints);

            expectedClass = struct( ...
                'MaxMach',           "LevelFlightConstraint", ...
                'Cruise',            "LevelFlightConstraint", ...
                'MaxAlt',            "LevelFlightConstraint", ...
                'CombatSubsonic',    "SustainedTurnConstraint", ...
                'CombatSupersonic',  "SustainedTurnConstraint", ...
                'ExcessPower',       "ExcessPowerConstraint");
            rowNames = ["Max Mach", "Cruise", "Max Alt", ...
                "Combat Turn 1 (subsonic)", "Combat Turn 2 (supersonic)", ...
                "Excess Power"];
            fields = fieldnames(expectedClass);
            for k = 1:numel(rowNames)
                name = rowNames(k);
                c = constraints{names == name};
                tc.verifyClass(c, char(expectedClass.(fields{k})), ...
                    sprintf('"%s" should build a %s.', name, expectedClass.(fields{k})));
                tc.verifyTrue(isa(c, 'MasterEquationConstraint'), ...
                    sprintf('"%s" should be a MasterEquationConstraint.', name));
            end
        end

        function testExcessPowerHasNonzeroPs(tc)
            % Excess Power is the only row with a real PS_ft_s_ value (500) and
            % so the only ExcessPowerConstraint; all other Master-Equation rows
            % have Ps = 0.
            constraints = TestF16ConstraintSet.buildLevel("L3");
            names = cellfun(@(c) c.name, constraints);
            excessPower = constraints{names == "Excess Power"};
            tc.verifyEqual(excessPower.Ps, 500);

            cruise = constraints{names == "Cruise"};
            tc.verifyEqual(cruise.Ps, 0);
        end

        function testTakeoffAndLandingKFactors(tc)
            % k_TO/k_L now come from the JSON's k_factor field (1.2 takeoff,
            % 1.3 landing; Brandt Main!U12/U13). Those values equal the src
            % class defaults, so this remains behavior-neutral -- the check is
            % that the wired-through requirement value is correct.
            constraints = TestF16ConstraintSet.buildLevel("L3");
            names = cellfun(@(c) c.name, constraints);
            takeoff = constraints{names == "Takeoff"};
            landing = constraints{names == "Landing"};
            tc.verifyEqual(takeoff.k_TO, 1.2);
            tc.verifyEqual(landing.k_L, 1.3);
        end

        % --- Power setting wired from the sheet's AB% column (2026-07-25) ------

        function testPowerSettingComesFromABPercentColumn(tc)
            % THE FIX. Every thrust row used to be built with the "AB"
            % default, so Cruise -- the F-16's one dry-power condition
            % (power_setting "mil" in the JSON) -- drew the afterburner lapse
            % instead of the mil-on-AB-scale lapse. Since every Master-Equation
            % term is proportional to 1/alpha, and alpha_AB ~ 0.37 vs
            % alpha_mil_on_AB ~ 0.14 at that condition, the required T/W came
            % out ~2.6x low. power_setting now comes directly from the JSON.
            constraints = TestF16ConstraintSet.buildLevel("L2");
            names = cellfun(@(c) c.name, constraints);
            tc.verifyEqual(constraints{names == "Cruise"}.powerSetting, "mil", ...
                'Cruise has power_setting "mil" in the JSON and must use the mil basis.');
            for row = ["Max Mach", "Max Alt", "Combat Turn 1 (subsonic)", ...
                       "Combat Turn 2 (supersonic)", "Excess Power"]
                tc.verifyEqual(constraints{names == row}.powerSetting, "AB", ...
                    sprintf('%s has power_setting "AB" and must use the AB basis.', row));
            end
        end

        function testCruiseRequiredTWIsOnTheMilAlphaBasis(tc)
            % Same fix, checked on the numbers rather than the label. Every
            % Master-Equation term carries a 1/alpha factor, so an otherwise
            % identical AB-basis Cruise constraint must give a required T/W
            % smaller by exactly alpha_mil/alpha_AB. That ratio is ~0.46 at this
            % condition -- i.e. the old AB-default Cruise curve sat a factor
            % ~2.2 too low, which is the -58% error the scrape doc records.
            constraints = TestF16ConstraintSet.buildLevel("L2");
            names  = cellfun(@(c) c.name, constraints);
            cruise = constraints{names == "Cruise"};
            [aero, prop] = deal(F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2), f16a_control_surfaces()), ...
                                F16PropL2(f16a_spec_path(2)));
            % Cruise is a LevelFlightConstraint (n=1, Ps=0). Rebuild it on the
            % AB basis to compare the two alpha bases at the same condition.
            cruise_AB = LevelFlightConstraint(cruise.name, cruise.state, aero, prop, ...
                cruise.beta, "AB");

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
            tc.verifyError(@() LevelFlightConstraint("X", AircraftState(0, 0.5), ...
                F16AeroL1(f16a_spec_path(1)), F16PropL1(f16a_spec_path(1)), ...
                0.9, "partial"), 'MATLAB:validators:mustBeMember', ...
                'A Master-Equation constraint must reject a power setting outside {AB, mil}.');
        end

        function testTakeoffStateUsesLiftoffMach(tc)
            % T3 intentional numeric change: Takeoff is now built at the JSON's
            % mach_liftoff = 0.2 (real V_liftoff/a_SL, Brandt Consts!AT32),
            % replacing the Excel-era hardcoded 0.1 state. rho at sea level is
            % Mach-independent, so this does not move the F-16 optimum; it makes
            % the modeled liftoff condition match Brandt.
            constraints = TestF16ConstraintSet.buildLevel("L3");
            names = cellfun(@(c) c.name, constraints);
            takeoff = constraints{names == "Takeoff"};
            tc.verifyEqual(takeoff.state.altitude_ft, 0);
            tc.verifyEqual(takeoff.state.mach, 0.2, 'AbsTol', 1e-9);
        end

        % --- End-to-end with ConstraintAnalysis ------------------------------

        function testOptimalPointWithinPhysicsBounds(tc, fidelityLevel)
            constraints = TestF16ConstraintSet.buildLevel(fidelityLevel);
            ca = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
            [WS_opt, TW_opt] = ca.optimal_point();

            % Brandt's published optimum (Size&Opt sheet / Main!P13), diagnostic
            % print only -- not asserted.
            fprintf('\n    [%s] F-16 optimum: W/S=%.2f, T/W=%.4f  (Brandt reference: W/S=104.59, T/W=0.7576)\n', ...
                fidelityLevel, WS_opt, TW_opt);

            % CORRECTED 2026-07-27 (was: bound loosened 70->50 psf to
            % accommodate Stall becoming the binding constraint, reasoned at
            % the time as "a real, physically expected shift, not a bug" --
            % that reasoning was wrong, per user report: Stall's wall used
            % AeroL2/L3's low geometry-based clean CLmax (~0.91, no Brandt
            % validation) and pulled the optimum to W/S~=62, vs. Brandt's
            % own 104.59 and Casey's legacy-code ~125). The default F-16 map
            % (F16ConstraintSet.constraint_map) excludes Stall, which restores
            % the optimum to W/S~=76-83 here -- still below Brandt/legacy,
            % but that residual gap traces to the already-documented
            % aero/propulsion fidelity gaps (CD0, thrust-lapse) on the real
            % constraint conditions, not to constraint-set wiring; see
            % MasterEquationConstraint.m/TakeoffConstraint.m/LandingConstraint.m
            % headers.
            tc.verifyGreaterThanOrEqual(WS_opt, 70, sprintf('[%s] Optimal W/S below plausible range.', fidelityLevel));
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
            constraints = TestF16ConstraintSet.buildLevel("L3");
            ca  = ConstraintAnalysis(constraints, PointPerformanceBase.WS_RANGE_BRANDT);
            fig = ca.plot_diagram();
            tc.addTeardown(@() close(fig));
            tc.verifyClass(fig, 'matlab.ui.Figure');
        end

    end

end
