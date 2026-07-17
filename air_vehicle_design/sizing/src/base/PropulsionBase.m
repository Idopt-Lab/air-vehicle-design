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

end
