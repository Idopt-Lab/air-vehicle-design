classdef TestInstantaneousTurnConstraint < matlab.unittest.TestCase
%TESTINSTANTANEOUSTURNCONSTRAINT  Unit tests for the
%   InstantaneousTurnConstraint class -- the Aero 481 "vertical maneuver"
%   turn-rate-driven constraint (Both_WbyS_TbyW category).
%
%   Equation [Aero 481 student-code formulation, +Constraints/InstantaneousTurn.m,
%   with the two documented corrections in InstantaneousTurnConstraint.m's
%   PROVENANCE block -- g typo fix and thrust-lapse alpha added], as the class
%   implements it:
%
%     n   = omega * V / g              (omega = deg2rad(turn_rate_dps), V = state.V)
%     required_TW(W/S) = (1/alpha) * ( q*CD0 ./ (n*W/S) + n*K1 .* W/S / q )
%
%   with CD0/K1 the CLEAN drag polar (drag_polar(state)) and alpha the thrust
%   lapse (alpha=1 for the FixedConfigPropStub, powerSetting "AB").
%
%   HAND-COMPUTED EXPECTED VALUE. n and required_TW are re-derived inline in
%   the test from the SAME state.V/state.q the class reads (documented below),
%   NOT by copying the class's algebra. g = 32.174 ft/s^2 is the ENGLISH
%   standard gravity used by the class (correcting Aero 481's 9.087 typo for
%   9.807 m/s^2 -- see InstantaneousTurnConstraint.m PROVENANCE (a)).
%
%   Chosen point: AircraftState(35000, 1.6), clean stub polar
%   (CD0=0.01597, K1=0.03815), turn_rate = 18 deg/s, alpha = 1.
%     n = deg2rad(18) * state.V / 32.174        (computed from state.V)
%     required_TW(80) = (1/1) * ( q*CD0/(n*80) + n*K1*80/q )
%
%   CITATION NOTE. InstantaneousTurnConstraint carries a PROVISIONAL citation
%   (Aero 481 provenance + a reproduced derivation) plus a _TODO flagging that
%   a primary Raymer ch.5 source is the citation it should ultimately carry --
%   it is NOT an uncited equation. Per repo convention, deliberately-failing
%   testTODO_* tests are reserved for genuinely-MISSING citations; this class
%   HAS a citation, so no failing test is added here. testDocumentsProvisional
%   CitationAndAlternative records the provisional-citation / CLmax-wall-
%   alternative documentation as a plain (passing) correctness assertion.

    properties (Constant)
        TURN_RATE_DPS = 18       % deg/s
        CD0 = 0.01597            % clean stub polar [FixedConfigAeroStub default]
        K1  = 0.03815
        WS  = 80                 % lbf/ft^2
        G_FTS2 = 32.174          % ft/s^2 -- English standard gravity (class value)
    end

    methods (Static, Access = private)

        function state = point()
            state = AircraftState(35000, 1.6);
        end

        function aero = cleanAero()
            aero = FixedConfigAeroStub();
        end

        function prop = unitProp()
            prop = FixedConfigPropStub();   % alpha = 1
        end

    end

    methods (Test)

        function testIsaBothWbySTbyW(tc)
            obj = InstantaneousTurnConstraint("Inst Turn", ...
                TestInstantaneousTurnConstraint.point(), ...
                TestInstantaneousTurnConstraint.cleanAero(), ...
                TestInstantaneousTurnConstraint.unitProp(), 18, "AB");
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'), ...
                'InstantaneousTurnConstraint must be a Both_WbyS_TbyW.');
        end

        function testRequiredTWMatchesHandComputed(tc)
            % Re-derive n and required_TW(80) inline from the state's own q/V.
            state = TestInstantaneousTurnConstraint.point();
            aero  = TestInstantaneousTurnConstraint.cleanAero();
            prop  = TestInstantaneousTurnConstraint.unitProp();

            CD0 = TestInstantaneousTurnConstraint.CD0;
            K1  = TestInstantaneousTurnConstraint.K1;
            WSv = TestInstantaneousTurnConstraint.WS;
            g   = TestInstantaneousTurnConstraint.G_FTS2;

            q     = state.q;   % lbf/ft^2, read directly off the state
            V     = state.V;   % ft/s
            alpha = 1;

            n = deg2rad(TestInstantaneousTurnConstraint.TURN_RATE_DPS) * V / g;
            expected = (1/alpha) * ( q * CD0 / (n * WSv) + n * K1 * WSv / q );

            obj = InstantaneousTurnConstraint("Inst Turn", state, aero, prop, 18, "AB");
            received = obj.required_TW(WSv);

            fprintf('\n    InstTurn required_TW(80): received=%.9f  hand=%.9f  (n=%.4f q=%.4f V=%.4f)\n', ...
                received, expected, n, q, V);
            tc.verifyEqual(received, expected, 'RelTol', 1e-9, ...
                'required_TW must equal the hand-derived instantaneous-turn value.');
        end

        function testLoadFactorFromTurnRate(tc)
            % n = omega*V/g is set once in the constructor; verify it against
            % the hand-computed value from state.V and g = 32.174.
            state = TestInstantaneousTurnConstraint.point();
            obj = InstantaneousTurnConstraint("Inst Turn", state, ...
                TestInstantaneousTurnConstraint.cleanAero(), ...
                TestInstantaneousTurnConstraint.unitProp(), 18, "AB");
            expected_n = deg2rad(18) * state.V / TestInstantaneousTurnConstraint.G_FTS2;
            tc.verifyEqual(obj.n, expected_n, 'RelTol', 1e-12, ...
                'Load factor must be omega*V/g with English g = 32.174.');
        end

        function testConstraintResidualSignAndValue(tc)
            % Both_WbyS_TbyW.constraint_residual = required_TW(dp.WS) - dp.TW.
            state = TestInstantaneousTurnConstraint.point();
            obj = InstantaneousTurnConstraint("Inst Turn", state, ...
                TestInstantaneousTurnConstraint.cleanAero(), ...
                TestInstantaneousTurnConstraint.unitProp(), 18, "AB");

            W_TO   = 30000;
            S_ref  = W_TO / 80;              % dp.WS = 80
            TW_req = obj.required_TW(80);

            dp_feas   = DesignPoint(W_TO, 1.10 * TW_req * W_TO, S_ref);
            dp_infeas = DesignPoint(W_TO, 0.90 * TW_req * W_TO, S_ref);

            tc.verifyEqual(obj.constraint_residual(dp_feas), TW_req - dp_feas.TW, ...
                'RelTol', 1e-10, 'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyLessThan(obj.constraint_residual(dp_feas), 0, ...
                'More T/W available than required must be feasible (g < 0).');
            tc.verifyGreaterThan(obj.constraint_residual(dp_infeas), 0, ...
                'Less T/W available than required must be infeasible (g > 0).');
        end

        function testNonFiniteTermErrors(tc)
            % A NaN CD0 in the clean drag polar makes the A coefficient
            % non-finite; required_TW must error
            % 'InstantaneousTurnConstraint:nonFiniteTerm' rather than feed a NaN
            % curve into the aggregator. Supply a clean config with NaN CD0 (the
            % stub's drag_polar echoes the clean entry).
            nanMap = struct('clean', ...
                struct('CD0', NaN, 'K1', 0.03815, 'K2', 0, 'CLmax', 0.9));
            aero = FixedConfigAeroStub(nanMap);
            obj  = InstantaneousTurnConstraint("Inst Turn", ...
                TestInstantaneousTurnConstraint.point(), aero, ...
                TestInstantaneousTurnConstraint.unitProp(), 18, "AB");
            tc.verifyError(@() obj.required_TW(80), ...
                'InstantaneousTurnConstraint:nonFiniteTerm', ...
                'A non-finite drag polar must make required_TW error loudly.');
        end

        function testFromConditionMatchesDirectConstructor(tc)
            % fromCondition reads cond.name/altitude_ft/mach/turn_rate_dps/
            % power_setting.
            cond = struct('name', 'Inst Turn', 'altitude_ft', 35000, ...
                'mach', 1.6, 'turn_rate_dps', 18, 'power_setting', 'AB');
            aero = TestInstantaneousTurnConstraint.cleanAero();
            prop = TestInstantaneousTurnConstraint.unitProp();

            obj_fc  = InstantaneousTurnConstraint.fromCondition(cond, aero, prop);
            obj_dir = InstantaneousTurnConstraint("Inst Turn", ...
                TestInstantaneousTurnConstraint.point(), aero, prop, 18, "AB");

            tc.verifyEqual(obj_fc.required_TW(80), obj_dir.required_TW(80), ...
                'RelTol', 1e-12, 'fromCondition must match the direct constructor.');
            tc.verifyEqual(obj_fc.name, "Inst Turn");
        end

        function testDocumentsProvisionalCitationAndAlternative(tc)
            % The class carries a PROVISIONAL citation (not a missing one): the
            % Aero 481 provenance block, the reproduced derivation, the g-typo
            % correction, and the standard CLmax-limited W/S-wall ALTERNATIVE
            % form, plus a _TODO for the primary Raymer ch.5 source. Per repo
            % convention (testTODO_* is reserved for genuinely-MISSING
            % citations) this is a plain passing check that the documentation is
            % present -- NOT a deliberately-failing test.
            src = fileread(fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                'src', 'constraints', 'InstantaneousTurnConstraint.m'));
            tc.verifyTrue(contains(src, 'PROVENANCE'), ...
                'The class must document its Aero 481 provenance.');
            tc.verifyTrue(contains(src, '_TODO'), ...
                'The class must flag the pending primary Raymer ch.5 citation.');
            tc.verifyTrue(contains(src, 'ALTERNATIVE'), ...
                'The class must record the standard CLmax-limited W/S-wall alternative.');
        end

    end

end
