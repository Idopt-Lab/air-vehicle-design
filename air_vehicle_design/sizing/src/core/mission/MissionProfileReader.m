classdef MissionProfileReader
%MISSIONPROFILEREADER  Reads one named mission profile from a requirements JSON.
%
%   Generic Layer-1 utility -- the mission-analysis analogue of
%   ConstraintSetImporter. Any aircraft's mission requirements can be read with
%   this, as long as the file follows the requirements-JSON layout the F-16 uses
%   (examples/F16A/inputs/f16a_requirements.json): a top-level "missions" object
%   keyed by profile name, each profile carrying mission-level scalars
%   (warmup_fuel_per_engine_lb, reserve_fuel_fraction, mu_rolling, mu_braking,
%   liftoff_factor, approach_factor) and an ordered "segments" array. Each
%   segment object carries REQUIREMENT data ONLY -- the segment type, the
%   end-of-segment flight condition (alt_ft, mach_end), and whichever of
%   distance_nm / time_min / drop_lb / percent_ab / cd0_increment applies. It
%   carries NO discipline-owned quantity (CLmax, CD0, K1/K2, thrust, TSFC come
%   from the injected aero/prop objects) and NO spec data (aircraft_category
%   from the injected aero object, n_engines from the injected geometry object).
%
%   Deliberately thin (mirrors ConstraintSetImporter): it does NOT append
%   atmosphere columns -- AircraftState derives density/speed/dynamic pressure
%   from altitude+Mach with its own citations (Mattingly Eq. 2.52). This class
%   only decodes the raw per-segment requirement fields.

    methods (Static)

        function profile = read_profile(json_path, profile_name)
        %READ_PROFILE  Read one named mission profile into a struct.
        %   json_path    -- requirements JSON path (e.g. f16a_requirements_path()).
        %   profile_name -- the profile key under the top-level "missions" object
        %                   (e.g. "cap", "brandt_14seg").
        %
        %   Returns the decoded profile struct: the mission-level scalar fields
        %   verbatim, a 1xN struct array `segments` in file order (one element per
        %   segment), and a `name` field echoing profile_name. Because the
        %   segments do not all carry the same keys (a cruise leg has distance_nm,
        %   a loiter leg time_min), the struct array is the union of all segment
        %   keys with the absent ones left empty ([]); read a per-segment field
        %   with isfield + ~isempty (a caller helper), not isfield alone. Errors,
        %   listing the available profiles, if the name is not present.
            arguments
                json_path    (1,1) string {mustBeNonzeroLengthText}
                profile_name (1,1) string {mustBeNonzeroLengthText}
            end

            if ~isfile(json_path)
                error('MissionProfileReader:fileNotFound', ...
                    'Mission requirements JSON not found: "%s".', json_path);
            end

            raw = jsondecode(fileread(json_path));

            if ~isfield(raw, 'missions')
                error('MissionProfileReader:missingMissionsBlock', ...
                    ['Requirements JSON "%s" has no top-level "missions" block. A ', ...
                     'mission requirements file must carry a "missions" object ', ...
                     'keyed by profile name.'], json_path);
            end

            key = char(profile_name);
            if ~isfield(raw.missions, key)
                avail = MissionProfileReader.profile_names(raw.missions);
                error('MissionProfileReader:profileNotFound', ...
                    'Mission profile "%s" is not in "%s". Available profiles: %s.', ...
                    key, json_path, strjoin(avail, ', '));
            end

            profile = raw.missions.(key);

            if ~isfield(profile, 'segments') || isempty(profile.segments)
                error('MissionProfileReader:noSegments', ...
                    'Mission profile "%s" has no non-empty "segments" array.', key);
            end

            profile.segments = MissionProfileReader.as_struct_array(profile.segments);

            % Every segment must declare a type -- it is the dispatch key the
            % aggregator maps to a concrete segment class.
            for i = 1:numel(profile.segments)
                if ~isfield(profile.segments(i), 'type') ...
                        || isempty(profile.segments(i).type) ...
                        || strlength(string(profile.segments(i).type)) == 0
                    error('MissionProfileReader:segmentMissingType', ...
                        'Segment %d of profile "%s" has no "type" field.', i, key);
                end
            end

            profile.name = string(profile_name);
        end

    end

    methods (Static, Access = private)

        function names = profile_names(missions)
        %PROFILE_NAMES  Profile keys under the missions object, excluding the
        %   "_"-prefixed documentation fields (jsondecode renames "_comment" to
        %   the valid identifier "x_comment", so filter both prefixes).
            f = string(fieldnames(missions));
            names = f(~startsWith(f, "_") & ~startsWith(f, "x_"));
        end

        function s = as_struct_array(segments)
        %AS_STRUCT_ARRAY  Normalize jsondecode's output to a 1xN struct array.
        %   jsondecode returns a cell array when the segment objects have
        %   heterogeneous fields (ours do), and a plain struct array only when
        %   every object shares one field set. Handle both so the caller always
        %   iterates a struct array. Mirrors ConstraintSetImporter.as_struct_array.
            if iscell(segments)
                s = repmat(struct(), 1, numel(segments));
                for i = 1:numel(segments)
                    fields = fieldnames(segments{i});
                    for f = 1:numel(fields)
                        s(i).(fields{f}) = segments{i}.(fields{f});
                    end
                end
            else
                s = reshape(segments, 1, []);
            end
        end

    end

end
