classdef TestWeightsL2 < matlab.unittest.TestCase
%TESTWEIGHTSL2  Unit tests for the Level-2 weight estimation toolbox.
%
%   Tests: WeightsL2 (static toolbox) + F16WeightsL2 (student class).
%
%   METHOD, and the two source tables it mixes:
%     (a) Raymer 6th ed. Table 15.2 surface density (psf x area) for structure:
%         wing 9.0, HT 4.0, VT 5.3 lbf/ft^2 on the EXPOSED planform areas;
%         fuselage 4.8 lbf/ft^2 on the WETTED area.
%     (b) AE481 metabook Sec. 7 "Fraction-Based Weight Estimates" (a SEPARATE,
%         UNNUMBERED table -- NOT Raymer Table 15.2, settled 2026-07-25
%         todo Sec. P4-7): LG 0.033*W_TO, installed engine 1.3 x bare,
%         all-else-empty 0.17*W_TO.
%     OEW = W_wings + W_tail.HT + W_tail.VT + W_fuselage + W_landing_gear
%           + W_installed_engine + W_all_else_empty + W_strake
%     (c) Strake (LERX), ADDED 2026-07-29: Brandt F-16A.xls Main!D18 (S_strake
%         = 20 ft^2) / Wt!H7 (k_strake = 4.5 lbf/ft^2) -- the only available
%         source, since Raymer Table 15.2 has no strake/LERX category. See
%         F16WeightsL2.m's S_strake/k_strake property comment.
%
%   CONSTRUCTOR (Phase 4, 2026-07-25):
%     F16WeightsL2(json_path, req_path, geom, prop) -- all four REQUIRED.
%       json_path = f16a_spec_path(2)          req_path = f16a_requirements_path()
%       geom      = (1,1) GeometryModelL2      prop     = (1,1) PropulsionBase
%
%   ======================================================================== %
%   ! THE OEW-vs-BRANDT AGREEMENT CHECK IS NOT IN THIS FILE ANY MORE.
%
%   Removed in Phase 4 (LOCKED; F16WeightsL2.md §4, docs/
%   weights_parameter_usage.md §4, review finding #14):
%       testOEWWithinBrandtValue   (expected = 19148, +-20 %, cited "Brandt B12")
%   Brandt Wt!B12 is 19980.700578 (live-read 2026-07-25); 19,148.08 is
%   corrections.xls Wt!B12 (Casey's revised-weight workbook, F16Baseline.m:136).
%   Two distinct provenances ~4.3 % apart. Beyond the mis-citation, that test
%   was anchored 4.2 % LOW, so keeping it would have biased every weight in the
%   framework light -- and per CLAUDE.md's two-tier rule an agreement check is
%   not a unit test at all. Both figures are now labelled columns of
%   examples/F16A/weights_brandt_comparison.m (Brandt = 19,980.70,
%   Alt = 19,148.08). The old header block also mis-cited it; corrected here.
%
%   NOTHING IN THIS FILE MAY TAKE AN EXPECTED VALUE FROM
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json OR FROM THE COMPARISON
%   REPORT. Every expected value is a structural invariant, an internal
%   identity, a table constant transcribed from a named repo extract with
%   file:line, or hand arithmetic recorded below.
%   ======================================================================== %
%
%   HAND-COMPUTED EXPECTED VALUES. Coefficients transcribed from
%   temp_AI/docs/disciplines/reference_extracts/metabook_data.md:
%     wing 9 lb/ft^2 :321 | H-tail 4 :322 | V-tail 5.3 :323 | fuselage 4.8 :324
%     LG (fighter) 0.033*W0 :330 | installed engine 1.3 x bare :333
%     all-else empty 0.17*W0 :334
%   Geometry areas are the EXPOSED/WETTED quantities the geometry tier supplies
%   by DI, independently verified against Brandt Geom! in TestGeomL2:
%     S_w = 196.226069, S_ht = 49.847251, S_vt = 40.889669,
%     S_wet_fus = 730.302320 ft^2 (all quoted to 6 dp).
%
%     (1) W_wings        = 9.0 * 196.226069  = 1766.034621 lbf
%     (2) W_tail.HT      = 4.0 *  49.847251  =  199.389004 lbf
%     (3) W_tail.VT      = 5.3 *  40.889669  =  216.715246 lbf
%           5.3*40.889669 = 204.448345 + 12.266901 = 216.715246
%     (4) W_fuselage     = 4.8 * 730.302320  = 3505.451136 lbf
%     (5) W_landing_gear = 0.033 * 31377     = 1035.441    lbf  (exact)
%     (6) W_all_else     = 0.17  * 31377     = 5334.09     lbf  (exact)
%     (7) W_en, Raymer 7th ed. Eq. 10.10 [raymer_data.md:38]
%           W = 0.0637 * T^1.1 * M^0.25 * exp(-0.81*BPR)
%         with T = prop.T_SL = 23770, M = design_mach = 2.0,
%         BPR = prop.bypass_ratio = 0.71:
%           ln(23770) = ln 2 + ln(1.1885) + ln(1e4)
%             ln(1.1885) = ln 1.2 + ln(0.9904167)
%                        = 0.18232156 - 0.00962949 = 0.17269207
%             ln(23770)  = 0.69314718 + 0.17269207 + 9.21034037 = 10.07617962
%           23770^1.1 = exp(1.1 * 10.07617962) = exp(11.08379758)
%             exp(0.08379758) = 1 + 0.08379758 + 0.00351102 + 0.00009806
%                                 + 0.00000205 + 0.00000003 = 1.08740874
%             exp(11) * 1.08740874 = 59874.14172 * 1.08740874
%                                  = 59874.14172 + 5233.5227 = 65107.6644
%           2^0.25 = 1.18920712
%           exp(-0.81*0.71) = exp(-0.5751) = exp(-0.6) * exp(0.0249)
%                           = 0.54881164 * 1.02521257 = 0.56264563
%           0.0637 * 65107.6644           = 4147.3582
%                  * 1.18920712           = 4932.0679
%                  * 0.56264563           = 2775.0065 lbf   (UNINSTALLED)
%     (8) W_installed_engine = 1.3 * N_en * W_en = 1.3 * 1 * 2775.0065
%                            = 3607.5085 lbf   (the x1.3 is L2-ONLY)
%     (9) W_en_brandt = 0.199 * 23770 = 4730.23 lbf (exact) -- ALTERNATE,
%         already installed, never summed into OEW.
%    (10) OEW(31377) = (1)+(2)+(3)+(4)+(5)+(8)+(6)+(12)
%           1766.034621 + 199.389004 = 1965.423625
%                       + 216.715246 = 2182.138871
%                       + 3505.451136 = 5687.590007
%                       + 1035.441    = 6723.031007
%                       + 3607.5085   = 10330.539507
%                       + 5334.09     = 15664.629507
%                       + 90.00       = 15754.629507 lbf
%    (12) W_strake = k_strake * S_strake = 4.5 * 20 = 90.00 lbf (exact)
%         [Brandt Main!D18 / Wt!H7]. ADDED 2026-07-29.
%    (11) Finding-#5 identity: only the LG and all-else terms scale with W_TO,
%         so for any W1, W2:
%           OEW(W2) - OEW(W1) = (0.17 + 0.033) * (W2 - W1)
%         At 45000 and 31377: 0.203 * 13623 = 2765.469 lbf, EXACTLY. This is
%         closed-form decimal arithmetic, not a regression -- hence AbsTol 1e-6
%         (double round-off on numbers of order 1e4), not a percentage.
%
%   TOLERANCE RATIONALE.
%     * Rows (5), (6), (9), (11) are exact decimal products -> AbsTol 1e-6.
%     * Rows (1)-(4) are exact products of a table constant and a 6-dp area, so
%       the only error is the 6-dp truncation of the quoted area
%       (<= 9 * 5e-7 = 4.5e-6 lbf) -> AbsTol 1e-4 gives ~1 order of margin.
%     * Rows (7), (8), (10) carry ~8 significant figures through two chained
%       exp/ln series evaluations; that arithmetic truncation is ~5e-6
%       relative -> RelTol 2e-5 for (7)/(8) and 1e-5 for the (10) sum, where
%       the Eq. 10.10 term is only 23 % of the total.
%   None of these tolerances is fitted to the code's output. In particular
%   there is NO "+-20 % statistical scatter" tolerance anywhere in this file:
%   Table 15.2's scatter is a property of the METHOD versus a real aircraft,
%   which is the comparison report's subject, not this file's.

    % ------------------------------------------------------------------ %
    % Inheritance / interface compliance / construction contract
    % ------------------------------------------------------------------ %

    methods (Test)

        function testIsaWeightsBase(tc)
            tc.verifyTrue(isa(TestWeightsL2.makeW2(), 'WeightsBase'), ...
                'F16WeightsL2 must inherit WeightsBase (Tier-1 contract).');
        end

        function testIsaWeightsModelL2(tc)
            tc.verifyTrue(isa(TestWeightsL2.makeW2(), 'WeightsModelL2'), ...
                'F16WeightsL2 must inherit WeightsModelL2 (Tier-2a contract).');
        end

        function testNotIsaWeightsModelL1(tc)
            tc.verifyFalse(isa(TestWeightsL2.makeW2(), 'WeightsModelL1'), ...
                'F16WeightsL2 must NOT inherit WeightsModelL1.');
        end

        function testConstructorRequiresAllFourArguments(tc)
        %TESTCONSTRUCTORREQUIRESALLFOURARGUMENTS  No silent default anywhere.
        %   A defaulted injection would silently re-freeze engine or geometry
        %   data -- the defect class Phase 4 removes (review findings #5/#11).
            tc.verifyError(@() F16WeightsL2(), 'MATLAB:minrhs', ...
                'F16WeightsL2 must require json_path.');
            tc.verifyError(@() F16WeightsL2(f16a_spec_path(2)), 'MATLAB:minrhs', ...
                'F16WeightsL2 must require req_path.');
            tc.verifyError(@() F16WeightsL2(f16a_spec_path(2), f16a_requirements_path()), ...
                'MATLAB:minrhs', 'F16WeightsL2 must require an injected geom.');
        end

        function testWrongGeomTierErrorsAtConstruction(tc)
        %TESTWRONGGEOMTIERERRORSATCONSTRUCTION  The finding-#10 lesson.
        %   The geom argument is typed (1,1) GeometryModelL2, not the looser
        %   GeometryBase. Phase 2d showed that a too-loose guard lets a wrong
        %   tier construct fine and then resolve property names to DIFFERENT
        %   physical quantities mid-run, with no error. An L1 or an L3 geometry
        %   object must therefore fail HERE, at construction.
            prop = TestWeightsL2.makeProp();
            g1   = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            g3   = F16GeomL3(f16a_spec_path(3), prop);
            tc.verifyError(@() F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g1, prop), ...
                'MATLAB:validation:UnableToConvert', ...
                'An L1 geometry object must be rejected at construction.');
            tc.verifyError(@() F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), g3, prop), ...
                'MATLAB:validation:UnableToConvert', ...
                'An L3 geometry object must be rejected at construction (L2 wants GeometryModelL2).');
        end

        function testJetFighterCategorySetCorrectly(tc)
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(lower(w.aircraft_category), 'jet_fighter', ...
                'F16WeightsL2 aircraft_category must be "jet_fighter".');
        end

        function testDesignMachComesFromRequirementsFile(tc)
        %TESTDESIGNMACHCOMESFROMREQUIREMENTSFILE  Requirement, not spec data.
        %   design_mach lives in the fidelity-independent
        %   examples/F16A/f16a_requirements.json, not in .weights. Compared
        %   against the file so a JSON edit cannot silently desync, and
        %   separately asserted NOT to be the T.O. Mach LIMIT 2.05, which is a
        %   different number from Brandt's design Mach 2.0 (todo Sec. P4-13).
            R = jsondecode(fileread(f16a_requirements_path()));
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.design_mach, R.design_mach, ...
                'design_mach must come from f16a_requirements.json.');
            tc.verifyNotEqual(w.design_mach, 2.05, ...
                ['design_mach is Brandt Main! aircraft.Mmax = 2.0, NOT the T.O. ' ...
                 '1F-16A-1 operating Mach limit 2.05 (todo Sec. P4-13).']);
        end

    end

    % ------------------------------------------------------------------ %
    % Structural invariants and sanity bounds on OEW
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWLessThanWTO(tc)
            w = TestWeightsL2.makeW2();
            tc.verifyLessThan(w.OEW(31377), 31377, ...
                'L2 OEW must be less than W_TO for any physical design.');
        end

        function testOEWGreaterThanZero(tc)
            w = TestWeightsL2.makeW2();
            tc.verifyGreaterThan(w.OEW(31377), 0, 'L2 OEW must be positive.');
        end

        function testOEWAboveSanityMinimum(tc)
            % No real jet fighter has OEW/TOGW < 30 %. Engineering sanity
            % bound, no external expected value.
            w = TestWeightsL2.makeW2();
            tc.verifyGreaterThan(w.OEW(31377), 0.30 * 31377, ...
                'L2 OEW must exceed 30 % of W_TO (sanity bound for jet fighters).');
        end

    end

    % ------------------------------------------------------------------ %
    % Hand-computed per-equation values (header rows 1-10)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWingWeightHandComputed(tc)
            % Header row (1): 9.0 [metabook_data.md:321] * 196.226069.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.weight_wing(31377), 1766.034621, 'AbsTol', 1e-4, ...
                'W_wing must be 9.0 * S_exposed_wing = 1766.034621 lbf [Raymer Tbl 15.2].');
        end

        function testTailWeightsHandComputed(tc)
            % Header rows (2) and (3): 4.0 [:322] and 5.3 [:323].
            w = TestWeightsL2.makeW2();
            W_t = w.weight_tail(31377);
            tc.verifyEqual(W_t.HT, 199.389004, 'AbsTol', 1e-4, ...
                'W_HT must be 4.0 * S_exposed_ht = 199.389004 lbf [Raymer Tbl 15.2].');
            tc.verifyEqual(W_t.VT, 216.715246, 'AbsTol', 1e-4, ...
                'W_VT must be 5.3 * S_exposed_vt = 216.715246 lbf [Raymer Tbl 15.2].');
        end

        function testFuselageWeightHandComputed(tc)
            % Header row (4): 4.8 [:324] * the WETTED area (not planform).
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.weight_fuselage(31377), 3505.451136, 'AbsTol', 1e-4, ...
                'W_fus must be 4.8 * S_wet_fus = 3505.451136 lbf [Raymer Tbl 15.2].');
        end

        function testLandingGearWeightHandComputed(tc)
            % Header row (5): exact decimal product, 0.033 [:330] * 31377.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.weight_landing_gear(31377), 1035.441, 'AbsTol', 1e-6, ...
                'W_LG must be 0.033 * W_TO = 1035.441 lbf [AE481 metabook Sec. 7].');
        end

        function testAllElseEmptyHandComputed(tc)
            % Header row (6): exact decimal product, 0.17 [:334] * 31377.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(WeightsL2.weight_all_else_empty(w, 31377), 5334.09, ...
                'AbsTol', 1e-6, ...
                'W_all_else must be 0.17 * W_TO = 5334.09 lbf [AE481 metabook Sec. 7].');
        end

        function testEngineWeightEq1010HandComputed(tc)
            % Header row (7). Also an end-to-end check of the propulsion DI and
            % the requirements-file Mach: a wrong T, M or BPR moves this.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.W_en, 2775.0065, 'RelTol', 2e-5, ...
                ['W_en must be Raymer 7th ed. Eq. 10.10 UNINSTALLED = 2775.0065 lbf ' ...
                 'at T=23770, M=2.0, BPR=0.71 [raymer_data.md:38].']);
        end

        function testInstalledEngineHandComputed(tc)
            % Header row (8), and that the x1.3 [:333] is applied EXACTLY once.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.W_installed_engine, 3607.5085, 'RelTol', 2e-5, ...
                'W_installed_engine must be 1.3 * N_en * W_en = 3607.5085 lbf [metabook_data.md:333].');
            tc.verifyEqual(w.W_installed_engine, 1.3 * w.N_en * w.W_en, ...
                'AbsTol', 1e-9, ...
                'The 1.3 installed/bare factor must be applied exactly once.');
        end

        function testOEWHandComputed(tc)
        %TESTOEWHANDCOMPUTED  Header row (10) -- replaces the removed gate.
        %   The expected value is the hand-summed component list, so a change
        %   in any one component, coefficient or injected area breaks it.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.OEW(31377), 15754.629507, 'RelTol', 1e-5, ...
                ['L2 OEW(31377) must equal the hand-summed Table 15.2 + metabook ' ...
                 'Sec. 7 + strake buildup = 15754.629507 lbf.']);
        end

        function testStrakeWeightHandComputed(tc)
        %TESTSTRAKEWEIGHTHANDCOMPUTED  Header row (12). ADDED 2026-07-29.
        %   k_strake * S_strake = 4.5 * 20 = 90.00 lbf exactly [Brandt
        %   Main!D18 / Wt!H7]. No W_TO dependence -- pure area x density,
        %   same pattern as the other structural groups.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.W_strake, 90.00, 'AbsTol', 1e-9, ...
                'W_strake must be k_strake * S_strake = 4.5 * 20 = 90.00 lbf.');
            tc.verifyEqual(w.S_strake, 20.0, 'AbsTol', 1e-9, ...
                'S_strake must be read from f16a_L2.json as 20.0 ft^2 [Brandt Main!D18].');
            tc.verifyEqual(w.k_strake, 4.5, 'AbsTol', 1e-9, ...
                'k_strake must be read from f16a_L2.json as 4.5 lbf/ft^2 [Brandt Wt!H7].');
        end

        function testOEWEqualsSumOfItsComponents(tc)
        %TESTOEWEQUALSSUMOFITSCOMPONENTS  Internal aggregation identity.
        %   Guards against OEW drifting away from the per-component methods
        %   the report and the tests above exercise.
            w = TestWeightsL2.makeW2();
            W_TO  = 31377;
            W_t   = w.weight_tail(W_TO);
            total = w.weight_wing(W_TO) + W_t.HT + W_t.VT + w.weight_fuselage(W_TO) ...
                    + w.weight_landing_gear(W_TO) + WeightsL2.weight_installed_engine(w) ...
                    + WeightsL2.weight_all_else_empty(w, W_TO) + w.W_strake;
            tc.verifyEqual(w.OEW(W_TO), total, 'AbsTol', 1e-9, ...
                'OEW must equal the exact sum of its eight component terms.');
        end

    end

    % ------------------------------------------------------------------ %
    % REVIEW FINDING #5 -- W_all_else_empty was frozen at 0.17*31377
    % ------------------------------------------------------------------ %

    methods (Test)

        function testOEWScalesWithItsArgumentNotAFrozenWTO(tc)
        %TESTOEWSCALESWITHITSARGUMENTNOTAFROZENWTO  The finding-#5 guard.
        %
        %   The pre-Phase-4 constructor contained, verbatim:
        %       obj.W_all_else_empty = WeightsL2.weight_all_else_empty(obj, 31377);
        %   so OEW(W_TO) never recomputed the 0.17*W_TO term at its own
        %   argument. Two defects in one line: (a) stale under mutation --
        %   OEW(45000) carried an all-else group of 0.17*31377 = 5334.09 where
        %   0.17*45000 = 7650.00 is required, UNDERSTATING by 2315.91 lbf; and
        %   (b) 31,377 is Brandt Wt!B3, a sizing OUTPUT, forbidden as an input
        %   by CLAUDE.md. Every old TestWeightsL2 case called OEW(31377) -- the
        %   single argument at which the bug is invisible -- which is why no
        %   test caught it.
        %
        %   Only two terms scale with W_TO (LG 0.033, all-else 0.17), so the
        %   difference is exactly (0.17+0.033)*(W2-W1); header row (11).
            w = TestWeightsL2.makeW2();
            delta_expected = (0.17 + 0.033) * (45000 - 31377);   % 0.203*13623 = 2765.469
            tc.verifyEqual(delta_expected, 2765.469, 'AbsTol', 1e-9, ...
                'Guard on the guard: 0.203*13623 must be 2765.469.');
            tc.verifyEqual(w.OEW(45000) - w.OEW(31377), delta_expected, ...
                'AbsTol', 1e-6, ...
                ['OEW must pick up (0.17+0.033)*dW_TO from its two W_TO-scaling ' ...
                 'terms -- i.e. the all-else term must track the ARGUMENT.']);
        end

        function testOEWDoesNotUnderstateByTheFrozenAllElseAmount(tc)
        %TESTOEWDOESNOTUNDERSTATEBYTHEFROZENALLELSEAMOUNT  Pin the old value.
        %   Pins the specific wrong number the frozen-all-else code returned at
        %   W_TO = 45000, the way TestGeomL2 pins the VT 0.33 deg bug. The
        %   understatement is exactly 0.17*(45000-31377) = 2315.91 lbf.
            w = TestWeightsL2.makeW2();
            frozen_understatement = 0.17 * (45000 - 31377);       % 2315.91
            oew45 = w.OEW(45000);
            tc.verifyNotEqual(oew45, oew45 - frozen_understatement, ...
                'Sanity: the two figures must differ.');
            tc.verifyEqual(oew45 - w.OEW(31377) - 0.033 * (45000 - 31377), ...
                frozen_understatement, 'AbsTol', 1e-6, ...
                ['After removing the LG term, the remaining OEW(45000)-OEW(31377) ' ...
                 'difference must be exactly 0.17*13623 = 2315.91 lbf -- the ' ...
                 'amount the frozen constructor value used to lose.']);
        end

        function testOEWWorksWithWTOUnset(tc)
        %TESTOEWWORKSWITHWTOUNSET  OEW is a pure function of its argument.
        %   obj.W_TO is sizing-loop state and stays NaN until set; OEW(W_TO)
        %   must not consult it. If OEW ever reads obj.W_TO this returns NaN.
            w = TestWeightsL2.makeW2();
            tc.verifyTrue(isnan(w.W_TO), 'obj.W_TO must be NaN until set.');
            tc.verifyEqual(w.OEW(31377), 15754.629507, 'RelTol', 1e-5, ...
                'OEW must be computable with obj.W_TO unset.');
        end

    end

    % ------------------------------------------------------------------ %
    % REVIEW FINDING #11 -- geometry DI, and the exposed-vs-FULL name traps
    % ------------------------------------------------------------------ %

    methods (Test)

        function testGeometryDINameTraps(tc)
        %TESTGEOMETRYDINAMETRAPS  Lock the exposed-vs-FULL wiring.
        %   After the Phase-2 geometry rename, geom.S_ht / geom.S_vt mean the
        %   FULL planform (108 / 60 ft^2) on both geometry tiers, while Raymer
        %   Table 15.2 wants the EXPOSED planform. Wiring the FULL names raises
        %   NO error and returns a plausible wrong number, so the wrong value
        %   is asserted against explicitly.
        %   docs/weights_parameter_usage.md §2.
            [w, geom] = TestWeightsL2.makeW2();
            tc.verifyEqual(w.S_w,  geom.S_exposed_wing, 'AbsTol', 1e-9, ...
                'S_w must be geom.S_exposed_wing.');
            tc.verifyEqual(w.S_ht, geom.S_exposed_ht, 'AbsTol', 1e-9, ...
                'S_ht must be geom.S_exposed_ht.');
            tc.verifyEqual(w.S_vt, geom.S_exposed_vt, 'AbsTol', 1e-9, ...
                'S_vt must be geom.S_exposed_vt.');
            tc.verifyNotEqual(w.S_ht, geom.S_ht, ...
                'S_ht must NOT be geom.S_ht (the FULL 108 ft^2 planform).');
            tc.verifyNotEqual(w.S_vt, geom.S_vt, ...
                'S_vt must NOT be geom.S_vt (the FULL 60 ft^2 planform).');
            tc.verifyEqual(w.S_wet_fus, geom.get_S_wet_fuselage(), 'AbsTol', 1e-9, ...
                'S_wet_fus must be geom.get_S_wet_fuselage() [Roskam Vol. II Eq. 12.3].');
            tc.verifyNotEqual(w.S_wet_fus, 750, ...
                'S_wet_fus must no longer be the former stored 750 [estimate].');
        end

        function testEngineWeightIsNotTheFormerFrozenEstimate(tc)
        %TESTENGINEWEIGHTISNOTTHEFORMERFROZENESTIMATE  Pin the old literals.
        %   W_en used to be a stored 3030 [estimate; verify TO/Jane's] pinned to
        %   nothing, and W_installed_engine a constructor-frozen 1.3*3030 = 3939.
            w = TestWeightsL2.makeW2();
            tc.verifyNotEqual(w.W_en, 3030, ...
                'W_en must be computed from Eq. 10.10, not the former stored 3030.');
            tc.verifyNotEqual(w.W_installed_engine, 3939, ...
                'W_installed_engine must not be the former frozen 1.3*3030 = 3939.');
        end

        function testBrandtEngineAlternateIsNeverSummedIntoOEW(tc)
        %TESTBRANDTENGINEALTERNATEISNEVERSUMMEDINTOOEW  Decision-1 guard.
        %   W_en_brandt = 0.199*T_AB is Brandt's ALREADY-INSTALLED formula
        %   [Brandt Wt!B11; the 0.199 literal at 'Engn(s)'!D22]. It exists for
        %   the comparison report only. Two things must hold: OEW must use the
        %   Raymer figure, and the doubly-installed 1.3*4730.23 = 6149.299
        %   variant -- which agrees BEST with Brandt, and is rejected exactly
        %   for that reason -- must appear nowhere.
            w = TestWeightsL2.makeW2();
            tc.verifyEqual(w.W_en_brandt, 0.199 * 23770, 'AbsTol', 1e-6, ...
                'W_en_brandt must be 0.199 * T_SL = 4730.23 lbf exactly.');
            tc.verifyNotEqual(w.W_installed_engine, w.W_en_brandt, ...
                'The OFFICIAL installed engine weight must not be Brandt''s alternate.');
            tc.verifyNotEqual(w.W_installed_engine, 1.3 * w.W_en_brandt, ...
                'The REJECTED double-installed 1.3*0.199*T variant must not be used.');
            oew_official = w.OEW(31377);
            tc.verifyLessThan(abs(oew_official - 15754.629507), 1e-3 * 15754.629507, ...
                'OEW must be built on the Raymer engine weight, not the Brandt alternate.');
        end

    end

    % ------------------------------------------------------------------ %
    % REVIEW FINDING #12 -- the Dependent properties (12 -> 13, W_strake
    % added 2026-07-29)
    % ------------------------------------------------------------------ %

    methods (Test)

        function testAllThirteenDependentPropertiesExist(tc)
        %TESTALLTHIRTEENDEPENDENTPROPERTIESEXIST  The declared INPUT/DERIVED split.
        %   F16WeightsL2.md §2: 9 inputs (8 numeric + 1 string) + 2 injected
        %   objects; 13 Dependent (12 + W_strake, added 2026-07-29). A count
        %   change means the split moved and the sweeps below no longer cover
        %   what they claim to.
            names = TestWeightsL2.dependentNames();
            tc.verifyEqual(numel(names), 13, ...
                'F16WeightsL2 must declare exactly 13 Dependent properties.');
        end

        function testNoDependentPropertyIsNonFinite(tc)
        %TESTNODEPENDENTPROPERTYISNONFINITE  Finding #12's headline symptom.
        %   W_wings / W_landing_gear / W_tail / W_fuselage were declared
        %   abstract, satisfied with "= NaN", and never assigned by any code --
        %   so a consumer reading the documented contract got NaN. Sweeps ALL
        %   13 Dependents (metaclass-derived, so a newly added one is covered
        %   automatically) at a set W_TO and requires every scalar, including
        %   every field of the W_tail struct, to be finite.
            w = TestWeightsL2.makeW2();
            w.W_TO = 31377;
            vals = TestWeightsL2.flattenDependents(w);
            tc.verifyTrue(all(isfinite(vals)), ...
                'No Dependent property may read NaN or Inf at W_TO = 31377.');
            tc.verifyEqual(numel(vals), 14, ...
                'Sweep must cover 13 Dependents = 14 scalars (W_tail has HT and VT).');
        end

        function testGenuinelyWTODependentPropertiesErrorWhenWTOUnset(tc)
        %TESTGENUINELYWTODEPENDENTPROPERTIESERRORWHENWTOUNSET  No silent NaN.
        %   Phase-1e/1f precedent (F16GeomL1.requireWTO): a Dependent that
        %   needs a gross weight must ERROR with an identified message rather
        %   than return NaN. These two genuinely scale with W_TO.
            w = TestWeightsL2.makeW2();
            tc.verifyTrue(isnan(w.W_TO), 'Precondition: W_TO unset.');
            tc.verifyError(@() w.W_landing_gear, 'F16WeightsL2:WTONotSet', ...
                'W_landing_gear = 0.033*W_TO must error on unset W_TO, not return NaN.');
            tc.verifyError(@() w.W_all_else_empty, 'F16WeightsL2:WTONotSet', ...
                'W_all_else_empty = 0.17*W_TO must error on unset W_TO, not return NaN.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
        %TESTDERIVEDPROPERTIESAREREADONLY  Derived quantities are OUTPUTS.
        %   None of the 12 has a set-method, so assignment must error
        %   MATLAB:class:noSetMethod -- nothing can overwrite a live-computed
        %   value with a frozen literal, which is the anti-pattern Phase 4
        %   removed. setfield is used because a property assignment cannot
        %   appear inside an anonymous function. The list is metaclass-derived
        %   so a newly added Dependent is covered automatically.
            w     = TestWeightsL2.makeW2();
            names = TestWeightsL2.dependentNames();
            cellfun(@(n) tc.verifyError(@() setfield(w, n, 0), ...
                'MATLAB:class:noSetMethod', ...
                sprintf('Dependent property %s must be read-only.', n)), names);
            % Spot-check the two that were constructor-FROZEN before Phase 4.
            tc.verifyError(@() setfield(w, 'W_all_else_empty', 5334.09), ...
                'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(w, 'W_installed_engine', 3939), ...
                'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testDerivedLiveRecomputeOnMutation(tc)
        %TESTDERIVEDLIVERECOMPUTEONMUTATION  Optimization-ready property design.
        %   The sizing loop mutates design variables in place and expects
        %   updated outputs on the next read, with NO reconstruction. Three
        %   independent mutation paths are exercised: the injected geometry, the
        %   injected engine, and the requirements-file Mach.
            [w, geom, prop] = TestWeightsL2.makeW2();
            w.W_TO = 31377;

            % (a) geometry DI: S_ref up -> exposed wing area up -> W_wings up.
            S_w_before  = w.S_w;
            W_w_before  = w.W_wings;
            geom.S_ref  = geom.S_ref + 50;
            tc.verifyGreaterThan(w.S_w, S_w_before, ...
                'S_w must track geom.S_ref live (geometry DI).');
            tc.verifyGreaterThan(w.W_wings, W_w_before, ...
                'W_wings must track the geometry change live -- no cached copy.');
            tc.verifyEqual(w.W_wings, 9.0 * w.S_w, 'AbsTol', 1e-9, ...
                'W_wings must stay 9.0 * S_w after mutation.');

            % (b) propulsion DI: thrust up -> Eq. 10.10 W_en up -> installed up.
            W_en_before = w.W_en;
            W_ie_before = w.W_installed_engine;
            prop.T_SL   = 30000;
            tc.verifyGreaterThan(w.W_en, W_en_before, ...
                'W_en must track prop.T_SL live (Eq. 10.10 T^1.1).');
            tc.verifyGreaterThan(w.W_installed_engine, W_ie_before, ...
                'W_installed_engine must track W_en live -- it was frozen before Phase 4.');
            tc.verifyEqual(w.W_en_brandt, 0.199 * 30000, 'AbsTol', 1e-6, ...
                'W_en_brandt must track prop.T_SL live too.');

            % (c) requirement: design Mach up -> Eq. 10.10 M^0.25 up.
            W_en_at_M20   = w.W_en;
            w.design_mach = 2.05;
            tc.verifyGreaterThan(w.W_en, W_en_at_M20, ...
                'W_en must track design_mach live (Eq. 10.10 M^0.25).');
        end

    end

    % ------------------------------------------------------------------ %
    % DELIBERATELY-FAILING TODO (pending source change) -- EXPECTED RED
    % ------------------------------------------------------------------ %

    methods (Test)

        function testGuardsEncodeOnlyRealWTODependencies(tc)
        %TESTGUARDSENCODEONLYREALWTODEPENDENCIES  A guard must encode a real
        %   dependency, not a house style.
        %
        %   Of the six component/group Dependents only these genuinely depend on
        %   W_TO, and they are the only ones guarded:
        %       W_landing_gear   = 0.033 * W_TO
        %       W_all_else_empty = 0.17  * W_TO
        %   The rest are pure area x density -- WeightsL2.weight_wing, weight_tail
        %   and weight_fuselage all declare W_TO as `~` and never read it
        %   (WeightsL2.m:81,92,108) -- and W_installed_engine is a thrust
        %   correlation. All four must be readable WITHOUT a W_TO.
        %
        %   HISTORY (todo 2026-07-25 Phase 4 §P4-18). Phase 4 first routed the
        %   three structural getters through requireWTO as well, with a docstring
        %   claiming the guard was applied "UNIFORMLY to all six". It was applied
        %   to five -- W_installed_engine was never guarded -- so the stated
        %   rationale did not describe the code, and the guard asserted a
        %   dependency the formulas do not have. This test replaced the
        %   deliberately-red testTODO_ that drove that fix; it is now a positive
        %   assertion and must stay green.
        %
        %   Do NOT "simplify" this by re-adding the guards, and do NOT unguard
        %   W_landing_gear or W_all_else_empty -- those two must keep erroring,
        %   which testGenuinelyWTODependentPropertiesErrorWhenWTOUnset asserts.
            w = TestWeightsL2.makeW2();
            tc.verifyTrue(isnan(w.W_TO), 'Precondition: W_TO unset.');
            for name = ["W_wings", "W_tail", "W_fuselage", "W_installed_engine", "W_strake"]
                tc.verifyTrue(TestWeightsL2.readsWithoutError(w, char(name)), ...
                    sprintf(['%s has no W_TO dependence (its toolbox method takes ' ...
                             'W_TO as ~) and must be readable without one -- a guard ' ...
                             'here would assert a dependency that does not exist.'], name));
            end
        end

    end

    % ------------------------------------------------------------------ %
    % Lookup tables -- expecteds transcribed from metabook_data.md
    % ------------------------------------------------------------------ %

    methods (Test)

        function testWingUnitWeightAllCategories(tc)
            % metabook_data.md:321 -- fighters 9 / transport 10 / GA 2.5.
            tc.verifyEqual(WeightsL2.wing_unit_weight('jet_fighter'), 9.0, ...
                'AbsTol', 1e-6, 'jet_fighter wing psf must be 9.0 [metabook_data.md:321].');
            tc.verifyEqual(WeightsL2.wing_unit_weight('jet_transport'), 10.0, ...
                'AbsTol', 1e-6, 'jet_transport wing psf must be 10.0 [metabook_data.md:321].');
            tc.verifyEqual(WeightsL2.wing_unit_weight('general_aviation'), 2.5, ...
                'AbsTol', 1e-6, 'general_aviation wing psf must be 2.5 [metabook_data.md:321].');
        end

        function testTailUnitWeightsAllCategories(tc)
            % metabook_data.md:322 (H-tail 4 / 5.5 / 2) and :323 (V-tail 5.3 / 5.5 / 2).
            tc.verifyEqual(WeightsL2.HT_unit_weight('jet_fighter'), 4.0, ...
                'AbsTol', 1e-6, 'jet_fighter HT psf must be 4.0 [metabook_data.md:322].');
            tc.verifyEqual(WeightsL2.HT_unit_weight('jet_transport'), 5.5, ...
                'AbsTol', 1e-6, 'jet_transport HT psf must be 5.5 [metabook_data.md:322].');
            tc.verifyEqual(WeightsL2.HT_unit_weight('general_aviation'), 2.0, ...
                'AbsTol', 1e-6, 'general_aviation HT psf must be 2.0 [metabook_data.md:322].');
            tc.verifyEqual(WeightsL2.VT_unit_weight('jet_fighter'), 5.3, ...
                'AbsTol', 1e-6, 'jet_fighter VT psf must be 5.3 [metabook_data.md:323].');
            tc.verifyEqual(WeightsL2.VT_unit_weight('jet_transport'), 5.5, ...
                'AbsTol', 1e-6, 'jet_transport VT psf must be 5.5 [metabook_data.md:323].');
            tc.verifyEqual(WeightsL2.VT_unit_weight('general_aviation'), 2.0, ...
                'AbsTol', 1e-6, 'general_aviation VT psf must be 2.0 [metabook_data.md:323].');
        end

        function testFuselageUnitWeightAllCategories(tc)
            % metabook_data.md:324 -- fighters 4.8 / transport 5 / GA 1.4.
            tc.verifyEqual(WeightsL2.fus_unit_weight('jet_fighter'), 4.8, ...
                'AbsTol', 1e-6, 'jet_fighter fuselage psf must be 4.8 [metabook_data.md:324].');
            tc.verifyEqual(WeightsL2.fus_unit_weight('jet_transport'), 5.0, ...
                'AbsTol', 1e-6, 'jet_transport fuselage psf must be 5.0 [metabook_data.md:324].');
            tc.verifyEqual(WeightsL2.fus_unit_weight('general_aviation'), 1.4, ...
                'AbsTol', 1e-6, 'general_aviation fuselage psf must be 1.4 [metabook_data.md:324].');
        end

        function testLGFractionCitedRows(tc)
        %TESTLGFRACTIONCITEDROWS  Only the two rows the extract supports.
        %   metabook_data.md:330 fighter 0.033, :332 transport 0.043. The coded
        %   general_aviation 0.057 row is deliberately NOT asserted: the extract
        %   has no GA landing-gear row, so the value has no in-repo source
        %   (todo Sec. P4-7, open). Asserting 0.057 would manufacture a green
        %   over a missing citation.
            tc.verifyEqual(WeightsL2.LG_fraction('jet_fighter'), 0.033, ...
                'AbsTol', 1e-9, 'jet_fighter LG fraction must be 0.033 [metabook_data.md:330].');
            tc.verifyEqual(WeightsL2.LG_fraction('jet_transport'), 0.043, ...
                'AbsTol', 1e-9, 'jet_transport LG fraction must be 0.043 [metabook_data.md:332].');
            tc.verifyNotEqual(WeightsL2.LG_fraction('jet_fighter'), 0.034, ...
                ['The framework uses the metabook 0.033, NOT Brandt Wt!F23 = 0.034 ' ...
                 '(locked decision, user 2026-07-24). Two different models.']);
        end

        function testLGFractionHasNoNavyFighterRow(tc)
        %TESTLGFRACTIONHASNONAVYFIGHTERROW  Records an absence as a decision.
        %   metabook_data.md:331 carries a Navy-fighter row (0.045 * W0) that
        %   the lookup deliberately does not add -- no consumer exists, and
        %   adding it would be a feature beyond this phase. Asserted so the
        %   absence reads as a decision rather than an oversight (todo P4-7).
            tc.verifyError(@() WeightsL2.LG_fraction('navy_fighter'), ...
                'WeightsL2:UnknownCategory', ...
                'navy_fighter is deliberately not a coded LG_fraction row (todo Sec. P4-7).');
        end

        function testLookupUnknownCategoryErrors(tc)
            % Error contract on every lookup, not just the wing one.
            tc.verifyError(@() WeightsL2.wing_unit_weight('spaceship'), ...
                'WeightsL2:UnknownCategory', 'wing_unit_weight must reject unknown categories.');
            tc.verifyError(@() WeightsL2.HT_unit_weight('spaceship'), ...
                'WeightsL2:UnknownCategory', 'HT_unit_weight must reject unknown categories.');
            tc.verifyError(@() WeightsL2.VT_unit_weight('spaceship'), ...
                'WeightsL2:UnknownCategory', 'VT_unit_weight must reject unknown categories.');
            tc.verifyError(@() WeightsL2.fus_unit_weight('spaceship'), ...
                'WeightsL2:UnknownCategory', 'fus_unit_weight must reject unknown categories.');
            tc.verifyError(@() WeightsL2.LG_fraction('spaceship'), ...
                'WeightsL2:UnknownCategory', 'LG_fraction must reject unknown categories.');
        end

        function testUnknownCategoryPropagatesThroughTheBuildup(tc)
        %TESTUNKNOWNCATEGORYPROPAGATESTHROUGHTHEBUILDUP  Guard the whole path.
        %   An unknown aircraft_category must fail loudly at OEW, not silently
        %   fall back to a default psf row.
            w = TestWeightsL2.makeW2();
            w.aircraft_category = 'spaceship';
            tc.verifyError(@() w.OEW(31377), 'WeightsL2:UnknownCategory', ...
                'An unknown aircraft_category must propagate an error out of OEW.');
        end

    end

    % ------------------------------------------------------------------ %
    % Fixture / sweep helpers
    % ------------------------------------------------------------------ %

    methods (Static, Access = private)

        function [w, geom, prop] = makeW2()
        %MAKEW2  Build a FRESH F-16A L2 weights object plus its collaborators.
        %   Fresh geometry and propulsion objects every call: both are handle
        %   classes, and the mutation tests below change them in place.
            prop = TestWeightsL2.makeProp();
            geom = F16GeomL2(f16a_spec_path(2), prop);
            w    = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
        end

        function p = makeProp()
            p = F16PropL2(f16a_spec_path(2));
        end

        function names = dependentNames()
        %DEPENDENTNAMES  Metaclass-derived list of the Dependent properties.
        %   Derived rather than hardcoded so a newly added Dependent is swept
        %   automatically instead of silently escaping the guards.
            mc    = ?F16WeightsL2;
            pl    = mc.PropertyList;
            names = {pl([pl.Dependent]).Name};
        end

        function vals = flattenDependents(w)
        %FLATTENDEPENDENTS  Every Dependent read, structs expanded to scalars.
            names = TestWeightsL2.dependentNames();
            cells = cellfun(@(n) TestWeightsL2.flatten(w.(n)), names, ...
                'UniformOutput', false);
            vals  = [cells{:}];
        end

        function v = flatten(x)
        %FLATTEN  Numeric row vector from a scalar or a struct of scalars.
        %   The branch lives here, in a helper, so the test methods themselves
        %   stay free of control flow.
            if isstruct(x)
                v = reshape(cell2mat(struct2cell(x)), 1, []);
            else
                v = reshape(x, 1, []);
            end
        end

        function ok = readsWithoutError(w, name)
        %READSWITHOUTERROR  True if reading property `name` does not throw.
        %   try/catch lives here, in a helper, not in a test method.
            try
                w.(name);   %#ok<VUNUS>
                ok = true;
            catch
                ok = false;
            end
        end

    end

end
