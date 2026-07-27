classdef TestLandingConstraint < matlab.unittest.TestCase
%TESTLANDINGCONSTRAINT  Unit tests for the generic LandingConstraint
%   class (landing ground-roll-with-braking upper bound on wing loading)
%   and its F-16 "Landing" instantiation.
%
%   Equation [landing ground-roll-with-braking sizing relation -- matches
%   Roskam Part I's Military landing-distance method and Brandt's F-16A.xls
%   Consts-sheet landing row; NOT Raymer's statistical FAR field-length
%   correlation, per LandingConstraint.m's header], as
%   LandingConstraint.m implements it:
%
%     W_TO/S <= rho * g * S_FR * (mu * CLmax_land + 0.83 * CD0_land) / (k_L^2 * beta)
%
%   testWSMaxMatchesHandComputedEquation checks WS_max against an
%   independently written form of the same equation (not a copy of
%   LandingConstraint's own algebra) using the same aero discipline
%   output (get_CLmax/drag_polar -- already unit-tested elsewhere).
%
%   testEquationReproducesBrandtLandingPoint plugs Brandt's own landing
%   inputs (mu=0.50, CLmax_land=1.4288, CD0=0.062, K1/K2 from
%   b.constraints.landing) into a FixedAeroStub (test-only AerodynamicsBase
%   returning fixed values) and drives the ACTUAL LandingConstraint.WS_max()
%   production code path with it -- not a hand-rederived copy of the formula
%   -- checking it lands within 0.1% of F16Baseline's
%   b.constraints.landing.WS_land=138.742. This validates the equation as
%   coded, independent of which aero discipline object supplies CLmax/CD0.
%
%   The F-16 Landing field condition [subplans/06_constraint_analysis.md
%   "Field constraints" table]: sea level, k_L=1.3, S_FR=4,000 ft, mu=0.50,
%   beta=1.0. testF16LandingWSMaxByFidelityLevel (parameterized over L1/L2/L3)
%   computes each fidelity level's OWN flapped-landing CLmax/CD0
%   (get_CLmax_L() + clean-CD0-plus-get_Delta_CD0_L(), the same assembly
%   examples/F16A/fidelity_comparison.m uses -- ad-hoc methods present on
%   every F16AeroLN class but not part of the generic AerodynamicsBase
%   interface, same documented gap as TakeoffConstraint.m's header and the
%   subplan's "TODO (high-lift configuration)" note), feeds them through a
%   FixedAeroStub into the real WS_max(), and prints -- organized by
%   fidelity level -- the CD0/K1/K2/CLmax used, the computed W/S, Brandt's
%   reference W/S (138.742), and the relative % error. Only plausibility is
%   asserted, not closeness: L1/L2/L3's flap/slat buildups are still
%   textbook estimates, not Brandt's flight-calibrated flapped values.

    properties (TestParameter)
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaPointPerformanceBase(tc)
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), 4000, 0.5);
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaOnlyWbyS(tc)
            % Landing belongs to the Only_WbyS category, same as
            % StallConstraint -- see LandingConstraint.m/Only_WbyS.m headers.
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), 4000, 0.5);
            tc.verifyTrue(isa(obj, 'Only_WbyS'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), 4000, 0.5);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Landing", state, F16AeroL1(f16a_spec_path(1)), 4000, 0.5);
            tc.verifyEqual(obj.name, "Landing");
        end

        function testDefaultBetaAndKL(tc)
            % beta and k_L default to 1.0 and 1.3 (field constraint, per
            % subplans/06_constraint_analysis.md) when omitted.
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), 4000, 0.5);
            tc.verifyEqual(obj.beta, 1.0);
            tc.verifyEqual(obj.k_L, 1.3);
        end

        % --- Equation assembly (generic, hand-computed) ---------------------

        function testWSMaxMatchesHandComputedEquation(tc)
            % Arbitrary field length / friction / margin (not F-16-specific
            % data, just uses an F-16 discipline object as a concrete
            % AerodynamicsBase). Independently derived form of the same
            % equation, not a copy of LandingConstraint's own algebra.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            S_FR  = 3500;
            mu    = 0.45;
            beta  = 0.98;
            k_L   = 1.25;

            CLmax_land = aero.get_CLmax(state);
            CD0_land   = aero.drag_polar(state).CD0;
            rho        = state.rho;
            g          = 32.174;

            expected = (rho * g * S_FR * (mu * CLmax_land + 0.83 * CD0_land)) / (k_L^2 * beta);

            obj      = LandingConstraint("Toy", state, aero, S_FR, mu, beta, k_L);
            received = obj.WS_max();

            fprintf('\n    WS_max: received=%.4f  hand-computed=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'WS_max must equal the hand-computed landing equation.');
        end

        function testEquationReproducesBrandtLandingPoint(tc)
            % Plugs Brandt's own landing inputs directly into the same
            % equation LandingConstraint.m implements (mu*CLmax_land +
            % 0.83*CD0_land form) and checks it lands within 0.1% of
            % F16Baseline's b.constraints.landing.WS_land=138.742 [Brandt
            % F-16A.xls Consts sheet, row 33]. This validates the equation
            % itself against Brandt's worksheet -- separate from
            % testWSMaxMatchesHandComputedEquation's generic algebra check
            % and from testF16LandingWSMaxByFidelityLevel's aero-driven
            % (flapped CLmax/CD0 per fidelity level, not expected to match
            % exactly) comparison.
            b = F16Baseline();

            mu    = 0.50;
            CLmax = b.brandt.CLmax_land;        % 1.4288 [Brandt L10]
            CD0   = b.constraints.landing.CD0;  % 0.062 [Brandt Consts row 33]
            K1    = b.constraints.landing.K1;   % 0.11603 [Brandt Consts row 33]
            K2    = b.constraints.landing.K2;   % -0.0066 [Brandt Consts row 33]
            S_FR  = 4000;
            k_L   = 1.3;
            beta  = 1.0;

            % Drive the actual production code path (LandingConstraint.WS_max,
            % which internally calls aero.get_CLmax(state)/aero.drag_polar(state))
            % via a fixed-value aero stub carrying Brandt's own numbers, rather
            % than re-deriving the equation by hand in the test -- this way the
            % test would catch a bug in LandingConstraint.m's own algebra.
            stub = FixedAeroStub(CLmax, CD0, K1, K2);
            state = AircraftState(0, 0.1);
            obj = LandingConstraint("Landing", state, stub, S_FR, mu, beta, k_L);

            received = obj.WS_max();
            expected = b.constraints.landing.WS_land;

            fprintf('\n    Landing WS_max (Brandt inputs): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-3, ...
                'The landing equation, fed Brandt''s own inputs, should reproduce Brandt''s WS_land to within 0.1%.');
        end

        function testWSMaxIncreasesWithGroundRoll(tc)
            % A longer allowable ground roll tolerates a higher wing loading
            % (more room to bleed off the same touchdown speed).
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);

            obj_short = LandingConstraint("Short field", state, aero, 2000, 0.5);
            obj_long  = LandingConstraint("Long field", state, aero, 6000, 0.5);

            tc.verifyGreaterThan(obj_long.WS_max(), obj_short.WS_max(), ...
                'A longer ground-roll allowance must permit a higher WS_max.');
        end

        function testWSMaxIncreasesWithFriction(tc)
            % Better braking (higher mu) decelerates faster, tolerating a
            % higher wing loading for the same ground-roll distance.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);

            obj_low  = LandingConstraint("Low mu", state, aero, 4000, 0.3);
            obj_high = LandingConstraint("High mu", state, aero, 4000, 0.6);

            tc.verifyGreaterThan(obj_high.WS_max(), obj_low.WS_max(), ...
                'Higher braking friction must permit a higher WS_max.');
        end

        function testWSMaxDecreasesWithSpeedMargin(tc)
            % A larger touchdown-speed margin k_L means a higher touchdown
            % speed for the same stall speed, demanding a lower wing loading
            % to still stop within the same ground roll.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);

            obj_tight = LandingConstraint("Tight margin", state, aero, 4000, 0.5, 1.0, 1.15);
            obj_loose = LandingConstraint("Loose margin", state, aero, 4000, 0.5, 1.0, 1.45);

            tc.verifyGreaterThan(obj_tight.WS_max(), obj_loose.WS_max(), ...
                'A larger touchdown-speed margin k_L must lower WS_max.');
        end

        % --- Available/margin ------------------------------------------------

        function testWSMarginMatchesHandComputedFormula(tc)
            % Arbitrary field length/friction/design point (not F-16-specific
            % data). WS_max() itself is already independently verified above,
            % so this only needs to confirm WS_margin combines it with the
            % actual W_TO/S_ref correctly: margin = WS_required - WS_available,
            % WS_required = WS_max(), WS_available = W_TO/S_ref. Requests
            % WS_margin's 2nd/3rd (available/required) outputs directly so
            % both underlying constraint values are independently verified,
            % not just their combined margin.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, aero, 3500, 0.45, 0.98, 1.25);

            W_TO  = 32000;
            S_ref = 320;

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

        function testWSMarginDecreasesWithHigherActualWS(tc)
            % A heavier design (or smaller wing) for the same W_TO -- higher
            % actual W_TO/S_ref -- must shrink the margin: less "wiggle room"
            % before hitting the landing wall. Prints/verifies the required
            % and available values behind each margin: required must be
            % identical between the two calls (same condition), only
            % available should move.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, aero, 4000, 0.5);

            W_TO = 30000;
            [margin_light_loading, available_light, required_light] = obj.WS_margin(W_TO, 350);   % lower actual W/S
            [margin_heavy_loading, available_heavy, required_heavy] = obj.WS_margin(W_TO, 250);   % higher actual W/S

            fprintf('\n    Light loading (S_ref=350): required=%.4f  available=%.4f  margin=%.4f\n', ...
                required_light, available_light, margin_light_loading);
            fprintf('    Heavy loading (S_ref=250): required=%.4f  available=%.4f  margin=%.4f\n', ...
                required_heavy, available_heavy, margin_heavy_loading);

            tc.verifyEqual(required_light, required_heavy, 'AbsTol', 1e-12, ...
                'required must be unchanged between the two calls -- only S_ref differs.');
            tc.verifyGreaterThan(available_heavy, available_light, ...
                'A smaller S_ref (same W_TO) must increase the available output.');
            tc.verifyGreaterThan(margin_light_loading, margin_heavy_loading, ...
                'A higher actual wing loading must shrink WS_margin.');
        end

        function testWSMarginSignAtLimit(tc)
            % When the actual W_TO/S_ref exactly equals WS_max(), margin must
            % be ~0 -- the definitional boundary between feasible (>=0) and
            % infeasible (<0). Prints/verifies required and available
            % explicitly equal one another here.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, aero, 4000, 0.5);

            W_TO  = 30000;
            S_ref = W_TO / obj.WS_max();   % actual W/S == the landing limit, exactly

            [margin, available, required] = obj.WS_margin(W_TO, S_ref);
            fprintf('\n    At boundary: required=%.4f  available=%.4f  margin=%.4f\n', ...
                required, available, margin);
            tc.verifyEqual(available, required, 'RelTol', 1e-8, ...
                'available must equal required exactly at this constructed boundary.');
            tc.verifyEqual(margin, 0, 'AbsTol', 1e-8, ...
                'WS_margin must be ~0 when actual W_TO/S_ref exactly equals WS_max().');
        end

        function testF16LandingWSMarginAtBrandtDesignPoint(tc)
            % Diagnostic only: evaluates WS_margin at Brandt's own actual
            % design point (W_TO=b.brandt.TOGW, S_ref=b.geom.S_ref ->
            % WS_actual=b.constraint.WS_opt=104.59) using this framework's
            % own (clean-CLmax) WS_max() -- already documented (class header,
            % "NOTE ON CLmax/CD0 BASIS") to read below Brandt's flapped
            % WS_land=138.742, so a negative margin here is expected, not a
            % bug -- printed for visibility, not asserted for closeness.
            b     = F16Baseline();
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Landing", state, aero, 4000, 0.5);

            [margin, available, required] = obj.WS_margin(b.brandt.TOGW, b.geom.S_ref);
            fprintf('\n    Landing at Brandt''s design point (WS_opt=%.2f): required=%.2f  available=%.2f  margin=%.4f\n', ...
                b.constraint.WS_opt, required, available, margin);
            tc.verifyTrue(isfinite(required), 'WS_margin''s required output must be finite at Brandt''s design point.');
            tc.verifyTrue(isfinite(available), 'WS_margin''s available output must be finite at Brandt''s design point.');
            tc.verifyTrue(isfinite(margin), 'WS_margin must be finite at Brandt''s design point.');
        end

        % --- Vertical-wall required_TW encoding -----------------------------

        function testRequiredTWZeroAtOrBelowLimit(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, aero, 4000, 0.5);
            WS_limit = obj.WS_max();

            tc.verifyEqual(obj.required_TW(WS_limit), 0);
            tc.verifyEqual(obj.required_TW(WS_limit * 0.5), 0);
        end

        function testRequiredTWInfAboveLimit(tc)
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, aero, 4000, 0.5);
            WS_limit = obj.WS_max();

            tc.verifyEqual(obj.required_TW(WS_limit * 1.01), Inf);
            tc.verifyEqual(obj.required_TW(WS_limit * 5), Inf);
        end

        function testRequiredTWVectorizedOverWS(tc)
            % Constraint diagrams sweep W/S -- required_TW must vectorize
            % cleanly, staying finite below the limit and Inf above it.
            aero  = F16AeroL1(f16a_spec_path(1));
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Toy", state, aero, 4000, 0.5);
            WS_limit = obj.WS_max();

            WS_range = linspace(WS_limit * 0.2, WS_limit * 1.8, 21);
            TW = obj.required_TW(WS_range);

            tc.verifyEqual(numel(TW), numel(WS_range));
            tc.verifyTrue(all(TW(WS_range <= WS_limit) == 0), ...
                'required_TW must be 0 at or below the landing WS limit.');
            tc.verifyTrue(all(isinf(TW(WS_range > WS_limit))), ...
                'required_TW must be Inf above the landing WS limit.');
        end

        % --- F-16 Landing field condition -----------------------------------
        % Sea level, k_L=1.3, S_FR=4,000 ft, mu=0.50, beta=1.0
        % [subplans/06_constraint_analysis.md "Field constraints" table]

        function testF16LandingWSMaxByFidelityLevel(tc, fidelityLevel)
            % Computes the F-16 landing wing-loading limit at each fidelity
            % level using that level's OWN flapped-landing CLmax/CD0
            % (get_CLmax_L() + clean-CD0-plus-get_Delta_CD0_L(), the same
            % assembly examples/F16A/fidelity_comparison.m uses -- ad-hoc
            % methods present on all three F16AeroLN classes but not part of
            % the generic AerodynamicsBase interface, see
            % LandingConstraint.m's header "NOTE ON CLmax/CD0 BASIS"),
            % fed through the actual LandingConstraint.WS_max() production
            % code path via FixedAeroStub (not re-derived by hand). K1/K2 use
            % the clean drag polar -- this framework has no separate flapped
            % K1/K2 variant, matching Brandt's own Consts sheet, which reuses
            % the same K1=0.11603/K2=-0.0066 for both the takeoff (row 32)
            % and landing (row 33) rows [F16Baseline b.constraints.landing].
            % Which F16Baseline() table this prints against ("original" or
            % "corrected" -- see F16Baseline.m section 11b; Landing's WS_land
            % is essentially unchanged between the two) is controlled by the
            % single manual switch in BrandtVariant.m.
            %
            % Prints, organized by fidelity level: the CD0/K1/K2/CLmax used,
            % the computed W/S, Brandt's reference W/S (138.742), and the
            % relative % error. Only asserts plausibility (positive, finite,
            % in a sane W/S range) rather than closeness to Brandt -- L1/L2's
            % flap-only (no slat) buildup and L3's full flap+slat buildup are
            % still textbook estimates, not Brandt's flight-calibrated
            % flapped CLmax/CD0, so some gap remains even after matching
            % flap-vs-clean bases (see testEquationReproducesBrandtLandingPoint,
            % which confirms the EQUATION itself reproduces Brandt exactly
            % when fed Brandt's own flapped numbers).
            variant = BrandtVariant();
            b = F16Baseline(variant);
            [~, CLmax_land, CD0_land, K1, K2] = TestLandingConstraint.landingAeroValues(fidelityLevel);

            stub  = FixedAeroStub(CLmax_land, CD0_land, K1, K2);
            state = AircraftState(0, 0.1);
            obj   = LandingConstraint("Landing", state, stub, 4000, 0.50, 1.0, 1.3);

            WS_computed = obj.WS_max();
            WS_expected = b.constraints.landing.WS_land;
            pct_error   = 100 * (WS_computed - WS_expected) / WS_expected;

            fprintf('\n    ==================== Fidelity Level: %s (%s) ====================\n', fidelityLevel, variant);
            fprintf('    Aerodynamics used (flapped landing config):\n');
            fprintf('      CD0    = %.5f\n', CD0_land);
            fprintf('      K1     = %.5f\n', K1);
            fprintf('      K2     = %.5f\n', K2);
            fprintf('      CL_max = %.4f\n', CLmax_land);
            fprintf('    Computed W/S = %.3f lbf/ft^2\n', WS_computed);
            fprintf('    Expected W/S = %.3f lbf/ft^2  (Brandt, F16Baseline b.constraints.landing.WS_land)\n', WS_expected);
            fprintf('    Relative error = %.2f%%\n', pct_error);

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
                    error('TestLandingConstraint:buildAero:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

        function [aero, CLmax_land, CD0_land, K1, K2] = landingAeroValues(fidelityLevel)
        %LANDINGAEROVALUES  Flapped-landing CLmax/CD0 (get_CLmax_L() and
        %   clean-CD0 + get_Delta_CD0_L(), matching
        %   examples/F16A/fidelity_comparison.m's cd0_L_total/clmax_L_total
        %   assembly) plus the clean drag-polar K1/K2, for the given F-16
        %   fidelity level. L3's get_Delta_CD0_L needs a state argument
        %   (gear-strut Reynolds-number lookup); L1/L2's do not -- see
        %   F16AeroL1.m/F16AeroL2.m/F16AeroL3.m get_Delta_CD0_L signatures.
            state = AircraftState(0, 0.1);
            aero  = TestLandingConstraint.buildAero(fidelityLevel);

            polar = aero.drag_polar(state);
            K1 = polar.K1;
            K2 = polar.K2;
            CLmax_land = aero.get_CLmax_L();

            switch fidelityLevel
                case 'L1'
                    % L1 is geometry-free and has NO get_CD0 (migrated to L2);
                    % read the clean CD0 from the Mattingly drag polar instead
                    % (same fix applied in examples/F16A/fidelity_comparison.m).
                    CD0_clean   = polar.CD0;
                    Delta_CD0_L = aero.get_Delta_CD0_L();
                case 'L2'
                    CD0_clean   = aero.get_CD0();
                    Delta_CD0_L = aero.get_Delta_CD0_L();
                case 'L3'
                    CD0_clean   = polar.CD0;
                    Delta_CD0_L = aero.get_Delta_CD0_L(state);
                otherwise
                    error('TestLandingConstraint:landingAeroValues:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
            CD0_land = CD0_clean + Delta_CD0_L;
        end

    end

end
