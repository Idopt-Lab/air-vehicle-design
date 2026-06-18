classdef MissionBase < handle
    % Abstract base class for all mission analysis discipline implementations.
    %
    % Every fidelity level (MissionLevel1, MissionLevel2, …) inherits from
    % this class and implements compute_fuel.  The sizing loop calls
    % compute_fuel once per iteration.
    %
    % Higher-fidelity implementations call aero.drag_polar and prop.TSFC
    % at each mission segment; lower-fidelity implementations use tabulated
    % fuel fractions and do not call those methods directly.

    methods (Abstract)
        % compute_fuel  Returns total fuel burned over the mission (lbf).
        %   aero  — AerodynamicsBase subclass instance
        %   prop  — PropulsionBase subclass instance
        %   W_TO  — current takeoff gross weight estimate (lbf)
        %   req   — requirements struct (mission profile, payload, etc.)
        fuel = compute_fuel(obj, aero, prop, W_TO, req)
    end
end
