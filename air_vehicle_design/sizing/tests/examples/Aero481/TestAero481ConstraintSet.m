classdef TestAero481ConstraintSet < matlab.unittest.TestCase
%TESTAero481CONSTRAINTSET  Tier-1 unit tests for the F-35A (Aero 481 provenance)
%   constraint set: Aero481ConstraintSet.constraint_map, the requirements-JSON
%   dispatch through ConstraintAnalysis.from_requirements / build_constraints,
%   and spot-checks that specific conditions resolve to the right
%   ConstraintType / concrete class.
%
%   These are STRUCTURAL / dispatch checks, not value-agreement checks:
%   per-constraint T/W values against the Aero 481 inline formulas are
%   INFORMATIONAL and belong in the aero481_comparison report, never here
%   (two-tier rule). This suite asserts the map is complete and correct and
%   that from_requirements builds every mapped constraint over the F-35 stack.
%
%   Stack (coordinator-verified):
%       sp = aero481_spec_path(1);       rp = aero481_requirements_path();
%       geom = Aero481GeomL1(sp, rp);    prop = Aero481PropL1(sp);   aero = Aero481AeroL1(sp);
%
%   ── EXPECTED STRUCTURE (independent of the class under test) ─────────────
%
%   The F-35 diagram carries the 12 ACTIVE Aero 481 constraints
%   [A481 +Constraints/All.m; aero481_requirements.json .constraints.conditions]:
%   Cruise, Dash, 2 sustained turns, 4 SEP (1g) rows, 2 SEP (5g) rows,
%   Instantaneous Turn, Ceiling = 12; PLUS a Stall (approach) W/S wall ADDED
%   beyond Aero 481 = 13 total. The six FAR-25 climb gradients and the
%   framework-only Takeoff/Landing were DROPPED (user decision, A481 parity):
%   FAR-25 climbs are transport-certification gradients not applicable to a
%   fighter, and Aero 481 leaves Takeoff/Landing unimplemented. The Stall wall
%   (StallConstraint, W/S <= q_approach*CLmax) was ADDED (user decision) because
%   without it the design space is unbounded on the small-wing side and the
%   min-T/W optimum runs to the sweep edge -- Aero 481's own gap.
%
%   ConstraintType per condition [Aero481ConstraintSet class header]:
%     Cruise / Dash                       -> LevelFlight   (LevelFlightConstraint)
%     Sustained Turn 1/2                  -> SustainedTurn
%     SEP1/SEP2 (1g) SL+alt               -> ExcessPower
%     SEP3 (5g) SL+alt                    -> ManeuveringExcessPower
%     Instantaneous Turn                  -> InstantaneousTurn
%     Ceiling                             -> Ceiling
%
%   The concrete-class check for Cruise (LevelFlightConstraint) is an INDEPENDENT
%   string-literal check of the built object's class -- not read from the map --
%   so a mis-wired map row cannot pass by matching itself.

    properties (Constant)
        N_CONDITIONS = 13    % 12 A481 active constraints + the added Stall (approach) W/S wall [aero481_requirements.json]
    end

    methods (Static)
        function [aero, prop] = buildAeroProp()
            sp   = aero481_spec_path(1);
            rp   = aero481_requirements_path(); %#ok<NASGU>
            geom = Aero481GeomL1(aero481_spec_path(1), aero481_requirements_path());
            prop = Aero481PropL1(sp);
            aero = Aero481AeroL1(sp);
        end

        function con = findByName(list, target)
        %FINDBYNAME  Return the constraint object in the cell list whose .name
        %   matches target (a string). Errors if not found.
            con = [];
            for i = 1:numel(list)
                if strcmp(string(list{i}.name), target)
                    con = list{i};
                    return;
                end
            end
            error('TestAero481ConstraintSet:notFound', ...
                'No constraint named "%s" in the built list.', target);
        end
    end

    % ==================================================================== %
    methods (Test)

        % ---- constraint_map + dispatch ----------------------------------- %

        function testConstraintMapHas12Entries(tc)
        % Aero481ConstraintSet.constraint_map must carry the 12 Aero 481 conditions.
            m = Aero481ConstraintSet.constraint_map();
            tc.verifyClass(m, 'dictionary');
            fprintf('\n    constraint_map entries = %d (expected %d)\n', ...
                numel(keys(m)), tc.N_CONDITIONS);
            tc.verifyEqual(numel(keys(m)), tc.N_CONDITIONS, ...
                'The F-35 map must carry the 12 Aero 481 diagram conditions.');
        end

        function testEveryMapValueIsConstraintType(tc)
        % Every value in the map is a ConstraintType member (only implemented
        % classes can be selected -- a not-yet-written class is a definition
        % error in ConstraintType, not a run-time failure).
            m = Aero481ConstraintSet.constraint_map();
            ks = keys(m);
            for i = 1:numel(ks)
                tc.verifyClass(m(ks(i)), 'ConstraintType', ...
                    sprintf('Map value for "%s" must be a ConstraintType.', ks(i)));
            end
        end

        function testEveryJSONConditionResolvesToAConstraintType(tc)
        % Every condition NAME in aero481_requirements.json must be a key in the
        % map (and each map value a ConstraintType). This is the verbatim
        % name-match dispatch guard.
            m    = Aero481ConstraintSet.constraint_map();
            cond = ConstraintSetImporter.read_conditions(aero481_requirements_path());
            tc.verifyEqual(numel(cond), tc.N_CONDITIONS, ...
                'The requirements JSON must carry the 12 F-35 conditions.');
            for i = 1:numel(cond)
                nm = string(cond(i).name);
                tc.verifyTrue(isKey(m, nm), ...
                    sprintf('Condition "%s" is not in Aero481ConstraintSet.constraint_map.', nm));
                tc.verifyClass(m(nm), 'ConstraintType');
            end
        end

        function testFromRequirementsBuildsAll12(tc)
        % ConstraintAnalysis.from_requirements must build without error over
        % the F-35 aero/prop stack, producing one constraint per mapped
        % condition (all 12), each a PointPerformanceBase.
            [aero, prop] = TestAero481ConstraintSet.buildAeroProp();
            m  = Aero481ConstraintSet.constraint_map();
            ca = ConstraintAnalysis.from_requirements(aero, prop, ...
                string(aero481_requirements_path()), m, 41:5:143);
            tc.verifyClass(ca, 'ConstraintAnalysis');
            fprintf('\n    from_requirements built %d constraints (expected %d)\n', ...
                numel(ca.constraints), tc.N_CONDITIONS);
            tc.verifyEqual(numel(ca.constraints), tc.N_CONDITIONS, ...
                'from_requirements must build all 12 mapped F-35 constraints.');
            for i = 1:numel(ca.constraints)
                tc.verifyTrue(isa(ca.constraints{i}, 'PointPerformanceBase'), ...
                    'Every built constraint must be a PointPerformanceBase.');
            end
        end

        % ---- spot-check that specific conditions resolve correctly ------- %

        function testCruiseResolvesToLevelFlight(tc)
        % The Cruise condition must map to ConstraintType.LevelFlight and build
        % a LevelFlightConstraint. The class-name literal is independent of the
        % map, so a mis-wired row cannot pass by matching itself.
            m = Aero481ConstraintSet.constraint_map();
            tc.verifyEqual(m("Cruise"), ConstraintType.LevelFlight, ...
                'Cruise must map to ConstraintType.LevelFlight.');
            [aero, prop] = TestAero481ConstraintSet.buildAeroProp();
            list = ConstraintAnalysis.build_constraints(aero, prop, ...
                string(aero481_requirements_path()), m);
            c = TestAero481ConstraintSet.findByName(list, "Cruise");
            fprintf('\n    Cruise built as %s\n', class(c));
            tc.verifyClass(c, 'LevelFlightConstraint', ...
                'Cruise must build a LevelFlightConstraint.');
        end

        function testDashResolvesToLevelFlight(tc)
        % Dash (the M1.6 AB level-flight condition) also maps to LevelFlight.
            m = Aero481ConstraintSet.constraint_map();
            tc.verifyEqual(m("Dash"), ConstraintType.LevelFlight, ...
                'Dash must map to ConstraintType.LevelFlight.');
        end

        function testSEP1g5gResolveToDistinctClasses(tc)
        % The 1g SEP rows are ExcessPower; the 5g SEP rows are the maneuvering
        % variant ManeuveringExcessPower (n > 1 AND Ps > 0). Verify the map
        % distinguishes them.
            m = Aero481ConstraintSet.constraint_map();
            tc.verifyEqual(m("SEP1 SL (1g, M0.9)"), ConstraintType.ExcessPower, ...
                'A 1g SEP row must map to ExcessPower.');
            tc.verifyEqual(m("SEP3 SL (5g, M0.9)"), ConstraintType.ManeuveringExcessPower, ...
                'A 5g SEP row must map to ManeuveringExcessPower.');
        end

        function testCeilingAndTurnsResolve(tc)
        % Ceiling -> Ceiling; sustained/instantaneous turns -> their classes.
            m = Aero481ConstraintSet.constraint_map();
            tc.verifyEqual(m("Ceiling"), ConstraintType.Ceiling);
            tc.verifyEqual(m("Sustained Turn 1 (subsonic)"), ConstraintType.SustainedTurn);
            tc.verifyEqual(m("Instantaneous Turn"), ConstraintType.InstantaneousTurn);
        end

        function testClimbAndFieldRowsAreAbsent(tc)
        % The six FAR-25 climbs and the framework-only Takeoff/Landing were
        % DROPPED (user decision, A481 parity). Their names must NOT be keys in
        % the map -- a regression guard against re-introducing them.
            m = Aero481ConstraintSet.constraint_map();
            dropped = ["Climb 1 (TO)", "Climb 2 (TS)", "Climb 3 (SS)", ...
                "Climb 4 (EN)", "Climb 5 (BA)", "Climb 6 (BO)", ...
                "Takeoff", "Landing"];
            for i = 1:numel(dropped)
                tc.verifyFalse(isKey(m, dropped(i)), ...
                    sprintf('Dropped condition "%s" must NOT be in the map.', dropped(i)));
            end
        end

        function testMapKeyNotInRequirementsErrors(tc)
        % A map key that names no JSON condition is a typo guard -- build_
        % constraints errors rather than silently selecting nothing.
            [aero, prop] = TestAero481ConstraintSet.buildAeroProp();
            m = Aero481ConstraintSet.constraint_map();
            m("Hypersonic Cruise") = ConstraintType.LevelFlight;   % not in the JSON
            tc.verifyError(@() ConstraintAnalysis.build_constraints(aero, prop, ...
                string(aero481_requirements_path()), m), ...
                'ConstraintAnalysis:mapKeyNotInRequirements');
        end

    end
end
