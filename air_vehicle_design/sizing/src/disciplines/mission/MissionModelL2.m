classdef (Abstract) MissionModelL2 < MissionBase
%MISSIONMODELL2  Tier-2b abstract enforcer for Level-2 mission analysis.
%
%   Inherits MissionBase directly (NOT MissionModelL1 or L3 -- each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-2 mission analysis is single-point Breguet using the REAL
%   discipline objects for the Table-2.2-replaced phases: Cruise/Dash/
%   Combat/Loiter call aero.drag_polar(state) for CD0/K1/K2 (L/D computed
%   at the segment's mid-weight CL) and prop.get_TSFC(state) (mil) or
%   prop.compute_TSFC_AB(state) (AB -- selected per-segment by dry_or_wet)
%   instead of Roskam Table 2.2 lookups. Roskam Table 2.1's fixed-fraction
%   phases (Startup, Taxi, Takeoff, Descent, Landing) are unchanged from L1
%   -- Table 2.1 has no aero/prop-based alternative at any fidelity level.
%   Climb is NOT a fixed-fraction phase at L2 (user-directed 2026-07-24): it
%   is discretized into N=20 sub-intervals of the same energy-height
%   integration MissionL3 uses for Climb, via MissionL2.segment_climb
%   delegating to MissionL3.segment_climb with N=20 (L3 uses its own N=40).
%   See docs/subplans/07_mission_analysis.md, "L2 -- single-point Breguet
%   with real discipline objects".
%
%   INPUT vs DERIVED and the aircraft_category note: identical rationale to
%   MissionModelL1 -- see that file's header for the full explanation this
%   pass doesn't repeat verbatim here.
%
%   Inheritance: MissionBase -> MissionModelL2 -> F16MissionL2

    properties (Abstract)
        % ---- Generic mission-profile inputs (identical shape across L1/L2/L3) %
        segment_names               % string array  -- mission-segment names, in mission order
        alt_ft                      % double array  -- altitude AT END of each segment [ft]
        mach_end                    % double array  -- Mach number AT END of each segment
        dist_nm_given               % double array  -- given range per segment [nm]; NaN where not range-given
        time_min_given              % double array  -- given duration per segment [min]; NaN where not time-given
        drop_lb                     % double array  -- payload jettisoned during the segment [lbf]
        dry_or_wet                  % string array  -- "Dry"/"Wet" afterburner flag per segment; selects prop.get_TSFC vs. prop.compute_TSFC_AB

        % ---- scalar spec/configuration constants ------------------------ %
        CLmax_TO                    % double -- takeoff-configuration CLmax
        CLmax_land                  % double -- landing-configuration CLmax
        mu_rolling                  % double -- ground-roll rolling-friction coefficient
        liftoff_factor              % double -- V_LO / V_stall margin factor
        warmup_fuel_per_engine_lb   % double -- engine warmup fuel [lbf/engine]
        RFF                         % double -- reserve fuel fraction [Design Notes: 0.06]
        aircraft_category           % string -- Roskam Table 2.1 category key, still needed for the fixed-fraction phases (see class header)

        % ---- dual-return contract's stored output ----------------------- %
        mission_fuel                % double -- lbf; stored by compute_fuel as a side effect
    end

    properties (Abstract, Dependent)
        %MISSIONDATA  Struct packaging of the current mission-profile inputs,
        %   in the shape MissionL2.get_mission_fuel expects. Zero-argument,
        %   recomputed live on every read -- see MissionModelL1's header.
        missiondata
    end

end
