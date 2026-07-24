classdef (Abstract) MissionModelL1 < MissionBase
%MISSIONMODELL1  Tier-2a abstract enforcer for Level-1 mission analysis.
%
%   Inherits MissionBase directly (NOT MissionModelL2 or L3 -- each fidelity
%   enforcer independently satisfies the Tier-1 contract, per the
%   established pattern).
%
%   Level-1 mission analysis is TABULATED ONLY (Roskam Airplane Design Part
%   I, Table 2.1 fixed fractions + Table 2.2 single-point Breguet with
%   tabulated L/D and TSFC) -- it must NEVER call the real aero/prop
%   discipline objects, even though compute_fuel(obj, aero, prop, W_TO)
%   still accepts them (to satisfy the one shared Tier-1 signature every
%   fidelity level uses). See docs/subplans/07_mission_analysis.md Design
%   Notes: "L1 does NOT call aero.drag_polar or prop.get_TSFC/
%   compute_TSFC_AB. Arguments accepted but unused -- test this with a mock
%   that errors if called." Concrete classes (F16MissionL1) must honor this;
%   it is enforced by test-writer's mock aero/prop objects, not by MATLAB.
%
%   This class (and MissionModelL2/L3, MissionL1/L2/L3) is Layer 1 --
%   generic, any aircraft -- per PLAN.md's Layer-1/Layer-2 split. Nothing
%   below is specific to any one aircraft's mission profile; the F-16's CAP
%   mission (examples/F16A/mission_profile.json, F16MissionL1/L2/L3.m) is
%   just ONE example instance of the schema these abstract properties
%   declare, used here for illustration only.
%
%   INPUT vs DERIVED (optimization-ready pattern, matching F16GeomL2's
%   reference implementation -- see examples/F16A/F16GeomL2.m header):
%   the mission-profile arrays below (segment_names, alt_ft, mach_end,
%   dist_nm_given, time_min_given, drop_lb, dry_or_wet) plus the scalar
%   spec constants (CLmax_TO, CLmax_land, mu_rolling, liftoff_factor,
%   warmup_fuel_per_engine_lb, RFF, aircraft_category) are genuine INPUTS,
%   read once from mission_profile.json by the concrete constructor and
%   free to be mutated by an optimizer thereafter. `missiondata` is a
%   DERIVED, zero-argument Dependent property that packages the object's
%   current inputs into the single struct MissionL1.get_mission_fuel
%   expects -- it is recomputed live on every read, so it can never go
%   stale relative to the stored inputs (see docs/subplans/07's "Input vs.
%   derived properties" section).
%
%   NOTE ON aircraft_category (judgment call -- see the implementation
%   pass's report): declared here AND identically on MissionModelL2/L3, not
%   L1-only, because Roskam Table 2.1's fixed-fraction phases (Startup,
%   Taxi, Takeoff, Climb, Descent, Landing) have no aero/prop-based
%   alternative at ANY fidelity level per the subplan's own L2 description
%   (which only replaces the Table 2.2 Breguet segments -- Cruise/Dash/
%   Combat/Loiter -- with real aero/prop calls, saying nothing about
%   replacing Table 2.1). L2/L3 concrete classes therefore still need an
%   aircraft_category to reuse the same Table 2.1 lookup for those phases.
%
%   mission_fuel is the dual-return contract's stored side effect (see
%   MissionBase) -- a plain, mutable property (not Dependent): it's an
%   OUTPUT that persists between compute_fuel calls, not a pure function of
%   the other stored inputs.
%
%   Inheritance: MissionBase -> MissionModelL1 -> F16MissionL1

    properties (Abstract)
        % ---- Generic mission-profile inputs (identical shape across
        %      L1/L2/L3; see mission_profile.json for one example instance) %
        segment_names               % string array  -- mission-segment names, in mission order
        alt_ft                      % double array  -- altitude AT END of each segment [ft]
        mach_end                    % double array  -- Mach number AT END of each segment
        dist_nm_given               % double array  -- given range per segment [nm]; NaN where not range-given
        time_min_given              % double array  -- given duration per segment [min]; NaN where not time-given
        drop_lb                     % double array  -- payload jettisoned during the segment [lbf]
        dry_or_wet                  % string array  -- "Dry"/"Wet" afterburner flag per segment

        % ---- scalar spec/configuration constants ------------------------ %
        CLmax_TO                    % double -- takeoff-configuration CLmax
        CLmax_land                  % double -- landing-configuration CLmax
        mu_rolling                  % double -- ground-roll rolling-friction coefficient
        liftoff_factor              % double -- V_LO / V_stall margin factor
        warmup_fuel_per_engine_lb   % double -- engine warmup fuel [lbf/engine]
        RFF                         % double -- reserve fuel fraction [Design Notes: 0.06]
        aircraft_category           % string -- Roskam Table 2.1/2.2 category key (e.g. "fighter")

        % ---- dual-return contract's stored output ----------------------- %
        mission_fuel                % double -- lbf; stored by compute_fuel as a side effect
    end

    properties (Abstract, Dependent)
        %MISSIONDATA  Struct packaging of the current mission-profile inputs,
        %   in the shape MissionL1.get_mission_fuel expects. Zero-argument,
        %   recomputed live from the object's own stored inputs on every
        %   read -- see class header.
        missiondata
    end

end
