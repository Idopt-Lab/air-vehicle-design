classdef F16MissionL1 < MissionModelL1
%F16MISSIONL1  F-16A CAP mission Level-1 student class.
%
%   Inherits from MissionModelL1 (abstract enforcer). compute_fuel is a
%   single delegation line to MissionL1.get_mission_fuel -- no equations are
%   duplicated here.
%
%   Level-1 model: Roskam Airplane Design Part I, Table 2.1 fixed fractions
%   (Startup/Taxi/Takeoff/Climb/Descent/Landing) + Table 2.2 tabulated
%   Breguet (Cruise/Dash/Combat/Loiter). Does NOT call aero/prop -- see
%   MissionModelL1's header.
%
%   ============================================================================
%   INPUT vs DERIVED -- follows the F16GeomL2 reference pattern (see that
%   class's header for the full rationale; not repeated verbatim here).
%
%     INPUTS (plain, mutable properties): the CAP segment arrays
%     (segment_names, alt_ft, mach_end, dist_nm_given, time_min_given,
%     drop_lb, dry_or_wet) and the scalar spec/configuration constants
%     (CLmax_TO, CLmax_land, mu_rolling, liftoff_factor,
%     warmup_fuel_per_engine_lb, RFF, aircraft_category), read once from
%     examples/F16A/mission_profile.json by the constructor. mission_fuel
%     is also a plain property (the dual-return contract's stored output --
%     an OUTPUT persisted as a side effect of compute_fuel, not a pure
%     function of the other inputs, so it is NOT Dependent).
%
%     DERIVED (zero-argument Dependent properties, recomputed live, never
%     stale): missiondata (struct packaging of the current inputs, in the
%     shape MissionL1.get_mission_fuel expects -- required by the
%     MissionModelL1 abstract contract), n_segments, total_range_nm_given.
%   ============================================================================
%
%   Constructor requires an explicit JSON path (mission_profile_path()); no
%   silent default, same convention as F16GeomL2.
%
%   Inheritance: MissionBase -> MissionModelL1 -> F16MissionL1
%
%   SOURCES:
%     [subplan]  docs/subplans/07_mission_analysis.md (equations, citations,
%                CAP mission profile table -- user-approved 2026-07-24)
%     [JSON]     examples/F16A/mission_profile.json (verified CAP profile data)

    properties
        % ---- CAP mission-profile inputs ---------------------------------- %
        segment_names               % string array
        alt_ft                      % double array, ft
        mach_end                    % double array
        dist_nm_given                % double array, nm (NaN where not range-given)
        time_min_given               % double array, min (NaN where not time-given)
        drop_lb                      % double array, lbf
        dry_or_wet                   % string array, "Dry"/"Wet"

        % ---- scalar spec/configuration constants ------------------------- %
        CLmax_TO
        CLmax_land
        mu_rolling
        liftoff_factor
        warmup_fuel_per_engine_lb
        RFF
        aircraft_category = "fighter"   % [subplan 07 CAP table -- F-16A is a fighter-category aircraft, Roskam Table 2.1/2.2 row key]

        % ---- dual-return contract's stored output ------------------------ %
        mission_fuel = NaN   % lbf; populated by compute_fuel as a side effect
    end

    properties (Dependent)
        missiondata            % struct -- current inputs, packaged for MissionL1.get_mission_fuel
        n_segments              % -- numel(segment_names)
        total_range_nm_given    % nm -- sum(dist_nm_given, 'omitnan')
    end

    methods

        function obj = F16MissionL1(json_path)
        %F16MISSIONL1  Construct from a required mission-profile JSON path
        %   (mission_profile_path()). No silent default (fixed 2026-07-30,
        %   matching every other discipline's constructor convention; see
        %   CLAUDE.md). Sets ONLY the input properties; missiondata/
        %   n_segments/total_range_nm_given are produced live by their
        %   Dependent getters.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            S = MissionProfileImporter.read_json(json_path);

            obj.segment_names  = string(S.segment_names(:)');
            obj.alt_ft          = S.alt_ft(:)';
            obj.mach_end        = S.mach_end(:)';
            obj.dist_nm_given   = S.dist_nm_given(:)';
            obj.time_min_given  = S.time_min_given(:)';
            obj.drop_lb         = S.drop_lb(:)';
            obj.dry_or_wet      = string(S.dry_or_wet(:)');

            obj.CLmax_TO                   = S.CLmax_TO;
            obj.CLmax_land                 = S.CLmax_land;
            obj.mu_rolling                  = S.mu_rolling;
            obj.liftoff_factor              = S.liftoff_factor;
            obj.warmup_fuel_per_engine_lb   = S.warmup_fuel_per_engine_lb;
            obj.RFF                         = S.RFF;
        end

        function W_fuel = compute_fuel(obj, aero, prop, W_TO)
        %COMPUTE_FUEL  Single delegation into MissionL1.get_mission_fuel.
        %   aero/prop are accepted (shared Tier-1 signature) but MUST NOT be
        %   called at L1 -- see MissionModelL1's header.
            W_fuel = MissionL1.get_mission_fuel(obj.missiondata, W_TO, aero, prop);
            obj.mission_fuel = W_fuel;   % dual-return contract's side effect
        end

        % ================================================================== %
        % DERIVED-property getters -- recompute live from the inputs on
        % every read (see class header's INPUT vs DERIVED note).
        % ================================================================== %

        function v = get.missiondata(obj)
            v = struct( ...
                'segment_names', obj.segment_names, ...
                'alt_ft', obj.alt_ft, ...
                'mach_end', obj.mach_end, ...
                'dist_nm_given', obj.dist_nm_given, ...
                'time_min_given', obj.time_min_given, ...
                'drop_lb', obj.drop_lb, ...
                'dry_or_wet', obj.dry_or_wet, ...
                'CLmax_TO', obj.CLmax_TO, ...
                'CLmax_land', obj.CLmax_land, ...
                'mu_rolling', obj.mu_rolling, ...
                'liftoff_factor', obj.liftoff_factor, ...
                'warmup_fuel_per_engine_lb', obj.warmup_fuel_per_engine_lb, ...
                'RFF', obj.RFF, ...
                'aircraft_category', obj.aircraft_category);
        end

        function v = get.n_segments(obj)
            v = numel(obj.segment_names);
        end

        function v = get.total_range_nm_given(obj)
            v = sum(obj.dist_nm_given, 'omitnan');
        end

    end

end
