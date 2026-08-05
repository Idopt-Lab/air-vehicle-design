classdef TestTailL2 < matlab.unittest.TestCase
%TESTTAILL2  Unit tests for the generic TailL2 static toolbox and its F-16
%   Tier-3 concrete class F16TailL2.
%
%   METHOD -- same governing identity as TailL1's Raymer 7th ed. Table 6.4
%   form, confirmed algebraically identical to Nicolai & Carichner Eq.
%   (11.1)/(11.2) [docs/reference_extracts/
%   11_tail_sizing.md Secs. 11.2-11.3, pp. 286, 289]:
%
%     C_VT = (l_VT*S_VT)/(b*S_ref)      ==>  S_VT = C_VT*b*S_ref/l_VT
%     C_HT = (l_HT*S_HT)/(cbar*S_ref)   ==>  S_HT = C_HT*cbar*S_ref/l_HT
%
%   COEFFICIENTS: Nicolai & Carichner Table 11.6, "General Dynamics F-16"
%   row, p.289: C_HT=0.3, C_VT=0.094 (EXPLICITLY NOT the conflicting
%   C_HT=0.68/C_VT=0.041 figure that mis-transcribes the same row in three
%   other reference-digest files -- scribe plan Sec. 5.1/7.1).
%
%   TAIL ARM: carries forward L1's rule unchanged, L_HT=L_VT=0.475*L_fus
%   [Raymer 7th ed. text] -- TailL2 calls TailL1.compute_tail_arm directly
%   rather than duplicating the formula.
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

        function testTailArmReusesTailL1Formula(tc)
        % TailL2 does NOT duplicate the tail-arm formula -- confirms the
        % cross-toolbox call target (TailL1.compute_tail_arm) still gives
        % 0.475*L_fus, hand-computed at L_fus=46.5: 0.475*46.5=22.0875.
            L = TailL1.compute_tail_arm(46.5);
            tc.verifyEqual(L, 22.0875, 'AbsTol', 1e-12);
        end

        % ================================================================ %
        % High-level TailL2.size(obj): obj.geom injected, read live
        % ================================================================ %

        function testSizeReadsGeomLiveAndMatchesHandComputedFormula(tc)
        % A plain struct with a nested struct `geom` suffices as `obj` --
        % TailL2.size only reads obj.C_HT/obj.C_VT/obj.geom.* via dot access.
        %   C_HT=0.3, C_VT=0.094, S_ref=250, b=28, cbar=9.5, L_fus=40
        %   L_HT=L_VT=0.475*40=19
        %   S_ht = 0.3*9.5*250/19  = 37.5 EXACTLY (see testComputeSHTFormula)
        %   S_vt = 0.094*28*250/19 = 34.631578947368421... (see testComputeSVTFormula)
            geom = struct('S_ref', 250, 'b_wing', 28, 'cbar_wing', 9.5, 'L_fus', 40);
            obj  = struct('C_HT', 0.3, 'C_VT', 0.094, 'geom', geom);
            result = TailL2.size(obj);
            fprintf('\n    TailL2.size: S_ht received=%.9f expected=37.500000000 | S_vt received=%.9f expected=34.631578947\n', ...
                result.S_ht, result.S_vt);
            tc.verifyEqual(result.S_ht, 37.5, 'AbsTol', 1e-9);
            tc.verifyEqual(result.S_vt, 34.631578947368421, 'RelTol', 1e-9);
        end

        function testResultFieldNamesAreLowercase(tc)
            geom = struct('S_ref', 300, 'b_wing', 30, 'cbar_wing', 11, 'L_fus', 46.5);
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
        % Feeds F16TailL2 with a REAL, injected F16GeomL2 object -- read
        % live via obj.geom.b_wing/cbar_wing/S_ref/L_fus inside TailL2.size.
        %
        % HAND-COMPUTED EXPECTED VALUES (same geometry fraction arithmetic
        % as TestTailL1's F-16 case: S_ref=300, b=30, cbar=2729080/241081=
        % 11.320178695... ft, L_fus=46.5 -> L_HT=L_VT=22.0875 exactly):
        %   S_ht = 0.3*11.320178695*300/22.0875 = 19649376000/425990127
        %        = 46.126364801... ft^2
        %   S_vt = 0.094*30*300/22.0875 = 22560/589 = 38.302207130... ft^2
        % (Cross-checked independently against the geometry-equations-
        % expert's reported ~46.12636/~38.30221 -- both derivations agree.)
            geom = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            obj    = F16TailL2(geom);
            result = obj.size();

            expected_S_ht = 46.126364801;
            expected_S_vt = 38.302207130;

            fprintf(['\n    F16TailL2.size (real injected F16GeomL2): ' ...
                     'S_ht received=%.6f expected=%.6f | S_vt received=%.6f expected=%.6f\n'], ...
                result.S_ht, expected_S_ht, result.S_vt, expected_S_vt);
            tc.verifyEqual(result.S_ht, expected_S_ht, 'RelTol', 1e-6, ...
                'F16TailL2 S_ht must match the hand-computed Nicolai/Carichner formula result.');
            tc.verifyEqual(result.S_vt, expected_S_vt, 'RelTol', 1e-6, ...
                'F16TailL2 S_vt must match the hand-computed Nicolai/Carichner formula result.');
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
