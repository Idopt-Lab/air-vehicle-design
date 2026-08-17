classdef TestAeroL1 < matlab.unittest.TestCase
%TESTAEROL1  Tier-1 unit/correctness tests for the AeroL1 toolbox + F16AeroL1.
%
%   L1's drag polar (Aero deep-dive Phase C, K1 changed to equation-based
%   2026-07-29 -- see F16AeroL1.m's class header for the full diagnostic):
%     CD = CD0(M) + K1(M)*CL^2 + K2*CL         Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9
%     CD0(M)         interpolated from the fighter "Current" curve table
%                    (f16a_L1.json .aerodynamics cd0_curve) -- still geometry-free
%     K1(M)          AeroL1.k1_from_geometry(AR, Lambda_LE_deg, M): real F-16
%                    wing AR=3.0/Lambda_LE_deg=40.0 (genuine spec scalars, NOT
%                    an injected geometry object) through AeroL2's own Raymer
%                    equations -- Eq. 12.48-12.50 subsonic (M<0.95), Eq. 12.51
%                    supersonic (M>=1.05), NaN in the transonic band between
%                    (AeroL2.flight_regime; matches L2/L3's convention -- a
%                    real behavior change from the old smooth Mattingly curve)
%     K2 = 0         uncambered fighter          Mattingly Sec. 2.3.1
%     CLmax = 1.50   fighter clean, ONE table    Roskam Vol. I Table 3.1
%                    (TO 1.70 / landing 2.10; the increments are Table 3.1
%                    differences, so the clean base is Table 3.1 too --
%                    2026-07-25. Table 3.3's 0.90 is still reachable through
%                    the standalone AeroL1.lookup_CLmax, tested below, but is
%                    no longer what get_CLmax returns. See AeroL1.md.)
%
%   These are TRUE unit tests: every "expected" value is HAND-COMPUTED from the
%   cited formula/table with the arithmetic shown inline, never copied from a
%   code output or a Brandt figure. ALL Brandt / multi-source comparisons live
%   in the separate examples/F16A/sanity_checks/aerodynamics_brandt_comparison.m report
%   (informational, not pass/fail), NOT here.
%
%   NOTE ON DELETED TESTS (do not re-add): the previous TestAeroL1 asserted
%   get_CD0()/get_e_osw()/get_K1() on L1 -- those geometry-dependent methods
%   MIGRATED to L2 (L1 no longer has them). Its testCD0Formula/testEoswFormula/
%   testDragPolarAtConstraintConditions were mislabeled loose Brandt
%   comparisons (RelTol 0.20 vs Brandt-model echoes) and are removed; the
%   comparison now happens only in the report script.
%
%   TODO tests (testTODO_*) are DELIBERATELY-FAILING placeholders flagging an
%   unverified citation still marked _TODO/_placeholder in the JSON. They are
%   the only expected run_all_tests failures for this file and auto-resolve
%   when the _TODO marker is removed.

    methods (Static, Access = private)
        function J = readAeroJSON(name)
        %READAEROJSON  Load an examples/F16A aero input JSON by filename.
            this_dir    = fileparts(mfilename('fullpath'));
            sizing_root = fileparts(fileparts(this_dir));
            J = jsondecode(fileread(fullfile(sizing_root, 'examples', 'F16A', 'inputs', name)));
        end
    end

    methods (Test)

        % ================================================================== %
        % Low-level: Mattingly curve interpolation (interp_curve)
        % ================================================================== %

        function testInterpCurveLinear(tc)
            % Linear interpolation of a value-vs-Mach curve at an interior
            % point. Independently chosen breakpoints (0,10)/(1,20)/(2,40),
            % query M=1.5 (between the last two):
            %   v = 20 + (1.5-1)/(2-1)*(40-20) = 20 + 0.5*20 = 30.
            received = AeroL1.interp_curve([0 1 2], [10 20 40], 1.5);
            tc.verifyEqual(received, 30.0, 'RelTol', 1e-4);
        end

        function testInterpCurveClampsBelowRange(tc)
            % M below the first breakpoint clamps to the endpoint value (no
            % extrapolation). Points (0.2,5)/(1.0,9), query M=0.0 -> 5.
            received = AeroL1.interp_curve([0.2 1.0], [5 9], 0.0);
            tc.verifyEqual(received, 5.0, 'RelTol', 1e-4);
        end

        function testInterpCurveClampsAboveRange(tc)
            % M above the last breakpoint clamps to the endpoint value.
            % Points (0,5)/(1,9), query M=2.0 -> 9.
            received = AeroL1.interp_curve([0 1], [5 9], 2.0);
            tc.verifyEqual(received, 9.0, 'RelTol', 1e-4);
        end

        % ================================================================== %
        % K1 from geometry (Raymer Eq. 12.48-12.50 subsonic / 12.51 supersonic)
        % -- AeroL1.k1_from_geometry, low-level: pure math, no object access.
        % Reuses the exact same AeroL2 primitives TestAeroL2 already
        % hand-derives (testOswaldEffEq1249Swept/testK1Subsonic/SupersonicFormula),
        % so the intermediate e_osw/K1 values here are the same numbers, not
        % re-derived independently.
        % ================================================================== %

        function testK1FromGeometrySubsonic(tc)
            % M=0.5 (< AeroL2.MACH_SUBSONIC_MAX=0.95) -> subsonic branch.
            % AR=3, Lambda_LE_deg=40 (real F-16 wing spec, matches
            % f16a_L2.json .geometry.wing) -> Eq. 12.49 (Lambda_LE>=30):
            %   e_osw = 4.61*(1-0.045*3^0.68)*cos(40)^0.15 - 3.1 = 0.9086192166
            %   (same hand-derivation as TestAeroL2.testOswaldEffEq1249Swept)
            %   K1 = 1/(pi*AR*e_osw) = 1/(pi*3*0.9086192166) = 0.1167742146
            received = AeroL1.k1_from_geometry(3, 40, 0.5);
            tc.verifyEqual(received, 0.1167742146, 'RelTol', 1e-6);
        end

        function testK1FromGeometrySupersonic(tc)
            % M=1.6 (>= AeroL2.MACH_SUPERSONIC_MIN=1.05) -> supersonic branch,
            % Eq. 12.51: K1 = AR*(M^2-1)*cos(Lambda_LE)/(4*AR*beta-2),
            % beta=sqrt(M^2-1). AR=3, Lambda_LE_deg=40, M=1.6:
            %   beta = sqrt(1.56) = 1.2489996
            %   num  = 3*1.56*cos(40) = 4.68*0.7660444 = 3.5850879
            %   den  = 4*3*1.2489996 - 2 = 14.987995 - 2 = 12.987995
            %   K1   = 3.5850879/12.987995 = 0.2760309
            received = AeroL1.k1_from_geometry(3, 40, 1.6);
            tc.verifyEqual(received, 0.2760308993, 'RelTol', 1e-6);
        end

        function testK1FromGeometryTransonicNaN(tc)
            % Between AeroL2.MACH_SUBSONIC_MAX=0.95 and MACH_SUPERSONIC_MIN=1.05
            % neither branch applies (Eq. 12.51 has a pole near M=1, same "not
            % modeled" convention as AeroL2.drag_polar -- see AeroL1.m/AeroL2.m
            % class headers). M=1.0 is the midpoint of that band.
            received = AeroL1.k1_from_geometry(3, 40, 1.0);
            tc.verifyTrue(isnan(received), ...
                'K1 must be NaN in the transonic band (Eq. 12.51 pole near M=1).');
        end

        % ================================================================== %
        % Full drag_polar assembly at F16AeroL1 level: CD0 curve-interpolated,
        % K1 equation-based (changed 2026-07-29), K2 from the Mattingly rule.
        % ================================================================== %

        function testDragPolarAtMach1p05(tc)
            % Full F16AeroL1.drag_polar at M=1.05: CD0 still interpolates the
            % Mattingly "Current" curve (breakpoints straddle 1.05); K1 is now
            % AeroL1.k1_from_geometry's SUPERSONIC branch (flight_regime(1.05)
            % = "supersonic", AeroL2.MACH_SUPERSONIC_MIN=1.05).
            %   CD0: (0.9,0.016)->(1.2,0.028), frac=(1.05-0.9)/0.3=0.5
            %        CD0 = 0.016 + 0.5*(0.028-0.016) = 0.022
            %   K1  = AeroL2.K1_supersonic(1.05, 3, 40) = 0.1278907226
            %        (beta=sqrt(1.05^2-1)=0.3201562, num=3*0.1025*cos(40)
            %        =0.2355587, den=4*3*0.3201562-2=1.8418744,
            %        K1=0.2355587/1.8418744=0.1278907)
            %   K2  = 0 (uncambered fighter, Mattingly Sec. 2.3.1)
            a     = F16AeroL1(f16a_spec_path(1));
            polar = a.drag_polar(AircraftState(0, 1.05));
            tc.verifyEqual(polar.CD0, 0.022,        'RelTol', 1e-4);
            tc.verifyEqual(polar.K1,  0.1278907226, 'RelTol', 1e-6);
            tc.verifyEqual(polar.K2,  0.0,           'AbsTol', 1e-12);
        end

        function testDragPolarK1TransonicNaNCD0StaysFinite(tc)
            % CHANGED BEHAVIOR (2026-07-29): unlike the old Mattingly K1
            % curve (a smooth table, no pole), the new equation-based K1 has
            % a real transonic gap (Eq. 12.51 pole near M=1, same as L2/L3 --
            % see AeroL1.k1_from_geometry). At M=1.0, K1 is now NaN. CD0 is
            % UNAFFECTED -- it still interpolates the Mattingly curve, which
            % has no such gap, so drag_polar's CD0 stays finite even while K1
            % does not. (Superseded testDragPolarNoTransonicNaN, which
            % asserted the opposite of the new K1 behavior; do not re-add it.)
            %   CD0: frac=(1.0-0.9)/0.3=1/3, CD0=0.016+(1/3)*0.012=0.020
            %   K1 = NaN (transonic band)
            a     = F16AeroL1(f16a_spec_path(1));
            polar = a.drag_polar(AircraftState(0, 1.0));
            tc.verifyEqual(polar.CD0, 0.020, 'RelTol', 1e-4);
            tc.verifyTrue(isnan(polar.K1), 'K1 must be NaN in the transonic band.');
            tc.verifyEqual(polar.K2, 0.0, 'AbsTol', 1e-12);
        end

        function testMattinglyK2ZeroForUncambered(tc)
            % K2 = 0 for the uncambered fighter type (Mattingly Sec. 2.3.1).
            tc.verifyEqual(AeroL1.mattingly_K2("uncambered"), 0, 'AbsTol', 1e-12);
        end

        function testMattinglyK2UnsupportedTypeThrows(tc)
            % Cambered/cargo K2 curves are not fitted (TODO); the toolbox must
            % error loudly rather than silently return 0.
            tc.verifyError(@() AeroL1.mattingly_K2("cambered"), ...
                'AeroL1:unsupportedDesignType');
        end

        % ================================================================== %
        % CLmax (Roskam Vol. I Table 3.1 fighter row) + unknown-type errors
        %
        % TABLE 3.1 THROUGHOUT (2026-07-25). get_CLmax used to return Table
        % 3.3's 0.90 while get_Delta_CLmax_TO/L were Table 3.1 differences off a
        % 1.50 clean base, so the totals matched neither table. The clean value
        % and the increments now come from one table -- and
        % testCLmaxTotalsMatchTable31Means below locks that invariant, which is
        % what the two old single-sided tests could not catch between them.
        % ================================================================== %

        function testCLmaxFighterCleanFromTable31(tc)
            % Roskam Vol. I Table 3.1, fighter row, clean column [1.2 1.8]:
            % mean = 1.50.  Hand-computed: (1.2 + 1.8)/2 = 1.50.
            a = F16AeroL1(f16a_spec_path(1));
            tc.verifyEqual(a.get_CLmax([]), 1.50, 'AbsTol', 1e-12, ...
                'L1 clean CLmax must be the Roskam Table 3.1 fighter-row mean.');
        end

        function testCLmaxTotalsMatchTable31Means(tc)
            % THE INVARIANT: because the increments are differences WITHIN Table
            % 3.1, clean + Delta must reproduce that table's own TO/landing
            % means exactly. Hand-computed from the fighter row:
            %   clean [1.2 1.8] -> 1.50 ;  TO [1.4 2.0] -> 1.70 ;  L [1.6 2.6] -> 2.10
            %   CLmax_TO = 1.50 + (1.70-1.50) = 1.70
            %   CLmax_L  = 1.50 + (2.10-1.50) = 2.10
            % Before the fix these were 1.10 and 1.50 -- a 0.60 offset carried
            % straight from a mismatched Table 3.3 clean base.
            a = F16AeroL1(f16a_spec_path(1));
            tc.verifyEqual(a.get_CLmax_TO(), 1.70, 'AbsTol', 1e-12, ...
                'CLmax_TO must equal the Roskam Table 3.1 fighter takeoff mean.');
            tc.verifyEqual(a.get_CLmax_L(), 2.10, 'AbsTol', 1e-12, ...
                'CLmax_L must equal the Roskam Table 3.1 fighter landing mean.');
        end

        function testLookupCLmaxTable33StillAvailable(tc)
            % AeroL1.lookup_CLmax (Roskam Table 3.3) is retained as a standalone
            % utility -- 0.90 for a fighter -- but is deliberately NOT the
            % get_CLmax path any more. Both spellings resolve.
            tc.verifyEqual(AeroL1.lookup_CLmax("fighter"), 0.90, 'AbsTol', 1e-12);
            tc.verifyEqual(AeroL1.lookup_CLmax("jet_fighter"), 0.90, 'AbsTol', 1e-12);
        end

        function testLookupCLmaxUnknownTypeThrows(tc)
            % Unknown aircraft_type must throw (guard against silent defaults).
            tc.verifyError(@() AeroL1.lookup_CLmax("dirigible"), ...
                'AeroL1:unknownCategory');
        end

        function testCanonicalCategoryResolvesToTheTablesOwnRowName(tc)
            % PHASE 3 (2026-07-25). Roskam's CLmax table prints its fighter row
            % as "fighter", while every other table in the framework (Roskam
            % 3.5, Raymer 6.3 / 4.1 / 3.1) names the same class "jet_fighter".
            % The JSON now carries ONE canonical aircraft_category, so this
            % lookup must accept it -- previously "jet_fighter" brace-indexed an
            % empty row and threw.
            %
            % Renaming the table row to "jet_fighter" was rejected: the row name
            % is the category name the textbook prints, and renaming it would
            % break source traceability. The canonical value is translated at the
            % table boundary instead, so one input key serves every table while
            % each table stays faithful to its source.
            tc.verifyEqual(AeroL1.to_CLmax_table_row("jet_fighter"), "fighter", ...
                'The canonical category must map to Roskam Table 3.1''s own row name.');
            % Both spellings must reach the same row and the same value.
            tc.verifyEqual(AeroL1.roskam_CLmax_value("jet_fighter", "CL_max_TO"), ...
                            AeroL1.roskam_CLmax_value("fighter", "CL_max_TO"), ...
                'AbsTol', 1e-12);
            tc.verifyEqual(AeroL1.roskam_CLmax_value("jet_fighter", "CL_max_TO"), 1.70, ...
                'AbsTol', 1e-12, 'Table 3.1 fighter takeoff mean.');
        end

        function testRoskamCLmaxValueUnknownCategoryThrows(tc)
            % A genuinely unknown category must still raise an identified error
            % naming the known rows -- the translation layer passes unrecognised
            % values straight through rather than guessing a row.
            tc.verifyError(@() AeroL1.roskam_CLmax_value("dirigible", "CL_max_TO"), ...
                'AeroL1:unknownAircraftType');
        end

        % ================================================================== %
        % High-lift-device / gear deltas (Roskam Vol. I Tables 3.1 / 3.6).
        % Expected values are hand-computed means of the published table
        % ranges (the tables are the independent source).
        % ================================================================== %

        function testDeltaCLmaxFromRoskamTable(tc)
            % Roskam Table 3.1 fighter row means:
            %   clean = mean([1.2 1.8]) = 1.5
            %   TO    = mean([1.4 2.0]) = 1.7  -> Delta_TO = 1.7 - 1.5 = 0.2
            %   L     = mean([1.6 2.6]) = 2.1  -> Delta_L  = 2.1 - 1.5 = 0.6
            a = F16AeroL1(f16a_spec_path(1));
            tc.verifyEqual(a.get_Delta_CLmax_TO(), 0.2, 'RelTol', 1e-4);
            tc.verifyEqual(a.get_Delta_CLmax_L(),  0.6, 'RelTol', 1e-4);
        end

        function testDeltaEoswFromRoskamTable(tc)
            % Roskam Table 3.6 e-column means (clean 0.825, TO 0.775, L 0.725):
            %   Delta_e_TO = 0.775 - 0.825 = -0.05
            %   Delta_e_L  = 0.725 - 0.825 = -0.10  (flaps degrade span eff.)
            a = F16AeroL1(f16a_spec_path(1));
            tc.verifyEqual(a.get_Delta_e_osw_TO(), -0.05, 'RelTol', 1e-4);
            tc.verifyEqual(a.get_Delta_e_osw_L(),  -0.10, 'RelTol', 1e-4);
        end

        function testDeltaCD0FromRoskamTable(tc)
            % Roskam Table 3.6 Delta_CD0 means + gear (mean([0.015 0.025])=0.020):
            %   TO = mean([0.010 0.020]) + 0.020 = 0.015 + 0.020 = 0.035
            %   L  = mean([0.055 0.075]) + 0.020 = 0.065 + 0.020 = 0.085
            a = F16AeroL1(f16a_spec_path(1));
            tc.verifyEqual(a.get_Delta_CD0_TO(), 0.035, 'RelTol', 1e-4);
            tc.verifyEqual(a.get_Delta_CD0_L(),  0.085, 'RelTol', 1e-4);
        end

        % ================================================================== %
        % drag_polar struct contract + inheritance / interface compliance
        % ================================================================== %

        function testDragPolarReturnsStruct(tc)
            a     = F16AeroL1(f16a_spec_path(1));
            polar = a.drag_polar(AircraftState(0, 0.5));
            tc.verifyTrue(isstruct(polar));
            tc.verifyTrue(all(isfield(polar, {'CD0', 'K1', 'K2'})));
        end

        function testIsaAerodynamicsBase(tc)
            tc.verifyTrue(isa(F16AeroL1(f16a_spec_path(1)), 'AerodynamicsBase'));
        end

        function testIsaAeroModelL1(tc)
            tc.verifyTrue(isa(F16AeroL1(f16a_spec_path(1)), 'AeroModelL1'));
        end

        function testNotIsaToolboxAeroL1(tc)
            % Student class inherits the abstract enforcer, NOT the toolbox.
            tc.verifyFalse(isa(F16AeroL1(f16a_spec_path(1)), 'AeroL1'));
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(F16AeroL1(f16a_spec_path(1)), 'handle'));
        end

        % TODO (8/13/2026): This should'bve been removed a long time ago,
        % since I thought we were ditching the Mattingly K1 tabulation.
        % ================================================================== %
        % DELIBERATELY-FAILING TODO (missing/placeholder citation) -- see
        % header. Expected to be RED in run_all_tests until resolved.
        % ================================================================== %

        function testTODO_MattinglyCurvesArePlaceholder(tc)
            % The Mattingly Fig. 2.10 CD0 fighter curve is NOT in the repo --
            % f16a_L1.json's .aerodynamics cd0_curve block is seeded from 5
            % AAF worked points and marked "_placeholder": true. This FAILS
            % on purpose until the real digitized curve replaces the
            % placeholder (remove the "_placeholder" flag to turn it green).
            % NOTE (2026-07-29): this was previously CD0(M)/K1(M) -- K1 no
            % longer comes from a curve (see AeroL1.k1_from_geometry / class
            % header), so it is no longer a placeholder and is dropped here.
            A = TestAeroL1.readAeroJSON('f16a_L1.json').aerodynamics;
            isPlaceholder = isfield(A.cd0_curve, 'x_placeholder') && A.cd0_curve.x_placeholder;
            tc.verifyFalse(isPlaceholder, ...
                ['TODO: Mattingly Fig. 2.10 fighter CD0(M) curve is PLACEHOLDER ' ...
                 'data (5 AAF worked points, not the digitized figure). ' ...
                 'Transcribe the real curve and clear "_placeholder".']);
        end

    end
end
