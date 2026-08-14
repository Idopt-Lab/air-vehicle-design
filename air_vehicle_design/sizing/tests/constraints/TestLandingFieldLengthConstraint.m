classdef TestLandingFieldLengthConstraint < matlab.unittest.TestCase
%TESTLANDINGFIELDLENGTHCONSTRAINT  Unit tests for the generic
%   LandingFieldLengthConstraint class (FAR-25 statistical field-length
%   correlation, upper bound on wing loading, Only_WbyS category).
%
%   Equation [Metabook (Aero 481 metabook), metabook_data.md "§4.6 Landing
%   Field Length," Eqs. 4.19/4.45; worked Example 4.2, Eq. 4.46], as
%   LandingFieldLengthConstraint.m implements it:
%
%     W/S <= sigma * CLmax_L / 80
%              * (S_runway * runway_factor - Sa) / weight_ratio    (Eq. 4.45/4.46)
%
%   HAND-COMPUTED EXPECTED VALUE (in the properties block below), independently
%   derived from Eq. 4.45/4.46 with the metabook Example 4.2 inputs -- NOT a
%   copy of LandingFieldLengthConstraint's own algebra:
%
%     Inputs [Ex. 4.2]: sigma = 0.95, S_runway = 12,000 ft, runway_factor = 0.6,
%       Sa = 1,000 ft, weight_ratio = 0.65, and
%       CLmax_L = 2.6 -- the FixedConfigAeroStub default landing_flaps_gear_down
%       CLmax [metabook_data.md §4.11 config TABLE].
%
%       available_field = S_runway*runway_factor - Sa
%                       = 12000*0.6 - 1000 = 7200 - 1000 = 6200 ft
%       WS_max = sigma * CLmax_L / 80 * available_field / weight_ratio
%              = 0.95 * 2.6 / 80 * 6200 / 0.65
%              = (2.47 / 80) * 6200 / 0.65
%              = 0.0308750 * 6200 / 0.65
%              = 191.425 / 0.65
%              = 294.5 lbf/ft^2   (exactly 294.5)
%
%   Cross-check against the class header's own Eq. 4.46 shorthand
%   (WS = 113.27 * CLmax): 113.27 * 2.6 = 294.502 -- agrees to rounding of the
%   113.27 coefficient (0.95/(80*0.65) * 6200 = 113.2692...).
%
%   The stub used here (FixedConfigAeroStub, no-arg) ships the metabook
%   Example 4.2 polars -- see its class header. This constraint is Only_WbyS
%   and takes no prop object.

    properties (Constant)
        % Metabook Example 4.2 landing-field inputs [Eq. 4.46].
        SIGMA         = 0.95    % [Ex. 4.2] hot-day near-SL air-density ratio
        S_RUNWAY_FT   = 12000   % [Ex. 4.2] available runway length, ft
        RUNWAY_FACTOR = 0.6     % [Ex. 4.2] FAR landing-field multiple (0.6 = 1/1.67)
        SA_FT         = 1000    % [Ex. 4.2] obstacle-clearance approach distance, ft
        WEIGHT_RATIO  = 0.65    % [Ex. 4.2] MLW/MTOW
        CLMAX_L       = 2.6     % [FixedConfigAeroStub default landing_flaps_gear_down]

        % Hand-computed WS_max [Eq. 4.45/4.46, Ex. 4.2]:
        %   0.95*2.6/80 * (12000*0.6 - 1000)/0.65 = 294.5 lbf/ft^2.
        EXPECTED_WS_MAX = 0.95 * 2.6 / 80 * (12000 * 0.6 - 1000) / 0.65
    end

    methods (Static, Access = private)

        function aero = defaultAero()
        %DEFAULTAERO  No-arg FixedConfigAeroStub (ships metabook Ex 4.2 polars).
            aero = FixedConfigAeroStub();
        end

        function obj = defaultConstraint()
        %DEFAULTCONSTRAINT  The metabook Example 4.2 landing-field constraint.
            obj = LandingFieldLengthConstraint("Landing Field Length", ...
                TestLandingFieldLengthConstraint.defaultAero(), ...
                TestLandingFieldLengthConstraint.S_RUNWAY_FT, ...
                TestLandingFieldLengthConstraint.SA_FT, ...
                TestLandingFieldLengthConstraint.WEIGHT_RATIO, ...
                TestLandingFieldLengthConstraint.SIGMA, ...
                TestLandingFieldLengthConstraint.RUNWAY_FACTOR);
        end

    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaOnlyWbyS(tc)
            obj = TestLandingFieldLengthConstraint.defaultConstraint();
            tc.verifyTrue(isa(obj, 'Only_WbyS'), ...
                'LandingFieldLengthConstraint must be an Only_WbyS.');
        end

        function testNamePropertySet(tc)
            obj = TestLandingFieldLengthConstraint.defaultConstraint();
            tc.verifyEqual(obj.name, "Landing Field Length");
        end

        % --- Hand-computed equation (metabook Ex 4.2) ----------------------

        function testWSMaxMatchesHandComputed(tc)
            % WS_max must equal the independently hand-computed Eq. 4.45/4.46
            % value 294.5 lbf/ft^2 [Ex. 4.2].
            obj = TestLandingFieldLengthConstraint.defaultConstraint();

            received = obj.WS_max();
            expected = TestLandingFieldLengthConstraint.EXPECTED_WS_MAX;

            fprintf('\n    LFL WS_max: received=%.4f  hand=%.4f\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-3, ...
                'WS_max must equal the hand-computed Eq. 4.45/4.46 value (294.5).');
        end

        % --- Defaults -------------------------------------------------------

        function testRunwayFactorDefaultsToPointSix(tc)
            % runway_factor defaults to 0.6 when omitted (FAR 1/1.67 multiple).
            % weight_ratio and sigma default to 1.0; supply them explicitly so
            % only runway_factor is defaulted here.
            obj = LandingFieldLengthConstraint("LFL", ...
                TestLandingFieldLengthConstraint.defaultAero(), ...
                12000, 1000, 0.65, 0.95);
            % Same inputs as the hand-computed case, runway_factor defaulted to
            % 0.6 -> the same 294.5 result.
            tc.verifyEqual(obj.WS_max(), ...
                TestLandingFieldLengthConstraint.EXPECTED_WS_MAX, 'AbsTol', 1e-3, ...
                'runway_factor must default to 0.6.');
        end

        function testWeightRatioAndSigmaDefaultToOne(tc)
            % weight_ratio and sigma both default to 1.0 when omitted.
            % WS_max = 1.0*2.6/80 * (12000*0.6 - 1000)/1.0 = 2.6/80*6200 = 201.5.
            obj = LandingFieldLengthConstraint("LFL", ...
                TestLandingFieldLengthConstraint.defaultAero(), 12000, 1000);
            expected = 1.0 * 2.6 / 80 * (12000 * 0.6 - 1000) / 1.0;
            tc.verifyEqual(obj.WS_max(), expected, 'AbsTol', 1e-3, ...
                'weight_ratio and sigma must default to 1.0.');
        end

        % --- Feasibility residual (Only_WbyS) ------------------------------

        function testConstraintResidualSignAndValue(tc)
            % Only_WbyS.constraint_residual = dp.WS - WS_max(); g <= 0 feasible,
            % dp.TW unused. Straddle the wall with a feasible/infeasible dp.WS.
            obj = TestLandingFieldLengthConstraint.defaultConstraint();
            WS_limit = obj.WS_max();
            S_ref    = 350;

            dp_feas   = DesignPoint(0.5 * WS_limit * S_ref, 20000, S_ref);
            g_feas    = obj.constraint_residual(dp_feas);
            dp_infeas = DesignPoint(1.5 * WS_limit * S_ref, 20000, S_ref);
            g_infeas  = obj.constraint_residual(dp_infeas);

            tc.verifyEqual(g_feas, dp_feas.WS - WS_limit, 'RelTol', 1e-10, ...
                'constraint_residual must equal dp.WS - WS_max().');
            tc.verifyLessThan(g_feas, 0, ...
                'A design below the landing W/S wall must be feasible (g < 0).');
            tc.verifyEqual(g_infeas, dp_infeas.WS - WS_limit, 'RelTol', 1e-10, ...
                'constraint_residual must equal dp.WS - WS_max().');
            tc.verifyGreaterThan(g_infeas, 0, ...
                'A design above the landing W/S wall must be infeasible (g > 0).');
        end

        % --- fromCondition factory -----------------------------------------

        function testFromConditionMatchesDirectConstructor(tc)
            % fromCondition reads cond.name/runway_ft/Sa_ft/weight_ratio/sigma
            % and the optional cond.runway_factor.
            cond = struct('name', 'Landing Field Length', ...
                'runway_ft', 12000, 'Sa_ft', 1000, 'weight_ratio', 0.65, ...
                'sigma', 0.95, 'runway_factor', 0.6);
            aero = TestLandingFieldLengthConstraint.defaultAero();

            obj_fc  = LandingFieldLengthConstraint.fromCondition(cond, aero, []);
            obj_dir = TestLandingFieldLengthConstraint.defaultConstraint();

            tc.verifyEqual(obj_fc.WS_max(), obj_dir.WS_max(), 'AbsTol', 1e-9, ...
                'fromCondition must match the direct-constructor result.');
            tc.verifyEqual(obj_fc.name, "Landing Field Length");
        end

        function testFromConditionDefaultsRunwayFactorWhenAbsent(tc)
            % When cond has no runway_factor field, fromCondition uses the
            % constructor default (0.6).
            cond = struct('name', 'Landing Field Length', ...
                'runway_ft', 12000, 'Sa_ft', 1000, 'weight_ratio', 0.65, ...
                'sigma', 0.95);
            aero = TestLandingFieldLengthConstraint.defaultAero();

            obj_fc = LandingFieldLengthConstraint.fromCondition(cond, aero, []);
            tc.verifyEqual(obj_fc.WS_max(), ...
                TestLandingFieldLengthConstraint.EXPECTED_WS_MAX, 'AbsTol', 1e-3, ...
                'fromCondition must default runway_factor to 0.6 when absent.');
        end

    end

end
