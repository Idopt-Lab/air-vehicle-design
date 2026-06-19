function S = tableToNestedStruct(T, opts)
%TABL ETONESTEDSTRUCT Convert a table into a nested struct.
%
% Supports tables shaped like:
%   - variables = entities, row names = attributes
%   - rows = entities, variables = attributes
%   - tables with no row names, using a key column instead
%
% Examples:
%   S = tableToNestedStruct(T);
%   S = tableToNestedStruct(T, Orientation="variables");
%   S = tableToNestedStruct(T, Orientation="rows", KeySource="firstvar");
%   S = tableToNestedStruct(T, NameTransform=@(s) lower(string(matlab.lang.makeValidName(s))));
%
% Output pattern:
%   Orientation="variables"  -> S.<VariableName>.<RowName>
%   Orientation="rows"       -> S.<RowName>.<VariableName>

    arguments
        T table
        opts.Orientation (1,1) string {mustBeMember(opts.Orientation, ["auto","variables","rows"])} = "auto"
        opts.KeySource   (1,1) string {mustBeMember(opts.KeySource, ["auto","rownames","firstvar"])} = "auto"
        opts.KeyVariable = ""     % used only if KeySource="firstvar"
        opts.NameTransform function_handle = @defaultNameTransform
        opts.DropKeyVariable (1,1) logical = true
        opts.UnwrapScalarCells (1,1) logical = true
        opts.PreserveLabels (1,1) logical = true
        opts.RecurseTables (1,1) logical = false
    end

    S = struct();

    hasRowNames = ~isempty(T.Properties.RowNames);

    % Resolve key source
    keySource = opts.KeySource;
    if keySource == "auto"
        if hasRowNames
            keySource = "rownames";
        else
            keySource = "firstvar";
        end
    end

    % Resolve orientation
    orientation = opts.Orientation;
    if orientation == "auto"
        % Good default:
        % - if row names exist, treat variables as top-level fields
        % - otherwise treat rows (via key variable) as top-level fields
        if keySource == "rownames"
            orientation = "variables";
        else
            orientation = "rows";
        end
    end

    % Get row/entity labels
    switch keySource
        case "rownames"
            rowLabels = string(T.Properties.RowNames);
            dataTable = T;

        case "firstvar"
            if opts.KeyVariable == ""
                keyVar = string(T.Properties.VariableNames{1});
            else
                keyVar = string(opts.KeyVariable);
            end

            rowLabels = extractLabelsFromVariable(T.(keyVar));

            if opts.DropKeyVariable
                dataTable = removevars(T, keyVar);
            else
                dataTable = T;
            end
    end

    varLabels = string(dataTable.Properties.VariableNames);

    % Check uniqueness after name transform
    rowFields = makeUniqueFieldNames(rowLabels, opts.NameTransform);
    varFields = makeUniqueFieldNames(varLabels, opts.NameTransform);

    if orientation == "variables"
        for c = 1:numel(varLabels)
            outer = varFields(c);
            for r = 1:height(dataTable)
                inner = rowFields(r);
                value = dataTable{r, c};
                value = postprocessValue(value, opts.UnwrapScalarCells, opts.RecurseTables);
                S.(outer).(inner) = value;
            end
        end

        if opts.PreserveLabels
            S.meta.orientation = "variables";
            S.meta.outerLabels.original = cellstr(varLabels);
            S.meta.outerLabels.fields   = cellstr(varFields);
            S.meta.innerLabels.original = cellstr(rowLabels);
            S.meta.innerLabels.fields   = cellstr(rowFields);
        end

    else % orientation == "rows"
        for r = 1:height(dataTable)
            outer = rowFields(r);
            for c = 1:numel(varLabels)
                inner = varFields(c);
                value = dataTable{r, c};
                value = postprocessValue(value, opts.UnwrapScalarCells, opts.RecurseTables);
                S.(outer).(inner) = value;
            end
        end

        if opts.PreserveLabels
            S.meta.orientation = "rows";
            S.meta.outerLabels.original = cellstr(rowLabels);
            S.meta.outerLabels.fields   = cellstr(rowFields);
            S.meta.innerLabels.original = cellstr(varLabels);
            S.meta.innerLabels.fields   = cellstr(varFields);
        end
    end
end


function labels = extractLabelsFromVariable(v)
    if isstring(v) || ischar(v)
        labels = string(v);
    elseif iscellstr(v)
        labels = string(v);
    elseif iscell(v)
        labels = strings(size(v));
        for i = 1:numel(v)
            labels(i) = string(v{i});
        end
    elseif iscategorical(v)
        labels = string(v);
    else
        error("Key variable must contain text-like labels.");
    end
end


function value = postprocessValue(value, unwrapScalarCells, recurseTables)
    if unwrapScalarCells && iscell(value) && isscalar(value)
        value = value{1};
    end

    if recurseTables && istable(value)
        value = tableToNestedStruct(value);
    end
end


function fields = makeUniqueFieldNames(labels, transformFcn)
    labels = string(labels);
    fields = strings(size(labels));

    used = containers.Map('KeyType','char','ValueType','double');

    for i = 1:numel(labels)
        f = string(transformFcn(labels(i)));

        if strlength(f) == 0
            f = "x";
        end

        key = char(f);
        if isKey(used, key)
            used(key) = used(key) + 1;
            f = f + "_" + string(used(key));
        else
            used(key) = 1;
        end

        fields(i) = f;
    end
end


function out = defaultNameTransform(label)
    % General-purpose, conservative:
    % preserve meaning, just make it a valid field name
    out = string(matlab.lang.makeValidName(string(label), 'ReplacementStyle', 'delete'));
end