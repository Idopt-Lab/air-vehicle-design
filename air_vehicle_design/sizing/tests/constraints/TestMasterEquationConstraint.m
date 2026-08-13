classdef TestMasterEquationConstraint < matlab.unittest.TestCase
%TESTMASTEREQUATIONCONSTRAINT  Unit tests for the MasterEquationConstraint subtree
%   (Mattingly Master Equation) and its F-16 condition instantiations.
%
%   The MasterEquationConstraint subtree has three specializations:
%   LevelFlightConstraint (n=1, Ps=0: Max Mach, Cruise, Max Alt),
%   SustainedTurnConstraint (n>1, Ps=0: Combat Turn 1 & 2), and
%   ExcessPowerConstraint (Ps>0: Excess Power). These tests instantiate
%   whichever specialization matches each condition's data. A few
%   generic-algebra checks that need both n>1 and Ps>0 active at once use
%   MasterEqTestConstraint, a thin concrete test double over the abstract
%   MasterEquationConstraint (see that file).
%
%   Brandt reference values are LIVE from brandt_constraint_reference (the
%   VnV/BrandtF16A model), not a hand-transcribed table.
%
%   Master Equation [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA,
%   2002; see also NPTEL_Fighter_Aircraft_Sizing.ipynb], as
%   MasterEquationConstraint.m implements it (algebraically simplified):
%
%     T_SL/W_TO = A/(W_TO/S) + B*(W_TO/S) + C + D
%       A = q*CD0/alpha
%       B = (q/alpha) * K1 * (n*beta/q)^2
%       C = K2 * n * beta / alpha
%       D = (beta/alpha) * (Ps/V)
%
%   testRequiredTWMatchesHandComputedMasterEquation checks required_TW
%   against the RAW, unsimplified form of the same equation (not the A/B/C/D
%   simplification above -- computing that would just copy the class's own
%   algebra back at it) using the same aero/prop discipline outputs
%   (drag_polar, thrust_lapse -- each already unit-tested elsewhere).

    properties (Constant)
        ALPHA_ABS_TOL = 0.10   % Brandt-vs-Mattingly alpha formula mismatch, matches TestPropL2.testLapseABAtDash
    end

    properties (TestParameter)
        % Aero/prop discipline pairing per fidelity level. No F16PropL3
        % exists yet, so L3 pairs F16AeroL3 with F16PropL2 (highest
        % propulsion fidelity available) -- the same pairing the sanity_checks
        % comparison reports use (their L3 propulsion columns are NaN for the same reason).
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    properties
        ref   % live Brandt constraint reference (brandt_constraint_reference), built once
    end

    methods (TestClassSetup)
        function buildBrandtReference(tc)
            % Build the Brandt discipline chain + constraint analysis once for
            % the whole class; the diagnostic tests read WS_land / the
            % design-point trio / WS_opt from it (replaces the retired baseline).
            tc.ref = brandt_constraint_reference();
        end
    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaPointPerformanceBase(tc)
            state = AircraftState(0, 0.5);
            obj   = LevelFlightConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaMasterEquationConstraintAndBoth(tc)
            % Every specialization is a MasterEquationConstraint (hence a
            % Both_WbyS_TbyW, hence a PointPerformanceBase) -- see the subtree
            % headers.
            state = AircraftState(0, 0.5);
            obj   = LevelFlightConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyTrue(isa(obj, 'MasterEquationConstraint'));
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.5);
            obj   = LevelFlightConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.5);
            obj   = LevelFlightConstraint("Max Mach", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 1.0);
            tc.verifyEqual(obj.name, "Max Mach");
        end

        function testLevelFlightFixesLoadFactorAndPs(tc)
            % LevelFlightConstraint fixes n=1.0 and Ps=0.0 (sustained,
            % unaccelerated flight), per its constructor.
            state = AircraftState(0, 0.5);
            obj   = LevelFlightConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 0.9);
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
            % MasterEquationConstraint.m implements) -- a genuinely independent
            % derivation, not a copy of the class's own algebra, so it
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

            obj      = MasterEqTestConstraint("Toy", state, aero, prop, beta, n, Ps);
            received = obj.required_TW(WS);

            fprintf('\n    required_TW(WS=%d): received=%.6f  hand-computed=%.6f\n', WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'required_TW must equal the raw (unsimplified) Master Equation.');
        end

        % --- Feasibility residual --------------------------------------------

        function testConstraintResidualMatchesHandComputedFormula(tc)
            % Arbitrary condition/design point (not F-16-specific data).
            % required_TW itself is already independently verified above, so
            % this only needs to confirm constraint_residual combines it with
            % the design point's SL-static T/W correctly: g = required_TW(dp.WS)
            % - dp.TW, on the flat SL-static basis (NO alpha scaling). Feeds one
            % FEASIBLE and one INFEASIBLE DesignPoint and asserts both the sign
            % and the hand-computed value.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            obj   = MasterEqTestConstraint("Toy", state, aero, prop, 0.95, 2.0, 50);

            W_TO  = 32000;
            S_ref = W_TO / 90;                 % gives dp.WS = 90 lbf/ft^2
            TW_req = obj.required_TW(90);      % required T/W at this W/S

            % Feasible: available T/W a hair above required -> g < 0.
            T_SL_feas   = 1.10 * TW_req * W_TO;
            dp_feas     = DesignPoint(W_TO, T_SL_feas, S_ref);
            g_feas      = obj.constraint_residual(dp_feas);
            expected_g_feas = TW_req - dp_feas.TW;

            % Infeasible: available T/W below required -> g > 0.
            T_SL_infeas = 0.90 * TW_req * W_TO;
            dp_infeas   = DesignPoint(W_TO, T_SL_infeas, S_ref);
            g_infeas    = obj.constraint_residual(dp_infeas);
            expected_g_infeas = TW_req - dp_infeas.TW;

            fprintf(['\n    constraint_residual: required_TW=%.6f  ' ...
                'feasible(TW=%.6f) g=%.6f  infeasible(TW=%.6f) g=%.6f\n'], ...
                TW_req, dp_feas.TW, g_feas, dp_infeas.TW, g_infeas);

            tc.verifyEqual(g_feas, expected_g_feas, 'RelTol', 1e-10, ...
                'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyLessThan(g_feas, 0, ...
                'A design with more T/W available than required must be feasible (g < 0).');
            tc.verifyEqual(g_infeas, expected_g_infeas, 'RelTol', 1e-10, ...
                'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyGreaterThan(g_infeas, 0, ...
                'A design with less T/W available than required must be infeasible (g > 0).');
        end

        function testConstraintResidualDecreasesWithAvailableThrust(tc)
            % More installed sea-level-static thrust (same W_TO, same S_ref)
            % raises available T/W, so the residual g = required - available
            % must DECREASE (move toward/into feasibility) -- everything else
            % held fixed. required_TW(dp.WS) is identical between the two calls
            % (same condition, same W/S), only available T/W moves.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            obj   = MasterEqTestConstraint("Toy", state, aero, prop, 0.95, 2.0, 50);

            W_TO  = 32000;
            S_ref = W_TO / 90;   % dp.WS = 90 lbf/ft^2

            g_low  = obj.constraint_residual(DesignPoint(W_TO, 20000, S_ref));
            g_high = obj.constraint_residual(DesignPoint(W_TO, 30000, S_ref));

            fprintf('\n    T_SL=20000: g=%.6f    T_SL=30000: g=%.6f\n', g_low, g_high);
            tc.verifyLessThan(g_high, g_low, ...
                'More installed T_SL must decrease the residual (toward feasibility).');
        end

        function testConstraintResidualZeroAtRequiredBoundary(tc)
            % When available T/W is set to exactly required_TW at dp.WS, the
            % residual must be ~0 -- the definitional boundary between feasible
            % (g <= 0) and infeasible (g > 0).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.6);
            obj   = MasterEqTestConstraint("Toy", state, aero, prop, 0.95, 2.0, 50);

            W_TO        = 32000;
            S_ref       = W_TO / 90;             % dp.WS = 90 lbf/ft^2
            TW_required = obj.required_TW(90);
            T_SL        = TW_required * W_TO;     % dp.TW == required exactly
            dp          = DesignPoint(W_TO, T_SL, S_ref);

            g = obj.constraint_residual(dp);
            fprintf('\n    At boundary: required_TW=%.6f  dp.TW=%.6f  g=%.6f\n', ...
                TW_required, dp.TW, g);
            tc.verifyEqual(dp.TW, TW_required, 'RelTol', 1e-10, ...
                'dp.TW must equal required_TW exactly at this constructed boundary.');
            tc.verifyEqual(g, 0, 'AbsTol', 1e-10, ...
                'constraint_residual must be ~0 when dp.TW exactly equals required_TW.');
        end

        function testRequiredTWVectorizedOverWS(tc)
            % Constraint diagrams sweep W/S -- required_TW must vectorize
            % cleanly and stay finite over a physically reasonable range.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.8);
            obj   = LevelFlightConstraint("Toy", state, aero, prop, 0.95);

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

            obj    = LevelFlightConstraint("Toy", state, aero, prop, beta);  % n=1, Ps=0
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
        % [examples/F16A/inputs/f16a_requirements.md; Brandt Consts sheet
        % (via brandt_constraint_reference)]

        function testF16MaxMachAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Max Mach condition should be in the neighborhood of
            % Brandt's alpha_AB -- same AbsTol as TestPropL2.testLapseABAtDash,
            % since Brandt's formula and normalization differ from Mattingly
            % Eq. 2.54.
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 1.60);   % Max Mach: 36 kft, M=1.60
            received = prop.thrust_lapse(state);
            expected = tc.ref.eng.run(36000, 1.60, 1.0).alpha_AB_ref;   % [Brandt Consts, 100% AB]
            fprintf('\n    alpha (Max Mach, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Max Mach alpha should be within 0.10 of Brandt AT23.');
        end

        function testF16MaxMachDragPolarK2ZeroSupersonic(tc)
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            state = AircraftState(36000, 1.60);   % Max Mach: 36 kft, M=1.60
            polar = aero.drag_polar(state);
            aBr   = tc.ref.aero.run(1.60);
            fprintf('\n    Max Mach polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, aBr.CD0, aBr.K1, aBr.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, 'K2 must be 0 supersonic.');
        end

        function testF16MaxMachRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Max Mach condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [Brandt Consts sheet, via brandt_constraint_reference].
            % L1/L2 still read LOW vs. Brandt (~40-51%/~47-57% across the
            % sweep) -- CD0 is a flat Cfe*Swet/Sref estimate with no Mach
            % dependence at all, so neither ever picks up the supersonic
            % wave-drag rise. L3 now reads CLOSE to Brandt (within about
            % +2.5% to +3.0% across the sweep) since F16AeroL3.compute_CD0_wave
            % was fixed to use the true whole-aircraft Amax/length (Raymer
            % 6th ed. Eqs. 12.44-12.45, see F16AeroL3.md) instead
            % of a fuselage-only approximation -- "higher fidelity is more
            % accurate" now holds here, reversing the earlier state where L3
            % (fuselage-only wave drag) undershot even L1's flat estimate.
            % Remaining ~+3% at L3 is a known, smaller residual gap (Brandt's
            % own flight-calibrated polar vs. this framework's textbook
            % buildup), not a Master-Equation constraint bug.
            [aero, prop] = TestMasterEquationConstraint.buildDisciplines(fidelityLevel);

            state = AircraftState(36000, 1.60);   % Max Mach: 36 kft, M=1.60
            obj   = LevelFlightConstraint("Max Mach", state, aero, prop, 0.8997);

            WS_range      = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_MxMach = tc.ref.run.TW_max_mach;
            TW            = obj.required_TW(WS_range);

            % "required"/"available" diagnostic columns on the SL-static basis
            % (matching constraint_residual's g = required - available axis) at
            % Brandt's own actual design point (T_SL=ref.T_SL, W_TO=ref.TOGW):
            % "required" = required_TW(WS) tracks the curve, "available" =
            % T_SL/W_TO is the flat design-point T/W (constant across rows).
            T_SL = tc.ref.T_SL;
            W_TO = tc.ref.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s]\n', fidelityLevel);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                required_vals(i)  = obj.required_TW(WS_range(i));
                available_vals(i) = T_SL / W_TO;
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_MxMach(i), ...
                    100*(TW(i) - brandt_MxMach(i))/brandt_MxMach(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive (100%% AB, supersonic dash).', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] the SL-static available T/W must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16MaxMachRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match
            % to Brandt's TW_opt (~0.7576): our textbook CD0/K1 buildup is
            % expected to differ from Brandt's flight-calibrated polar.
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 1.60);   % Max Mach: 36 kft, M=1.60
            obj   = LevelFlightConstraint("Max Mach", state, aero, prop, 0.8997);

            TW = obj.required_TW(tc.ref.run.WS_opt);
            fprintf('\n    Max Mach required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                tc.ref.run.WS_opt, TW, tc.ref.run.TW_opt);
            tc.verifyGreaterThan(TW, 0.1, 'required_TW implausibly low for a supersonic-dash constraint.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Max Alt (ceiling) condition -------------------------------
        % 50,000 ft, M=0.87, n=1.0, 100% AB, Ps=0, beta=0.8997
        % [examples/F16A/inputs/f16a_requirements.md; Brandt Consts sheet
        % (via brandt_constraint_reference)]
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
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(50000, 0.87);   % Max Alt: 50 kft, M=0.87
            received = prop.thrust_lapse(state);
            expected = tc.ref.eng.run(50000, 0.87, 1.0).alpha_AB_ref;   % [Brandt Consts, 100% AB]
            fprintf('\n    alpha (Max Alt, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Max Alt alpha should be within 0.10 of Brandt AT25.');
        end

        function testF16MaxAltDragPolarSubsonic(tc)
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            state = AircraftState(50000, 0.87);   % Max Alt: 50 kft, M=0.87
            polar = aero.drag_polar(state);
            aBr   = tc.ref.aero.run(0.87);
            fprintf('\n    Max Alt polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, aBr.CD0, aBr.K1, aBr.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16MaxAltRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Max Alt condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [Brandt Consts sheet, via brandt_constraint_reference].
            % Diagnostic only, same caveats as testF16CruiseRequiredTWTable
            % (textbook CD0/K1 buildup vs. Brandt's flight-calibrated polar).
            [aero, prop] = TestMasterEquationConstraint.buildDisciplines(fidelityLevel);

            state = AircraftState(50000, 0.87);   % Max Alt: 50 kft, M=0.87
            obj   = LevelFlightConstraint("Max Alt", state, aero, prop, 0.8997);

            WS_range      = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_maxalt = tc.ref.run.TW_max_alt;
            TW            = obj.required_TW(WS_range);

            % "required"/"available" diagnostic columns on the SL-static basis
            % (matching constraint_residual's g = required - available axis) at
            % Brandt's own actual design point (T_SL=ref.T_SL, W_TO=ref.TOGW):
            % "required" = required_TW(WS) tracks the curve, "available" =
            % T_SL/W_TO is the flat design-point T/W (constant across rows).
            T_SL = tc.ref.T_SL;
            W_TO = tc.ref.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s]\n', fidelityLevel);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                required_vals(i)  = obj.required_TW(WS_range(i));
                available_vals(i) = T_SL / W_TO;
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_maxalt(i), ...
                    100*(TW(i) - brandt_maxalt(i))/brandt_maxalt(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] the SL-static available T/W must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16MaxAltRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Cruise).
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(50000, 0.87);   % Max Alt: 50 kft, M=0.87
            obj   = LevelFlightConstraint("Max Alt", state, aero, prop, 0.8997);

            TW = obj.required_TW(tc.ref.run.WS_opt);
            fprintf('\n    Max Alt required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                tc.ref.run.WS_opt, TW, tc.ref.run.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Combat Turn 1 (subsonic) condition -------------------------
        % 20,000 ft, M=0.87, n=4.5, 100% AB, Ps=0, beta=0.8997
        % [examples/F16A/inputs/f16a_requirements.md; Brandt Consts sheet
        % (via brandt_constraint_reference)]
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
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.87);   % Combat Turn 1: 20 kft, M=0.87
            received = prop.thrust_lapse(state);
            expected = tc.ref.eng.run(20000, 0.87, 1.0).alpha_AB_ref;   % [Brandt Consts, 100% AB]
            fprintf('\n    alpha (Combat Turn 1, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Combat Turn 1 alpha should be within 0.10 of Brandt AT26.');
        end

        function testF16CombatSubDragPolarSubsonic(tc)
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            state = AircraftState(20000, 0.87);   % Combat Turn 1: 20 kft, M=0.87
            polar = aero.drag_polar(state);
            aBr   = tc.ref.aero.run(0.87);
            fprintf('\n    Combat Turn 1 polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, aBr.CD0, aBr.K1, aBr.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16CombatSubRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Combat Turn 1
            % condition at each fidelity level, alongside Brandt's full
            % 21-point tabulated row [Brandt Consts sheet, via
            % brandt_constraint_reference]. Diagnostic only, same caveats as
            % testF16MaxAltRequiredTWTable (textbook CD0/K1 buildup vs.
            % Brandt's flight-calibrated polar) -- n=4.5 also means the K1
            % (induced-drag) term dominates far more here than at the n=1.0
            % conditions, so any K1 buildup gap will show up amplified.
            [aero, prop] = TestMasterEquationConstraint.buildDisciplines(fidelityLevel);

            state = AircraftState(20000, 0.87);   % Combat Turn 1: 20 kft, M=0.87
            obj   = SustainedTurnConstraint("Combat Turn 1", state, aero, prop, 0.8997, 4.5);   % n=4.5

            WS_range         = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_combatsub = tc.ref.run.TW_combat_turn_sub;
            TW               = obj.required_TW(WS_range);

            % "required"/"available" diagnostic columns on the SL-static basis
            % (matching constraint_residual's g = required - available axis) at
            % Brandt's own actual design point (T_SL=ref.T_SL, W_TO=ref.TOGW):
            % "required" = required_TW(WS) tracks the curve, "available" =
            % T_SL/W_TO is the flat design-point T/W (constant across rows).
            T_SL = tc.ref.T_SL;
            W_TO = tc.ref.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s]\n', fidelityLevel);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                required_vals(i)  = obj.required_TW(WS_range(i));
                available_vals(i) = T_SL / W_TO;
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_combatsub(i), ...
                    100*(TW(i) - brandt_combatsub(i))/brandt_combatsub(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] the SL-static available T/W must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16CombatSubRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Max Alt/Cruise).
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(20000, 0.87);   % Combat Turn 1: 20 kft, M=0.87
            obj   = SustainedTurnConstraint("Combat Turn 1", state, aero, prop, 0.8997, 4.5);   % n=4.5

            TW = obj.required_TW(tc.ref.run.WS_opt);
            fprintf('\n    Combat Turn 1 required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                tc.ref.run.WS_opt, TW, tc.ref.run.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Combat Turn 2 (supersonic) condition -----------------------
        % 36,000 ft, M=1.4, n=1.4, 100% AB, Ps=0, beta=0.8997
        % [examples/F16A/inputs/f16a_requirements.md; Brandt Consts sheet
        % (via brandt_constraint_reference)]
        %
        % Like Combat Turn 1, this condition is flown at 100% AB, so
        % prop.thrust_lapse's AB-basis convention applies directly. Like Max
        % Mach (not Max Alt/Combat Turn 1), M=1.4 is supersonic.

        function testF16CombatSupAlphaNearBrandt(tc)
            % thrust_lapse (AB/max power, per PropulsionBase convention) at
            % the Combat Turn 2 condition should be in the neighborhood of
            % Brandt's alpha_AB -- same AbsTol as the other AB conditions.
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 1.40);   % Combat Turn 2: 36 kft, M=1.40
            received = prop.thrust_lapse(state);
            expected = tc.ref.eng.run(36000, 1.40, 1.0).alpha_AB_ref;   % [Brandt Consts, 100% AB]
            fprintf('\n    alpha (Combat Turn 2, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Combat Turn 2 alpha should be within 0.10 of Brandt AT27.');
        end

        function testF16CombatSupDragPolarK2ZeroSupersonic(tc)
            % Same K2=0 supersonic assumption as Max Mach (M=1.4 > 1 here
            % too). Brandt's own K2 for this row is not exactly zero --
            % printed for reference, not asserted against, per this
            % framework's own linearized-theory K2=0 supersonic assumption
            % (AeroL1.K2_value).
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            state = AircraftState(36000, 1.40);   % Combat Turn 2: 36 kft, M=1.40
            polar = aero.drag_polar(state);
            aBr   = tc.ref.aero.run(1.40);
            fprintf('\n    Combat Turn 2 polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, aBr.CD0, aBr.K1, aBr.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, 'K2 must be 0 supersonic.');
        end

        function testF16CombatSupRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Combat Turn 2
            % condition at each fidelity level, alongside Brandt's full
            % 21-point tabulated row [Brandt Consts sheet, via
            % brandt_constraint_reference]. Diagnostic only, same caveats as
            % testF16MaxMachRequiredTWTable: L1/L2 still read far LOW vs.
            % Brandt (~30-54%/~44-63%, no Mach-dependent CD0 at all), while
            % L3 now reads much closer (~8.4-8.9% low across the sweep) since
            % compute_CD0_wave was fixed to use the true whole-aircraft
            % Amax/length instead of a fuselage-only approximation (see
            % F16AeroL3.md) -- textbook CD0/K1 buildup vs.
            % Brandt's flight-calibrated polar accounts for the remainder.
            [aero, prop] = TestMasterEquationConstraint.buildDisciplines(fidelityLevel);

            state = AircraftState(36000, 1.40);   % Combat Turn 2: 36 kft, M=1.40
            obj   = SustainedTurnConstraint("Combat Turn 2", state, aero, prop, 0.8997, 1.4);   % n=1.4

            WS_range         = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_combatsup = tc.ref.run.TW_combat_turn_sup;
            TW               = obj.required_TW(WS_range);

            % "required"/"available" diagnostic columns on the SL-static basis
            % (matching constraint_residual's g = required - available axis) at
            % Brandt's own actual design point (T_SL=ref.T_SL, W_TO=ref.TOGW):
            % "required" = required_TW(WS) tracks the curve, "available" =
            % T_SL/W_TO is the flat design-point T/W (constant across rows).
            T_SL = tc.ref.T_SL;
            W_TO = tc.ref.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s]\n', fidelityLevel);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                required_vals(i)  = obj.required_TW(WS_range(i));
                available_vals(i) = T_SL / W_TO;
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_combatsup(i), ...
                    100*(TW(i) - brandt_combatsup(i))/brandt_combatsup(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive (100%% AB, supersonic turn).', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] the SL-static available T/W must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16CombatSupRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Max Alt/Cruise).
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 1.40);   % Combat Turn 2: 36 kft, M=1.40
            obj   = SustainedTurnConstraint("Combat Turn 2", state, aero, prop, 0.8997, 1.4);   % n=1.4

            TW = obj.required_TW(tc.ref.run.WS_opt);
            fprintf('\n    Combat Turn 2 required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                tc.ref.run.WS_opt, TW, tc.ref.run.TW_opt);
            tc.verifyGreaterThan(TW, 0.1, 'required_TW implausibly low for a supersonic-turn constraint.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Cruise condition ------------------------------------------
        % 36,000 ft, M=0.87, n=1.0, 0% AB (dry/mil power), Ps=0, beta=0.8997
        % [examples/F16A/inputs/f16a_requirements.md; Brandt Consts sheet
        % (via brandt_constraint_reference)]
        %
        % ALPHA BASIS (updated): Cruise is flown at 0% AB/dry (mil) power, so
        % it needs a mil-power thrust lapse rather than prop.thrust_lapse's
        % AB-basis default. PropulsionBase now exposes
        % thrust_lapse_mil_on_AB_scale (mil thrust re-normalized onto the AB
        % T_SL scale, matching Brandt's own alpha_mil_T_AB convention -- see
        % PropulsionBase.m and MasterEquationConstraint.m get_alpha), and the
        % Cruise LevelFlightConstraint instances below are constructed with
        % powerSetting="mil" so compute_A/B/C/D pull alpha from it. This
        % closes most (not all) of the previous ~2x-alpha gap at L2/L3 --
        % F16PropL2's mil lapse now lands ~0.032 absolute off Brandt's
        % alpha_mil_T_AB, well inside ALPHA_ABS_TOL=0.10. F16PropL1 has no
        % mil-power model and PropulsionBase's default thrust_lapse_mil_on_AB_scale
        % silently falls back to the AB-basis thrust_lapse, so Cruise at L1
        % specifically is UNAFFECTED by this fix and stays as inaccurate as
        % before -- do not be surprised its numbers didn't move. Full
        % diagnosis: see MasterEquationConstraint.m's power-setting rationale.

        function testF16CruiseAlphaNearBrandt(tc)
            % F16PropL2's mil-power lapse, expressed on the AB T_SL scale via
            % thrust_lapse_mil_on_AB_scale, should be in the neighborhood of
            % Brandt's own alpha_mil_T_AB -- the value his Cruise row
            % equation actually uses (T_mil/T_SL_AB). Same AbsTol as the
            % Max Mach alpha check; the paired implementation agent's sanity
            % check found this lands ~0.032 absolute off, well inside it.
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 0.87);   % Cruise: 36 kft, M=0.87
            received = prop.thrust_lapse_mil_on_AB_scale(state);
            expected = tc.ref.eng.run(36000, 0.87, 0.0).alpha_AB_ref;   % [Brandt Consts, mil/dry -> alpha_mil_T_AB]
            fprintf('\n    alpha (Cruise, mil-on-AB-scale basis): received=%.4f  Brandt alpha_mil_T_AB=%.4f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Cruise alpha (mil-on-AB-scale basis) should be within 0.10 of Brandt AU24.');
        end

        function testF16CruiseDragPolarSubsonic(tc)
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            state = AircraftState(36000, 0.87);   % Cruise: 36 kft, M=0.87
            polar = aero.drag_polar(state);
            aBr   = tc.ref.aero.run(0.87);
            fprintf('\n    Cruise polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, aBr.CD0, aBr.K1, aBr.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16CruiseRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Cruise condition at
            % each fidelity level, alongside Brandt's full 21-point tabulated
            % row [Brandt Consts sheet, via brandt_constraint_reference].
            % Constructed with powerSetting="mil" so alpha is drawn from
            % thrust_lapse_mil_on_AB_scale (see this section's header
            % comment). At L2/L3 (F16PropL2's real mil-power model) expect
            % our values to read much closer to Brandt's table now -- most of
            % the previous ~2x-alpha gap is closed, leaving only the usual
            % CD0/K1 buildup-vs-flight-calibration gap already seen at
            % Max Mach. At L1 (F16PropL1, no mil-power model, silently falls
            % back to the AB-basis lapse) expect values to still read LOW vs.
            % Brandt, same as before this fix.
            [aero, prop] = TestMasterEquationConstraint.buildDisciplines(fidelityLevel);

            state = AircraftState(36000, 0.87);   % Cruise: 36 kft, M=0.87
            obj   = LevelFlightConstraint("Cruise", state, aero, prop, 0.8997, "mil");

            WS_range     = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_cruise = tc.ref.run.TW_cruise;
            TW           = obj.required_TW(WS_range);

            % "required"/"available" diagnostic columns on the SL-static basis
            % (matching constraint_residual's g = required - available axis) at
            % Brandt's own actual design point (T_SL=ref.T_SL, W_TO=ref.TOGW):
            % "required" = required_TW(WS) tracks the curve, "available" =
            % T_SL/W_TO is the flat design-point T/W (constant across rows).
            T_SL = tc.ref.T_SL;
            W_TO = tc.ref.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s]\n', fidelityLevel);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                required_vals(i)  = obj.required_TW(WS_range(i));
                available_vals(i) = T_SL / W_TO;
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_cruise(i), ...
                    100*(TW(i) - brandt_cruise(i))/brandt_cruise(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] the SL-static available T/W must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16CruiseRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not an exact
            % match to Brandt's TW_opt, though constructed with
            % powerSetting="mil" (see this section's header comment) so it's
            % now much closer than before this fix.
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(36000, 0.87);   % Cruise: 36 kft, M=0.87
            obj   = LevelFlightConstraint("Cruise", state, aero, prop, 0.8997, "mil");

            TW = obj.required_TW(tc.ref.run.WS_opt);
            fprintf('\n    Cruise required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                tc.ref.run.WS_opt, TW, tc.ref.run.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        % --- F-16 Excess Power (Ps) condition --------------------------------
        % 10,000 ft, M=0.87, n=1.0, 100% AB, Ps=500 ft/s, beta=0.8997
        % [examples/F16A/inputs/f16a_requirements.md; Brandt Consts sheet
        % (via brandt_constraint_reference)]
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
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.87);   % Excess Power: 10 kft, M=0.87
            received = prop.thrust_lapse(state);
            expected = tc.ref.eng.run(10000, 0.87, 1.0).alpha_AB_ref;   % [Brandt Consts, 100% AB]
            fprintf('\n    alpha (Ps, AB): received=%.4f  Brandt=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', tc.ALPHA_ABS_TOL, ...
                'Ps alpha should be within 0.10 of Brandt AT28.');
        end

        function testF16PsDragPolarSubsonic(tc)
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            state = AircraftState(10000, 0.87);   % Excess Power: 10 kft, M=0.87
            polar = aero.drag_polar(state);
            aBr   = tc.ref.aero.run(0.87);
            fprintf('\n    Ps polar: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                polar.CD0, polar.K1, polar.K2, aBr.CD0, aBr.K1, aBr.K2);
            tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
            tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
        end

        function testF16PsRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Ps condition at
            % each fidelity level, alongside Brandt's full 21-point tabulated
            % row [Brandt Consts sheet, via brandt_constraint_reference].
            % Diagnostic only, same caveats as testF16MaxAltRequiredTWTable
            % (textbook CD0/K1 buildup vs. Brandt's flight-calibrated polar).
            [aero, prop] = TestMasterEquationConstraint.buildDisciplines(fidelityLevel);

            state = AircraftState(10000, 0.87);   % Excess Power: 10 kft, M=0.87
            obj   = ExcessPowerConstraint("Excess Power", state, aero, prop, 0.8997, ...
                500);   % Ps=500 ft/s; n=1 fixed by ExcessPowerConstraint

            WS_range   = obj.WS_RANGE_BRANDT;      % Brandt's own 20:7:160 sweep (21 points)
            brandt_ps  = tc.ref.run.TW_ps500;
            TW         = obj.required_TW(WS_range);

            % "required"/"available" diagnostic columns on the SL-static basis
            % (matching constraint_residual's g = required - available axis) at
            % Brandt's own actual design point (T_SL=ref.T_SL, W_TO=ref.TOGW):
            % "required" = required_TW(WS) tracks the curve, "available" =
            % T_SL/W_TO is the flat design-point T/W (constant across rows).
            T_SL = tc.ref.T_SL;
            W_TO = tc.ref.TOGW;
            required_vals  = zeros(size(WS_range));
            available_vals = zeros(size(WS_range));

            fprintf('\n    [%s]\n', fidelityLevel);
            fprintf('    %6s  %12s  %12s  %10s  %12s  %12s\n', ...
                'W/S', 'Our T/W', 'Brandt T/W', 'diff %', 'required', 'available');
            for i = 1:numel(WS_range)
                required_vals(i)  = obj.required_TW(WS_range(i));
                available_vals(i) = T_SL / W_TO;
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%  %12.6f  %12.6f\n', WS_range(i), TW(i), brandt_ps(i), ...
                    100*(TW(i) - brandt_ps(i))/brandt_ps(i), required_vals(i), available_vals(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
            tc.verifyTrue(all(isfinite(required_vals)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(isfinite(available_vals)), sprintf('[%s] the SL-static available T/W must be finite over the W/S sweep.', fidelityLevel));
        end

        function testF16PsRequiredTWPhysicalRange(tc)
            % Sanity check only, at Brandt's own optimal W/S -- not a match to
            % Brandt's TW_opt (see class note on CD0/K1 buildup-vs-flight-
            % calibration gap already documented at Max Mach/Max Alt/Cruise).
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.87);   % Excess Power: 10 kft, M=0.87
            obj   = ExcessPowerConstraint("Excess Power", state, aero, prop, 0.8997, ...
                500);   % Ps=500 ft/s; n=1 fixed by ExcessPowerConstraint

            TW = obj.required_TW(tc.ref.run.WS_opt);
            fprintf('\n    Ps required_TW at Brandt WS_opt=%.2f: %.4f  (Brandt TW_opt=%.4f, reference only)\n', ...
                tc.ref.run.WS_opt, TW, tc.ref.run.TW_opt);
            tc.verifyGreaterThan(TW, 0.01, 'required_TW implausibly low.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        function testF16PsNonzeroPsIncreasesRequiredTW(tc)
            % Distinguishing feature of this condition vs. Max Mach/Max
            % Alt/Combat Turn 1/2/Cruise: Ps=500 ft/s (not 0), so the Master
            % Equation's D = (beta/alpha)*(Ps/V) term is active. Confirms
            % required_TW here is strictly greater than the same flight
            % condition evaluated at Ps=0 (sustained level flight) -- i.e.
            % that ExcessPowerConstraint is actually using the nonzero Ps input,
            % not silently ignoring it.
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(10000, 0.87);   % Excess Power: 10 kft, M=0.87
            WS    = tc.ref.run.WS_opt;
            Ps    = 500;   % Ps=500 ft/s

            obj_ps0 = LevelFlightConstraint("Ps=0 reference", state, aero, prop, 0.8997);  % n=1
            obj_ps  = ExcessPowerConstraint("Excess Power", state, aero, prop, 0.8997, Ps);

            TW_ps0 = obj_ps0.required_TW(WS);
            TW_ps  = obj_ps.required_TW(WS);
            fprintf('\n    required_TW at WS=%.2f: Ps=0 -> %.4f, Ps=%d ft/s -> %.4f\n', ...
                WS, TW_ps0, Ps, TW_ps);
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
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2));
                    prop = F16PropL2(f16a_spec_path(2));
                case 'L3'
                    aero = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3));
                    prop = F16PropL2(f16a_spec_path(2));
                otherwise
                    error('TestMasterEquationConstraint:buildDisciplines:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end
end
