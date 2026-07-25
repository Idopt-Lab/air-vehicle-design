classdef TestThrustConstraint < matlab.unittest.TestCase
%TESTTHRUSTCONSTRAINT  Unit tests for the generic ThrustConstraint class
%   (Mattingly Master Equation) and its F-16 "Max Mach" instantiation.
%
%   Master Equation [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA,
%   2002; see also NPTEL_Fighter_Aircraft_Sizing.ipynb], as ThrustConstraint.m
%   implements it (algebraically simplified):
%
%     T_SL/W_TO = A/(W_TO/S) + B*(W_TO/S) + C + D
%       A = q*CD0/alpha
%       B = (q/alpha) * K1 * (n*beta/q)^2
%       C = K2 * n * beta / alpha
%       D = (beta/alpha) * (Ps/V)
%
%   testRequiredTWMatchesHandComputedMasterEquation checks required_TW
%   against the RAW, unsimplified form of the same equation (not the A/B/C/D
%   simplification above -- computing that would just copy ThrustConstraint's
%   own algebra back at it) using the same aero/prop discipline outputs
%   (drag_polar, thrust_lapse -- each already unit-tested elsewhere).
%
%   The F-16 Max Mach condition [sizing/docs/subplans/06_constraint_analysis.md]:
%     36,000 ft, M=1.60, n=1.0, 100% AB, Ps=0, beta=0.8997
%   uses F16AeroL3 + F16PropL2, matching the classes TestAeroL3 and TestPropL2
%   already validate at this exact (alt, Mach) point (F16Baseline b.constraints.dash).
%   Per F16Baseline's own comments, Brandt's alpha/CD0/K1 at this point come
%   from a different thrust-lapse formula and a flight-calibrated drag polar
%   respectively -- so, consistent with TestPropL2.testLapseABAtDash (AbsTol
%   0.10) and TestAeroL3 (positivity-only at supersonic conditions), those are
%   diagnostic/loose checks here, not exact-match assertions.
%
%   NOTE ON temp_Casey (HISTORICAL -- see 2026-07-23 update below): a
%   since-removed diagnostic test fed Brandt's own CD0/K1/K2/alpha for the
%   Max Mach condition through the Master Equation directly (bypassing
%   F16AeroL3/F16PropL2) and found that temp_Casey's src/Utilities/
%   Constraints.m records MxMach K1 = 0.213727, but F16Baseline's
%   b.constraints.dash.K1 -- 0.1251 at the time -- reproduced Brandt's
%   original worksheet numbers (0.213727 overshot Brandt's table by a
%   growing percentage as W/S increases, up to +1.7% by W/S=83, while
%   0.1251 matched to a constant ~0.15% offset, i.e. pure atmosphere-model
%   rounding). Do not port temp_Casey's K1 value for MxMach.
%
%   2026-07-23 UPDATE: F16Baseline's b.constraints.dash.K1 has since been
%   changed, at user direction, from 0.1251 (the Consts-row-23 tabulated
%   cell value the finding above validated against) to 0.276031 -- the
%   supersonic-form K1 [Raymer 6th ed. Eq. 12.51 / Brandt's own Aero-tab
%   k1_super_f, see F16Baseline.m's b.constraints.dash.K1 comment]. The
%   b.constraints.dash.TW_MxMach table was recomputed to match this new K1
%   (see that field's comment in F16Baseline.m), so it and K1 are internally
%   consistent again, but the specific 0.1251-vs-0.213727 comparison above
%   no longer describes what b.constraints.dash.K1 currently holds --
%   retained as historical context for how 0.1251 was originally chosen,
%   not as a statement about the present value.

    properties (Constant)
        ALPHA_ABS_TOL = 0.10   % Brandt-vs-Mattingly alpha formula mismatch, matches TestPropL2.testLapseABAtDash
    end

    properties (TestParameter)
        % Aero/prop discipline pairing per fidelity level. No F16PropL3
        % exists yet, so L3 pairs F16AeroL3 with F16PropL2 (highest
        % propulsion fidelity available) -- same pairing fidelity_comparison.m
        % uses elsewhere (its L3 propulsion columns are NaN for the same reason).
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaPointPerformanceBase(tc)
            state = AircraftState(0, 0.5);
            obj   = ThrustConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaBothWbySTbyW(tc)
            % ThrustConstraint belongs to the Both_WbyS_TbyW category, same
            % as TakeoffConstraint -- see ThrustConstraint.m/
            % Both_WbyS_TbyW.m headers.
            state = AircraftState(0, 0.5);
            obj   = ThrustConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.5);
            obj   = ThrustConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.5);
            obj   = ThrustConstraint("Max Mach", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyEqual(obj.name, "Max Mach");
        end

        function testDefaultLoadFactorAndPs(tc)
            % n and Ps default to 1.0 and 0.0 (sustained, unaccelerated flight)
            % when omitted, per the constructor's arguments block.
            state = AircraftState(0, 0.5);
            obj   = ThrustConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 0.9);
            tc.verifyEqual(obj.n, 1.0);
            tc.verifyEqual(obj.Ps, 0.0);
        end

        % --- Master-equation assembly (generic, hand-computed) -----------

        function testRequiredTWMatchesHandComputedMasterEquation(tc)
            % Arbitrary condition (not F-16 specific data, just uses the F-16
            % discipline objects as a concrete AerodynamicsBase/PropulsionBase
            % pair). Checks required_TW against the RAW, unsimplified
            % Mattingly Master Equation (the NPTEL notebook's original form,
            % before the A/(W/S)+B*(W/S)+C+D algebraic simplification
            % ThrustConstraint.m implements) -- a genuinely independent
            % derivation, not a copy of ThrustConstraint's own algebra, so it
            % actually catches errors in that simplification step:
            %
            %   T_SL/W_TO = (beta/alpha) * { (q/(beta*WS)) *
            %                 [K1*(n*beta*WS/q)^2 + K2*(n*beta*WS/q) + CD0] + Ps/V }
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            beta  = 0.95;
            n     = 2.0;
            Ps    = 50;
            WS    = 90;

            polar = aero.drag_polar(state);
            alpha = prop.thrust_lapse(state);
            q     = state.q;
            V     = state.V;

            z        = n * beta * WS / q;
            bracket  = polar.K1 * z^2 + polar.K2 * z + polar.CD0;
            expected = (beta / alpha) * ((q / (beta * WS)) * bracket + Ps / V);

            obj      = ThrustConstraint("Toy", state, aero, prop, beta, n, Ps);
            received = obj.required_TW(WS);

            fprintf('\n    required_TW(WS=%d): received=%.6f  hand-computed=%.6f\n', WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'required_TW must equal the raw (unsimplified) Master Equation.');
        end

        % --- Available/margin ------------------------------------------------

        function testTWMarginMatchesHandComputedFormula(tc)
            % Arbitrary condition/design point (not F-16-specific data).
            % required_TW itself is already independently verified above, so
            % this only needs to confirm TW_margin combines it with the
            % available (lapsed) T_SL/W_TO correctly: margin =
            % alpha*(T_SL/W_TO - required_TW(WS_actual)), where alpha is the
            % same AB-basis lapse this ThrustConstraint's own required_TW
            % uses internally (default powerSetting="AB"). Requests
            % TW_margin's 2nd/3rd (available/required) outputs directly,
            % rather than just its combined margin, so both underlying
            % constraint values are independently verified too.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            obj   = ThrustConstraint("Toy", state, aero, prop, 0.95, 2.0, 50);

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

        function testTWMarginIncreasesWithAvailableThrust(tc)
            % More installed sea-level-static thrust (same W_TO, same
            % WS_actual) must increase the margin -- strictly more T/W
            % available with everything else held fixed. Prints/verifies
            % the required and available values behind each margin: required
            % must be identical between the two calls (same condition, same
            % WS_actual), only available should move.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            obj   = ThrustConstraint("Toy", state, aero, prop, 0.95, 2.0, 50);

            [margin_low, available_low, required_low]   = obj.TW_margin(90, 20000, 32000);
            [margin_high, available_high, required_high] = obj.TW_margin(90, 30000, 32000);

            fprintf('\n    Low T_SL=20000:  required=%.6f  available=%.6f  margin=%.6f\n', ...
                required_low, available_low, margin_low);
            fprintf('    High T_SL=30000: required=%.6f  available=%.6f  margin=%.6f\n', ...
                required_high, available_high, margin_high);

            tc.verifyEqual(required_low, required_high, 'AbsTol', 1e-12, ...
                'required must be unchanged between the two calls -- only available T_SL differs.');
            tc.verifyGreaterThan(available_high, available_low, ...
                'More installed T_SL must increase the available output.');
            tc.verifyGreaterThan(margin_high, margin_low, ...
                'More available T_SL must increase TW_margin.');
        end

        function testTWMarginSignAtRequiredBoundary(tc)
            % When available T/W is set to exactly the required_TW at
            % WS_actual, margin must be ~0 -- the definitional boundary
            % between feasible (>=0) and infeasible (<0). Prints/verifies
            % required and available explicitly equal one another here.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            obj   = ThrustConstraint("Toy", state, aero, prop, 0.95, 2.0, 50);

            WS_actual   = 90;
            W_TO        = 32000;
            TW_required = obj.required_TW(WS_actual);
            T_SL        = TW_required * W_TO;   % available == required, exactly

            [margin, available, required] = obj.TW_margin(WS_actual, T_SL, W_TO);
            fprintf('\n    At boundary: required=%.6f  available=%.6f  margin=%.6f\n', ...
                required, available, margin);
            tc.verifyEqual(available, required, 'RelTol', 1e-10, ...
                'available must equal required exactly at this constructed boundary.');
            tc.verifyEqual(margin, 0, 'AbsTol', 1e-10, ...
                'TW_margin must be ~0 when available T/W exactly equals required_TW.');
        end

        function testRequiredTWVectorizedOverWS(tc)
            % Constraint diagrams sweep W/S -- required_TW must vectorize
            % cleanly and stay finite over a physically reasonable range.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            obj   = ThrustConstraint("Toy", state, aero, prop, 0.95, 1.0, 0.0);

            WS_range = 20:10:180;
            TW       = obj.required_TW(WS_range);

            tc.verifyEqual(numel(TW), numel(WS_range));
            tc.verifyTrue(all(isfinite(TW)), 'required_TW must be finite over the W/S sweep.');
        end

        function testRequiredTWConvexShape(tc)
            % A/(W/S) dominates at low W/S, B*(W/S) dominates at high W/S ->
            % required_TW = A/x + B*x (+ const) is convex in x=W/S with an
            % analytic minimum at x* = sqrt(A/B). Bracket that minimum
            % (rather than guessing fixed W/S points, which may not bracket
            % it for an arbitrary condition) to confirm the "bucket" shape.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            beta  = 0.95;
            n     = 1.0;

            polar = aero.drag_polar(state);
            alpha = prop.thrust_lapse(state);
            q     = state.q;
            A     = q * polar.CD0 / alpha;
            B     = (q / alpha) * polar.K1 * (n * beta / q)^2;
            WS_star = sqrt(A / B);

            obj    = ThrustConstraint("Toy", state, aero, prop, beta, n, 0.0);
            TW_lo  = obj.required_TW(WS_star / 2);
            TW_mid = obj.required_TW(WS_star);
            TW_hi  = obj.required_TW(WS_star * 2);
            fprintf('\n    required_TW around WS*=%.2f: WS*/2 -> %.4f, WS* -> %.4f, 2*WS* -> %.4f\n', ...
                WS_star, TW_lo, TW_mid, TW_hi);
            tc.verifyGreaterThan(TW_lo, TW_mid);
            tc.verifyGreaterThan(TW_hi, TW_mid);
        end

        % --- F-16 Max Mach condition --------------------------------------
        % 36,000 ft, M=1.60, n=1.0, 100% AB, Ps=0, beta=0.8997
        % [subplans/06_constraint_analysis.md; F16Baseline b.constraints.dash]

        function testF16MaxMachAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Max Mach condition should be in the neighborhood of
            % Brandt's alpha_AB -- same AbsTol as TestPropL2.testLapseABAtDash,
            % since Brandt's formula and normalization differ from Mattingly
            % Eq. 2.54 (F16Baseline Sec. 11 comment).
            b     = F16Baseline();
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.dash.alt_ft, b.constraints.dash.mach);
            received = prop.thrust_lapse(state);
            expected = b.constraints.dash.alpha_AB;   % 0.5770 [Brandt Consts AT23]
            fprintf('\n    alpha (Max Mach, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Max Mach alpha should be within 0.10 of Brandt AT23.');
        end

        function testF16MaxMachDragPolarK2ZeroSupersonic(tc)
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            state = AircraftState(b.constraints.dash.alt_ft, b.constraints.dash.mach);
            polar = aero.drag_polar(state);
            fprintf('\n    Max Mach polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, b.constraints.dash.CD0, b.constraints.dash.K1, b.constraints.dash.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, 'K2 must be 0 supersonic.');
        end

        function testF16MaxMachRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Max Mach condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [F16Baseline b.constraints.dash.TW_MxMach].
            % L1/L2 still read LOW vs. Brandt (~40-51%/~47-57% across the
            % sweep) -- CD0 is a flat Cfe*Swet/Sref estimate with no Mach
            % dependence at all, so neither ever picks up the supersonic
            % wave-drag rise. L3 now reads CLOSE to Brandt (within about
            % +2.5% to +3.0% across the sweep) since F16AeroL3.compute_CD0_wave
            % was fixed to use the true whole-aircraft Amax/length (Raymer
            % 6th ed. Eqs. 12.44-12.45, see F16AeroL3_wave_drag_fix.md) instead
            % of a fuselage-only approximation -- "higher fidelity is more
            % accurate" now holds here, reversing the earlier state where L3
            % (fuselage-only wave drag) undershot even L1's flat estimate.
            % Remaining ~+3% at L3 is a known, smaller residual gap (Brandt's
            % own flight-calibrated polar vs. this framework's textbook
            % buildup), not a ThrustConstraint bug -- see the class header
            % note on how the Master Equation itself was separately confirmed
            % against Brandt's table to ~0.15%. Which F16Baseline() table this prints
            % against ("original" Brandt F-16A.xls, or Casey's "corrected"
            % revised-OEW recalculation) is controlled by the single manual
            % switch in BrandtVariant.m -- edit that file, not this one, to
            % flip it.
            [aero, prop] = TestThrustConstraint.buildDisciplines(fidelityLevel);

            variant = BrandtVariant();
            b     = F16Baseline(variant);
            state = AircraftState(b.constraints.dash.alt_ft, b.constraints.dash.mach);
            obj   = ThrustConstraint("Max Mach", state, aero, prop, 0.8997, 1.0, 0.0);

            WS_range      = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_MxMach = b.constraints.dash.TW_MxMach;
            TW            = obj.required_TW(WS_range);

            % "required"/"available" columns (this class's TW_margin, 2nd/3rd
            % outputs) at Brandt's own actual design point (T_SL=b.engine.T_max,
            % W_TO=b.brandt.TOGW), evaluated at each W/S in the sweep -- alpha
            % is fixed for this condition, so "available" is constant across
            % rows while "required" (=alpha*required_TW(WS)) tracks TW*alpha.
            T_SL = b.engine.T_max;
            W_TO = b.brandt.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s, %s]\n', fidelityLevel, variant);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                [~, available_vals(i), required_vals(i)] = obj.TW_margin(WS_range(i), T_SL, W_TO);
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_MxMach(i), ...
                    100*(TW(i) - brandt_MxMach(i))/brandt_MxMach(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive (100%% AB, supersonic dash).', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] TW_margin''s required output must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] TW_margin''s available output must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16MaxMachRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match
            % to Brandt's TW_opt (~0.7576): our textbook CD0/K1 buildup is
            % expected to differ from Brandt's flight-calibrated polar (see
            % subplans/06_constraint_analysis.md, "Tests" section note).
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.dash.alt_ft, b.constraints.dash.mach);
            obj   = ThrustConstraint("Max Mach", state, aero, prop, 0.8997, 1.0, 0.0);

            TW = obj.required_TW(b.constraint.WS_opt);
            fprintf('\n    Max Mach required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                b.constraint.WS_opt, TW, b.constraint.TW_opt);
            tc.verifyGreaterThan(TW, 0.1, 'required_TW implausibly low for a supersonic-dash constraint.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Max Alt (ceiling) condition -------------------------------
        % 50,000 ft, M=0.87, n=1.0, 100% AB, Ps=0, beta=0.8997
        % [subplans/06_constraint_analysis.md; F16Baseline b.constraints.max_alt]
        %
        % Like Max Mach (not Cruise), this condition is flown at 100% AB, so
        % prop.thrust_lapse's AB-basis convention applies directly -- no
        % alpha-basis mismatch to account for here. Unlike Max Mach, though,
        % M=0.87 is subsonic, so the drag polar has the usual nonzero K2 (no
        % supersonic K2=0 assumption applies at this condition).

        function testF16MaxAltAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Max Alt condition should be in the neighborhood of Brandt's
            % alpha_AB -- same AbsTol as the Max Mach/Cruise alpha checks.
            b     = F16Baseline();
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.max_alt.alt_ft, b.constraints.max_alt.mach);
            received = prop.thrust_lapse(state);
            expected = b.constraints.max_alt.alpha_AB;   % 0.17029 [Brandt Consts AT25]
            fprintf('\n    alpha (Max Alt, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Max Alt alpha should be within 0.10 of Brandt AT25.');
        end

        function testF16MaxAltDragPolarSubsonic(tc)
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            state = AircraftState(b.constraints.max_alt.alt_ft, b.constraints.max_alt.mach);
            polar = aero.drag_polar(state);
            fprintf('\n    Max Alt polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, b.constraints.max_alt.CD0, b.constraints.max_alt.K1, b.constraints.max_alt.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16MaxAltRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Max Alt condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [F16Baseline b.constraints.max_alt.TW_MaxAlt].
            % Diagnostic only, same caveats as testF16CruiseRequiredTWTable
            % (textbook CD0/K1 buildup vs. Brandt's flight-calibrated polar).
            % Which F16Baseline() table this prints against ("original" or
            % "corrected" -- see F16Baseline.m section 11b; Max Alt is one of
            % the rows that shifts materially between the two) is controlled
            % by the single manual switch in BrandtVariant.m.
            [aero, prop] = TestThrustConstraint.buildDisciplines(fidelityLevel);

            variant = BrandtVariant();
            b     = F16Baseline(variant);
            state = AircraftState(b.constraints.max_alt.alt_ft, b.constraints.max_alt.mach);
            obj   = ThrustConstraint("Max Alt", state, aero, prop, 0.8997, 1.0, 0.0);

            WS_range      = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_maxalt = b.constraints.max_alt.TW_MaxAlt;
            TW            = obj.required_TW(WS_range);

            % "required"/"available" columns (this class's TW_margin, 2nd/3rd
            % outputs) at Brandt's own actual design point (T_SL=b.engine.T_max,
            % W_TO=b.brandt.TOGW), evaluated at each W/S in the sweep -- alpha
            % is fixed for this condition, so "available" is constant across
            % rows while "required" (=alpha*required_TW(WS)) tracks TW*alpha.
            T_SL = b.engine.T_max;
            W_TO = b.brandt.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s, %s]\n', fidelityLevel, variant);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                [~, available_vals(i), required_vals(i)] = obj.TW_margin(WS_range(i), T_SL, W_TO);
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_maxalt(i), ...
                    100*(TW(i) - brandt_maxalt(i))/brandt_maxalt(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] TW_margin''s required output must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] TW_margin''s available output must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16MaxAltRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Cruise).
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.max_alt.alt_ft, b.constraints.max_alt.mach);
            obj   = ThrustConstraint("Max Alt", state, aero, prop, 0.8997, 1.0, 0.0);

            TW = obj.required_TW(b.constraint.WS_opt);
            fprintf('\n    Max Alt required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                b.constraint.WS_opt, TW, b.constraint.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Combat Turn 1 (subsonic) condition -------------------------
        % 20,000 ft, M=0.87, n=4.5, 100% AB, Ps=0, beta=0.8997
        % [subplans/06_constraint_analysis.md; F16Baseline b.constraints.combat_sub]
        %
        % Like Max Mach and Max Alt (not Cruise), this condition is flown at
        % 100% AB, so prop.thrust_lapse's AB-basis convention applies
        % directly -- no alpha-basis mismatch to account for here. Like Max
        % Alt, M=0.87 is subsonic, so the drag polar has the usual nonzero K2.
        % The distinguishing feature of this condition is n=4.5 (sustained
        % turn at high load factor), not altitude/Mach/AB.

        function testF16CombatSubAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Combat Turn 1 condition should be in the neighborhood of
            % Brandt's alpha_AB -- same AbsTol as the Max Mach/Max Alt/Cruise
            % alpha checks.
            b     = F16Baseline();
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            received = prop.thrust_lapse(state);
            expected = b.constraints.combat_sub.alpha_AB;   % 0.681777 [Brandt Consts AT26]
            fprintf('\n    alpha (Combat Turn 1, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Combat Turn 1 alpha should be within 0.10 of Brandt AT26.');
        end

        function testF16CombatSubDragPolarSubsonic(tc)
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            state = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            polar = aero.drag_polar(state);
            fprintf('\n    Combat Turn 1 polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, b.constraints.combat_sub.CD0, b.constraints.combat_sub.K1, b.constraints.combat_sub.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16CombatSubRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Combat Turn 1
            % condition at each fidelity level, alongside Brandt's full
            % 21-point tabulated row [F16Baseline b.constraints.combat_sub.
            % TW_CombatSub]. Diagnostic only, same caveats as
            % testF16MaxAltRequiredTWTable (textbook CD0/K1 buildup vs.
            % Brandt's flight-calibrated polar) -- n=4.5 also means the K1
            % (induced-drag) term dominates far more here than at the n=1.0
            % conditions, so any K1 buildup gap will show up amplified.
            % Which F16Baseline() table this prints against ("original" or
            % "corrected" -- see F16Baseline.m section 11b; Combat Turn 1 is
            % one of the rows that shifts materially between the two) is
            % controlled by the single manual switch in BrandtVariant.m.
            [aero, prop] = TestThrustConstraint.buildDisciplines(fidelityLevel);

            variant = BrandtVariant();
            b     = F16Baseline(variant);
            state = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            obj   = ThrustConstraint("Combat Turn 1", state, aero, prop, 0.8997, b.constraints.combat_sub.n, 0.0);

            WS_range         = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_combatsub = b.constraints.combat_sub.TW_CombatSub;
            TW               = obj.required_TW(WS_range);

            % "required"/"available" columns (this class's TW_margin, 2nd/3rd
            % outputs) at Brandt's own actual design point (T_SL=b.engine.T_max,
            % W_TO=b.brandt.TOGW), evaluated at each W/S in the sweep -- alpha
            % is fixed for this condition, so "available" is constant across
            % rows while "required" (=alpha*required_TW(WS)) tracks TW*alpha.
            T_SL = b.engine.T_max;
            W_TO = b.brandt.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s, %s]\n', fidelityLevel, variant);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                [~, available_vals(i), required_vals(i)] = obj.TW_margin(WS_range(i), T_SL, W_TO);
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_combatsub(i), ...
                    100*(TW(i) - brandt_combatsub(i))/brandt_combatsub(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] TW_margin''s required output must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] TW_margin''s available output must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16CombatSubRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Max Alt/Cruise).
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.combat_sub.alt_ft, b.constraints.combat_sub.mach);
            obj   = ThrustConstraint("Combat Turn 1", state, aero, prop, 0.8997, b.constraints.combat_sub.n, 0.0);

            TW = obj.required_TW(b.constraint.WS_opt);
            fprintf('\n    Combat Turn 1 required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                b.constraint.WS_opt, TW, b.constraint.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Combat Turn 2 (supersonic) condition -----------------------
        % 36,000 ft, M=1.4, n=1.4, 100% AB, Ps=0, beta=0.8997
        % [subplans/06_constraint_analysis.md; F16Baseline b.constraints.combat_sup]
        %
        % Like Combat Turn 1, this condition is flown at 100% AB, so
        % prop.thrust_lapse's AB-basis convention applies directly. Like Max
        % Mach (not Max Alt/Combat Turn 1), M=1.4 is supersonic.

        function testF16CombatSupAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Combat Turn 2 condition should be in the neighborhood of
            % Brandt's alpha_AB -- same AbsTol as the other AB conditions.
            b     = F16Baseline();
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.combat_sup.alt_ft, b.constraints.combat_sup.mach);
            received = prop.thrust_lapse(state);
            expected = b.constraints.combat_sup.alpha_AB;   % 0.556558 [Brandt Consts AT27]
            fprintf('\n    alpha (Combat Turn 2, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Combat Turn 2 alpha should be within 0.10 of Brandt AT27.');
        end

        function testF16CombatSupDragPolarK2ZeroSupersonic(tc)
            % Same K2=0 supersonic assumption as Max Mach (M=1.4 > 1 here
            % too). Brandt's own K2 for this row is -0.00105, not exactly
            % zero [F16Baseline combat_sup.K2 comment] -- printed for
            % reference, not asserted against, per this framework's own
            % linearized-theory K2=0 supersonic assumption (AeroL1.K2_value).
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            state = AircraftState(b.constraints.combat_sup.alt_ft, b.constraints.combat_sup.mach);
            polar = aero.drag_polar(state);
            fprintf('\n    Combat Turn 2 polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, b.constraints.combat_sup.CD0, b.constraints.combat_sup.K1, b.constraints.combat_sup.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, 'K2 must be 0 supersonic.');
        end

        function testF16CombatSupRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Combat Turn 2
            % condition at each fidelity level, alongside Brandt's full
            % 21-point tabulated row [F16Baseline b.constraints.combat_sup.
            % TW_CombatSup]. Diagnostic only, same caveats as
            % testF16MaxMachRequiredTWTable: L1/L2 still read far LOW vs.
            % Brandt (~30-54%/~44-63%, no Mach-dependent CD0 at all), while
            % L3 now reads much closer (~8.4-8.9% low across the sweep) since
            % compute_CD0_wave was fixed to use the true whole-aircraft
            % Amax/length instead of a fuselage-only approximation (see
            % F16AeroL3_wave_drag_fix.md) -- textbook CD0/K1 buildup vs.
            % Brandt's flight-calibrated polar accounts for the remainder.
            % Which F16Baseline() table this prints against ("original" or
            % "corrected" -- see F16Baseline.m section 11b; Combat Turn 2 is
            % essentially unchanged between the two) is controlled by the
            % single manual switch in BrandtVariant.m.
            [aero, prop] = TestThrustConstraint.buildDisciplines(fidelityLevel);

            variant = BrandtVariant();
            b     = F16Baseline(variant);
            state = AircraftState(b.constraints.combat_sup.alt_ft, b.constraints.combat_sup.mach);
            obj   = ThrustConstraint("Combat Turn 2", state, aero, prop, 0.8997, b.constraints.combat_sup.n, 0.0);

            WS_range         = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_combatsup = b.constraints.combat_sup.TW_CombatSup;
            TW               = obj.required_TW(WS_range);

            % "required"/"available" columns (this class's TW_margin, 2nd/3rd
            % outputs) at Brandt's own actual design point (T_SL=b.engine.T_max,
            % W_TO=b.brandt.TOGW), evaluated at each W/S in the sweep -- alpha
            % is fixed for this condition, so "available" is constant across
            % rows while "required" (=alpha*required_TW(WS)) tracks TW*alpha.
            T_SL = b.engine.T_max;
            W_TO = b.brandt.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s, %s]\n', fidelityLevel, variant);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                [~, available_vals(i), required_vals(i)] = obj.TW_margin(WS_range(i), T_SL, W_TO);
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_combatsup(i), ...
                    100*(TW(i) - brandt_combatsup(i))/brandt_combatsup(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive (100%% AB, supersonic turn).', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] TW_margin''s required output must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] TW_margin''s available output must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16CombatSupRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Max Alt/Cruise).
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.combat_sup.alt_ft, b.constraints.combat_sup.mach);
            obj   = ThrustConstraint("Combat Turn 2", state, aero, prop, 0.8997, b.constraints.combat_sup.n, 0.0);

            TW = obj.required_TW(b.constraint.WS_opt);
            fprintf('\n    Combat Turn 2 required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                b.constraint.WS_opt, TW, b.constraint.TW_opt);
            tc.verifyGreaterThan(TW, 0.1, 'required_TW implausibly low for a supersonic-turn constraint.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Cruise condition ------------------------------------------
        % 36,000 ft, M=0.87, n=1.0, 0% AB (dry/mil power), Ps=0, beta=0.8997
        % [subplans/06_constraint_analysis.md; F16Baseline b.constraints.cruise]
        %
        % ALPHA BASIS (updated): Cruise is flown at 0% AB/dry (mil) power, so
        % it needs a mil-power thrust lapse rather than prop.thrust_lapse's
        % AB-basis default. PropulsionBase now exposes
        % thrust_lapse_mil_on_AB_scale (mil thrust re-normalized onto the AB
        % T_SL scale, matching Brandt's own alpha_mil_T_AB convention -- see
        % PropulsionBase.m and ThrustConstraint.m get_alpha), and the Cruise
        % ThrustConstraint instances below are constructed with
        % powerSetting="mil" so compute_A/B/C/D pull alpha from it. This
        % closes most (not all) of the previous ~2x-alpha gap at L2/L3 --
        % F16PropL2's mil lapse now lands ~0.032 absolute off Brandt's
        % alpha_mil_T_AB, well inside ALPHA_ABS_TOL=0.10. F16PropL1 has no
        % mil-power model and PropulsionBase's default thrust_lapse_mil_on_AB_scale
        % silently falls back to the AB-basis thrust_lapse, so Cruise at L1
        % specifically is UNAFFECTED by this fix and stays as inaccurate as
        % before -- do not be surprised its numbers didn't move. Full
        % diagnosis: cruise_and_combatturn2_error_scrape.md Sec 2.

        function testF16CruiseAlphaNearBrandt(tc)
            % F16PropL2's mil-power lapse, expressed on the AB T_SL scale via
            % thrust_lapse_mil_on_AB_scale, should be in the neighborhood of
            % Brandt's own alpha_mil_T_AB -- the value his Cruise row
            % equation actually uses (T_mil/T_SL_AB). Same AbsTol as the
            % Max Mach alpha check; the paired implementation agent's sanity
            % check found this lands ~0.032 absolute off, well inside it.
            b     = F16Baseline();
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            received = prop.thrust_lapse_mil_on_AB_scale(state);
            expected = b.constraints.cruise.alpha_mil_T_AB;   % 0.171083 [Brandt Consts AU24]
            fprintf('\n    alpha (Cruise, mil-on-AB-scale basis): received=%.4f  Brandt alpha_mil_T_AB=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Cruise alpha (mil-on-AB-scale basis) should be within 0.10 of Brandt AU24.');
        end

        function testF16CruiseDragPolarSubsonic(tc)
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            state = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            polar = aero.drag_polar(state);
            fprintf('\n    Cruise polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, b.constraints.cruise.CD0, b.constraints.cruise.K1, b.constraints.cruise.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16CruiseRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Cruise condition at
            % each fidelity level, alongside Brandt's full 21-point tabulated
            % row [F16Baseline b.constraints.cruise.TW_Cruise]. Constructed
            % with powerSetting="mil" so alpha is drawn from
            % thrust_lapse_mil_on_AB_scale (see this section's header
            % comment). At L2/L3 (F16PropL2's real mil-power model) expect
            % our values to read much closer to Brandt's table now -- most of
            % the previous ~2x-alpha gap is closed, leaving only the usual
            % CD0/K1 buildup-vs-flight-calibration gap already seen at
            % Max Mach. At L1 (F16PropL1, no mil-power model, silently falls
            % back to the AB-basis lapse) expect values to still read LOW vs.
            % Brandt, same as before this fix. Which F16Baseline() table this
            % prints against ("original" or "corrected" -- see F16Baseline.m
            % section 11b; Cruise is one of the rows that shifts materially
            % between the two) is controlled by the single manual switch in
            % BrandtVariant.m.
            [aero, prop] = TestThrustConstraint.buildDisciplines(fidelityLevel);

            variant = BrandtVariant();
            b     = F16Baseline(variant);
            state = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            obj   = ThrustConstraint("Cruise", state, aero, prop, 0.8997, 1.0, 0.0, "mil");

            WS_range     = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_cruise = b.constraints.cruise.TW_Cruise;
            TW           = obj.required_TW(WS_range);

            % "required"/"available" columns (this class's TW_margin, 2nd/3rd
            % outputs) at Brandt's own actual design point (T_SL=b.engine.T_max,
            % W_TO=b.brandt.TOGW), evaluated at each W/S in the sweep -- alpha
            % (mil-on-AB-scale basis, per this object's powerSetting="mil") is
            % fixed for this condition, so "available" is constant across rows
            % while "required" (=alpha*required_TW(WS)) tracks TW*alpha.
            T_SL = b.engine.T_max;
            W_TO = b.brandt.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s, %s]\n', fidelityLevel, variant);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                [~, available_vals(i), required_vals(i)] = obj.TW_margin(WS_range(i), T_SL, W_TO);
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_cruise(i), ...
                    100*(TW(i) - brandt_cruise(i))/brandt_cruise(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] TW_margin''s required output must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] TW_margin''s available output must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16CruiseRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not an exact
            % match to Brandt's TW_opt, though constructed with
            % powerSetting="mil" (see this section's header comment) so it's
            % now much closer than before this fix.
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.cruise.alt_ft, b.constraints.cruise.mach);
            obj   = ThrustConstraint("Cruise", state, aero, prop, 0.8997, 1.0, 0.0, "mil");

            TW = obj.required_TW(b.constraint.WS_opt);
            fprintf('\n    Cruise required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                b.constraint.WS_opt, TW, b.constraint.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Excess Power (Ps) condition --------------------------------
        % 10,000 ft, M=0.87, n=1.0, 100% AB, Ps=500 ft/s, beta=0.8997
        % [subplans/06_constraint_analysis.md; F16Baseline b.constraints.ps]
        %
        % Like Max Alt/Combat Turn 1/Combat Turn 2 (not Cruise), this
        % condition is flown at 100% AB, so prop.thrust_lapse's AB-basis
        % convention applies directly -- no alpha-basis mismatch. Like Max
        % Alt/Combat Turn 1, M=0.87 is subsonic, so K2 is the usual nonzero
        % value. The distinguishing feature of this condition is Ps=500 ft/s
        % (specific excess power for a climb/acceleration requirement, not
        % sustained level flight) -- the first condition tested here where
        % the Master Equation's D = (beta/alpha)*(Ps/V) term is nonzero.

        function testF16PsAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Ps condition should be in the neighborhood of Brandt's
            % alpha_AB -- same AbsTol as the other AB conditions.
            b     = F16Baseline();
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            received = prop.thrust_lapse(state);
            expected = b.constraints.ps.alpha_AB;   % 0.853550 [Brandt Consts AT28]
            fprintf('\n    alpha (Ps, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Ps alpha should be within 0.10 of Brandt AT28.');
        end

        function testF16PsDragPolarSubsonic(tc)
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            state = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            polar = aero.drag_polar(state);
            fprintf('\n    Ps polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, b.constraints.ps.CD0, b.constraints.ps.K1, b.constraints.ps.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16PsRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Ps condition at
            % each fidelity level, alongside Brandt's full 21-point tabulated
            % row [F16Baseline b.constraints.ps.TW_Ps]. Diagnostic only, same
            % caveats as testF16MaxAltRequiredTWTable (textbook CD0/K1 buildup
            % vs. Brandt's flight-calibrated polar). Which F16Baseline()
            % table this prints against ("original" or "corrected" -- see
            % F16Baseline.m section 11b; Ps is essentially unchanged between
            % the two) is controlled by the single manual switch in
            % BrandtVariant.m.
            [aero, prop] = TestThrustConstraint.buildDisciplines(fidelityLevel);

            variant = BrandtVariant();
            b     = F16Baseline(variant);
            state = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            obj   = ThrustConstraint("Excess Power", state, aero, prop, 0.8997, ...
                b.constraints.ps.n, b.constraints.ps.Ps_fps);

            WS_range   = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_ps  = b.constraints.ps.TW_Ps;
            TW         = obj.required_TW(WS_range);

            % "required"/"available" columns (this class's TW_margin, 2nd/3rd
            % outputs) at Brandt's own actual design point (T_SL=b.engine.T_max,
            % W_TO=b.brandt.TOGW), evaluated at each W/S in the sweep -- alpha
            % is fixed for this condition, so "available" is constant across
            % rows while "required" (=alpha*required_TW(WS)) tracks TW*alpha.
            T_SL = b.engine.T_max;
            W_TO = b.brandt.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s, %s]\n', fidelityLevel, variant);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                [~, available_vals(i), required_vals(i)] = obj.TW_margin(WS_range(i), T_SL, W_TO);
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_ps(i), ...
                    100*(TW(i) - brandt_ps(i))/brandt_ps(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] TW_margin''s required output must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] TW_margin''s available output must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16PsRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Max Alt/Cruise).
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            obj   = ThrustConstraint("Excess Power", state, aero, prop, 0.8997, ...
                b.constraints.ps.n, b.constraints.ps.Ps_fps);

            TW = obj.required_TW(b.constraint.WS_opt);
            fprintf('\n    Ps required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                b.constraint.WS_opt, TW, b.constraint.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        function testF16PsNonzeroPsIncreasesRequiredTW(tc)
            % Distinguishing feature of this condition vs. Max Mach/Max
            % Alt/Combat Turn 1/2/Cruise: Ps=500 ft/s (not 0), so the Master
            % Equation's D = (beta/alpha)*(Ps/V) term is active. Confirms
            % required_TW here is strictly greater than the same flight
            % condition evaluated at Ps=0 (sustained level flight) -- i.e.
            % that ThrustConstraint is actually using the nonzero Ps input,
            % not silently ignoring it.
            b     = F16Baseline();
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(b.constraints.ps.alt_ft, b.constraints.ps.mach);
            WS    = b.constraint.WS_opt;

            obj_ps0 = ThrustConstraint("Ps=0 reference", state, aero, prop, 0.8997, b.constraints.ps.n, 0.0);
            obj_ps  = ThrustConstraint("Excess Power", state, aero, prop, 0.8997, ...
                b.constraints.ps.n, b.constraints.ps.Ps_fps);

            TW_ps0 = obj_ps0.required_TW(WS);
            TW_ps  = obj_ps.required_TW(WS);
            fprintf('\n    required_TW at WS=%.2f: Ps=0 -> %.4f, Ps=%d ft/s -> %.4f\n', ...
                WS, TW_ps0, b.constraints.ps.Ps_fps, TW_ps);
            tc.verifyGreaterThan(TW_ps, TW_ps0, ...
                'Nonzero Ps must increase required T/W relative to sustained (Ps=0) flight.');
        end

    end

    methods (Static, Access = private)

        function [aero, prop] = buildDisciplines(fidelityLevel)
        %BUILDDISCIPLINES  F-16 aero/prop discipline pair for a fidelity level.
        %   No F16PropL3 exists yet, so L3 pairs F16AeroL3 with F16PropL2.
            switch fidelityLevel
                case 'L1'
                    aero = F16AeroL1(f16a_spec_path(1));
                    prop = F16PropL1(f16a_spec_path(1));
                case 'L2'
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(2));
                    prop = F16PropL2(f16a_spec_path(2));
                case 'L3'
                    aero = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
                    prop = F16PropL2(f16a_spec_path(2));
                otherwise
                    error('TestThrustConstraint:buildDisciplines:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end
end
