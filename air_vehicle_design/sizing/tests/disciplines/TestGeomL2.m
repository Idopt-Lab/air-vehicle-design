classdef TestGeomL2 < matlab.unittest.TestCase
%TESTGEOML2  Unit tests for GeomL2, GeometryBase, and F16GeomL2.
%
%   2026-07-22: Geometry's former L3 fidelity tier was eliminated and merged
%   into L2 (user decision -- see src/disciplines/geometry/GeomL2.md's dated
%   note). This file now also carries the still-applicable test cases
%   formerly in tests/disciplines/TestGeomL3.m (duct-frustum formula,
%   degenerate-to-cylinder case, Brandt-nacelle sanity check), retargeted at
%   GeomL2/F16GeomL2 instead of the deleted GeomL3/F16GeomL3 -- TestGeomL3.m
%   is deleted. It also carries new tests for GeometryBase's Base-tier
%   planform statics (root/tip chord, MAC, span, sweep conversion) and for
%   the new GeomL2 methods added in the same pass (Roskam Eq. 12.1 variable-
%   tc planform, Brandt fuselage low-fi/high-fi alternates, exposed-area
%   computation).
%
%   Formula references:
%     Lifting surfaces (uniform tc, official-alternate): Brandt F-16A
%       workbook, Geom sheet, cell B13 -- S_wet = S_exposed*(1.977+0.52*tc)
%     Lifting surfaces (variable root/tip tc, OFFICIAL as of 2026-07-22):
%       Roskam, Airplane Design Vol. II, Eq. 12.1 (see compute_roskam_planform
%       tests below) -- get_S_wet_wing/HT/VT delegate to this formula, not
%       the uniform-tc one, per GeomL2.md's 2026-07-22 resolution.
%     Fuselage (official): Roskam, Airplane Design Vol. II, Eq. 12.3
%       S_wet = pi*D*L*(1 - 2/lambda_f)^(2/3)*(1 + 1/lambda_f^2)
%       where lambda_f = L/D  (fineness ratio)
%     Fuselage (Brandt alternates): low-fi "1/3-cone+2/3-cylinder"
%       [Geom!B3] and high-fi frame-integration [Geom!D23] -- see the
%       dedicated tests below.
%     Duct/inlet (frustum, moved from former L3): Raymer 6th ed. Sec 7.3.
%
%   Pre-computed F-16A expected component S_wet (F16GeomL2 inputs, verified
%   live via mcp__matlab__evaluate_matlab_code against a fresh F16GeomL2()
%   instance, 2026-07-22 -- see F16GeomL2.m's class header for the full
%   breakdown):
%     Wing:      396.38 ft^2   (Brandt Geom!B14 = 392.02, +1.1%)
%     HT:        101.39 ft^2   (Brandt Geom!B16 =  99.59, +1.8%)
%     VT:         83.14 ft^2   (Brandt Geom!B17 =  81.69, +1.8%)
%     Fuselage:  730.30 ft^2   (Roskam Eq.12.3; Brandt low-fi 730.42, high-fi 676.33)
%     Duct:      155.57 ft^2   (frustum degenerates to cylinder, D=D_nacelle=3.537 ft)
%     Total:    1466.77 ft^2   (Brandt Main!L3 = 1371.09, +7.0%)
%   NOTE: as of the 2026-07-22 merge, get_S_wet_wing/HT/VT are computed via
%   compute_roskam_planform (Roskam Eq. 12.1), NOT compute_wet_planform
%   (Brandt's uniform-tc formula) -- the wing/HT/VT tests below still pass
%   against Brandt's loose tolerances either way (both formulas agree to
%   within a percent or two for this aircraft's thin, near-uniform sections).

    properties (Constant)
        TOGW        = 31377     % lbf    — F-16A Brandt TOGW (passed to get_S_wet; unused by L2)
        BRANDT_SWET = 1371.09   % ft^2   — Brandt F-16A workbook [Main!L3]
        TOL_PCT     = 0.15      % —      — ±15% physical-reasonableness tolerance

        % Brandt ground-truth figures for the new Task-2 methods, from
        % VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json.
        BRANDT_FUS_LOWFI    = 730.422    % ft^2  [Brandt Geom!B3]  fuselage_S_wet.low_fi_ft2
        BRANDT_FUS_HIGHFI   = 676.3289   % ft^2  [Brandt Geom!D23] fuselage_S_wet.high_fi_ft2
        BRANDT_EXP_WING     = 196.2261   % ft^2  [Brandt Geom!7]   lifting_surface_exposed_areas.wing.exposed_S_ft2
        BRANDT_EXP_VT       = 40.8897    % ft^2  [Brandt Geom!10]  lifting_surface_exposed_areas.vertical_tail.exposed_S_ft2
        BRANDT_NACELLE_SWET = 41.515     % ft^2  [Brandt Geom!B4]  nacelle.S_wet_ft2
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        function testFuselageSwetVsBrandt(tc)
        % Roskam Eq. 12.3 equivalent-diameter fuselage (~730 ft^2) vs
        % Brandt's "More Accurate Fuselage Swet"  [Geom!D23] = 676.33 ft^2.
        % Difference is the equivalent-diameter approximation (~8%).
            b        = F16Baseline();
            g        = F16GeomL2(f16a_spec_path(2));
            expected = b.brandt.S_wet_fus_alt;
            received = g.get_S_wet_fuselage();
            fprintf('\n    fuselage S_wet: received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.1, ...
                'Fuselage S_wet does not match Brandt Geom!D23 within 10%.');
        end

        % --- F-16A component values vs Brandt Geom-sheet truth ------------
        %
        %   [Brandt] Geom sheet component wetted areas (extract_brandt.m,
        %   data.geom_wet), transcribed into F16Baseline.m as b.brandt.S_wet_*.
        %   Wing matches tightly (both use ~the same exposed planform area).
        %   HT/VT diverge because this framework's S_exposed_HT/VT inputs
        %   are close to but not identical to Brandt's own exposed-planform
        %   figures. NOTE (2026-07-22): get_S_wet_wing/HT/VT now compute via
        %   compute_roskam_planform (Roskam Eq. 12.1, variable root/tip tc),
        %   not compute_wet_planform (Brandt's uniform-tc formula) -- the
        %   loose tolerances below were set for the old formula's output but
        %   still comfortably bound the new formula's output too, since both
        %   formulas agree to within ~2% for this aircraft's thin sections.

        function testWingSwet(tc)
        % Roskam Eq. 12.1 (compute_roskam_planform), S_exposed_wing≈196.23,
        % tc_r=tc_t=0.04, lambda=0.2275 -> ≈396.38 ft^2.
        % Brandt:  392.020 ft^2  [Geom!B14] -- tight agreement (~1.1%).
            b        = F16Baseline();
            g        = F16GeomL2(f16a_spec_path(2));
            expected = b.brandt.S_wet_wing;
            received = g.get_S_wet_wing();
            fprintf('\n    wing S_wet: received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.03, ...
                'Wing S_wet does not match Brandt Geom!B14 within 3%.');
        end

        function testHTSwet(tc)
        % Roskam Eq. 12.1 (compute_roskam_planform), S_exposed_ht≈49.85,
        % tc_r=0.060, tc_t=0.035, lambda=0.390 -> ≈101.39 ft^2.
        % Brandt:  99.585 ft^2  [Geom!B16] -- loose tolerance; see header note.
            b        = F16Baseline();
            g        = F16GeomL2(f16a_spec_path(2));
            expected = b.brandt.S_wet_HT;
            received = g.get_S_wet_HT();
            fprintf('\n    HT S_wet:   received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.35, ...
                'HT S_wet does not match Brandt Geom!B16 within 35%.');
        end

        function testVTSwet(tc)
        % Roskam Eq. 12.1 (compute_roskam_planform), S_exposed_vt≈40.89,
        % tc_r=0.053, tc_t=0.030, lambda=0.437 -> ≈83.14 ft^2.
        % Brandt:  81.689 ft^2  [Geom!B17] -- loose tolerance; see header note.
            b        = F16Baseline();
            g        = F16GeomL2(f16a_spec_path(2));
            expected = b.brandt.S_wet_VT;
            received = g.get_S_wet_VT();
            fprintf('\n    VT S_wet:   received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.4, ...
                'VT S_wet does not match Brandt Geom!B17 within 40%.');
        end

        % --- Total S_wet (physical-reasonableness check) -----------------

        function testTotalSwetWithinTolOfBrandt(tc)
        % Total (wing+HT+VT+fuselage+duct) ≈1466.8 ft^2.
        % Brandt truth: 1371 ft^2.  Tolerance: ±15% → [1165, 1577] ft^2.
            g       = F16GeomL2(f16a_spec_path(2));
            received = g.get_S_wet();
            lo      = tc.BRANDT_SWET * (1 - tc.TOL_PCT);   % 1165.4 ft^2
            hi      = tc.BRANDT_SWET * (1 + tc.TOL_PCT);   % 1576.8 ft^2
            fprintf('\n    total S_wet: received = %.2f ft^2,  Brandt = %.2f ft^2  (%.1f%%)\n', ...
                received, tc.BRANDT_SWET, 100*(received - tc.BRANDT_SWET)/tc.BRANDT_SWET);
            fprintf('    tolerance band: [%.1f, %.1f] ft^2\n', lo, hi);
            tc.verifyGreaterThan(received, lo, ...
                sprintf('Total S_wet %.1f ft^2 is more than 15%% below Brandt %.1f ft^2.', ...
                received, tc.BRANDT_SWET));
            tc.verifyLessThan(received, hi, ...
                sprintf('Total S_wet %.1f ft^2 is more than 15%% above Brandt %.1f ft^2.', ...
                received, tc.BRANDT_SWET));
        end

        function testTotalSwetEqualsSum(tc)
        % get_S_wet() must equal the manual sum of the FIVE component
        % methods (wing+HT+VT+fuselage+duct). FIXED 2026-07-22: duct S_wet
        % is now unconditionally included in GeomL2.get_S_wet's aggregation
        % (the L3-elimination merge folded the duct term into L2 -- see
        % GeomL2.m's get_S_wet docstring/DECISION note). This test used to
        % sum only four components (wing+HT+VT+fuselage) and failed once
        % the duct term was added to get_S_wet's own aggregation.
            g      = F16GeomL2(f16a_spec_path(2));
            manual = g.get_S_wet_wing() + g.get_S_wet_HT() + ...
                     g.get_S_wet_VT()  + g.get_S_wet_fuselage() + ...
                     g.get_S_wet_duct();
            via_method = g.get_S_wet();
            fprintf('\n    get_S_wet():      %.6f ft^2\n', via_method);
            fprintf('    component sum:    %.6f ft^2\n', manual);
            tc.verifyEqual(via_method, manual, 'AbsTol', 1e-9, ...
                'get_S_wet() is not the sum of its five component methods (wing+HT+VT+fuselage+duct).');
        end

        % --- get_S_wet() takes no W_TO argument at all --------------------

        function testGetSwetNoArgRequired(tc)
        % RESOLVED 2026-07-22 (user decision): L2's get_S_wet no longer
        % accepts a W_TO argument at all -- superseding the old
        % testGetSwetIgnoresWTO, which asserted W_TO was accepted-but-
        % ignored. Calling with zero arguments must succeed and match the
        % property populated automatically at construction (obj.S_wet).
            g   = F16GeomL2(f16a_spec_path(2));
            val = g.get_S_wet();
            fprintf('\n    get_S_wet():  %.6f ft^2\n', val);
            fprintf('    obj.S_wet:    %.6f ft^2  (should match -- Dependent, live-computed)\n', g.S_wet);
            tc.verifyEqual(val, g.S_wet, 'AbsTol', 1e-9, ...
                'get_S_wet() should match the Dependent obj.S_wet property.');
            tc.verifyError(@() g.get_S_wet(99999), 'MATLAB:TooManyInputs', ...
                'get_S_wet should reject an extra argument -- L2 no longer takes W_TO at all.');
        end

        function testWettedAreasLiveOnRead(tc)
        % RESOLVED 2026-07-22 (user decision): the wetted-area quantities
        % must be real, current values the instant they are read -- never 0
        % placeholders, and never a stale copy frozen at construction.
        % They are implemented as Dependent properties (get.S_wet_* live-
        % recompute from the inputs); this test guards both facts: (a) they
        % are nonzero and consistent with a fresh method call right after
        % construction, and (b) they track a mutated input WITHOUT any
        % reconstruction -- the exact behavior a downstream optimizer needs.
            g = F16GeomL2(f16a_spec_path(2));
            % (a) nonzero + consistent with the method immediately
            tc.verifyNotEqual(g.S_wet, 0, 'obj.S_wet must not be 0.');
            tc.verifyNotEqual(g.S_wet_wing, 0, 'obj.S_wet_wing must not be 0.');
            tc.verifyNotEqual(g.S_wet_ht, 0, 'obj.S_wet_ht must not be 0.');
            tc.verifyNotEqual(g.S_wet_vt, 0, 'obj.S_wet_vt must not be 0.');
            tc.verifyEqual(g.S_wet_wing, g.get_S_wet_wing(), 'AbsTol', 1e-9);
            tc.verifyEqual(g.S_wet_ht, g.get_S_wet_HT(), 'AbsTol', 1e-9);
            tc.verifyEqual(g.S_wet_vt, g.get_S_wet_VT(), 'AbsTol', 1e-9);
            tc.verifyEqual(g.S_wet, g.get_S_wet(), 'AbsTol', 1e-9);
            % (b) mutate an input -> every derived read must follow, no rebuild
            b0  = g.b_wing;
            sw0 = g.S_wet_wing;
            st0 = g.S_wet;
            g.AR_wing = g.AR_wing + 1;   % optimizer-style in-place mutation
            tc.verifyEqual(g.b_wing, GeometryBase.compute_span(g.AR_wing, g.S_ref), 'AbsTol', 1e-9, ...
                'b_wing must recompute live from the mutated AR_wing.');
            tc.verifyGreaterThan(g.b_wing, b0, 'larger AR -> larger span, live.');
            tc.verifyNotEqual(g.S_wet_wing, sw0, 'S_wet_wing must change after AR_wing mutation.');
            tc.verifyNotEqual(g.S_wet, st0, 'total S_wet must change after AR_wing mutation.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning to one must
        % error (there is no set-method), so nothing can silently overwrite a
        % computed value with a frozen literal (the anti-pattern this whole
        % refactor removes).
            g = F16GeomL2(f16a_spec_path(2));
            tc.verifyError(@() setfield(g, 'S_wet_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'QC_sweep_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_wet', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % --- S_ref -------------------------------------------------------

        function testGetSref(tc)
        % Expected: 300 ft^2  [Brandt Main!B18, f16a_L2.json wing.S_ft2]
            g        = F16GeomL2(f16a_spec_path(2));
            received = g.get_S_ref();
            fprintf('\n    get_S_ref: received = %.2f ft^2,  expected = 300.00 ft^2\n', received);
            tc.verifyEqual(received, 300, 'AbsTol', 1e-9);
        end

        % --- L_fus (used directly by fidelity_comparison.m) --------------

        function testLfusMatchesBrandt(tc)
        % L2 exposes L_fus as a plain property (not a method, unlike L1's
        % get_L_fus). RENAMED/FIXED 2026-07-22 (was testLfusMatchesTO): the
        % OOP-practice pass re-sourced L_fus from examples/F16A/f16a_L2.json's
        % fuselage.length_ft (Brandt Main!B32 = 46.5 ft), replacing the old
        % T.O.-manual literal (47.5 ft) this test used to check against --
        % see F16GeomL2.m's constructor and f16a_L2.json's "_comment"
        % field explaining why the Brandt Main-tab value is used instead of
        % the T.O. manual value. Expected value below is the Brandt figure,
        % cited independently (not read back out of the same JSON via
        % F16GeomL2's own constructor code path).
            expected = 46.5;   % ft [Brandt Main!B32, f16a_geometry.json fuselage.length_ft]
            g        = F16GeomL2(f16a_spec_path(2));
            received = g.L_fus;
            fprintf('\n    L_fus: received = %.2f ft,  expected (Brandt) = %.2f ft\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'F16GeomL2.L_fus does not match Brandt Main!B32 fuselage length (46.5 ft).');
        end

        % --- Inheritance / interface compliance --------------------------

        function testIsaGeometryBase(tc)
            g = F16GeomL2(f16a_spec_path(2));
            tc.verifyTrue(isa(g, 'GeometryBase'));
        end

        function testIsaGeometryModelL2(tc)
            g = F16GeomL2(f16a_spec_path(2));
            tc.verifyTrue(isa(g, 'GeometryModelL2'));
        end

        function testNotIsaGeometryModelL1(tc)
        % L2 does NOT inherit from the L1 enforcer.
            g = F16GeomL2(f16a_spec_path(2));
            tc.verifyFalse(isa(g, 'GeometryModelL1'), ...
                'L2 geometry must NOT inherit from GeometryModelL1.');
        end

        function testIsHandleClass(tc)
            g = F16GeomL2(f16a_spec_path(2));
            tc.verifyTrue(isa(g, 'handle'));
        end

        % ================================================================== %
        % GeometryBase Task-2 statics (2026-07-22): compute_root_chord,
        % compute_tip_chord, compute_mac, compute_span, convert_sweep.
        % Representative input values below are independently chosen and
        % hand-computed from the cited Raymer 7th ed. formulas -- NOT the
        % F-16's own numbers (except the dedicated headline-regression test
        % below, which deliberately IS the F-16's own wing), and not
        % generated by calling the method under test.
        % ================================================================== %

        function testComputeRootChord(tc)
        % c_root = 2*S_ref/(b*(1+lambda))  [Raymer 7th ed. Eq. 7.6].
        % S_ref=240 ft^2, b=20 ft, lambda=0.5 -> 2*240/(20*1.5) = 16.0 ft.
            received = GeometryBase.compute_root_chord(240, 20, 0.5);
            fprintf('\n    c_root: received = %.10f ft,  hand-computed = 16.0000000000 ft\n', received);
            tc.verifyEqual(received, 16.0, 'AbsTol', 1e-9);
        end

        function testComputeTipChord(tc)
        % c_tip = lambda*c_root  [Raymer 7th ed. Eq. 7.7].
        % c_root=16.0 ft, lambda=0.5 -> 8.0 ft.
            received = GeometryBase.compute_tip_chord(16.0, 0.5);
            fprintf('\n    c_tip: received = %.10f ft,  hand-computed = 8.0000000000 ft\n', received);
            tc.verifyEqual(received, 8.0, 'AbsTol', 1e-9);
        end

        function testComputeMac(tc)
        % cbar = (2/3)*c_root*(1+lambda+lambda^2)/(1+lambda)  [Raymer 7th ed. Eq. 7.8].
        % c_root=16.0 ft, lambda=0.5 -> (2/3)*16*1.75/1.5 = 12.4444444444 ft.
            expected = 12.4444444444;
            received = GeometryBase.compute_mac(16.0, 0.5);
            fprintf('\n    cbar: received = %.10f ft,  hand-computed = %.10f ft\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testComputeSpan(tc)
        % b = sqrt(AR*S_ref)  [definitional].  AR=9, S_ref=225 -> sqrt(2025) = 45.0 ft.
            received = GeometryBase.compute_span(9, 225);
            fprintf('\n    span: received = %.10f ft,  hand-computed = 45.0000000000 ft\n', received);
            tc.verifyEqual(received, 45.0, 'AbsTol', 1e-9);
        end

        function testConvertSweepGenericCase(tc)
        % tan(Lambda_x) = tan(Lambda_LE) - (4/AR)*x*(1-lambda)/(1+lambda)
        % [standard swept-wing planform identity -- citation unresolved per
        % GeometryBase.md]. Representative case (deliberately NOT the F-16's
        % own wing, to keep this test independent of the headline regression
        % check below): Lambda_LE=45 deg, AR=8, lambda=0.4, x=0.25.
        % Hand-computed: atand(tand(45) - (4/8)*0.25*(0.6/1.4)) = 43.4234499448 deg.
            expected = 43.4234499448;
            received = GeometryBase.convert_sweep(45, 8, 0.4, 0.25);
            fprintf('\n    convert_sweep (generic): received = %.10f deg,  hand-computed = %.10f deg\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testConvertSweepWingQC_HeadlineRegressionCheck(tc)
        % THE HEADLINE BUG FIX (2026-07-22). F16GeomL2's QC_sweep_wing used
        % to be a hardcoded, never-actually-derived literal of 37 deg
        % (apparently copy-pasted from the HT's own ~36.8 deg figure -- see
        % F16GeomL2.md's "THE BUG" section). It is now computed via
        % GeometryBase.convert_sweep at the wing's own AR=3.0, lambda=0.2275,
        % Lambda_LE=40 deg, x=0.25. Hand-computed independently:
        %   tan(Lambda_c/4) = tand(40) - (4/3)*0.25*(1-0.2275)/(1+0.2275)
        %   Lambda_c/4 = atand(...) = 32.1831783983 deg  (NOT 37 deg).
        % This test exists specifically so QC_sweep_wing can never silently
        % regress back to the old hardcoded-wrong 37 deg literal.
            expected_correct = 32.1831783983;
            old_wrong_value  = 37;
            g        = F16GeomL2(f16a_spec_path(2));
            received = g.QC_sweep_wing;
            fprintf(['\n    QC_sweep_wing: received = %.10f deg,  hand-computed (correct) ' ...
                '= %.10f deg,  old hardcoded (wrong) = %d deg\n'], ...
                received, expected_correct, old_wrong_value);
            tc.verifyEqual(received, expected_correct, 'AbsTol', 0.01, ...
                'F16GeomL2.QC_sweep_wing does not match the hand-computed convert_sweep result (~32.2 deg).');
            tc.verifyGreaterThan(abs(received - old_wrong_value), 1, ...
                'F16GeomL2.QC_sweep_wing has regressed back toward the old hardcoded-wrong 37 deg literal.');
        end

        % ================================================================== %
        % Roskam Eq. 12.1 variable root/tip tc lifting-surface formula
        % (compute_roskam_planform, moved from former L3, now OFFICIAL for
        % get_S_wet_wing/HT/VT per GeomL2.md's 2026-07-22 resolution).
        % ================================================================== %

        function testRoskamPlanformFormula(tc)
        % S_wet = 2*S_exp*(1+0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))
        % [Roskam Vol. II Eq. 12.1]. Representative values (independently
        % chosen, not the F-16's own tc splits): S_exp=100 ft^2, tc_r=0.05,
        % tc_t=0.03, lambda=0.25.
        %   Hand-computed: 2*100*(1+0.25*0.05*(1+1.666667*0.25)/1.25)
        %                = 202.8333333333 ft^2.
            expected = 202.8333333333;
            received = GeomL2.compute_roskam_planform(100, 0.05, 0.03, 0.25);
            fprintf('\n    roskam planform: received = %.10f ft^2,  hand-computed = %.10f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testRoskamPlanformZeroTipTcErrors(tc)
        % Guard-gap fix (2026-07-22 OOP pass, GeomL2.md "Guard gaps" note):
        % tc_t=0 used to silently return Inf (division by tc_r/tc_t is the
        % formula's tc_r/tc_t term); now guarded by an arguments-block
        % mustBePositive constraint on tc_t, so this errors instead.
            tc.verifyError(@() GeomL2.compute_roskam_planform(100, 0.05, 0, 0.25), ...
                'MATLAB:validators:mustBePositive');
        end

        % ================================================================== %
        % Fuselage fineness-ratio guard (compute_s_wet_fus_cyl)
        % ================================================================== %

        function testFusCylFinenessRatioGuard(tc)
        % Guard-gap fix (2026-07-22 OOP pass, GeomL2.md "Guard gaps" note):
        % Roskam Eq. 12.3 is only valid for fineness ratio L/D > 2; a
        % short/wide fuselage (D_fus=10, L_fus=15 -> L/D=1.5) used to
        % silently return a complex number via the (1-2/lambda_f)^(2/3)
        % term. Now errors explicitly instead of returning a complex number.
            tc.verifyError(@() GeomL2.compute_s_wet_fus_cyl(10, 15), ...
                'GeomL2:invalidFinenessRatio');
        end

        % ================================================================== %
        % Brandt fuselage alternates (compute_s_wet_fus_brandt_lowfi/_highfi).
        % These methods are explicitly built to reproduce Brandt's own
        % workbook figures, so the Brandt ground-truth JSON is the correct
        % oracle here (not a formula re-derived by hand) -- this is an
        % intentional comparison-tier-style check on an otherwise Tier-1
        % unit test, per the task brief's explicit carve-out, NOT the
        % implementation's own computed output fed back as its own oracle
        % (the GT values below come from f16a_ground_truth.json /
        % f16a_geometry.json, independent ground-truth files).
        % ================================================================== %

        function testFusBrandtLowfiVsGT(tc)
        % "1/3-cone + 2/3-cylinder" approximation [Brandt Geom!B3]. Inputs
        % are the F-16's genuine spec fuselage envelope (max_width=7.0 ft,
        % max_height=5.0 ft, L_fuse=46.5 ft -- f16a_L2.json's fuselage
        % block).
            received = GeomL2.compute_s_wet_fus_brandt_lowfi(7.0, 5.0, 46.5);
            fprintf('\n    fus brandt low-fi: received = %.4f ft^2,  Brandt GT = %.4f ft^2\n', ...
                received, tc.BRANDT_FUS_LOWFI);
            tc.verifyEqual(received, tc.BRANDT_FUS_LOWFI, 'RelTol', 1e-3, ...
                'compute_s_wet_fus_brandt_lowfi does not match Brandt Geom!B3 within 0.1%.');
        end

        function testF16GeomL2FusBrandtLowfiHighLevel(tc)
        % High-level get_S_wet_fuselage_brandt_lowfi(obj) reads
        % obj.W_max_fuselage/H_max_fuselage/L_fuselage from a real
        % F16GeomL2 instance and must match the low-level call above.
            g        = F16GeomL2(f16a_spec_path(2));
            received = GeomL2.get_S_wet_fuselage_brandt_lowfi(g);
            fprintf(['\n    F16GeomL2 fus brandt low-fi (high-level): received = %.4f ft^2, ' ...
                ' Brandt GT = %.4f ft^2\n'], received, tc.BRANDT_FUS_LOWFI);
            tc.verifyEqual(received, tc.BRANDT_FUS_LOWFI, 'RelTol', 1e-3, ...
                'get_S_wet_fuselage_brandt_lowfi does not match Brandt Geom!B3 within 0.1%.');
        end

        function testFusBrandtHighfiVsGT(tc)
        % Trapezoidal per-frame-perimeter integration [Brandt Geom!D23].
        % Frame data (20 fuselage stations: x, z_chine, z, w, h) is read
        % directly from VnV/BrandtF16A/GroundTruth/f16a_geometry.json
        % fuselage.frames -- an independent ground-truth input file, not
        % GeomL2's own output. RelTol 0.5% covers the small (~0.24%) gap
        % between this reproduction and Brandt's own live workbook figure.
            this_dir    = fileparts(mfilename('fullpath'));
            sizing_root = fileparts(fileparts(this_dir));
            gt_path     = fullfile(sizing_root, 'VnV', 'BrandtF16A', 'GroundTruth', 'f16a_geometry.json');
            J           = jsondecode(fileread(gt_path));
            frames      = J.fuselage.frames;
            received    = GeomL2.compute_s_wet_fus_brandt_highfi( ...
                [frames.x_ft], [frames.z_chine_ft], [frames.z_ft], [frames.w_ft], [frames.h_ft]);
            fprintf('\n    fus brandt high-fi: received = %.4f ft^2,  Brandt GT = %.4f ft^2\n', ...
                received, tc.BRANDT_FUS_HIGHFI);
            tc.verifyEqual(received, tc.BRANDT_FUS_HIGHFI, 'RelTol', 0.005, ...
                'compute_s_wet_fus_brandt_highfi does not match Brandt Geom!D23 within 0.5%.');
        end

        % ================================================================== %
        % Lifting-surface exposed-area computation (compute_S_exposed_
        % horizontal/_vertical, moved from former L3's design intent -- no
        % prior implementation existed anywhere in GeomL2.m before this
        % pass). Same Brandt-GT-as-oracle rationale as the fuselage
        % alternates above: these methods are explicitly built to reproduce
        % Brandt's own exposed-area table.
        % ================================================================== %

        function testExposedAreaHorizontalWingVsGT(tc)
        % compute_S_exposed_horizontal, wing case: boundary = fuselage
        % half-width, both panels mirrored [Brandt readme_geom.md Sec 4.3].
        % Inputs are Brandt's OWN root/tip chord and span figures from the
        % ground-truth exposed-area table (f16a_ground_truth.json
        % lifting_surface_exposed_areas.wing), not this framework's own
        % computed chords.
            c_root = 16.2933; c_tip = 3.7067; hs = 15.0; fw = 3.5;   % fw = fuselage half-width = 7.0/2
            received = GeomL2.compute_S_exposed_horizontal(c_root, c_tip, hs, fw);
            fprintf('\n    exposed wing: received = %.4f ft^2,  Brandt GT = %.4f ft^2\n', ...
                received, tc.BRANDT_EXP_WING);
            tc.verifyEqual(received, tc.BRANDT_EXP_WING, 'RelTol', 1e-4, ...
                'compute_S_exposed_horizontal (wing) does not match Brandt Geom!7 within 0.01%.');
        end

        function testExposedAreaVerticalVsGT(tc)
        % compute_S_exposed_vertical: boundary = fuselage half-height, full
        % single-panel span (no mirroring) [Brandt readme_geom.md Sec 4.3].
        % Inputs are Brandt's own S/AR/root/tip-chord figures.
            S = 60.0; AR = 1.6; c_root = 8.1650; c_tip = 4.0825; fh = 2.5;   % fh = fuselage half-height = 5.0/2
            received = GeomL2.compute_S_exposed_vertical(S, AR, c_root, c_tip, fh);
            fprintf('\n    exposed VT: received = %.4f ft^2,  Brandt GT = %.4f ft^2\n', ...
                received, tc.BRANDT_EXP_VT);
            tc.verifyEqual(received, tc.BRANDT_EXP_VT, 'RelTol', 1e-4, ...
                'compute_S_exposed_vertical does not match Brandt Geom!10 within 0.01%.');
        end

        function testF16GeomL2ExposedAreasMatchBrandtGT(tc)
        % F16GeomL2's own constructor computes S_exposed_wing/vt from its
        % genuine JSON spec inputs (AR/taper/sweep/S + fuselage width/height)
        % via the same GeomL2 exposed-area statics tested above -- this
        % checks the full JSON-to-property pipeline reproduces Brandt's
        % exposed-area ground truth, not just the bare static functions.
            g = F16GeomL2(f16a_spec_path(2));
            fprintf('\n    F16GeomL2 S_exposed_wing = %.4f ft^2 (Brandt = %.4f)\n', g.S_exposed_wing, tc.BRANDT_EXP_WING);
            fprintf('    F16GeomL2 S_exposed_vt   = %.4f ft^2 (Brandt = %.4f)\n', g.S_exposed_vt, tc.BRANDT_EXP_VT);
            tc.verifyEqual(g.S_exposed_wing, tc.BRANDT_EXP_WING, 'RelTol', 1e-3, ...
                'F16GeomL2.S_exposed_wing does not match Brandt Geom!7 within 0.1%.');
            tc.verifyEqual(g.S_exposed_vt, tc.BRANDT_EXP_VT, 'RelTol', 1e-3, ...
                'F16GeomL2.S_exposed_vt does not match Brandt Geom!10 within 0.1%.');
        end

        function testGetSExposedWingPassthrough(tc)
        % get_S_exposed_wing(obj) is a pure passthrough accessor -- must
        % return obj.S_exposed_wing unchanged (structural test, not a
        % formula check; moved from the former GeometryModelL3 contract).
            g        = F16GeomL2(f16a_spec_path(2));
            received = g.get_S_exposed_wing();
            fprintf('\n    get_S_exposed_wing: received = %.6f,  obj.S_exposed_wing = %.6f\n', ...
                received, g.S_exposed_wing);
            tc.verifyEqual(received, g.S_exposed_wing, 'AbsTol', 1e-12, ...
                'get_S_exposed_wing does not passthrough obj.S_exposed_wing unchanged.');
        end

        % ================================================================== %
        % Duct/inlet frustum (moved from former L3, 2026-07-22 merge). Test
        % cases merged in from the now-deleted tests/disciplines/TestGeomL3.m,
        % retargeted at GeomL2/F16GeomL2 instead of the deleted
        % GeomL3/F16GeomL3 classes.
        % ================================================================== %

        function testDuctFrustumFormula(tc)
        % S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2)  [Raymer 6th ed. Sec 7.3].
        % D_inlet=3.4, D_exit=2.9, L=14 -> r1=1.7, r2=1.45.
        %   Hand-computed: pi*3.15*sqrt(0.0625+196) = 138.5663235860 ft^2.
            expected = 138.5663235860;
            received = GeomL2.compute_s_wet_duct(3.4, 2.9, 14.0);
            fprintf('\n    duct frustum: received = %.10f ft^2,  hand-computed = %.10f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'Frustum duct formula does not match hand-computed value.');
        end

        function testDuctCylinderDegenerate(tc)
        % D_inlet == D_exit = 3.2 ft (constant section) -> degenerates to
        % pi*D*L.  Hand-computed: pi*3.2*14.0 = 140.7433508808 ft^2.
            expected = 140.7433508808;
            received = GeomL2.compute_s_wet_duct(3.2, 3.2, 14.0);
            fprintf('\n    duct cylinder: received = %.10f ft^2,  hand-computed = %.10f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6, ...
                'Constant-section duct should give pi*D*L.');
        end

        function testDuctSwetVsBrandtNacelle(tc)
        % F16GeomL2's own D_inlet=D_exit (Brandt nacelle-diameter formula,
        % D=sqrt(T_AB_SLS_lb/1900)) vs Brandt's own nacelle S_wet ground
        % truth [Geom!B4, f16a_ground_truth.json nacelle.S_wet_ft2].
        % Not a tight physical match by design: this framework's duct is the
        % exposed inlet-to-exit frustum lateral surface, while Brandt's
        % nacelle is a full-cylinder engine-nacelle approximation -- a
        % different quantity. Loose bound is a same-order-of-magnitude
        % sanity check only (mirrors the former TestGeomL3's identical note).
            g        = F16GeomL2(f16a_spec_path(2));
            received = g.get_S_wet_duct();
            fprintf('\n    duct S_wet: received = %.4f ft^2,  Brandt nacelle = %.4f ft^2 (different definitions)\n', ...
                received, tc.BRANDT_NACELLE_SWET);
            tc.verifyGreaterThan(received, 0, 'Duct S_wet must be positive.');
            tc.verifyLessThan(received, 5 * tc.BRANDT_NACELLE_SWET, ...
                'Duct S_wet is more than 5x Brandt nacelle estimate -- check for a gross unit/formula error.');
        end

        % ================================================================== %
        % Constructor: required explicit JSON path (no silent default)
        % ================================================================== %

        function testNoArgConstructorErrors(tc)
        % F16GeomL2 has no default JSON path -- a no-arg call must error rather
        % than silently loading a default file.
            errored = false;
            ctor = @F16GeomL2;   % no-arg call below must hit the required-path guard
            try
                ctor();   %#ok<NASGU>
            catch
                errored = true;
            end
            tc.verifyTrue(errored, ...
                'F16GeomL2() with no path must error (no silent default).');
        end

        function testExplicitJsonPathConstructor(tc)
        % Constructing from the unified L2 JSON path (f16a_spec_path(2)) loads
        % the genuine spec values (checked against a few distinctive fields).
            g = F16GeomL2(f16a_spec_path(2));
            fprintf('\n    L2 ctor: AR_wing=%.2f, LE_sweep_wing=%.1f, S_ref=%.1f, QC_sweep_wing=%.4f deg\n', ...
                g.AR_wing, g.LE_sweep_wing, g.S_ref, g.QC_sweep_wing);
            tc.verifyEqual(g.AR_wing, 3.0, 'AbsTol', 1e-9);
            tc.verifyEqual(g.LE_sweep_wing, 40.0, 'AbsTol', 1e-9);
            tc.verifyEqual(g.S_ref, 300.0, 'AbsTol', 1e-9);
        end

    end
end
