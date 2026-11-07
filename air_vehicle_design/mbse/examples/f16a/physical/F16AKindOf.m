function kind = F16AKindOf(candidate)
%F16AKINDOF The logical kind a physical candidate realizes.
%   KIND = F16AKINDOF(CANDIDATE) returns the name of the L-layer kind (for
%   example "SingleEngine") that the P-layer CANDIDATE component realizes.
%   The trade studies use it to carry a P decision back up to L: the winner's
%   kind becomes the active choice of the logical role.
%
%   Several candidates may realize one kind -- two engines are both
%   SingleEngine -- so the kind, not the candidate name, is the key into L.

for st = reshape(string(getStereotypes(candidate)), 1, [])
    if endsWith(st, "Candidate")
        kind = erase(string(getProperty(candidate, char(st + ".RealizesKind"))), "'");
        return
    end
end
error("F16AKindOf:noKind", "%s carries no candidate stereotype, so it realizes no kind.", ...
    candidate.Name);
end
