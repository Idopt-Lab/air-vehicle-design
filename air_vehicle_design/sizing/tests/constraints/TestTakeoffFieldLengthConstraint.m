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
%   HAND-COMPUTED EXPECTED VALUE (in the properties block below), independently
%   derived from Eqs. 4.15-4.16 with the metabook Example 4.2 inputs -- NOT a
%   copy of TakeoffFieldLengthConstraint's own algebra:
%
%     Inputs [Ex. 4.2]: BFL = 12,000 ft, sigma = 0.95, and
%       CLmax_TO = 2.0 -- the FixedConfigAeroStub default
%       takeoff_flaps_gear_down CLmax [metabook_data.md §4.11 config TABLE;
%       see FixedConfigAeroStub.m header discrepancy note D1].
%
%       TOP25 = 12000 / 37.5 = 320.0                              (Eq. 4.47)
%       denominator constant = sigma * CLmax_TO * TOP25
%                            = 0.95 * 2.0 * 320.0 = 608.0
%       required_TW(W/S) = (W/S) / 608.0
%
%       At W/S = 100:  required_TW = 100 / 608.0 = 0.16447368421...
%
%   The relation is LINEAR THROUGH THE ORIGIN in W/S, so
%   required_TW(200) = 2 * required_TW(100) exactly (Eq. 4.16 is a pure slope).
%
%   The stubs used here (FixedConfigAeroStub, FixedConfigPropStub) are the
%   deterministic per-config aero/prop stand-ins that ship the metabook
%   Example 4.2 polars -- see their class headers. This constraint takes no
%   prop object (the TOP correlation models takeoff thrust statistically), so
%   only the aero stub matters.

    properties (Constant)
        % Metabook Example 4.2 takeoff-field inputs [Eqs. 4.47-4.48].
        BFL_ft   = 12000    % [Ex. 4.2] required balanced-field length, ft
        SIGMA    = 0.95     % [Ex. 4.2] hot-day near-SL air-density ratio
        CLMAX_TO = 2.0      % [FixedConfigAeroStub default takeoff_flaps_gear_down]

        % Hand-computed required_TW at W/S = 100 [Eqs. 4.15-4.16, Ex. 4.2]:
        %   TOP25 = 12000/37.5 = 320; 100 / (0.95*2.0*320) = 100/608.
        WS_TEST            = 100
        EXPECTED_TW_AT_100 = 100 / (0.95 * 2.0 * 320.0)   % = 0.16447368421...
    end

    methods (Static, Access = private)

        function aero = defaultAero()
        %DEFAULTAERO  No-arg FixedConfigAeroStub (ships metabook Ex 4.2 polars).
            aero = FixedConfigAeroStub();
        end

    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaBothWbySTbyW(tc)
            obj = TakeoffFieldLengthConstraint("TOFL", ...
                TestTakeoffFieldLengthConstraint.defaultAero(), 12000, 0.95);
            tc.verifyTrue(isa(obj, 'Both_WbyS_TbyW'), ...
                'TakeoffFieldLengthConstraint must be a Both_WbyS_TbyW.');
        end

        function testNamePropertySet(tc)
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.defaultAero(), 12000, 0.95);
            tc.verifyEqual(obj.name, "Takeoff Field Length");
        end

        % --- Hand-computed equation (metabook Ex 4.2) ----------------------

        function testRequiredTWMatchesHandComputed(tc)
            % required_TW(100) must equal the independently hand-computed
            % Eq. 4.15-4.16 value 100/608 = 0.16447368421... [Ex. 4.2].
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft, ...
                TestTakeoffFieldLengthConstraint.SIGMA);

            received = obj.required_TW(TestTakeoffFieldLengthConstraint.WS_TEST);
            expected = TestTakeoffFieldLengthConstraint.EXPECTED_TW_AT_100;

            fprintf('\n    TOFL required_TW(W/S=100): received=%.9f  hand=%.9f\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'required_TW must equal the hand-computed Eq. 4.15-4.16 value.');
        end

        function testRequiredTWLinearThroughOrigin(tc)
            % Eq. 4.16 is a pure slope (linear through the origin): doubling
            % W/S must double required_TW exactly. required_TW(200) ==
            % 2*required_TW(100).
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft, ...
                TestTakeoffFieldLengthConstraint.SIGMA);

            tw_100 = obj.required_TW(100);
            tw_200 = obj.required_TW(200);
            tc.verifyEqual(tw_200, 2 * tw_100, 'RelTol', 1e-12, ...
                'required_TW must be linear through the origin (Eq. 4.16 slope).');
        end

        function testSigmaDefaultsToOne(tc)
            % sigma defaults to 1.0 when omitted (ISA sea-level basis).
            obj = TakeoffFieldLengthConstraint("TOFL", ...
                TestTakeoffFieldLengthConstraint.defaultAero(), 12000);
            % With sigma=1, denominator = 1.0*2.0*320 = 640, so
            % required_TW(100) = 100/640 = 0.15625.
            tc.verifyEqual(obj.required_TW(100), 100 / (1.0 * 2.0 * 320.0), ...
                'AbsTol', 1e-9, 'sigma must default to 1.0 when omitted.');
        end

        % --- Feasibility residual (Both_WbyS_TbyW) -------------------------

        function testConstraintResidualSignAndValue(tc)
            % Both_WbyS_TbyW.constraint_residual = required_TW(dp.WS) - dp.TW.
            % g <= 0 feasible. Build a DesignPoint at W/S=100 and straddle the
            % required T/W with a feasible and an infeasible thrust.
            obj = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                TestTakeoffFieldLengthConstraint.defaultAero(), ...
                TestTakeoffFieldLengthConstraint.BFL_ft, ...
                TestTakeoffFieldLengthConstraint.SIGMA);

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
            % fromCondition(cond, aero, prop) reads cond.name/BFL_ft/sigma and
            % must match the direct constructor exactly. prop is accepted but
            % ignored (TOP correlation needs no propulsion object).
            cond = struct('name', 'Takeoff Field Length', ...
                'BFL_ft', 12000, 'sigma', 0.95);
            aero = TestTakeoffFieldLengthConstraint.defaultAero();

            obj_fc  = TakeoffFieldLengthConstraint.fromCondition(cond, aero, []);
            obj_dir = TakeoffFieldLengthConstraint("Takeoff Field Length", ...
                aero, 12000, 0.95);

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
                aero, 12000, 0.95);

            tc.verifyError(@() obj.required_TW(100), ...
                'TakeoffFieldLengthConstraint:nonFiniteTerm', ...
                'A non-finite Takeoff-Parameter slope must error loudly.');
        end

    end

end
