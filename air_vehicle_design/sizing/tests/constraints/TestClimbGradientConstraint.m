classdef TestClimbGradientConstraint < matlab.unittest.TestCase
%TESTCLIMBGRADIENTCONSTRAINT  Unit tests for the generic
%   ClimbGradientConstraint class (FAR-25 climb-gradient T/W floor,
%   Only_TbyW category).
%
%   Equation [Metabook (Aero 481 metabook), metabook_data.md "§4.7 Climb,"
%   Eq. 4.24 with the Eq. 4.25 correction factors; worked Example 4.2,
%   Eqs. 4.49-4.54], as ClimbGradientConstraint.m implements it:
%
%     tw_climb = ks^2/CLmax * CD0 + CLmax/ks^2 * K1 + G              (Eq. 4.24)
%     TW_min   = f_hot * f_mcont * f_oei * weight_ratio * tw_climb   (Eq. 4.25)
%       f_hot   = 1/0.8   if hot_day        else 1
%       f_mcont = 1/0.94  if max_continuous else 1
%       f_oei   = N/(N-1) if oei            else 1   (N = prop.n_engines)
%   (K-convention: the metabook's induced factor 1/(pi*AR*e) IS this repo's K1.)
%
%   HAND-COMPUTED EXPECTED VALUES (properties block below), independently
%   derived from Eqs. 4.24-4.25 for each of the six metabook Example 4.2 climb
%   segments (Eqs. 4.49-4.54, p.46) -- NOT a copy of ClimbGradientConstraint's
%   own algebra. Every case uses TWO engines (N=2 -> f_oei = 2/1 = 2 when oei),
%   and CLmax is the PRINTED per-climb value from the climb EQUATIONS (2.2 for
%   the takeoff-flap climbs), NOT the config-table 2.0/2.6 -- see
%   FixedConfigAeroStub.m discrepancy note D1. Each test builds a
%   FixedConfigAeroStub with a CUSTOM config map carrying that climb's printed
%   CLmax (and CD0/K1) so CLmax is read off the stub's config polar.
%
%   Climb 1 [Eq. 4.49]  takeoff_flaps_gear_up, CD0=0.03597, K1=0.04054,
%     CLmax=2.2; G=0.012, ks=1.2; oei+hot (2 eng), wr=1.0:
%       (1/0.8)(2/1)( 1.2^2/2.2*0.03597 + 2.2/1.2^2*0.04054 + 0.012 )
%       = 0.243700  (coordinator-confirmed)
%   Climb 2 [Eq. 4.50]  takeoff_flaps_gear_down, CD0=0.06097, K1=0.04054,
%     CLmax=2.2; G=0.0, ks=1.15; oei+hot, wr=1.0:
%       (1/0.8)(2/1)( 1.15^2/2.2*0.06097 + 2.2/1.15^2*0.04054 + 0.0 )
%   Climb 3 [Eq. 4.51]  takeoff_flaps_gear_up, CD0=0.03597, K1=0.04054,
%     CLmax=2.2; G=0.024, ks=1.2; oei+hot, wr=1.0:
%       (1/0.8)(2/1)( 1.2^2/2.2*0.03597 + 2.2/1.2^2*0.04054 + 0.024 )
%   Climb 4 [Eq. 4.52]  clean, CD0=0.01597, K1=0.03815, CLmax=0.9;
%     G=0.012, ks=1.25; oei+hot+max_continuous, wr=1.0:
%       (1/0.8)(1/0.94)(2/1)( 1.25^2/0.9*0.01597 + 0.9/1.25^2*0.03815 + 0.012 )
%   Climb 5 [Eq. 4.53]  landing_flaps_gear_down, CD0=0.11597, K1=0.04324,
%     CLmax=2.6; G=0.032, ks=1.3; hot only (AEO, oei=FALSE), wr=0.65:
%       (1/0.8)(0.65/1)( 1.3^2/2.6*0.11597 + 2.6/1.3^2*0.04324 + 0.032 )
%     NOTE: no OEI factor (all-engines-operating balked landing).
%   Climb 6 [Eq. 4.54]  approach, CD0=0.08847, K1=0.04324, CLmax=0.85*2.6=2.21;
%     G=0.021, ks=1.5; oei+hot, wr=0.65:
%       (1/0.8)(2/1)(0.65/1)( 1.5^2/(0.85*2.6)*0.08847 + (0.85*2.6)/1.5^2*0.04324 + 0.021 )
%
%   The stubs are FixedConfigAeroStub (custom per-climb config map) and
%   FixedConfigPropStub (settable n_engines, default 2). The plain
%   FixedPropStub -- which has NO n_engines property -- is used to exercise the
%   missing-n_engines error path.

    properties (Constant)
        % --- Hand-computed TW_min per climb [Eqs. 4.49-4.54, Ex. 4.2] ------
        % Each expression is the independently-assembled Eq. 4.24/4.25 value;
        % f_oei = 2/1 for the two-engine OEI climbs, weight_ratio applied last.
        EXP_CLIMB1 = (1/0.8) * (2/1) * (1.2^2/2.2*0.03597 + 2.2/1.2^2*0.04054 + 0.012)
        EXP_CLIMB2 = (1/0.8) * (2/1) * (1.15^2/2.2*0.06097 + 2.2/1.15^2*0.04054 + 0.0)
        EXP_CLIMB3 = (1/0.8) * (2/1) * (1.2^2/2.2*0.03597 + 2.2/1.2^2*0.04054 + 0.024)
        EXP_CLIMB4 = (1/0.8) * (1/0.94) * (2/1) * (1.25^2/0.9*0.01597 + 0.9/1.25^2*0.03815 + 0.012)
        EXP_CLIMB5 = (1/0.8) * (0.65/1) * (1.3^2/2.6*0.11597 + 2.6/1.3^2*0.04324 + 0.032)
        EXP_CLIMB6 = (1/0.8) * (2/1) * (0.65/1) * (1.5^2/(0.85*2.6)*0.08847 + (0.85*2.6)/1.5^2*0.04324 + 0.021)
    end

    methods (Static, Access = private)

        function aero = climbAero(config, CD0, K1, CLmax)
        %CLIMBAERO  FixedConfigAeroStub carrying ONE climb's config polar with
        %   its PRINTED CLmax (a partial config map -- only the config this
        %   climb touches).
            m = struct(char(config), struct('CD0', CD0, 'K1', K1, 'K2', 0, 'CLmax', CLmax));
            aero = FixedConfigAeroStub(m);
        end

        function prop = twinProp()
        %TWINPROP  Two-engine FixedConfigPropStub (default n_engines = 2).
            prop = FixedConfigPropStub();
        end

    end

    methods (Test)

        % --- Interface / inheritance --------------------------------------

        function testIsaOnlyTbyW(tc)
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_up", 0.03597, 0.04054, 2.2);
            obj  = ClimbGradientConstraint("Climb 1", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.012, 1.2, ...
                "takeoff_flaps_gear_up", 'oei', true, 'hot_day', true);
            tc.verifyTrue(isa(obj, 'Only_TbyW'), ...
                'ClimbGradientConstraint must be an Only_TbyW.');
        end

        % --- Hand-computed climb equations (metabook Ex 4.2, Eqs 4.49-4.54) -

        function testClimb1_Eq449(tc)
            % Climb 1 [Eq. 4.49]: TO flaps gear up, OEI, hot day, 2 engines.
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_up", 0.03597, 0.04054, 2.2);
            obj  = ClimbGradientConstraint("Climb 1", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.012, 1.2, ...
                "takeoff_flaps_gear_up", 'oei', true, 'hot_day', true, ...
                'max_continuous', false, 'weight_ratio', 1.0);
            received = obj.TW_min();
            fprintf('\n    Climb 1 TW_min: received=%.6f  hand=%.6f\n', ...
                received, TestClimbGradientConstraint.EXP_CLIMB1);
            tc.verifyEqual(received, TestClimbGradientConstraint.EXP_CLIMB1, ...
                'AbsTol', 1e-5, 'Climb 1 must reproduce Eq. 4.49 (0.243700).');
        end

        function testClimb2_Eq450(tc)
            % Climb 2 [Eq. 4.50]: TO flaps gear down, OEI, hot day, G=0.
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_down", 0.06097, 0.04054, 2.2);
            obj  = ClimbGradientConstraint("Climb 2", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.0, 1.15, ...
                "takeoff_flaps_gear_down", 'oei', true, 'hot_day', true, ...
                'weight_ratio', 1.0);
            tc.verifyEqual(obj.TW_min(), TestClimbGradientConstraint.EXP_CLIMB2, ...
                'AbsTol', 1e-5, 'Climb 2 must reproduce Eq. 4.50.');
        end

        function testClimb3_Eq451(tc)
            % Climb 3 [Eq. 4.51]: TO flaps gear up, OEI, hot day, G=0.024.
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_up", 0.03597, 0.04054, 2.2);
            obj  = ClimbGradientConstraint("Climb 3", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.024, 1.2, ...
                "takeoff_flaps_gear_up", 'oei', true, 'hot_day', true, ...
                'weight_ratio', 1.0);
            tc.verifyEqual(obj.TW_min(), TestClimbGradientConstraint.EXP_CLIMB3, ...
                'AbsTol', 1e-5, 'Climb 3 must reproduce Eq. 4.51.');
        end

        function testClimb4_Eq452(tc)
            % Climb 4 [Eq. 4.52]: clean, OEI, hot, max_continuous ALL true.
            aero = TestClimbGradientConstraint.climbAero("clean", 0.01597, 0.03815, 0.9);
            obj  = ClimbGradientConstraint("Climb 4", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.012, 1.25, ...
                "clean", 'oei', true, 'hot_day', true, 'max_continuous', true, ...
                'weight_ratio', 1.0);
            tc.verifyEqual(obj.TW_min(), TestClimbGradientConstraint.EXP_CLIMB4, ...
                'AbsTol', 1e-5, 'Climb 4 must reproduce Eq. 4.52 (with 1/0.94).');
        end

        function testClimb5_Eq453(tc)
            % Climb 5 [Eq. 4.53]: landing flaps gear down, AEO (oei FALSE),
            % hot day, weight_ratio 0.65. NO OEI factor.
            aero = TestClimbGradientConstraint.climbAero("landing_flaps_gear_down", 0.11597, 0.04324, 2.6);
            obj  = ClimbGradientConstraint("Climb 5", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.032, 1.3, ...
                "landing_flaps_gear_down", 'oei', false, 'hot_day', true, ...
                'weight_ratio', 0.65);
            tc.verifyEqual(obj.TW_min(), TestClimbGradientConstraint.EXP_CLIMB5, ...
                'AbsTol', 1e-5, 'Climb 5 must reproduce Eq. 4.53 (no OEI factor).');
        end

        function testClimb6_Eq454(tc)
            % Climb 6 [Eq. 4.54]: approach, CLmax=0.85*2.6=2.21, OEI, hot,
            % weight_ratio 0.65.
            aero = TestClimbGradientConstraint.climbAero("approach", 0.08847, 0.04324, 0.85*2.6);
            obj  = ClimbGradientConstraint("Climb 6", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.021, 1.5, ...
                "approach", 'oei', true, 'hot_day', true, 'weight_ratio', 0.65);
            tc.verifyEqual(obj.TW_min(), TestClimbGradientConstraint.EXP_CLIMB6, ...
                'AbsTol', 1e-5, 'Climb 6 must reproduce Eq. 4.54.');
        end

        % --- Only_TbyW: required_TW is W/S-independent ---------------------

        function testRequiredTWIsFlatAcrossWS(tc)
            % Only_TbyW: required_TW returns TW_min at every W/S. A W/S vector
            % must yield TW_min repeated.
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_up", 0.03597, 0.04054, 2.2);
            obj  = ClimbGradientConstraint("Climb 1", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.012, 1.2, ...
                "takeoff_flaps_gear_up", 'oei', true, 'hot_day', true);

            tw_min = obj.TW_min();
            WS     = [50 100 150];
            tc.verifyEqual(obj.required_TW(WS), repmat(tw_min, size(WS)), ...
                'AbsTol', 1e-12, 'required_TW must be TW_min at every W/S.');
        end

        function testConstraintResidualSignAndValue(tc)
            % Only_TbyW.constraint_residual = TW_min() - dp.TW; g <= 0 feasible,
            % dp.WS unused.
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_up", 0.03597, 0.04054, 2.2);
            obj  = ClimbGradientConstraint("Climb 1", aero, ...
                TestClimbGradientConstraint.twinProp(), 0.012, 1.2, ...
                "takeoff_flaps_gear_up", 'oei', true, 'hot_day', true);

            TW_req = obj.TW_min();
            W_TO   = 30000;
            S_ref  = 300;

            dp_feas   = DesignPoint(W_TO, 1.10 * TW_req * W_TO, S_ref);
            dp_infeas = DesignPoint(W_TO, 0.90 * TW_req * W_TO, S_ref);

            tc.verifyEqual(obj.constraint_residual(dp_feas), TW_req - dp_feas.TW, ...
                'RelTol', 1e-10, 'constraint_residual must equal TW_min() - dp.TW.');
            tc.verifyLessThan(obj.constraint_residual(dp_feas), 0, ...
                'More T/W available than the floor must be feasible (g < 0).');
            tc.verifyGreaterThan(obj.constraint_residual(dp_infeas), 0, ...
                'Less T/W available than the floor must be infeasible (g > 0).');
        end

        % --- Error paths ----------------------------------------------------

        function testOeiSingleEngineErrors(tc)
            % OEI on a single-engine aircraft is undefined: N/(N-1) divides by
            % zero. Must error 'ClimbGradientConstraint:oeiSingleEngine'. The
            % class reads n_engines inside TW_min (only when oei is set), so the
            % error is raised on the TW_min call, not at construction.
            aero = TestClimbGradientConstraint.climbAero("clean", 0.01597, 0.03815, 0.9);
            prop = FixedConfigPropStub(1.0, 1);   % single-engine
            obj  = ClimbGradientConstraint("Climb", aero, prop, 0.012, 1.25, ...
                "clean", 'oei', true, 'hot_day', true);
            tc.verifyError(@() obj.TW_min(), ...
                'ClimbGradientConstraint:oeiSingleEngine', ...
                'An OEI climb on a single-engine aircraft must error loudly.');
        end

        function testMissingNEnginesErrors(tc)
            % A prop object lacking an n_engines property, with oei=true, must
            % error 'ClimbGradientConstraint:missingNEngines'. FixedPropStub
            % (the point-performance stub) has NO n_engines property, so it
            % triggers the guarded isprop read. The error is raised inside
            % TW_min, where the OEI factor is formed.
            aero = TestClimbGradientConstraint.climbAero("clean", 0.01597, 0.03815, 0.9);
            prop = FixedPropStub(1.0);            % no n_engines property
            obj  = ClimbGradientConstraint("Climb", aero, prop, 0.012, 1.25, ...
                "clean", 'oei', true, 'hot_day', true);
            tc.verifyError(@() obj.TW_min(), ...
                'ClimbGradientConstraint:missingNEngines', ...
                'An OEI climb with a prop lacking n_engines must error loudly.');
        end

        % --- fromCondition factory -----------------------------------------

        function testFromConditionMatchesDirectConstructor(tc)
            % fromCondition reads cond.name/G/ks/config and the optional
            % oei/hot_day/max_continuous/weight_ratio flags. Reproduce Climb 1.
            cond = struct('name', 'Climb 1', 'G', 0.012, 'ks', 1.2, ...
                'config', 'takeoff_flaps_gear_up', 'oei', true, ...
                'hot_day', true, 'max_continuous', false, 'weight_ratio', 1.0);
            aero = TestClimbGradientConstraint.climbAero("takeoff_flaps_gear_up", 0.03597, 0.04054, 2.2);
            prop = TestClimbGradientConstraint.twinProp();

            obj_fc = ClimbGradientConstraint.fromCondition(cond, aero, prop);
            tc.verifyEqual(obj_fc.TW_min(), TestClimbGradientConstraint.EXP_CLIMB1, ...
                'AbsTol', 1e-5, 'fromCondition must reproduce the Climb 1 (Eq. 4.49) value.');
            tc.verifyEqual(obj_fc.name, "Climb 1");
        end

    end

end
