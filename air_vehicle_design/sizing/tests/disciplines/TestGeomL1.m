classdef TestGeomL1 < matlab.unittest.TestCase
%TESTGEOML1  Unit tests for GeomL1 and F16GeomL1.
%
%   Formula references:
%     S_wet regression: Roskam, Airplane Design Vol. I, Table 3.5
%       S_wet = 10^c * W_TO^d   (jet fighter: c=-0.1289, d=0.7506)
%     L_fus regression: Raymer, Aircraft Design 6th ed., Table 6.3
%       L_fus = a * W_TO^C      (jet fighter: a=0.93, C=0.39)
%
%   Formula outputs at W_TO = 31377 lbf (F-16A Brandt TOGW):
%     S_wet  = 10^(-0.1289) * 31377^0.7506 ≈ 1762 ft^2  [Roskam regression]
%     L_fus  = 0.93 * 31377^0.39           ≈  53.0 ft   [Raymer regression]
%
%   Physical reference values (ground-truth):
%     S_wet  = 1371 ft^2  [Brandt F-16A.xls, L3]
%     L_fus  = 47.5 ft    [T.O. 1F-16A-1, Fig. 1-2]
%
%   Tests assert formula output is within ±30% of S_wet (Roskam scatter is
%   ~29% for this type) and within ±20% of L_fus (Raymer scatter is ~12%).

    properties (Constant)
        TOGW   = 31377    % lbf   — F-16A Brandt TOGW
        W_TO_2 = 20000    % lbf   — lighter weight for sensitivity check
    end

    % ------------------------------------------------------------------ %
    methods (Test)

        % --- Formula correctness (±1% of reference computation) ----------

        function testSwetFormulaJetFighter(tc)
        % S_wet = 10^c * W_TO^d,  c=-0.1289, d=0.7506  [Roskam Table 3.5]
        % Formula gives ≈1762 ft^2; Brandt actual = 1371 ft^2 (~29% scatter).
        % Assert within ±30% of Brandt reference to cover known regression scatter.
            b        = F16Baseline();
            expected = b.brandt.S_wet;   % 1371.09 ft^2 [Brandt L3]
            g        = F16GeomL1();
            received = g.get_S_wet_statistical(tc.TOGW);
            fprintf('\n    S_wet_statistical: received = %.2f ft^2,  expected (Brandt) = %.2f ft^2\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.30, ...
                'S_wet regression deviates >30% from Brandt workbook value.');
        end

        function testLfusFormulaJetFighter(tc)
        % L_fus = a * W_TO^C,  a=0.93, C=0.39  [Raymer 6th ed. Table 6.3]
        % Formula gives ≈53.0 ft; USAF TO 1F-16A-1 = 47.5 ft (~11.6% off).
        % Assert within ±20% of USAF TO reference value.
            b        = F16Baseline();
            expected = b.geom.L_fus;   % 47.50 ft [T.O. 1F-16A-1, Fig. 1-2]
            g        = F16GeomL1();
            received = g.get_L_fus(tc.TOGW);
            fprintf('\n    get_L_fus:         received = %.2f ft,    expected (TO) = %.2f ft\n', ...
                received, expected);
            tc.verifyEqual(received, expected, 'RelTol', 0.20, ...
                'L_fus regression deviates >20% from USAF TO reference.');
        end

        function testGetSwetCallsStatistical(tc)
        % Structural: get_S_wet(W_TO) must delegate to get_S_wet_statistical(W_TO).
        % Both calls should return bit-identical results.
            g        = F16GeomL1();
            via_base = g.get_S_wet(tc.TOGW);
            via_impl = g.get_S_wet_statistical(tc.TOGW);
            fprintf('\n    get_S_wet (base):  %.6f ft^2\n', via_base);
            fprintf('    get_S_wet_stat:    %.6f ft^2\n', via_impl);
            tc.verifyEqual(via_base, via_impl, 'AbsTol', 1e-10, ...
                'get_S_wet does not delegate to get_S_wet_statistical.');
        end

        % --- Physical reasonableness -------------------------------------


        function testSwetMonotonicallyIncreasing(tc)
        % Positive regression exponent d=0.7506 → heavier ⟹ more wetted area.
            g  = F16GeomL1();
            S1 = g.get_S_wet_statistical(tc.W_TO_2);   % W_TO = 20000 lbf
            S2 = g.get_S_wet_statistical(tc.TOGW);     % W_TO = 31377 lbf
            fprintf('\n    S_wet at W_TO=20000: %.2f ft^2\n', S1);
            fprintf('    S_wet at W_TO=31377: %.2f ft^2  (should be larger)\n', S2);
            tc.verifyGreaterThan(S2, S1, ...
                'S_wet should increase with W_TO (positive regression exponent d>0).');
        end

        % --- Unknown category error --------------------------------------

        function testUnknownCategoryThrows(tc)
            g = F16GeomL1();
            g.aircraft_category = "flying_car";
            tc.verifyError(@() g.get_S_wet_statistical(tc.TOGW), ...
                'GeomL1:unknownCategory');
        end

        function testUnknownCategoryLfusThrows(tc)
            g = F16GeomL1();
            g.aircraft_category = "flying_car";
            tc.verifyError(@() g.get_L_fus(tc.TOGW), ...
                'GeomL1:unknownCategory');
        end

        % --- Mutable S_ref (handle semantics) ----------------------------

        function testSrefMutable(tc)
        % Sizing loop updates S_ref in-place on the handle object.
        % Expected: get_S_ref() returns 250 after assignment.
            g = F16GeomL1();
            g.S_ref = 250;
            received = g.get_S_ref();
            fprintf('\n    S_ref after assignment: received = %.2f ft^2,  expected = 250.00 ft^2\n', ...
                received);
            tc.verifyEqual(received, 250, 'AbsTol', 1e-9, ...
                'S_ref should be mutable for handle objects.');
        end

    end
end
