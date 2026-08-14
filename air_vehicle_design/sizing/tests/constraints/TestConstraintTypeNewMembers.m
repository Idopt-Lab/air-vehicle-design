classdef TestConstraintTypeNewMembers < matlab.unittest.TestCase
%TESTCONSTRAINTTYPENEWMEMBERS  Coverage for the FIVE new ConstraintType
%   enumeration members added alongside the FAR-25 field-length / climb-gradient
%   / maneuvering constraint classes:
%
%     TakeoffFieldLength      -> TakeoffFieldLengthConstraint
%     LandingFieldLengthFAR25 -> LandingFieldLengthConstraint
%     ClimbGradient           -> ClimbGradientConstraint
%     ManeuveringExcessPower  -> ManeuveringExcessPowerConstraint
%     InstantaneousTurn       -> InstantaneousTurnConstraint
%
%   ConstraintType(name).build(cond, aero, prop) delegates to the target class's
%   static fromCondition(cond, aero, prop). These tests confirm that (a) each
%   member's .ClassName resolves to the right concrete class, and (b) build()
%   constructs an object of that class from a minimal condition struct wired to
%   the deterministic FixedConfigAeroStub / FixedConfigPropStub test stubs.
%
%   These are DISPATCH tests -- the constructed objects' physics values are
%   asserted in each class's own Test*.m. Here we only check the enum wiring and
%   that build() returns an instance of the expected class.

    methods (Static, Access = private)

        function aero = aeroStub()
            aero = FixedConfigAeroStub();   % metabook Ex 4.2 per-config polars
        end

        function prop = propStub()
            prop = FixedConfigPropStub();   % alpha=1, n_engines=2
        end

    end

    methods (Test)

        % --- .ClassName wiring ---------------------------------------------

        function testClassNamesResolve(tc)
            tc.verifyEqual(ConstraintType.TakeoffFieldLength.ClassName, ...
                "TakeoffFieldLengthConstraint");
            tc.verifyEqual(ConstraintType.LandingFieldLengthFAR25.ClassName, ...
                "LandingFieldLengthConstraint");
            tc.verifyEqual(ConstraintType.ClimbGradient.ClassName, ...
                "ClimbGradientConstraint");
            tc.verifyEqual(ConstraintType.ManeuveringExcessPower.ClassName, ...
                "ManeuveringExcessPowerConstraint");
            tc.verifyEqual(ConstraintType.InstantaneousTurn.ClassName, ...
                "InstantaneousTurnConstraint");
        end

        % --- build() dispatch per new member -------------------------------

        function testBuildTakeoffFieldLength(tc)
            cond = struct('name', 'Takeoff Field Length', 'BFL_ft', 12000, 'sigma', 0.95);
            c = ConstraintType.TakeoffFieldLength.build(cond, ...
                TestConstraintTypeNewMembers.aeroStub(), TestConstraintTypeNewMembers.propStub());
            tc.verifyClass(c, 'TakeoffFieldLengthConstraint');
            tc.verifyEqual(c.name, "Takeoff Field Length");
        end

        function testBuildLandingFieldLengthFAR25(tc)
            cond = struct('name', 'Landing Field Length', 'runway_ft', 12000, ...
                'Sa_ft', 1000, 'weight_ratio', 0.65, 'sigma', 0.95);
            c = ConstraintType.LandingFieldLengthFAR25.build(cond, ...
                TestConstraintTypeNewMembers.aeroStub(), TestConstraintTypeNewMembers.propStub());
            tc.verifyClass(c, 'LandingFieldLengthConstraint');
            tc.verifyEqual(c.name, "Landing Field Length");
        end

        function testBuildClimbGradient(tc)
            % oei=false so no n_engines is needed; the dispatch is what matters.
            cond = struct('name', 'Climb 1', 'G', 0.012, 'ks', 1.2, ...
                'config', 'takeoff_flaps_gear_up', 'oei', false, 'hot_day', true);
            c = ConstraintType.ClimbGradient.build(cond, ...
                TestConstraintTypeNewMembers.aeroStub(), TestConstraintTypeNewMembers.propStub());
            tc.verifyClass(c, 'ClimbGradientConstraint');
            tc.verifyEqual(c.name, "Climb 1");
        end

        function testBuildManeuveringExcessPower(tc)
            cond = struct('name', 'Maneuver', 'altitude_ft', 15000, 'mach', 0.9, ...
                'beta', 0.85, 'n', 5, 'Ps_fps', 300, 'power_setting', 'AB');
            c = ConstraintType.ManeuveringExcessPower.build(cond, ...
                TestConstraintTypeNewMembers.aeroStub(), TestConstraintTypeNewMembers.propStub());
            tc.verifyClass(c, 'ManeuveringExcessPowerConstraint');
            tc.verifyEqual(c.name, "Maneuver");
        end

        function testBuildInstantaneousTurn(tc)
            cond = struct('name', 'Inst Turn', 'altitude_ft', 35000, 'mach', 1.6, ...
                'turn_rate_dps', 18, 'power_setting', 'AB');
            c = ConstraintType.InstantaneousTurn.build(cond, ...
                TestConstraintTypeNewMembers.aeroStub(), TestConstraintTypeNewMembers.propStub());
            tc.verifyClass(c, 'InstantaneousTurnConstraint');
            tc.verifyEqual(c.name, "Inst Turn");
        end

    end

end
