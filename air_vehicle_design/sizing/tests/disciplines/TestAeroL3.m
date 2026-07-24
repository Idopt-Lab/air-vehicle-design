classdef TestAeroL3 < matlab.unittest.TestCase
%TESTAEROL3  Tier-1 unit/correctness tests for the AeroL3 toolbox + F16AeroL3.
%
%   L3 is the Raymer Eq. 12.24 component drag build-up plus the F16's own
%   supersonic wave-drag term (Eq. 12.41, M>=1.2):
%     CD0 = [sum_c (Cf_c*FF_c*Q_c*S_wet_c)]/S_ref + CD0_misc + CD0_LandP
%       Cf_lam  = 1.328/sqrt(Re)                        Eq. 12.26
%       Cf_turb = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65]  Eq. 12.27
%       Re_cut  = 38.21*(l/k)^1.053 (sub) / 44.62*(l/k)^1.053*M^1.16 (sup)  Eq. 12.28/29
%       FF_surf = (1+0.6/x*tc+100*tc^4)*(1.34*M^0.18*cos(Lm)^0.28)  Eq. 12.30
%       FF_body = 1+5/f^1.5+f/400 (f<=6) or 1+60/f^3+f/400 (f>6)     Eq. 12.31
%     CD_wave = E_WD*[1-0.386*(M-1.2)^0.57*(1-(pi*L_LE^0.77)/100)]
%               *(9*pi/2)*(A_max/l)^2/S_ref   (M>=1.2)   Eq. 12.41
%       (F16-specific F16AeroL3.compute_CD0_wave, NOT a generic toolbox method)
%     K1/K2/CLmax as at L2. Transonic band (0.95<M<1.05) NOT modeled -> NaN.
%
%   The shared skin-friction primitives (dyn_viscosity, Cf_turbulent) live in
%   the AeroL2 toolbox (single source of truth); the AeroL3 buildup calls them.
%   Tests reference them at their real home (AeroL2.*) -- the old tests that
%   called AeroL3.dyn_viscosity / AeroL3.Cf_turbulent are updated accordingly.
%
%   Every "expected" is HAND-COMPUTED from the cited formula with independent
%   inputs and the arithmetic shown inline (RelTol 1e-4). No Brandt-comparison
%   assertions -- those live in the separate aerodynamics_brandt_comparison.m
%   report.
%
%   NOTE ON DELETED TESTS (do not re-add): testPopulateHLDDeltasFillsProperties
%   called g.populate_HLD_deltas / Delta_CD0_TO_flap -- neither the method nor
%   those properties exist on the rewritten F16AeroL3 (removed). The Brandt
%   actual-polar comparison (testDragPolarVsBrandtActualAtDash) and Brandt
%   Mach-point / constraint-condition comparisons moved to the report.
%
%   testTODO_* are DELIBERATELY-FAILING placeholders for citations still marked
%   _TODO in f16a_L3.json's .aerodynamics (the only expected run_all_tests failures).

    methods (Static, Access = private)
        function a = makeAero()
        %MAKEAERO  A fresh F16AeroL3 with an injected F16GeomL2 (Geometry has no
        %   L3 tier), aero constants from the unified L3 JSON, geometry from the
        %   unified L2 JSON. Constructors require explicit paths -- no defaults.
            a = F16AeroL3(F16GeomL2(f16a_spec_path(2)), f16a_spec_path(3));
        end
        function J = readAeroL3JSON()
        %READAEROL3JSON  The .aerodynamics block of the unified L3 JSON.
            J = jsondecode(fileread(f16a_spec_path(3))).aerodynamics;
        end
    end

    methods (Test)

        % ================================================================== %
        % Skin-friction primitives (shared, homed in AeroL2; Cf_lam in AeroL3)
        % ================================================================== %

        function testViscosityAtSeaLevel(tc)
            % Sutherland (English): at T = T_ref = 518.67 R the two ratio terms
            % are exactly 1, so mu = mu_ref = 3.737e-7 slug/(ft*s).
            tc.verifyEqual(AeroL2.dyn_viscosity(518.67), 3.737e-7, 'AbsTol', 1e-12);
        end

        function testViscosityIncreasesWithTemperature(tc)
            % Sutherland: mu rises with temperature for a gas.
            tc.verifyGreaterThan(AeroL2.dyn_viscosity(700), AeroL2.dyn_viscosity(400));
        end

        function testCfLaminarFormula(tc)
            % Cf_lam = 1.328/sqrt(Re). Re=1e6 -> 1.328/1000 = 0.001328.
            tc.verifyEqual(AeroL3.Cf_laminar(1e6), 0.001328, 'RelTol', 1e-4);
        end

        function testCfTurbulentFormula(tc)
            % Eq. 12.27: Cf = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65].
            % Independent Re=1e7, M=0.5:
            %   log10(1e7) = 7 ; 7^2.58 = 151.4056
            %   1+0.144*0.25 = 1.036 ; 1.036^0.65 = 1.0233346
            %   Cf = 0.455/(151.4056*1.0233346) = 0.455/154.9391 = 0.0029354
            tc.verifyEqual(AeroL2.Cf_turbulent(1e7, 0.5), 0.0029354495, 'RelTol', 1e-4);
        end

        function testCfTurbGreaterThanLaminar(tc)
            tc.verifyGreaterThan(AeroL2.Cf_turbulent(1e7, 0.3), AeroL3.Cf_laminar(1e7));
        end

        function testCfTurbDecreasesWithRe(tc)
            tc.verifyGreaterThan(AeroL2.Cf_turbulent(1e6, 0.3), AeroL2.Cf_turbulent(1e8, 0.3));
        end

        function testComputeReScalesLinearlyWithLength(tc)
            % Re = rho*V*l/mu is linear in reference length l (structural check
            % of the wiring, independent of the atmosphere values).
            state = AircraftState(0, 0.5);
            re1 = AeroL2.compute_Re(state, 5.0);
            re2 = AeroL2.compute_Re(state, 10.0);
            tc.verifyEqual(re2, 2*re1, 'RelTol', 1e-10);
        end

        % ================================================================== %
        % Cutoff Reynolds (Raymer Eq. 12.28 / 12.29)
        % ================================================================== %

        function testReCutoffSubFormula(tc)
            % Re_cut = 38.21*(l/k)^1.053. Independent l=10, k=2.08e-5:
            %   l/k = 480769.23 ; (l/k)^1.053 = 961787.90 ; *38.21 = 3.674992e7
            tc.verifyEqual(AeroL3.Re_cutoff_sub(10, 2.08e-5), 3.674992e7, 'RelTol', 1e-4);
        end

        function testReCutoffSupFormula(tc)
            % Re_cut = 44.62*(l/k)^1.053*M^1.16. l=10, k=2.08e-5, M=1.5:
            %   base 44.62*(l/k)^1.053 = 4.291498e7 ; 1.5^1.16 = 1.6005375
            %   -> 4.291498e7*1.6005375 = 6.868703e7
            tc.verifyEqual(AeroL3.Re_cutoff_sup(10, 2.08e-5, 1.5), 6.868703e7, 'RelTol', 1e-4);
        end

        % ================================================================== %
        % Form factors (Raymer Eq. 12.30 surface / Eq. 12.31 body)
        % ================================================================== %

        function testFFSurfaceFormula(tc)
            % Eq. 12.30: (1+0.6/x*tc+100*tc^4)*(1.34*M^0.18*cos(Lm)^0.28).
            % Independent tc=0.04, x=0.40, Lm=32 deg, M=0.5:
            %   thickness = 1 + 0.6/0.40*0.04 + 100*0.04^4
            %             = 1 + 0.06 + 0.0000256 = 1.0602560 (0.6/0.40*0.04=0.06)
            %   comp = 1.34*0.5^0.18*cos(32)^0.28
            %        = 1.34*0.8827030*0.9548997 = 1.1294763
            %   FF = 1.0602560*1.1294763 = 1.1975341
            tc.verifyEqual(AeroL3.FF_surface(0.04, 0.40, 32, 0.5), 1.1975340572, 'RelTol', 1e-4);
        end

        function testFFSurfaceGuardsZeroXcMax(tc)
            % x_c_max is a 0.6/x denominator -> mustBePositive guard.
            tc.verifyError(@() AeroL3.FF_surface(0.04, 0, 32, 0.5), ...
                'MATLAB:validators:mustBePositive');
        end

        function testFFBodyFinenessGreaterThan6(tc)
            % Eq. 12.31 (f>6 branch): 1 + 60/f^3 + f/400. F16 fuselage-like
            % L=46.5, D=5 -> f=9.3:
            %   60/9.3^3 = 60/804.357 = 0.0745938 ; 9.3/400 = 0.023250
            %   FF = 1 + 0.0745938 + 0.023250 = 1.0978437
            tc.verifyEqual(AeroL3.FF_body(46.5, 5), 1.0978437438, 'RelTol', 1e-4);
        end

        function testFFBodyFinenessAtMost6(tc)
            % Eq. 12.31 (f<=6 branch): 1 + 5/f^1.5 + f/400. Duct-like L=14,
            % D=3.15 -> f=4.4444:
            %   5/4.4444^1.5 = 0.5336344 ; 4.4444/400 = 0.0111111
            %   FF = 1 + 0.5336344 + 0.0111111 = 1.5447455
            tc.verifyEqual(AeroL3.FF_body(14, 3.15), 1.5447454663, 'RelTol', 1e-4);
        end

        function testFFBodyGuardsNonPositiveDiameter(tc)
            % D_body is a fineness-ratio denominator -> mustBePositive guard.
            tc.verifyError(@() AeroL3.FF_body(46.5, 0), ...
                'MATLAB:validators:mustBePositive');
        end

        % ================================================================== %
        % Supersonic wave drag (F16-specific, Raymer Eq. 12.41) -- HEADLINE
        % ================================================================== %

        function testCD0WaveFormula(tc)
            % Hand-computed at M=1.5, SL, from the injected geometry envelope
            % (max_width=7.0 ft, max_height=5.0 ft, L_fus=46.5 ft) and the aero
            % inputs (Lambda_LE=40 deg, E_WD=2.2, S_ref=300 ft^2):
            %   A_max = (pi/4)*7.0*5.0 = 27.488936   (ellipse approximation)
            %   (M-1.2)^0.57       = 0.3^0.57        = 0.5034532
            %   pi*40^0.77/100     = pi*17.1232498/100 = 0.5379428
            %   1 - 0.386*0.5034532*(1-0.5379428)
            %       = 1 - 0.386*0.5034532*0.4620572 = 1 - 0.0897929 = 0.9102071
            %   searshaack = (9*pi/2)*(27.488936/46.5)^2 = 14.137167*0.3494700
            %              = 4.9405163
            %   CD_wave = 2.2*0.9102071*4.9405163/300 = 9.893164/300 = 0.0329772
            g        = TestAeroL3.makeAero();
            received = g.compute_CD0_wave(AircraftState(0, 1.5));
            tc.verifyEqual(received, 0.0329772136, 'RelTol', 1e-4);
        end

        function testCD0WaveDecreasesTowardHigherMach(tc)
            % The (M-1.2)^0.57 factor grows with M, shrinking the bracket, so
            % CD_wave eases from M=1.5 to M=2.0.
            g = TestAeroL3.makeAero();
            tc.verifyGreaterThan(g.compute_CD0_wave(AircraftState(0, 1.5)), ...
                                 g.compute_CD0_wave(AircraftState(0, 2.0)));
        end

        function testBuildupUnchangedBelowMach1p2(tc)
            % Below the Eq. 12.41 domain (M=1.05 < 1.2) the F16 override adds NO
            % wave drag: get_CD0_buildup must equal the generic AeroL3 buildup.
            g      = TestAeroL3.makeAero();
            state  = AircraftState(0, 1.05);
            tc.verifyEqual(g.get_CD0_buildup(state), AeroL3.get_CD0_buildup(g, state), ...
                'AbsTol', 1e-12);
        end

        function testBuildupIncludesWaveAboveMach1p2(tc)
            % At M=1.5 (>=1.2) the override adds exactly compute_CD0_wave on top
            % of the generic buildup (additive; confirms it is not a no-op).
            g     = TestAeroL3.makeAero();
            state = AircraftState(0, 1.5);
            tc.verifyEqual(g.get_CD0_buildup(state), ...
                AeroL3.get_CD0_buildup(g, state) + g.compute_CD0_wave(state), 'AbsTol', 1e-12);
        end

        function testDragPolarCD0RoutesThroughOverride(tc)
            % drag_polar's CD0 must flow through the instance's get_CD0_buildup
            % (dynamic dispatch), so it INCLUDES the F16 wave-drag term at M=1.5
            % -- regression guard for the override-vs-static dispatch bug.
            g     = TestAeroL3.makeAero();
            state = AircraftState(0, 1.5);
            tc.verifyEqual(g.drag_polar(state).CD0, g.get_CD0_buildup(state), 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Buildup physical-plausibility (coarse band, NOT a ground-truth fit)
        % ================================================================== %

        function testBuildupSubsonicPositiveAndPlausible(tc)
            % Sea-level M=0.5 clean CD0 from the component sum must be a
            % positive, physically plausible fighter value. Broad band
            % [0.005, 0.05] -- a sanity guard, not a fit to any ground truth
            % (the component model omits gaps/fillets/excrescences).
            g   = TestAeroL3.makeAero();
            cd0 = g.get_CD0_buildup(AircraftState(0, 0.5));
            tc.verifyGreaterThan(cd0, 0.005);
            tc.verifyLessThan(cd0, 0.05);
        end

        % ================================================================== %
        % Transonic guard (mandatory) + supersonic K2
        % ================================================================== %

        function testDragPolarTransonicReturnsNaN(tc)
            g = TestAeroL3.makeAero();
            w = warning('off', 'AeroL3:transonicNotModeled');
            cleanup = onCleanup(@() warning(w)); %#ok<NASGU>
            polar = g.drag_polar(AircraftState(0, 1.0));
            tc.verifyTrue(isnan(polar.CD0));
            tc.verifyTrue(isnan(polar.K1));
            tc.verifyTrue(isnan(polar.K2));
        end

        function testDragPolarTransonicWarns(tc)
            g = TestAeroL3.makeAero();
            tc.verifyWarning(@() g.drag_polar(AircraftState(0, 1.0)), ...
                'AeroL3:transonicNotModeled');
        end

        function testGetK1TransonicThrows(tc)
            g = TestAeroL3.makeAero();
            tc.verifyError(@() g.get_K1(1.0), 'AeroL3:transonicNotModeled');
        end

        function testDragPolarSupersonicK2Zero(tc)
            g     = TestAeroL3.makeAero();
            polar = g.drag_polar(AircraftState(0, 1.5));
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Optimization-ready DI guards (mirror TestGeomL2)
        % ================================================================== %

        function testDerivedTracksMutatedGeometryLiveOnRead(tc)
            % LIVE-RECOMPUTE: mutate the injected geometry in place; the
            % derived AR and the (S_wet-dependent) component buildup must both
            % track the change with no reconstruction.
            g    = TestAeroL3.makeAero();
            AR0  = g.AR;
            cd00 = g.get_CD0_buildup(AircraftState(0, 0.5));
            g.geom.AR_wing = g.geom.AR_wing + 1;
            tc.verifyEqual(g.AR, AR0 + 1, 'AbsTol', 1e-12);
            tc.verifyNotEqual(g.get_CD0_buildup(AircraftState(0, 0.5)), cd00, ...
                'Component buildup must change after the injected AR is mutated.');
        end

        function testDerivedPropertiesAreReadOnly(tc)
            g = TestAeroL3.makeAero();
            tc.verifyError(@() setfield(g, 'AR', 5),          'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_ref', 300),     'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'S_wet_comp', 0),  'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(g, 'CD0_misc', 0),    'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        % ================================================================== %
        % High-lift-device / gear deltas -- ordering/sign only
        % ================================================================== %

        function testDeltaCD0SlatPositive(tc)
            % LE slat parasite increment (Eq. 12.61 form) is positive.
            g = TestAeroL3.makeAero();
            tc.verifyGreaterThan(g.Delta_CD0_slat(g.delta_slat_TO_deg), 0);
        end

        function testDeltaCD0GeardownPositive(tc)
            % Landing-gear component-buildup increment is positive.
            g = TestAeroL3.makeAero();
            tc.verifyGreaterThan(g.compute_Delta_CD0_geardown(AircraftState(0, 0.2)), 0);
        end

        function testDeltaCLmaxFlapPlusSlatExceedsFlapAlone(tc)
            % L3 adds the LE slat on top of the TE flap -> total > flap alone.
            g = TestAeroL3.makeAero();
            tc.verifyGreaterThan(g.get_Delta_CLmax_TO(), g.Delta_CLmax_flap('TO'));
        end

        % ================================================================== %
        % Inheritance / interface compliance
        % ================================================================== %

        function testIsaAerodynamicsBase(tc)
            tc.verifyTrue(isa(TestAeroL3.makeAero(), 'AerodynamicsBase'));
        end

        function testIsaAeroModelL3(tc)
            tc.verifyTrue(isa(TestAeroL3.makeAero(), 'AeroModelL3'));
        end

        function testNotIsaAeroModelL2(tc)
            tc.verifyFalse(isa(TestAeroL3.makeAero(), 'AeroModelL2'));
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(TestAeroL3.makeAero(), 'handle'));
        end

        % ================================================================== %
        % DELIBERATELY-FAILING TODO (unverified citations) -- see header.
        % ================================================================== %

        function testTODO_EWDCalibrationInput(tc)
            % E_WD = 2.2 is a TUNED wave-drag multiplier back-checked to
            % Brandt/Casey, NOT a measured F16 datum. f16a_L3.json's .aerodynamics
            % still carries "_TODO_wave_drag_factor_E_WD". FAILS until it is
            % either sourced or explicitly accepted as a calibration knob.
            J = TestAeroL3.readAeroL3JSON();
            tc.verifyFalse(isfield(J, 'x_TODO_wave_drag_factor_E_WD'), ...
                'TODO: E_WD=2.2 is a tuned calibration input, not a spec value.');
        end

        function testTODO_RoughnessTableCitation(tc)
            % surface_roughness k cites Raymer Table 12.2 (the high-lift
            % Delta_cl_max table); the roughness table is 12.4/12.5 -- citation
            % drift. f16a_L3.json's .aerodynamics still carries "_TODO_table_number".
            J = TestAeroL3.readAeroL3JSON();
            tc.verifyFalse(isfield(J.surface_roughness_k_ft, 'x_TODO_table_number'), ...
                'TODO: surface-roughness k table number is miscited (12.2 vs 12.4/12.5).');
        end

    end
end
