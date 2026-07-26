classdef (Abstract) WeightsModelL1 < WeightsBase
%WEIGHTSMODELL1  Tier-2a abstract enforcer for Level-1 weight estimation.
%
%   Inherits WeightsBase directly (NOT WeightsModelL2 or L3 — each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-1 methods (both are statistical regressions on takeoff gross weight):
%     (1) Raymer Table 3.1 power law:  We/Wto = K_vs · A · W_TO^C
%         Central estimate.  A, C, K_vs from an aircraft-category lookup.
%         [Raymer 7th ed. Table 3.1]  ** This is what OEW delegates to. **
%     (2) Roskam Eq. 2.16 log-log:     log10(W_E) = (log10(W_TO) − A) / B
%         The MINIMUM achievable W_E for that class — a lower bound, not a
%         central estimate. Compare with (1) to gauge design margin; it is never
%         summed into OEW.  [Roskam Part I Eq. 2.16 + Table 2.15]
%
%   NO ABSTRACT PROPERTIES ARE DECLARED HERE, deliberately. Both L1 quantities
%   take W_TO as a method argument, so they recompute per call and cannot go
%   stale; there is no stored derived state at L1 and therefore nothing for the
%   inputs-vs-Dependent rule to govern. Consequently L1 carries none of the NaN
%   "computed total" placeholders that review finding #12 flagged at L2/L3.
%   Adding Dependent mirrors keyed off obj.W_TO would be a feature beyond what
%   this tier needs (docs/weights_parameter_usage.md §1;
%   F16WeightsL1.md §B.2).
%
%   Inheritance: WeightsBase → WeightsModelL1 → F16WeightsL1
%   (WeightsL1 is the static toolbox alongside, NOT in the chain.)

    methods (Abstract)

        %COMPUTE_WE_FRACTION  OEW/Wto fraction via the Raymer Table 3.1 power law.
        %   [Raymer 7th ed. Table 3.1]
        %   W_TO             — candidate gross weight [lbf].
        %   aircraft_category — optional char/string (e.g. 'jet_fighter').
        %                       Defaults to obj.aircraft_category when omitted.
        %   Returns the dimensionless fraction We/Wto in (0, 1).
        OEW_frac = compute_We_fraction(obj, W_TO, aircraft_category)

        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf] via Roskam Eq. 2.16.
        %   [Roskam Part I Eq. 2.16 + Table 2.15]
        %   W_TO — candidate gross weight [lbf].
        %   Returns the minimum W_E [lbf]. A LOWER BOUND — an actual OEW should
        %   exceed it, and it must never be reported as an OEW estimate.
        W_E = compute_We_roskam(obj, W_TO)

    end

end
