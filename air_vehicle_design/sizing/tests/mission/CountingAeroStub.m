classdef CountingAeroStub < AerodynamicsBase
%COUNTINGAEROSTUB  Minimal AerodynamicsBase stand-in that RECORDS how many
%   times drag_polar/get_CLmax are called -- used to verify Mission
%   L2/L3 call aero_obj.drag_polar the expected number of times per segment
%   (once at L2, N times at L3), per subplan 07's Tests table. A handle
%   object (AerodynamicsBase < handle), so call counts persist across the
%   whole dispatch loop.
%
%   Returns a fixed, physically-reasonable drag polar (CD0=0.02, K1=0.1,
%   K2=0) regardless of state -- the VALUE returned is not the point of this
%   stub (MissionL1's Breguet math is tested independently in
%   TestMissionL1); only the CALL COUNT and the fact that MissionL2/L3
%   correctly WIRE that returned polar into the Breguet form are exercised
%   here.

    properties
        e_osw_clean = 0
        CD0 = 0.02
        CDi = 0
        CL = 0
        CD = 0
        CL_minD = 0
        CL_max_clean = 1.2
        Cf = 0
        K1 = 0.1
        K2 = 0
        S_ref = 300   % ft^2 -- read directly by MissionL2/L3's compute_CL call

        drag_polar_calls (1,1) double = 0
        get_CLmax_calls  (1,1) double = 0
    end

    methods

        function polar = drag_polar(obj, ~)
            obj.drag_polar_calls = obj.drag_polar_calls + 1;
            polar = struct('CD0', obj.CD0, 'K1', obj.K1, 'K2', obj.K2);
        end

        function CLmax = get_CLmax(obj, ~)
            obj.get_CLmax_calls = obj.get_CLmax_calls + 1;
            CLmax = obj.CL_max_clean;
        end

    end

end
