classdef F16ADataProvenance
%F16ADATAPROVENANCE Where a number came from -- the provenance vocabulary.
%   The controlled vocabulary for the DataProvenance property, which every
%   value-bearing P stereotype declares: TradeCandidate (D-007), FuelTank
%   (D-023), Material (D-031) and PhysicalItem (D-052). P is the only layer
%   that carries numbers, so it is the layer that must say where each came
%   from. An Estimate is permitted, but every Estimate must also be listed in
%   docs/07_decision_log.md -- an unexplained guess and a sourced figure must
%   not look alike in the model.
%
%   The four members, strongest evidence first:
%     Datasheet    A manufacturer or programme datasheet figure.
%     Reference    Traceable to the Brandt F-16A ground truth in
%                  sizing/VnV/BrandtF16A/ (this repo's reference aircraft).
%     Simulation   The output of an analysis or roll-up in this repo.
%     Estimate     An illustrative teaching value. NOT F-16 data, and must
%                  never be cited as such.
%
%   Write/read convention: identical to F16ASourceKind, which documents it.
%
%   See also F16ASOURCEKIND, generate_f16a_physical.

    enumeration
        Datasheet
        Reference
        Estimate
        Simulation
    end
end
