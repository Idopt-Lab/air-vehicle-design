classdef TestAeroL3 < matlab.unittest.TestCase
     %TESTAERO L3  Unit tests for AeroL3 toolbox and F16AeroL3 student class.
     %
     %   Formula references:
     %     Re  = rho*V*l/mu                               Raymer Eq. 12.25
     %     mu  = Sutherland's law (English units)          Raymer §12.3.1
     %     Cf_lam  = 1.328/sqrt(Re)                        Raymer Eq. 12.26
     %     Cf_turb = 0.455/(log10(Re)^2.58*(1+0.144*M^2)^0.65)  Raymer Eq. 12.27
     %     FF_surf = (1+0.6/xmax*tc+100*tc^4)*(1.34*M^0.18*cos(Lm)^0.28)   Eq. 12.30
     %     FF_body = 1+5/f^1.5+f/400, f=L/D              (user-modified Eq. 12.31)
     %
     %   Pre-computed values used as expected results:
     %
     %   SUTHERLAND at T=518.67 R (sea level):
     %     mu = 3.737e-7 * 1 * (518.67+198.6)/(518.67+198.6) = 3.737e-7 slug/(ft·s)
     %
     %   CF_LAM at Re=1e6: 1.328/sqrt(1e6) = 1.328/1000 = 0.001328
     %   CF_TURB at Re=1e7, M=0.5:
     %     Cf = 0.455 / (log10(1e7)^2.58 * (1+0.144*0.25)^0.65)
     %        = 0.455 / (7^2.58 * 1.036^0.65)
     %        = 0.455 / (7^2.58 * 1.023)
     %     7^2.58 = exp(2.58*ln7) = exp(2.58*1.9459) = exp(5.020) = 151.4
     %     Cf = 0.455 / (151.4*1.023) = 0.455/154.9 = 0.002937
     %
     %   FF_SURFACE: tc=0.04, x_c_max=0.40, Lambda_m=35 deg, M=0.5
     %     = (1+0.6/0.40*0.04+100*0.04^4)*(1.34*0.5^0.18*cos(35)^0.28)
     %     = (1+0.060+2.56e-4)*1.34*0.8827*0.9458
     %     = 1.0603 * 1.119 = 1.1864
     %
     %   FF_BODY: L=47.5 ft, D=5.0 ft, f=9.5
     %     = 1 + 5/9.5^1.5 + 9.5/400 (user-modified formula)
     %
     %   PHYSICAL TOLERANCE vs Raymer Fig 12.32 reported F-16 CD0:
     %     M=0.5: ~0.020;  M=1.2: ~0.035;  M=1.5: ~0.047
     %     Tests use ±40% tolerance — L3 component model omits many real-world
     %     drag items (gaps, fillets, antenna protuberances, etc.).

     properties (Constant)
          TOL_ABS  = 1e-6
          TOL_PCT  = 0.40    % ±40% physical tolerance vs Raymer Fig 12.32
     end

     % ------------------------------------------------------------------ %
     methods (Test)

          % --- Sutherland viscosity ----------------------------------------

          function testViscosityAtSL(tc)
               % At T=518.67 R (ISA sea level), mu = 3.737e-7 slug/(ft·s).
               expected = 3.737e-7;
               received = AeroL3.dyn_viscosity(518.67);
               fprintf('\n    mu at SL: received = %.4e,  expected = %.4e slug/(ft·s)\n', ...
                    received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', 1e-10, ...
                    'Sutherland mu at SL should equal mu_ref (T=T_ref).');
          end

          function testViscosityIncreasesWithTemp(tc)
               % Sutherland: mu increases with temperature for gases.
               mu_cold = AeroL3.dyn_viscosity(400);    % below std day
               mu_hot  = AeroL3.dyn_viscosity(700);    % above std day
               fprintf('\n    mu(400R)=%.3e  mu(700R)=%.3e  (mu should increase)\n', mu_cold, mu_hot);
               tc.verifyGreaterThan(mu_hot, mu_cold);
          end

          % --- Cf formulas -------------------------------------------------

          function testCfLaminar(tc)
               % Cf_lam = 1.328/sqrt(1e6) = 0.001328
               expected = 1.328 / sqrt(1e6);   % = 0.001328  (Blasius formula is the primary source)
               received = AeroL3.Cf_laminar(1e6);
               fprintf('\n    Cf_lam (Re=1e6): received = %.6f,  expected = %.6f\n', ...
                    received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testCfTurbulent(tc)
               % Cf_turb at Re=1e7, M=0.5:
               % = 0.455/(7^2.58*(1+0.144*0.25)^0.65) = 0.455/(7^2.58*1.023)
               Re = 1e7;  M = 0.5;
               expected = 0.455 / (log10(Re)^2.58 * (1 + 0.144*M^2)^0.65);  % Raymer Eq. 12.27 is the primary source
               % TODO (7/13/2026): Find an empherical number for "expected" value (preferrably a primary source or experimental data)
               received = AeroL3.Cf_turbulent(Re, M);
               fprintf('\n    Cf_turb (Re=1e7, M=0.5): received = %.6f,  expected = %.6f\n', ...
                    received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testCfTurbGreaterThanCfLam(tc)
               % For the same Re, turbulent Cf > laminar Cf.
               Re = 1e7;  M = 0.3;
               tc.verifyGreaterThan(AeroL3.Cf_turbulent(Re, M), AeroL3.Cf_laminar(Re), ...
                    'Turbulent Cf must exceed laminar Cf at same Re.');
          end

          function testCfTurbDecreasesWithRe(tc)
               % Higher Re → lower turbulent Cf (thinner boundary layer).
               Cf_lo = AeroL3.Cf_turbulent(1e6, 0.3);
               Cf_hi = AeroL3.Cf_turbulent(1e8, 0.3);
               fprintf('\n    Cf_turb: Re=1e6 → %.5f,  Re=1e8 → %.5f\n', Cf_lo, Cf_hi);
               tc.verifyGreaterThan(Cf_lo, Cf_hi);
          end

          % --- Form factors ------------------------------------------------

          function testFFSurfaceFormula(tc)
               % tc=0.04, x_c_max=0.40, Lambda_m=35 deg, M=0.5
               % FF = (1+0.6/0.40*0.04+100*0.04^4)*(1.34*0.5^0.18*cos(35)^0.28)
               %    = 1.0603 * 1.119 = 1.1864 (approx)
               tc_val = 0.04;  xcmax = 0.40;  Lm = 35;  M = 0.5;
               expected = (1 + 0.6/xcmax*tc_val + 100*tc_val^4) * ...
                    (1.34 * M^0.18 * cosd(Lm)^0.28);  % Raymer Eq. 12.30 is the primary source
               received = AeroL3.FF_surface(tc_val, xcmax, Lm, M);
               fprintf('\n    FF_surface: received = %.5f,  expected = %.5f\n', received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testFFBodyFormula(tc)
               % F-16 fuselage: L=47.5, D=5.0, f=9.5
               % FF = 1 + 5/9.5^1.5 + 9.5/400
               L = 47.5;  D = 5.0;  f = L/D;
               expected = 1 + 5/f^1.5 + f/400;  % user-modified formula; no independent reference
               % TODO (7/13/2026): Find an empherical number for "expected" value (preferrably a primary source or experimental data)
               received = AeroL3.FF_body(L, D);
               fprintf('\n    FF_body (F-16 fus): received = %.5f,  expected = %.5f\n', received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          function testFFBodySlenderFuselageLow(tc)
               % Very slender body (high fineness ratio): FF approaches 1 + f/400.
               % f=20: FF = 1 + 5/20^1.5 + 20/400
               L = 100;  D = 5.0;   % f=20
               expected = 1 + 5/20^1.5 + 20/400;  % user-modified formula; no independent reference
               % TODO (7/13/2026): Find an empherical number for "expected" value (preferrably a primary source or experimental data)
               received = AeroL3.FF_body(L, D);
               fprintf('\n    FF_body (f=20): received = %.5f,  expected = %.5f\n', received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          % --- Re cutoff ---------------------------------------------------

          function testReCutoffSubsonicFormula(tc)
               % Re_cut = 38.21 * (l/k)^1.053
               % For l=12 ft, k=2.08e-5 ft: l/k = 576923
               % Re_cut = 38.21 * 576923^1.053
               l = 12;  k = 2.08e-5;
               expected = 38.21 * (l/k)^1.053;  % Raymer Eq. 12.28 is the primary source
               % TODO (7/13/2026): Find an empherical number for "expected" value (preferrably a primary source or experimental data)
               received = AeroL3.Re_cutoff_sub(l, k);
               fprintf('\n    Re_cut_sub (l=12ft): received = %.4e,  expected = %.4e\n', ...
                    received, expected);
               tc.verifyEqual(received, expected, 'AbsTol', tc.TOL_ABS);
          end

          % --- Full CD0 buildup (physical range) ---------------------------

          function testCD0PhysicalRangeSL_M05(tc)
               % At sea level, M=0.5: expect CD0 in [0.008, 0.030].
               % Raymer Fig 12.32 reference: 0.020.  Tolerance ±40%.
               g        = F16AeroL3();
               state    = AircraftState(0, 0.5);
               received = g.get_CD0_buildup(state);
               ref      = 0.020;
               lo       = ref * (1 - tc.TOL_PCT);   % 0.012
               hi       = ref * (1 + tc.TOL_PCT);   % 0.028
               fprintf('\n    CD0 (SL, M=0.5): received = %.5f,  Raymer ref = %.3f  (%.1f%%)\n', ...
                    received, ref, 100*(received-ref)/ref);
               fprintf('    tolerance band: [%.4f, %.4f]\n', lo, hi);
               tc.verifyGreaterThan(received, lo, ...
                    sprintf('CD0 %.4f is >40%% below Raymer reference %.3f.', received, ref));
               tc.verifyLessThan(received, hi, ...
                    sprintf('CD0 %.4f is >40%% above Raymer reference %.3f.', received, ref));
          end

          function testDragPolarReturnsStruct(tc)
               g     = F16AeroL3();
               state = AircraftState(0, 0.5);
               polar = g.drag_polar(state);
               tc.verifyTrue(isstruct(polar));
               tc.verifyTrue(isfield(polar,'CD0'));
               tc.verifyTrue(isfield(polar,'K1'));
               tc.verifyTrue(isfield(polar,'K2'));
               fprintf('\n    CD0=%.5f  K1=%.5f  K2=%.5f  (M=0.5 SL)\n', ...
                    polar.CD0, polar.K1, polar.K2);
          end

          function testK2SupersonicZero(tc)
               g     = F16AeroL3();
               state = AircraftState(35000, 1.2);
               polar = g.drag_polar(state);
               tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, ...
                    'K2 must be 0 supersonic.');
          end

          % --- Inheritance / interface compliance --------------------------

          function testIsaAerodynamicsBase(tc)
               g = F16AeroL3();
               tc.verifyTrue(isa(g, 'AerodynamicsBase'));
          end

          function testIsaAeroModelL3(tc)
               g = F16AeroL3();
               tc.verifyTrue(isa(g, 'AeroModelL3'));
          end

          function testNotIsaAeroModelL2(tc)
               g = F16AeroL3();
               tc.verifyFalse(isa(g, 'AeroModelL2'), ...
                    'L3 must NOT inherit from the L2 enforcer.');
          end

          function testIsHandleClass(tc)
               g = F16AeroL3();
               tc.verifyTrue(isa(g, 'handle'));
          end

     end
end
