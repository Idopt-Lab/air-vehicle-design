classdef test_F16SizingStudies < matlab.unittest.TestCase
    % V&V tests for end-to-end F-16 sizing studies.
    %
    % Brandt ground-truth targets (Brandt-F16-A.xls):
    %   W_TO   = 31,377 lb   (Wt!B3)
    %   S_ref  = 300 ft²     (fixed input from JSON)
    %   T_SL   = 23,770 lb   (engine.T_AB_SLS_lb)
    %   W/S    = 104.59 psf  (Consts tab)
    %   T/W    = 0.7575      (Consts tab)
    %   S_HT   ~ 108 ft²     (back-calculated from volume coeff.)
    %   S_VT   ~ 60 ft²      (back-calculated from volume coeff.)
    %
    % Tolerance: Study 01 ±30% on W_TO; Study 02/03 ±20% on W_TO.

    properties
        geom_json
        W_TO_brandt = 31377    % lbf
        T_SL_brandt = 23770    % lbf
        S_ref       = 300      % ft²
        W_payload   = 5100     % lbf (4400 weapons + 700 pilot)
    end

    methods (TestClassSetup)
        function setup(~)
            TestSetup();
        end
    end

    methods (TestMethodSetup)
        function loadJSON(tc)
            json_path = fullfile(fileparts(mfilename('fullpath')), ...
                '..', 'Ground-Truth', 'f16a_geometry.json');
            tc.geom_json = jsondecode(fileread(json_path));
        end
    end

    methods (Test)

        % ---- Design Study 01: L1 disciplines + SizingLoopL1 ----

        function testStudy01_converges(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [W_TO, ~, ~, iter] = sizer.run(req, aero, prop, wts, geom, miss, con);
            tc.verifyLessThan(iter, sizer.max_iter, ...
                'Study 01 must converge within max_iter');
            tc.verifyGreaterThan(W_TO, 0, 'Converged W_TO must be positive');
        end

        function testStudy01_WTO_physical_range(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [W_TO, ~, ~] = sizer.run(req, aero, prop, wts, geom, miss, con);
            tc.verifyGreaterThan(W_TO, 20000, 'W_TO > 20,000 lb');
            tc.verifyLessThan(W_TO,    50000, 'W_TO < 50,000 lb');
        end

        function testStudy01_WTO_vs_Brandt(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [W_TO, ~, ~] = sizer.run(req, aero, prop, wts, geom, miss, con);
            tc.verifyGreaterThan(W_TO, tc.W_TO_brandt * 0.70, ...
                'Study 01 W_TO lower bound (Brandt ±30%)');
            tc.verifyLessThan(W_TO,    tc.W_TO_brandt * 1.30, ...
                'Study 01 W_TO upper bound (Brandt ±30%)');
        end

        function testStudy01_Sref_positive(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [~, S_ref, ~] = sizer.run(req, aero, prop, wts, geom, miss, con);
            tc.verifyGreaterThan(S_ref, 0);
        end

        function testStudy01_Sref_physical_range(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [~, S_ref, ~] = sizer.run(req, aero, prop, wts, geom, miss, con);
            tc.verifyGreaterThan(S_ref, 150, 'S_ref > 150 ft²');
            tc.verifyLessThan(S_ref,    700, 'S_ref < 700 ft²');
        end

        function testStudy01_TSL_vs_Brandt(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [~, ~, T_SL] = sizer.run(req, aero, prop, wts, geom, miss, con);
            tc.verifyGreaterThan(T_SL, tc.T_SL_brandt * 0.70, ...
                'Study 01 T_SL lower bound (Brandt ±30%)');
            tc.verifyLessThan(T_SL,    tc.T_SL_brandt * 1.30, ...
                'Study 01 T_SL upper bound (Brandt ±30%)');
        end

        function testStudy01_WingLoading_range(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [W_TO, S_ref, ~] = sizer.run(req, aero, prop, wts, geom, miss, con);
            WS = W_TO / S_ref;
            tc.verifyGreaterThan(WS, 60,  'W/S > 60 psf');
            tc.verifyLessThan(WS,    160, 'W/S < 160 psf');
        end

        % ---- Design Study 02: L2 disciplines + SizingLoopL2 ----

        function testStudy02_converges(tc)
            [sizer, req, aero, prop, wts, geom, miss, con, tail] = ...
                tc.build_study02();
            [W_TO, ~, iter] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
            tc.verifyLessThan(iter, sizer.max_iter, ...
                'Study 02 must converge within max_iter');
            tc.verifyGreaterThan(W_TO, 0);
        end

        function testStudy02_WTO_vs_Brandt(tc)
            [sizer, req, aero, prop, wts, geom, miss, con, tail] = ...
                tc.build_study02();
            [W_TO, ~, ~] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
            tc.verifyGreaterThan(W_TO, tc.W_TO_brandt * 0.80, ...
                'Study 02 W_TO lower bound (Brandt ±20%)');
            tc.verifyLessThan(W_TO,    tc.W_TO_brandt * 1.20, ...
                'Study 02 W_TO upper bound (Brandt ±20%)');
        end

        function testStudy02_TSL_positive(tc)
            [sizer, req, aero, prop, wts, geom, miss, con, tail] = ...
                tc.build_study02();
            [~, T_SL, ~] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
            tc.verifyGreaterThan(T_SL, 0);
        end

        function testStudy02_TSL_vs_Brandt(tc)
            [sizer, req, aero, prop, wts, geom, miss, con, tail] = ...
                tc.build_study02();
            [~, T_SL, ~] = sizer.run(req, aero, prop, wts, geom, miss, con, tail);
            tc.verifyGreaterThan(T_SL, tc.T_SL_brandt * 0.80, ...
                'Study 02 T_SL lower bound (Brandt ±20%)');
            tc.verifyLessThan(T_SL,    tc.T_SL_brandt * 1.20, ...
                'Study 02 T_SL upper bound (Brandt ±20%)');
        end

        function testStudy02_tail_was_sized(tc)
            [sizer, req, aero, prop, wts, geom, miss, con, tail] = ...
                tc.build_study02();
            sizer.run(req, aero, prop, wts, geom, miss, con, tail);
            tc.verifyGreaterThan(geom.S_HT, 0, 'S_HT must be set after L2 sizing');
            tc.verifyGreaterThan(geom.S_VT, 0, 'S_VT must be set after L2 sizing');
            tc.verifyGreaterThan(geom.S_HT, 40,  'S_HT > 40 ft²');
            tc.verifyLessThan(geom.S_HT,    250, 'S_HT < 250 ft²');
        end

        % ---- Weight closure check ----

        function testStudy01_weight_closure(tc)
            [sizer, req, aero, prop, wts, geom, miss, con] = ...
                tc.build_study01();
            [W_TO, S_ref, ~] = sizer.run(req, aero, prop, wts, geom, miss, con);
            % Verify the weight equation closes at the converged solution
            req.S_ref  = S_ref;
            prop.T0    = W_TO * 0.7575;  % approximate; recompute
            W_fuel = miss.compute_fuel(aero, prop, W_TO, req);
            W_OEW  = wts.OEW(W_TO);
            W_TO_check = W_OEW + req.W_payload + W_fuel;
            rel_err = abs(W_TO_check - W_TO) / W_TO;
            tc.verifyLessThan(rel_err, 0.05, ...
                'Weight equation must close within 5% at converged W_TO');
        end

    end

    methods (Access = private)

        function req = build_req(tc)
            req.W_payload     = tc.W_payload;
            req.S_ref         = tc.S_ref;
            req.AR            = tc.geom_json.wing.AR;
            req.aircraft_type = 'fighter';
            req.engine_type   = 'jet';
            req.segments      = tc.build_mission_segments();
        end

        function seg = build_mission_segments(~)
            seg(1).name='startup';  seg(1).altitude_ft=0;     seg(1).mach=0;
            seg(2).name='taxi';     seg(2).altitude_ft=0;     seg(2).mach=0;
            seg(3).name='takeoff';  seg(3).altitude_ft=0;     seg(3).mach=0.282;
            seg(4).name='climb';    seg(4).altitude_ft=40000; seg(4).mach=0.87;
            seg(5).name='cruise';   seg(5).altitude_ft=40000; seg(5).mach=0.87;
                                     seg(5).range_ft=190.8*6076;
            seg(6).name='dash';     seg(6).altitude_ft=40000; seg(6).mach=0.87;
                                     seg(6).range_ft=50*6076;
            seg(7).name='combat';   seg(7).altitude_ft=25000; seg(7).mach=0.87;
                                     seg(7).time_min=2; seg(7).W_drop=4400;
            seg(8).name='cruise';   seg(8).altitude_ft=40000; seg(8).mach=0.87;
                                     seg(8).range_ft=250*6076;
            seg(9).name='loiter';   seg(9).altitude_ft=10000; seg(9).mach=0.30;
                                     seg(9).time_min=20;
            seg(10).name='descent'; seg(10).altitude_ft=0; seg(10).mach=0.3;
            seg(11).name='landing'; seg(11).altitude_ft=0; seg(11).mach=0.2;
        end

        function [sizer, req, aero, prop, wts, geom, miss, con] = build_study01(tc)
            req   = tc.build_req();
            aero  = F16AeroLevel1(tc.geom_json);
            prop  = F16PropulsionLevel1(tc.geom_json);
            wts   = F16WeightLevel1();
            geom  = F16GeometryLevel1(tc.geom_json);
            miss  = F16MissionLevel1();
            con   = F16ConstraintAnalysis(tc.geom_json);
            sizer = SizingLoopL1(struct('tol', 1.0, 'max_iter', 200, 'verbose', false));
        end

        function [sizer, req, aero, prop, wts, geom, miss, con, tail] = build_study02(tc)
            req   = tc.build_req();
            aero  = F16AeroLevel2(tc.geom_json);
            prop  = F16PropulsionLevel2(tc.geom_json);
            wts   = F16WeightLevel2(tc.geom_json);
            geom  = F16GeometryLevel2(tc.geom_json);
            miss  = F16MissionLevel2();
            con   = F16ConstraintAnalysis(tc.geom_json);
            tail  = F16TailSizingLevel1();
            sizer = SizingLoopL2(struct('tol', 1.0, 'max_iter', 200, 'verbose', false));
        end

    end

    methods (TestClassTeardown)
        function printComparisonTable(tc) %#ok<MANU>
            fprintf('\n%s\n', repmat('=',1,70));
            fprintf('  F-16 Sizing Studies V&V — Comparison to Brandt\n');
            fprintf('%s\n', repmat('=',1,70));
            fprintf('%-25s %12s %12s %12s\n', 'Quantity', 'Brandt', 'Study01 tol', 'Study02 tol');
            fprintf('%s\n', repmat('-',1,70));
            fprintf('%-25s %12.0f %12s %12s\n', 'W_TO (lb)',  31377, '±30%', '±20%');
            fprintf('%-25s %12.0f %12s %12s\n', 'T_SL (lb)',  23770, '±30%', '±20%');
            fprintf('%-25s %12.1f %12s %12s\n', 'S_ref (ft²)', 300,  'Output', 'Fixed input');
            fprintf('%-25s %12.2f %12s %12s\n', 'W/S (psf)', 104.6,  'Output', 'Derived');
            fprintf('%-25s %12.4f %12s %12s\n', 'T/W',       0.7575, 'Output', 'Output');
            fprintf('%s\n', repmat('=',1,70));
        end
    end

end
