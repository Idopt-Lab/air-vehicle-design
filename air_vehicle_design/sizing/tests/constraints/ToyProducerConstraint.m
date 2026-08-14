classdef ToyProducerConstraint < Both_WbyS_TbyW
%TOYPRODUCERCONSTRAINT  Analytic toy required_TW producer, used only by tests.
%
%   Mirrors FixedAeroStub.m's rationale: the sizing loops and
%   ConstraintAnalysis.optimal_point_continuous take real constraint
%   OBJECTS, not raw curves, so a test that wants a constraint whose exact
%   continuous optimum is knowable by hand needs a minimal
%   Both_WbyS_TbyW-shaped object with a closed-form required_TW. Using a
%   real Master-Equation constraint here would make the "expected" optimum
%   depend on the same atmosphere/drag code under test elsewhere -- this toy
%   keeps the expectation independently derivable with pencil and paper.
%
%   CURVE (pure algebra, no physics citation applies -- this is a test
%   artifact, not a textbook equation):
%
%       required_TW(WS) = A/WS + B*WS ,   A > 0, B > 0, WS > 0
%
%   HAND-DERIVED MINIMUM (calculus, documented so every consuming test can
%   cite it):
%       d(TW)/d(WS) = -A/WS^2 + B = 0   ->   WS* = sqrt(A/B)
%       TW* = A/WS* + B*WS* = sqrt(A*B) + sqrt(A*B) = 2*sqrt(A*B)
%   The curve is strictly decreasing for WS < WS* and strictly increasing
%   for WS > WS* (d2(TW)/d(WS)^2 = 2A/WS^3 > 0, strictly convex), so WS* is
%   the unique global minimum and any W/S wall below WS* binds the
%   constrained optimum exactly AT the wall.
%
%   The consuming tests (TestOptimalPointContinuous.m, TestSizingLoopL1.m,
%   TestSizingLoopL2.m, TestTSDiagram.m) all use A = 10, B = 0.001:
%       WS* = sqrt(10/0.001) = sqrt(10000) = 100 psf   (exact)
%       TW* = 2*sqrt(10*0.001) = 2*sqrt(0.01) = 0.2    (exact)

    properties (SetAccess = protected)
        name    % string -- condition label (PointPerformanceBase contract)
    end

    properties
        A (1,1) double {mustBePositive} = 10
        B (1,1) double {mustBePositive} = 0.001
    end

    methods

        function obj = ToyProducerConstraint(name, A, B)
            arguments
                name (1,1) string
                A    (1,1) double {mustBePositive}
                B    (1,1) double {mustBePositive}
            end
            obj.name = name;
            obj.A = A;
            obj.B = B;
        end

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  TW = A/WS + B*WS (see class header for the hand-derived
        %   minimum). WS scalar or array; TW returned the same size.
            TW = obj.A ./ WS + obj.B .* WS;
        end

    end

end
