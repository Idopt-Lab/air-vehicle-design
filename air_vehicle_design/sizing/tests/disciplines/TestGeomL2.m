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
%       Roskam, Airplane Design Vol. II, Eq. 12.1 (see compute_S_wet_planform_roskam
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
%   compute_S_wet_planform_roskam (Roskam Eq. 12.1), NOT compute_S_wet_planform_raymer
%   (Brandt's uniform-tc formula) -- the wing/HT/VT tests below still pass
%   against Brandt's loose tolerances either way (both formulas agree to
%   within a percent or two for this aircraft's thin, near-uniform sections).
%
%   PHASE 2 (2026-07-25, locked user decisions; spec examples/F16A/models/disciplines/geom/F16GeomL3.md
%   -- that doc governs BOTH tiers). What changed here:
%     * CONSTRUCTOR: F16GeomL2(json_path, prop). A propulsion object is now a
%       REQUIRED injected argument, because the nacelle diameter -- and hence
%       duct wetted area and CD0 -- is sized from engine SLS thrust
%       (D_nac = sqrt(T_AB_SLS/1900)), which is engine data, not airframe data.
%       Every construction site below takes the appended
%       F16PropL2(f16a_spec_path(2)).
%     * T_AB_SLS_lb is Dependent on prop.T_SL, no longer a frozen 23770 copy.
%       testNacelleDiameterAndDuctTrackInjectedThrust is the positive control
%       for that path, which verification proved was previously DEAD (setting
%       p.T_SL = 30000 left D_inlet, duct S_wet and CD0 bit-identical).
%     * tc_ht / tc_vt are DERIVED root/tip means (0.0475 / 0.0415), not stored
%       0.04 inputs; the L2 JSON no longer carries an HT/VT tc_ratio key at all.
%     * L_aircraft (47.65 ft) is a new INPUT and Amax a new DERIVED property, so
%       an injected aero object reads the Raymer Eq. 12.44 wave-drag geometry
%       live instead of carrying Brandt's frozen outputs.

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

        % Component wetted-area ground truth, from f16a_ground_truth.json
        % lifting_surface_S_wet_ft2 (loose comparison targets).
        BRANDT_SWET_WING    = 392.0204   % ft^2  [Brandt Geom!B14] lifting_surface_S_wet_ft2.wing
        BRANDT_SWET_HT      = 99.5848    % ft^2  [Brandt Geom!B16] lifting_surface_S_wet_ft2.pitch_control_HT
        BRANDT_SWET_VT      = 81.6894    % ft^2  [Brandt Geom!B17] lifting_surface_S_wet_ft2.vertical_tail
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        function testFuselageSwetVsBrandt(tc)
        % Roskam Eq. 12.3 equivalent-diameter fuselage (~730 ft^2) vs
        % Brandt's "More Accurate Fuselage Swet"  [Geom!D23] = 676.33 ft^2.
        % Difference is the equivalent-diameter approximation (~8%).
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            expected = tc.BRANDT_FUS_HIGHFI;   % [Brandt Geom!D23; f16a_ground_truth.json]
            received = g.S_wet_fuselage;   % Mod (08/19/2026) (Claude)
            fprintf('\n    fuselage S_wet: received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.1, ...
                'Fuselage S_wet does not match Brandt Geom!D23 within 10%.');
        end

        % --- F-16A component values vs Brandt Geom-sheet truth ------------
        %
        %   [Brandt] Geom sheet component wetted areas, from
        %   f16a_ground_truth.json lifting_surface_S_wet_ft2 (Geom!B14/B16/B17).
        %   Wing matches tightly (both use ~the same exposed planform area).
        %   HT/VT diverge because this framework's S_exposed_HT/VT inputs
        %   are close to but not identical to Brandt's own exposed-planform
        %   figures. NOTE (2026-07-22): get_S_wet_wing/HT/VT now compute via
        %   compute_S_wet_planform_roskam (Roskam Eq. 12.1, variable root/tip tc),
        %   not compute_S_wet_planform_raymer (Brandt's uniform-tc formula) -- the
        %   loose tolerances below were set for the old formula's output but
        %   still comfortably bound the new formula's output too, since both
        %   formulas agree to within ~2% for this aircraft's thin sections.

        function testWingSwet(tc)
        % Roskam Eq. 12.1 (compute_S_wet_planform_roskam), S_exposed_wing≈196.23,
        % tc_r=tc_t=0.04, lambda=0.2275 -> ≈396.38 ft^2.
        % Brandt:  392.020 ft^2  [Geom!B14] -- tight agreement (~1.1%).
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            expected = tc.BRANDT_SWET_WING;   % [Brandt Geom!B14; f16a_ground_truth.json]
            % Mod (08/18/2026) (Claude) -- Option B: call the toolbox.
            received = GeomL2.compute_S_wet_planform_roskam(g.S_exposed_wing, g.tc_r_wing, g.tc_t_wing, g.lambda_wing);
            fprintf('\n    wing S_wet: received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.03, ...
                'Wing S_wet does not match Brandt Geom!B14 within 3%.');
        end

        function testHTSwet(tc)
        % Roskam Eq. 12.1 (compute_S_wet_planform_roskam), S_exposed_ht≈49.85,
        % tc_r=0.060, tc_t=0.035, lambda=0.390 -> ≈101.39 ft^2.
        % Brandt:  99.585 ft^2  [Geom!B16] -- loose tolerance; see header note.
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            expected = tc.BRANDT_SWET_HT;   % [Brandt Geom!B16; f16a_ground_truth.json]
            % Mod (08/18/2026) (Claude) -- Option B: call the toolbox.
            received = GeomL2.compute_S_wet_planform_roskam(g.S_exposed_ht, g.tc_r_ht, g.tc_t_ht, g.lambda_ht);
            fprintf('\n    HT S_wet:   received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.35, ...
                'HT S_wet does not match Brandt Geom!B16 within 35%.');
        end

        function testVTSwet(tc)
        % Roskam Eq. 12.1 (compute_S_wet_planform_roskam), S_exposed_vt≈40.89,
        % tc_r=0.053, tc_t=0.030, lambda=0.437 -> ≈83.14 ft^2.
        % Brandt:  81.689 ft^2  [Geom!B17] -- loose tolerance; see header note.
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            expected = tc.BRANDT_SWET_VT;   % [Brandt Geom!B17; f16a_ground_truth.json]
            % Mod (08/18/2026) (Claude) -- Option B: call the toolbox.
            received = GeomL2.compute_S_wet_planform_roskam(g.S_exposed_vt, g.tc_r_vt, g.tc_t_vt, g.lambda_vt);
            fprintf('\n    VT S_wet:   received = %.4f ft^2,  Brandt = %.4f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.4, ...
                'VT S_wet does not match Brandt Geom!B17 within 40%.');
        end

        % --- Total S_wet (physical-reasonableness check) -----------------

        function testTotalSwetWithinTolOfBrandt(tc)
        % Total (wing+HT+VT+fuselage+duct) ≈1466.8 ft^2.
        % Brandt truth: 1371 ft^2.  Tolerance: ±15% → [1165, 1577] ft^2.
            g       = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
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
            g      = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            % Mod (08/18/2026) (Claude) -- Option B: call the toolbox.
            manual = GeomL2.compute_S_wet_planform_roskam(g.S_exposed_wing, g.tc_r_wing, g.tc_t_wing, g.lambda_wing) + ...
                     GeomL2.compute_S_wet_planform_roskam(g.S_exposed_ht, g.tc_r_ht, g.tc_t_ht, g.lambda_ht) + ...
                     GeomL2.compute_S_wet_planform_roskam(g.S_exposed_vt, g.tc_r_vt, g.tc_t_vt, g.lambda_vt) + ...
                     g.S_wet_fuselage + ...   % Mod (08/19/2026) (Claude)
                     GeomL2.compute_s_wet_duct(g.D_inlet, g.D_exit, g.L_duct);
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
            g   = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
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
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            % (a) nonzero + consistent with the method immediately
            tc.verifyNotEqual(g.S_wet, 0, 'obj.S_wet must not be 0.');
            % Mod (08/18/2026) (Claude) -- Option B removed S_wet_wing/_ht/_vt.
            %   The per-component checks now call the toolbox directly.
            tc.verifyNotEqual(GeomL2.compute_S_wet_planform_roskam(g.S_exposed_wing, g.tc_r_wing, g.tc_t_wing, g.lambda_wing), 0);
            tc.verifyNotEqual(GeomL2.compute_S_wet_planform_roskam(g.S_exposed_ht, g.tc_r_ht, g.tc_t_ht, g.lambda_ht), 0);
            tc.verifyNotEqual(GeomL2.compute_S_wet_planform_roskam(g.S_exposed_vt, g.tc_r_vt, g.tc_t_vt, g.lambda_vt), 0);
            tc.verifyEqual(g.S_wet, g.get_S_wet(), 'AbsTol', 1e-9);
            % (b) mutate an input -> every derived read must follow, no rebuild
            b0  = g.b_wing;
            sw0 = GeomL2.compute_S_wet_planform_roskam(g.S_exposed_wing, g.tc_r_wing, g.tc_t_wing, g.lambda_wing);   % Mod (08/18/2026) (Claude)
            st0 = g.S_wet;
            g.AR_wing = g.AR_wing + 1;   % optimizer-style in-place mutation
            tc.verifyEqual(g.b_wing, GeometryBase.compute_span(g.AR_wing, g.S_ref), 'AbsTol', 1e-9, ...
                'b_wing must recompute live from the mutated AR_wing.');
            tc.verifyGreaterThan(g.b_wing, b0, 'larger AR -> larger span, live.');
            tc.verifyNotEqual(GeomL2.compute_S_wet_planform_roskam(g.S_exposed_wing, g.tc_r_wing, g.tc_t_wing, g.lambda_wing), sw0, ...
                'wing S_wet must change after AR_wing mutation.');   % Mod (08/18/2026) (Claude)
            tc.verifyNotEqual(g.S_wet, st0, 'total S_wet must change after AR_wing mutation.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
        % Derived (Dependent) quantities are outputs -- assigning to one must
        % error (there is no set-method), so nothing can silently overwrite a
        % computed value with a frozen literal (the anti-pattern this whole
        % refactor removes).
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            % Mod (08/18/2026) (Claude) -- S_wet_wing is gone (Option B).
            %   S_exposed_wing replaces it as the per-surface read-only check.
            tc.verifyError(@() setfield(g, 'S_exposed_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'QC_sweep_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_wet', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % --- S_ref -------------------------------------------------------

        function testGetSref(tc)
        % Expected: 300 ft^2  [Brandt Main!B18, f16a_L2.json wing.S_ft2]
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            received = g.get_S_ref();
            fprintf('\n    get_S_ref: received = %.2f ft^2,  expected = 300.00 ft^2\n', received);
            tc.verifyEqual(received, 300, 'AbsTol', 1e-9);
        end

        % --- L_fus (used directly by geometry_brandt_comparison.m) -------

        function testLfusMatchesBrandt(tc)
        % L2 exposes L_fus as a plain property (not a method, unlike L1's
        % get_L_fus). RENAMED/FIXED 2026-07-22 (was testLfusMatchesTO): the
        % OOP-practice pass re-sourced L_fus from examples/F16A/inputs/f16a_L2.json's
        % fuselage.length_ft (Brandt Main!B32 = 46.5 ft), replacing the old
        % T.O.-manual literal (47.5 ft) this test used to check against --
        % see F16GeomL2.m's constructor and f16a_L2.json's "_comment"
        % field explaining why the Brandt Main-tab value is used instead of
        % the T.O. manual value. Expected value below is the Brandt figure,
        % cited independently (not read back out of the same JSON via
        % F16GeomL2's own constructor code path).
            expected = 46.5;   % ft [Brandt Main!B32, f16a_geometry.json fuselage.length_ft]
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            received = g.L_fus;
            fprintf('\n    L_fus: received = %.2f ft,  expected (Brandt) = %.2f ft\n', received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'F16GeomL2.L_fus does not match Brandt Main!B32 fuselage length (46.5 ft).');
        end

        % --- Inheritance / interface compliance --------------------------

        function testIsaGeometryBase(tc)
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyTrue(isa(g, 'GeometryBase'));
        end

        function testIsaGeometryModelL2(tc)
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyTrue(isa(g, 'GeometryModelL2'));
        end

        function testNotIsaGeometryModelL1(tc)
        % L2 does NOT inherit from the L1 enforcer.
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyFalse(isa(g, 'GeometryModelL1'), ...
                'L2 geometry must NOT inherit from GeometryModelL1.');
        end

        function testIsHandleClass(tc)
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
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
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
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
        % SINGLE-PANEL sweep conversion (convert_sweep_panel, added 2026-07-25).
        %
        % The mirrored convert_sweep's 4/AR coefficient assumes root->tip spans
        % a SEMIspan b/2. A vertical tail is one panel spanning the full b, so
        % its coefficient is 2/AR. The VT getters used the mirrored form, which
        % double-counted the taper term and produced a physically impossible
        % 0.33 deg VT trailing-edge sweep. NOTHING in the suite covered VT sweep
        % at all, which is exactly why that survived -- hence these tests.
        % ================================================================== %

        function testConvertSweepPanelIsHalfTheMirroredTaperTerm(tc)
        % Definitional relationship between the two forms: the single-panel
        % taper term is exactly half the mirrored one, so
        %   tan(panel) - tan(LE)  ==  0.5 * (tan(mirrored) - tan(LE))
        % Checked on a generic case (AR=1.6, lambda=0.5, LE=40 deg, x=1.0),
        % independent of any F-16 number.
            LE = 40; AR = 1.6; lambda = 0.5; x = 1.0;
            t_LE    = tand(LE);
            t_panel = tand(GeometryBase.convert_sweep_panel(LE, AR, lambda, x));
            t_mirr  = tand(GeometryBase.convert_sweep(LE, AR, lambda, x));
            tc.verifyEqual(t_panel - t_LE, 0.5*(t_mirr - t_LE), 'AbsTol', 1e-12, ...
                'convert_sweep_panel''s taper term must be exactly half convert_sweep''s.');
        end

        function testVTSweepsFromPanelChordGeometry(tc)
        % HEADLINE REGRESSION CHECK for the 2026-07-25 fix. Derived independently
        % from the VT's own chords rather than from either sweep formula:
        %   b_vt     = sqrt(AR_vt*S_vt) = sqrt(1.6*60)        = 9.7979589711 ft
        %   c_root   = 2*S_vt/(b_vt*(1+lambda)) = 120/14.6969 = 8.1649658093 ft
        %   c_tip    = lambda*c_root = 0.5*8.16497            = 4.0824829046 ft
        %   (c_root - c_tip)/b_vt                             = 0.4166666667
        % A single panel's x-chord line falls back over the FULL span b_vt:
        %   tan(Lambda_x) = tand(40) - x*(c_root - c_tip)/b_vt
        %   x=1.00 -> atand(0.8390996312 - 0.4166666667) = 22.9007986415 deg
        %   x=0.25 -> atand(0.8390996312 - 0.1041666667) = 36.3133926497 deg
        % The old mirrored form gave 0.33 deg (TE) and 32.24 deg (QC).
            expected_TE = 22.9007986415;
            expected_QC = 36.3133926497;
            old_wrong_TE = 0.33;
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            fprintf(['\n    VT sweeps: TE received = %.10f deg (chord-geometry %.10f, ' ...
                'old mirrored-form %.2f);  QC received = %.10f deg (chord-geometry %.10f)\n'], ...
                g.TE_sweep_vt, expected_TE, old_wrong_TE, g.QC_sweep_vt, expected_QC);
            tc.verifyEqual(g.TE_sweep_vt, expected_TE, 'AbsTol', 1e-6, ...
                'F16GeomL2.TE_sweep_vt must match the VT panel''s own chord geometry.');
            tc.verifyEqual(g.QC_sweep_vt, expected_QC, 'AbsTol', 1e-6, ...
                'F16GeomL2.QC_sweep_vt must match the VT panel''s own chord geometry.');
            tc.verifyGreaterThan(g.TE_sweep_vt, 15, ...
                ['F16GeomL2.TE_sweep_vt has regressed toward the mirrored-form ' ...
                 '0.33 deg -- a near-zero VT trailing-edge sweep is physically impossible.']);
        end

        function testWingAndHTSweepsStillUseMirroredForm(tc)
        % Guard the other direction: the wing and horizontal tail ARE mirrored
        % surfaces and must keep the 4/AR form. Both have AR=3.0,
        % lambda=0.2275, LE=40 deg, so both quarter-chord sweeps stay at the
        % hand-computed 32.1831783983 deg (see the headline wing test above).
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyEqual(g.QC_sweep_wing, 32.1831783983, 'AbsTol', 1e-6, ...
                'Wing is mirrored -- it must keep GeometryBase.convert_sweep''s 4/AR form.');
            tc.verifyEqual(g.QC_sweep_ht, 32.1831783983, 'AbsTol', 1e-6, ...
                'HT is mirrored -- it must keep GeometryBase.convert_sweep''s 4/AR form.');
        end

        % ================================================================== %
        % Roskam Eq. 12.1 variable root/tip tc lifting-surface formula
        % (compute_S_wet_planform_roskam, moved from former L3, now OFFICIAL for
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
            received = GeomL2.compute_S_wet_planform_roskam(100, 0.05, 0.03, 0.25);
            fprintf('\n    roskam planform: received = %.10f ft^2,  hand-computed = %.10f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'AbsTol', 1e-6);
        end

        function testRoskamPlanformZeroTipTcErrors(tc)
        % Guard-gap fix (2026-07-22 OOP pass, GeomL2.md "Guard gaps" note):
        % tc_t=0 used to silently return Inf (division by tc_r/tc_t is the
        % formula's tc_r/tc_t term); now guarded by an arguments-block
        % mustBePositive constraint on tc_t, so this errors instead.
            tc.verifyError(@() GeomL2.compute_S_wet_planform_roskam(100, 0.05, 0, 0.25), ...
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
            received = F16GeomBrandtAlt.compute_s_wet_fus_brandt_lowfi(7.0, 5.0, 46.5);   % Mod (08/18/2026) (Claude)
            fprintf('\n    fus brandt low-fi: received = %.4f ft^2,  Brandt GT = %.4f ft^2\n', ...
                received, tc.BRANDT_FUS_LOWFI);
            tc.verifyEqual(received, tc.BRANDT_FUS_LOWFI, 'RelTol', 1e-3, ...
                'compute_s_wet_fus_brandt_lowfi does not match Brandt Geom!B3 within 0.1%.');
        end

        function testF16GeomL2FusBrandtLowfiHighLevel(tc)
        % High-level get_S_wet_fuselage_brandt_lowfi(obj) reads
        % obj.W_max_fuselage/H_max_fuselage/L_fuselage from a real
        % F16GeomL2 instance and must match the low-level call above.
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            % Mod (08/18/2026) (Claude) -- the object-taking wrapper is gone.
            received = F16GeomBrandtAlt.compute_s_wet_fus_brandt_lowfi( ...
                           g.W_max_fuselage, g.H_max_fuselage, g.L_fuselage);
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
            received    = GeomL3.compute_s_wet_from_control_stations( ...   % Mod (08/19/2026) (Claude)
                [frames.x_ft], [frames.z_chine_ft], [frames.z_ft], [frames.w_ft], [frames.h_ft]);
            fprintf('\n    fus brandt high-fi: received = %.4f ft^2,  Brandt GT = %.4f ft^2\n', ...
                received, tc.BRANDT_FUS_HIGHFI);
            tc.verifyEqual(received, tc.BRANDT_FUS_HIGHFI, 'RelTol', 0.005, ...
                'compute_s_wet_from_control_stations does not match Brandt Geom!D23 within 0.5%.');
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
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
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
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            received = g.S_exposed_wing;
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

        function testDuctNoDuctGivesWarningAndZero(tc)
        % D_inlet = D_exit = L_duct = 0 means "no duct given," not a
        % zero-length duct. compute_s_wet_duct must warn, not error, and
        % must return 0 (fixes the earlier mustBePositive-on-L_duct
        % contradiction with GET_S_WET's own documented no-duct convention).
            received = tc.verifyWarning(@() GeomL2.compute_s_wet_duct(0, 0, 0), ...
                'GeomL2:noDuctGeometry', ...
                'A design with no duct geometry must warn, not error or fail silently.');
            tc.verifyEqual(received, 0, 'No-duct case must give 0 duct wetted area.');
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
            g        = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            received = GeomL2.compute_s_wet_duct(g.D_inlet, g.D_exit, g.L_duct);   % Mod (08/18/2026) (Claude)
            fprintf('\n    duct S_wet: received = %.4f ft^2,  Brandt nacelle = %.4f ft^2 (different definitions)\n', ...
                received, tc.BRANDT_NACELLE_SWET);
            tc.verifyGreaterThan(received, 0, 'Duct S_wet must be positive.');
            tc.verifyLessThan(received, 5 * tc.BRANDT_NACELLE_SWET, ...
                'Duct S_wet is more than 5x Brandt nacelle estimate -- check for a gross unit/formula error.');
        end

        % ================================================================== %
        % PHASE 2 (2026-07-25): propulsion injection, derived t/c means,
        % Amax / L_aircraft. See the class header for what each change fixed.
        % ================================================================== %

        function testConstructorRequiresInjectedPropulsion(tc)
        % The propulsion object is a REQUIRED second argument -- there is
        % deliberately no optional/defaulted injection, because a silent default
        % is the exact defect class Phase 2 removes (it would re-freeze the
        % engine thrust inside geometry). A path-only call must therefore error.
            tc.verifyError(@() F16GeomL2(f16a_spec_path(2)), 'MATLAB:minrhs', ...
                'F16GeomL2 must require an injected propulsion object (no silent default).');
            % Positive control: the two-argument form constructs.
            tc.verifyClass(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                'F16GeomL2');
        end

        function testTcHtVtAreDerivedRootTipMeans(tc)
        % tc_ht / tc_vt were STORED 0.04 inputs [Brandt Main!C22/H22, the NACA
        % 4-digit '0004' designation]. Phase 2 made the T.O. 1F-16A-1 Sec. I
        % biconvex root/tip splits the SINGLE t/c basis (locked decision 6), so
        % both are now Dependent root/tip means and the L2 JSON carries no
        % HT/VT tc_ratio key at all. Hand-computed from the T.O. splits:
        %   tc_ht = (0.060 + 0.035)/2 = 0.0475
        %   tc_vt = (0.053 + 0.030)/2 = 0.0415
        % The old stored 0.04 is pinned as a NOT-equal regression guard: a
        % re-frozen uniform input would read 0.04 for both.
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyEqual(g.tc_ht, 0.0475, 'AbsTol', 1e-12, ...
                'tc_ht must be the (0.060+0.035)/2 T.O. root/tip mean.');
            tc.verifyEqual(g.tc_vt, 0.0415, 'AbsTol', 1e-12, ...
                'tc_vt must be the (0.053+0.030)/2 T.O. root/tip mean.');
            tc.verifyGreaterThan(abs(g.tc_ht - 0.04), 1e-3, ...
                'tc_ht has regressed to the old stored uniform 0.04 input.');
            tc.verifyGreaterThan(abs(g.tc_vt - 0.04), 1e-4, ...
                'tc_vt has regressed to the old stored uniform 0.04 input.');
            % Derived -> read-only.
            tc.verifyError(@() setfield(g, 'tc_ht', 0.04), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'tc_vt', 0.04), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testAmaxAndOverallLengthAtL2(tc)
        % Both are NEW at L2 in Phase 2, so an injected aero object can read the
        % Raymer 6th ed. Eq. 12.44 Sears-Haack inputs live instead of carrying
        % Brandt's frozen geometry OUTPUTS (Geom!B20 = 25.110556,
        % Geom!B21 = 48.303947) as aero inputs.
        %   Amax = (pi/4)*W_max*H_max = (pi/4)*7.0*5.0 = 35*pi/4
        %        = 27.4889357189 ft^2
        %   [standard elliptical-cross-section identity; NO equation number is
        %    known -- documented as such per the convert_sweep precedent,
        %    todo.md 2026-07-25 Phase 2 §4]
        %   L_aircraft = 47.65 ft, a genuine INPUT (not derivable: the geometry
        %   model has no nose-boom/tailcone x-stations). Distinct from
        %   L_fus = 46.5 ft -- the two length scales must not be conflated.
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyEqual(g.Amax, 35*pi/4, 'AbsTol', 1e-12, ...
                'Amax must be the (pi/4)*W_max*H_max envelope ellipse.');
            tc.verifyEqual(g.L_aircraft, 47.65, 'AbsTol', 1e-12);
            tc.verifyNotEqual(g.L_aircraft, g.L_fus, ...
                'L_aircraft (47.65) and L_fus (46.5) are different length scales.');
            tc.verifyError(@() setfield(g, 'Amax', 25.110556), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testAmaxTracksFuselageEnvelopeLive(tc)
        % Positive control for a previously DEAD path: Amax was not modeled at
        % all in geometry and the aero side carried Brandt's frozen 25.110556,
        % so no fuselage change could ever reach the wave-drag term. Amax is now
        % Dependent, and linear in each envelope dimension.
        %   W_max 7.0 -> 8.0 (H_max = 5.0): Amax = (pi/4)*8*5 = 10*pi
        %                                        = 31.4159265359 ft^2
        %   ratio = 8/7 = 1.1428571 exactly (linear in W_max).
            g     = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            Amax0 = g.Amax;
            g.W_max_fuselage = 8.0;              % optimizer-style mutation
            tc.verifyEqual(g.Amax, 10*pi, 'AbsTol', 1e-12, ...
                'Amax must recompute live from the mutated fuselage width.');
            tc.verifyEqual(g.Amax/Amax0, 8/7, 'RelTol', 1e-12, ...
                'Amax is linear in W_max, so the ratio must be exactly 8/7.');
        end

        function testNacelleDiameterAndDuctTrackInjectedThrust(tc)
        % HEADLINE PHASE-2 DEPENDENCY-INJECTION POSITIVE CONTROL.
        % T_AB_SLS_lb = 23770 used to be a STORED geometry input, i.e. engine
        % data frozen into the airframe. Verification proved the path was DEAD:
        % setting p.T_SL = 30000 left geom.D_inlet, the 155.57 ft^2 of duct
        % wetted area, and the aero CD0 all bit-identical, so a thrust-growing
        % sizing loop under-predicted drag. T_AB_SLS_lb is now Dependent on the
        % injected prop.T_SL.
        %
        % Hand-computed from the cited formulas:
        %   D_nac = sqrt(T_AB_SLS/1900)      [Brandt Engn(s) D_nac;
        %                                     readme_geom.md Sec. 3]
        %     T = 23770 -> sqrt(12.5105263158) = 3.5370222385 ft
        %     T = 30000 -> sqrt(15.7894736842) = 3.9735970712 ft
        %   duct S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2), r1 = r2 = D/2
        %              -> degenerates to pi*D*L    [Raymer 6th ed. Sec. 7.3]
        %     L_duct = 14 ft:  pi*3.5370222385*14 = 155.5663631217 ft^2
        %                      pi*3.9735970712*14 = 174.7679271407 ft^2
        %   Delta(duct S_wet) = 19.2015640190 ft^2
        %   CD0 = Cfe*S_wet/S_ref            [Raymer 6th ed. Eq. 12.23], linear
        %     in S_wet, so with Cfe = 0.0035 [Raymer Table 12.3] and
        %     S_ref = 300 ft^2:
        %     Delta(CD0) = 0.0035*19.2015640190/300 = 2.2401824689e-4
            p = F16PropL2(f16a_spec_path(2));
            g = F16GeomL2(f16a_spec_path(2), p);
            a = F16AeroL2(g, f16a_spec_path(2));

            tc.verifyEqual(g.T_AB_SLS_lb, p.T_SL, 'AbsTol', 1e-12, ...
                'T_AB_SLS_lb must be the injected prop.T_SL, not a stored copy.');
            tc.verifyEqual(g.D_inlet, 3.5370222385, 'RelTol', 1e-9, ...
                'D_inlet must be sqrt(23770/1900).');
            tc.verifyEqual(GeomL2.compute_s_wet_duct(g.D_inlet, g.D_exit, g.L_duct), 155.5663631217, 'RelTol', 1e-9, ...
                'Duct S_wet must be pi*D*L at D = sqrt(23770/1900).');
            cd0_0 = a.drag_polar(AircraftState(0, 0.5)).CD0;

            p.T_SL = 30000;   % in-place engine mutation, no reconstruction

            tc.verifyEqual(g.T_AB_SLS_lb, 30000, 'AbsTol', 1e-12);
            tc.verifyEqual(g.D_inlet, 3.9735970712, 'RelTol', 1e-9, ...
                'D_inlet must track the mutated thrust: sqrt(30000/1900).');
            tc.verifyEqual(g.D_exit, g.D_inlet, 'AbsTol', 1e-12, ...
                'The nacelle is a constant-diameter cylinder: D_exit == D_inlet.');
            tc.verifyEqual(GeomL2.compute_s_wet_duct(g.D_inlet, g.D_exit, g.L_duct), 174.7679271407, 'RelTol', 1e-9, ...
                'Duct S_wet must track the mutated nacelle diameter.');
            cd0_1 = a.drag_polar(AircraftState(0, 0.5)).CD0;
            % RelTol 1e-6: the expected delta is hand-arithmetic carried to 11
            % significant figures, so only round-off at that level is tolerated.
            tc.verifyEqual(cd0_1 - cd0_0, 2.2401824689e-4, 'RelTol', 1e-6, ...
                ['CD0 must move by Cfe*Delta(S_wet_duct)/S_ref when engine thrust ' ...
                 'changes -- this whole chain was dead before Phase 2.']);
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
            g = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            fprintf('\n    L2 ctor: AR_wing=%.2f, LE_sweep_wing=%.1f, S_ref=%.1f, QC_sweep_wing=%.4f deg\n', ...
                g.AR_wing, g.LE_sweep_wing, g.S_ref, g.QC_sweep_wing);
            tc.verifyEqual(g.AR_wing, 3.0, 'AbsTol', 1e-9);
            tc.verifyEqual(g.LE_sweep_wing, 40.0, 'AbsTol', 1e-9);
            tc.verifyEqual(g.S_ref, 300.0, 'AbsTol', 1e-9);
        end

    end
end
