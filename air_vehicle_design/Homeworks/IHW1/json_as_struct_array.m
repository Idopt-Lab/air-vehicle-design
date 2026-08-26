function s = json_as_struct_array(items)
%JSON_AS_STRUCT_ARRAY  Normalize jsondecode output to a 1xN struct array.
%   jsondecode returns a cell array when the objects have heterogeneous
%   fields, and a plain struct array when every object shares one field set.
%   Return a 1xN struct array in both cases so callers always iterate one.
%   Shared by ConstraintSetImporter (constraint conditions) and
%   MissionProfileReader (mission segments).
    if iscell(items)
        s = repmat(struct(), 1, numel(items));
        for i = 1:numel(items)
            fields = fieldnames(items{i});
            for f = 1:numel(fields)
                s(i).(fields{f}) = items{i}.(fields{f});
            end
        end
    else
        s = reshape(items, 1, []);
    end
end
