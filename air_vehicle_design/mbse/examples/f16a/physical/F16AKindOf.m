function kind = F16AKindOf(candidate)
%F16AKINDOF Return the logical kind that a physical candidate realizes.
%   KIND = F16AKINDOF(CANDIDATE) returns the name of the L-layer kind (for
%   example "SingleEngine") that the P-layer CANDIDATE component realizes.
%   The answer comes from an allocation edge, kind -> candidate, in the L->P
%   allocation set. To see the edges, open the set with
%   systemcomposer.allocation.editor.
%
%   The trade studies use this function to send a P decision back to L. The
%   kind of the winner becomes the active choice of the logical role. Many
%   candidates can realize one kind, for example two engines are both
%   SingleEngine. Thus the kind, not the candidate name, is the key into L.

ALLOCSET = "F16A_LogicalToPhysical";

allocSet = systemcomposer.allocation.AllocationSet.find(ALLOCSET);
if isempty(allocSet)
    allocSet = systemcomposer.allocation.load( ...
        fullfile(f16aRoot(), "physical", ALLOCSET + ".mldatx"));
end

sources = getAllocatedFrom(allocSet.Scenarios(1), candidate);
if numel(sources) ~= 1
    error("F16AKindOf:notOneKind", ...
        "%s should have an allocation from exactly one logical kind in %s, but it has %d.", ...
        candidate.Name, ALLOCSET, numel(sources));
end
kind = string(sources.Name);
end
