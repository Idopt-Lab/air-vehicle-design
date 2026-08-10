classdef F16ConstraintSet
%F16CONSTRAINTSET  The F-16's constraint-condition -> ConstraintType map.
%
%   Layer-2 (aircraft-specific) data only. This class no longer builds
%   constraint objects itself -- that is now generic Layer-1 work done by
%   ConstraintAnalysis.from_requirements(aero, prop, json_path, classMap,
%   WS_range), which reads examples/F16A/jsons/f16a_requirements.json and, for
%   each condition, dispatches to the ConstraintType the map selects. This
%   class supplies only that map: which specific constraint class models each
%   of the F-16's named conditions.
%
%   Typical use (see any design_study_*.m or run_F16_constraint_diagram.m):
%       ca = ConstraintAnalysis.from_requirements(aero, prop, ...
%                f16a_requirements_path(), F16ConstraintSet.constraint_map(), ...
%                PointPerformanceBase.WS_RANGE_BRANDT);
%
%   The map is keyed on the ConstraintType enum, so only IMPLEMENTED constraint
%   classes can be selected (a not-yet-written class is a definition-time error
%   in ConstraintType, not a run-time failure). The F-16's six thrust rows map
%   to the Master-Equation subtree by their physics -- Max Mach/Cruise/Max Alt
%   are level flight (n=1, Ps=0), Combat Turn 1/2 are sustained turns (n>1),
%   Excess Power is a specific-excess-power demand (Ps>0); the two field rows
%   map to Takeoff/Landing.
%
%   STALL IS NOT AN F-16 DIAGRAM CONSTRAINT: the requirements JSON carries no
%   Stall condition, so none is built (selection is driven by the JSON; a
%   condition it does not list is simply not built -- there is no includeStall
%   flag). Stall was removed because at L2/L3 its wall sits on AeroL2/L3's
%   geometry-based CLEAN CLmax estimate (~0.91 vs L1's Roskam-table ~1.50),
%   which put the wall at W/S ~ 62 psf and spuriously bound the optimum (vs.
%   Brandt's W/S = 104.59). The fix belongs in aerodynamics (clean-CLmax root
%   cause, ToDo_Darshan.md §3); re-add a Stall condition to the JSON once it
%   lands. StallConstraint.m still exists and is unit-tested standalone.

    methods (Static)

        function m = constraint_map()
        %CONSTRAINT_MAP  The F-16's condition-name -> ConstraintType map (the 8
        %   diagram conditions). See the class header for the thrust-row -> class
        %   rationale and for why Stall is not among them.
            m = dictionary;
            m("Max Mach")                   = ConstraintType.LevelFlight;
            m("Cruise")                     = ConstraintType.LevelFlight;
            m("Max Alt")                    = ConstraintType.LevelFlight;
            m("Combat Turn 1 (subsonic)")   = ConstraintType.SustainedTurn;
            m("Combat Turn 2 (supersonic)") = ConstraintType.SustainedTurn;
            m("Excess Power")               = ConstraintType.ExcessPower;
            m("Takeoff")                    = ConstraintType.Takeoff;
            m("Landing")                    = ConstraintType.Landing;
        end

    end

end
