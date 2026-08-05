classdef F16ASourceKind
%F16ASOURCEKIND Why a physical part exists -- the Rationale vocabulary.
%   The controlled vocabulary for F16A_PhysicalProps.Rationale.SourceKind, the
%   property that makes "why does this part exist?" a QUERYABLE fact about the
%   model instead of a code comment (D-006). Every component in
%   physical/F16A_Physical.slx carries exactly one of these six answers:
%     RealizesFunction         A logical role, and through it a function, has
%                              to be realized by something concrete.
%     SatisfiesRequirement     A requirement demands the part directly.
%     TradeWinner              It WON the physical trade study.
%     TradeAlternative         It LOST, and losers stay in the model so the
%                              decision remains auditable (D-002).
%     ConstraintDriven         Building an airplane at all requires it.
%     SupportingInfrastructure It serves OTHER parts and realizes no role.
%
%   WRITE/READ CONVENTION (measured, R2026a). Write fully qualified and
%   unquoted, "F16ASourceKind.SupportingInfrastructure", or as a quoted bare
%   member, "'SupportingInfrastructure'"; anything else errors. It reads back
%   WITH quotes, so strip them: erase(string(getProperty(c, "...")), "'").
%
%   See also F16ADATAPROVENANCE, generate_f16a_physical.

    enumeration
        RealizesFunction
        SatisfiesRequirement
        TradeWinner
        TradeAlternative
        ConstraintDriven
        SupportingInfrastructure
    end
end
