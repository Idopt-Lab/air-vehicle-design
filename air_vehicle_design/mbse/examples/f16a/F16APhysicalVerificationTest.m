classdef F16APhysicalVerificationTest < matlab.unittest.TestCase
    %F16APHYSICALVERIFICATIONTEST Verify F-16A requirements by analysis.
    %   This is the project's first "verified by" test suite: each test checks
    %   that a requirement is actually MET (not just allocated), and each
    %   requirement carries a Verify link to this file so the trace is
    %   two-way. Unlike F16APhysicalArchitectureTest (which checks the model is
    %   built correctly), this checks the DESIGN satisfies its requirements.
    %
    %   REQ_F16A_022 (composite <= 20%): PASSES -- the airframe materials
    %   roll-up gives ~19% composite, within the cap.
    %
    %   REQ_F16A_P01 (fuel volume sufficiency): FAILS ON PURPOSE for now. The
    %   available side (fuel-capacity roll-up) is real, but the required side
    %   (mission fuel) is a stub returning NaN until the /sizing/ mission
    %   analysis is connected. The failure is an honest, traceable
    %   "verification pending" marker -- expect it to go green once the
    %   mission-fuel function is wired to /sizing/.

    properties
        OrigSet   % f16a.slreqx (REQ_F16A_022)
        PhysSet   % f16a_physical_derived.slreqx (REQ_F16A_P01)
    end

    methods (TestClassSetup)
        function openArtifacts(testCase)
            thisDir = fileparts(mfilename("fullpath"));
            addpath(thisDir);
            addpath(fullfile(thisDir, "physical"));
            addpath(fullfile(thisDir, "requirements"));
            slreq.clear();
            testCase.OrigSet = slreq.load(fullfile(thisDir, "requirements", "f16a.slreqx"));
            testCase.PhysSet = slreq.load(fullfile(thisDir, "requirements", "f16a_physical_derived.slreqx"));
            testCase.addTeardown(@() bdclose("all"));
            testCase.addTeardown(@() slreq.clear());
        end
    end

    methods (Test)

        function testMaterialsRequirementMet(testCase)
            % REQ_F16A_022: airframe composite fraction shall be <= 20%.
            mats = F16APhysicalMaterialsRollup();
            testCase.verifyLessThanOrEqual(mats.CompositeFraction, 0.20, ...
                sprintf("Airframe composite fraction %.1f%% exceeds the REQ_F16A_022 20%% cap.", ...
                100*mats.CompositeFraction));
            testCase.verifyGreaterThan(mats.CompositeFraction, 0, ...
                "Composite fraction roll-up returned 0 -- CompositeFraction props not set?");
        end

        function testMaterialsRequirementHasVerifyLink(testCase)
            % REQ_F16A_022 is "verified by" a test (Verify link present).
            req = find(testCase.OrigSet, Id="REQ_F16A_022");
            testCase.verifyNotEmpty(req, "REQ_F16A_022 not found.");
            testCase.verifyTrue(testCase.hasVerifyLink(req), ...
                "REQ_F16A_022 should carry a Verify link to its test.");
        end

        function testFuelVolumeRequirementMet(testCase)
            % REQ_F16A_P01: available internal fuel shall be >= mission fuel.
            % KNOWN-PENDING: mission fuel is a NaN stub, so this FAILS until
            % F16APhysicalMissionFuel is connected to the /sizing/ analysis.
            available = F16APhysicalFuelRollup().AvailableFuel_lb;
            required  = F16APhysicalMissionFuel();
            msg = sprintf("Fuel-volume verification PENDING: available=%.0f lb, " + ...
                "required=%g. Connect F16APhysicalMissionFuel to the /sizing/ " + ...
                "mission analysis (returns NaN until then).", available, required);
            testCase.verifyGreaterThanOrEqual(available, required, msg);
        end

        function testFuelVolumeRequirementHasVerifyLink(testCase)
            % REQ_F16A_P01 is "verified by" a test (Verify link present).
            req = find(testCase.PhysSet, Id="REQ_F16A_P01");
            testCase.verifyNotEmpty(req, "REQ_F16A_P01 not found.");
            testCase.verifyTrue(testCase.hasVerifyLink(req), ...
                "REQ_F16A_P01 should carry a Verify link to its test.");
        end

    end

    methods (Access = private)
        function tf = hasVerifyLink(~, req)
            tf = false;
            if isempty(req); return; end
            for links = {req.outLinks(), req.inLinks()}
                ls = links{1};
                for k = 1:numel(ls)
                    if string(ls(k).Type) == "Verify"; tf = true; return; end
                end
            end
        end
    end
end
