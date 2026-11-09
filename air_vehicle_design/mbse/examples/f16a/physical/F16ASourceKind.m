classdef F16ASourceKind
%F16ASOURCEKIND The Rationale vocabulary: why a physical part exists.
%   This is the vocabulary for F16A_PhysicalProps.Rationale.SourceKind. It
%   makes "why does this part exist?" a fact that you can query in the model.
%   Each component in physical/F16A_Physical.slx has one of these six answers:
%     RealizesFunction         Something concrete must realize a logical role,
%                              and through the role, a function.
%     SatisfiesRequirement     A requirement directly demands the part.
%     TradeWinner              It won the physical trade study.
%     TradeAlternative         It lost. Losers stay in the model so that the
%                              decision stays auditable (D-002).
%     ConstraintDriven         An airplane cannot be built without it.
%     SupportingInfrastructure It serves other parts and realizes no role.
%
%   To set a value, write "F16ASourceKind.TradeWinner" or "'TradeWinner'". The
%   value reads back with quotes. To remove them, use
%   erase(string(getProperty(c, "...")), "'"). See also F16ADATAPROVENANCE.

    enumeration
        RealizesFunction
        SatisfiesRequirement
        TradeWinner
        TradeAlternative
        ConstraintDriven
        SupportingInfrastructure
    end
end
