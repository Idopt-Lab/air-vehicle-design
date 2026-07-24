classdef (Abstract) PropulsionBase < handle
%PROPULSIONBASE  Tier-1 base enforcer for all propulsion discipline classes.
%
%   Declares only the two methods orchestrators call (thrust_lapse, TSFC) and
%   the T_SL property as abstract.  No equations, no coefficients.
%
%   Convention (applied at every fidelity level):
%     thrust_lapse — returns α = T(alt,M) / T_SL at the AB/max power setting.
%                   T_SL is the AB sea-level static thrust.
%                   Used in constraint analysis and the sizing loop.
%     TSFC         — returns mil-power TSFC in lbf_fuel/(hr·lbf_thrust) [1/hr].
%                   Used in Breguet-range mission analysis.
%                   Student classes expose compute_TSFC_AB separately when needed.
%
%   Inheritance chain per fidelity level:
%     PropulsionBase → PropulsionModelLN (abstract) → F16PropLN (student class)
%
%   PropL1/L2/L3 are standalone static toolboxes — NOT in this chain.  Student
%   classes call them via PropL1.method(obj, state) etc.

    properties (Abstract)
        T_SL    % double; lbf — sea-level static (max) thrust (static thrust)
        TSFC
    end

    methods (Abstract)

        %THRUST_LAPSE  Thrust lapse α = T(alt,M) / T_SL at AB/max power.
        %   state — AircraftState object.  Returns scalar α ∈ [0, 1].
        alpha = thrust_lapse(obj, state)

        %TSFC  Mil-power thrust-specific fuel consumption at the given state.
        %   Returns TSFC in lbf_fuel / (hr · lbf_thrust).
        %   For AB TSFC, call compute_TSFC_AB on the concrete fidelity class.
        c_t = get_TSFC(obj, state)

    end

    methods

        function alpha = thrust_lapse_mil_on_AB_scale(obj, state)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  Mil-power thrust lapse expressed on the
        %   AB/max T_SL scale: alpha = T_mil(alt,M) / T_SL_AB (NOT T_SL_mil).
        %   Matches Brandt F-16A.xls Consts col AU convention (alpha_mil_T_AB =
        %   alpha_dry*(T_SL_dry/T_SL_AB)) -- needed so a dry-power point-
        %   performance condition (e.g. Cruise) can be expressed on the same
        %   T_SL_AB/W_TO constraint-diagram axis as AB-flown conditions.
        %   Default: falls back to the AB-basis thrust_lapse -- correct for any
        %   concrete class with no separate mil-power model (e.g. F16PropL1's
        %   density-only lapse, which cannot distinguish power settings at all).
        %   Override in a concrete/Tier-2 class with a real mil-power model.
            alpha = obj.thrust_lapse(state);
        end

    end

end
