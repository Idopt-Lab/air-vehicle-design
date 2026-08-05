function [names, values] = F16AStereotypeLeaves(comp, stereotype, propNames)
%F16ASTEREOTYPELEAVES Parts at or under COMP that carry STEREOTYPE.
%   [NAMES, VALUES] = F16ASTEREOTYPELEAVES(COMP, STEREOTYPE, PROPNAMES) walks
%   the architecture under COMP and returns one row per component carrying
%   STEREOTYPE (a short name, "Material" or "FuelTank"). NAMES is a column of
%   component names; VALUES is numeric with one column per PROPNAMES entry
%   (fully qualified property names).
%
%   A component carrying the stereotype IS a leaf and is not descended into, so
%   a lumped part stating one whole-block value and a decomposed group stating
%   one per cell use the same walk -- no list of part names anywhere.
%
%   Variant-safe on the two counts that matter (Stage-0 findings 2 and 6): a
%   VariantComponent is replaced by its ACTIVE choice, never expanded into all
%   of them, and its children are never reached through .Architecture
%   .Components, which returns zero on a saved-and-reloaded model.
%
%   The materials and fuel roll-ups both need this walk. It lives here so the
%   variant rule is fixed in ONE place -- fixing one copy and not the other is
%   the D-038 failure mode.
%   See also F16APHYSICALMATERIALSROLLUP, F16APHYSICALFUELROLLUP.

names  = strings(0,1);
values = zeros(0, numel(propNames));

if isa(comp, "systemcomposer.arch.VariantComponent")
    [names, values] = F16AStereotypeLeaves(getActiveChoice(comp), stereotype, propNames);
    return;
end

% getStereotypes returns a cell array of '<profile>.<stereotype>'.
applied = reshape(string(getStereotypes(comp)), 1, []);
if any(endsWith(applied, "." + stereotype))
    names  = string(comp.Name);
    values = zeros(1, numel(propNames));
    for i = 1:numel(propNames)
        values(i) = str2double(string(getProperty(comp, char(propNames(i)))));
    end
    return;
end

for k = comp.Architecture.Components
    [n, v] = F16AStereotypeLeaves(k, stereotype, propNames);
    names  = [names;  n];   %#ok<AGROW>
    values = [values; v];   %#ok<AGROW>
end
end
