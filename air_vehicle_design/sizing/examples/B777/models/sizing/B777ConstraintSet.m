classdef B777ConstraintSet
%B777CONSTRAINTSET  The B777's constraint-condition -> ConstraintType map.
%
%   Layer-2 (aircraft-specific) data only, mirroring F16ConstraintSet.
%   ConstraintAnalysis.from_requirements builds the objects; this class supplies
%   only the condition-name -> ConstraintType map, keyed on the ConstraintType
%   enum (only IMPLEMENTED classes can be selected).
%
%   Typical use:
%       ca = ConstraintAnalysis.from_requirements(aero, prop, ...
%                b777_requirements_path(), B777ConstraintSet.constraint_map(), ...
%                WS_range);
%
%   B777 vs F-16 CLASS CHOICES (b777_requirements.md §§2-3):
%     * FAR-25 STATISTICAL field-length classes (TakeoffFieldLengthConstraint /
%       LandingFieldLengthConstraint, metabook Eqs. 4.14-4.19/4.45-4.48).
%     * SIX FAR-25 climb segments, all ClimbGradient (Eqs. 4.49-4.54) -- one
%       class, six conditions differing by G/ks/config/oei in the JSON.
%     * Ceiling -> Ceiling (Eq. 4.30/4.56); Cruise -> LevelFlight (Eq. 4.57).
%
%   Keys below match b777_requirements.json .constraints.conditions verbatim.

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
