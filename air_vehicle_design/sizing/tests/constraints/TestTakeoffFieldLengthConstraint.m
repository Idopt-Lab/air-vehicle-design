classdef TestTakeoffFieldLengthConstraint < matlab.unittest.TestCase
%TESTTAKEOFFFIELDLENGTHCONSTRAINT  Unit tests for the generic
%   TakeoffFieldLengthConstraint class (FAR-25 Takeoff-Parameter / TOP25
%   field-length correlation, Both_WbyS_TbyW category).
%
%   Equation [Metabook (Aero 481 metabook), metabook_data.md "§4.5 Takeoff
%   Field Length," Eqs. 4.15-4.16; worked Example 4.2, Eqs. 4.47-4.48], as
%   TakeoffFieldLengthConstraint.m implements it:
%
%     TOP25       = BFL / 37.5                                    (Eq. 4.15)
%     T_SL/W_TO   = (W/S) / (sigma * CLmax_TO * TOP25)            (Eq. 4.16)
%
%   sigma = rho/rho_SL is DERIVED FROM THE STATE the constraint is built with
%   (not a separate input): the takeoff-field density ratio is exactly what the
%   AircraftState carries. A sea-level state gives sigma = 1.0; the metabook's
%   hot-day sigma = 0.95 is represented as the matching DENSITY ALTITUDE
%   (AircraftState(1742.4 ft) has sigma = 0.95000).
%
%   HAND-COMPUTED EXPECTED VALUES, independently derived from Eqs. 4.15-4.16
%   with the metabook Example 4.2 CLmax and BFL -- NOT a copy of the
%   constraint's own algebra:
%
%     CLmax_TO = 2.0 -- the FixedConfigAeroStub default takeoff_flaps_gear_down
%       CLmax [metabook_data.md §4.11 config TABLE; see FixedConfigAeroStub.m
%       header discrepancy note D1]. BFL = 12,000 ft => TOP25 = 320.0 (Eq. 4.47).
%
%     Sea level (sigma = 1.0):   required_TW(100) = 100 / (1.0*2.0*320) = 0.15625
%     Hot day (sigma = 0.95):    required_TW(100) = 100 / (0.95*2.0*320) = 100/608
%
%   The relation is LINEAR THROUGH THE ORIGIN in W/S, so
%   required_TW(200) = 2 * required_TW(100) exactly (Eq. 4.16 is a pure slope).
%
%   The stub used here (FixedConfigAeroStub) is the deterministic per-config
%   aero stand-in that ships the metabook Example 4.2 polars -- see its class
%   header. This constraint takes no prop object (the TOP correlation models
%   takeoff thrust statistically), so only the aero stub matters.

    properties (Constant)
        BFL_ft   = 12000    % [Ex. 4.2] required balanced-field length, ft
        CLMAX_TO = 2.0      % [FixedConfigAeroStub default takeoff_flaps_gear_down]
        HOT_DAY_ALT_FT = 1742.4   % density altitude giving sigma = 0.95000 [Ex. 4.2 hot day]

        WS_TEST              = 100
        EXPECTED_TW_SL       = 100 / (1.0  * 2.0 * 320.0)   % sigma=1.0  -> 0.15625
        EXPECTED_TW_HOTDAY   = 100 / (0.95 * 2.0 * 320.0)   % sigma=0.95 -> 100/608
    end

    methods (Static, Access = private)

        function aero = defaultAero()
        %DEFAULTAERO  No-arg FixedConfigAeroStub (ships metabook Ex 4.2 polars).
            aero = FixedConfigAeroStub();
        end

        function state = slState()
        %SLSTATE  Sea-level takeoff condition (sigma = 1.0).
            state = AircraftState(0, 0.2);
        end

        function state = hotDayState()
        %HOTDAYSTATE  Density altitude reproducing the Ex 4.2 hot day (sigma=0.95).
            state = AircraftState(TestTakeoffFieldLengthConstraint.HOT_DAY_ALT_FT, 0.2);
        end

    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaBothWbySTbyW(tc)
            obj = TakeoffFieldLengthConstraint("TOFL", ...
                TestTakeoffFieldLengthConstraint.slState(), ...
                TestTakeoffFieldLengthConstraint.defaultAero(), 12000);
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'), ...
                'TakeoffFieldLengthConstraint must be a Both_WbyS_TbyW.');
        end

        function testNamePropertySet(tc)
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.slState(), ...
                TestTakeoffFieldLengthConstraint.defaultAero(), 12000);
            tc.verifyEqual(obj.name, "Takeoff Field Length");
        end

        % --- Hand-computed equation, sea level (sigma = 1.0) ---------------

        function testRequiredTWSeaLevel(tc)
            % A sea-level state has sigma = 1.0, so required_TW(100) must equal
            % the hand-computed 100/(1.0*2.0*320) = 0.15625 [Eqs. 4.15-4.16].
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.slState(), ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft);

            received = obj.required_TW(TestTakeoffFieldLengthConstraint.WS_TEST);
            expected = TestTakeoffFieldLengthConstraint.EXPECTED_TW_SL;
            fprintf('\n    TOFL required_TW(W/S=100) sea level: received=%.9f  hand=%.9f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'required_TW at sigma=1.0 must equal the hand-computed value.');
        end

        % --- Hot-day density-altitude (sigma ~ 0.95) -----------------------

        function testSigmaFromHotDayState(tc)
            % The hot-day density altitude must reproduce sigma = 0.95, and
            % required_TW(100) must then match 100/(0.95*2.0*320) = 100/608.
            state = TestTakeoffFieldLengthConstraint.hotDayState();
            sigma = state.rho / AircraftState(0, 0.2).rho;
            tc.verifyEqual(sigma, 0.95, 'RelTol', 1e-3, ...
                'The 1742.4 ft density altitude must give sigma ~ 0.95 (Ex 4.2 hot day).');

            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", state, ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft);
            received = obj.required_TW(100);
            expected = TestTakeoffFieldLengthConstraint.EXPECTED_TW_HOTDAY;
            fprintf('    TOFL required_TW(W/S=100) hot day: received=%.9f  hand=%.9f  (sigma=%.6f)\n', ...
                received, expected, sigma);
            tc.verifyEqual(received, expected, 'RelTol', 1e-3, ...
                'required_TW at the hot-day density altitude must match 100/608.');
        end

        function testRequiredTWLinearThroughOrigin(tc)
            % Eq. 4.16 is a pure slope (linear through the origin): doubling
            % W/S must double required_TW exactly.
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.slState(), ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft);

            tw_100 = obj.required_TW(100);
            tw_200 = obj.required_TW(200);
            tc.verifyEqual(tw_200, 2 * tw_100, 'RelTol', 1e-12, ...
                'required_TW must be linear through the origin (Eq. 4.16 slope).');
        end

        % --- Feasibility residual (Both_WbyS_TbyW) -------------------------

        function testConstraintResidualSignAndValue(tc)
            % Both_WbyS_TbyW.constraint_residual = required_TW(dp.WS) - dp.TW.
            % g <= 0 feasible. Build a DesignPoint at W/S=100 and straddle the
            % required T/W with a feasible and an infeasible thrust.
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.slState(), ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft);

            W_TO   = 30000;
            S_ref  = W_TO / 100;               % dp.WS = 100 lbf/ft^2
            TW_req = obj.required_TW(100);

            dp_feas   = DesignPoint(W_TO, 1.10 * TW_req * W_TO, S_ref);
            g_feas    = obj.constraint_residual(dp_feas);
            dp_infeas = DesignPoint(W_TO, 0.90 * TW_req * W_TO, S_ref);
            g_infeas  = obj.constraint_residual(dp_infeas);

            tc.verifyEqual(g_feas, TW_req - dp_feas.TW, 'RelTol', 1e-10, ...
                'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyLessThan(g_feas, 0, ...
                'More T/W available than required must be feasible (g < 0).');
            tc.verifyEqual(g_infeas, TW_req - dp_infeas.TW, 'RelTol', 1e-10, ...
                'constraint_residual must equal required_TW(dp.WS) - dp.TW.');
            tc.verifyGreaterThan(g_infeas, 0, ...
                'Less T/W available than required must be infeasible (g > 0).');
        end

        % --- fromCondition factory -----------------------------------------

        function testFromConditionMatchesDirectConstructor(tc)
            % fromCondition(cond, aero, prop) reads cond.name/BFL_ft/altitude_ft
            % (sigma derived from that state) and must match the direct
            % constructor. prop is accepted but ignored.
            cond = struct('name', 'Takeoff Field Length', ...
                'BFL_ft', 12000, 'altitude_ft', 1742.4);
            aero = TestTakeoffFieldLengthConstraint.defaultAero();

            obj_fc  = TakeoffFieldLengthConstraint.fromCondition(cond, aero, []);
            obj_dir = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                AircraftState(1742.4, 0.2), aero, 12000);

            tc.verifyEqual(obj_fc.required_TW(100), obj_dir.required_TW(100), ...
                'AbsTol', 1e-12, ...
                'fromCondition must match the direct-constructor result.');
            tc.verifyEqual(obj_fc.name, "Takeoff Field Length");
        end

        % --- Non-finite guard ----------------------------------------------

        function testNonFiniteTermErrors(tc)
            % A zero CLmax_TO makes the Eq. 4.16 slope 1/(sigma*0*TOP25) = Inf,
            % so required_TW is non-finite and must error loudly rather than
            % feeding a NaN/Inf curve into the aggregator. Supply a PARTIAL
            % config map carrying only the config this constraint touches
            % (takeoff_flaps_gear_down) with CLmax = 0.
            badMap = struct('takeoff_flaps_gear_down', ...
                struct('CD0', 0.06097, 'K1', 0.04054, 'K2', 0, 'CLmax', 0));
            aero = FixedConfigAeroStub(badMap);
            obj  = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.slState(), aero, 12000);

            tc.verifyError(@() obj.required_TW(100), ...
                'TakeoffFieldLengthConstraint:nonFiniteTerm', ...
                'A non-finite Takeoff-Parameter slope must error loudly.');
        end

    end

end
