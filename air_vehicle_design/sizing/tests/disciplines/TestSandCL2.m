classdef TestSandCL2 < matlab.unittest.TestCase
%TESTSANDCL2  Unit tests for SandCL2 (the weighted-CG static toolbox) and
%   F16SandCL2 (the F-16 CG-only concrete class).
%
%   TIER 1 (unit/correctness) per CLAUDE.md's two-tier-tests-never-blended
%   convention -- part of run_all_tests, must be green. No deliberate TODO
%   test in this file: F16SandCL2's ONE quantity (x_cg) has no citation gap
%   (docs/subplans/10_stability_control.md "DECIDED: F16SandCL2 is limited
%   to the CG term only").
%
%   SCOPE: F16SandCL2 computes ONLY x_cg = Sum(W_i*x_i)/Sum(W_i) over the 10
%   WeightsL2-matched component groups -- see F16SandCL2.m's own header.
%   Every test below either (a) exercises SandCL2.weighted_cg directly with
%   synthetic arrays (pure-math, no DI), or (b) constructs a REAL F16WeightsL2
%   object (per CLAUDE.md's "never self-referential" rule, the expected value
%   in the integration test is independently re-derived by re-reading the
%   SAME public weight getters F16SandCL2 itself reads and re-transcribing
%   the JSON's own cg_x_ft stations -- NOT by calling SandCL2.weighted_cg or
%   F16SandCL2's private component_weights/group_weight helpers a second
%   time, so a bug in either the mapping or the toolbox static would still be
%   caught).

    methods (Test)

        % ================================================================== %
        % SandCL2.weighted_cg -- pure-math, no DI, no JSON.
        % ================================================================== %

        function testWeightedCgHandComputed(tc)
        % [no separate Raymer/Roskam eq. number -- standard weighted-average
        %  CG identity, VnV/BrandtF16A/readme_bsc.md's own "CG closure"
        %  formula]:
        %    weights_vec = [10, 20, 30], x_vec = [5, 10, 15]
        %    x_cg = (10*5 + 20*10 + 30*15) / (10+20+30)
        %         = (50 + 200 + 450) / 60 = 700/60 = 11.666666...7
            received = SandCL2.weighted_cg([10, 20, 30], [5, 10, 15]);
            expected = 700/60;
            tc.verifyEqual(received, expected, 'AbsTol', 1e-9, ...
                'weighted_cg must equal the hand-computed Sum(w_i*x_i)/Sum(w_i).');
        end

        function testWeightedCgSizeMismatchErrors(tc)
        % Guard condition: mismatched vector lengths must error, not silently
        % broadcast or truncate.
            tc.verifyError(@() SandCL2.weighted_cg([1, 2, 3], [1, 2]), ...
                'SandCL2:sizeMismatch');
        end

        function testWeightedCgPropagatesNaNGracefully(tc)
        % Documented behavior (StabControlBase.m, SandCL2.weighted_cg's own
        % header): a NaN component weight (the 'fuel' group pre-mission)
        % must propagate to a NaN x_cg via ordinary IEEE arithmetic, NOT
        % error. weights_vec = [10, NaN], x_vec = [5, 10] -> NaN, not an
        % error thrown by a mustBeNonnegative-style validator.
            received = SandCL2.weighted_cg([10, NaN], [5, 10]);
            tc.verifyTrue(isnan(received), ...
                'A NaN component weight must propagate to a NaN x_cg, not error.');
        end

        % ================================================================== %
        % F16SandCL2.x_cg -- integration test with a REAL F16WeightsL2.
        % ================================================================== %

        function testF16SandCL2XCgMatchesIndependentRecompute(tc)
        % Independent re-derivation: read the SAME 10 group weights off the
        % PUBLIC F16WeightsL2 API (not via F16SandCL2's own private
        % group_weight switch) and pair them with the JSON's own cg_x_ft
        % stations (hand-transcribed here from
        % examples/F16A/jsons/f16a_L2.json .stability_control
        % .component_x_stations.groups, group order wing/horizontal_tail/
        % vertical_tail/fuselage/landing_gear/installed_engine/
        % subsystems_lump/strake/payload/fuel), then compute the weighted
        % average by hand (sum(w.*x)/sum(w)) in THIS test -- not by calling
        % SandCL2.weighted_cg. This still catches a wrong-property-name or
        % wrong-group-order bug in F16SandCL2.group_weight/component_cg_x_ft,
        % which is the actual DI-wiring risk this class carries (the
        % weighted-average identity itself is separately unit-tested above).
            [w2, prop, geom] = TestSandCL2.makeWeights(); %#ok<ASGLU>
            w2.W_TO     = 31377;   % Brandt F-16A TOGW [readme_wt.md] -- unblocks requireWTO-guarded groups
            w2.W_energy = 6294;    % legacy Fuel1+2+3 = 2098*3 [f16a_L3.json .stability_control component note] -- a real, non-NaN number so this test checks the numeric path, not the NaN-propagation path (that is its own dedicated test below)

            s2 = F16SandCL2(f16a_spec_path(2), w2);

            x = [27.28, 41.0, 40.0, 26.0, 26.0, 31.45, 21.11, 17.0, 24.63, 26.0];
            w = [w2.W_wings, w2.W_tail.HT, w2.W_tail.VT, w2.W_fuselage, ...
                 w2.W_landing_gear, w2.W_installed_engine, w2.W_all_else_empty, ...
                 w2.W_strake, w2.W_payload_fixed + w2.W_payload_expendable, w2.W_energy];
            expected = sum(w .* x) / sum(w);

            tc.verifyEqual(s2.x_cg, expected, 'RelTol', 1e-9, ...
                'F16SandCL2.x_cg must equal the independently-recomputed weighted average of the live group weights and JSON cg_x_ft stations.');
        end

        function testF16SandCL2XCgPropagatesNaNWhenFuelUnset(tc)
        % W_energy defaults to NaN (mission-analysis STATE, not set here) --
        % x_cg must read NaN, NOT error, per StabControlBase.m's contract.
        % W_TO IS set (required for the OTHER, genuinely W_TO-dependent
        % groups -- landing_gear/subsystems_lump -- to avoid erroring for an
        % unrelated reason and masking the behavior actually under test).
            [w2, ~, ~] = TestSandCL2.makeWeights();
            w2.W_TO = 31377;
            % w2.W_energy left at its NaN default.

            s2 = F16SandCL2(f16a_spec_path(2), w2);
            tc.verifyTrue(isnan(s2.x_cg), ...
                'x_cg must propagate NaN gracefully when W_energy (fuel) is unset, not error.');
        end

        function testF16SandCL2XCgErrorsBeforeWTOSet(tc)
        % Landing_gear/subsystems_lump groups genuinely need obj.weights.W_TO
        % (0.033*W_TO / 0.17*W_TO metabook fractions) -- reading x_cg before
        % ANY candidate W_TO exists must error loudly through
        % F16WeightsL2's existing requireWTO guard, distinct from the
        % graceful fuel-NaN case above.
            [w2, ~, ~] = TestSandCL2.makeWeights();
            % w2.W_TO left at its NaN default -- deliberately not set.
            s2 = F16SandCL2(f16a_spec_path(2), w2);
            tc.verifyError(@() s2.x_cg, 'F16WeightsL2:WTONotSet');
        end

        % ================================================================== %
        % Constructor error paths -- arguments-block validation, matching
        % this repo's existing convention (e.g. TestSubsystemsL3's wrong-
        % geom-tier check).
        % ================================================================== %

        function testConstructorRejectsEmptyJsonPath(tc)
            [w2, ~, ~] = TestSandCL2.makeWeights();
            tc.verifyError(@() F16SandCL2('', w2), 'MATLAB:validators:mustBeNonzeroLengthText');
        end

        function testConstructorRejectsNonTextJsonPath(tc)
            [w2, ~, ~] = TestSandCL2.makeWeights();
            tc.verifyError(@() F16SandCL2(123, w2), 'MATLAB:validators:mustBeTextScalar');
        end

        function testConstructorRejectsWrongTypeWeights(tc)
        % weights is typed (1,1) F16WeightsL2 -- a bare double must fail at
        % CONSTRUCTION (arguments-block type coercion), matching
        % TestSubsystemsL3.testF16SubsystemsL3WrongGeomTierErrorsAtConstruction's
        % precedent.
            tc.verifyError(@() F16SandCL2(f16a_spec_path(2), 42), ...
                'MATLAB:validation:UnableToConvert');
        end

        function testConstructorRejectsNonexistentJsonPath(tc)
        % A well-formed but nonexistent file path must still throw -- past
        % the arguments-block validators (which only check TEXT-ness), the
        % constructor's own jsondecode(fileread(...)) call fails. Not
        % asserting a specific MATLAB-internal error identifier here (fragile
        % across MATLAB versions); just that construction throws.
            [w2, ~, ~] = TestSandCL2.makeWeights();
            bogus = fullfile(tempdir, 'TestSandCL2_nonexistent_9f3c1a.json');
            threw = false;
            try
                F16SandCL2(bogus, w2);
            catch %#ok<CTCH>
                threw = true;
            end
            tc.verifyTrue(threw, 'Constructing with a nonexistent JSON path must throw.');
        end

        function testConstructorRequiresBothArgs(tc)
            tc.verifyError(@() F16SandCL2(), 'MATLAB:minrhs');
            tc.verifyError(@() F16SandCL2(f16a_spec_path(2)), 'MATLAB:minrhs');
        end

        % ================================================================== %
        % Optimization-ready property design -- read-only Dependent.
        % ================================================================== %

        function testXCgIsReadOnly(tc)
            [w2, ~, ~] = TestSandCL2.makeWeights();
            w2.W_TO = 31377;
            s2 = F16SandCL2(f16a_spec_path(2), w2);
            tc.verifyError(@() setfield(s2, 'x_cg', 999), 'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testIsaChecks(tc)
            [w2, ~, ~] = TestSandCL2.makeWeights();
            s2 = F16SandCL2(f16a_spec_path(2), w2);
            tc.verifyTrue(isa(s2, 'StabControlBase'));
            tc.verifyTrue(isa(s2, 'SandCModelL2'));
            tc.verifyTrue(isa(s2, 'handle'));
        end

    end

    % ---------------------------------------------------------------------- %
    % Fixture helper
    % ---------------------------------------------------------------------- %

    methods (Static, Access = private)

        function [w2, prop, geom] = makeWeights()
        %MAKEWEIGHTS  Real F16WeightsL2, W_TO/W_energy left at their NaN
        %   defaults (the caller sets whichever it needs for its own test).
            prop = F16PropL2(f16a_spec_path(2));
            geom = F16GeomL2(f16a_spec_path(2), prop);
            w2   = F16WeightsL2(f16a_spec_path(2), f16a_requirements_path(), geom, prop);
        end

    end

end
