classdef Aero481ConstraintSet
%Aero481CONSTRAINTSET  The F-35's constraint-condition -> ConstraintType map.
%
%   Layer-2 (aircraft-specific) data only, mirroring F16ConstraintSet and
%   B777ConstraintSet. This class does not build constraint objects itself --
%   that is generic Layer-1 work done by ConstraintAnalysis.from_requirements(
%   aero, prop, req_path, classMap, WS_range), which reads
%   examples/Aero481/inputs/aero481_requirements.json and, for each condition, dispatches
%   to the ConstraintType this map selects. This class supplies only that map:
%   which concrete constraint class models each of the F-35's named conditions.
%
%   Typical use:
%       ca = ConstraintAnalysis.from_requirements(aero, prop, ...
%                aero481_requirements_path(), Aero481ConstraintSet.constraint_map(), ...
%                WS_range);
%
%   The map is keyed on the ConstraintType enum, so only IMPLEMENTED constraint
%   classes can be selected (a not-yet-written class is a definition-time error
%   in ConstraintType, not a run-time failure). Every one of the 12 conditions
%   maps to an EXISTING framework constraint class (NO new constraint class was
%   added).
%
%   TWELVE CONSTRAINTS -- ALIGNED WITH AERO 481 (user decision). The map carries
%   exactly the 12 ACTIVE constraints Aero 481's +Constraints/All.m evaluates for
%   the F-35: Cruise, Dash, two sustained turns, six SEP points, instantaneous
%   turn, and ceiling. TWO groups from the earlier 20-row map were DROPPED:
%     * The six FAR-25 climb gradients (Climb 1-6: TO/TS/SS/EN/BA/BO) are
%       TRANSPORT-CERTIFICATION gradients and do NOT apply to a fighter -- Aero
%       481's climb rows exist only because the starter code is transport-shaped.
%       Removed per the user decision.
%     * Takeoff and Landing were framework-only additions; Aero 481 leaves both
%       UNIMPLEMENTED (All.m:37 sets ConstraintStruct.TO = 0; Landing is a stub),
%       so neither is a real Aero 481 constraint. Removed for A481 parity.
%
%   F-35 CLASS CHOICES (Aero 481 Design01/+Constraints/All.m):
%     * Cruise / Dash -> LevelFlight (n = 1, Ps = 0 fixed by the class)
%       [A481 Cruise.m; All.m:66,70].
%     * Sustained Turn 1/2 -> SustainedTurn (Ps = 0 fixed by the class)
%       [A481 SustainedTurn.m; All.m:78,82].
%     * SEP1/SEP2 (1g) SL+alt -> ExcessPower (n = 1 fixed by the class)
%       [A481 SpecExcessPower.m; All.m:93,94,97,98]. The 6 SEP rows evaluate at
%       the Aero 481 50%-internal-fuel COMBAT weight via beta = 0.8285 in the
%       requirements JSON [A481 SpecExcessPower.m:28]; the other rows stay at
%       takeoff weight (beta = 1), matching A481.
%     * SEP3 (5g) SL+alt -> ManeuveringExcessPower (n > 1 AND Ps > 0)
%       [A481 All.m:101,102].
%     * Instantaneous Turn -> InstantaneousTurn [A481 InstantaneousTurn.m;
%       All.m:86]. The existing class corrects the A481 g = 9.087 typo
%       (discrepancy A3, to 32.174 ft/s^2) and adds a thrust lapse -- this map
%       only wires to it.
%     * Ceiling -> Ceiling (CeilingConstraint, the W/S-independent T/W floor;
%       user-approved over the ExcessPower-via-Ps alternative for direct A481
%       parity -- Ceiling.m = Cruise + G) [A481 Ceiling.m; All.m:74].
%
%   The keys below are the EXACT condition "name" strings in
%   aero481_requirements.json .constraints.conditions -- they must match verbatim
%   for from_requirements to dispatch.

    methods (Static)

        function m = constraint_map()
        %CONSTRAINT_MAP  The F-35's condition-name -> ConstraintType map (the 12
        %   Aero 481 diagram conditions). See the class header for the per-row
        %   class-choice rationale and for why the 6 climbs + Takeoff/Landing were
        %   dropped. Keys match aero481_requirements.json verbatim.
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
            % unimplemented (Lnd = 0), so its constraint space was UNBOUNDED on the
            % small-wing side and the min-T/W "optimum" ran to the sweep edge. Add
            % the physical limit W/S <= q_approach*CLmax [StallConstraint] so the
            % design sits at a bounded corner (the wall meets the SEP2 floor), not
            % an arbitrary edge. Deliberate ADDITION beyond Aero 481 (user
            % decision 2026-08-15) to make the diagram physically correct.
            m("Stall (approach)")              = ConstraintType.Stall;
        end

    end

end
