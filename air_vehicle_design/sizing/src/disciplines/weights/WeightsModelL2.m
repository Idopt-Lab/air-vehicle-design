classdef (Abstract) WeightsModelL2 < WeightsBase
%WEIGHTSMODELL2  Tier-2a abstract enforcer for Level-2 weight estimation.
%
%   Inherits WeightsBase directly (NOT WeightsModelL1 — each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-2 method: surface-density (psf × area) structural buildup with
%   fraction-based engine and all-else groups.
%     structure  — Raymer 7th ed. Table 15.2 unit weights (fighter row:
%                  wing 9, HT 4, VT 5.3, fuselage 4.8 lbf/ft^2), on the
%                  EXPOSED planform areas and the fuselage WETTED area.
%     LG / engine / all-else — AE481 metabook Sec. 7 "Fraction-Based Weight
%                  Estimates" table (0.033·W_TO, 1.3× bare engine, 0.17·W_TO).
%                  ! These three are NOT Raymer Table 15.2 (todo §P4-7).
%
%   Interpretation: L2 breaks OEW into physical groups so students can see where
%   mass lives. Compare the total against the L1 Roskam lower bound
%   (WeightsL1.compute_We_roskam) and the L1 Raymer central estimate to gauge the
%   fidelity improvement.
%
%   ! THE SIX PROPERTIES BELOW ARE COMPUTED OUTPUTS, NOT STORED STATE.
%   A concrete class MUST satisfy each with a `properties (Dependent)` getter
%   that recomputes live from its inputs on every read — never with a plain
%   property, and never by assigning a value in the constructor. Two defects
%   this contract now forbids, both found in F16WeightsL2 before 2026-07-25:
%     * FINDING #12 — W_wings / W_landing_gear / W_tail / W_fuselage were
%       satisfied with `= NaN` and no code ever assigned them, so a consumer
%       reading the documented contract got NaN back. A property documented as
%       computed must never be able to read NaN.
%     * FINDING #5 — W_all_else_empty was computed ONCE in the constructor at a
%       hardcoded W_TO = 31377 (Brandt Wt!B3, an OUTPUT) and frozen, so it went
%       stale under mutation: OEW(45000) understated by 2315.91 lbf.
%   docs/weights_parameter_usage.md §4; F16WeightsL2.md §4/§3;
%   todo 2026-07-24 §3c items 1 and 6.
%
%   Inheritance: WeightsBase → WeightsModelL2 → F16WeightsL2
%   (WeightsL2 is the static toolbox alongside, NOT in the chain.)

    properties (Abstract)
        W_wings            % DERIVED wing structural weight [lbf] = weight_wing(obj, obj.W_TO)
        W_landing_gear     % DERIVED total landing gear weight [lbf] = weight_landing_gear(obj, obj.W_TO)
        W_tail             % DERIVED tail weights, struct(HT, VT) [lbf] = weight_tail(obj, obj.W_TO)
        W_fuselage         % DERIVED fuselage structural weight [lbf] = weight_fuselage(obj, obj.W_TO)
        W_installed_engine % DERIVED installed engine weight [lbf] = 1.3·N_en·W_en [AE481 metabook Sec. 7]
        W_all_else_empty   % DERIVED systems/equipment group [lbf] = 0.17·obj.W_TO [AE481 metabook Sec. 7]
    end

    methods (Abstract)

        %WEIGHT_WING  Wing structural weight [lbf].  [Raymer 7th ed. Table 15.2]
        %   Surface-density estimate: 9 lbf/ft^2 × S_w (exposed) for fighters.
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = weight_wing(obj, W_TO)

        %WEIGHT_TAIL  HT + VT tail structural weights [lbf].  [Raymer 7th ed. Table 15.2]
        %   Returns struct with fields HT and VT (4 and 5.3 lbf/ft^2 × exposed area).
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = weight_tail(obj, W_TO)

        %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer 7th ed. Table 15.2]
        %   Surface-density estimate: 4.8 lbf/ft^2 × S_wet_fus for fighters.
        %   W_TO is accepted for API consistency but does not enter the formula.
        W = weight_fuselage(obj, W_TO)

        %WEIGHT_LANDING_GEAR  Total landing gear weight [lbf].
        %   [AE481 metabook Sec. 7, "Fraction-Based Weight Estimates" table]
        %   Fraction-based: 0.033 × W_TO for non-Navy fighters. Must be evaluated
        %   at the PASSED W_TO — this term genuinely scales with gross weight.
        W = weight_landing_gear(obj, W_TO)

    end

end
