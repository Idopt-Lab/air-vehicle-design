classdef F16ASourceKind
%F16ASOURCEKIND Why a physical part exists -- the Rationale vocabulary.
%   The vocabulary for F16A_PhysicalProps.Rationale.SourceKind, which makes
%   "why does this part exist?" a queryable fact about the model. Every
%   component in physical/F16A_Physical.slx carries one of these six answers:
%     RealizesFunction         A logical role, and through it a function, has
%                              to be realized by something concrete.
%     SatisfiesRequirement     A requirement demands the part directly.
%     TradeWinner              It WON the physical trade study.
%     TradeAlternative         It LOST, and losers stay in the model so the
%                              decision remains auditable (D-002).
%     ConstraintDriven         Building an airplane at all requires it.
%     SupportingInfrastructure It serves OTHER parts and realizes no role.
%
%   Write "F16ASourceKind.TradeWinner" or "'TradeWinner'". It reads back WITH
%   quotes: erase(string(getProperty(c, "...")), "'"). See F16ADATAPROVENANCE.

    enumeration
        RealizesFunction
        SatisfiesRequirement
        TradeWinner
        TradeAlternative
        ConstraintDriven
        SupportingInfrastructure
    end
end
