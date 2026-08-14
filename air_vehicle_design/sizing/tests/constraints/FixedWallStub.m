classdef FixedWallStub < Only_WbyS
%FIXEDWALLSTUB  A constant W/S wall (Only_WbyS) stand-in, used only by tests.
%
%   Mirrors FixedAeroStub.m's rationale: ConstraintAnalysis and TSDiagram
%   treat any Only_WbyS constraint as a vertical W/S wall via WS_max(). A
%   test that wants a wall at an EXACT, hand-chosen wing loading (to check
%   that the continuous optimizer lands ON the wall, or that a wall left of
%   the whole sweep makes the set infeasible) needs a minimal wall object
%   with a constructor-set constant limit -- a real LandingConstraint would
%   put the wall wherever the aero model says, which is exactly the
%   dependence these tests must NOT have.
%
%   WS_max() returns the constructor-set constant, so the inherited
%   Only_WbyS.constraint_residual is g = dp.WS - WS_limit (g <= 0 feasible).

    properties (SetAccess = protected)
        name    % string -- condition label (PointPerformanceBase contract)
    end

    properties
        WS_limit (1,1) double {mustBePositive} = 80   % psf -- the wall
    end

    methods

        function obj = FixedWallStub(name, WS_limit)
            arguments
                name     (1,1) string
                WS_limit (1,1) double {mustBePositive}
            end
            obj.name = name;
            obj.WS_limit = WS_limit;
        end

        function WS = WS_max(obj)
        %WS_MAX  The constant, constructor-set wing-loading upper bound.
            WS = obj.WS_limit;
        end

    end

end
