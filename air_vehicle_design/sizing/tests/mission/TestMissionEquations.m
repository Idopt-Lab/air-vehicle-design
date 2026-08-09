classdef TestMissionEquations < matlab.unittest.TestCase
%TESTMISSIONEQUATIONS  Unit tests for the MissionEquations static toolbox.
%   Pure closed-form checks with hand-computed expected values; no discipline
%   objects except a fixed-TSFC prop stub for the select_tsfc blend. Unit tier
%   (gate run_all_tests).

    properties (Constant)
        TOL = 1e-9;
    end

    methods (Test)

        function testBreguetRangeWF(tc)
            % t_hr = (R/V)/3600 = (6080000/800)/3600 = 2.1111... hr
            % WF   = exp(-c_j * t_hr / (L/D)) = exp(-0.9*2.11111/10) = exp(-0.19)
            wf = MissionEquations.breguet_range_wf(0.9, 6080000, 800, 10);
            tc.verifyEqual(wf, exp(-0.19), 'RelTol', tc.TOL);
        end

        function testBreguetEnduranceWF(tc)
            % E = 60/60 = 1 hr; WF = exp(-0.9*1/10) = exp(-0.09)
            wf = MissionEquations.breguet_endurance_wf(0.9, 60, 10);
            tc.verifyEqual(wf, exp(-0.09), 'RelTol', tc.TOL);
        end

        function testRoskamFixedFractionsFighter(tc)
            f = @(ph) MissionEquations.roskam_fixed_fraction("jet_fighter", ph);
            tc.verifyEqual(f("startup"), 0.990);
            tc.verifyEqual(f("taxi"),    0.990);
            tc.verifyEqual(f("takeoff"), 0.990);
            tc.verifyEqual(f("climb"),   0.93);    % mean of Roskam 0.90-0.96
            tc.verifyEqual(f("descent"), 0.990);
            tc.verifyEqual(f("landing"), 0.995);
        end

        function testToRoskamRowTranslatesCanonical(tc)
            tc.verifyEqual(MissionEquations.to_roskam_row("jet_fighter"), "fighter");
            tc.verifyEqual(MissionEquations.to_roskam_row("fighter"), "fighter");
        end

        function testUnknownCategoryErrors(tc)
            tc.verifyError(@() MissionEquations.to_roskam_row("airliner"), ...
                'MissionEquations:unknownCategory');
        end

        function testUnknownPhaseErrors(tc)
            tc.verifyError(@() MissionEquations.roskam_fixed_fraction("jet_fighter", "hover"), ...
                'MissionEquations:unknownPhase');
        end

        function testSelectTsfcDryAndBlend(tc)
            prop  = MissionStubProp();          % dry 0.9, AB 1.8, no installed method
            state = AircraftState(10000, 0.5);  % ignored by the stub
            tc.verifyEqual(MissionEquations.select_tsfc(prop, state, 0),   0.9,  'RelTol', tc.TOL);
            tc.verifyEqual(MissionEquations.select_tsfc(prop, state, 100), 1.8,  'RelTol', tc.TOL);
            % blend: 0.9 + (50/100)*(1.8-0.9) = 1.35
            tc.verifyEqual(MissionEquations.select_tsfc(prop, state, 50),  1.35, 'RelTol', tc.TOL);
        end

        function testSelectTsfcDegradesWhenNoAB(tc)
            % F16PropL1 has no afterburner model: an AB request degrades to mil.
            prop  = F16PropL1(f16a_spec_path(1));
            state = AircraftState(40000, 0.87);
            tc.verifyFalse(MissionEquations.has_ab_model(prop));
            tc.verifyEqual(MissionEquations.select_tsfc(prop, state, 100), ...
                           prop.get_TSFC(state), 'RelTol', tc.TOL);
        end

    end
end
