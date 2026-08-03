classdef TestAeroL3 < matlab.unittest.TestCase
%TESTAEROL3  Tier-1 unit/correctness tests for the AeroL3 toolbox + F16AeroL3.
%
%   L3 is the Raymer Eq. 12.24 component drag build-up plus the F16's own
%   supersonic wave-drag term (Eqs. 12.44/12.45, M>=1.2):
%     CD0 = [sum_c (Cf_c*FF_c*Q_c*S_wet_c)]/S_ref + CD0_misc + CD0_LandP
%       Cf_lam  = 1.328/sqrt(Re)                        Eq. 12.26
%       Cf_turb = 0.455/[(log10 Re)^2.58*(1+0.144*M^2)^0.65]  Eq. 12.27
%       Re_cut  = 38.21*(l/k)^1.053 (sub) / 44.62*(l/k)^1.053*M^1.16 (sup)  Eq. 12.28/29
%       FF_surf = (1+0.6/x*tc+100*tc^4)*(1.34*M^0.18*cos(Lm)^0.28)  Eq. 12.30
%       FF_body = 1+5/f^1.5+f/400 (f<=6) or 1+60/f^3+f/400 (f>6)     Eq. 12.31
%     CD_wave = E_WD*[1-0.386*(M-1.2)^0.57*(1-(pi*L_LE^0.77)/100)]
%               *(9*pi/2)*(A_max/l)^2/S_ref   (M>=1.2)   Eqs. 12.44/12.45
%       (F16-specific F16AeroL3.compute_CD0_wave; A_max/l are WHOLE-AIRCRAFT
%        inputs, not the fuselage component)
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
        %MAKEAERO  A fresh F16AeroL3 with an injected F16GeomL2: aero constants
        %   from the unified L3 JSON, geometry from the unified L2 JSON.
        %   Constructors require explicit paths -- no defaults.
        %
        %   GEOMETRY TIER, deliberate (2026-07-25): Phase 2 promoted GeomL3 to a
        %   full L3 geometry tier, so an F16GeomL3 is now injectable here too
        %   (testGeometryInjectionRejectsWrongTierAtConstruction proves it).
        %   These tests keep the L2 geometry on purpose: every expected value in
        %   this file is hand-computed either from a bare AeroL2/AeroL3 static
        %   (geometry-independent) or from the L2 wing/fuselage envelope, and
        %   the file's job is the AeroL3 FORMULAS, not the L3 planform. Switching
        %   the injected tier is a comparison-report concern (the aerodynamics comparison report),
        %   not a unit-test one.
        %   PHASE-2 CONSTRUCTOR CHANGE: F16GeomL2 takes a REQUIRED injected
        %   propulsion object -- the nacelle diameter is sqrt(T_AB_SLS/1900),
        %   engine data rather than airframe data.
            a = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                          f16a_spec_path(3));
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
        % Supersonic wave drag (F16-specific, Raymer Eqs. 12.44/12.45) -- HEADLINE
        % ================================================================== %

        function testCD0WaveFormula(tc)
            % UPDATED 2026-07-25 (Phase 2). Amax_ft2 / L_aircraft_ft are no
            % longer frozen aero INPUTS read from a .aerodynamics.wave_drag JSON
            % block (that block is deleted); they are Dependent on the injected
            % geometry object. The old expected value used Brandt's geometry
            % OUTPUTS Amax=25.110556 / l=48.304 [Geom!B20/H47/B21]; the geometry
            % now supplies its own envelope figures, so this expected value is
            % re-derived from the geometry INPUTS instead.
            %
            % Hand-computed at M=1.5, SL, from the geometry inputs
            % (W_max_fuselage=7.0 ft, H_max_fuselage=5.0 ft, overall
            % L_aircraft=47.65 ft) and the aero inputs (Lambda_LE=40 deg,
            % E_WD=2.2, S_ref=300 ft^2):
            %   Amax = (pi/4)*W*H = (pi/4)*7*5 = 27.4889357 ft^2
            %          [standard elliptical-cross-section identity,
            %           GeometryBase.compute_Amax_elliptical -- no equation
            %           number exists; todo.md 2026-07-25 Phase 2 §4]
            %   Amax/l   = 27.4889357/47.65 = 0.5768927
            %   (Amax/l)^2                  = 0.3328052
            %   (D/q)_SH = (9*pi/2)*0.3328052 = 14.1371669*0.3328052
            %            = 4.7049220                                   [Eq. 12.44]
            %   (M-1.2)^0.57   = 0.3^0.57          = 0.5034532
            %   pi*40^0.77/100 = pi*17.1232498/100 = 0.5379428
            %   bracket = 1 - 0.386*0.5034532*(1-0.5379428) = 0.9102071  [Eq. 12.45]
            %   CD_wave = 2.2*0.9102071*4.7049220/300 = 0.0314047
            % (The old 0.0255006 value is +23.15% below this -- the shift is
            % REPORTED, not absorbed by retuning E_WD; see F16GeomL3.md §4.)
            g        = TestAeroL3.makeAero();
            received = g.compute_CD0_wave(AircraftState(0, 1.5));
            tc.verifyEqual(received, 0.0314046569, 'RelTol', 1e-4);
        end

        function testCD0WaveTracksFuselageEnvelopeLive(tc)
            % PHASE-2 POSITIVE CONTROL for a previously DEAD path. Amax_ft2 was
            % a frozen 25.110556 aero input, so the Eq. 12.44 Sears-Haack term
            % could not respond to ANY fuselage change: mutating the geometry
            % envelope left CD0 bit-identical. It is now Dependent on
            % geom.Amax = (pi/4)*W_max*H_max, so widening the fuselage must move
            % both Amax and the supersonic CD0.
            %   W_max 7.0 -> 8.0 ft, H_max 5.0:
            %     Amax     = (pi/4)*8*5      = 31.4159265 ft^2
            %     (Amax/l) = 31.4159265/47.65 = 0.6593060
            %     (D/q)_SH = (9*pi/2)*0.4346843 = 6.1441843
            %     CD_wave  = 2.2*0.9102071*6.1441843/300 = 0.0410183
            %   i.e. exactly (8/7)^2 = 1.3061224 times the baseline 0.0314047,
            %   since the term is linear in W_max^2.
            g     = TestAeroL3.makeAero();
            state = AircraftState(0, 1.5);
            tc.verifyEqual(g.Amax_ft2, 27.4889357189, 'RelTol', 1e-9, ...
                'Amax_ft2 must be the live geometry envelope (pi/4)*7*5, not Brandt''s 25.110556.');
            g.geom.W_max_fuselage = 8.0;   % optimizer-style in-place mutation
            tc.verifyEqual(g.Amax_ft2, 31.4159265359, 'RelTol', 1e-9, ...
                'Amax_ft2 must track the mutated fuselage width with no reconstruction.');
            tc.verifyEqual(g.compute_CD0_wave(state), 0.0410183274, 'RelTol', 1e-4, ...
                'The Eq. 12.44 wave term must follow the fuselage envelope (previously a dead path).');
        end

        function testGeometryInjectionRejectsWrongTierAtConstruction(tc)
            % PHASE-2 NARROWED GUARD (2026-07-25). The geometry argument was
            % `geom (1,1) GeometryBase`, which declares only
            % S_ref/S_wet/get_S_ref/get_S_wet while this class reads ~20 members
            % off obj.geom. A wrong tier constructed cleanly and then either died
            % mid-run inside get.S_wet_comp or -- worse, before the Phase-2
            % rename -- resolved AR_ht/lambda_ht to the EXPOSED planform where
            % Raymer Eq. 7.8 needs the FULL one, giving a wrong HT MAC, Reynolds
            % number and Eq. 12.30 form factor with no error and no warning. The
            % guard is now mustBeA(geom, ["GeometryModelL2","GeometryModelL3"]),
            % so a bad tier fails HERE.
            g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyError(@() F16AeroL3(g1, f16a_spec_path(3)), ...
                'MATLAB:validators:mustBeA', ...
                'An L1 geometry object must be rejected at F16AeroL3 construction.');
            % Positive control: both accepted tiers still construct.
            tc.verifyClass(F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                f16a_spec_path(3)), 'F16AeroL3');
            tc.verifyClass(F16AeroL3(F16GeomL3(f16a_spec_path(3), F16PropL2(f16a_spec_path(2))), ...
                f16a_spec_path(3)), 'F16AeroL3');
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
        % Domain guards + L2/L3 consistency (added 2026-07-25).
        % ================================================================== %

        function testCD0BuildupErrorsAtZeroMach(tc)
            % The Raymer Eq. 12.24 buildup is Reynolds-based. At M=0 every
            % component Re is 0, so Cf_laminar(0)=Inf while the Eq. 12.30 form
            % factor's 1.34*M^0.18 term is 0 -- the product used to evaluate to
            % NaN and return a NaN whole-aircraft CD0 with no warning. NaN makes
            % every > / < comparison in a constraint solve FALSE, so the point
            % was reported satisfied. AircraftState permits mach=0, so this must
            % error at the buildup.
            a3 = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                           f16a_spec_path(3));
            tc.verifyError(@() a3.drag_polar(AircraftState(0, 0)), ...
                'AeroL3:machOutOfDomain', ...
                'The L3 component buildup must reject M=0, not return NaN CD0.');
        end

        function testCfLaminarRejectsZeroReynolds(tc)
            % Re=0 -> Inf, Re<0 -> complex. Both are guarded at the primitive.
            tc.verifyError(@() AeroL3.Cf_laminar(0), 'MATLAB:validators:mustBePositive');
            tc.verifyError(@() AeroL3.Cf_laminar(-1), 'MATLAB:validators:mustBePositive');
            % Sanity: a physical Re still works -- Raymer Eq. 12.26,
            % 1.328/sqrt(1e6) = 1.328e-3 exactly.
            tc.verifyEqual(AeroL3.Cf_laminar(1e6), 1.328e-3, 'RelTol', 1e-12);
        end

        function testCD0BuildupFiniteAtSmallPositiveMach(tc)
            % The guard must reject only M=0, not a legitimate low-speed point.
            a3 = F16AeroL3(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                           f16a_spec_path(3));
            polar = a3.drag_polar(AircraftState(0, 0.1));
            tc.verifyTrue(isfinite(polar.CD0) && polar.CD0 > 0, ...
                'CD0 must be finite and positive at a small nonzero Mach.');
        end

        function testL3LiftSlopeMatchesL2ForSameGeometryAndAirfoil(tc)
            % L3 used to call AeroL2.CL_alpha with three arguments, so Raymer
            % Eq. 12.8's eta silently fell back to 0.95 while L2 -- the LOWER
            % fidelity level -- used the real NACA 64A204 slope (0.105/deg ->
            % eta = 6.016/(2*pi) = 0.957). Same wing, same airfoil, two answers.
            % With identical injected geometry the two levels must now agree
            % exactly: both are the same Raymer Eq. 12.6 evaluation.
            g  = F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2)));
            a2 = F16AeroL2(g, f16a_spec_path(2));
            a3 = F16AeroL3(g, f16a_spec_path(3));
            for M = [0, 0.6, 0.87]
                tc.verifyEqual(a3.get_CL_alpha(M), a2.get_CL_alpha(M), 'RelTol', 1e-12, ...
                    sprintf(['L3 and L2 CL_alpha must agree at M=%.2f for identical ' ...
                             'geometry and airfoil.'], M));
            end
            tc.verifyEqual(a3.cl_alpha_2D, 0.105*180/pi, 'RelTol', 1e-12, ...
                'F16AeroL3.cl_alpha_2D must be the JSON per-deg slope converted to 1/rad.');
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

        function testTODO_LEFScheduleNotPinned(tc)
        %TESTTODO_LEFSCHEDULENOTPINNED  Deliberate, EXPECTED red.
        %
        %   THIS TEST IS EXPECTED TO BE RED. Added 2026-07-30 -- audit finding
        %   A-3 noted this open item had no guarding test, unlike every other
        %   citation gap in Aerodynamics.
        %
        %   WHAT IS MISSING: delta_slat_TO_deg/delta_slat_L_deg = 17 in
        %   F16AeroL3.m is a stand-in for the leading-edge flap's real,
        %   AoA/Mach-scheduled position near the rotation/touchdown condition
        %   CLmax_TO/CLmax_L represent. Web research (2026-07-30) pinned the
        %   trailing-edge flap (20 deg, both conditions) but confirmed the LEF
        %   is not a fixed "TO/L config" value at all in the real aircraft --
        %   it is a continuous schedule, not in this repo. 17 deg remains
        %   unpinned against a primary source (T.O. 1F-16A-1).
        %
        %   HOW THIS TEST DETECTS IT: keys off F16AeroL3.m's own comment
        %   sentence, following TestWeightsL1.testTODO_RaymerTable61CoefficientsNotInRepo's
        %   pattern for a non-JSON-marker TODO. Do NOT make this green by
        %   deleting the comment without actually pinning the schedule.
            src = fileread(which('F16AeroL3'));
            tc.verifyFalse(contains(src, 'Still unpinned against a primary'), ...
                ['TODO (EXPECTED RED): the LEF schedule near rotation/touchdown ' ...
                 'is not pinned to a primary source; F16AeroL3.m still carries ' ...
                 'the standing TO-DO.']);
        end

    end
end
