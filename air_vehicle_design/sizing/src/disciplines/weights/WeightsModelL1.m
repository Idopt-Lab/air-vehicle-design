classdef (Abstract) WeightsModelL1 < WeightsBase
%WEIGHTSMODELL1  Tier-2a abstract enforcer for Level-1 weight estimation.
%
%   Inherits WeightsBase directly (NOT WeightsModelL2 or L3 — each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-1 methods (both are statistical regressions):
%     (1) Raymer Table 3.1 power-law:  We/Wto = Kvs × A × W_TO^C
%         Central estimate.  A, C, Kvs from aircraft-category lookup.
%     (2) Roskam Eq. 2.16 log-log:     log10(W_E) = (log10(W_TO) − A) / B
%         Minimum achievable W_E for that class — a lower bound, not a central
%         estimate.  Compare with (1) to gauge design margin.
%
%   Inheritance: WeightsBase → WeightsModelL1 → F16WeightsL1

    methods (Abstract)

        %COMPUTE_WE_FRACTION  OEW/Wto fraction via Raymer Table 3.1 power law.
        %   W_TO             — candidate gross weight [lbf].
        %   aircraft_category — optional string (e.g. 'jet_fighter').
        %                       Defaults to obj.aircraft_category when omitted.
        %   Returns dimensionless fraction We/Wto ∈ (0, 1).
        OEW_frac = compute_We_fraction(obj, W_TO, aircraft_category)

        %COMPUTE_WE_ROSKAM  Minimum empty weight [lbf] via Roskam Eq. 2.16.
        %   W_TO — candidate gross weight [lbf].
        %   Returns minimum W_E [lbf].  Lower bound — actual OEW ≥ this value.
        W_E = compute_We_roskam(obj, W_TO)

    end

end
