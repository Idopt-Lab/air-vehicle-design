classdef ConstraintSetImporter
%CONSTRAINTSETIMPORTER  Reads constraint conditions from a requirements JSON.
%
%   Generic Layer-1 utility. Reads any aircraft's constraint requirements from
%   the requirements-JSON layout the F-16 uses
%   (examples/F16A/inputs/f16a_requirements.json): a top-level "constraints"
%   block whose "conditions" member is an array of condition objects. Each
%   object carries REQUIREMENT / CONDITION data only (flight condition +
%   field-performance requirement), keyed by explicit field names. It carries
%   NO discipline-owned quantity (no CLmax, CD0, K1, K2, alpha, TSFC): those
%   come from the injected aero/prop objects at run time. Schema and per-field
%   citations: examples/F16A/inputs/f16a_requirements.md.
%
%   Wiring each condition into a concrete constraint is a Layer-2 concern --
%   see examples/F16A/models/sizing/F16ConstraintSet.m.
%
%   Thin: it does NOT append atmosphere columns -- AircraftState derives those
%   from altitude+Mach (Mattingly Eq. 2.52).

    methods (Static)

        function conditions = read_conditions(json_path)
        %READ_CONDITIONS  Read the constraint conditions from a requirements
        %   JSON into a struct array, one element per condition.
        %   json_path -- path to the requirements JSON (e.g. the value of
        %                f16a_requirements_path()).
        %
        %   Returns a struct array in file order, one element per condition.
        %   The conditions do not all carry the same keys (a thrust row has
        %   n/Ps_fps/power_setting; a field row has distance_ft/mu/k_factor;
        %   Stall carries mach only), so the caller reads whichever keys it
        %   needs and tests presence with isfield.
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

            conditions = json_as_struct_array(raw.constraints.conditions);
        end

    end

end
