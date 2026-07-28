classdef F16MissionL3 < MissionModelL3
%F16MISSIONL3  F-16A CAP mission Level-3 student class.
%
%   Inherits from MissionModelL3 (abstract enforcer). compute_fuel is a
%   single delegation line to MissionL3.get_mission_fuel -- no equations are
%   duplicated here.
%
%   Level-3 model: sub-segmented Breguet (N=20; Roskam Eq. 2.10/2.12 forms)
%   with REAL aero/prop discipline objects for Cruise/Dash/Combat/Loiter,
%   plus an energy-height climb integration; Roskam Table 2.1 fixed
%   fractions (unchanged from L1/L2) for Startup/Taxi/Takeoff/Descent/
%   Landing -- see MissionModelL3's header.
%
%   ============================================================================
%   INPUT vs DERIVED -- identical pattern to F16MissionL1 (see that class's
%   header for the full rationale; not repeated verbatim here).
%   ============================================================================
%
%   Constructor loads examples/F16A/mission_profile.json by default
%   (override by passing an explicit path) -- the SAME profile L1/L2 read.
%
%   Inheritance: MissionBase -> MissionModelL3 -> F16MissionL3
%
%   SOURCES:
%     [subplan]  docs/subplans/07_mission_analysis.md
%     [JSON]     examples/F16A/mission_profile.json

    properties
        % ---- CAP mission-profile inputs ---------------------------------- %
        segment_names
        alt_ft
        mach_end
        dist_nm_given
        time_min_given
        drop_lb
        dry_or_wet

        % ---- scalar spec/configuration constants ------------------------- %
        CLmax_TO
        CLmax_land
        mu_rolling
        liftoff_factor
        warmup_fuel_per_engine_lb
        RFF
        aircraft_category = "fighter"   % Roskam Table 2.1 category key, still needed for the fixed-fraction phases (see MissionModelL2/L3's header)

        % ---- dual-return contract's stored output ------------------------ %
        mission_fuel = NaN   % lbf; populated by compute_fuel as a side effect
    end

    properties (Dependent)
        missiondata
        n_segments
        total_range_nm_given
    end

    methods

        function obj = F16MissionL3(json_path)
        %F16MISSIONL3  Construct from examples/F16A/mission_profile.json
        %   (default) or an explicit override path.
            if nargin == 0
                json_path = fullfile(fileparts(mfilename('fullpath')), 'jsons', 'mission_profile.json');
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
        %COMPUTE_FUEL  Single delegation into MissionL3.get_mission_fuel.
        %   aero/prop are the REAL discipline objects -- called once per
        %   sub-interval for Cruise/Dash/Combat/Loiter/Climb (see
        %   MissionModelL3's header).
            W_fuel = MissionL3.get_mission_fuel(obj.missiondata, W_TO, aero, prop);
            obj.mission_fuel = W_fuel;   % dual-return contract's side effect
        end

        % ================================================================== %
        % DERIVED-property getters -- recompute live from the inputs on
        % every read (see F16MissionL1's header for the full rationale).
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
