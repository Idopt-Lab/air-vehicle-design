classdef (Abstract) WeightsModelL1 < WeightsBase
%WEIGHTSMODELL1  Tier-2 abstract enforcer for Level-1 weights.
%
%   Inherits WeightsBase directly, not another WeightsModelLN.
%
%   L1 is a statistical empty-weight fraction: a power law in W_TO with an
%   independent regression as a lower bound. No geometry, no engine data, so a
%   concrete L1 class injects nothing.
%
%   No DERIVED properties are declared. OEW is a method taking W_TO, and at
%   this tier the whole model is one closed-form evaluation, so there is
%   nothing to recompute on read.
%
%   Toolbox companion: src/disciplines/weights/WeightsL1.md

    properties (Abstract)
        aircraft_category   % string; selects the coefficient rows
    end

    methods (Abstract)

        %COMPUTE_WE_FRACTION  OEW/W_TO fraction.  [Raymer 7th ed. Table 3.1]
        %   aircraft_category is optional; defaults to obj.aircraft_category.
        OEW_frac = compute_We_fraction(obj, W_TO, aircraft_category)

        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf].
        %   [Roskam Part I Eq. 2.16 with Table 2.15]
        %   A LOWER BOUND: an actual OEW should exceed it, and it must never be
        %   reported as an OEW estimate.
        W_E = compute_We_roskam(obj, W_TO)

    end

end
