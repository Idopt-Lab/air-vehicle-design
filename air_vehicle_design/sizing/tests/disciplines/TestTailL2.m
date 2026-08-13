classdef TestTailL2 < matlab.unittest.TestCase
%TESTTAILL2  Unit tests for the generic TailL2 static toolbox and its F-16
%   Tier-3 concrete class F16TailL2.
%
%   METHOD -- same governing identity as TailL1's Raymer 7th ed. Table 6.4
%   form, confirmed algebraically identical to Nicolai & Carichner Eq.
%   (11.1)/(11.2) [temp_AI/docs/disciplines/reference_extracts/
%   11_tail_sizing.md Secs. 11.2-11.3, pp. 286, 289]:
%
%     C_VT = (l_VT*S_VT)/(b*S_ref)      ==>  S_VT = C_VT*b*S_ref/l_VT
%     C_HT = (l_HT*S_HT)/(cbar*S_ref)   ==>  S_HT = C_HT*cbar*S_ref/l_HT
%
%   COEFFICIENTS: Nicolai & Carichner Table 11.6, "General Dynamics F-16"
%   row, p.289: C_HT=0.3, C_VT=0.094 (EXPLICITLY NOT the conflicting
%   C_HT=0.68/C_VT=0.041 figure that mis-transcribes the same row in three
%   other temp_AI digest files -- scribe plan Sec. 5.1/7.1).
%
%   TAIL ARM (CHANGED 2026-08-11): NICOLAI'S OWN c.g.-REFERENCED ARM, not
%   L1's 0.475*L_fus fuselage fraction. Eqs. (11.1)/(11.2) define l_VT/l_HT as
%   the "distance from initial c.g. estimate to quarter-chord of the [tail]
%   mac" (Fig. 11.1, p.285), and Sec. 11.1, p.284, points that initial c.g.
%   estimate at Nicolai Ch. 8, p.212 -- "Locate the wing so the c.g. is at
%   ~30% of the wing mean aerodynamic chord". So:
%       x_cg,init = x_MAC_LE,wing + 0.30*cbar_wing
%       l_HT      = x_c/4,HT - x_cg,init ;  l_VT = x_c/4,VT - x_cg,init
%   A Nicolai Table 11.6 coefficient must be used with a Nicolai arm; using
%   Raymer's fuselage fraction there applied the coefficient against a
%   reference it was never tabulated on, and for the F-16A it overstated the
%   arm by ~46 %. TailL2 therefore calls its OWN compute_x_cg_initial /
%   compute_tail_arm_cg, no longer TailL1.compute_tail_arm.
%
%   GEOMETRY INJECTION CONVENTION: this repo's established pattern for L2
%   discipline-injects-geometry tests (TestWeightsL2.makeW2/makeProp) is to
%   build a REAL F16GeomL2(f16a_spec_path(2), prop) object from the actual
%   JSON spec, not a hand-rolled mock -- reused here rather than inventing a
%   new stub convention.
%
%   NOT SELF-REFERENTIAL: every "expected" value is hand-derived by fraction
%   arithmetic from Nicolai's stated coefficients and GeometryBase's OWN
%   independent chord/span formulas, never read back from TailL2's output.

    methods (Test)

        % ================================================================ %
        % Low-level statics: S_HT/S_VT formula correctness (arbitrary scalars)
        % ================================================================ %

        function testComputeSHTFormula(tc)
        % Arbitrary invented scalars (not F-16 data): C_HT=0.3, cbar=9.5,
        % S_ref=250, L_HT=19. Hand-computed: 0.3*9.5*250/19 = 712.5/19
        %   19*37=703, remainder 9.5, 9.5/19=0.5 exactly -> 37.5 EXACTLY.
            val = TailL2.compute_S_HT(0.3, 9.5, 250, 19);
            tc.verifyEqual(val, 37.5, 'AbsTol', 1e-9);
        end

        function testComputeSVTFormula(tc)
        % Arbitrary invented scalars: C_VT=0.094, b=28, S_ref=250, L_VT=19.
        % Hand-computed: 0.094*28*250/19 = 658/19 = 34.631578947368421...
        %   (19*34=646, remainder 12, 12/19=0.631578947368421... repeating).
            val = TailL2.compute_S_VT(0.094, 28, 250, 19);
            tc.verifyEqual(val, 34.631578947368421, 'RelTol', 1e-12);
        end

        function testComputeSHTRejectsNonPositiveDenominator(tc)
            tc.verifyError(@() TailL2.compute_S_HT(0.3, 9, 250, 0), 'MATLAB:validators:mustBePositive');
        end

        function testComputeSVTRejectsNonPositiveDenominator(tc)
            tc.verifyError(@() TailL2.compute_S_VT(0.094, 28, 250, 0), 'MATLAB:validators:mustBePositive');
        end

        % ---------------------------------------------------------------- %
        % The c.g.-referenced arm (REPLACED testTailArmReusesTailL1Formula,
        % 2026-08-11 -- TailL2 no longer calls TailL1.compute_tail_arm).
        % ---------------------------------------------------------------- %

        function testInitialCgIsThirtyPercentMac(tc)
        % [Nicolai & Carichner Ch. 8, p.212: "Locate the wing so the c.g. is
        % at ~30% of the wing mean aerodynamic chord"; Sec. 11.1, p.284, is
        % what points Eqs. (11.1)/(11.2) at this estimate]
        %   x_cg,init = x_MAC_LE,wing + 0.30*cbar_wing
        % Arbitrary invented scalars: x_MAC_LE=20, cbar=9.5 ->
        %   20 + 0.30*9.5 = 20 + 2.85 = 22.85 ft EXACTLY.
            x_cg = TailL2.compute_x_cg_initial(20, 9.5);
            tc.verifyEqual(x_cg, 22.85, 'AbsTol', 1e-12, ...
                'x_cg,init must be x_MAC_LE,wing + 0.30*cbar_wing.');
        end

        function testInitialCgIsNotRaymersQuarterMacReference(tc)
        % Nicolai's 0.30 and Raymer's 0.25 are DIFFERENT references, and the
        % coefficient tables are tabulated against their own one. This asserts
        % the 0.30 explicitly, so the two cannot be quietly unified.
        % Hand-computed at cbar=9.5: 0.30*9.5=2.85 aft of the mac LE, whereas
        % a 0.25 reference would put it 0.25*9.5=2.375 aft, 0.475 ft further
        % forward.
            tc.verifyEqual(TailL2.compute_x_cg_initial(0, 9.5), 2.85, 'AbsTol', 1e-12);
            tc.verifyNotEqual(TailL2.compute_x_cg_initial(0, 9.5), 2.375, ...
                'The Nicolai reference is 0.30*cbar, NOT Raymer''s 0.25*cbar.');
        end

        function testTailArmCgIsAStationDifference(tc)
        % [Nicolai & Carichner Eq. (11.1) p.286 / Eq. (11.2) p.289;
        % Fig. 11.1, p.285]  l = x_c/4,tail - x_cg,init -- a subtraction, so
        % arbitrary invented stations test it honestly.
        % Hand-computed: 41.85 - 22.85 = 19.00 ft EXACTLY.
            L = TailL2.compute_tail_arm_cg(41.85, 22.85);
            tc.verifyEqual(L, 19.00, 'AbsTol', 1e-12);
        end

        function testTailArmCgRejectsForwardSurface(tc)
        % A surface forward of the initial c.g. is a canard, which is
        % Nicolai's Eq. (11.3), a different method. Eqs. (11.1)/(11.2) divide
        % by the arm, so a non-positive arm must error.
            tc.verifyError(@() TailL2.compute_tail_arm_cg(20.0, 22.85), ...
                'TailL2:nonPositiveTailArm');
            tc.verifyError(@() TailL2.compute_tail_arm_cg(22.85, 22.85), ...
                'TailL2:nonPositiveTailArm', ...
                'A ZERO arm must error too -- Eqs. (11.1)/(11.2) divide by it.');
        end

        function testNicolaiArmIsNotTheFuselageFraction(tc)
        % THE REGRESSION GUARD (2026-08-11). TailL2 used to size the F-16A
        % against 0.475*L_fus = 22.0875 ft. Hand-computed from the stations
        % (derivation in testF16TailL2SizeAgainstF16GeomL2WingGeometry) the
        % real Nicolai arm is 14.5267431130 ft for the HT -- the fraction is
        % +52.0 % on it. Asserting they disagree stops the fraction returning.
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            x_cg = TailL2.compute_x_cg_initial(geom.x_mac_le_wing, geom.cbar_wing);
            l_HT = TailL2.compute_tail_arm_cg(geom.x_c4_ht, x_cg);
            tc.verifyEqual(TailL1.compute_tail_arm(46.5), 22.0875, 'AbsTol', 1e-12, ...
                'The pre-layout fraction itself is unchanged: 0.475*46.5.');
            tc.verifyGreaterThan(abs(22.0875 - l_HT) / l_HT, 0.40, ...
                ['0.475*L_fus must NOT stand in for Nicolai''s c.g.-referenced ' ...
                 'arm: it overstates it by >40 % for the F-16A.']);
        end

        % ================================================================ %
        % High-level TailL2.size(obj): obj.geom injected, read live
        % ================================================================ %

        function testSizeReadsGeomLiveAndMatchesHandComputedFormula(tc)
        % A plain struct with a nested struct `geom` suffices as `obj` --
        % TailL2.size only reads obj.C_HT/obj.C_VT/obj.geom.* via dot access.
        %
        % GEOM FIELDS CHANGED 2026-08-11: size() now reads x_mac_le_wing,
        % x_c4_ht and x_c4_vt and no longer reads L_fus at all, because the
        % arm is a real station-to-station distance.
        %
        % HAND-COMPUTED, all invented scalars chosen to make the arithmetic
        % exact (they are NOT F-16 data):
        %   C_HT=0.3, C_VT=0.094, S_ref=250, b=28, cbar=9.5
        %   x_MAC_LE,wing = 20   -> x_cg,init = 20 + 0.30*9.5 = 22.85
        %   x_c/4,HT = 41.85     -> l_HT = 41.85 - 22.85 = 19 EXACTLY
        %   x_c/4,VT = 42.85     -> l_VT = 42.85 - 22.85 = 20 EXACTLY
        %   S_ht = 0.3*9.5*250/19  = 712.5/19 = 37.5 EXACTLY (19*37=703,
        %          remainder 9.5, 9.5/19 = 0.5)
        %   S_vt = 0.094*28*250/20 = 658/20   = 32.9 EXACTLY
        % The two arms are deliberately UNEQUAL: if l_HT were used for both,
        % S_vt would come out 658/19 = 34.6316, and if l_VT were used for
        % both, S_ht would come out 712.5/20 = 35.625.
            geom = struct('S_ref', 250, 'b_wing', 28, 'cbar_wing', 9.5, ...
                          'x_mac_le_wing', 20, 'x_c4_ht', 41.85, 'x_c4_vt', 42.85);
            obj  = struct('C_HT', 0.3, 'C_VT', 0.094, 'geom', geom);
            result = TailL2.size(obj);
            fprintf('\n    TailL2.size: S_ht received=%.9f expected=37.500000000 | S_vt received=%.9f expected=32.900000000\n', ...
                result.S_ht, result.S_vt);
            tc.verifyEqual(result.S_ht, 37.5, 'AbsTol', 1e-9, ...
                'S_ht must equal C_HT*cbar*S_ref/l_HT with l_HT = x_c/4,HT - x_cg,init.');
            tc.verifyEqual(result.S_vt, 32.9, 'AbsTol', 1e-9, ...
                'S_vt must equal C_VT*b*S_ref/l_VT with l_VT = x_c/4,VT - x_cg,init.');
        end

        function testResultFieldNamesAreLowercase(tc)
            geom = struct('S_ref', 300, 'b_wing', 30, 'cbar_wing', 11, ...
                          'x_mac_le_wing', 22, 'x_c4_ht', 40, 'x_c4_vt', 41);
            obj  = struct('C_HT', 0.3, 'C_VT', 0.094, 'geom', geom);
            result = TailL2.size(obj);
            tc.verifyTrue(isfield(result, 'S_ht'));
            tc.verifyTrue(isfield(result, 'S_vt'));
        end

        % ================================================================ %
        % F16TailL2 (Tier-3 concrete class), injected real F16GeomL2
        % ================================================================ %

        function testF16TailL2IsaTailSizingBase(tc)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyTrue(isa(F16TailL2(geom), 'TailSizingBase'));
        end

        function testF16TailL2IsaTailSizingModelL2(tc)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            tc.verifyTrue(isa(F16TailL2(geom), 'TailSizingModelL2'));
        end

        function testConstructorRequiresGeom(tc)
        % No silent default -- a defaulted injection would silently re-freeze
        % wing geometry (matches F16WeightsL2's precedent).
            tc.verifyError(@() F16TailL2(), 'MATLAB:minrhs');
        end

        function testConstructorRejectsWrongGeomTier(tc)
        % geom is typed (1,1) GeometryModelL2 -- an L1 geometry object (which
        % has no b_wing/cbar_wing/S_ref/L_fus at all) must be rejected at
        % construction, not fail later with an unhelpful "no such property".
            g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyError(@() F16TailL2(g1), 'MATLAB:validation:UnableToConvert');
        end

        function testF16TailL2NicolaiCoefficients(tc)
        % [Nicolai & Carichner Table 11.6, "General Dynamics F-16" row, p.289]
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj = F16TailL2(geom);
            tc.verifyEqual(obj.C_HT, 0.3, 'AbsTol', 0);
            tc.verifyEqual(obj.C_VT, 0.094, 'AbsTol', 0);
        end

        function testF16TailL2SizeAgainstF16GeomL2WingGeometry(tc)
        % Feeds F16TailL2 with a REAL, injected F16GeomL2 object -- read live
        % via obj.geom.S_ref/b_wing/cbar_wing/x_mac_le_wing/x_c4_ht/x_c4_vt
        % inside TailL2.size.
        %
        % EXPECTED VALUES RECOMPUTED 2026-08-11 for the corrected arm. They
        % were 46.126364801 / 38.302207130, computed against
        % l_HT = l_VT = 0.475*L_fus = 22.0875 ft -- a Raymer fuselage-length
        % rule of thumb standing in for a quantity Nicolai defines from the
        % initial c.g. station. S_HT goes as 1/l_HT, so the areas rise.
        %
        % HAND-COMPUTED EXPECTED VALUES -- decimal arithmetic done in this
        % comment block from the JSON inputs, NOT read from the code under
        % test. The wing/HT/VT MAC-station chain is derived line by line in
        % TestTailL1.testF16TailL1SizeAgainstF16GeomL2WingGeometry and is
        % reproduced here only at its results:
        %   cbar_wing     = 2729080/241081 = 11.3201786951 ft
        %   x_MAC_LE,wing =                  22.7590752071 ft
        %   x_c/4,HT      =                  40.6818719286 ft
        %   x_c/4,VT      =                  41.2416161335 ft
        % Nicolai's arm [Eqs. (11.1)/(11.2) + Ch. 8 p.212 initial c.g.]:
        %   x_cg,init = 22.7590752071 + 0.30*11.3201786951
        %             = 22.7590752071 +  3.3960536085 = 26.1551288156 ft
        %   l_HT      = 40.6818719286 - 26.1551288156 = 14.5267431130 ft
        %   l_VT      = 41.2416161335 - 26.1551288156 = 15.0864873179 ft
        % Areas [Table 11.6 F-16 row: C_HT=0.3, C_VT=0.094]:
        %   S_ht = 0.3*11.3201786951*300/14.5267431130
        %        = 1018.816082559/14.5267431130 = 70.133826600 ft^2
        %   S_vt = 0.094*30*300/15.0864873179
        %        =  846/15.0864873179           = 56.076671938 ft^2
        %
        % TOLERANCE. Same rationale as the L1 file: the arithmetic is carried
        % to 11-12 significant figures through one tangent evaluation and a
        % handful of products, truncating at ~1e-10 relative, and RelTol 1e-7
        % is three decades of margin over that. Not fitted to the output.
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj    = F16TailL2(geom);
            result = obj.size();

            expected_S_ht = 70.133826600;
            expected_S_vt = 56.076671938;

            fprintf(['\n    F16TailL2.size (real injected F16GeomL2): ' ...
                     'S_ht received=%.6f expected=%.6f | S_vt received=%.6f expected=%.6f\n'], ...
                result.S_ht, expected_S_ht, result.S_vt, expected_S_vt);
            tc.verifyEqual(result.S_ht, expected_S_ht, 'RelTol', 1e-7, ...
                'F16TailL2 S_ht must match the hand-computed Nicolai/Carichner formula result.');
            tc.verifyEqual(result.S_vt, expected_S_vt, 'RelTol', 1e-7, ...
                'F16TailL2 S_vt must match the hand-computed Nicolai/Carichner formula result.');
            % The retired values, asserted against so the fuselage-fraction
            % arm cannot come back unnoticed.
            tc.verifyGreaterThan(abs(result.S_ht - 46.126364801) / 46.126364801, 0.30, ...
                'S_ht must NOT be the 0.475*L_fus-arm value 46.1264 ft^2 any more.');
            tc.verifyGreaterThan(abs(result.S_vt - 38.302207130) / 38.302207130, 0.30, ...
                'S_vt must NOT be the 0.475*L_fus-arm value 38.3022 ft^2 any more.');
        end

        function testF16TailL2SizeTracksGeometryMutationLive(tc)
        % LIVE-RECOMPUTE GUARD (parallels TestGeomL2.testWettedAreasLiveOnRead
        % for the optimization-ready property design): F16TailL2 stores no
        % cached copy of geometry -- mutating the injected geom object's
        % AR_wing in place must change the NEXT size() call's S_ht/S_vt with
        % NO reconstruction of F16TailL2 itself.
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj  = F16TailL2(geom);
            r0   = obj.size();
            geom.AR_wing = geom.AR_wing + 1;   % optimizer-style in-place mutation
            r1   = obj.size();
            fprintf('\n    Before mutation: S_ht=%.6f S_vt=%.6f | After AR_wing+1: S_ht=%.6f S_vt=%.6f\n', ...
                r0.S_ht, r0.S_vt, r1.S_ht, r1.S_vt);
            tc.verifyNotEqual(r1.S_ht, r0.S_ht, ...
                'S_ht must change after mutating the injected geom''s AR_wing -- no cached copy allowed.');
            tc.verifyNotEqual(r1.S_vt, r0.S_vt, ...
                'S_vt must change after mutating the injected geom''s AR_wing -- no cached copy allowed.');
        end

        function testF16TailL2AreasArePositive(tc)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            result = F16TailL2(geom).size();
            tc.verifyGreaterThan(result.S_ht, 0);
            tc.verifyGreaterThan(result.S_vt, 0);
        end

    end

end
