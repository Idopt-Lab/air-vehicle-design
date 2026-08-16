classdef Aero481ConstraintSet
%Aero481CONSTRAINTSET  The F-35's constraint-condition -> ConstraintType map.
%
%   Layer-2 (aircraft-specific) data only, mirroring F16ConstraintSet and
%   B777ConstraintSet. ConstraintAnalysis.from_requirements builds the objects;
%   this class supplies only the condition-name -> ConstraintType map. The map is
%   keyed on the ConstraintType enum, so only IMPLEMENTED classes can be selected;
%   every condition maps to an EXISTING class (no new class added).
%
%   Typical use:
%       ca = ConstraintAnalysis.from_requirements(aero, prop, ...
%                aero481_requirements_path(), Aero481ConstraintSet.constraint_map(), ...
%                WS_range);
%
%   TWELVE CONSTRAINTS -- ALIGNED WITH AERO 481 (user decision): the 12 ACTIVE
%   +Constraints/All.m conditions (Cruise, Dash, two sustained turns, six SEP,
%   instantaneous turn, ceiling). Dropped for A481 parity: the six FAR-25 climb
%   gradients (transport-cert, not applicable to a fighter) and Takeoff/Landing
%   (Aero 481 leaves both unimplemented -- All.m:37 sets TO = 0).
%
%   F-35 CLASS CHOICES (Aero 481 Design01/+Constraints/All.m):
%     * Cruise / Dash -> LevelFlight [A481 Cruise.m; All.m:66,70].
%     * Sustained Turn 1/2 -> SustainedTurn [A481 SustainedTurn.m; All.m:78,82].
%     * SEP1/SEP2 (1g) -> ExcessPower [A481 SpecExcessPower.m; All.m:93-98]. The
%       6 SEP rows use the 50%-fuel COMBAT weight (beta = 0.8285 in the
%       requirements JSON) [A481 SpecExcessPower.m:28]; other rows stay at beta = 1.
%     * SEP3 (5g) -> ManeuveringExcessPower [A481 All.m:101,102].
%     * Instantaneous Turn -> InstantaneousTurn [A481 InstantaneousTurn.m;
%       All.m:86]. The class corrects the A481 g = 9.087 typo (disc A3) and adds
%       a thrust lapse -- this map only wires to it.
%     * Ceiling -> Ceiling [A481 Ceiling.m; All.m:74].
%
%   Keys below are the EXACT condition "name" strings in
%   aero481_requirements.json .constraints.conditions -- verbatim match required.

    methods (Static)

        function m = constraint_map()
        %CONSTRAINT_MAP  The F-35's condition-name -> ConstraintType map (12
        %   Aero 481 conditions + a Stall wall). See the class header for the
        %   per-row rationale. Keys match aero481_requirements.json verbatim.
            m = dictionary;
            m("Cruise")                        = ConstraintType.LevelFlight;
            m("Dash")                          = ConstraintType.LevelFlight;
            m("Sustained Turn 1 (subsonic)")   = ConstraintType.SustainedTurn;
            m("Sustained Turn 2 (supersonic)") = ConstraintType.SustainedTurn;
            m("SEP1 SL (1g, M0.9)")            = ConstraintType.ExcessPower;
            m("SEP1 alt (1g, M0.9, 15 kft)")   = ConstraintType.ExcessPower;
            m("SEP2 SL (1g, M0.9, max)")       = ConstraintType.ExcessPower;
            m("SEP2 alt (1g, M0.9, 15 kft)")   = ConstraintType.ExcessPower;
            m("SEP3 SL (5g, M0.9)")            = ConstraintType.ManeuveringExcessPower;
            m("SEP3 alt (5g, M0.9, 15 kft)")   = ConstraintType.ManeuveringExcessPower;
            m("Instantaneous Turn")            = ConstraintType.InstantaneousTurn;
            m("Ceiling")                       = ConstraintType.Ceiling;
            % Stall / approach-speed W/S WALL (Only_WbyS). Aero 481 left landing
            % unimplemented, so the constraint space was UNBOUNDED on the
            % small-wing side. This physical limit W/S <= q_approach*CLmax
            % [StallConstraint] bounds the design corner. Deliberate ADDITION
            % beyond Aero 481 (user decision).
            m("Stall (approach)")              = ConstraintType.Stall;
        end

    end

end
