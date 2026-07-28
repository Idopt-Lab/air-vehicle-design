classdef F16ASourceKind
%F16ASOURCEKIND Why a physical part exists -- the Rationale vocabulary.
%   The controlled vocabulary for F16A_PhysicalProps.Rationale.SourceKind, the
%   property that makes "why does this part exist?" a QUERYABLE fact about the
%   model instead of a code comment (decision D-006). Every component in
%   physical/F16A_Physical.slx carries exactly one of these six answers.
%
%   The six members, and the question each one answers:
%     RealizesFunction         The part exists because a logical role (and,
%                              through it, a function) has to be realized by
%                              something concrete. TraceRef names the role.
%     SatisfiesRequirement     The part exists because a requirement demands
%                              it directly. TraceRef names the requirement.
%     TradeWinner              The part exists because it WON the physical
%                              trade study -- the selected candidate for a
%                              variant role.
%     TradeAlternative         The part exists because it LOST, and a rejected
%                              alternative is kept in the model so the decision
%                              stays auditable (set-based design; the losers
%                              are not deleted).
%     ConstraintDriven         The part exists because of a constraint of
%                              building an airplane at all -- ground handling,
%                              geometry, regulation -- not because of any
%                              function above it.
%     SupportingInfrastructure The part exists only to serve OTHER parts. It
%                              realizes no logical role; TraceRef points at the
%                              part(s) it serves, not at a role or requirement.
%
%   TradeAlternative was added to the original five so a losing candidate can
%   state what it is (D-006). TradeWinner/TradeAlternative are unused until the
%   candidates appear -- they are declared here so the vocabulary is complete
%   before the parts that need them exist.
%
%   WRITE/READ CONVENTION (measured, R2026a). A stereotype property of this
%   type is WRITTEN either fully qualified and unquoted --
%       setProperty(c, "F16A_PhysicalProps.Rationale.SourceKind", ...
%           "F16ASourceKind.SupportingInfrastructure")
%   -- or as a quoted bare member ("'SupportingInfrastructure'"); any other
%   form errors. It READS BACK WITH SURROUNDING QUOTES, like a string property,
%   so strip them:
%       kind = erase(string(getProperty(c, "...SourceKind")), "'");
%   the same convention MeasureOfMerit.Goal already uses.
%
%   A plain MATLAB enumeration (no int32 base) is enough for System Composer's
%   addProperty(..., Type="F16ASourceKind") -- the only requirement is that
%   this classdef is on the MATLAB path whenever the profile is loaded. It sits
%   in physical/, which is on the f16a project path.
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
