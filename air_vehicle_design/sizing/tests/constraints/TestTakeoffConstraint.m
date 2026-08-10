classdef TestTakeoffConstraint < matlab.unittest.TestCase
%TESTTAKEOFFCONSTRAINT  Unit tests for the generic TakeoffConstraint class
%   (Mattingly Master Equation, ground-roll/takeoff case) and its F-16
%   "Takeoff" instantiation.
%
%   Equation [Mattingly, Heiser, Pratt, "Aircraft Engine Design," 2nd ed.,
%   AIAA, 2002, Master Equation specialized to ground roll (T_SL>>D+R,
%   dh/dt=0), plus Brandt's own ground-roll drag/rolling-friction correction
%   (F-16A.xls Consts-sheet row 32, matching temp_Casey's takeoff_constraint.m
%   term2); B term matches NPTEL_Fighter_Aircraft_Sizing.ipynb's Takeoff class
%   (cells 32-33) -- NOT Raymer ch. 5, which gives only the graphical TOP
%   method, per TakeoffConstraint.m's header], as TakeoffConstraint.m
%   implements it:
%
%     T_SL/W_TO = (beta^2/alpha) * (k_TO^2 / (rho*g*CLmax_TO)) * (W_TO/S) / S_G
%                 + 0.7*CD0_TO/(beta*CLmax_TO) + mu
%
%   testRequiredTWMatchesHandComputedEquation checks required_TW against an
%   independently written form of the same equation (not a copy of
%   TakeoffConstraint's own algebra) using the same aero/prop discipline
%   outputs (get_CLmax_TO, get_Delta_CD0_TO, drag_polar, thrust_lapse --
%   each already unit-tested elsewhere). testEquationReproducesBrandtTakeoffPoint
%   drives the actual production code path with Brandt's own inputs (mu,
%   CD0, CLmax_TO, alpha_AB) and checks it reproduces his tabulated value
%   directly.
%
%   The F-16 Takeoff field condition [examples/F16A/mds/f16a_requirements.md
%   field-condition table]: sea level, k_TO=1.2, S_G=4,000 ft, mu=0.03,
%   beta=1.0. Brandt's full 21-point Consts-sheet row 32 (via
%   brandt_constraint_reference, BrandtConstraintAnalysis.run().TW_takeoff) is
%   printed by testF16TakeoffRequiredTWTable alongside our per-fidelity-level
%   values as a diagnostic (not an exact-match assertion, same spirit as the
%   MasterEquation testF16MaxMachRequiredTWTable) -- this framework's own
%   aero/prop fidelity-level gaps (documented in F16AeroLN/F16PropLN) still
%   drive some spread even though the equation itself now matches Brandt's.

    properties (TestParameter)
        % Aero/prop discipline pairing per fidelity level. No F16PropL3
        % exists yet, so L3 pairs F16AeroL3 with F16PropL2 (highest
        % propulsion fidelity available), matching TestThrustConstraint.
        fidelityLevel = {'L1', 'L2', 'L3'};
    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaPointPerformanceBase(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyTrue(isa(obj, 'PointPerformanceBase'));
        end

        function testIsaBothWbySTbyW(tc)
            % TakeoffConstraint belongs to the Both_WbyS_TbyW category as a
            % DIRECT sibling of the MasterEquationConstraint subtree (T9) --
            % see TakeoffConstraint.m/Both_WbyS_TbyW.m headers.
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'));
        end

        function testIsHandleClass(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyTrue(isa(obj, 'handle'));
        end

        function testNamePropertySet(tc)
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Takeoff", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyEqual(obj.name, "Takeoff");
        end

        function testDefaultBetaAndKTO(tc)
            % beta and k_TO default to 1.0 and 1.2 (field constraints, per
            % examples/F16A/mds/f16a_requirements.md) when omitted.
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, F16AeroL1(f16a_spec_path(1)), F16PropL2(f16a_spec_path(2)), 4000, 0.03);
            tc.verifyEqual(obj.beta, 1.0);
            tc.verifyEqual(obj.k_TO, 1.2);
        end

        % --- Equation assembly (generic, hand-computed) ---------------------

        function testRequiredTWMatchesHandComputedEquation(tc)
            % Arbitrary field length / margin (not F-16-specific data, just
            % uses the F-16 discipline objects as a concrete
            % AerodynamicsBase/PropulsionBase pair). Independently derived
            % form of the same equation, not a copy of TakeoffConstraint's
            % own algebra. Uses the FLAPPED takeoff CLmax/CD0
            % (get_CLmax_TO(), drag_polar(state).CD0 + get_Delta_CD0_TO())
            % since that is what compute_B/compute_C now call -- see
            % TakeoffConstraint.m's header. F16AeroL1's get_Delta_CD0_TO
            % takes no state argument (only F16AeroL3's does).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            S_G   = 3500;
            mu    = 0.03;
            beta  = 0.98;
            k_TO  = 1.15;
            WS    = 90;

            CLmax_TO = aero.get_CLmax_TO();
            CD0_TO   = aero.drag_polar(state).CD0 + aero.get_Delta_CD0_TO();
            alpha    = prop.thrust_lapse(state);
            rho      = state.rho;
            g        = 32.174;

            expected = (beta^2 / alpha) * (k_TO^2 / (rho * g * CLmax_TO)) * WS / S_G ...
                + 0.7 * CD0_TO / (beta * CLmax_TO) + mu;

            obj      = TakeoffConstraint("Toy", state, aero, prop, S_G, mu, beta, k_TO);
            received = obj.required_TW(WS);

            fprintf('\n    required_TW(WS=%d): received=%.6f  hand-computed=%.6f\n', WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 1e-10, ...
                'required_TW must equal the hand-computed takeoff equation.');
        end

        function testEquationReproducesBrandtTakeoffPoint(tc)
            % Plugs Brandt's own takeoff inputs directly into the same
            % equation TakeoffConstraint.m implements (B term + the
            % 0.7*CD0_TO/(beta*CLmax_TO) + mu correction) and checks it lands
            % within 0.5% of Brandt's own tabulated TW_Takeoff at W/S=90
            % (index 11 of the 20:7:160 sweep) [Brandt F-16A.xls Consts sheet,
            % row 32]. This validates the equation itself against Brandt's
            % worksheet -- separate from testRequiredTWMatchesHandComputedEquation's
            % generic algebra check and from testF16TakeoffRequiredTWTable's
            % aero-driven (textbook flapped CLmax_TO/CD0_TO per fidelity level,
            % not expected to match exactly) comparison.
            %
            % Brandt's own takeoff inputs and the tabulated result are
            % documented inline as Brandt-cited literals: this is an
            % equation-reproduction check, so the inputs and target are fixed
            % by Brandt's Consts row 32, not read live.
            mu       = 0.03;
            CLmax_TO = 1.2785;      % [Brandt Aero!L9]
            CD0_TO   = 0.052;       % [Brandt Consts row 32]
            alpha_AB = 0.955053;    % [Brandt Consts row 32, col AT]
            S_G      = 4000;
            k_TO     = 1.2;
            beta     = 1.0;
            WS       = 90;          % 11th point of Brandt's 20:7:160 sweep

            % Drive the actual production code path (TakeoffConstraint.required_TW,
            % which internally calls aero.get_CLmax_TO()/(aero.drag_polar(state).CD0
            % + aero.get_Delta_CD0_TO()) and prop.thrust_lapse(state)) via
            % fixed-value aero/prop stubs carrying Brandt's own already-
            % flapped numbers directly (FixedAeroStub's
            % get_CLmax_TO/get_Delta_CD0_TO just echo the constructor's
            % CLmax/CD0 and 0, respectively -- see FixedAeroStub.m's header),
            % rather than re-deriving the equation by hand in the test --
            % this way the test would catch a bug in TakeoffConstraint.m's
            % own algebra.
            aeroStub = FixedAeroStub(CLmax_TO, CD0_TO);
            propStub = FixedPropStub(alpha_AB);
            state    = AircraftState(0, 0.1);
            obj      = TakeoffConstraint("Takeoff", state, aeroStub, propStub, S_G, mu, beta, k_TO);

            received = obj.required_TW(WS);
            expected = 0.40514;   % [Brandt F-16A.xls Consts row 32, W/S=90]

            fprintf('\n    Takeoff required_TW at WS=%d (Brandt inputs): received=%.6f  Brandt=%.6f\n', ...
                WS, received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 5e-3, ...
                'The takeoff equation, fed Brandt''s own inputs, should reproduce Brandt''s TW_Takeoff to within 0.5%.');
        end

        % --- Feasibility residual --------------------------------------------

        function testConstraintResidualFeasibleAndInfeasible(tc)
            % Arbitrary field length/design point (not F-16-specific data).
            % Confirms Both_WbyS_TbyW.constraint_residual (shared with the
            % MasterEquationConstraint subtree) works through TakeoffConstraint's
            % own required_TW (affine in W/S, the old A=D=0 case, B and C
            % nonzero -- a different code path than the Master Equation's
            % bucket-shaped curve): g = required_TW(dp.WS) - dp.TW on the flat
            % SL-static basis (NO alpha scaling). Feeds one FEASIBLE and one
            % INFEASIBLE DesignPoint and asserts both the sign and the
            % hand-computed value.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 3500, 0.03, 0.98, 1.15);

            W_TO   = 32000;
            S_ref  = W_TO / 90;               % dp.WS = 90 lbf/ft^2
            TW_req = obj.required_TW(90);

            % Feasible: available T/W above required -> g < 0.
            dp_feas   = DesignPoint(W_TO, 1.10 * TW_req * W_TO, S_ref);
            g_feas    = obj.constraint_residual(dp_feas);
            expected_g_feas = TW_req - dp_feas.TW;

            % Infeasible: available T/W below required -> g > 0.
            dp_infeas = DesignPoint(W_TO, 0.90 * TW_req * W_TO, S_ref);
            g_infeas  = obj.constraint_residual(dp_infeas);
            expected_g_infeas = TW_req - dp_infeas.TW;

            fprintf(['\n    constraint_residual: required_TW=%.6f  ' ...
                'feasible g=%.6f  infeasible g=%.6f\n'], TW_req, g_feas, g_infeas);

            tc.verifyEqual(g_feas, expected_g_feas, 'RelTol', 1e-10, ...
                'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyLessThan(g_feas, 0, ...
                'A design with more T/W available than required must be feasible (g < 0).');
            tc.verifyEqual(g_infeas, expected_g_infeas, 'RelTol', 1e-10, ...
                'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyGreaterThan(g_infeas, 0, ...
                'A design with less T/W available than required must be infeasible (g > 0).');
        end

        function testRequiredTWVectorizedOverWS(tc)
            % Constraint diagrams sweep W/S -- required_TW must vectorize
            % cleanly and stay finite over a physically reasonable range.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 4000, 0.03);

            WS_range = 20:10:180;
            TW       = obj.required_TW(WS_range);

            tc.verifyEqual(numel(TW), numel(WS_range));
            tc.verifyTrue(all(isfinite(TW)), 'required_TW must be finite over the W/S sweep.');
        end

        function testRequiredTWAffineInWS(tc)
            % Unlike the Mattingly Master Equation (bucket-shaped), the
            % simplified takeoff relation is strictly linear in W/S:
            % required_TW = coeff * WS / S_G, so doubling WS must double TW.
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Toy", state, aero, prop, 4000, 0.03);

            WS = 60;
            d  = 20;
            TW_0 = obj.required_TW(WS);
            TW_1 = obj.required_TW(WS + d);
            TW_2 = obj.required_TW(WS + 2*d);

            tc.verifyEqual(TW_1 - TW_0, TW_2 - TW_1, 'RelTol', 1e-10, ...
                'required_TW must be affine in W/S (equal W/S steps -> equal T/W steps).');
        end

        function testRequiredTWIncreasesWithGroundRoll(tc)
            % A shorter required ground roll demands a higher T/W at fixed
            % W/S (harder field-length requirement -> more thrust needed).
            aero  = F16AeroL1(f16a_spec_path(1));
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            WS    = 90;

            obj_short = TakeoffConstraint("Short field", state, aero, prop, 2000, 0.03);
            obj_long  = TakeoffConstraint("Long field", state, aero, prop, 6000, 0.03);

            tc.verifyGreaterThan(obj_short.required_TW(WS), obj_long.required_TW(WS), ...
                'A shorter ground-roll requirement must demand a higher required T/W.');
        end

        % --- F-16 Takeoff field condition -----------------------------------
        % Sea level, k_TO=1.2, S_G=4,000 ft, beta=1.0
        % [examples/F16A/mds/f16a_requirements.md field-condition table]

        function testF16TakeoffRequiredTWPhysicalRange(tc)
            % Sanity check only -- no Brandt TW_Takeoff table to compare
            % against (see class header note). Confirms the F-16 discipline
            % objects produce a plausible, finite, positive required T/W at
            % a representative W/S.
            aero  = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3), f16a_control_surfaces());
            prop  = F16PropL2(f16a_spec_path(2));
            state = AircraftState(0, 0.1);
            obj   = TakeoffConstraint("Takeoff", state, aero, prop, 4000, 0.03, 1.0, 1.2);

            WS = 80;
            TW = obj.required_TW(WS);
            fprintf('\n    Takeoff required_TW at WS=%.2f: %.4f (CLmax_TO used=%.4f)\n', ...
                WS, TW, aero.get_CLmax_TO());
            tc.verifyGreaterThan(TW, 0, 'required_TW must be positive.');
            tc.verifyLessThan(TW, 5.0, 'required_TW implausibly high -- check for a gross error.');
        end

        function testF16TakeoffRequiredTWTable(tc, fidelityLevel)
            % Prints the full required_TW(W/S) table this framework's own
            % aero+prop discipline objects produce for the Takeoff condition
            % at each fidelity level, alongside Brandt's full 21-point
            % tabulated row [BrandtConstraintAnalysis.run().TW_takeoff, via
            % brandt_constraint_reference]. Now that the equation itself
            % includes Brandt's drag/rolling-
            % friction correction (see class header), the remaining diff is
            % from this framework's own textbook flapped-CLmax_TO/CD0_TO
            % estimate vs. Brandt's flight-calibrated values (same class of
            % per-fidelity gap as Landing, see LandingConstraint.m's header)
            % -- diagnostic only, not an exact-match assertion.
            [aero, prop] = TestTakeoffConstraint.buildDisciplines(fidelityLevel);

            ref   = brandt_constraint_reference();   % live Brandt Consts-row-32 table
            state = AircraftState(0, 0.1);   % sea level, near-zero Mach (avoids M=0 edge cases)
            obj   = TakeoffConstraint("Takeoff", state, aero, prop, 4000, 0.03, 1.0, 1.2);

            WS_range       = obj.WS_RANGE_BRANDT;     % Brandt's own 20:7:160 sweep (21 points)
            brandt_takeoff = ref.run.TW_takeoff;      % BrandtConstraintAnalysis.run(20:7:160).TW_takeoff
            TW            = obj.required_TW(WS_range);

            fprintf('\n    [%s]  %6s  %12s  %12s  %10s\n', fidelityLevel, 'W/S', 'Our T/W', 'Brandt T/W', 'diff %');
            for i = 1:numel(WS_range)
                fprintf('    %6d  %12.6f  %12.6f  %9.2f%%\n', WS_range(i), TW(i), brandt_takeoff(i), ...
                    100*(TW(i) - brandt_takeoff(i))/brandt_takeoff(i));
            end

            tc.verifyTrue(all(isfinite(TW)), sprintf('[%s] required_TW must be finite over the W/S sweep.', fidelityLevel));
            tc.verifyTrue(all(TW > 0), sprintf('[%s] required_TW must be positive.', fidelityLevel));
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
                    aero = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(2), f16a_control_surfaces());
                    prop = F16PropL2(f16a_spec_path(2));
                case 'L3'
                    aero = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), f16a_spec_path(3), f16a_control_surfaces());
                    prop = F16PropL2(f16a_spec_path(2));
                otherwise
                    error('TestTakeoffConstraint:buildDisciplines:UnknownFidelity', ...
                        'Unknown fidelity level "%s".', fidelityLevel);
            end
        end

    end

end
