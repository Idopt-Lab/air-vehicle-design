classdef B777ConstraintSet
%B777CONSTRAINTSET  The B777's constraint-condition -> ConstraintType map.
%
%   Layer-2 (aircraft-specific) data only, mirroring F16ConstraintSet. This class
%   does not build constraint objects itself -- that is generic Layer-1 work done
%   by ConstraintAnalysis.from_requirements(aero, prop, req_path, classMap,
%   WS_range), which reads examples/B777/inputs/b777_requirements.json and, for
%   each condition, dispatches to the ConstraintType this map selects. This class
%   supplies only that map: which concrete constraint class models each of the
%   B777's named conditions.
%
%   Typical use:
%       ca = ConstraintAnalysis.from_requirements(aero, prop, ...
%                b777_requirements_path(), B777ConstraintSet.constraint_map(), ...
%                WS_range);
%
%   The map is keyed on the ConstraintType enum, so only IMPLEMENTED constraint
%   classes can be selected (a not-yet-written class is a definition-time error
%   in ConstraintType, not a run-time failure).
%
%   B777 vs F-16 CLASS CHOICES (b777_requirements.md §§2-3):
%     * FAR-25 STATISTICAL field-length classes (TakeoffFieldLengthConstraint /
%       LandingFieldLengthConstraint, metabook Eqs. 4.14-4.19/4.45-4.48), NOT the
%       Mattingly/Roskam ground-roll siblings (Takeoff/Landing) the F-16 uses.
%     * SIX FAR-25 climb segments, all ClimbGradient (Eqs. 4.49-4.54): the
%       balked-landing/2nd-segment/enroute rows differ only in G/ks/config/oei,
%       which the requirements JSON carries per row -- one class, six conditions.
%     * Ceiling -> Ceiling (minimum-T/W horizontal line, Eq. 4.30/4.56).
%     * Cruise -> LevelFlight (n = 1, Ps = 0, Eq. 4.57).
%
%   The keys below are the EXACT condition "name" strings in
%   b777_requirements.json .constraints.conditions -- they must match verbatim
%   for from_requirements to dispatch.

    methods (Static)

        function m = constraint_map()
        %CONSTRAINT_MAP  The B777's condition-name -> ConstraintType map (the 10
        %   diagram conditions). See the class header for the class-choice
        %   rationale. Keys match b777_requirements.json verbatim.
            m = dictionary;
            m("Takeoff Field Length")                = ConstraintType.TakeoffFieldLength;
            m("Landing Field Length")                = ConstraintType.LandingFieldLengthFAR25;
            m("Climb 1 (takeoff, FAR 25.111)")       = ConstraintType.ClimbGradient;
            m("Climb 2 (transition, FAR 25.121)")    = ConstraintType.ClimbGradient;
            m("Climb 3 (2nd segment, FAR 25.121)")   = ConstraintType.ClimbGradient;
            m("Climb 4 (enroute, FAR 25.121)")       = ConstraintType.ClimbGradient;
            m("Climb 5 (AEO balked landing, FAR 25.119)") = ConstraintType.ClimbGradient;
            m("Climb 6 (OEI balked landing, FAR 25.121)") = ConstraintType.ClimbGradient;
            m("Ceiling")                             = ConstraintType.Ceiling;
            m("Cruise")                              = ConstraintType.LevelFlight;
        end

    end

end
