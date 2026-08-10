classdef ErroringAeroMock < AerodynamicsBase
%ERRORINGAEROMOCK  Aero discipline stand-in that ERRORS if any method is
%   called -- used only to prove a FixedFractionSegment never touches the aero
%   object (those phases have no L/D dependence, so the same Roskam fraction
%   holds for every discipline stack).
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale (a minimal
%   AerodynamicsBase-shaped object), but inverts the behavior: every method
%   throws, so an accidental call surfaces immediately as a test failure
%   instead of silently returning a plausible-looking number.

    properties
        e_osw_clean = 0
        CD0 = 0
        CDi = 0
        CL = 0
        CD = 0
        CL_minD = 0
        CL_max_clean = 0
        Cf = 0
        K1 = 0
        K2 = 0
        S_ref = 300   % present in case a caller reads it directly (never should at L1)
    end

    methods

        function polar = drag_polar(~, ~)
            error('ErroringAeroMock:calledAtL1', ...
                'aero_obj.drag_polar was called -- a FixedFractionSegment must NEVER call the aero discipline object.');
        end

        function CLmax = get_CLmax(~, ~)
            error('ErroringAeroMock:calledAtL1', ...
                'aero_obj.get_CLmax was called -- a FixedFractionSegment must NEVER call the aero discipline object.');
        end

    end

end
