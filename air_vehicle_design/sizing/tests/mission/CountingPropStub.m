classdef CountingPropStub < PropulsionBase
%COUNTINGPROPSTUB  Minimal PropulsionBase stand-in that RECORDS how many
%   times get_TSFC/compute_TSFC_AB/thrust_lapse_mil_on_AB_scale are called --
%   used to verify Mission L2/L3 call prop_obj the expected number of times
%   per segment (once at L2, N times at L3 for Breguet segments; N times in
%   L3's climb sub-loop for get_TSFC/thrust_lapse_mil_on_AB_scale), per
%   subplan 07's Tests table. A handle object (PropulsionBase < handle), so
%   call counts persist across the whole dispatch loop.
%
%   Returns fixed, physically-reasonable TSFC values regardless of state --
%   the VALUE is not the point (MissionL1's Breguet math is tested
%   independently); only the CALL COUNT and correct mil/AB dispatch (via
%   dry_or_wet) are exercised here.

    properties
        T_SL = 15000
        TSFC = 0
        TSFC_dry_value = 0.90   % 1/hr, arbitrary plausible mil-power value
        TSFC_AB_value  = 1.80   % 1/hr, arbitrary plausible AB value

        get_TSFC_calls              (1,1) double = 0
        compute_TSFC_AB_calls       (1,1) double = 0
        thrust_lapse_calls          (1,1) double = 0
        thrust_lapse_mil_AB_calls   (1,1) double = 0
    end

    methods

        function alpha = thrust_lapse(obj, ~)
            obj.thrust_lapse_calls = obj.thrust_lapse_calls + 1;
            alpha = 0.5;
        end

        function c_t = get_TSFC(obj, ~)
            obj.get_TSFC_calls = obj.get_TSFC_calls + 1;
            c_t = obj.TSFC_dry_value;
        end

        function c_t = compute_TSFC_AB(obj, ~)
            obj.compute_TSFC_AB_calls = obj.compute_TSFC_AB_calls + 1;
            c_t = obj.TSFC_AB_value;
        end

        function alpha = thrust_lapse_mil_on_AB_scale(obj, state)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  Override the PropulsionBase default
        %   fallback (which would just call thrust_lapse) so L3's climb
        %   sub-loop call count is tracked separately from AB-basis
        %   thrust_lapse calls.
            obj.thrust_lapse_mil_AB_calls = obj.thrust_lapse_mil_AB_calls + 1;
            alpha = 0.6;
        end

    end

end
