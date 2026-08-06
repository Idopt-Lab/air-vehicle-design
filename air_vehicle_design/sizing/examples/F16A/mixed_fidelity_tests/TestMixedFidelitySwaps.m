classdef TestMixedFidelitySwaps < matlab.unittest.TestCase
%TESTMIXEDFIDELITYSWAPS  Curated pass/fail regression gate for the
%   mixed-fidelity sizing harness (`build_fidelity_combo.m`).
%
%   TIER: this is a Tier-1 unit/correctness test file [CLAUDE.md's
%   two-test-tier rule] -- it gates `run_all_tests` and every assertion
%   below must be green except where explicitly labeled otherwise. It is
%   NOT the informational report: `run_fidelity_sweep.m` (full 1536-combo
%   cross-product, no pass/fail) is the separate, non-gating companion.
%
%   Every "expected" outcome below (valid/converges vs. invalid/fails, and
%   which stage an invalid combo fails at) was derived by READING the
%   actual guard conditions in `build_fidelity_combo.m`, `F16AeroL2.m`,
%   `F16WeightsL2.m`/`F16WeightsL3.m`, `F16GeomL2.m`, `SizingLoopL1.m`/
%   `SizingLoopL2.m`, and the Brandt adapter classes -- never guessed and
%   never reverse-engineered from a single run's output. Two of the
%   findings below go BEYOND what `COMPATIBILITY_NOTES.md` already
%   documents; both are called out explicitly where they occur (see the
%   combo18 TestParameter's c08/c11/c17 entries, exercised by
%   testUserCombo, and testPureBrandtBaselineFailsToConverge).
%
%   No test in this file is a deliberately-failing TODO test in the
%   "missing citation" sense -- every `verifyFalse(status.ok)` below is a
%   real, structurally-justified assertion about how the code actually
%   behaves today, not a placeholder for missing work.

    properties (Constant)
        W_TO_GUESS = 30000   % lbf -- matches every design_study_*.m's own default initial guess
        T_SL_GUESS = 20000   % lbf -- matches every design_study_*.m's own default initial guess

        % Brandt's own published TOGW [Brandt F-16A.xls Main!B38 "Total @
        % Takeoff", reproduced verbatim in baseline/F16Baseline.m's
        % b.brandt.TOGW = 31377.0]. The ONE case in this file where an
        % actual ground-truth W_TO number exists to compare against --
        % see the class header note on why this constant ends up UNUSED
        % by the current all-Brandt baseline test (testPureBrandtBaselineFailsToConverge).
        BRANDT_TOGW = 31377.0   % lbf
    end

    properties (TestParameter)
        % ================================================================= %
        % The user's 18 example combinations (Aero/Geometry/Propulsion/
        % Weights), Mission and Loop pinned to "L1" for every row per the
        % coordinator's instruction. Field name c01..c18 preserves the
        % user's own ordering for easy cross-reference. `valid` is whether
        % build_fidelity_combo is expected to reach a converged result;
        % `stage` is the expected status.stage when valid=false (ignored by
        % the test method when valid=true).
        %
        % CLASSIFICATION RULES APPLIED (see COMPATIBILITY_NOTES.md items 1/2/9
        % for the first three; items 4/5/8 not triggered by any of the 18
        % since none pairs with Geometry/Aero/Weights/Mission=Brandt; the
        % 4th and 5th rules below are NEW findings this test-writing pass
        % discovered, not yet in COMPATIBILITY_NOTES.md):
        %   (a) Aero=L2 requires Geometry in {L2,L3} [F16AeroL2.m's mustBeA
        %       guard] -- else fails at CONSTRUCTION, stage="aero".
        %   (b) Weights=L2/L3 requires Geometry in {L2,L3} [F16WeightsL2.m/
        %       F16WeightsL3.m's mustBeA guard] -- else fails at
        %       CONSTRUCTION, stage="weights" (checked only if (a) didn't
        %       already fail first -- aero builds before weights in
        %       build_fidelity_combo's dependency order).
        %   (c) Weights=L2/L3 requires Propulsion to expose `bypass_ratio`
        %       [F16WeightsL2/L3's W_en getter reads obj.prop.bypass_ratio,
        %       a plain property only F16PropL2 declares -- NOT part of
        %       PropulsionBase's abstract contract] -- else construction
        %       passes cleanly but the FIRST obj.wts.OEW(W_TO) call inside
        %       the sizing loop errors, caught as a RUNTIME failure,
        %       stage="loop" [COMPATIBILITY_NOTES.md item 9].
        %   (d) *** NEW FINDING, not yet in COMPATIBILITY_NOTES.md ***
        %       Weights=L3 genuinely requires Geometry=L3, NOT merely
        %       Geometry in {L2,L3} as the mustBeA guard (and F16WeightsL3.m's
        %       own doc comment, "both tiers declare these identically")
        %       claims. F16WeightsL3.weight_tail/weight_systems read NINE
        %       geometry properties -- B_h, F_w, H_t, H_v, L_t, S_r, S_cs,
        %       AR_exposed_vt, lambda_exposed_vt (F16WeightsL3.m's own
        %       Dependent-property table, "Geometry, by DI" section) -- that
        %       are declared on GeometryModelL3's abstract contract but NOT
        %       on GeometryModelL2's (confirmed by reading both
        %       GeometryModelL2.m, which has no such properties, and
        %       F16GeomL2.m, which implements none of them). Pairing
        %       Weights=L3 with Geometry=L2 therefore passes the mustBeA
        %       construction guard cleanly, then fails the FIRST time
        %       OEW(W_TO) is called (inside weight_tail, reading obj.F_w /
        %       obj.B_h) with a "no public property" MATLAB error --
        %       caught as a RUNTIME failure, stage="loop", exactly like (c)
        %       but for a different underlying cause (a missing PROPERTY,
        %       not a missing bypass_ratio). This affects c08/c11/c17 below.
        %   (e) Aero=L1/Weights=L1/Mission=L1 never read an injected geom or
        %       prop object at all [COMPATIBILITY_NOTES.md item 8] --
        %       Geometry/Propulsion axis is fully decorative for those two
        %       disciplines, so any row with Aero=L1 AND Weights=L1 is
        %       structurally valid regardless of the Geometry/Propulsion
        %       choice.
        % Per-row rationale (kept as ORDINARY comment lines BEFORE each
        % entry, never sandwiched inside the struct(...) argument list
        % itself, to avoid any ambiguity between a MATLAB line-continuation
        % ("...") and an intervening full-line comment):
        %
        % c01 -- Rule (b): Weights=L2 needs Geometry in {L2,L3}; Geometry=L1 here.
        % c02 -- Rule (b): Weights=L3 needs Geometry in {L2,L3}; Geometry=L1 here.
        % c03 -- Rule (e): Aero=L1 & Weights=L1 -> Geometry/Propulsion axis
        %        decorative for both; same weight/mission closure as
        %        design_study_01_L1 (known convergent fixed point).
        % c04 -- Rule (b): Weights=L2 needs Geometry in {L2,L3}; Geometry=L1 here.
        % c05 -- Rule (b): Weights=L3 needs Geometry in {L2,L3}; Geometry=L1 here.
        % c06 -- Rule (e): Aero=L1 & Weights=L1 -> Geometry swap is decorative
        %        [COMPATIBILITY_NOTES.md item 8]. Converges.
        % c07 -- Rule (b) satisfied (Geometry=L2), construction succeeds; but
        %        rule (c): Propulsion=L1 has no bypass_ratio -> runtime
        %        failure the first time obj.wts.OEW is called in the loop.
        % c08 -- Construction succeeds (mustBeA(geom,[L2,L3]) accepts L2).
        %        RUNTIME failure, stage="loop", for TWO compounding reasons:
        %        rule (d) (F16WeightsL3 reads B_h/F_w/etc. off geom, absent
        %        on F16GeomL2 -- fires FIRST, inside weight_tail, since
        %        weight_tail runs before weight_engine_section in
        %        WeightsL3.OEW) AND rule (c) (Propulsion=L1 lacks
        %        bypass_ratio, would also fail in weight_engine_section had
        %        weight_tail not already thrown). Either way: stage="loop".
        % c09 -- Rule (e): Aero=L1 & Weights=L1 -> decorative Geometry/Prop
        %        axis. Converges.
        % c10 -- Weights=L2 + Geometry=L2 (its own native tier, rule (b)
        %        satisfied) + Propulsion=L2 (rule (c) satisfied, has
        %        bypass_ratio). F16WeightsL2 only reads the FOUR properties
        %        common to both geometry tiers (S_exposed_wing/ht/vt,
        %        get_S_wet_fuselage) -- no rule-(d)-style gap for L2
        %        Weights. Converges (Aero=L1 is geometry-free, so this
        %        differs from design_study_02_L2 only in which aero model
        %        feeds the constraint envelope -- still a valid, convergent
        %        combination).
        % c11 -- *** Rule (d), the NEW finding. *** Propulsion=L2 satisfies
        %        rule (c) (has bypass_ratio) and construction passes the
        %        mustBeA(geom,[L2,L3]) guard cleanly -- but F16WeightsL3
        %        needs L3-ONLY geometry properties (B_h, F_w, H_t, H_v, L_t,
        %        S_r, S_cs, AR_exposed_vt, lambda_exposed_vt) that F16GeomL2
        %        does not implement. RUNTIME failure the first time OEW is
        %        called, stage="loop". This ROW IS THE ONE THAT DIFFERS FROM
        %        A NAIVE READING OF COMPATIBILITY_NOTES.md item 2 (which
        %        states Weights in {L2,L3} works with Geometry in {L2,L3}
        %        generically) -- that statement is true for Weights=L2 but
        %        NOT for Weights=L3, which this row demonstrates.
        % c12 -- Rule (a): Aero=L2 needs Geometry in {L2,L3}; Geometry=L1 here.
        % c13 -- Rule (a): same as c12 -- aero builds (and fails) before
        %        weights ever gets a chance to also fail on rule (b)/(c).
        % c14 -- Rule (a): same as c12/c13.
        % c15 -- Rule (a) satisfied (Geometry=L2). Weights=L1 never reads
        %        geom/prop (rule (e)'s Weights=L1 half), so Propulsion=L1's
        %        missing bypass_ratio never matters here -- only
        %        Weights=L2/L3 reads it. Converges.
        % c16 -- Rules (a)/(b) satisfied (Geometry=L2 covers both Aero=L2
        %        and Weights=L2). Rule (c): Propulsion=L1 lacks bypass_ratio
        %        -> runtime failure, stage="loop".
        % c17 -- Rule (a) satisfied (Geometry=L2 for Aero=L2). Construction
        %        of Weights=L3 also passes (mustBeA accepts L2). RUNTIME
        %        failure for the same two compounding reasons as c08: rule
        %        (d) (L3-only geometry properties missing from F16GeomL2,
        %        fires first) and rule (c) (Propulsion=L1 lacks
        %        bypass_ratio). stage="loop" either way.
        % c18 -- Rule (a) satisfied (Geometry=L3 is in Aero=L2's accepted
        %        set). Weights=L1 never reads geom/prop. Converges.
        combo18 = struct( ...
            'c01_L1Aero_L1Geom_L1Prop_L2Wts', struct('aero',"L1",'geom',"L1",'prop',"L1",'weights',"L2",'valid',false,'stage',"weights"), ...
            'c02_L1Aero_L1Geom_L1Prop_L3Wts', struct('aero',"L1",'geom',"L1",'prop',"L1",'weights',"L3",'valid',false,'stage',"weights"), ...
            'c03_L1Aero_L1Geom_L2Prop_L1Wts', struct('aero',"L1",'geom',"L1",'prop',"L2",'weights',"L1",'valid',true, 'stage',""), ...
            'c04_L1Aero_L1Geom_L2Prop_L2Wts', struct('aero',"L1",'geom',"L1",'prop',"L2",'weights',"L2",'valid',false,'stage',"weights"), ...
            'c05_L1Aero_L1Geom_L2Prop_L3Wts', struct('aero',"L1",'geom',"L1",'prop',"L2",'weights',"L3",'valid',false,'stage',"weights"), ...
            'c06_L1Aero_L2Geom_L1Prop_L1Wts', struct('aero',"L1",'geom',"L2",'prop',"L1",'weights',"L1",'valid',true, 'stage',""), ...
            'c07_L1Aero_L2Geom_L1Prop_L2Wts', struct('aero',"L1",'geom',"L2",'prop',"L1",'weights',"L2",'valid',false,'stage',"loop"), ...
            'c08_L1Aero_L2Geom_L1Prop_L3Wts', struct('aero',"L1",'geom',"L2",'prop',"L1",'weights',"L3",'valid',false,'stage',"loop"), ...
            'c09_L1Aero_L2Geom_L2Prop_L1Wts', struct('aero',"L1",'geom',"L2",'prop',"L2",'weights',"L1",'valid',true, 'stage',""), ...
            'c10_L1Aero_L2Geom_L2Prop_L2Wts', struct('aero',"L1",'geom',"L2",'prop',"L2",'weights',"L2",'valid',true, 'stage',""), ...
            'c11_L1Aero_L2Geom_L2Prop_L3Wts', struct('aero',"L1",'geom',"L2",'prop',"L2",'weights',"L3",'valid',false,'stage',"loop"), ...
            'c12_L2Aero_L1Geom_L1Prop_L1Wts', struct('aero',"L2",'geom',"L1",'prop',"L1",'weights',"L1",'valid',false,'stage',"aero"), ...
            'c13_L2Aero_L1Geom_L1Prop_L2Wts', struct('aero',"L2",'geom',"L1",'prop',"L1",'weights',"L2",'valid',false,'stage',"aero"), ...
            'c14_L2Aero_L1Geom_L1Prop_L3Wts', struct('aero',"L2",'geom',"L1",'prop',"L1",'weights',"L3",'valid',false,'stage',"aero"), ...
            'c15_L2Aero_L2Geom_L1Prop_L1Wts', struct('aero',"L2",'geom',"L2",'prop',"L1",'weights',"L1",'valid',true, 'stage',""), ...
            'c16_L2Aero_L2Geom_L1Prop_L2Wts', struct('aero',"L2",'geom',"L2",'prop',"L1",'weights',"L2",'valid',false,'stage',"loop"), ...
            'c17_L2Aero_L2Geom_L1Prop_L3Wts', struct('aero',"L2",'geom',"L2",'prop',"L1",'weights',"L3",'valid',false,'stage',"loop"), ...
            'c18_L2Aero_L3Geom_L2Prop_L1Wts', struct('aero',"L2",'geom',"L3",'prop',"L2",'weights',"L1",'valid',true, 'stage',"") ...
        );
    end

    methods (Test)

        % ================================================================= %
        % Four "pure" baselines
        % ================================================================= %

        function testPureL1BaselineConverges(tc)
        % All-L1 (Geometry/Aero/Propulsion/Weights/Mission/Loop = L1) --
        % exactly design_study_01_L1's own combination, reusing
        % build_fidelity_combo purely as an alternate construction path.
            [objs, status] = build_fidelity_combo("L1", "L1", "L1", "L1", "L1", "L1", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);
            tc.verifyTrue(status.ok, sprintf('all-L1 baseline failed at stage "%s": %s', ...
                status.stage, status.message));
            tc.verifyTrue(isfinite(objs.result.W_TO));
            tc.verifyGreaterThan(objs.result.W_TO, 0);
            tc.verifyTrue(isfinite(objs.result.T_SL));
            tc.verifyGreaterThan(objs.result.T_SL, 0);
        end

        function testPureL2BaselineConverges(tc)
        % All-L2 (Geometry/Aero/Propulsion/Weights/Mission = L2, Loop = L2)
        % -- exactly design_study_02_L2's own combination.
            [objs, status] = build_fidelity_combo("L2", "L2", "L2", "L2", "L2", "L2", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);
            tc.verifyTrue(status.ok, sprintf('all-L2 baseline failed at stage "%s": %s', ...
                status.stage, status.message));
            tc.verifyTrue(isfinite(objs.result.W_TO));
            tc.verifyGreaterThan(objs.result.W_TO, 0);
            tc.verifyTrue(isfinite(objs.result.T_SL));
            tc.verifyGreaterThan(objs.result.T_SL, 0);
        end

        function testPureL3BaselineConverges(tc)
        % All-L3, Propulsion PINNED to L2 (no L3 propulsion tier exists --
        % the established convention design_study_03_L3.m documents),
        % Loop = L2 (design_study_03_L3 reuses SizingLoopL2 unmodified).
            [objs, status] = build_fidelity_combo("L3", "L3", "L2", "L3", "L3", "L2", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);
            tc.verifyTrue(status.ok, sprintf('all-L3 baseline failed at stage "%s": %s', ...
                status.stage, status.message));
            tc.verifyTrue(isfinite(objs.result.W_TO));
            tc.verifyGreaterThan(objs.result.W_TO, 0);
            tc.verifyTrue(isfinite(objs.result.T_SL));
            tc.verifyGreaterThan(objs.result.T_SL, 0);
        end

        function testPureBrandtBaselineDoesNotConverge(tc)
        % All-Brandt (Geometry/Aero/Propulsion/Weights/Mission = Brandt).
        %
        % *** DOES NOT CONVERGE, AND THIS IS THE CORRECT, EXPECTED OUTCOME --
        % NOT A BUG. *** Two real defects that WOULD have made this fail for
        % the wrong reason were found and fixed during verification (see
        % COMPATIBILITY_NOTES.md item 12): BrandtWeightsAdapter's payload
        % properties were NaN (now read from Brandt's own
        % inp.weight.perm_payload_lb/exp_payload_lb), and BrandtAeroAdapter
        % was missing the four takeoff/landing methods F16ConstraintSet.build
        % needs (now added, item 11). With both fixed, all-Brandt
        % constructs cleanly and runs -- it just does not converge within
        % SizingLoopL1's 200-iteration cap. This is a genuine numerical
        % mismatch, not a coding defect: the framework's iterative
        % under-relaxed fixed-point loop and Brandt's own spreadsheet
        % circular-reference closure are different root-finding mechanics
        % over the same W_TO equation, and nothing guarantees the former
        % converges when every discipline input is swapped out from under
        % it. This is exactly the kind of "weird but expected" outcome the
        % mixed-fidelity feature is meant to surface, not hide -- asserting
        % non-convergence here (rather than forcing an artificial fix, e.g.
        % relaxing the iteration cap or initial guess until it happens to
        % converge) keeps the test honest about what the code actually does.
            [objs, status] = build_fidelity_combo("Brandt", "Brandt", "Brandt", "Brandt", "Brandt", "L1", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);
            tc.verifyFalse(status.ok, ...
                ['all-Brandt baseline unexpectedly converged -- if this now passes, the ', ...
                 'framework/Brandt closure mismatch described above has changed; replace this ', ...
                 'assertion with a loose RelTol comparison against BRANDT_TOGW.']);
            tc.verifyEqual(string(status.stage), "loop");
            tc.verifyNotEmpty(status.message);
            tc.verifyEmpty(objs, 'objs must be [] on a failed build (build_fidelity_combo contract).');
        end

        % ================================================================= %
        % The user's 18 example combinations
        % ================================================================= %

        function testUserCombo(tc, combo18)
        % Mission and Loop pinned to "L1" for all 18, per the coordinator's
        % instruction. See the combo18 TestParameter block above for the
        % full valid/invalid classification and per-row citations.
            c = combo18;
            [objs, status] = build_fidelity_combo(c.geom, c.aero, c.prop, c.weights, "L1", "L1", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);

            if c.valid
                tc.verifyTrue(status.ok, sprintf( ...
                    ['Expected VALID combo (Aero=%s Geom=%s Prop=%s Weights=%s) to converge ', ...
                     'but it failed at stage "%s": %s'], ...
                    c.aero, c.geom, c.prop, c.weights, status.stage, status.message));
                if status.ok
                    tc.verifyTrue(isfinite(objs.result.W_TO));
                    tc.verifyGreaterThan(objs.result.W_TO, 0);
                end
            else
                tc.verifyFalse(status.ok, sprintf( ...
                    ['Expected INVALID combo (Aero=%s Geom=%s Prop=%s Weights=%s) to fail ', ...
                     'at stage "%s" but it unexpectedly converged (W_TO=%g). If this now ', ...
                     'passes, whatever guard this row tested has been loosened/fixed -- ', ...
                     'reclassify this row rather than deleting the assertion.'], ...
                    c.aero, c.geom, c.prop, c.weights, c.stage, ...
                    TestMixedFidelitySwaps.wtoOrNaN(objs)));
                % string() wrap: status.stage is a plain char literal from
                % build_fidelity_combo.m; c.stage is a string (TestParameter
                % values above are double-quoted) -- verifyEqual is
                % class-sensitive, so compare like-for-like.
                tc.verifyEqual(string(status.stage), c.stage, sprintf( ...
                    'Combo (Aero=%s Geom=%s Prop=%s Weights=%s) failed, but at the wrong stage.', ...
                    c.aero, c.geom, c.prop, c.weights));
            end
        end

        % ================================================================= %
        % Two representative genuinely-invalid Brandt combinations
        % [COMPATIBILITY_NOTES.md item 6: Geometry=Brandt only satisfies bare
        % GeometryBase, so it fails the SAME mustBeA(geom, [GeometryModelL2,
        % GeometryModelL3]) guards Aero=L2/L3 and Weights=L2/L3 both use].
        % ================================================================= %

        function testBrandtGeometryIncompatibleWithAeroL2(tc)
        % Geometry=Brandt + Aero=L2: F16AeroL2's mustBeA guard rejects
        % BrandtGeomAdapter (satisfies only GeometryBase) at construction.
        % Other axes (Propulsion/Weights/Mission=L1) are chosen so nothing
        % else can fail first / mask this specific guard.
            [objs, status] = build_fidelity_combo("Brandt", "L2", "L1", "L1", "L1", "L1", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);
            tc.verifyFalse(status.ok);
            tc.verifyEqual(string(status.stage), "aero");
            tc.verifyNotEmpty(status.message);
            % Confirms the guard fails LOUDLY with the specific MATLAB
            % mustBeA validation text (naming the required classes), not a
            % generic/blank message.
            tc.verifyTrue(contains(status.message, "GeometryModelL2") || ...
                          contains(status.message, "GeometryModelL3"), ...
                sprintf('Expected a mustBeA-style message naming GeometryModelL2/L3, got: %s', ...
                status.message));
            tc.verifyEmpty(objs);
        end

        function testBrandtGeometryIncompatibleWithWeightsL2(tc)
        % Geometry=Brandt + Weights=L2: F16WeightsL2's mustBeA guard rejects
        % BrandtGeomAdapter at construction. Aero pinned to L1 (geometry-free
        % -- COMPATIBILITY_NOTES.md item 8) so THIS guard is the one that
        % fires, not Aero's identical guard from the previous test.
            [objs, status] = build_fidelity_combo("Brandt", "L1", "L1", "L2", "L1", "L1", ...
                tc.W_TO_GUESS, tc.T_SL_GUESS);
            tc.verifyFalse(status.ok);
            tc.verifyEqual(string(status.stage), "weights");
            tc.verifyNotEmpty(status.message);
            tc.verifyTrue(contains(status.message, "GeometryModelL2") || ...
                          contains(status.message, "GeometryModelL3"), ...
                sprintf('Expected a mustBeA-style message naming GeometryModelL2/L3, got: %s', ...
                status.message));
            tc.verifyEmpty(objs);
        end

    end

    methods (Static, Access = private)

        function w = wtoOrNaN(objs)
        %WTOORNAN  Small helper for testUserCombo's failure-message string:
        %   objs is [] whenever status.ok is false (build_fidelity_combo's
        %   own contract), so there is no W_TO to print in that branch --
        %   this only ever actually executes if a "should be invalid" row
        %   surprises us by returning ok=true, in which case
        %   objs.result.W_TO is real and printable. A local function after
        %   the classdef block is not permitted in a class-definition file,
        %   so this lives here as a private static method instead.
            if isempty(objs)
                w = NaN;
            else
                w = objs.result.W_TO;
            end
        end

    end

end
