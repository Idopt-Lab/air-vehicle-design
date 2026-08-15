classdef TestCeilingConstraint < matlab.unittest.TestCase
%TESTCEILINGCONSTRAINT  Unit tests for CeilingConstraint (Only_TbyW, the
%   minimum-T/W service-ceiling line, metabook Eq. 4.30/4.56).
%
%   HAND-COMPUTED EXPECTED VALUE
%     TW_min = (1/alpha) * ( 2*sqrt(CD0*K1) + G )        [metabook Eq. 4.30/4.55]
%   With the FixedConfigAeroStub clean polar CD0 = 0.01597, K1 = 0.03815
%   [metabook_data.md §4.11 Example 4.2], G = 0.001, and the
%   FixedConfigPropStub default lapse alpha = 1 (mil basis, state-independent):
%     2*sqrt(0.01597*0.03815) = 2*sqrt(6.0925e-4) = 2*0.0246831 = 0.0493661
%     TW_min = (1/1) * (0.0493661 + 0.001) = 0.0503661
%   The value is INDEPENDENT of wing loading (Only_TbyW): required_TW returns
%   it at every W/S -- this is why the ceiling is a HORIZONTAL line on the
%   constraint diagram (metabook Fig. 4.6), unlike the W/S-dependent
%   ExcessPower U-curve.

    properties (Constant)
        CD0   = 0.01597
        K1    = 0.03815
        G     = 0.001
        TWMIN = 0.05036622  % (1/1)*(2*sqrt(0.01597*0.03815) + 0.001) = 0.04936622 + 0.001
    end

    methods (Static)
        function [state, aero, prop] = build()
            state = AircraftState(42000, 0.84);
            aero  = FixedConfigAeroStub();     % clean drag_polar CD0/K1 above
            prop  = FixedConfigPropStub(1.0);  % alpha = 1 (mil = AB, state-independent)
        end
    end

    methods (Test)

        function testTWMinHandValue(tc)
            [state, aero, prop] = TestCeilingConstraint.build();
            c = CeilingConstraint("Ceiling", state, aero, prop, tc.G, "mil");
            fprintf('\n    Ceiling TW_min = %.7f (hand %.7f)\n', c.TW_min(), tc.TWMIN);
            tc.verifyEqual(c.TW_min(), tc.TWMIN, 'RelTol', 1e-6, ...
                'Ceiling TW_min must be (1/alpha)*(2*sqrt(CD0*K1)+G).');
        end

        function testWingLoadingIndependent(tc)
            % Only_TbyW: required_TW is the SAME flat floor at every W/S -- the
            % horizontal ceiling line (metabook Fig. 4.6).
            [state, aero, prop] = TestCeilingConstraint.build();
            c = CeilingConstraint("Ceiling", state, aero, prop, tc.G, "mil");
            ws = [50 100 150 250];
            tw = c.required_TW(ws);
            tc.verifyEqual(tw, repmat(tc.TWMIN, size(ws)), 'RelTol', 1e-6, ...
                'required_TW must return the flat TW_min at every W/S.');
        end

        function testResidual(tc)
            % Only_TbyW residual: g = TW_min - dp.TW (g <= 0 feasible), dp.WS unused.
            [state, aero, prop] = TestCeilingConstraint.build();
            c = CeilingConstraint("Ceiling", state, aero, prop, tc.G, "mil");
            dp_ok  = DesignPoint(1, tc.TWMIN * 2, 1/100);   % TW well above floor
            dp_bad = DesignPoint(1, tc.TWMIN / 2, 1/100);   % TW below floor
            tc.verifyLessThan(c.constraint_residual(dp_ok), 0, ...
                'A design above the ceiling floor is feasible (g < 0).');
            tc.verifyGreaterThan(c.constraint_residual(dp_bad), 0, ...
                'A design below the ceiling floor is infeasible (g > 0).');
        end

        function testFromCondition(tc)
            cond = struct('name', "Ceiling", 'altitude_ft', 42000, ...
                'mach', 0.84, 'G', tc.G, 'power_setting', "mil");
            [~, aero, prop] = TestCeilingConstraint.build();
            c = CeilingConstraint.fromCondition(cond, aero, prop);
            tc.verifyEqual(c.TW_min(), tc.TWMIN, 'RelTol', 1e-6, ...
                'fromCondition must reproduce the direct-constructor value.');
        end

        function testEnumResolves(tc)
            tc.verifyEqual(ConstraintType.Ceiling.ClassName, "CeilingConstraint");
        end

    end

end
