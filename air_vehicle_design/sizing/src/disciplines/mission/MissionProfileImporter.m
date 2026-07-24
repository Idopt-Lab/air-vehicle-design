classdef MissionProfileImporter
%MISSIONPROFILEIMPORTER  Generic Layer-1 IO for a mission profile (any
%   aircraft, any segment sequence matching the documented schema -- NOT
%   specific to the F-16's CAP mission, which is just one example instance).
%
%   Generic Layer-1 utility (mirrors ConstraintSetImporter's role and its
%   "deliberately thin" philosophy -- see src/constraints/ConstraintSetImporter.m):
%   any aircraft's mission profile (segment names, per-segment altitude/
%   Mach, given range/time, payload drop, dry-or-wet AB flag, plus scalar
%   high-lift/ground-roll constants) can be read with this, as long as the
%   source follows the same schema examples/F16A/mission_profile.json uses.
%   Aircraft-specific wiring into a concrete F16MissionL1/L2/L3 object is a
%   Layer-2 concern (each class's own constructor).
%
%   Deliberately thin, same precedent as ConstraintSetImporter: does NOT
%   compute or append atmosphere columns (temperature, density, q, ...) --
%   AircraftState already derives those from altitude+Mach with its own
%   citations (Mattingly Eq. 2.52), so recomputing them here would duplicate
%   that logic. Only the raw per-segment columns and scalar constants are
%   read. See docs/subplans/07_mission_analysis.md's "File-I/O" section.
%
%   TWO SOURCE FORMATS, ONE FUNCTIONING TODAY:
%     read_json(filepath)  -- IMPLEMENTED. mission_profile.json is the
%       actual input F16MissionL1/L2/L3 read from right now; its schema
%       (arrays keyed by a common segment_names index, plus scalar spec
%       constants) is documented inline below and in the JSON file's own
%       header comments.
%     read_excel(filepath, sheet) -- STUB ONLY (judgment call, see this
%       pass's report). Building a real Mission_Profile.xlsx reader
%       (mirroring legacy MissionAnalysisModel.get_mission_data's
%       readtable/readcell orientation, segments-as-columns, MINUS the
%       atmosphere-column computation it did) is not necessary yet: JSON is
%       the established per-discipline input convention already used by
%       Geometry (geometry_L2.json) and now Mission, and no F16MissionL*
%       class needs to read the .xlsx directly at this stage. Left as a
%       clearly-flagged TODO rather than built speculatively, per PLAN.md's
%       "no feature added beyond what the current step requires" rule.

    methods (Static)

        function S = read_json(filepath)
        %READ_JSON  Read a mission_profile.json-shaped file into a struct.
        %   filepath -- path to the JSON file (e.g. examples/F16A/mission_profile.json).
        %   Returns the decoded struct as-is (field names match the JSON
        %   schema exactly: segment_names, alt_ft, mach_end, dist_nm_given,
        %   time_min_given, drop_lb, dry_or_wet, CLmax_TO, CLmax_land,
        %   mu_rolling, liftoff_factor, warmup_fuel_per_engine_lb, RFF, plus
        %   "_"-prefixed documentation/provenance fields the caller should
        %   ignore). No atmosphere columns are computed -- see class header.
            arguments
                filepath (1,1) string
            end
            if ~isfile(filepath)
                error("MissionProfileImporter:fileNotFound", ...
                    "Mission profile JSON not found: %s", filepath);
            end
            S = jsondecode(fileread(filepath));
        end

        function T = read_excel(filepath, sheet)
        %READ_EXCEL  STUB -- Mission_Profile.xlsx reading is not yet
        %   implemented. See class header for why.
        %   TODO(future pass): implement by carrying forward
        %   MissionAnalysisModel.get_mission_data's readtable/readcell
        %   orientation (segments as COLUMNS, quantities as ROWS -- unlike
        %   Constraints.xlsx's row-per-condition layout) and the
        %   Dry-or-Wet row extraction, but DROP the manual atmosisa-into-
        %   table step (see class header's "deliberately thin" note).
            arguments
                filepath (1,1) string
                sheet    (1,1) string   % no default -- generic Layer-1 utility; caller supplies the sheet name for its own mission workbook (e.g. "CAP" for the F-16 example)
            end
            error("MissionProfileImporter:notImplemented", ...
                "read_excel is a stub -- Mission_Profile.xlsx reading is not yet implemented. Use read_json(filepath) against examples/F16A/mission_profile.json instead.");
        end

    end

end
