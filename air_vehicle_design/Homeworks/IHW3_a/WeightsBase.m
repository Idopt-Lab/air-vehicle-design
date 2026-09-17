classdef (Abstract) WeightsBase < handle
%WEIGHTSBASE  Tier-1 abstract enforcer for all weight-estimation classes.
%
%   Declares the four sizing-loop weight properties and the top-level method.
%
%   Inheritance: WeightsBase -> WeightsModelLN (abstract) -> F16WeightsLN
%   The WeightsLN static toolboxes are NOT in this chain.
%
%   Sizing-loop closure:
%     W_TO = OEW + W_energy + W_payload_fixed + W_payload_expendable
%
%   Companion doc: src/base/WeightsBase.md
%
%   TODO: no WeightsL{1,2,3} static reads W_energy or either payload, so the
%   closure above is not enforced anywhere and those three properties are inert
%   until the sizing loop lands (PLAN.md step 8).

    properties (Abstract)
        W_TO                 % lbf — candidate gross takeoff weight; NaN until the sizing loop sets it
        W_energy             % lbf — total internal fuel/battery weight; NaN until mission analysis sets it
        W_payload_expendable % lbf — expendable payload (stores)
        W_payload_fixed      % lbf — fixed equipment, including crew
    end

    methods (Abstract)

        %OEW  Operating empty weight [lbf] at a candidate takeoff weight.
        %   Must satisfy OEW < W_TO for all physical designs.
        %
        %   OEW stays a METHOD at every level: it takes W_TO as an argument, so
        %   it recomputes on every call and cannot go stale. Concrete classes
        %   must never cache it, and every W_TO-dependent term inside must be
        %   evaluated at the PASSED W_TO, not at obj.W_TO.
        oew = OEW(obj, W_TO)

    end

end
