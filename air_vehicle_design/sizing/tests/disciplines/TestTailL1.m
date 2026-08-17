classdef TestTailL1 < matlab.unittest.TestCase
%TESTTAILL1  Unit tests for the generic TailL1 static toolbox and its F-16
%   Tier-3 concrete class F16TailL1.
%
%   METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA,
%   2018, Table 6.4 + accompanying text]:
%
%     L_HT = L_VT = 0.475 * L_fus
%     c_HT = c_HT_base * (1 - 0.10) * (1 - 0.125)   [if RSS and all-moving tail]
%     c_VT = c_VT_base * (1 - 0.10)                 [if RSS; no VT-specific
%                                                     text correction exists]
%     S_VT = c_VT * b    * S_ref / L_VT
%     S_HT = c_HT * cbar * S_ref / L_HT
%
%   Jet-fighter base row: c_HT=0.40, c_VT=0.07.
%
%   These are the CORRECTED values adopted 2026-07-28 (scribe plan Sec. 2),
%   replacing the orphaned/never-called GeomL1 methods this class migrates
%   from, and replacing the OLD, now-SUPERSEDED TailSizingLevel1 class's
%   0.40/0.07/0.5*L_fus/6th-ed. values (see tests/tail_sizing/
%   TestTailSizingLevel1.m, retired).
%
%   NOT SELF-REFERENTIAL: every "expected" value below is hand-derived from
%   Table 6.4's stated arithmetic (base coefficient x stated correction
%   factors) or from GeometryBase's OWN chord/span formulas (Raymer Eqs.
%   7.6-7.8), independently re-derived by long division in this file's
%   commit history -- never read back from TailL1's own output.

    methods (Test)

        % ================================================================ %
        % Low-level statics: base lookup, category error, corrections
        % ================================================================ %

        function testLookupJetFighterBaseCoefficients(tc)
        % [Raymer 7th ed. Table 6.4, "Jet fighter" row]
            [c_HT, c_VT] = TailL1.lookup_tail_volume_coeffs('jet_fighter');
            tc.verifyEqual(c_HT, 0.40, 'AbsTol', 0, 'Jet-fighter base c_HT must be 0.40.');
            tc.verifyEqual(c_VT, 0.07, 'AbsTol', 0, 'Jet-fighter base c_VT must be 0.07.');
        end

        function testUnknownCategoryThrows(tc)
        % Only the jet-fighter row is implemented -- an unknown category must
        % error rather than silently return a guessed value.
            tc.verifyError(@() TailL1.lookup_tail_volume_coeffs('prop_trainer'), ...
                'TailL1:unknownCategory');
        end

        function testCorrectionsNeitherAppliesLeavesBaseUnchanged(tc)
            [c_HT, c_VT] = TailL1.compute_tail_volume_coeffs('jet_fighter', false, false);
            tc.verifyEqual(c_HT, 0.40, 'AbsTol', 0);
            tc.verifyEqual(c_VT, 0.07, 'AbsTol', 0);
        end

        function testCorrectionsRSSOnly(tc)
        % RSS: -10% on BOTH c_HT and c_VT [Table 6.4 text].
        % Hand-computed: 0.40*0.90=0.36, 0.07*0.90=0.063.
            [c_HT, c_VT] = TailL1.compute_tail_volume_coeffs('jet_fighter', true, false);
            tc.verifyEqual(c_HT, 0.36, 'AbsTol', 1e-12);
            tc.verifyEqual(c_VT, 0.063, 'AbsTol', 1e-12);
        end

        function testCorrectionsAllMovingTailOnly(tc)
        % All-moving stabilator: -12.5% on c_HT ONLY, no VT-specific text
        % correction. Hand-computed: 0.40*0.875=0.35; c_VT unchanged=0.07.
            [c_HT, c_VT] = TailL1.compute_tail_volume_coeffs('jet_fighter', false, true);
            tc.verifyEqual(c_HT, 0.35, 'AbsTol', 1e-12);
            tc.verifyEqual(c_VT, 0.07, 'AbsTol', 1e-12);
        end

        function testCorrectionsBothAppliesF16NetValues(tc)
        % Both corrections (the F-16's case): c_HT=0.40*0.90*0.875=0.315,
        % c_VT=0.07*0.90=0.063 -- hand-computed, independent of F16TailL1's
        % own constructor call to this same static (verified below by a
        % SEPARATE test comparing the two).
            [c_HT, c_VT] = TailL1.compute_tail_volume_coeffs('jet_fighter', true, true);
            tc.verifyEqual(c_HT, 0.315, 'AbsTol', 1e-12, ...
                'F-16 net c_HT must equal 0.40*(1-0.10)*(1-0.125)=0.315.');
            tc.verifyEqual(c_VT, 0.063, 'AbsTol', 1e-12, ...
                'F-16 net c_VT must equal 0.07*(1-0.10)=0.063.');
        end

        function testTailArmFormula(tc)
        % [Raymer 7th ed. text, aft-mounted single-engine rule, midpoint 0.475]
        % Hand-computed at L_fus=46.5: 0.475*46.5=22.0875 exactly.
            L = TailL1.compute_tail_arm(46.5);
            tc.verifyEqual(L, 22.0875, 'AbsTol', 1e-12);
        end

        function testTailArmRejectsNonPositive(tc)
        % L_fus is a numerator-only quantity but is guarded mustBePositive
        % (a zero/negative fuselage length is nonphysical).
            tc.verifyError(@() TailL1.compute_tail_arm(0), 'MATLAB:validators:mustBePositive');
            tc.verifyError(@() TailL1.compute_tail_arm(-10), 'MATLAB:validators:mustBePositive');
        end

        function testComputeSHTFormula(tc)
        % Arbitrary invented scalars (not F-16 data): c_HT=0.45, cbar=9.5,
        % S_ref=250, L_HT=19 (deliberately NOT 0.475*L_fus here -- this test
        % isolates compute_S_HT's own arithmetic from compute_tail_arm's).
        % Hand-computed: 0.45*9.5*250/19 = 1068.75/19 = 56.25 EXACTLY
        % (19*56=1064, remainder 4.75, 4.75/19=0.25).
            val = TailL1.compute_S_HT(0.45, 9.5, 250, 19);
            tc.verifyEqual(val, 56.25, 'AbsTol', 1e-9);
        end

        function testComputeSVTFormula(tc)
        % Arbitrary invented scalars: c_VT=0.08, b=28, S_ref=250, L_VT=19.
        % Hand-computed: 0.08*28*250/19 = 560/19 = 29.473684210526315...
        % (repeating decimal, 9/19 remainder pattern) -- RelTol 1e-12 covers
        % double round-off only, not any code-fitted slack.
            val = TailL1.compute_S_VT(0.08, 28, 250, 19);
            tc.verifyEqual(val, 29.473684210526315, 'RelTol', 1e-12);
        end

        function testComputeSHTRejectsNonPositiveDenominator(tc)
        % L_HT=0 would divide by zero -- guarded mustBePositive.
            tc.verifyError(@() TailL1.compute_S_HT(0.4, 9, 250, 0), 'MATLAB:validators:mustBePositive');
        end

        % ================================================================ %
        % High-level TailL1.size: combines the pieces, arbitrary scalars
        % ================================================================ %

        function testSizeMatchesHandComputedFormula(tc)
        % A plain struct suffices as `obj` -- TailL1.size only reads
        % obj.c_HT/obj.c_VT via dot access, which structs support.
        %   c_HT=0.45, c_VT=0.08, S_ref=250, b=28, cbar=9.5, L_fus=40
        %   L_HT=L_VT=0.475*40=19
        %   S_ht = 0.45*9.5*250/19 = 56.25 EXACTLY (see testComputeSHTFormula)
        %   S_vt = 0.08*28*250/19  = 29.473684210526315... (see testComputeSVTFormula)
            obj = struct('c_HT', 0.45, 'c_VT', 0.08);
            result = TailL1.size(obj, 250, 28, 9.5, 40);
            fprintf('\n    TailL1.size: S_ht received=%.9f expected=56.250000000 | S_vt received=%.9f expected=29.473684211\n', ...
                result.S_ht, result.S_vt);
            tc.verifyEqual(result.S_ht, 56.25, 'AbsTol', 1e-9, ...
                'S_ht must equal c_HT*cbar*S_ref/(0.475*L_fus).');
            tc.verifyEqual(result.S_vt, 29.473684210526315, 'RelTol', 1e-9, ...
                'S_vt must equal c_VT*b*S_ref/(0.475*L_fus).');
        end

        function testResultFieldNamesAreLowercase(tc)
        % Field names must be S_ht/S_vt (matching GeometryBase-derived
        % classes' own property casing, e.g. F16GeomL2.S_ht/S_vt).
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            result = TailL1.size(obj, 300, 30, 11, 46.5);
            tc.verifyTrue(isfield(result, 'S_ht'));
            tc.verifyTrue(isfield(result, 'S_vt'));
        end

        function testSizeScalesLinearlyWithSRef(tc)
        % Both S_ht and S_vt are directly proportional to S_ref with
        % everything else held fixed -- a structural invariant of the
        % formula, independent of the exact coefficient values.
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            r1 = TailL1.size(obj, 300, 30, 11, 46.5);
            r2 = TailL1.size(obj, 600, 30, 11, 46.5);
            tc.verifyEqual(r2.S_ht, 2 * r1.S_ht, 'RelTol', 1e-12);
            tc.verifyEqual(r2.S_vt, 2 * r1.S_vt, 'RelTol', 1e-12);
        end

        % ================================================================ %
        % F16TailL1 (Tier-3 concrete class)
        % ================================================================ %

        function testF16TailL1IsaTailSizingBase(tc)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyTrue(isa(F16TailL1(geom), 'TailSizingBase'));
        end

        function testF16TailL1IsaTailSizingModelL1(tc)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyTrue(isa(F16TailL1(geom), 'TailSizingModelL1'));
        end

        function testF16TailL1NetCoefficients(tc)
        % F16TailL1's constructor calls
        % TailL1.compute_tail_volume_coeffs('jet_fighter', true, true) --
        % this test asserts the RESULTING property values against the
        % independently hand-computed 0.315/0.063 (same numbers as
        % testCorrectionsBothAppliesF16NetValues, computed by hand there,
        % not read from the object under test).
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj = F16TailL1(geom);
            tc.verifyEqual(obj.c_HT, 0.315, 'AbsTol', 1e-12);
            tc.verifyEqual(obj.c_VT, 0.063, 'AbsTol', 1e-12);
        end

        function testF16TailL1SizeAgainstF16GeomL2WingGeometry(tc)
        % Feeds F16TailL1 with REAL F16GeomL2 wing geometry (S_ref, b_wing,
        % cbar_wing, L_fus), read live from an actual F16GeomL2 object
        % (independent of TailL1's own equations -- GeometryBase's
        % compute_span/compute_root_chord/compute_mac chain, Raymer 7th ed.
        % Eqs. 7.6-7.8) rather than hardcoding F16GeomL2's numbers again.
        %
        % HAND-COMPUTED EXPECTED VALUES (fraction arithmetic, not read from
        % the code under test): with S_ref=300, AR_wing=3.0, lambda=0.2275
        % (=91/400 exactly) -> b=sqrt(3*300)=30 exactly;
        % c_root=2*300/(30*1.2275)=8000/491 ft;
        % cbar=(2/3)*c_root*(1+lambda+lambda^2)/(1+lambda) = 2729080/241081
        %     = 11.320178695... ft  [Raymer 7th ed. Eqs. 7.6/7.8]
        % L_fus=46.5 -> L_HT=L_VT=0.475*46.5=22.0875 exactly.
        %   S_ht = 0.315*11.320178695*300/22.0875 = 41263689600/851980254
        %        = 48.432683041... ft^2
        %   S_vt = 0.063*30*300/22.0875 = 15120/589 = 25.670628183... ft^2
        % (Cross-checked independently against the geometry-equations-
        % expert's reported ~48.43268/~25.67063 -- both derivations agree.)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj    = F16TailL1(geom);
            result = obj.size();

            expected_S_ht = 48.432683041;
            expected_S_vt = 25.670628183;

            fprintf(['\n    F16TailL1.size (real F16GeomL2 wing geometry): ' ...
                     'S_ht received=%.6f expected=%.6f | S_vt received=%.6f expected=%.6f\n'], ...
                result.S_ht, expected_S_ht, result.S_vt, expected_S_vt);
            tc.verifyEqual(result.S_ht, expected_S_ht, 'RelTol', 1e-6, ...
                'F16TailL1 S_ht must match the hand-computed volume-coefficient formula result.');
            tc.verifyEqual(result.S_vt, expected_S_vt, 'RelTol', 1e-6, ...
                'F16TailL1 S_vt must match the hand-computed volume-coefficient formula result.');
        end

        function testF16TailL1AreasVsBrandtIsNotAssertedTight(tc)
        % Brandt agreement is NEVER a unit-test pass/fail gate (CLAUDE.md's
        % two-tier rule) -- this test only documents, via fprintf, that the
        % gap widens under the corrected 0.315/0.063 coefficients relative to
        % the flat 0.40/0.07 the old, superseded TailSizingLevel1 used (its
        % own retired test recorded S_ht~=58.4/S_vt~=27.1, ~46%/~55% below
        % Brandt's 108.0/60.0). No assertion here is tolerance-fitted to
        % Brandt; see examples/F16A/sanity_checks/tail_sizing_brandt_comparison.m for the
        % actual (non-pass/fail) comparison report.
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj    = F16TailL1(geom);
            result = obj.size();
            brandt_S_ht = 108.0;   % [Brandt Main!C18]
            brandt_S_vt = 60.0;    % [Brandt Main!H18]
            fprintf(['\n    F16TailL1 vs Brandt (informational only): ' ...
                     'S_ht=%.4f (Brandt=%.1f, %+.1f%%) | S_vt=%.4f (Brandt=%.1f, %+.1f%%)\n'], ...
                result.S_ht, brandt_S_ht, 100*(result.S_ht-brandt_S_ht)/brandt_S_ht, ...
                result.S_vt, brandt_S_vt, 100*(result.S_vt-brandt_S_vt)/brandt_S_vt);
            tc.verifyGreaterThan(result.S_ht, 0);
            tc.verifyGreaterThan(result.S_vt, 0);
        end

    end

end
