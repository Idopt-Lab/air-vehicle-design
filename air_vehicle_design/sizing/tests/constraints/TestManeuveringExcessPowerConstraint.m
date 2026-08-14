classdef TestManeuveringExcessPowerConstraint < matlab.unittest.TestCase
%TESTMANEUVERINGEXCESSPOWERCONSTRAINT  Unit tests for the
%   ManeuveringExcessPowerConstraint class -- the Mattingly Master-Equation
%   specialization with BOTH n>1 and Ps>0 active (Both_WbyS_TbyW category).
%
%   Equation [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002 --
%   point-performance Master Equation; cf. metabook_data.md "Sustained
%   Maneuver/Turn Constraint" Eq. 4.33 and "Cruise Constraint" Eq. 4.34], as
%   MasterEquationConstraint.m implements it and this thin child widens:
%
%     T_SL/W_TO = A/(W/S) + B*(W/S) + C + D
%       A = q*CD0/alpha
%       B = (q/alpha) * K1 * (n*beta/q)^2
%       C = K2 * n*beta / alpha
%       D = (beta/alpha) * (Ps/V)
%
%   HAND-COMPUTED EXPECTED VALUE. The A/B/C/D terms are re-assembled inline in
%   the test from the SAME AircraftState q/V the class reads (state.q, state.V,
%   read directly off the constructed state -- documented below) and the clean
%   FixedConfigAeroStub polar (CD0=0.01597, K1=0.03815, K2=0), NOT by copying
%   the class's algebra. The test asserts required_TW(80) against that inline
%   assembly.
%
%   Chosen point: AircraftState(15000, 0.9), clean stub polar, alpha=1
%   (FixedConfigPropStub default thrust_lapse), beta=0.85, n=5, Ps=300 ft/s,
%   powerSetting="AB" (so get_alpha uses thrust_lapse = alpha = 1). With
%   K2=0 the C term vanishes; D=(beta/alpha)*(Ps/V) is nonzero because Ps>0;
%   B carries n=5 (n*beta/q)^2, so both the maneuvering (n) and excess-power
%   (Ps) contributions are exercised.
%
%   This class is INTENDED for n>1 AND Ps>0. Two comparison guards below
%   confirm it genuinely uses BOTH: its required_TW must differ from a
%   SustainedTurnConstraint (same n, Ps=0 -> no D term) and from an
%   ExcessPowerConstraint (n=1, same Ps -> lower B term) built on the same
%   state/stubs.

    properties (Constant)
        BETA = 0.85
        N    = 5
        PS   = 300     % ft/s
        WS   = 80      % lbf/ft^2
        % Clean stub polar [FixedConfigAeroStub default clean, metabook Ex 4.2].
        CD0  = 0.01597
        K1   = 0.03815
        K2   = 0
    end

    methods (Static, Access = private)

        function state = point()
            state = AircraftState(15000, 0.9);
        end

        function aero = cleanAero()
            aero = FixedConfigAeroStub();   % clean polar CD0=0.01597,K1=0.03815,K2=0
        end

        function prop = unitProp()
            prop = FixedConfigPropStub();   % alpha = 1
        end

    end

    methods (Test)

        function testIsaMasterEquationConstraint(tc)
            obj = ManeuveringExcessPowerConstraint("Maneuver", ...
                TestManeuveringExcessPowerConstraint.point(), ...
                TestManeuveringExcessPowerConstraint.cleanAero(), ...
                TestManeuveringExcessPowerConstraint.unitProp(), 0.85, 5, 300, "AB");
            tc.verifyTrue(isa(obj, 'MasterEquationConstraint'), ...
                'ManeuveringExcessPowerConstraint must be a MasterEquationConstraint.');
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'));
        end

        function testRequiredTWMatchesHandComputedABCD(tc)
            % Re-assemble A/B/C/D inline from the state's own q/V (read off the
            % constructed AircraftState, the same values the class uses) and
            % assert required_TW(80) against A/80 + B*80 + C + D.
            state = TestManeuveringExcessPowerConstraint.point();
            aero  = TestManeuveringExcessPowerConstraint.cleanAero();
            prop  = TestManeuveringExcessPowerConstraint.unitProp();

            beta  = TestManeuveringExcessPowerConstraint.BETA;
            n     = TestManeuveringExcessPowerConstraint.N;
            Ps    = TestManeuveringExcessPowerConstraint.PS;
            CD0   = TestManeuveringExcessPowerConstraint.CD0;
            K1    = TestManeuveringExcessPowerConstraint.K1;
            K2    = TestManeuveringExcessPowerConstraint.K2;
            WSv   = TestManeuveringExcessPowerConstraint.WS;

            q     = state.q;      % lbf/ft^2, read directly off the state
            V     = state.V;      % ft/s
            alpha = 1;            % FixedConfigPropStub default, powerSetting "AB"

            A = q * CD0 / alpha;
            B = (q / alpha) * K1 * (n * beta / q)^2;
            C = K2 * n * beta / alpha;                 % = 0 (K2 = 0)
            D = (beta / alpha) * (Ps / V);
            expected = A / WSv + B * WSv + C + D;

            obj = ManeuveringExcessPowerConstraint("Maneuver", state, aero, prop, ...
                beta, n, Ps, "AB");
            received = obj.required_TW(WSv);

            fprintf('\n    ManeuverExcessPower required_TW(80): received=%.9f  hand=%.9f  (q=%.4f V=%.4f)\n', ...
                received, expected, q, V);
            tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                'required_TW must equal the hand-assembled A/B/C/D Master Equation.');
        end

        function testUsesBothNAndPs(tc)
            % Confirm the class genuinely activates BOTH the elevated-n B term
            % AND the excess-power D term: its value must differ from a
            % SustainedTurn (same n, Ps=0 -> D dropped) and from an ExcessPower
            % (n=1, same Ps -> smaller B), all on the same state/stubs at the
            % same W/S.
            state = TestManeuveringExcessPowerConstraint.point();
            aero  = TestManeuveringExcessPowerConstraint.cleanAero();
            prop  = TestManeuveringExcessPowerConstraint.unitProp();
            beta  = TestManeuveringExcessPowerConstraint.BETA;
            n     = TestManeuveringExcessPowerConstraint.N;
            Ps    = TestManeuveringExcessPowerConstraint.PS;
            WSv   = TestManeuveringExcessPowerConstraint.WS;

            maneuver = ManeuveringExcessPowerConstraint("Maneuver", state, aero, prop, beta, n, Ps, "AB");
            turn     = SustainedTurnConstraint("Turn", state, aero, prop, beta, n, "AB");   % Ps=0
            excess   = ExcessPowerConstraint("Excess", state, aero, prop, beta, Ps, "AB");  % n=1

            tw_m = maneuver.required_TW(WSv);
            tw_t = turn.required_TW(WSv);
            tw_e = excess.required_TW(WSv);

            % D term (nonzero Ps) makes it exceed the Ps=0 sustained turn.
            tc.verifyGreaterThan(tw_m, tw_t, ...
                'Maneuvering value must exceed the Ps=0 sustained turn (D term active).');
            % Elevated-n B term makes it exceed the n=1 excess-power case.
            tc.verifyGreaterThan(tw_m, tw_e, ...
                'Maneuvering value must exceed the n=1 excess-power case (elevated B term).');
        end

        function testFromConditionMatchesDirectConstructor(tc)
            % fromCondition reads cond.name/altitude_ft/mach/beta/n/Ps_fps/
            % power_setting.
            cond = struct('name', 'Maneuver', 'altitude_ft', 15000, ...
                'mach', 0.9, 'beta', 0.85, 'n', 5, 'Ps_fps', 300, ...
                'power_setting', 'AB');
            aero = TestManeuveringExcessPowerConstraint.cleanAero();
            prop = TestManeuveringExcessPowerConstraint.unitProp();

            obj_fc = ManeuveringExcessPowerConstraint.fromCondition(cond, aero, prop);
            obj_dir = ManeuveringExcessPowerConstraint("Maneuver", ...
                TestManeuveringExcessPowerConstraint.point(), aero, prop, ...
                0.85, 5, 300, "AB");

            tc.verifyEqual(obj_fc.required_TW(80), obj_dir.required_TW(80), ...
                'RelTol', 1e-12, 'fromCondition must match the direct constructor.');
            tc.verifyEqual(obj_fc.name, "Maneuver");
        end

    end

end
