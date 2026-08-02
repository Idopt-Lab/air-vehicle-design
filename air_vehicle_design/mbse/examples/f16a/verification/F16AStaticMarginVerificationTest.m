classdef F16AStaticMarginVerificationTest < matlab.unittest.TestCase
    %F16ASTATICMARGINVERIFICATIONTEST Verify REQ_F16A_025 (relaxed static stability).
    %   This is the test that the REQ_F16A_025 "Verify" link points to. It
    %   checks that the DESIGN MEETS the requirement: the static margin
    %   SM = (x_np - x_cg)/MAC lies between -6 %MAC and +1 %MAC across the
    %   operational CG range -- at takeoff weight AND at landing weight
    %   (D-046).
    %
    %   IT IS THE THIRD VERIFICATION TEST, AND THE FIRST THAT LEAVES THE MODEL.
    %   The other two evaluate their requirement from the MBSE model itself:
    %   F16AMaterialsVerificationTest rolls up CompositeFraction, and
    %   F16AFuelVerificationTest rolls up FuelCapacity_lb. This one CANNOT.
    %   The Physical layer carries mass, composite fraction and fuel capacity
    %   -- it carries no neutral point, no centre of gravity and no mean
    %   aerodynamic chord, because none of those are properties of a part.
    %   Static margin is a whole-aircraft aerodynamic-and-balance result, so
    %   the requirement is verified by DELEGATING to the analysis that owns
    %   that result: sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m.
    %
    %   That delegation is the teaching point, not a workaround. A
    %   requirement's verification belongs wherever the evidence lives, and
    %   for stability and control the evidence lives in the sizing model. What
    %   the MBSE model contributes is the traceability: the requirement, the
    %   Implement link from the Airframe role, and this Verify link.
    %
    %   WHY THERE IS NO PROJECT ENTRY FOR THE SIZING CODE, AND WHY NONE IS
    %   NEEDED. A MATLAB project's files and path entries are all relative to
    %   the project ROOT, which for f16a.prj is the example folder itself.
    %   sizing/VnV/BrandtF16A sits OUTSIDE that root (it is a sibling of
    %   mbse/, three levels up), so it cannot be registered in f16a.prj at
    %   all -- not as a project file, not as a project path entry. Nor is it
    %   needed: project membership buys the Project browser, dependency
    %   analysis, runChecks and packaging, but NOT the ability to run anything
    %   (measured, TODO A1b -- 41 unregistered files ran fine). Resolution is
    %   by the MATLAB PATH, which is what the fixture below provides.
    %
    %   THE PATH IS RESTORED WHEN THE TEST FINISHES. A PathFixture is used
    %   rather than a bare addpath, and deliberately: the rest of this example
    %   addpaths sibling layer folders without cleanup, which is harmless
    %   because those folders are the project's own. Reaching THREE LEVELS
    %   OUT of the project is not harmless -- leaving sizing/ on the path
    %   would let a later test resolve a Brandt* name it never asked for, and
    %   would make results depend on which suites had run first. The fixture
    %   unwinds it -- and that is measured, not asserted: after this suite
    %   finishes, sizing/VnV/BrandtF16A is absent from `path` (checked
    %   2026-08-02).
    %
    %   NOTHING IN /sizing/ IS WRITTEN. BrandtGeometry / BrandtWeight /
    %   BrandtAerodynamics / BrandtBalanceStabControl compute in memory; the
    %   only file touched is GroundTruth/f16a_geometry.json, and it is read.
    %   /sizing/ is read-only reference for this example (house rule 4).
    %
    %   IF /sizing/ IS MISSING THIS TEST FAILS LOUDLY AND SAYS SO. It does not
    %   skip and it does not fall back to a transcribed number. A verification
    %   test that quietly stops verifying is worse than one that is red: the
    %   first reports success it did not earn.
    %
    %   HOW TO READ A PASS -- this matters more here than in the other two.
    %   The Brandt model COMPUTES SM_TO = -0.002602 (-0.26 %MAC) and
    %   SM_land = +0.002065 (+0.21 %MAC), measured 2026-08-02. The reference
    %   figures those are checked against, -0.00219 and +0.00272, are THE
    %   SIZING SUITE'S validation targets, not the workbook's: they appear in
    %   exactly one place -- test_BrandtBalanceStabControl.m:68,72, under
    %   sizing/VnV/BrandtF16A/tests -- and in neither GroundTruth/cell-map.md
    %   nor readme_bsc.md's own validation list, so attributing them to the
    %   spreadsheet would be wrong. Both computed
    %   values sit inside the AbsTol 0.001 those two tests allow -- an
    %   analogous .m-vs-.xls discrepancy to the one D-036 records for the
    %   component masses. ANALOGOUS, NOT THE SAME: the mass gap has a single
    %   documented cause (pi against the workbook's 3.1516), whereas this one
    %   has no single identified cause, and readme_bsc.md:44-46 lists three
    %   different approximations that could each contribute -- an
    %   exposed-span correction to the vertical-tail MAC station, a -0.522 ft
    %   balance datum shift applied to the installed-component arms, and a
    %   width-scaled fuselage destabilizing correction.
    %
    %   Both margins are inside the band, so REQ_F16A_025 is MET. But it is
    %   met because the band is wide enough to admit a NEARLY NEUTRAL
    %   aircraft -- NOT because the model reproduces the strongly relaxed
    %   static stability the F-16A is generally described as having. The
    %   -6 %MAC figure is an illustrative teaching value, not sourced data
    %   (D-030). Brandt's neutral point is a simplified approximation
    %   (readme_bsc.md: "a simplified neutral point"; "the fuselage
    %   destabilizing correction is simplified to a width-scaled offset"),
    %   and it lands near the STABLE end of the band rather than the relaxed
    %   end. Read the green as "the check runs and the figure is in range",
    %   not as evidence that the model demonstrates relaxed static stability.
    %   Same discipline D-030 applies to the composite fractions.
    %
    %   Kept in its own file, like the other two, so one requirement's status
    %   is one suite's status and no requirement's result can be hidden behind
    %   another's.
    %
    %   See also F16AMATERIALSVERIFICATIONTEST, F16AFUELVERIFICATIONTEST.

    properties (Constant)
        % The requirement band, REQ_F16A_025 (D-046). Expressed as a FRACTION
        % of MAC, matching BrandtBalanceStabControl's SM_TO / SM_land, which
        % are (x_np - x_cg)/MAC and therefore already fractions -- so -0.06 is
        % -6 %MAC. Declared here as the single place the numbers appear.
        %
        % BOTH BOUNDS ARE Estimate-CLASS VALUES, inventoried in D-030, and
        % NEITHER IS TRACEABLE TO /sizing/. There is no static-margin
        % criterion anywhere in the sizing code, its ground truth or its
        % tests (verified by f16a-data), and no source is cited for the
        % -6 %MAC lower bound. This is a teaching band, not a specification;
        % a pass against it says the figure is in range, not that the figure
        % was checked against a real requirement (see HOW TO READ A PASS).
        SMLower_fracMAC = -0.06
        SMUpper_fracMAC =  0.01

        % The SIZING POINT handed to BrandtBalanceStabControl.run, Wt!B3.
        % Stated rather than assumed: a static margin is only meaningful at a
        % stated weight, and this is the weight the whole Brandt F-16A model
        % is built around.
        %
        % IT IS THE WEIGHT SM_TO IS EVALUATED AT. IT IS NOT THE WEIGHT
        % SM_land IS EVALUATED AT. run() builds the landing case internally
        % (BrandtBalanceStabControl.m:203-206) by zeroing the expendable
        % payload and all three fuel thirds, and because
        % W_fuel = W_TO - perm_payload - exp_payload - W_empty
        % (BrandtWeight.m:267), what is left is
        % W_land = W_TO - exp_payload - W_fuel = W_empty + perm_payload
        % -- 20,677.61 lb at this sizing point, roughly 10,700 lb lighter
        % than takeoff. Measured 2026-08-02 and confirmed down both arms of
        % that identity: W_empty 19,977.61 + perm_payload 700, and
        % W_TO 31,377 - exp_payload 4,400 - W_fuel 6,299.39.
        %
        % THOSE ARE THE COMPUTED WEIGHTS. Substituting the validation-target
        % fuel figure of 6,296.30 lb instead would give 20,680.70 lb -- the
        % same .m-vs-.xls gap as everywhere else in this file, showing up as
        % 3 lb here. The number above is the computed one; do not "correct"
        % it from the target column, because keeping computed and target
        % values distinguishable is most of what this file is trying to
        % teach. The results struct returns no landing weight
        % (its fields are xcg_TO_ft, xcg_land_ft, SM_TO, SM_land,
        % gear_main_pct, gear_nose_pct, tipback_deg, rollover_deg, xnp_ft),
        % so where this file has to name that weight it states the
        % derivation rather than pretending to read a field back.
        W_TO_lb = 31377
    end

    properties
        % The struct BrandtBalanceStabControl.run returns. Computed once in
        % TestClassSetup: it is the same answer for every test method here and
        % re-running it per method would triple the cost for nothing.
        Balance struct
    end

    methods (TestClassSetup)
        function loadSizingBalanceModel(testCase)
            import matlab.unittest.fixtures.PathFixture

            brandtDir = F16AStaticMarginVerificationTest.brandtF16ADir();

            % ASSERT, not verify: everything below is meaningless without it,
            % and an assertion failure stops the suite instead of producing a
            % cascade of misleading requirement failures.
            testCase.assertTrue(isfolder(brandtDir), ...
                "REQ_F16A_025 cannot be verified: the sizing reference model was not " + ...
                "found at " + brandtDir + ". This test delegates the static-margin " + ...
                "calculation to sizing/VnV/BrandtF16A/BrandtBalanceStabControl.m, which " + ...
                "is outside the f16a project and resolved by path rather than by " + ...
                "project membership. It is NOT skipped when absent -- a verification " + ...
                "test that stops verifying must not report success.");

            % Restores the path when the class finishes, however it finishes.
            testCase.applyFixture(PathFixture(brandtDir));

            % Read-only: these compute in memory and write no file. The no-arg
            % constructor builds and analyzes its own geometry, weight and
            % aerodynamics, which is the documented usage.
            bsc = BrandtBalanceStabControl();
            bsc.analyze();
            testCase.Balance = bsc.run(testCase.W_TO_lb);
        end
    end

    methods (Test)
        function testAnalysisProducedUsableMargins(testCase)
            % A DEPENDENCY CHECK, RUN BEFORE THE REQUIREMENT IS JUDGED.
            % It separates "the aircraft violates REQ_F16A_025" from "the
            % analysis that evaluates REQ_F16A_025 is broken" -- two failures
            % that mean completely different things and would otherwise arrive
            % looking identical. A NaN static margin is not a requirement
            % violation; it is an analysis that did not run.
            testCase.assertTrue(isfield(testCase.Balance, "SM_TO") && ...
                isfield(testCase.Balance, "SM_land"), ...
                "BrandtBalanceStabControl.run did not return SM_TO / SM_land. The " + ...
                "sizing model's interface has changed and this verification is reading " + ...
                "the wrong fields -- fix the reader, do not reinterpret the result.");
            % string(num2str(x)), NOT string(x) -- AND THE REASON IS THE WHOLE
            % POINT OF THIS METHOD. string(NaN) is <missing>; concatenating
            % <missing> into a string yields <missing>; and the diagnostic
            % framework rejects <missing> with
            % MATLAB:automation:StringDiagnostic:InvalidValueMissingElement.
            % So written the obvious way, the message that exists to explain a
            % non-finite margin DISAPPEARED on precisely the input it was
            % written for, and this method threw an opaque framework exception
            % instead of failing in its own words -- while bandMessage's
            % non-finite branch was busy telling the reader to go and read it.
            % A check that becomes unreadable exactly when it fires is worth
            % less than no check at all, because it looks like tooling
            % breakage rather than a broken analysis.
            %
            % This is the house gotcha recorded at the end of the API findings
            % in docs/08_agent_team.md ("string(NaN) is <missing> ... use
            % string(num2str(NaN))"). num2str renders NaN as "NaN" and leaves
            % finite values legible.
            testCase.verifyTrue(isfinite(testCase.Balance.SM_TO), ...
                "Static margin at takeoff is not finite (" + ...
                string(num2str(testCase.Balance.SM_TO)) + "). This is a broken " + ...
                "analysis, not a requirement violation.");
            testCase.verifyTrue(isfinite(testCase.Balance.SM_land), ...
                "Static margin at landing is not finite (" + ...
                string(num2str(testCase.Balance.SM_land)) + "). This is a broken " + ...
                "analysis, not a requirement violation.");
        end

        function testTakeoffStaticMarginWithinBand(testCase)
            % REQ_F16A_025, AFT end of the operational CG range: heaviest,
            % full fuel, full stores. AFT, not forward. xcg_TO = 26.1979 ft
            % against xcg_land = 26.1451 ft (measured 2026-08-02), so takeoff
            % sits 0.0528 ft aft of landing -- and it has to, because the
            % expendable payload and all three fuel groups are stationed at
            % about 26.3 ft, aft of the aircraft CG, so releasing and burning
            % them moves the CG FORWARD. The margins already in this file say
            % the same thing from the other direction: xnp = 26.1684 ft falls
            % between the two CGs, which is why SM_TO comes out negative and
            % SM_land positive. The aft CG is always the less stable end.
            testCase.verifyThat(testCase.Balance.SM_TO, ...
                testCase.inBandConstraint(), ...
                testCase.bandMessage("takeoff", testCase.Balance.SM_TO));
        end

        function testLandingStaticMarginWithinBand(testCase)
            % REQ_F16A_025, FORWARD end of the operational CG range: fuel
            % burnt, stores released -- see the takeoff method above for why
            % the lighter case is the forward one and not the aft one. The
            % requirement says "across the operational CG range", so BOTH ends
            % have to hold -- checking only takeoff would verify half a
            % requirement and report it as all of one.
            testCase.verifyThat(testCase.Balance.SM_land, ...
                testCase.inBandConstraint(), ...
                testCase.bandMessage("landing", testCase.Balance.SM_land));
        end
    end

    methods (Access = private)
        function c = inBandConstraint(testCase)
            %INBANDCONSTRAINT The REQ_F16A_025 band as a unittest constraint.
            %   Built from the class constants rather than restated, so the
            %   band cannot be widened in one test and left alone in another.
            import matlab.unittest.constraints.IsGreaterThanOrEqualTo
            import matlab.unittest.constraints.IsLessThanOrEqualTo
            c = IsGreaterThanOrEqualTo(testCase.SMLower_fracMAC) & ...
                IsLessThanOrEqualTo(testCase.SMUpper_fracMAC);
        end

        function msg = bandMessage(testCase, condition, sm)
            %BANDMESSAGE A failure message that says which way it failed.
            %   THREE OUTCOMES, NOT TWO. Below the lower bound is too unstable
            %   to fly on the FCS authority assumed; above the upper bound is
            %   conventionally stable, which is not the relaxed configuration
            %   REQ_F16A_L02's fly-by-wire decision was justified by; and NOT
            %   A NUMBER AT ALL is neither of those -- it is a broken
            %   analysis.
            %
            %   The non-finite branch is not defensive padding, it is a bug
            %   fix. `NaN < x` is false, so with only an if/else a NaN static
            %   margin fell through to the else and was reported as "MORE
            %   POSITIVE ... conventionally stable" -- the exact confusion
            %   testAnalysisProducedUsableMargins exists to prevent, restated
            %   backwards by the message printed immediately after it. The
            %   finiteness checks stay verifyTrue rather than assertTrue so
            %   all three results still report in one run; it is the wording
            %   that had to stop lying, not the control flow.

            % THE BOUNDS IN THE PROSE ARE INTERPOLATED, NOT TYPED. They used
            % to be literal "-6 %MAC" / "+1 %MAC" text, which meant that the
            % moment either constant moved, this message named one band while
            % the "Required:" line below it named another -- measured with the
            % band forced to [0.50, 0.60], where the message read "MORE
            % NEGATIVE than the -6 %MAC lower bound ... Required: +50.0 %MAC
            % <= SM <= +60.0 %MAC". D-047 guarantee 5 claims the band appears
            % once, as class constants, and cannot be widened in one place and
            % left alone in another. inBandConstraint honoured that; the
            % sentence explaining the failure did not. Transcribing a value
            % instead of referencing it is the defect class this whole file
            % argues against, so it does not get an exemption in the file's
            % own diagnostics.
            lowerPct = 100 * testCase.SMLower_fracMAC;
            upperPct = 100 * testCase.SMUpper_fracMAC;
            if ~isfinite(sm)
                why = "NOT A FINITE NUMBER -- the analysis did not produce a static " + ...
                    "margin, so REQ_F16A_025 has not been evaluated at all, in either " + ...
                    "direction. This is a broken analysis, not a requirement " + ...
                    "violation; read it together with the " + ...
                    "testAnalysisProducedUsableMargins failure in the same run and " + ...
                    "fix the analysis before drawing any conclusion about stability";
            elseif sm < testCase.SMLower_fracMAC
                why = sprintf( ...
                    "MORE NEGATIVE than the %+.1f %%MAC lower bound -- more unstable " + ...
                    "than the flight control system is assumed to be able to stabilize", ...
                    lowerPct);
            else
                why = sprintf( ...
                    "MORE POSITIVE than the %+.1f %%MAC upper bound -- conventionally " + ...
                    "stable, which is not the relaxed configuration REQ_F16A_L02's " + ...
                    "fly-by-wire selection was justified by", upperPct);
            end

            % Which weight this condition actually is. The takeoff case IS the
            % sizing point; the landing case is not, and printing W_TO for it
            % would name a condition 10,700 lb heavier than the one that
            % failed. See the W_TO_lb constant above for the derivation.
            if strcmp(condition, "takeoff")
                atWeight = sprintf("sizing point W_TO = %d lb", testCase.W_TO_lb);
            elseif strcmp(condition, "landing")
                atWeight = sprintf( ...
                    "landing weight, which run() builds internally from the sizing " + ...
                    "point W_TO = %d lb by zeroing the expendable payload and all " + ...
                    "three fuel thirds: W_land = W_empty + perm_payload, about " + ...
                    "20,678 lb computed", testCase.W_TO_lb);
            else
                % A condition this builder has not been taught. Say the weight
                % is unknown rather than defaulting to W_TO -- defaulting is
                % exactly how the landing message came to name the wrong
                % weight, and the fix should not leave the door open behind
                % it.
                atWeight = sprintf( ...
                    "run() called at sizing point W_TO = %d lb; the weight of " + ...
                    "condition '%s' is not characterised by this test", ...
                    testCase.W_TO_lb, condition);
            end

            % Same two locals the prose above used, and the same %+.1f, so the
            % two statements of the band are identical character for
            % character. A reader who spots a difference between them is
            % looking at a bug, not at a rounding convention.
            msg = sprintf( ...
                "REQ_F16A_025 NOT met at %s (%s): static margin %.4f %%MAC is %s. " + ...
                "Required: %+.1f %%MAC <= SM <= %+.1f %%MAC. Source: " + ...
                "sizing/VnV/BrandtF16A/BrandtBalanceStabControl.", ...
                condition, atWeight, 100*sm, why, lowerPct, upperPct);
        end
    end

    methods (Static, Access = private)
        function d = brandtF16ADir()
            %BRANDTF16ADIR Absolute path to sizing/VnV/BrandtF16A.
            %   Derived from f16aRoot() -- the example's single location
            %   anchor -- rather than from this file's own folder, so it
            %   follows the same rule every other script here does and
            %   survives the verification/ folder being moved.
            %
            %   Three levels up from the example root:
            %     .../air_vehicle_design/mbse/examples/f16a   <- f16aRoot()
            %     .../air_vehicle_design/mbse/examples
            %     .../air_vehicle_design/mbse
            %     .../air_vehicle_design                      <- and sizing/ is here
            avd = fileparts(fileparts(fileparts(f16aRoot())));
            d = fullfile(avd, "sizing", "VnV", "BrandtF16A");
        end
    end
end
