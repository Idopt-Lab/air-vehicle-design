classdef (Abstract) MissionModelL3 < MissionBase
%MISSIONMODELL3  Tier-2c abstract enforcer for Level-3 mission analysis.
%
%   Inherits MissionBase directly (NOT MissionModelL1 or L2 -- each fidelity
%   enforcer independently satisfies the Tier-1 contract).
%
%   Level-3 mission analysis sub-segments Cruise/Dash/Combat/Loiter into
%   N=20 sub-intervals of real-aero/prop single-point Breguet (capturing the
%   cruise-climb L/D improvement as fuel burns off between sub-intervals),
%   and integrates Climb with an energy-height method (dh_e/dt = (T-D)V/W,
%   dW_fuel/dt = TSFC*T) at its OWN, separately-set N=40 sub-intervals
%   (user-directed 2026-07-24 -- double MissionL2's N=20 climb resolution),
%   fixing the two legacy bugs documented in
%   docs/subplans/07_mission_analysis.md's Known Issues #7 (altitude-unit
%   conversion dropped inside the climb loop; gravity-variation array
%   computed once then abandoned) rather than replicating them. Roskam
%   Table 2.1's fixed-fraction phases (Startup, Taxi, Takeoff, Descent,
%   Landing) are unchanged from L1/L2 -- see MissionModelL2's header for why.
%
%   INPUT vs DERIVED and the aircraft_category note: identical rationale to
%   MissionModelL1 -- see that file's header.
%
%   Inheritance: MissionBase -> MissionModelL3 -> F16MissionL3

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
        aircraft_category           % string -- Roskam Table 2.1 category key, still needed for the fixed-fraction phases (see MissionModelL2's header)

        % ---- dual-return contract's stored output ----------------------- %
        mission_fuel                % double -- lbf; stored by compute_fuel as a side effect
    end

    properties (Abstract, Dependent)
        %MISSIONDATA  Struct packaging of the current mission-profile inputs,
        %   in the shape MissionL3.get_mission_fuel expects. Zero-argument,
        %   recomputed live on every read -- see MissionModelL1's header.
        missiondata
    end

end
