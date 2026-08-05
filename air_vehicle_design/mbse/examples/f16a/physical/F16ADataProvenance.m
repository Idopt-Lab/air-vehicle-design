classdef F16ADataProvenance
%F16ADATAPROVENANCE Where a number came from -- the provenance vocabulary.
%   The controlled vocabulary for the `DataProvenance` property, which every
%   value-bearing P stereotype declares -- TradeCandidate (D-007), FuelTank
%   (D-023), Material (D-031) and PhysicalItem (D-052). The Physical layer is
%   the only layer that carries numbers, so it is the layer that must say where
%   each number came from: no agent and no author gets to introduce a value
%   without tagging its source (decision D-007). A tag of Estimate is
%   permitted, but every Estimate must also be listed in docs/07_decision_log.md
%   -- an unexplained guess and a sourced figure must not look alike in the
%   model.
%
%   The four members, strongest evidence first:
%     Datasheet    A manufacturer or programme datasheet figure.
%     Reference    Traceable to the Brandt F-16A ground truth carried in
%                  sizing/VnV/BrandtF16A/ (this repo's reference aircraft).
%     Simulation   The output of an analysis or roll-up in this repo.
%     Estimate     An illustrative teaching value. NOT F-16 data, must never be
%                  cited as such, and must appear in the decision log.
%
%   WRITE/READ CONVENTION (measured, R2026a). Identical to F16ASourceKind:
%   write fully qualified and unquoted ("F16ADataProvenance.Reference") or as a
%   quoted bare member ("'Reference'"); read back with the surrounding quotes
%   stripped, erase(string(getProperty(...)), "'").
%
%   A plain MATLAB enumeration (no int32 base) is enough for System Composer's
%   addProperty(..., Type="F16ADataProvenance"); the classdef only has to be on
%   the MATLAB path whenever the profile is loaded. It sits in physical/, which
%   is on the f16a project path.
%
%   See also F16ASOURCEKIND, generate_f16a_physical.

    enumeration
        Datasheet
        Reference
        Estimate
        Simulation
    end
end
