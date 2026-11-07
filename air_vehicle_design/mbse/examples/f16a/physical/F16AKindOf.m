function kind = F16AKindOf(candidate)
%F16AKINDOF The logical kind a physical candidate realizes.
%   KIND = F16AKINDOF(CANDIDATE) returns the name of the L-layer kind (for
%   example "SingleEngine") that the P-layer CANDIDATE component realizes.
%   The answer is an allocation edge, kind -> candidate, in the L->P
%   allocation set; open it with systemcomposer.allocation.editor to see them.
%
%   The trade studies use it to carry a P decision back up to L: the winner's
%   kind becomes the active choice of the logical role. Several candidates may
%   realize one kind -- two engines are both SingleEngine -- so the kind, not
%   the candidate name, is the key into L.

ALLOCSET = "F16A_LogicalToPhysical";

allocSet = systemcomposer.allocation.AllocationSet.find(ALLOCSET);
if isempty(allocSet)
    allocSet = systemcomposer.allocation.load( ...
        fullfile(f16aRoot(), "physical", ALLOCSET + ".mldatx"));
end

sources = getAllocatedFrom(allocSet.Scenarios(1), candidate);
if numel(sources) ~= 1
    error("F16AKindOf:notOneKind", ...
        "%s should be allocated from exactly one logical kind in %s, but has %d.", ...
        candidate.Name, ALLOCSET, numel(sources));
end
kind = string(sources.Name);
end
