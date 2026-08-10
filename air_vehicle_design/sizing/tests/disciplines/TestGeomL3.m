classdef TestGeomL3 < matlab.unittest.TestCase
%TESTGEOML3  Tier-1 unit/correctness tests for the L3 geometry tier
%   (GeometryModelL3, the GeomL3 static toolbox, F16GeomL3).
%
%   2026-07-24: GeomL3 (re)introduced (user decision, reversing the 2026-07-22
%   "Geometry has no L3").
%   2026-07-25 (PHASE 2, locked user decisions): promoted from a weights-only
%   tier to the FULL L3 geometry tier consumed by L3 geometry + aero + weights.
%   Authoritative spec: examples/F16A/F16GeomL3.md.
%
%   L3 is the HIGHER-fidelity PHYSICAL / T.O.-geometry tier: where a
%   physical/T.O. value differs from Brandt, GeomL3 uses the physical one (VT LE
%   sweep 47.5 deg, L_fus 47.5 ft, HT span B_h = 18.5 ft as the PRIMARY span,
%   exposed HT/VT AR 2.114/1.294 and tapers 0.390/0.437). Those divergences from
%   GeomL2 are INTENTIONAL fidelity differences, not errors (locked decision,
%   VnV/BrandtF16A/todo.md 2026-07-24 GeomL3 + 2026-07-25 Phase 2), so the
%   physical inputs are asserted here as the correct spec.
%
%   ==========================================================================
%   WHAT PHASE 2 CHANGED, and which test guards it
%   ==========================================================================
%   1. CONSTRUCTOR: F16GeomL3(json_path, prop). A propulsion object is a
%      REQUIRED injected argument -- the nacelle diameter, and hence duct wetted
%      area and CD0, is sized from engine SLS thrust (sqrt(T_AB_SLS/1900)),
%      which is engine data, not airframe data.
%          -> testConstructorRequiresInjectedPropulsion
%   2. RENAME (F16GeomL3.md §2): AR_ht / lambda_ht / S_ht / S_vt now mean
%      FULL planform on BOTH tiers; the physical exposed values live under
%      AR_exposed_ht / lambda_exposed_ht / AR_exposed_vt / lambda_exposed_vt.
%      This removed a live silent-wrong-answer hazard: F16AeroL3's reference
%      length getter calls GeometryBase.compute_mac(g.c_root_ht, g.lambda_ht),
%      and Raymer 7th ed. Eq. 7.8 needs the FULL-planform taper that goes with
%      the chord it is handed -- under the old naming an injected F16GeomL3 fed
%      the exposed 0.390 where 0.2275 belongs, giving a wrong HT MAC, Reynolds
%      number and Eq. 12.30 form factor with no error and no warning.
%          -> testFullVsExposedPlanformNamesAfterRename
%   3. OPTION-B HT PLANFORM (Decision 1): the whole HT planform derives from the
%      measured S_ht = 108 + B_h = 18.5 INPUT PAIR, so AR_ht is DERIVED.
%          -> testHTPlanformFromSpanAreaPair, testHTAspectRatioTracksSpanMutation
%   4. FIVE quantities moved INPUT -> Dependent and must never be re-frozen:
%      S_exposed_ht, S_exposed_vt, AR_ht, tc_ht, tc_vt (plus T_AB_SLS_lb, which
%      left geometry entirely, and the new Amax).
%          -> testFormerlyFrozenPropertiesAreReadOnly
%   5. tc_ht / tc_vt changed VALUE: stored 0.04 -> the T.O. root/tip means
%      0.0475 / 0.0415.  -> testTcHtVtAreDerivedRootTipMeans
%   6. The official lifting-surface S_wet is Roskam Vol. II Eq. 12.1 (was
%      Brandt's uniform-t/c Geom!B13 form), and get_S_wet now INCLUDES the duct
%      (was airframe-only).  -> testComponentSwetRoskamEq121, testTotalSwet...
%   7. Propulsion DI is live end to end.
%          -> testNacelleDiameterAndDuctTrackInjectedThrust
%
%   ==========================================================================
%   EXPECTED VALUES -- how every one below is derived
%   ==========================================================================
%   Each is computed from the cited formula written out longhand, with the
%   arithmetic reproduced in the comment above its assertion. None is read back
%   from the class under test, and none is copied from
%   VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json or from any comparison
%   report (CLAUDE.md's two-tier rule). Where a Brandt figure is mentioned it is
%   labelled as a reference/divergence note, never used as the oracle.
%
%   Cited formulas used:
%     span            b = sqrt(AR*S)                        [definitional]
%     aspect ratio    AR = b^2/S                            [definitional]
%     root chord      c_r = 2*S/(b*(1+lambda))              [Raymer 7th Eq. 7.6]
%     tip chord       c_t = lambda*c_r                      [Raymer 7th Eq. 7.7]
%     MAC        cbar = (2/3)*c_r*(1+l+l^2)/(1+l)           [Raymer 7th Eq. 7.8]
%     sweep, MIRRORED (wing/HT):
%        tan(L_x) = tan(L_LE) - (4/AR)*x*(1-l)/(1+l)
%     sweep, SINGLE PANEL (VT):
%        tan(L_x) = tan(L_LE) - (2/AR)*x*(1-l)/(1+l)
%        [standard swept-wing planform identity, uncited to an edition/equation
%         number -- see src/base/GeometryBase.md, RESOLVED 2026-07-21]
%     exposed horizontal clip (fuselage half-width fw, half span hs):
%        c_exp = c_r - (fw/hs)*(c_r - c_t);
%        S_exp = (c_exp + c_t)/2*(hs - fw)*2
%     exposed vertical clip (fuselage half-height fh, FULL panel span b):
%        c_exp = c_r - (fh/b)*(c_r - c_t);  S_exp = (c_exp + c_t)/2*(b - fh)
%        [Brandt F-16A workbook; VnV/BrandtF16A/readme_geom.md Sec. 4.3]
%     lifting-surface S_wet, OFFICIAL at L3 (Decision 2):
%        S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*l)/(1+l))
%        [Roskam, Airplane Design Vol. II, Eq. 12.1]
%     fuselage S_wet:
%        S_wet = pi*D*L*(1-2/f)^(2/3)*(1+1/f^2),  f = L/D
%        [Roskam Vol. II Eq. 12.3]
%     duct S_wet = pi*(r1+r2)*sqrt((r2-r1)^2+L^2); r1 = r2 -> pi*D*L
%        [Raymer 6th ed. Sec. 7.3]
%     nacelle diameter  D_nac = sqrt(T_AB_SLS/1900)
%        [Brandt Engn(s) D_nac; readme_geom.md Sec. 3]
%     Amax = (pi/4)*W_max*H_max
%        [standard elliptical-cross-section identity -- NO equation number is
%         known for it in any reference in this repo; documented as such per the
%         convert_sweep precedent. STANDING OPEN item, todo.md 2026-07-25 §4]
%
%   TOLERANCES. Exact algebra (spans, t/c means, Amax, definitional AR) is
%   asserted at AbsTol/RelTol 1e-12 -- machine precision, since both sides are
%   the same closed-form expression. Values whose expected number is transcribed
%   here to 10-12 significant figures (chords, sweeps, exposed and wetted areas)
%   use RelTol 1e-9: that bounds transcription round-off at the last digit
%   written and nothing looser. No tolerance below was widened to make an
%   assertion pass.
%
%   testTODO_* is a DELIBERATELY-FAILING placeholder for a citation still marked
%   _TODO in the JSON -- see the bottom of this file.

    methods (Static, Access = private)

        function g = makeGeom()
        %MAKEGEOM  A fresh F16GeomL3 from the unified L3 JSON, with the injected
        %   propulsion object required since Phase 2. At the L3 rung that object
        %   is an F16PropL2: there is NO L3 propulsion tier (locked decision
        %   2026-07-25), so L2 propulsion serves the L3 rung.
            g = F16GeomL3(f16a_spec_path(3), F16PropL2(f16a_spec_path(2)));
        end

        function G = readGeomJSON(level)
        %READGEOMJSON  The .geometry block of a unified input JSON.
            G = jsondecode(fileread(f16a_spec_path(level))).geometry;
        end

    end

    methods (Test)

        % ================================================================== %
        % Construction + JSON pipeline
        % ================================================================== %

        function testConstructFromJson(tc)
            g = TestGeomL3.makeGeom();
            tc.verifyClass(g, 'F16GeomL3');
            tc.verifyEqual(g.S_ref, 300.0, 'AbsTol', 1e-12);
            tc.verifyEqual(g.get_S_ref(), 300.0, 'AbsTol', 1e-12);
        end

        function testNoArgConstructorErrors(tc)
        % No silent default -- a no-arg call must error (required-path guard).
            tc.verifyError(@() F16GeomL3(), 'MATLAB:minrhs');
        end

        function testConstructorRequiresInjectedPropulsion(tc)
        % PHASE 2. The propulsion object is a REQUIRED second argument, with no
        % optional/defaulted injection: a silent default is the exact defect
        % class Phase 2 removes, because it would re-freeze engine thrust inside
        % geometry and re-pin the duct wetted area to a stale engine. A
        % path-only call must therefore error.
            tc.verifyError(@() F16GeomL3(f16a_spec_path(3)), 'MATLAB:minrhs', ...
                'F16GeomL3 must require an injected propulsion object (no silent default).');
            tc.verifyClass(TestGeomL3.makeGeom(), 'F16GeomL3');
        end

        % ================================================================== %
        % Wing -- derived planform (hand-computed, not self-referential)
        % ================================================================== %

        function testWingSpanAndChords(tc)
        % S_ref = 300 ft^2, AR_wing = 3.0, lambda_wing = 0.2275:
        %   b_wing      = sqrt(3.0*300) = sqrt(900)          = 30            ft
        %   c_root_wing = 2*300/(30*(1+0.2275)) = 600/36.825  = 16.2932790224 ft
        %   c_tip_wing  = 0.2275*16.2932790224               =  3.7067209776 ft
        %   cbar_wing   = (2/3)*16.2932790224
        %                 *(1+0.2275+0.2275^2)/(1+0.2275)
        %               = 10.8621860149*1.0421639511         = 11.3201786951 ft
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.b_wing,      30.0,           'AbsTol', 1e-12);
            tc.verifyEqual(g.c_root_wing, 16.2932790224,  'RelTol', 1e-9);
            tc.verifyEqual(g.c_tip_wing,   3.7067209776,  'RelTol', 1e-9);
            tc.verifyEqual(g.cbar_wing,   11.3201786951,  'RelTol', 1e-9);
        end

        function testExposedWingAreaIsTheHandComputedClip(tc)
        % S_exposed_wing is DERIVED from the wing planform via the exposed-area
        % clip. Hand-computed with fw = W_max_fuselage/2 = 3.5 ft and
        % hs = b_wing/2 = 15.0 ft:
        %   c_exp = 16.2932790224 - (3.5/15.0)*(16.2932790224-3.7067209776)
        %         = 16.2932790224 - 0.2333333333*12.5865580448
        %         = 16.2932790224 - 2.9368635438  = 13.3564154786 ft
        %   S_exp = (13.3564154786+3.7067209776)/2*(15.0-3.5)*2
        %         = 8.5315682281*23.0             = 196.2260692464 ft^2
        % (For reference only, NOT the oracle: Brandt Geom!7 = 196.2261 -- the
        %  clip reproduces his exposed-wing table, which is why the formula is
        %  trusted, but the number asserted here is the hand-computed one.)
            g        = TestGeomL3.makeGeom();
            received = g.S_exposed_wing;
            fprintf('\n    S_exposed_wing: received = %.7f ft^2,  hand-computed = %.7f ft^2\n', ...
                received, 196.2260692464);
            tc.verifyEqual(received, 196.2260692464, 'RelTol', 1e-9, ...
                'F16GeomL3.S_exposed_wing does not match the hand-computed fuselage clip.');
            tc.verifyEqual(g.get_S_exposed_wing(), received, 'AbsTol', 1e-12, ...
                'get_S_exposed_wing must passthrough the Dependent value unchanged.');
        end

        % ================================================================== %
        % Horizontal tail -- DECISION 1 (option B), the headline Phase-2 change
        % ================================================================== %

        function testHTPlanformFromSpanAreaPair(tc)
        % DECISION 1 (user, 2026-07-25, option B "physical span primary"): the
        % HT planform is fixed by the MEASURED pair S_ht = 108 ft^2
        % [Brandt Main!C18] and B_h = 18.5 ft (18 ft 6 in) [USAF 3-view], so the
        % FULL-planform aspect ratio is DERIVED, not stored. Rationale worth
        % keeping: area and span are what a 3-view measures; aspect ratio is
        % definitional. A stored AR_ht = 3.0 alongside both would be
        % self-contradictory (sqrt(3.0*108) = 18.0 ft, not 18.5) AND would go
        % stale the instant an optimizer moved the span.
        %   AR_ht     = B_h^2/S_ht = 18.5^2/108 = 342.25/108 = 3.1689814815
        %   b_ht      = B_h                                  = 18.5           ft
        %   c_root_ht = 2*108/(18.5*(1+0.2275)) = 216/22.70875 = 9.5117520779 ft
        %   c_tip_ht  = 0.2275*9.5117520779                   = 2.1639235977 ft
        % Brandt Main!C19 = 3.0 is now a COMPARISON REFERENCE (+5.63%), not an
        % input, so 3.0 is pinned below as a NOT-equal regression guard: if
        % anyone re-freezes AR_ht as a stored JSON input it will read 3.0 and the
        % chords will drift back to the 18.0 ft basis (9.7760 / 2.2240).
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.AR_ht,     342.25/108,    'AbsTol', 1e-12, ...
                'AR_ht must be the definitional B_h^2/S_ht, not a stored input.');
            tc.verifyEqual(g.b_ht,      18.5,          'AbsTol', 1e-12, ...
                'b_ht mirrors the PRIMARY measured span B_h.');
            tc.verifyEqual(g.c_root_ht,  9.5117520779, 'RelTol', 1e-9);
            tc.verifyEqual(g.c_tip_ht,   2.1639235977, 'RelTol', 1e-9);
            tc.verifyGreaterThan(abs(g.AR_ht - 3.0), 0.15, ...
                'AR_ht has regressed to Brandt''s stored 3.0 -- it must be derived from B_h.');
            tc.verifyGreaterThan(abs(g.c_root_ht - 9.7759674), 0.2, ...
                'c_root_ht has regressed to the option-A 18.0 ft-span basis.');
        end

        function testHTAspectRatioTracksSpanMutation(tc)
        % LIVE-RECOMPUTE guard specific to Decision 1: AR_ht is Dependent, so
        % mutating the measured span IN PLACE must move the aspect ratio, both
        % chords and the exposed area with no reconstruction -- exactly what a
        % sizing loop / optimizer needs. Hand-computed at B_h = 20.0 ft with
        % S_ht = 108 and lambda_ht = 0.2275 unchanged:
        %   AR_ht     = 20^2/108 = 400/108                   = 3.7037037037
        %   c_root_ht = 2*108/(20*1.2275) = 216/24.55        = 8.7983706721 ft
        %   c_tip_ht  = 0.2275*8.7983706721                  = 2.0016293279 ft
        %   exposed clip, fw = 3.5, hs = 10.0:
        %     c_exp = 8.7983706721 - 0.35*(8.7983706721-2.0016293279)
        %           = 8.7983706721 - 0.35*6.7967413442
        %           = 8.7983706721 - 2.3788594705 = 6.4195112016 ft
        %     S_exp = (6.4195112016+2.0016293279)/2*(10.0-3.5)*2
        %           = 4.2105702648*13.0            = 54.7374134420 ft^2
        % A longer span at constant area gives smaller chords but MORE area
        % outside the fuselage, so the exposed area must RISE (51.15 -> 54.74).
            g      = TestGeomL3.makeGeom();
            AR0    = g.AR_ht;
            S_exp0 = g.S_exposed_ht;
            g.B_h  = 20.0;                       % optimizer-style in-place mutation
            tc.verifyEqual(g.AR_ht, 400/108, 'AbsTol', 1e-12, ...
                'AR_ht must recompute live from the mutated B_h.');
            tc.verifyGreaterThan(g.AR_ht, AR0, 'longer span at fixed area -> higher AR.');
            tc.verifyEqual(g.b_ht,      20.0,          'AbsTol', 1e-12);
            tc.verifyEqual(g.c_root_ht,  8.7983706721, 'RelTol', 1e-9, ...
                'HT root chord must follow the mutated span.');
            tc.verifyEqual(g.c_tip_ht,   2.0016293279, 'RelTol', 1e-9);
            tc.verifyEqual(g.S_exposed_ht, 54.7374134420, 'RelTol', 1e-9, ...
                'S_exposed_ht must follow the mutated span (Dependent, not frozen).');
            tc.verifyGreaterThan(g.S_exposed_ht, S_exp0, ...
                'More span outside the fuselage -> larger exposed HT area.');
        end

        function testHTSweepsUseMirroredFormAtTheDerivedAR(tc)
        % The HT is a MIRRORED surface, so its sweep conversion keeps the 4/AR
        % form, fed the DERIVED AR_ht = 3.1689814815 (Decision 1).
        %   tan(L_x) = tan(40 deg) - (4/AR_ht)*x*(1-0.2275)/(1+0.2275)
        %   tan(40 deg)            = 0.8390996312
        %   4/AR_ht = 432/342.25   = 1.2622352082
        %   (1-l)/(1+l) = 0.7725/1.2275 = 0.6293279022
        %   product (x=1)          = 0.7943598356
        %   x=0.25: atand(0.8390996312-0.1985899589) = atand(0.6405096723)
        %                                            = 32.6399548417 deg
        %   x=1.00: atand(0.8390996312-0.7943598356) = atand(0.0447397956)
        %                                            =  2.5616931648 deg
        % BY DESIGN, not an error: at L2 (stored AR_ht = 3.0) the same identity
        % gives 32.1831783983 / -0.0002 deg, and that -0.0002 matches Brandt
        % Main!C27 = -0.00024343 exactly. Decision 1's higher derived AR
        % slightly AFT-sweeps the L3 HT trailing edge. The guard below pins that
        % the L3 TE sweep is NOT the L2/Brandt near-zero value, so an accidental
        % revert to a stored AR_ht = 3.0 fails loudly.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.QC_sweep_ht, 32.6399548417, 'RelTol', 1e-9, ...
                'HT quarter-chord sweep must use the mirrored 4/AR form at the derived AR_ht.');
            tc.verifyEqual(g.TE_sweep_ht,  2.5616931648, 'RelTol', 1e-9, ...
                'HT trailing-edge sweep must use the mirrored 4/AR form at the derived AR_ht.');
            tc.verifyGreaterThan(g.TE_sweep_ht, 1.0, ...
                ['L3 TE_sweep_ht has collapsed toward L2/Brandt''s ~0 deg -- that means ' ...
                 'AR_ht reverted to a stored 3.0 instead of the derived B_h^2/S_ht.']);
        end

        % ================================================================== %
        % Vertical tail -- single-panel sweep form at L3 too
        % ================================================================== %

        function testVTSweepsUseSinglePanelFormAtL3(tc)
        % REGRESSION GUARD, mirroring TestGeomL2's VT 0.33 deg pin. A vertical
        % tail is ONE panel -- root->tip spans the full b_vt -- so its sweep
        % conversion coefficient is 2/AR, not the mirrored 4/AR. The mirrored
        % form double-counts the taper term.
        %   b_vt   = sqrt(60*1.6) = sqrt(96)              = 9.7979589711 ft
        %   c_root = 2*60/(9.7979589711*1.5) = 120/14.6969384567
        %                                                 = 8.1649658093 ft
        %   c_tip  = 0.5*8.1649658093                     = 4.0824829046 ft
        %   tan(47.5 deg) = 1.0913085163   (physical/T.O. LE sweep)
        %   single panel, (2/1.6)*(0.5/1.5) = 1.25*0.3333333333 = 0.4166666667
        %     x=0.25: atand(1.0913085163-0.1041666667) = 44.6292623272 deg
        %     x=1.00: atand(1.0913085163-0.4166666667) = 34.0052496648 deg
        %   the WRONG mirrored form, (4/1.6)*(0.5/1.5) = 0.8333333333:
        %     x=1.00: atand(1.0913085163-0.8333333333) = 14.4654943537 deg
        % An 14.47 deg trailing-edge sweep on a panel whose LE is at 47.5 deg is
        % the taper term applied twice; 34.01 deg is the panel's own chord
        % geometry. The final check pins the difference so the mirrored form can
        % never creep back in.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.b_vt,      9.7979589711, 'RelTol', 1e-9);
            tc.verifyEqual(g.c_root_vt, 8.1649658093, 'RelTol', 1e-9);
            tc.verifyEqual(g.c_tip_vt,  4.0824829046, 'RelTol', 1e-9);
            fprintf(['\n    L3 VT sweeps: QC received = %.7f deg (hand-computed %.7f), ' ...
                'TE received = %.7f deg (hand-computed %.7f; wrong mirrored form %.7f)\n'], ...
                g.QC_sweep_vt, 44.6292623272, g.TE_sweep_vt, 34.0052496648, 14.4654943537);
            tc.verifyEqual(g.QC_sweep_vt, 44.6292623272, 'RelTol', 1e-9, ...
                'VT quarter-chord sweep must use the SINGLE-PANEL 2/AR form at LE = 47.5 deg.');
            tc.verifyEqual(g.TE_sweep_vt, 34.0052496648, 'RelTol', 1e-9, ...
                'VT trailing-edge sweep must use the SINGLE-PANEL 2/AR form at LE = 47.5 deg.');
            tc.verifyGreaterThan(abs(g.TE_sweep_vt - 14.4654943537), 15, ...
                ['F16GeomL3.TE_sweep_vt has regressed to the mirrored 4/AR form ' ...
                 '(14.47 deg) -- that double-counts the taper term on a single panel.']);
        end

        function testExposedTailAreasAreHandComputedClips(tc)
        % Both were STORED inputs (49.85 / 40.89) before Phase 2 -- frozen
        % derivable values that would go stale the instant an optimizer touched
        % S_ht / B_h / lambda_ht / the fuselage envelope. Now Dependent.
        %   HT, fw = W_max_fuselage/2 = 3.5 ft, hs = B_h/2 = 9.25 ft:
        %     c_exp = 9.5117520779 - (3.5/9.25)*(9.5117520779-2.1639235977)
        %           = 9.5117520779 - 0.3783783784*7.3478284802
        %           = 9.5117520779 - 2.7802594492 = 6.7314926287 ft
        %     S_exp = (6.7314926287+2.1639235977)/2*(9.25-3.5)*2
        %           = 4.4477081132*11.5           = 51.1486434417 ft^2
        %     BY DESIGN this is +2.611% vs Brandt Geom!8 = 49.8473 (reference
        %     only, not the oracle): his figure rests on his DERIVED 18.0 ft
        %     span, ours on the measured 18.5 ft. Not an error -- Decision 1.
        %   VT, fh = H_max_fuselage/2 = 2.5 ft, FULL panel span b_vt:
        %     c_exp = 8.1649658093 - (2.5/9.7979589711)*(8.1649658093-4.0824829046)
        %           = 8.1649658093 - 0.2551551815*4.0824829047
        %           = 8.1649658093 - 1.0416666667 = 7.1232991426 ft
        %     S_exp = (7.1232991426+4.0824829046)/2*(9.7979589711-2.5)
        %           = 5.6028910236*7.2979589711   = 40.8896688101 ft^2
        %     This clip takes NO sweep argument, so despite the 47.5 deg LE sweep
        %     the L3 VT exposed area is bit-identical to L2's -- a genuine
        %     positive control. Do NOT invent a sweep-dependent exposed-area
        %     formula to manufacture a divergence (todo 2026-07-25 §7(a)).
            g = TestGeomL3.makeGeom();
            fprintf('\n    S_exposed_ht = %.7f ft^2 (hand-computed %.7f)\n', ...
                g.S_exposed_ht, 51.1486434417);
            fprintf('    S_exposed_vt = %.7f ft^2 (hand-computed %.7f)\n', ...
                g.S_exposed_vt, 40.8896688101);
            tc.verifyEqual(g.S_exposed_ht, 51.1486434417, 'RelTol', 1e-9, ...
                'S_exposed_ht must be the hand-computed option-B clip, not the old stored 49.85.');
            tc.verifyEqual(g.S_exposed_vt, 40.8896688101, 'RelTol', 1e-9, ...
                'S_exposed_vt must be the hand-computed clip, not the old stored 40.89.');
            tc.verifyGreaterThan(abs(g.S_exposed_ht - 49.85), 1.0, ...
                'S_exposed_ht has regressed to the pre-Phase-2 stored 49.85 input.');
        end

        % ================================================================== %
        % The Sec.-B rename: FULL vs EXPOSED planform names
        % ================================================================== %

        function testFullVsExposedPlanformNamesAfterRename(tc)
        % PHASE-2 RENAME GUARD (F16GeomL3.md §2). Before the rename this
        % tier used AR_ht / lambda_ht / AR_vt / lambda_vt for the EXPOSED
        % planform while GeometryModelL2 used the SAME FOUR NAMES for the FULL
        % planform, and carried no S_ht / S_vt at all. Both tiers are
        % GeometryBase subclasses, so injecting the wrong one compiled, ran, and
        % silently resolved one name to a different physical quantity.
        %
        % After the rename, on BOTH tiers:
        %   AR_ht / lambda_ht / S_ht / S_vt / AR_vt / lambda_vt = FULL planform
        %   AR_exposed_* / lambda_exposed_*                     = EXPOSED
        %
        % FULL values [Brandt Main!C18/C20, H18/H19/H20]: S_ht = 108,
        % lambda_ht = 0.2275, S_vt = 60, AR_vt = 1.6, lambda_vt = 0.5.
        % EXPOSED values, PHYSICAL construction figures [T.O./USAF]: 2.114 /
        % 0.390 / 1.294 / 0.437 -- three of the four are NOT reconcilable with
        % Brandt's exposed geometry (todo 2026-07-24 GeomL3 Sec. 1) and are
        % carried as inputs per the locked physical-tier decision.
        %
        % The final check is the concrete hazard the rename removed: F16AeroL3's
        % l_ref_comp getter calls GeometryBase.compute_mac(c_root_ht,
        % lambda_ht), and Raymer 7th ed. Eq. 7.8 needs the FULL-planform taper
        % that goes with the chord it is handed. With the FULL 0.2275:
        %   shape  = (1+0.2275+0.2275^2)/(1+0.2275)
        %          = 1.27925625/1.2275             = 1.0421639511
        %   mac_ht = (2/3)*9.5117520779*1.0421639511
        %          = 6.3411680520*1.0421639511     = 6.6085367518 ft
        % With the exposed 0.390 it would instead read
        %   (2/3)*9.5117520779*(1+0.390+0.1521)/1.390 = 7.0350469446 ft, +6.5%
        % -- a wrong HT Reynolds number and Eq. 12.30 form factor, silently.
            g = TestGeomL3.makeGeom();
            % FULL planform
            tc.verifyEqual(g.S_ht,      108.0,  'AbsTol', 1e-12);
            tc.verifyEqual(g.lambda_ht, 0.2275, 'AbsTol', 1e-12, ...
                'lambda_ht must now be the FULL-planform taper (0.2275), not the exposed 0.390.');
            tc.verifyEqual(g.S_vt,       60.0,  'AbsTol', 1e-12);
            tc.verifyEqual(g.AR_vt,       1.6,  'AbsTol', 1e-12, ...
                'AR_vt must now be the FULL-planform AR (1.6), not the exposed 1.294.');
            tc.verifyEqual(g.lambda_vt,   0.5,  'AbsTol', 1e-12, ...
                'lambda_vt must now be the FULL-planform taper (0.5), not the exposed 0.437.');
            tc.verifyEqual(g.LE_sweep_ht, 40.0, 'AbsTol', 1e-12);
            % EXPOSED planform, under the unambiguous names
            tc.verifyEqual(g.AR_exposed_ht,     2.114, 'AbsTol', 1e-12);
            tc.verifyEqual(g.lambda_exposed_ht, 0.390, 'AbsTol', 1e-12);
            tc.verifyEqual(g.AR_exposed_vt,     1.294, 'AbsTol', 1e-12);
            tc.verifyEqual(g.lambda_exposed_vt, 0.437, 'AbsTol', 1e-12);
            % The hazard the rename removed, checked on the actual consumer call
            tc.verifyEqual(GeometryBase.compute_mac(g.c_root_ht, g.lambda_ht), ...
                6.6085367518, 'RelTol', 1e-9, ...
                ['HT MAC via Raymer Eq. 7.8 must use the FULL-planform taper; a ' ...
                 'value near 7.035 ft means the exposed 0.390 leaked back into lambda_ht.']);
        end

        function testTcHtVtAreDerivedRootTipMeans(tc)
        % tc_ht / tc_vt were STORED 0.04 inputs [Brandt Main!C22/H22, NACA
        % 4-digit '0004']. Locked decision 6 made the T.O. 1F-16A-1 Sec. I
        % biconvex root/tip splits the SINGLE t/c basis at both tiers, so both
        % uniform values are now Dependent means:
        %   tc_ht = (tc_r_ht + tc_t_ht)/2 = (0.060 + 0.035)/2 = 0.0475
        %   tc_vt = (tc_r_vt + tc_t_vt)/2 = (0.053 + 0.030)/2 = 0.0415
        % The wing is untouched: it is genuinely uniform-t/c with no split
        % available, so tc_r_wing/tc_t_wing MIRROR tc_wing = 0.04.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.tc_ht, 0.0475, 'AbsTol', 1e-12, ...
                'tc_ht must be the (0.060+0.035)/2 T.O. root/tip mean, not a stored 0.04.');
            tc.verifyEqual(g.tc_vt, 0.0415, 'AbsTol', 1e-12, ...
                'tc_vt must be the (0.053+0.030)/2 T.O. root/tip mean, not a stored 0.04.');
            tc.verifyGreaterThan(abs(g.tc_ht - 0.04), 1e-3, ...
                'tc_ht has regressed to the pre-Phase-2 stored uniform 0.04.');
            tc.verifyGreaterThan(abs(g.tc_vt - 0.04), 1e-4, ...
                'tc_vt has regressed to the pre-Phase-2 stored uniform 0.04.');
            % Wing stays uniform-tc
            tc.verifyEqual(g.tc_wing,   0.04, 'AbsTol', 1e-12);
            tc.verifyEqual(g.tc_r_wing, 0.04, 'AbsTol', 1e-12);
            tc.verifyEqual(g.tc_t_wing, 0.04, 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Intentional physical divergences from GeomL2 (Brandt)
        % ================================================================== %

        function testPhysicalDivergencesFromGeomL2(tc)
        % These deliberately differ from GeomL2's Brandt values (intentional
        % fidelity differences, todo GeomL3 Sec. 2-4): VT LE sweep 47.5 vs 40,
        % L_fus 47.5 vs 46.5, HT physical span B_h 18.5 vs L2's derived 18.0.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.LE_sweep_vt, 47.5, 'AbsTol', 1e-12, ...
                'GeomL3 VT LE sweep must be the physical/T.O. 47.5 deg, not GeomL2 Brandt 40.');
            tc.verifyEqual(g.L_fus, 47.5, 'AbsTol', 1e-12, ...
                'GeomL3 L_fus must be the physical/T.O. 47.5 ft, not GeomL2 Brandt 46.5.');
            tc.verifyEqual(g.L_fuselage, g.L_fus, 'AbsTol', 1e-12, ...
                'L_fuselage mirrors L_fus (contract-parity duplicate).');
            tc.verifyEqual(g.B_h, 18.5, 'AbsTol', 1e-12, ...
                'GeomL3 HT span B_h must be the physical 18.5 ft (18 ft 6 in).');
        end

        function testFuselageDepthVsEquivalentDiameter(tc)
        % CRITICAL DI-correctness guard (todo GeomL3 Sec. 5): the weights Raymer
        % Eq. 15.4 fuselage DEPTH is H_max_fuselage = 5.0 -- NOT the Dependent
        % equivalent diameter D_fus = (W+H)/2 = (7+5)/2 = 6.0, which exists only
        % for the Roskam Eq. 12.3 S_wet term. This test locks the two apart so
        % they can never be conflated.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.H_max_fuselage, 5.0, 'AbsTol', 1e-12, ...
                'H_max_fuselage (weights Raymer-15.4 depth) must be 5.0 ft.');
            tc.verifyEqual(g.W_max_fuselage, 7.0, 'AbsTol', 1e-12);
            tc.verifyEqual(g.D_fus, 6.0, 'AbsTol', 1e-12, ...
                'D_fus (equivalent diameter, S_wet only) must be (7+5)/2 = 6.0 ft.');
            tc.verifyNotEqual(g.H_max_fuselage, g.D_fus, ...
                'Depth and equivalent diameter must stay distinct (naming-clash guard).');
        end

        function testAmaxIsAreaRuledNotTheEnvelopeEllipse(tc)
        % SUB-STEP 2h (2026-07-25). Amax was briefly (pi/4)*W_max*H_max = 35*pi/4
        % = 27.4889 -- but readme_geom.md §7 classifies the fuselage-envelope
        % form as the LOW-fidelity Amax, and Raymer Eq. 12.44's Sears-Haack term
        % wants the whole-aircraft AREA-RULED maximum. A coarse quantity had been
        % placed in the finest tier (same fidelity-inversion class as L3 once
        % using eta=0.95 while L2 used the real airfoil slope). L3 now computes
        % the area-ruled buildup; L2 correctly KEEPS the ellipse, since L2 is the
        % low-fidelity tier -- see TestGeomL2.testAmaxAndOverallLengthAtL2.
        %
        % Not asserting a closed form here: Amax is a MAX over 20 stations of a
        % 5-term sum (fuselage frames + wing + HT + VT cosine sections, less the
        % engine flow-through), so the meaningful checks are (a) it is NOT the
        % superseded ellipse, (b) it sits sensibly below the raw envelope, and
        % (c) the round-trip control below, which is the real proof.
        %   L_aircraft = 47.65 ft stays a genuine INPUT, DISTINCT from
        %   L_fus = 47.5 ft (todo §6: value approved, citation unpinned).
            g = TestGeomL3.makeGeom();
            tc.verifyNotEqual(g.Amax, 35*pi/4, ...
                'Amax must no longer be the (pi/4)*W_max*H_max envelope ellipse at L3.');
            tc.verifyGreaterThan(g.Amax, 0);
            tc.verifyLessThan(g.Amax, 35*pi/4, ...
                ['The area-ruled Amax should fall below the fuselage-envelope ' ...
                 'ellipse: the flow-through deduction removes more than the ' ...
                 'lifting-surface sections add at the governing station.']);
            tc.verifyEqual(g.L_aircraft, 47.65, 'AbsTol', 1e-12);
            tc.verifyNotEqual(g.L_aircraft, g.L_fus, ...
                'L_aircraft (47.65) and L_fus (47.5) are different length scales.');
        end

        function testAmaxRoundTripsToBrandtAtBrandtsOwnFuselageLength(tc)
        % THE CONTROL THAT PROVES THE METHOD, and the reason variant D (a
        % NORMALIZED frame table rescaled by the envelope) was chosen over
        % storing Brandt's raw table.
        %
        % The 20 frames are stored normalized (x/L_fus, w/W_max, h/H_max)
        % against Brandt's OWN envelope (46.5 / 7.0 / 5.0). So setting L_fus
        % back to 46.5 must denormalize to exactly Brandt's frame table and
        % reproduce his Amax. This is a genuine round-trip identity, NOT a fit:
        % nothing here was tuned to match, and normalizing then denormalizing by
        % the same envelope is arithmetically an identity.
        %   Brandt Geom!B20 = Geom!H47 = 25.11055621 ft^2
        %   framework, L_fus := 46.5    = 25.110534    (-0.0001%)
        % The residual 2e-5 is Brandt's own workbook using TWO different
        % hardcoded pi values in one calculation (3.1416 in the nacelle column,
        % 3.141579 in H47 and the cosine columns) -- todo §5 UPDATE.
        %
        % At the as-built L_fus = 47.5 the answer is 24.703652 (-1.62%), a
        % physical fidelity divergence, NOT an error: L3 is the physical/T.O.
        % tier and its fuselage is a foot longer than Brandt's.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.Amax, 24.703652, 'RelTol', 1e-6, ...
                'As-built L3 Amax (L_fus = 47.5).');
            g.L_fus = 46.5;                       % Brandt's own fuselage length
            tc.verifyEqual(g.Amax, 25.110534, 'RelTol', 1e-6, ...
                ['Denormalizing the frame table with Brandt''s own envelope must ' ...
                 'reproduce his Amax -- if this fails, normalization lost information.']);
            tc.verifyEqual(g.Amax, 25.11055621, 'RelTol', 2e-6, ...
                'Round-trip Amax must match Brandt Geom!B20 to within his own pi inconsistency.');
        end

        function testAmaxTracksFuselageEnvelopeLive(tc)
        % Positive control for a previously-DEAD path: with Amax frozen on the
        % aero side, no fuselage change could reach the Raymer Eq. 12.44
        % Sears-Haack term at all.
        %
        % Amax is Dependent, but under the area-ruled buildup it is DELIBERATELY
        % NO LONGER LINEAR in W_max -- a wider fuselage both enlarges every frame
        % section AND eats more exposed wing root (c_exp_root shrinks as the
        % fuselage half-width grows), so the two effects partly oppose. The
        % measured 7.0 -> 8.0 ratio is ~1.131, not 8/7 = 1.1429. Asserting 8/7
        % here would be asserting the superseded ellipse.
        %
        % Direction is what matters, and it must be RIGHT: storing Brandt's raw
        % (un-normalized) frame table was rejected precisely because W_max then
        % came out with the WRONG SIGN (-0.561% for +10%) and H_max was entirely
        % dead (0.000%) -- less optimization-live than the ellipse it replaced.
        % Verified live for the normalized table: W_max +10% -> +9.164%,
        % H_max +10% -> +9.164% (identical, since frame area is bilinear in w*h),
        % L_fus +10% -> +12.478%.
            g     = TestGeomL3.makeGeom();
            Amax0 = g.Amax;

            g.W_max_fuselage = 7.7;                        % +10%
            tc.verifyEqual(100*(g.Amax/Amax0 - 1), 9.164, 'AbsTol', 0.01, ...
                'Amax must rise ~9.164% for a +10% fuselage width -- and rise, not fall.');
            g.W_max_fuselage = 7.0;

            g.H_max_fuselage = 5.5;                        % +10%
            tc.verifyEqual(100*(g.Amax/Amax0 - 1), 9.164, 'AbsTol', 0.01, ...
                ['Fuselage DEPTH must move Amax identically to width (frame area ' ...
                 'is bilinear in w*h). It was completely dead under a raw frame table.']);
            g.H_max_fuselage = 5.0;

            g.L_fus = 52.25;                               % +10%
            tc.verifyEqual(100*(g.Amax/Amax0 - 1), 12.478, 'AbsTol', 0.01, ...
                'Fuselage length must stretch the station grid and move Amax ~+12.478%.');
            g.L_fus = 47.5;

            tc.verifyEqual(g.Amax, Amax0, 'RelTol', 1e-12, ...
                'Restoring every input must restore Amax -- Dependent, never cached.');
        end

        function testAmaxIsInsensitiveToTailPlanform(tc)
        % Not a defect -- a true geometric fact for this configuration, asserted
        % so nobody later "fixes" it. The HT and VT cosine sections begin aft of
        % x ~ 38.7 ft, while the governing station sits far forward, so no tail
        % variable can reach Amax. Verified live: S_ht, B_h, S_vt, tc_ht all
        % give exactly 0.000% for +10%.
            g     = TestGeomL3.makeGeom();
            Amax0 = g.Amax;
            g.S_ht = 118.8;                                % +10%
            tc.verifyEqual(g.Amax, Amax0, 'RelTol', 1e-12, ...
                'HT area cannot reach Amax: the HT section starts aft of the governing station.');
            g.S_ht = 108.0;
            g.S_vt = 66.0;                                 % +10%
            tc.verifyEqual(g.Amax, Amax0, 'RelTol', 1e-12, ...
                'VT area cannot reach Amax, for the same reason.');
        end

        % ================================================================== %
        % Control-surface + configuration inputs the weights tier needs
        % ================================================================== %

        function testControlSurfaceAndConfigInputs(tc)
        %   S_csw / S_r / S_cs BECAME DEPENDENT 2026-08-10. They were frozen
        %   plain inputs that the sizing loop never touched, so the L3 weight
        %   equations kept a 300 ft^2-wing control-surface area while the loop
        %   converged S_ref to roughly 180. They are buildups on the
        %   loop-written component areas now:
        %       S_csw = S_flaperon + S_lef  = 31.32 + 36.71  = 68.03
        %       S_r   = S_rud               =                  11.65
        %       S_cs  = S_csw + S_stab + S_rud = 68.03 + 108 + 11.65 = 187.68
        %   The first two still reproduce their old frozen values EXACTLY,
        %   because F16GeomL3's constructor seeds the components from the same
        %   T.O. 1F-16A-1 Fig. 1-2 measured areas. S_cs deliberately does not:
        %   190 was an unpinned estimate annotated "flaperon + HT + rudder +
        %   LEF", and the buildup of exactly those four terms is 187.68 (1.2%
        %   below). The estimate is retired, not the physics.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.S_csw, 68.03,  'AbsTol', 1e-10);   % wing control surfaces = flaperon + LEF
            tc.verifyEqual(g.S_cs,  187.68, 'AbsTol', 1e-10);   % total = wing + stabilator + rudder (was a frozen 190 estimate)
            tc.verifyEqual(g.S_r,   11.65,  'AbsTol', 1e-12);   % rudder area
            tc.verifyEqual(g.L_t,   22.0,   'AbsTol', 1e-12);   % tail arm
            tc.verifyEqual(g.F_w,   7.0,    'AbsTol', 1e-12);   % fuselage width at HT
            tc.verifyEqual(g.H_t,   0,      'AbsTol', 1e-12);   % conventional (non-T) tail
            tc.verifyEqual(g.H_v,   1,      'AbsTol', 1e-12);
            tc.verifyEqual(g.L_duct, 14.0,  'AbsTol', 1e-12);   % airframe duct length
        end

        function testControlSurfaceBuildupsAreLiveNotFrozen(tc)
        %   The staleness guard. Writing a component area must move its
        %   buildup immediately -- that is the whole point of making these
        %   three Dependent, and a stored copy would pass every value check
        %   above while silently freezing under the sizing loop.
            g = TestGeomL3.makeGeom();
            g.S_flaperon = 20;
            g.S_lef      = 30;
            g.S_rud      = 10;
            g.S_stab     = 50;
            tc.verifyEqual(g.S_csw, 50,  'AbsTol', 1e-12, 'S_csw must recompute from S_flaperon + S_lef.');
            tc.verifyEqual(g.S_r,   10,  'AbsTol', 1e-12, 'S_r must alias S_rud.');
            tc.verifyEqual(g.S_cs,  110, 'AbsTol', 1e-12, 'S_cs must recompute from S_csw + S_stab + S_rud.');
        end

        function testStabilatorSeedsToTheFullTailArea(tc)
        %   The F-16's horizontal tail is an all-moving stabilator, so its
        %   control-surface area is the WHOLE tail [Raymer 6th ed. Table 6.5
        %   footnote, "Supersonic usually all-moving tail without separate
        %   elevator"] -- not a chord fraction of it. This is also the only
        %   reading under which the retired S_cs = 190 annotation adds up.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.S_stab, g.S_ht, 'AbsTol', 1e-12);
            tc.verifyEqual(g.S_stab, 108.0,  'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Wetted areas -- Roskam Eq. 12.1 official, duct now included
        % ================================================================== %

        function testComponentSwetRoskamEq121(tc)
        % DECISION 2 (user, 2026-07-25): the OFFICIAL L3 lifting-surface wetted
        % area is Roskam Vol. II Eq. 12.1 fed the T.O. root/tip t/c splits (was
        % Brandt's uniform-t/c Geom!B13 form). Brandt's form survives only as a
        % comparison-report alternate row.
        %   S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*l)/(1+l))
        %   Wing: S_exp = 196.2260692464, tc_r = tc_t = 0.04, l = 0.2275
        %     tc_r/tc_t = 1 -> (1+0.2275)/(1+0.2275) = 1 -> factor = 1.01
        %     S_wet = 2*196.2260692464*1.01           = 396.3766598778 ft^2
        %   HT:   S_exp = 51.1486434417, tc_r = 0.060, tc_t = 0.035, l = 0.2275
        %     tc_r/tc_t = 1.7142857143; *0.2275 = 0.39; (1+0.39)/1.2275
        %                                             = 1.1323828921
        %     factor = 1 + 0.25*0.060*1.1323828921    = 1.0169857434
        %     S_wet = 2*51.1486434417*1.0169857434    = 104.0348823470 ft^2
        %   VT:   S_exp = 40.8896688101, tc_r = 0.053, tc_t = 0.030, l = 0.5
        %     tc_r/tc_t = 1.7666666667; *0.5 = 0.8833333333; /1.5
        %                                             = 1.2555555556
        %     factor = 1 + 0.25*0.053*1.2555555556    = 1.0166361111
        %     S_wet = 2*40.8896688101*1.0166361111    =  83.1398277675 ft^2
        %   Fuselage (Roskam Eq. 12.3), D_fus = 6.0, L_fus = 47.5, f = 7.9166667:
        %     pi*6*47.5 = 895.3539673      (1-2/f)^(2/3) = 0.7473684211^(2/3)
        %                                                = 0.8235526480
        %     (1+1/f^2) = 1.0159556614
        %     S_wet = 895.3539673*0.8235526480*1.0159556614 = 749.1336817716 ft^2
        %   Duct (Raymer Sec. 7.3 frustum, r1 = r2 -> pi*D*L),
        %     D = sqrt(23770/1900) = 3.5370222385, L_duct = 14:
        %     S_wet = pi*3.5370222385*14                    = 155.5663631217 ft^2
        % All five deliberately move L3 FURTHER from Brandt's ground truth
        % (wing +1.11%, HT +4.47%, VT +1.78%) and that is CORRECT: his GT
        % figures are the output of his own coarser uniform-t/c formula on his
        % own inputs, so the alternate would match them BY CONSTRUCTION. Those
        % percentages belong to the comparison report, never to an assertion.
            g = TestGeomL3.makeGeom();
            tc.verifyEqual(g.get_S_wet_wing(),     396.3766598778, 'RelTol', 1e-9, ...
                'Wing S_wet must be Roskam Eq. 12.1 on the hand-computed exposed area.');
            tc.verifyEqual(g.get_S_wet_HT(),       104.0348823470, 'RelTol', 1e-9, ...
                'HT S_wet must be Roskam Eq. 12.1 on the option-B exposed area.');
            tc.verifyEqual(g.get_S_wet_VT(),        83.1398277675, 'RelTol', 1e-9, ...
                'VT S_wet must be Roskam Eq. 12.1 on the hand-computed exposed area.');
            tc.verifyEqual(g.get_S_wet_fuselage(), 749.1336817716, 'RelTol', 1e-9, ...
                'Fuselage S_wet must be Roskam Eq. 12.3 at D_fus = 6.0, L_fus = 47.5.');
            tc.verifyEqual(g.get_S_wet_duct(),     155.5663631217, 'RelTol', 1e-9, ...
                'Duct S_wet must be the Raymer Sec. 7.3 frustum, degenerate to pi*D*L.');
            % The Dependent properties must agree with the methods exactly.
            tc.verifyEqual(g.S_wet_wing, g.get_S_wet_wing(), 'AbsTol', 1e-12);
            tc.verifyEqual(g.S_wet_ht,   g.get_S_wet_HT(),   'AbsTol', 1e-12);
            tc.verifyEqual(g.S_wet_vt,   g.get_S_wet_VT(),   'AbsTol', 1e-12);
        end

        function testTotalSwetIncludesDuct(tc)
        % SCOPE CHANGE in Phase 2: GeomL3's total was airframe-only
        % (wing+HT+VT+fuselage) because the tier had no duct geometry. It now
        % carries L_duct and the propulsion-injected nacelle diameter, so the
        % duct is the FIFTH component, matching GeomL2.
        %   396.3766598778 + 104.0348823470 + 83.1398277675
        %     + 749.1336817716 + 155.5663631217 = 1488.2514148856 ft^2
        % The four-component airframe-only sum would be 1332.6850517639, so the
        % explicit not-equal check below fails loudly if the duct term is ever
        % dropped again.
            g = TestGeomL3.makeGeom();
            sw_w = g.get_S_wet_wing(); sw_h = g.get_S_wet_HT();
            sw_v = g.get_S_wet_VT();   sw_f = g.get_S_wet_fuselage();
            sw_d = g.get_S_wet_duct();
            tc.verifyGreaterThan(sw_w, 0); tc.verifyGreaterThan(sw_h, 0);
            tc.verifyGreaterThan(sw_v, 0); tc.verifyGreaterThan(sw_f, 0);
            tc.verifyGreaterThan(sw_d, 0);
            fprintf('\n    total S_wet: received = %.7f ft^2,  hand-computed = %.7f ft^2\n', ...
                g.get_S_wet(), 1488.2514148856);
            tc.verifyEqual(g.get_S_wet(), 1488.2514148856, 'RelTol', 1e-9, ...
                'Total S_wet must be the hand-computed five-component sum (duct included).');
            tc.verifyEqual(g.get_S_wet(), sw_w + sw_h + sw_v + sw_f + sw_d, 'AbsTol', 1e-9, ...
                'get_S_wet must equal the sum of its FIVE components (wing+HT+VT+fuselage+duct).');
            tc.verifyEqual(g.S_wet, g.get_S_wet(), 'AbsTol', 1e-12, ...
                'Dependent S_wet must match get_S_wet().');
            tc.verifyGreaterThan(abs(g.get_S_wet() - (sw_w + sw_h + sw_v + sw_f)), 100, ...
                'get_S_wet has reverted to the pre-Phase-2 airframe-only (no duct) sum.');
        end

        % ================================================================== %
        % Propulsion dependency injection -- the headline dead-path fix
        % ================================================================== %

        function testNacelleDiameterAndDuctTrackInjectedThrust(tc)
        % HEADLINE PHASE-2 DEPENDENCY-INJECTION POSITIVE CONTROL, at L3.
        % T_AB_SLS_lb = 23770 was a STORED geometry input, i.e. engine data
        % frozen into the airframe, and verification proved the path was DEAD:
        % setting p.T_SL = 30000 left D_inlet, the 155.57 ft^2 of duct wetted
        % area and the aero CD0 bit-identical, so a thrust-growing sizing loop
        % under-predicted drag. It is now Dependent on the injected prop.T_SL.
        %
        %   D_nac = sqrt(T_AB_SLS/1900)  [Brandt Engn(s) D_nac; readme_geom §3]
        %     23770 -> sqrt(12.5105263158) = 3.5370222385 ft
        %     30000 -> sqrt(15.7894736842) = 3.9735970712 ft
        %   duct S_wet = pi*D*L_duct, L_duct = 14 ft  [Raymer Sec. 7.3]
        %     -> 155.5663631217 ft^2  and  174.7679271407 ft^2
        %   total S_wet (other four components unchanged at
        %     396.3766598778 + 104.0348823470 + 83.1398277675 + 749.1336817716
        %     = 1332.6850517639):
        %     -> 1488.2514148856 ft^2  and  1507.4529789046 ft^2
        %   With an aero object injected, CD0 = Cfe*S_wet/S_ref
        %   [Raymer 6th ed. Eq. 12.23] is linear in S_wet, so at Cfe = 0.0035
        %   [Raymer Table 12.3] and S_ref = 300:
        %     Delta(CD0) = 0.0035*(174.7679271407-155.5663631217)/300
        %                = 0.0035*19.2015640190/300 = 2.2401824689e-4
        % RelTol 1e-6 on that delta bounds round-off in the 11-significant-digit
        % hand arithmetic above and nothing looser.
            p = F16PropL2(f16a_spec_path(2));
            g = F16GeomL3(f16a_spec_path(3), p);
            a = F16AeroL2(g, f16a_spec_path(2), f16a_control_surfaces());   % L2 aero: CD0 = Cfe*S_wet/S_ref

            tc.verifyEqual(g.T_AB_SLS_lb, p.T_SL, 'AbsTol', 1e-12, ...
                'T_AB_SLS_lb must be the injected prop.T_SL, not a stored copy.');
            tc.verifyEqual(g.D_inlet, 3.5370222385,   'RelTol', 1e-9);
            tc.verifyEqual(g.D_exit,  g.D_inlet,      'AbsTol', 1e-12, ...
                'The nacelle is a constant-diameter cylinder: D_exit == D_inlet.');
            tc.verifyEqual(g.get_S_wet_duct(), 155.5663631217, 'RelTol', 1e-9);
            tc.verifyEqual(g.get_S_wet(),     1488.2514148856, 'RelTol', 1e-9);
            cd0_0 = a.drag_polar(AircraftState(0, 0.5)).CD0;

            p.T_SL = 30000;   % in-place engine mutation, no reconstruction

            tc.verifyEqual(g.T_AB_SLS_lb, 30000, 'AbsTol', 1e-12);
            tc.verifyEqual(g.D_inlet, 3.9735970712, 'RelTol', 1e-9, ...
                'D_inlet must track the mutated thrust: sqrt(30000/1900).');
            tc.verifyEqual(g.get_S_wet_duct(), 174.7679271407, 'RelTol', 1e-9, ...
                'Duct S_wet must track the mutated nacelle diameter.');
            tc.verifyEqual(g.get_S_wet(),     1507.4529789046, 'RelTol', 1e-9, ...
                'Total S_wet must track the mutated nacelle diameter.');
            cd0_1 = a.drag_polar(AircraftState(0, 0.5)).CD0;
            tc.verifyEqual(cd0_1 - cd0_0, 2.2401824689e-4, 'RelTol', 1e-6, ...
                ['CD0 must move by Cfe*Delta(S_wet_duct)/S_ref when engine thrust ' ...
                 'changes -- this whole chain was dead before Phase 2.']);
        end

        % ================================================================== %
        % Optimization-ready behaviour: live recompute + read-only
        % ================================================================== %

        function testDerivedLiveRecomputeOnMutation(tc)
        % A derived quantity must track a mutated input with NO reconstruction --
        % the exact behaviour the sizing loop / optimizer needs (no
        % frozen-at-construction stale value). Mutating AR_wing must move the
        % span by the definitional b = sqrt(AR*S), and everything downstream of
        % the wing planform with it.
            g   = TestGeomL3.makeGeom();
            sw0 = g.S_exposed_wing;
            b0  = g.b_wing;
            st0 = g.S_wet;
            g.AR_wing = g.AR_wing + 1;                % in-place mutation
            tc.verifyEqual(g.b_wing, sqrt(g.AR_wing*g.S_ref), 'AbsTol', 1e-12, ...
                'b_wing must recompute live from the mutated AR_wing.');
            tc.verifyGreaterThan(g.b_wing, b0, 'larger AR -> larger span, live.');
            tc.verifyNotEqual(g.S_exposed_wing, sw0, ...
                'S_exposed_wing must recompute after AR_wing mutation (Dependent, not frozen).');
            tc.verifyNotEqual(g.S_wet, st0, ...
                'total S_wet must recompute after AR_wing mutation.');
        end

        function testFormerlyFrozenPropertiesAreReadOnly(tc)
        % Derived (Dependent) quantities are OUTPUTS -- assigning to one must
        % error 'MATLAB:class:noSetMethod', so nothing can overwrite a computed
        % value with a frozen literal (the anti-pattern Phase 2 removes).
        % The FIVE quantities that were stored inputs before Phase 2 are checked
        % explicitly (F16GeomL3.md §3), plus T_AB_SLS_lb (which left
        % geometry entirely) and the new Amax. setfield is used because a
        % property assignment cannot appear inside an anonymous function.
            g = TestGeomL3.makeGeom();
            % --- the five INPUT -> DERIVED conversions
            tc.verifyError(@() setfield(g, 'AR_ht',        3.0),   'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_exposed_ht', 49.85), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_exposed_vt', 40.89), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'tc_ht',        0.04),  'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'tc_vt',        0.04),  'MATLAB:class:noSetMethod'); %#ok<SFLD>
            % --- engine data that left geometry, and the new Amax
            tc.verifyError(@() setfield(g, 'T_AB_SLS_lb', 23770),     'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'Amax',        25.110556), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            % --- the pre-existing derived set
            tc.verifyError(@() setfield(g, 'S_exposed_wing', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'D_fus',          999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'D_inlet',        999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'QC_sweep_vt',    999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_wet',         999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % ================================================================== %
        % Inheritance / interface compliance
        % ================================================================== %

        function testInheritance(tc)
            g = TestGeomL3.makeGeom();
            tc.verifyTrue(isa(g, 'GeometryBase'),      'must be a GeometryBase.');
            tc.verifyTrue(isa(g, 'GeometryModelL3'),   'must be a GeometryModelL3.');
            tc.verifyTrue(isa(g, 'handle'),            'must be a handle class.');
            tc.verifyFalse(isa(g, 'GeometryModelL2'),  'must NOT inherit GeometryModelL2.');
            tc.verifyFalse(isa(g, 'GeometryModelL1'),  'must NOT inherit GeometryModelL1.');
        end

        % ================================================================== %
        % DELIBERATELY-FAILING TODO (missing citation) -- EXPECTED RED
        % ================================================================== %

        function testTODO_OverallLengthCitationNotPinned(tc)
        %TESTTODO_OVERALLLENGTHCITATIONNOTPINNED  Deliberate, EXPECTED failure.
        %
        %   THIS TEST IS EXPECTED TO BE RED. It is not a regression; it is the
        %   labelled marker for a missing citation, following the same
        %   convention as TestAeroL3.testTODO_EWDCalibrationInput and
        %   TestAeroL2.testTODO_ClAlpha2DUnverified.
        %
        %   WHAT IS MISSING: `overall_length_ft = 47.65` (the L_aircraft input
        %   at BOTH L2 and L3, feeding ONLY the Raymer 6th ed. Eq. 12.44
        %   Sears-Haack wave-drag term as (Amax/l)^2). The VALUE is user-approved
        %   (2026-07-25) as the published F-16A airframe length 47 ft 7.75 in =
        %   47.6458 ft, of which 47.65 is a +0.009% rounding. The CITATION is
        %   NOT pinned: neither "47.65", "47 ft 7.75 in", nor any overall-length
        %   figure appears anywhere in air_vehicle_design/sizing/ (grepped
        %   2026-07-25). Brandt Geom!B21 = 48.303947 does NOT pin it -- that
        %   cell is a MAX() over his component x-station columns, i.e. an EXTENT
        %   of his own layout, not a published spec dimension, so it is a
        %   different quantity (-1.35%, annotated `definitional` in the
        %   comparison report). Both f16a_L2.json and f16a_L3.json therefore
        %   carry a `_TODO_overall_length_ft` marker key in their .geometry
        %   block, and this test fails while either marker is present.
        %
        %   HOW TO RESOLVE: pin the figure to T.O. 1F-16A-1 or another named
        %   primary source, record that citation in the `_overall_length_ft_src`
        %   field, delete the `_TODO_overall_length_ft` key from BOTH JSON files,
        %   and close VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §6. Do NOT make
        %   this test green by deleting the marker without the citation, and do
        %   NOT change the value.
        %
        %   (jsondecode renames a leading-underscore key to `x_...`.)
            G2 = TestGeomL3.readGeomJSON(2);
            G3 = TestGeomL3.readGeomJSON(3);
            tc.verifyFalse(isfield(G2, 'x_TODO_overall_length_ft'), ...
                ['TODO (EXPECTED RED): f16a_L2.json .geometry overall_length_ft ' ...
                 '= 47.65 has no in-repo citation.']);
            tc.verifyFalse(isfield(G3, 'x_TODO_overall_length_ft'), ...
                ['TODO (EXPECTED RED): f16a_L3.json .geometry overall_length_ft ' ...
                 '= 47.65 has no in-repo citation.']);
        end

    end
end
