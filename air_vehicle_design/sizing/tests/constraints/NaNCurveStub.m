classdef NaNCurveStub < PointPerformanceBase
%NANCURVESTUB  A constraint whose required_TW curve contains NaN, used only
%   by tests.
%
%   WHY THIS EXISTS: ConstraintAnalysis rejects a NaN required_TW curve at
%   construction (ConstraintAnalysis.assertNoNaN). That guard cannot be
%   exercised with a real ThrustConstraint, because Both_WbyS_TbyW.required_TW
%   catches a non-finite Master-Equation term FIRST and throws
%   Both_WbyS_TbyW:nonFiniteTerm -- so the aggregator never sees the NaN.
%
%   That is precisely the gap this stub represents. Both_WbyS_TbyW's check
%   only protects constraints built on the Master Equation; a constraint
%   category that computes required_TW some other way (a wall-type bound, a
%   future tabulated or interpolated condition) never passes through it. The
%   aggregator is the one place EVERY constraint type funnels through, so it
%   needs its own check, and this stub is a constraint that reaches it with a
%   NaN in hand.
%
%   Build with NaNCurveStub(name, nanIndices): required_TW returns ones the
%   size of WS with NaN at the requested linear indices. Inf is NOT stubbed
%   here -- Inf is a legal wall-constraint value that the aggregator must keep
%   accepting (see LandingConstraint), and TestConstraintAnalysis covers that
%   separately with a real LandingConstraint.

    properties (SetAccess = protected)
        name
    end

    properties
        nanIndices (1,:) double
    end

    methods

        function obj = NaNCurveStub(name, nanIndices)
            arguments
                name       (1,1) string
                nanIndices (1,:) double = 1
            end
            obj.name       = name;
            obj.nanIndices = nanIndices;
        end

        function TW = required_TW(obj, WS)
            TW = ones(size(WS));
            TW(obj.nanIndices) = NaN;
        end

    end

end
