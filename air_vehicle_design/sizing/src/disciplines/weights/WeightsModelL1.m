classdef (Abstract) WeightsModelL1 < WeightsBase
%WEIGHTSMODELL1  Tier-2 abstract enforcer for Level-1 weights (statistical
%   empty-weight fraction). Inherits WeightsBase; declares the abstract members
%   a concrete L1 class must supply. No DERIVED properties.
%   History and rationale: docs/decision_log.md.
%   Toolbox companion: src/disciplines/weights/WeightsL1.md

    properties (Abstract)
        aircraft_category   % string; selects the coefficient rows
    end

    methods (Abstract)

        %COMPUTE_WE_FRACTION  OEW/W_TO fraction.  [Raymer 6th ed. Table 3.1]
        %   aircraft_category is optional; defaults to obj.aircraft_category.
        OEW_frac = compute_We_fraction(obj, W_TO, aircraft_category)

        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf].
        %   [Roskam Part I Eq. 2.16 with Table 2.15]
        %   A LOWER BOUND: an actual OEW should exceed it, and it must never be
        %   reported as an OEW estimate.
        W_E = compute_We_roskam(obj, W_TO)

    end

end
