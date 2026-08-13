classdef TestTailL1 < matlab.unittest.TestCase
%TESTTAILL1  Unit tests for the generic TailL1 static toolbox and its F-16
%   Tier-3 concrete class F16TailL1.
%
%   METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA,
%   2018, Table 6.4 + accompanying text; 6th ed. Sec. 6.5.2, Eqs. (6.28)/
%   (6.29) and Table 6.4, pp.158-160]:
%
%     L_HT = x_c/4,HT - x_c/4,wing   [p.158: "Moment arm L is approximated as
%     L_VT = x_c/4,VT - x_c/4,wing    tail-quarter-chord to wing-quarter-chord
%                                     distance."]
%     c_HT = c_HT_base * (1 - 0.10) * (1 - 0.125)   [if RSS and all-moving tail]
%     c_VT = c_VT_base * (1 - 0.10)                 [if RSS; no VT-specific
%                                                     text correction exists]
%     S_VT = c_VT * b    * S_ref / L_VT
%     S_HT = c_HT * cbar * S_ref / L_HT
%
%   ARM DEFINITION CORRECTED 2026-08-11. These tests previously asserted
%   L_HT = L_VT = 0.475*L_fus everywhere. That fraction is still tested (it is
%   still Raymer's own p.159-160 rule) but it is now understood, and
%   documented in TailL1.m, as his PRE-LAYOUT APPROXIMATION of the p.158
%   station-to-station arm, valid only where no layout exists. Where a layout
%   does exist it reads 22.09 ft against a real 15.09 ft for the F-16A, +46%,
%   and S_HT is inversely proportional to it.
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
%
%   SIGNATURE CHANGE (2026-08-11), which several tests below exercise:
%   size(obj, S_ref, b, cbar, L_HT, L_VT). The fifth argument used to be
%   L_fus and the arm was 0.475*L_fus computed inside. The arm is now
%   SUPPLIED by the caller, and the two surfaces get SEPARATE arms, because
%   Raymer prints L_VT in Eq. (6.28) and L_HT in Eq. (6.29) and the two are
%   genuinely different distances once they come from real stations.

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

        % ---------------------------------------------------------------- %
        % compute_tail_arm_quarter_chord -- Raymer's ACTUAL arm definition
        % (added 2026-08-11 with the tail-arm fix).
        % ---------------------------------------------------------------- %

        function testTailArmQuarterChordIsAStationDifference(tc)
        % [Raymer 6th ed. Sec. 6.5.2, p.158, verbatim: "Moment arm L is
        % approximated as tail-quarter-chord to wing-quarter-chord
        % distance."]  L = x_c/4,tail - x_c/4,wing -- a pure subtraction, so
        % arbitrary invented stations are the honest test of it.
        % Hand-computed: 40.5 - 25.25 = 15.25 ft EXACTLY.
            L = TailL1.compute_tail_arm_quarter_chord(40.5, 25.25);
            tc.verifyEqual(L, 15.25, 'AbsTol', 1e-12, ...
                'The arm must be the tail-c/4 minus wing-c/4 station difference.');
        end

        function testTailArmQuarterChordRejectsForwardSurface(tc)
        % A surface FORWARD of the wing c/4 is a canard, which Raymer sizes by
        % a different method (Sec. 6.5.2 "Canard"; Nicolai Eq. 11.3). Eqs.
        % (6.28)/(6.29) divide by the arm, so a non-positive arm must error
        % rather than return a negative area.
            tc.verifyError(@() TailL1.compute_tail_arm_quarter_chord(20.0, 25.25), ...
                'TailL1:nonPositiveTailArm');
            tc.verifyError(@() TailL1.compute_tail_arm_quarter_chord(25.25, 25.25), ...
                'TailL1:nonPositiveTailArm', ...
                'A ZERO arm must error too -- it is a division by zero in Eq. (6.29).');
        end

        function testFuselageFractionIsNotTheQuarterChordArm(tc)
        % THE REGRESSION THIS FILE EXISTS TO PREVENT (2026-08-11). The two
        % statics are NOT interchangeable: compute_tail_arm is Raymer's
        % PRE-LAYOUT approximation (p.159-160) of the p.158 station-to-station
        % arm compute_tail_arm_quarter_chord returns. For the F-16A layout the
        % approximation reads 22.0875 ft (hand-computed: 0.475*46.5) against a
        % real 15.0927520477 ft (hand-derived in
        % testF16TailL1SizeAgainstF16GeomL2WingGeometry below), +46.3 %, and
        % S_HT is inversely proportional to the arm. Asserting they DISAGREE
        % is what stops the fraction being silently reinstated.
            geom       = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            approx_arm = TailL1.compute_tail_arm(geom.L_fus);
            tc.verifyEqual(approx_arm, 22.0875, 'AbsTol', 1e-12, ...
                'The pre-layout fraction is still 0.475*L_fus = 0.475*46.5.');
            tc.verifyGreaterThan(abs(approx_arm - geom.L_HT) / geom.L_HT, 0.40, ...
                ['0.475*L_fus must NOT be used as the F-16A''s tail arm: it ' ...
                 'overstates the real wing-c/4-to-HT-c/4 distance by >40 %.']);
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
        %   c_HT=0.45, c_VT=0.08, S_ref=250, b=28, cbar=9.5, L_HT=L_VT=19
        % The arms are ARGUMENTS now (signature change, see this file's
        % header); 19 ft is an invented scalar chosen because it divides both
        % numerators exactly, NOT because it is 0.475 of anything.
        %   S_ht = 0.45*9.5*250/19 = 56.25 EXACTLY (see testComputeSHTFormula)
        %   S_vt = 0.08*28*250/19  = 29.473684210526315... (see testComputeSVTFormula)
            obj = struct('c_HT', 0.45, 'c_VT', 0.08);
            result = TailL1.size(obj, 250, 28, 9.5, 19, 19);
            fprintf('\n    TailL1.size: S_ht received=%.9f expected=56.250000000 | S_vt received=%.9f expected=29.473684211\n', ...
                result.S_ht, result.S_vt);
            tc.verifyEqual(result.S_ht, 56.25, 'AbsTol', 1e-9, ...
                'S_ht must equal c_HT*cbar*S_ref/L_HT.');
            tc.verifyEqual(result.S_vt, 29.473684210526315, 'RelTol', 1e-9, ...
                'S_vt must equal c_VT*b*S_ref/L_VT.');
        end

        function testSizeUsesEachSurfacesOwnArm(tc)
        % ADDED 2026-08-11 with the two-arm signature. Raymer prints L_VT in
        % Eq. (6.28) and L_HT in Eq. (6.29) as DIFFERENT symbols, and once the
        % arms come from real stations they differ (the VT mac c/4 is not the
        % HT mac c/4). Passing one arm to both surfaces raises no error and
        % returns a plausible wrong area, so the two are given DELIBERATELY
        % different values here and each result is hand-computed against its
        % OWN arm:
        %   c_HT=0.45, c_VT=0.08, S_ref=250, b=28, cbar=9.5, L_HT=19, L_VT=20
        %   S_ht = 0.45*9.5*250/19 = 1068.75/19 = 56.25 EXACTLY
        %   S_vt = 0.08*28*250/20  =  560/20     = 28.00 EXACTLY
        % If L_HT were used for both, S_vt would come out 560/19 = 29.4737;
        % if L_VT were used for both, S_ht would come out 1068.75/20 = 53.4375.
            obj    = struct('c_HT', 0.45, 'c_VT', 0.08);
            result = TailL1.size(obj, 250, 28, 9.5, 19, 20);
            tc.verifyEqual(result.S_ht, 56.25, 'AbsTol', 1e-9, ...
                'S_ht must divide by L_HT (19), not L_VT (20).');
            tc.verifyEqual(result.S_vt, 28.00, 'AbsTol', 1e-9, ...
                'S_vt must divide by L_VT (20), not L_HT (19).');
        end

        function testResultFieldNamesAreLowercase(tc)
        % Field names must be S_ht/S_vt (matching GeometryBase-derived
        % classes' own property casing, e.g. F16GeomL2.S_ht/S_vt).
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            result = TailL1.size(obj, 300, 30, 11, 15, 16);
            tc.verifyTrue(isfield(result, 'S_ht'));
            tc.verifyTrue(isfield(result, 'S_vt'));
        end

        function testSizeScalesLinearlyWithSRef(tc)
        % Both S_ht and S_vt are directly proportional to S_ref with
        % everything else held fixed -- a structural invariant of the
        % formula, independent of the exact coefficient values and of the
        % arms (which are held fixed at two invented, unequal scalars).
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            r1 = TailL1.size(obj, 300, 30, 11, 15, 16);
            r2 = TailL1.size(obj, 600, 30, 11, 15, 16);
            tc.verifyEqual(r2.S_ht, 2 * r1.S_ht, 'RelTol', 1e-12);
            tc.verifyEqual(r2.S_vt, 2 * r1.S_vt, 'RelTol', 1e-12);
        end

        function testSizeIsInverselyProportionalToTheArm(tc)
        % The structural invariant the whole 2026-08-11 fix turns on: S_HT and
        % S_VT go as 1/L. Halving each arm must exactly double each area,
        % whatever the coefficients are. This is why a +46 % arm error was
        % worth a -32 % area error.
            obj = struct('c_HT', 0.4, 'c_VT', 0.07);
            r1 = TailL1.size(obj, 300, 30, 11, 22.0875, 22.0875);
            r2 = TailL1.size(obj, 300, 30, 11, 11.04375, 11.04375);
            tc.verifyEqual(r2.S_ht, 2 * r1.S_ht, 'RelTol', 1e-12);
            tc.verifyEqual(r2.S_vt, 2 * r1.S_vt, 'RelTol', 1e-12);
        end

        % ================================================================ %
        % F16TailL1 (Tier-3 concrete class)
        % ================================================================ %

        function testF16TailL1IsaTailSizingBase(tc)
            tc.verifyTrue(isa(F16TailL1(), 'TailSizingBase'));
        end

        function testF16TailL1IsaTailSizingModelL1(tc)
            tc.verifyTrue(isa(F16TailL1(), 'TailSizingModelL1'));
        end

        function testF16TailL1NetCoefficients(tc)
        % F16TailL1's constructor calls
        % TailL1.compute_tail_volume_coeffs('jet_fighter', true, true) --
        % this test asserts the RESULTING property values against the
        % independently hand-computed 0.315/0.063 (same numbers as
        % testCorrectionsBothAppliesF16NetValues, computed by hand there,
        % not read from the object under test).
            obj = F16TailL1();
            tc.verifyEqual(obj.c_HT, 0.315, 'AbsTol', 1e-12);
            tc.verifyEqual(obj.c_VT, 0.063, 'AbsTol', 1e-12);
        end

        function testF16TailL1SizeAgainstF16GeomL2WingGeometry(tc)
        % Feeds F16TailL1 with REAL F16GeomL2 geometry (S_ref, b_wing,
        % cbar_wing and the two Dependent moment arms L_HT/L_VT), read live
        % from an actual F16GeomL2 object rather than hardcoding F16GeomL2's
        % numbers again.
        %
        % EXPECTED VALUES RECOMPUTED 2026-08-11 for the corrected arm. They
        % were 48.432683041 / 25.670628183, computed against
        % L_HT = L_VT = 0.475*L_fus = 22.0875 ft. That fraction is Raymer's
        % PRE-LAYOUT approximation (6th ed. p.159-160) of the p.158 arm, and
        % F16GeomL2 now has the layout, so the real station-to-station arms
        % apply. S_HT goes as 1/L_HT, so the areas rise.
        %
        % HAND-COMPUTED EXPECTED VALUES -- fraction/decimal arithmetic done in
        % this comment block from the JSON inputs, NOT read from the code
        % under test. Inputs [Brandt Main! row 18-23]: S_ref=300, AR_wing=3.0,
        % lambda_wing=0.2275, LE_sweep_wing=40 deg, x_apex_wing=17.786;
        % S_ht=108, AR_ht=3.0, lambda_ht=0.2275, LE_sweep_ht=40, x_le_ht=36;
        % S_vt=60, AR_vt=1.6, lambda_vt=0.5, LE_sweep_vt=40, x_le_vt=36.
        % Constant used: tan(40 deg) = 0.83909963117727793.
        %
        %  WING  [Raymer 7th ed. Eqs. 7.6/7.8 + GeometryBase.compute_y_mac]
        %   b       = sqrt(3*300) = 30 EXACTLY
        %   c_root  = 2*300/(30*1.2275) = 8000/491   = 16.2932790224 ft
        %   cbar    = (2/3)*c_root*(1.27925625/1.2275)
        %           = 2729080/241081                 = 11.3201786951 ft
        %   y_MAC   = (30/6)*(1.455/1.2275) = 2910/491 = 5.9266802444 ft
        %   x_MAC_LE= 17.786 + 5.9266802444*0.83909963117727793
        %           = 17.786 + 4.9730752071          = 22.7590752071 ft
        %   x_c/4   = 22.7590752071 + 0.25*11.3201786951
        %           = 22.7590752071 + 2.8300446738   = 25.5891198809 ft
        %  HORIZONTAL TAIL (mirrored surface -> centreline y_MAC form)
        %   b_ht    = sqrt(3*108) = 18 EXACTLY
        %   c_root  = 2*108/(18*1.2275) = 4800/491   =  9.7759674134 ft
        %   cbar_ht = 0.6*cbar_wing                  =  6.7921072171 ft
        %             (c_root_ht = 0.6*c_root_wing, and cbar is linear in it)
        %   y_MAC   = (18/6)*(582/491)               =  3.5560081466 ft
        %   x_MAC_LE= 36 + 3.5560081466*0.83909963117727793
        %           = 36 + 2.9838451243              = 38.9838451243 ft
        %   x_c/4   = 38.9838451243 + 1.6980268043   = 40.6818719286 ft
        %   L_HT    = 40.6818719286 - 25.5891198809  = 15.0927520477 ft
        %  VERTICAL TAIL (SINGLE PANEL -> panel y_MAC form, coefficient b/3)
        %   b_vt    = sqrt(1.6*60) = sqrt(96)        =  9.7979589711 ft
        %   c_root  = 2*60/(9.7979589711*1.5) = 10*sqrt(6)/3 = 8.1649658093 ft
        %   cbar_vt = (7/9)*c_root = 70*sqrt(6)/27   =  6.3505289628 ft
        %   y_MAC   = (9.7979589711/3)*(2/1.5) = 4*sqrt(96)/9 = 4.3546484316 ft
        %   x_MAC_LE= 36 + 4.3546484316*0.83909963117727793
        %           = 36 + 3.6539838928              = 39.6539838928 ft
        %   x_c/4   = 39.6539838928 + 1.5876322407   = 41.2416161335 ft
        %   L_VT    = 41.2416161335 - 25.5891198809  = 15.6524962526 ft
        %  AREAS  [Raymer 6th ed. Eqs. (6.28)/(6.29), c_HT=0.315, c_VT=0.063]
        %   S_ht = 0.315*11.3201786951*300/15.0927520477
        %        = 1069.7568866870/15.0927520477 = 70.878848560 ft^2
        %   S_vt = 0.063*30*300/15.6524962526
        %        =  567/15.6524962526            = 36.224253969 ft^2
        %
        % TOLERANCE. The arithmetic above is carried to 11-12 significant
        % figures through one tangent evaluation (a standard constant) and
        % four products/quotients, so its truncation is ~1e-10 relative.
        % RelTol 1e-7 is three decades of margin over that truncation. It is
        % NOT fitted to the code's output and is not a physical-scatter
        % allowance -- the only question here is whether the code evaluates
        % the equation it documents.
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));

            obj    = F16TailL1();
            result = obj.size(geom.S_ref, geom.b_wing, geom.cbar_wing, ...
                              geom.L_HT, geom.L_VT);

            expected_S_ht = 70.878848560;
            expected_S_vt = 36.224253969;

            fprintf(['\n    F16TailL1.size (real F16GeomL2 geometry, arms L_HT=%.7f L_VT=%.7f ft): ' ...
                     'S_ht received=%.6f expected=%.6f | S_vt received=%.6f expected=%.6f\n'], ...
                geom.L_HT, geom.L_VT, result.S_ht, expected_S_ht, result.S_vt, expected_S_vt);
            tc.verifyEqual(result.S_ht, expected_S_ht, 'RelTol', 1e-7, ...
                'F16TailL1 S_ht must match the hand-computed volume-coefficient formula result.');
            tc.verifyEqual(result.S_vt, expected_S_vt, 'RelTol', 1e-7, ...
                'F16TailL1 S_vt must match the hand-computed volume-coefficient formula result.');
            % The retired values, asserted against so the fuselage-fraction
            % arm cannot come back unnoticed.
            tc.verifyGreaterThan(abs(result.S_ht - 48.432683041) / 48.432683041, 0.30, ...
                'S_ht must NOT be the 0.475*L_fus-arm value 48.4327 ft^2 any more.');
            tc.verifyGreaterThan(abs(result.S_vt - 25.670628183) / 25.670628183, 0.30, ...
                'S_vt must NOT be the 0.475*L_fus-arm value 25.6706 ft^2 any more.');
        end

        function testF16TailL1AreasVsBrandtIsNotAssertedTight(tc)
        % Brandt agreement is NEVER a unit-test pass/fail gate (CLAUDE.md's
        % two-tier rule) -- this test only documents the gap via fprintf. No
        % assertion here is tolerance-fitted to Brandt, and NOTHING in this
        % file is adjusted to close the gap; see
        % examples/F16A/sanity_checks/tail_sizing_brandt_comparison.m for the actual
        % (non-pass/fail) comparison report.
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj    = F16TailL1();
            result = obj.size(geom.S_ref, geom.b_wing, geom.cbar_wing, ...
                              geom.L_HT, geom.L_VT);
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
