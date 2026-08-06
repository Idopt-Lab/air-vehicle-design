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
%   STALL IS EXCLUDED BY DEFAULT: constraint_map() omits the Stall condition,
%   so it is not built (a condition absent from the map is simply skipped --
%   there is no includeStall flag anymore). Stall has no Brandt reference row
%   to validate its CLmax against, and at L2/L3 its wall sits on AeroL2/L3's
%   geometry-based CLEAN CLmax estimate (~0.91 vs L1's Roskam-table ~1.50 --
%   see F16AeroL2.m/F16AeroL3.m). That low CLmax put Stall's wall at
%   W/S~=62-64 psf, tighter than every real condition, so with Stall in the
%   set it silently became the BINDING constraint and pulled the reported
%   optimum to W/S~=62 at L2/L3 (vs. Brandt's W/S=104.59). Use
%   constraint_map_with_stall() to add it back as a sanity-check overlay, but
%   note it will again dominate optimal_point() at L2/L3. The underlying
%   clean-CLmax gap is tracked in ToDo_Darshan.md §3.

    methods (Static)

        function m = constraint_map()
        %CONSTRAINT_MAP  The F-16's condition-name -> ConstraintType map, Stall
        %   excluded (the 8 diagram conditions). See class header for why Stall
        %   is left out by default and for the thrust-row -> class rationale.
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

        function m = constraint_map_with_stall()
        %CONSTRAINT_MAP_WITH_STALL  constraint_map() plus the Stall wall
        %   (StallConstraint), for a 9-condition sanity-check overlay. Stall
        %   tends to dominate the optimum at L2/L3 -- see class header.
            m = F16ConstraintSet.constraint_map();
            m("Stall") = ConstraintType.Stall;
        end

    end

end
