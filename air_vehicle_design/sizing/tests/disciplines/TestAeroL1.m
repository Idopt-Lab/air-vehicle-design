classdef TestAeroL1 < matlab.unittest.TestCase
%TESTAEROL1  Tier-1 unit/correctness tests for the AeroL1 toolbox + F16AeroL1.
%
%   L1 is a GEOMETRY-FREE Mattingly type-curve drag polar (Aero deep-dive
%   Phase C):
%     CD = CD0(M) + K1(M)*CL^2 + K2*CL         Mattingly AED 2nd ed. Eq. 2.9
%     CD0(M), K1(M)  interpolated from the fighter "Current" curve tables
%                    (f16a_L1.json .aerodynamics cd0_curve / k1_curve)
%     K2 = 0         uncambered fighter          Mattingly Sec. 2.3.1
%     CLmax = 0.90   fighter lookup              Roskam Vol. I Table 3.3
%
%   These are TRUE unit tests: every "expected" value is HAND-COMPUTED from the
%   cited formula/table with the arithmetic shown inline, never copied from a
%   code output or a Brandt figure. ALL Brandt / multi-source comparisons live
%   in the separate examples/F16A/aerodynamics_brandt_comparison.m report
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
        %READAEROJSON  Load an examples/F16A aero JSON by filename.
            this_dir    = fileparts(mfilename('fullpath'));
            sizing_root = fileparts(fileparts(this_dir));
            J = jsondecode(fileread(fullfile(sizing_root, 'examples', 'F16A', name)));
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
        % Mattingly polar assembly (interpolation + K2 rule) at F16AeroL1 level
        % ================================================================== %

        function testDragPolarInterpolatedAtMach1p05(tc)
            % Full F16AeroL1.drag_polar at M=1.05 exercises real interpolation
            % on the fighter "Current" curves. Breakpoints straddle 1.05:
            %   CD0: (0.9,0.016)->(1.2,0.028); K1: (0.9,0.18)->(1.2,0.20).
            %   frac = (1.05-0.9)/(1.2-0.9) = 0.15/0.30 = 0.5
            %   CD0 = 0.016 + 0.5*(0.028-0.016) = 0.016 + 0.006 = 0.022
            %   K1  = 0.18  + 0.5*(0.20 -0.18 ) = 0.18  + 0.010 = 0.190
            %   K2  = 0 (uncambered fighter, Mattingly Sec. 2.3.1)
            a     = F16AeroL1(f16a_spec_path(1));
            polar = a.drag_polar(AircraftState(0, 1.05));
            tc.verifyEqual(polar.CD0, 0.022, 'RelTol', 1e-4);
            tc.verifyEqual(polar.K1,  0.190, 'RelTol', 1e-4);
            tc.verifyEqual(polar.K2,  0.0,   'AbsTol', 1e-12);
        end

        function testDragPolarNoTransonicNaN(tc)
            % L1 has NO transonic guard (a tabulated figure has no Eq.12.51
            % pole) -- it must return finite values at M=1.0, unlike L2/L3.
            % Hand-computed at M=1.0:
            %   frac = (1.0-0.9)/(1.2-0.9) = 0.1/0.3 = 1/3
            %   CD0 = 0.016 + (1/3)*(0.028-0.016) = 0.016 + 0.004 = 0.020
            %   K1  = 0.18  + (1/3)*(0.20 -0.18 ) = 0.18 + 0.006667 = 0.1866667
            a     = F16AeroL1(f16a_spec_path(1));
            polar = a.drag_polar(AircraftState(0, 1.0));
            tc.verifyTrue(all(isfinite([polar.CD0, polar.K1, polar.K2])), ...
                'L1 drag polar must stay finite through the transonic band.');
            tc.verifyEqual(polar.CD0, 0.020,            'RelTol', 1e-4);
            tc.verifyEqual(polar.K1,  0.18 + 0.02/3,    'RelTol', 1e-4);
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

        % ================================================================== %
        % DELIBERATELY-FAILING TODO (missing/placeholder citation) -- see
        % header. Expected to be RED in run_all_tests until resolved.
        % ================================================================== %

        function testTODO_MattinglyCurvesArePlaceholder(tc)
            % The Mattingly Fig. 2.10 (CD0) / Fig. 2.11 (K1) fighter curves are
            % NOT in the repo -- f16a_L1.json's .aerodynamics cd0_curve/k1_curve
            % blocks are seeded from 5 AAF worked points and marked
            % "_placeholder": true. This FAILS on purpose until the real
            % digitized curves replace the placeholder (remove the
            % "_placeholder" flags to turn it green).
            A = TestAeroL1.readAeroJSON('f16a_L1.json').aerodynamics;
            isPlaceholder = (isfield(A.cd0_curve, 'x_placeholder') && A.cd0_curve.x_placeholder) || ...
                            (isfield(A.k1_curve,  'x_placeholder') && A.k1_curve.x_placeholder);
            tc.verifyFalse(isPlaceholder, ...
                ['TODO: Mattingly Fig. 2.10/2.11 fighter CD0(M)/K1(M) curves are ' ...
                 'PLACEHOLDER data (5 AAF worked points, not the digitized figures). ' ...
                 'Transcribe the real curves and clear "_placeholder".']);
        end

    end
end
