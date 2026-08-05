classdef ConstraintSetImporter
%CONSTRAINTSETIMPORTER  Reads constraint conditions from a requirements JSON.
%
%   Generic Layer-1 utility. Any aircraft's constraint requirements (one
%   object per point-performance/field/stall condition) can be read with this,
%   as long as the file follows the requirements-JSON layout the F-16 uses
%   (examples/F16A/jsons/f16a_requirements.json): a top-level "constraints"
%   block whose "conditions" member is an array of condition objects. Each
%   object carries REQUIREMENT / CONDITION data ONLY -- the flight condition
%   and the field-performance requirement -- keyed by explicit field names
%   (name, category, altitude_ft, mach, beta, and per condition kind n / Ps_fps
%   / power_setting or distance_ft / mu / k_factor / mach_liftoff). It carries
%   NO discipline-owned quantity (no CLmax, CD0, K1, K2, CDx, thrust-lapse
%   alpha, or TSFC): those come from the injected aero/prop objects at run
%   time. See examples/F16A/mds/f16a_requirements.md for the schema and
%   per-field citations.
%
%   Aircraft-specific wiring of each condition into a concrete constraint
%   object is a Layer-2 concern -- see examples/F16A/F16ConstraintSet.m.
%
%   Deliberately thin: it does NOT append atmosphere columns (temperature,
%   density, dynamic pressure) -- AircraftState derives those from
%   altitude+Mach with its own citations (Mattingly Eq. 2.52). This class only
%   decodes the raw per-condition requirement fields.

    methods (Static)

        function conditions = read_conditions(json_path)
        %READ_CONDITIONS  Read the constraint conditions from a requirements
        %   JSON into a struct array, one element per condition.
        %   json_path -- path to the requirements JSON (e.g. the value of
        %                f16a_requirements_path()).
        %
        %   Returns a struct array whose fields are the explicit condition
        %   keys present in the JSON (name, category, altitude_ft, and the
        %   per-condition-kind fields). Because the conditions do not all
        %   carry the same keys (a thrust row has n/Ps_fps/power_setting; a
        %   field row has distance_ft/mu/k_factor; Stall carries mach only),
        %   the elements are read one at a time and left as a struct array in
        %   file order -- the caller reads whichever keys the condition it is
        %   building needs, and tests presence with isfield.
            arguments
                json_path (1,1) string {mustBeNonzeroLengthText}
            end

            raw = jsondecode(fileread(json_path));

            if ~isfield(raw, 'constraints') || ~isfield(raw.constraints, 'conditions')
                error('ConstraintSetImporter:missingConstraintsBlock', ...
                    ['Requirements JSON "%s" has no constraints.conditions block. ', ...
                     'A constraint requirements file must carry a top-level ', ...
                     '"constraints" object with a "conditions" array.'], json_path);
            end

            conditions = ConstraintSetImporter.as_struct_array(raw.constraints.conditions);
        end

    end

    methods (Static, Access = private)

        function s = as_struct_array(conditions)
        %AS_STRUCT_ARRAY  Normalize jsondecode's output to a 1xN struct array.
        %   jsondecode returns a cell array when the condition objects have
        %   heterogeneous fields (the F-16 set -- thrust vs field vs stall
        %   rows differ), and a plain struct array only when every object
        %   shares one field set. Handle both so the caller always iterates a
        %   struct array.
            if iscell(conditions)
                s = repmat(struct(), 1, numel(conditions));
                for i = 1:numel(conditions)
                    fields = fieldnames(conditions{i});
                    for f = 1:numel(fields)
                        s(i).(fields{f}) = conditions{i}.(fields{f});
                    end
                end
            else
                s = reshape(conditions, 1, []);
            end
        end

    end

end
