classdef ConstraintType
%CONSTRAINTTYPE  Enumeration of the implemented point-performance constraint
%   classes.
%
%   A requirements-to-constraints map (see ConstraintAnalysis.from_requirements)
%   selects one member per requirements-JSON condition. Keying that map on this
%   enumeration -- rather than a free-form class-name string -- means a caller
%   can ONLY choose a constraint class that is actually implemented: a typo or a
%   not-yet-written class is a definition-time error here, not a run-time feval
%   failure deep in a build loop.
%
%   Each member carries the name of the concrete PointPerformanceBase subclass
%   it builds and delegates construction to that class's static
%   fromCondition(cond, aero, prop) factory, which pulls the fields that class
%   needs from the condition struct and builds its own flight state. Adding a
%   new constraint class is therefore two steps: implement the class with a
%   fromCondition factory, and add one enumeration member here.

    properties (SetAccess = immutable)
        ClassName (1,1) string   % concrete PointPerformanceBase subclass this member builds
    end

    methods

        function obj = ConstraintType(className)
            obj.ClassName = className;
        end

        function c = build(obj, cond, aero, prop)
        %BUILD  Construct the concrete constraint for one requirements-JSON
        %   condition, wiring in the injected aero/prop. Delegates to the target
        %   class's static fromCondition; every constraint class exposes the
        %   same fromCondition(cond, aero, prop) signature, so the dispatch is
        %   uniform (aero-only constraints such as Stall/Landing accept prop and
        %   ignore it).
            c = feval(char(obj.ClassName + ".fromCondition"), cond, aero, prop);
        end

    end

    enumeration
        Takeoff                 ("TakeoffConstraint")
        Landing                 ("LandingConstraint")
        Stall                   ("StallConstraint")
        LevelFlight             ("LevelFlightConstraint")
        SustainedTurn           ("SustainedTurnConstraint")
        ExcessPower             ("ExcessPowerConstraint")
        TakeoffFieldLength      ("TakeoffFieldLengthConstraint")
        LandingFieldLengthFAR25 ("LandingFieldLengthConstraint")
        ClimbGradient           ("ClimbGradientConstraint")
        ManeuveringExcessPower  ("ManeuveringExcessPowerConstraint")
        InstantaneousTurn       ("InstantaneousTurnConstraint")
    end

end
