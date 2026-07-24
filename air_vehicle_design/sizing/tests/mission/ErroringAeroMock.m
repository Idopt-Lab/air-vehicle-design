classdef ErroringAeroMock < AerodynamicsBase
%ERRORINGAEROMOCK  Aero discipline stand-in that ERRORS if any method is
%   called -- used only to prove Mission L1 never touches aero_obj (subplan
%   07 Design Notes: "L1 does NOT call aero.drag_polar... test this with a
%   mock that errors if called").
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale (a minimal
%   AerodynamicsBase-shaped object, since MissionModelL1's compute_fuel
%   signature requires SOME aero object be passed in, even though L1 must
%   never call it) but inverts the behavior: instead of returning a fixed
%   value, every method throws, so any accidental call surfaces immediately
%   as a test failure instead of silently returning a plausible-looking
%   number.

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
                'aero_obj.drag_polar was called -- Mission L1 must NEVER call the aero discipline object.');
        end

        function CLmax = get_CLmax(~, ~)
            error('ErroringAeroMock:calledAtL1', ...
                'aero_obj.get_CLmax was called -- Mission L1 must NEVER call the aero discipline object.');
        end

    end

end
