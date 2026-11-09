classdef F16ADataProvenance
%F16ADATAPROVENANCE The provenance vocabulary: the source of a number.
%   This is the vocabulary for the DataProvenance property that each
%   value-bearing P stereotype declares. P is the only layer that carries
%   numbers. Thus P must give the source of each number. In the model, an
%   unexplained guess and a sourced figure must not look the same.
%
%   The four members, from the strongest evidence to the weakest:
%     Datasheet    A figure from a manufacturer or programme datasheet.
%     Reference    Traceable to the Brandt F-16A ground truth in
%                  sizing/VnV/BrandtF16A/ (the reference aircraft of this
%                  repository).
%     Simulation   The output of an analysis or roll-up in this repository.
%     Estimate     An illustrative teaching value. It is not F-16 data. Do not
%                  cite it as F-16 data.
%
%   Write and read values as for F16ASourceKind. See also F16ASOURCEKIND.

    enumeration
        Datasheet
        Reference
        Estimate
        Simulation
    end
end
