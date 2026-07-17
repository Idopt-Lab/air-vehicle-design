classdef (Abstract) WeightsModelL2 < WeightsBase
%WEIGHTSMODELL2  Tier-2a abstract enforcer for Level-2 weight estimation.
%
%   Inherits WeightsBase directly (NOT WeightsModelL1 — each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-2 method: Raymer Table 15.2 component/surface-density buildup.
%   Each structural surface is weighted by lbf/ft² unit weight (fighter row).
%   Installed engine weight and all-else-empty are set directly by the student
%   class (not computed here — those require L3 detail).
%
%   Interpretation: L2 breaks OEW into physical groups so students can see
%   where mass lives.  Compare total against the L1 Roskam lower bound
%   (now in WeightsL1.compute_We_roskam) and the L1 Raymer central estimate
%   to gauge fidelity improvement.
%
%   Inheritance: WeightsBase → WeightsModelL2 → F16WeightsL2

    properties (Abstract)
        W_wings            % computed wing structural weight [lbf]
        W_landing_gear     % computed total landing gear weight [lbf]
        W_tail             % computed tail weights; struct(HT, VT) after weight_tail call [lbf]
        W_fuselage         % computed fuselage structural weight [lbf]
        W_installed_engine % installed engine weight [lbf]; set by student class
        W_all_else_empty   % systems/equipment group [lbf]; set by student class
    end

    methods (Abstract)

        %WEIGHT_WING  Wing structural weight [lbf].  [Raymer Table 15.2]
        %   Surface-density estimate: 9 lbf/ft² × S_w for fighters.
        W = weight_wing(obj, W_TO)

        %WEIGHT_TAIL  HT + VT tail structural weights [lbf].  [Raymer Table 15.2]
        %   Returns struct with fields HT and VT.
        W = weight_tail(obj, W_TO)

        %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer Table 15.2]
        %   Surface-density estimate: 4.8 lbf/ft² × S_wet_fus for fighters.
        W = weight_fuselage(obj, W_TO)

        %WEIGHT_LANDING_GEAR  Total landing gear weight [lbf].  [AE481 metabook §7]
        %   Fraction-based: 0.033 × W_TO for non-Navy fighters.
        W = weight_landing_gear(obj, W_TO)

    end

end
