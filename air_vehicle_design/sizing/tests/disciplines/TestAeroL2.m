classdef TestAeroL2 < matlab.unittest.TestCase
%TESTAEROL2  Tier-1 unit/correctness tests for the AeroL2 toolbox + F16AeroL2.
%
%   L2 is the GEOMETRY-DEPENDENT clean drag polar + finite-wing lift, with all
%   geometry read live from an injected geometry object (dependency injection):
%     CD0 (subsonic)  = Cfe*(S_wet/S_ref)              Raymer 6th ed. Eq. 12.23
%     e (Lambda_LE>=30) = 4.61*(1-0.045*AR^0.68)*cos(L)^0.15 - 3.1   Eq. 12.49
%     e (Lambda_LE<30)  = 1.78*(1-0.045*AR^0.68) - 0.64              Eq. 12.48
%     K1 subsonic     = 1/(pi*AR*e)                    Eq. 12.50
%     K1 supersonic   = AR*(M^2-1)*cos(L_LE)/(4*AR*beta-2)          Eq. 12.51
%     K2 subsonic     = -2*K1*CL_minD (< 0, cambered)  Brandt Sec. 4.3
%     CL_alpha        = finite-wing Datcom slope       Eq. 12.6
%     CLmax (clean)   = 0.9*cl_max_2D*cos(Lambda_c/4)  Eq. 12.15
%   Transonic band (0.95 < M < 1.05) is NOT modeled -> drag_polar returns NaN.
%
%   Every "expected" is HAND-COMPUTED from the cited formula (arithmetic shown
%   inline), using GENUINE spec inputs where an F16 value is needed: AR=3,
%   Lambda_LE=40 deg (f16a_L2.json .geometry wing block), Cfe=0.0035 (Raymer Table
%   12.3), cl_max_2D=1.20 (airfoil), and the geometry-DERIVED quarter-chord
%   sweep Lambda_c/4=32.1831783983 deg (independently hand-computed in
%   TestGeomL2.testConvertSweepWingQC..., a GEOMETRY result, not an aero one).
%   No Brandt-comparison assertions here -- those live in the separate
%   examples/F16A/aerodynamics_brandt_comparison.m report.
%
%   NOTE ON DELETED TESTS (do not re-add): the previous TestAeroL2 asserted
%   CL_alpha at M=0 AND M=0.6 against the SAME Brandt per-degree constant
%   (0.054312*57.3, a value tabulated at Mcrit) -- self-contradicting and
%   self-referential (Brandt-model echo, todo.md Finding D). Its
%   testCLmaxClean/testDragPolarAtConstraintConditions were loose Brandt
%   comparisons. All removed; comparison happens only in the report.
%
%   testTODO_* are DELIBERATELY-FAILING placeholders for unverified airfoil
%   citations still marked _TODO in f16a_L2.json's .aerodynamics (the only expected
%   run_all_tests failures from this file).

    methods (Static, Access = private)
        function a = makeAero()
        %MAKEAERO  A fresh F16AeroL2 with an injected F16GeomL2, both built from
        %   the unified L2 JSON (constructors require explicit paths -- no
        %   silent defaults). The geometry constructor gained a REQUIRED
        %   injected propulsion object in Phase 2 (2026-07-25): the nacelle
        %   diameter is sized from engine thrust (sqrt(T_AB_SLS/1900)), which is
        %   engine data, not airframe data, so F16GeomL2 takes (json_path, prop).
            a = F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                          f16a_spec_path(2), f16a_control_surfaces());
        end
        function J = readAeroL2JSON()
        %READAEROL2JSON  The .aerodynamics block of the unified L2 JSON.
            J = jsondecode(fileread(f16a_spec_path(2))).aerodynamics;
        end
    end

    methods (Test)

        % ================================================================== %
        % Cfe is a cited table lookup, not an input (Phase 3, 2026-07-25).
        % ================================================================== %

        function testCfeComesFromTheRaymerTableNotTheJSON(tc)
            % Cfe was a stored .aerodynamics input. A published table constant is
            % not a design variable, and holding it as an input invited tuning it:
            % the 0.005908 value was used to force CD0 onto
            % Brandt's mission polar -- the back-calculated-value-as-input pattern
            % PLAN.md forbids. It is now Dependent on aircraft_category.
            %
            % Expected values transcribed from the repo's own reference extract
            % docs/reference_extracts/raymer_data.md:82
            % (Raymer 6th ed. Table 12.3, PDF p.447), corroborated by
            % metabook_data.md:118 -- both extracts agree on all ten rows.
            a = TestAeroL2.makeAero();
            tc.verifyEqual(a.Cfe, 0.0035, 'AbsTol', 1e-12, ...
                'F-16A is an Air Force fighter: Raymer Table 12.3 gives Cfe = 0.0035.');
            tc.verifyError(@() setfield(a, 'Cfe', 0.005908), ...
                'MATLAB:class:noSetMethod', ...
                'Cfe must be read-only -- it is a table value, not something to tune.'); %#ok<SFLD>
            % Spot-check rows other than the F-16's, so a future edit to the
            % table is caught rather than silently accepted.
            tc.verifyEqual(AeroL2.lookup_Cfe("navy_fighter"),          0.0040, 'AbsTol', 1e-12);
            tc.verifyEqual(AeroL2.lookup_Cfe("bomber"),                0.0030, 'AbsTol', 1e-12);
            tc.verifyEqual(AeroL2.lookup_Cfe("civil_transport"),       0.0026, 'AbsTol', 1e-12);
            tc.verifyEqual(AeroL2.lookup_Cfe("supersonic_cruise"),     0.0025, 'AbsTol', 1e-12);
            tc.verifyEqual(AeroL2.lookup_Cfe("light_aircraft_single"), 0.0055, 'AbsTol', 1e-12);
            tc.verifyEqual(AeroL2.lookup_Cfe("prop_seaplane"),         0.0065, 'AbsTol', 1e-12);
            tc.verifyError(@() AeroL2.lookup_Cfe("dirigible"), ...
                'AeroL2:unknownAircraftCategory');
        end

        % ================================================================== %
        % Oswald efficiency (Raymer Eq. 12.48 / 12.49, branch on Lambda_LE)
        % ================================================================== %

        function testOswaldEffEq1249Swept(tc)
            % Lambda_LE=40 (>=30) -> Eq. 12.49, AR=3 (genuine F16 spec):
            %   e = 4.61*(1-0.045*3^0.68)*cos(40)^0.15 - 3.1
            %   3^0.68 = 2.1107775 ; 0.045*2.1107775 = 0.0949850 ; 1-... = 0.9050150
            %   cos(40)^0.15 = 0.766044^0.15 = 0.9608113
            %   e = 4.61*0.9050150*0.9608113 - 3.1 = 4.0086192 - 3.1 = 0.9086192
            tc.verifyEqual(AeroL2.oswald_eff(3, 40), 0.9086192166, 'RelTol', 1e-4);
        end

        function testOswaldEffEq1248Unswept(tc)
            % Independently chosen unswept case Lambda_LE=10 (<30), AR=8 ->
            % Eq. 12.48:  e = 1.78*(1-0.045*8^0.68) - 0.64
            %   8^0.68 = 4.1124553 ; 0.045*4.1124553 = 0.1850605 ; 1-... = 0.8149395
            %   e = 1.78*0.8149395 - 0.64 = 1.4505923 - 0.64 = 0.8105923
            % (verifies the Eq.12.48 branch is selected for Lambda_LE < 30.)
            tc.verifyEqual(AeroL2.oswald_eff(8, 10), 0.8105923299, 'RelTol', 1e-4);
        end

        function testGetEoswReadsInjectedGeometry(tc)
            % F16AeroL2.get_e_osw must return the Eq.12.49 value for the
            % injected AR=3, Lambda_LE=40 -> 0.9086192 (same hand value above).
            % Confirms the JSON->geom->aero pipeline uses the official method.
            a = TestAeroL2.makeAero();
            tc.verifyEqual(a.get_e_osw(), 0.9086192166, 'RelTol', 1e-4);
        end

        function testUnknownEMethodThrows(tc)
            % A bogus e_method must error (only "official" is defined).
            a = TestAeroL2.makeAero();
            a.e_method = "bogus";
            tc.verifyError(@() a.get_e_osw(), 'AeroL2:unknownEMethod');
        end

        % ================================================================== %
        % Induced factor K1 (Raymer Eq. 12.50 subsonic / Eq. 12.51 supersonic)
        % ================================================================== %

        function testK1SubsonicFormula(tc)
            % K1 = 1/(pi*AR*e). Independent inputs e=0.85, AR=8:
            %   1/(pi*8*0.85) = 1/21.36283 = 0.04681028
            tc.verifyEqual(AeroL2.K1_subsonic(0.85, 8), 0.0468102774, 'RelTol', 1e-4);
        end

        function testK1SupersonicFormula(tc)
            % Eq. 12.51: K1 = AR*(M^2-1)*cos(L_LE)/(4*AR*beta-2), beta=sqrt(M^2-1).
            % M=1.5, AR=3, L_LE=40:
            %   beta = sqrt(1.25) = 1.1180340
            %   num  = 3*1.25*cos(40) = 3.75*0.766044 = 2.8726657
            %   den  = 4*3*1.1180340 - 2 = 13.416408 - 2 = 11.416408
            %   K1   = 2.8726657/11.416408 = 0.2516261
            tc.verifyEqual(AeroL2.K1_supersonic(1.5, 3, 40), 0.2516261416, 'RelTol', 1e-4);
        end

        function testK1SupersonicRejectsSubsonicMach(tc)
            % Guard: calling the supersonic branch at M<=1 must error.
            tc.verifyError(@() AeroL2.K1_supersonic(0.8, 3, 40), 'AeroL2:subsonicMach');
        end

        function testGetK1TransonicThrows(tc)
            % get_K1 is undefined in the transonic band (avoids the Eq.12.51
            % pole) -- must error (drag_polar returns the NaN signal instead).
            a = TestAeroL2.makeAero();
            tc.verifyError(@() a.get_K1(1.0), 'AeroL2:transonicNotModeled');
        end

        % ================================================================== %
        % Camber offset K2 (Convention A: CD = CD0 + K1*CL^2 + K2*CL)
        % ================================================================== %

        function testCLminDFormula(tc)
            % CL_minD = CL_alpha*(-deg2rad(alpha_L0)/2). Independent inputs
            % CL_alpha=3.0/rad, alpha_L0=-1.5 deg:
            %   -deg2rad(-1.5)/2 = deg2rad(1.5)/2 = 0.02617994/2 = 0.01308997
            %   CL_minD = 3.0*0.01308997 = 0.03926991
            tc.verifyEqual(AeroL2.compute_CL_minD(3.0, -1.5), 0.0392699082, 'RelTol', 1e-4);
        end

        function testK2ValueSubsonic(tc)
            % K2 = -2*K1_sub*CL_minD (M<1). Independent K1_sub=0.117,
            % CL_minD=0.05, M=0.6:  -2*0.117*0.05 = -0.0117
            tc.verifyEqual(AeroL2.K2_value(0.117, 0.05, 0.6), -0.0117, 'RelTol', 1e-4);
        end

        function testK2ValueSupersonicIsZero(tc)
            % K2 = 0 for all M>=1 (linearized supersonic theory), regardless
            % of CL_minD.
            tc.verifyEqual(AeroL2.K2_value(0.117, 0.20, 1.2), 0, 'AbsTol', 1e-12);
        end

        function testGetK2NegativeForCamberedF16(tc)
            % The F16's cambered 64A204 (alpha_L0 = -1.33 deg) gives CL_minD>0,
            % so subsonic K2 = -2*K1*CL_minD is strictly NEGATIVE (sign check;
            % the magnitude depends on the M-dependent CL_alpha).
            a  = TestAeroL2.makeAero();
            k1 = a.get_K1(0.6);
            tc.verifyLessThan(a.get_K2(k1, 0.6), 0, ...
                'Cambered F16 airfoil must give a negative subsonic K2.');
        end

        % ================================================================== %
        % Finite-wing lift-curve slope (Raymer Eq. 12.6)
        % ================================================================== %

        function testCLalphaFormula(tc)
            % Eq. 12.6 with the default eta=0.95 (no 2-D slope), no fuselage
            % factor. Independent inputs AR=8, Lambda_c/4=25 deg, M=0.5:
            %   beta = sqrt(1-0.25) = 0.8660254
            %   AR*beta/eta = 8*0.8660254/0.95 = 7.2928455
            %   tan(25)^2/beta^2 = 0.4663077^2/0.75 = 0.2174429/0.75 = 0.2899238
            %   radicand = 4 + 7.2928455^2*(1+0.2899238) = 4 + 68.6053643 = 72.6053643
            %   sqrt = 8.5208781
            %   CL_a = 2*pi*8/(2 + 8.5208781) = 50.265482/10.5208781 = 4.7776889
            tc.verifyEqual(AeroL2.CL_alpha(8, 25, 0.5), 4.7776888765, 'RelTol', 1e-4);
        end

        function testCLalphaClampsSupersonicMach(tc)
            % Eq. 12.6 is subsonic; M is clamped to 0.99 internally, so
            % CL_alpha(...,1.5) must equal CL_alpha(...,0.99) (no crash, no
            % imaginary beta).
            v_super = AeroL2.CL_alpha(3, 32, 1.5);
            v_clamp = AeroL2.CL_alpha(3, 32, 0.99);
            tc.verifyEqual(v_super, v_clamp, 'RelTol', 1e-4);
            tc.verifyTrue(isreal(v_super) && isfinite(v_super));
        end

        % ================================================================== %
        % Clean CLmax (Raymer Eq. 12.15)
        % ================================================================== %

        function testCLmaxCleanFormula(tc)
            % CLmax = 0.9*cl_max_2D*cos(Lambda_c/4). Independent inputs
            % cl_max_2D=1.5, Lambda_c/4=30 deg:
            %   0.9*1.5*cos(30) = 1.35*0.8660254 = 1.1691343
            tc.verifyEqual(AeroL2.CLmax_clean(1.5, 30), 1.1691342951, 'RelTol', 1e-4);
        end

        function testGetCLmaxUsesGeometryQuarterChordSweep(tc)
            % F16AeroL2.get_CLmax uses the genuine cl_max_2D=1.20 and the
            % geometry-DERIVED quarter-chord sweep 32.1831783983 deg (NOT the
            % old hardcoded 37 deg). Hand-computed:
            %   0.9*1.20*cos(32.1831783983) = 1.08*0.846349 = 0.9140575
            % (cos(32.1831784) = 0.8463496.) Guards the sweep-source bug fix.
            a = TestAeroL2.makeAero();
            tc.verifyEqual(a.get_CLmax([]), 0.9140575443, 'RelTol', 1e-4);
        end

        % ================================================================== %
        % Subsonic CD0 (Raymer Eq. 12.23) -- primitive + DI wiring
        % ================================================================== %

        function testCD0FromCfFormula(tc)
            % CD0 = Cf*S_wet/S_ref. Independent inputs Cf=0.0035, S_wet=1470,
            % S_ref=300:  0.0035*1470/300 = 5.145/300 = 0.017150
            tc.verifyEqual(AeroL2.CD0_from_Cf(0.0035, 1470, 300), 0.017150, 'RelTol', 1e-4);
        end

        function testCD0FromCfGuardsZeroSref(tc)
            % S_ref is a division denominator -> mustBePositive guard.
            tc.verifyError(@() AeroL2.CD0_from_Cf(0.0035, 1470, 0), ...
                'MATLAB:validators:mustBePositive');
        end

        function testGetCD0UsesInjectedSwetSref(tc)
            % DI wiring: get_CD0 must equal Cfe*(injected S_wet)/(injected
            % S_ref) with NO hardcoded S_wet (the historical S_wet=1371 bug).
            % Verifies the operands are wired from the live geometry object,
            % not frozen literals. The NUMERIC value of S_wet is verified
            % independently in TestGeomL2, not re-derived here.
            a = TestAeroL2.makeAero();
            tc.verifyEqual(a.get_CD0(), a.Cfe * a.S_wet / a.S_ref, 'RelTol', 1e-12);
            % ...and it must NOT be the old hardcoded S_wet=1371 result:
            tc.verifyNotEqual(round(a.S_wet, 0), 1371, ...
                'S_wet must be the live geometry value, not the Brandt back-calc 1371.');
        end

        function testSupersonicCD0IsPositiveFinite(tc)
            % The GENERIC AeroL2.get_CD0_supersonic toolbox static is skin
            % friction only (no wave drag -- see its own header); F16AeroL2
            % overrides drag_polar's supersonic branch to add Brandt's own
            % wave-drag term on top (see testSupersonicCD0ExceedsSubsonic and
            % testComputeCD0WaveMatchesBrandtFormula below), so a.drag_polar
            % here exercises the F-16-specific path, not the bare toolbox one.
            % Just check it is a positive finite number at M=1.5.
            a     = TestAeroL2.makeAero();
            polar = a.drag_polar(AircraftState(0, 1.5));
            tc.verifyTrue(isfinite(polar.CD0) && polar.CD0 > 0);
        end

        % ================================================================== %
        % F-16-specific supersonic wave drag (F16AeroL2, added 2026-07-29)
        % ================================================================== %

        function testComputeCD0WaveMatchesBrandtFormula(tc)
            % CD0_wave = (4.5*pi/S_ref)*(Amax/L_aircraft)^2 * E_WD
            %            * (0.74 + 0.37*cos(Lambda_LE)) * [1 - 0.3*sqrt(M - M_CD0max)]
            % M_CD0max = (1/cos(Lambda_LE))^0.2   [Brandt F-16A.xls Aero!B8/G8]
            % Using the F-16's genuine live spec/geometry values (Amax=27.4889
            % [fuselage-envelope ellipse, F16GeomL2], L_aircraft=47.65, S_ref=300,
            % E_WD=2.2, Lambda_LE=40 deg) at M=1.6:
            %   M_CD0max = (1/cos(40))^0.2 = (1/0.7660444)^0.2 = 1.0547395
            %   Dq_SH = 4.5*pi*(27.4889357/47.65)^2 = 14.137167*0.33266322 = 4.70290...
            %   CD0_wave = (4.70290.../300)*2.2*(0.74+0.37*0.7660444)*(1-0.3*sqrt(1.6-1.0547395))
            %            = 0.01567633*2.2*1.02344643*0.77841... = 0.0274891 (see RelTol)
            a  = TestAeroL2.makeAero();
            st = AircraftState(0, 1.6);
            M_CD0max = (1/cosd(a.Lambda_LE_deg))^0.2;
            Dq_SH    = 4.5*pi*(a.Amax_ft2/a.L_aircraft_ft)^2;
            expected = (Dq_SH/a.S_ref) * a.E_WD * (0.74 + 0.37*cosd(a.Lambda_LE_deg)) ...
                * (1 - 0.3*sqrt(1.6 - M_CD0max));
            tc.verifyEqual(a.compute_CD0_wave(st), expected, 'RelTol', 1e-10);
            tc.verifyEqual(a.compute_CD0_wave(st), 0.0274890893, 'RelTol', 1e-6);
        end

        function testSupersonicCD0ExceedsSubsonic(tc)
            % Physical sanity the pre-fix code violated: supersonic CD0 (wave
            % drag added) must exceed the subsonic CD0 at the same aircraft,
            % never read BELOW it. Guards the exact regression the 2026-07-29
            % investigation found (Max Mach CD0 was 0.00787, below the
            % subsonic 0.01711 -- backwards).
            a = TestAeroL2.makeAero();
            cd0_sub = a.drag_polar(AircraftState(0, 0.8)).CD0;
            cd0_sup = a.drag_polar(AircraftState(0, 1.6)).CD0;
            tc.verifyGreaterThan(cd0_sup, cd0_sub);
        end

        function testCD0WaveClampedBelowMCD0max(tc)
            % M_CD0max = 1.0547395 for Lambda_LE=40 deg. Just above
            % MACH_SUPERSONIC_MIN (1.05) but below M_CD0max, the sqrt argument
            % would be negative; compute_CD0_wave must clamp it to 0 (a flat
            % wave-drag-onset plateau) rather than return a complex/NaN value.
            a = TestAeroL2.makeAero();
            val = a.compute_CD0_wave(AircraftState(0, 1.06));
            tc.verifyTrue(isreal(val) && isfinite(val));
        end

        % ================================================================== %
        % Transonic guard (mandatory): drag_polar returns NaN, no crash
        % ================================================================== %

        function testDragPolarTransonicReturnsNaN(tc)
            % In the un-modeled transonic band (M=1.0) drag_polar returns NaN
            % for CD0/K1/K2 (Eq.12.51 pole near M=1) rather than crashing.
            a = TestAeroL2.makeAero();
            w = warning('off', 'AeroL2:transonicNotModeled');
            cleanup = onCleanup(@() warning(w)); %#ok<NASGU>
            polar = a.drag_polar(AircraftState(0, 1.0));
            tc.verifyTrue(isnan(polar.CD0));
            tc.verifyTrue(isnan(polar.K1));
            tc.verifyTrue(isnan(polar.K2));
        end

        function testDragPolarTransonicWarns(tc)
            % The transonic branch must WARN (not silently NaN).
            a = TestAeroL2.makeAero();
            tc.verifyWarning(@() a.drag_polar(AircraftState(0, 1.0)), ...
                'AeroL2:transonicNotModeled');
        end

        function testDragPolarSubsonicFiniteK2Negative(tc)
            % Subsonic (M=0.6): all coefficients finite/real, and the cambered
            % K2 is negative (sign contract).
            a     = TestAeroL2.makeAero();
            polar = a.drag_polar(AircraftState(0, 0.6));
            tc.verifyTrue(all(isfinite([polar.CD0, polar.K1, polar.K2])));
            tc.verifyLessThan(polar.K2, 0);
        end

        function testDragPolarSupersonicK2Zero(tc)
            % Supersonic (M=1.5): K2 = 0 (linearized theory).
            a     = TestAeroL2.makeAero();
            polar = a.drag_polar(AircraftState(0, 1.5));
            tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12);
        end

        % ================================================================== %
        % Optimization-ready DI guards (mirror TestGeomL2)
        % ================================================================== %

        function testDerivedTracksMutatedGeometryLiveOnRead(tc)
            % LIVE-RECOMPUTE: read a derived aero value, mutate the injected
            % geometry input IN PLACE, and confirm the derived value tracks the
            % change with NO reconstruction (the behavior a downstream
            % optimizer depends on).
            a   = TestAeroL2.makeAero();
            AR0 = a.AR;               % Dependent, reads geom.AR_wing
            k0  = a.get_K1(0.6);      % depends on AR and e(AR)
            a.geom.AR_wing = a.geom.AR_wing + 1;   % optimizer-style mutation
            tc.verifyEqual(a.AR, AR0 + 1, 'AbsTol', 1e-12, ...
                'a.AR must track the mutated injected geom.AR_wing live.');
            tc.verifyNotEqual(a.get_K1(0.6), k0, ...
                'K1 must change after the injected AR is mutated (no stale cache).');
        end

        function testDerivedPropertiesAreReadOnly(tc)
            % Derived (Dependent) aero properties are outputs: assigning to one
            % must error 'MATLAB:class:noSetMethod' (nothing can overwrite a
            % live-computed value with a frozen literal).
            a = TestAeroL2.makeAero();
            tc.verifyError(@() setfield(a, 'AR', 5),            'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(a, 'S_wet', 1371),      'MATLAB:class:noSetMethod'); %#ok<SFLD>
            tc.verifyError(@() setfield(a, 'Lambda_c4_deg', 37),'MATLAB:class:noSetMethod'); %#ok<SFLD>
        end

        function testGeometryInjectionRejectsWrongTierAtConstruction(tc)
            % PHASE-2 NARROWED GUARD (2026-07-25). The constructor's geometry
            % argument used to be validated as `geom (1,1) GeometryBase`, which
            % declares only S_ref/S_wet/get_S_ref/get_S_wet -- far less than the
            % ~7 members this class reads off obj.geom. An F16GeomL1 (whose
            % S_wet is a TOGW regression, not a planform, and which has no
            % QC_sweep_wing/lambda_wing/L_fus at all) therefore CONSTRUCTED
            % CLEANLY and only misbehaved later, at first use. The guard is now
            % mustBeA(geom, ["GeometryModelL2","GeometryModelL3"]), so a wrong
            % tier must fail HERE, at construction.
            g1 = F16GeomL1(f16a_spec_path(1), f16a_requirements_path());
            tc.verifyError(@() F16AeroL2(g1, f16a_spec_path(2), f16a_control_surfaces()), ...
                'MATLAB:validators:mustBeA', ...
                'An L1 geometry object must be rejected at F16AeroL2 construction.');
            % Positive control: both accepted tiers still construct.
            tc.verifyClass(F16AeroL2(F16GeomL2(f16a_spec_path(2), F16PropL2(f16a_spec_path(2))), ...
                f16a_spec_path(2), f16a_control_surfaces()), 'F16AeroL2');
            tc.verifyClass(F16AeroL2(F16GeomL3(f16a_spec_path(3), F16PropL2(f16a_spec_path(2))), ...
                f16a_spec_path(2), f16a_control_surfaces()), 'F16AeroL2');
        end

        % ================================================================== %
        % High-lift-device deltas -- ordering/sign only (formulas are
        % geometry-driven; exact magnitudes are report items, not unit checks)
        % ================================================================== %

        function testDeltaCLmaxFlapOrdered(tc)
            % Landing uses 80% of Table 12.2's Delta_cl_max vs 60% at takeoff
            % (Raymer Eq. 12.21) -> both positive, landing > takeoff.
            a = TestAeroL2.makeAero();
            tc.verifyGreaterThan(a.get_Delta_CLmax_TO(), 0);
            tc.verifyGreaterThan(a.get_Delta_CLmax_L(), a.get_Delta_CLmax_TO());
        end

        function testDeltaCD0FlapOrdered(tc)
            % Larger landing flap deflection -> larger parasite increment
            % (Raymer Eq. 12.61, linear in delta-10).
            a = TestAeroL2.makeAero();
            tc.verifyGreaterThan(a.get_Delta_CD0_TO(), 0);
            tc.verifyGreaterThan(a.get_Delta_CD0_L(), a.get_Delta_CD0_TO());
        end

        function testLookupDeltaClMaxWarnsOnUnrecognizedConfig(tc)
        % A config string that is not takeoff/TO or landing/L must warn
        % loudly, not silently fall through to the full, undiminished value
        % (per Casey's direction: "have the code scream a warning").
            received = tc.verifyWarning(@() AeroL2.lookup_Delta_cl_max_values('slotted', 'Takeoff', 1.0), ...
                'AeroL2:unrecognizedConfig', ...
                'A typo''d config string must trigger a loud warning, not a silent guess.');
            tc.verifyEqual(received, 1.3, ...
                'The unrecognized-config fallback must still be the full, undiminished value.');
        end

        % ================================================================== %
        % Inheritance / interface compliance
        % ================================================================== %

        function testIsaAerodynamicsBase(tc)
            tc.verifyTrue(isa(TestAeroL2.makeAero(), 'AerodynamicsBase'));
        end

        function testIsaAeroModelL2(tc)
            tc.verifyTrue(isa(TestAeroL2.makeAero(), 'AeroModelL2'));
        end

        function testNotIsaAeroModelL1(tc)
            tc.verifyFalse(isa(TestAeroL2.makeAero(), 'AeroModelL1'));
        end

        function testIsHandleClass(tc)
            tc.verifyTrue(isa(TestAeroL2.makeAero(), 'handle'));
        end

        % ================================================================== %
        % DELIBERATELY-FAILING TODO (unverified citations) -- see header.
        % ================================================================== %

        function testAlphaL0MatchesCitedValue(tc)
        % RETIRED as a testTODO_ 2026-07-30: alpha_L0 is now cited (a
        % compiled NACA 64A204 data summary, web-sourced, corroborated by
        % two independent searches -- see f16a_L2.json's _cite_alpha_L0_deg
        % for the honest caveat that primary 64A204 wind-tunnel data is
        % scarce). Per this repo's convention (see TestWeightsL2's retired
        % testTODO_PureAreaDerivedShouldNotRequireWTO), a satisfied TODO
        % guard is deleted, not kept as an always-green no-op -- this is a
        % real assertion on the new value instead.
            J = TestAeroL2.readAeroL2JSON();
            tc.verifyEqual(J.airfoil.alpha_L0_deg, -1.33, 'AbsTol', 1e-9, ...
                'alpha_L0 must match the cited NACA 64A204 value, -1.33 deg.');
        end

        function testTODO_ClMax2DUnverified(tc)
            % cl_max_2D = 1.20 (Abbott and von Doenhoff) conflicts with NTRS-
            % 19870017427's 1.0 for the same thin (4%) 64A204 section.
            % f16a_L2.json's .aerodynamics still carries "_TODO_cl_max_2D". FAILS until
            % reconciled to one primary-sourced value.
            J = TestAeroL2.readAeroL2JSON();
            tc.verifyFalse(isfield(J.airfoil, 'x_TODO_cl_max_2D'), ...
                'TODO: cl_max_2D 1.20 vs NTRS 1.0 for NACA 64A204 unreconciled.');
        end

        function testTODO_ClAlpha2DUnverified(tc)
            % cl_alpha_2D = 0.105/deg is an internet midpoint estimate (0.10-
            % 0.11 band), not a primary/repo-pinned 64A204 lift slope.
            % f16a_L2.json's .aerodynamics still carries "_TODO_cl_alpha_per_deg".
            J = TestAeroL2.readAeroL2JSON();
            tc.verifyFalse(isfield(J.airfoil, 'x_TODO_cl_alpha_per_deg'), ...
                'TODO: NACA 64A204 2-D lift slope (0.105/deg) is an unpinned estimate.');
        end

        function testTODO_EWDCalibrationInput(tc)
            % E_WD = 2.2 is a TUNED wave-drag multiplier back-checked to
            % Brandt/Casey, NOT a measured F-16 datum (same status as
            % F16AeroL3's identical E_WD -- TestAeroL3.testTODO_EWDCalibrationInput).
            % f16a_L2.json's .aerodynamics still carries
            % "_TODO_wave_drag_factor_E_WD". FAILS until it is either sourced
            % or explicitly accepted as a calibration knob.
            J = TestAeroL2.readAeroL2JSON();
            tc.verifyFalse(isfield(J, 'x_TODO_wave_drag_factor_E_WD'), ...
                'TODO: E_WD=2.2 is a tuned calibration input, not a spec value.');
        end

    end
end
