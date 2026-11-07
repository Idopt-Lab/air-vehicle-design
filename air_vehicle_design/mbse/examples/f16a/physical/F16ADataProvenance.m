classdef F16ADataProvenance
%F16ADATAPROVENANCE Where a number came from -- the provenance vocabulary.
%   The vocabulary for the DataProvenance property that every value-bearing
%   P stereotype declares. P is the only layer that carries numbers, so it is
%   the layer that must say where each came from: an unexplained guess and a
%   sourced figure must not look alike in the model.
%
%   The four members, strongest evidence first:
%     Datasheet    A manufacturer or programme datasheet figure.
%     Reference    Traceable to the Brandt F-16A ground truth in
%                  sizing/VnV/BrandtF16A/ (this repo's reference aircraft).
%     Simulation   The output of an analysis or roll-up in this repo.
%     Estimate     An illustrative teaching value. NOT F-16 data, and must
%                  never be cited as such.
%
%   Written and read like F16ASourceKind; see also F16ASOURCEKIND.

    enumeration
        Datasheet
        Reference
        Estimate
        Simulation
    end
end
