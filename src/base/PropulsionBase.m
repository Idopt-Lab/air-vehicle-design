classdef PropulsionBase < handle
    % Abstract base class for all propulsion discipline implementations.
    %
    % Every fidelity level (PropulsionLevel1, PropulsionLevel2, …) inherits
    % from this class and implements thrust_lapse and TSFC.
    %
    % The sizing loop sets T0 (sea-level static thrust) at each iteration:
    %   prop.T0 = T_W_opt * W_TO;
    % Available thrust at any condition is then: T = alpha * T0.

    properties
        T0 = 0  % Sea-level static thrust (lbf). Set by the sizing loop.
    end

    methods (Abstract)
        % thrust_lapse  Returns ratio of available thrust to T0 at the given state.
        %   alpha = T_available / T0   (dimensionless, typically 0–1)
        alpha = thrust_lapse(obj, state)

        % TSFC  Returns thrust-specific fuel consumption at the given state (1/s).
        %   Mission analysis integrates fuel burn as:  dW_fuel = TSFC * T * dt
        tsfc = TSFC(obj, state)
    end
end
