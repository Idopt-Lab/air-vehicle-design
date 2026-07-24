classdef (Abstract) MissionBase < handle
%MISSIONBASE  Tier-1 base enforcer for all mission-analysis discipline classes.
%
%   Declares ONLY the single method orchestrators (the sizing loop) call
%   (compute_fuel) as abstract, per docs/subplans/07_mission_analysis.md's
%   explicit Tier-1 file table. No equations, no coefficients, and (unlike
%   PropulsionBase/AerodynamicsBase) no shared abstract PROPERTIES either --
%   the generic mission-profile input properties (segment_names, alt_ft,
%   mach_end, ...) are instead declared identically by each of
%   MissionModelL1/L2/L3 (see those files' headers for why this is a
%   deliberate exception to the "fidelity-invariant items live at Tier 1"
%   convention PropulsionBase otherwise follows). This class and the
%   MissionL1/L2/L3 toolboxes are Layer 1 (generic, any aircraft) per
%   PLAN.md's Layer-1/Layer-2 split -- nothing here is specific to any one
%   aircraft's mission profile (e.g. the F-16's CAP mission is a purely
%   Layer-2/examples/F16A concern -- see F16MissionL1/L2/L3.m).
%
%   CONVENTION:
%     compute_fuel(obj, aero, prop, W_TO) -- runs the concrete class's own
%     mission profile (its own input properties) through the
%     fidelity-appropriate MissionLN.get_mission_fuel segment-dispatch loop
%     and returns total mission fuel weight [lbf].
%       aero  -- AerodynamicsBase-derived discipline object for the SAME
%                candidate design. Unused at L1 (accepted only to satisfy
%                the shared Tier-1 contract -- see MissionModelL1).
%       prop  -- PropulsionBase-derived discipline object, same design.
%                Unused at L1.
%       W_TO  -- current gross takeoff weight guess [lbf], supplied by the
%                sizing loop.
%
%     Dual-return contract (matches VnV/BrandtF16A's run()-method
%     convention): compute_fuel both RETURNS W_fuel and, as a side effect,
%     stores it on obj.mission_fuel (a plain property declared by each
%     MissionModelLN, not here) -- recomputed fresh on every call, never a
%     stale cache.
%
%   Inheritance chain per fidelity level:
%     MissionBase -> MissionModelLN (abstract) -> F16MissionLN (student class)
%
%   MissionL1/L2/L3 are standalone static toolboxes -- NOT in this
%   inheritance chain. Student classes call them via
%   MissionL1.get_mission_fuel(...) etc.

    methods (Abstract)

        %COMPUTE_FUEL  Total mission fuel weight [lbf] for the object's own
        %   mission profile, at the current W_TO guess.
        W_fuel = compute_fuel(obj, aero, prop, W_TO)

    end

end
