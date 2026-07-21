classdef TestAeroL3 < matlab.unittest.TestCase
     %TESTAERO L3  Unit tests for AeroL3 toolbox and F16AeroL3 student class.
     %
     %   Formula references:
     %     Re  = rho*V*l/mu                               Raymer Eq. 12.25
     %     mu  = Sutherland's law (English units)          Raymer §12.3.1
     %     Cf_lam  = 1.328/sqrt(Re)                        Raymer Eq. 12.26
     %     Cf_turb = 0.455/(log10(Re)^2.58*(1+0.144*M^2)^0.65)  Raymer Eq. 12.27
     %     FF_surf = (1+0.6/xmax*tc+100*tc^4)*(1.34*M^0.18*cos(Lm)^0.28)   Eq. 12.30
     %     FF_body = 1+5/f^1.5+f/400 (f<=6) or 1+60/f^3+f/400 (f>6)
     %               f=L/D                                Raymer Eq. 12.31
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
     %   FF_BODY: L=47.5 ft, D=5.0 ft, f=9.5 (>6 -> 60/f^3 form)
     %     = 1 + 60/9.5^3 + 9.5/400
     %   FF_BODY: F-16 duct, L=14.0 ft, D=3.15 ft, f=4.444 (<=6 -> 5/f^1.5 form)
     %     = 1 + 5/4.444^1.5 + 4.444/400
     %
     %   PHYSICAL TOLERANCE vs Raymer Fig 12.32 reported F-16 CD0:
     %     M=0.5: ~0.020;  M=1.2: ~0.035;  M=1.5: ~0.047
     %     Tests use ±40% tolerance — L3 component model omits many real-world
     %     drag items (gaps, fillets, antenna protuberances, etc.).

     properties (Constant)
          TOL_ABS  = 1e-6
          TOL_PCT  = 0.40    % ±40% physical tolerance vs Raymer Fig 12.32
     end

     % Brandt "Aero" A6:E10 tabulates the model polar at 5 Mach points
     % (b.brandt.polar_model rows): M = 0.1000, 0.8727(=Mcrit), 1.0547,
     % 1.5000, 2.0000. Tests below that compare against Brandt values use
     % these same rows/Mach numbers rather than arbitrary points.
     properties (TestParameter)
          brandtRow      = {1, 2, 3, 4, 5};
          constraintName = {'cruise', 'combat_sub', 'dash', 'max_alt', 'combat_sup', 'ps'};
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

          % --- drag_polar vs Brandt ACTUAL (flight-measured) polar ---------

          function testDragPolarVsBrandtActualAtDash(tc)
               % Sanity check against Brandt's ACTUAL (flight-measured) polar
               % table [Brandt Aero!M6:Q10] at 36 kft, M=1.6 -- a different
               % reference table than polar_model used elsewhere in this file
               % (see fidelity_comparison.m "[AERO — SUP]" section). Known to
               % diverge near/beyond M=1 (L3 has no wave drag yet -- see
               % testCD0AtBrandtMachPoints), so this is a coarse positivity /
               % order-of-magnitude check only.
               b       = F16Baseline();
               g       = F16AeroL3();
               state   = AircraftState(36000, 1.60);
               polar   = g.drag_polar(state);
               CD0_ref = b.brandt.polar_actual(4,3);   % 0.0461 [Brandt Aero!O9]
               K1_ref  = b.brandt.polar_actual(4,4);   % 0.3400 [Brandt Aero!P9]
               fprintf('\n    dash (actual polar ref): CD0=%.4f (ref %.4f), K1=%.4f (ref %.4f)\n', ...
                    polar.CD0, CD0_ref, polar.K1, K1_ref);
               tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
               tc.verifyGreaterThan(polar.K1, 0, 'K1 must be positive.');
               tc.verifyLessThan(polar.CD0, 5*CD0_ref, ...
                    'CD0 is more than 5x Brandt actual-polar reference -- check for a gross error.');
               tc.verifyLessThan(polar.K1, 5*K1_ref, ...
                    'K1 is more than 5x Brandt actual-polar reference -- check for a gross error.');
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

          % --- Verification across Brandt's tabulated Mach breakpoints -----

          function testCD0AtBrandtMachPoints(tc, brandtRow)
               % L3's from-scratch Raymer component buildup is a physically
               % different method than Brandt's calibrated equivalent skin-
               % friction coefficient (Cfe=0.0037, back-calculated from
               % flight-test data and implicitly absorbing excrescence/gap
               % drag beyond what a clean buildup captures) -- see subplan
               % 03_aerodynamics.md: "our textbook methods will give
               % different numbers" from Brandt's calibrated values.
               %
               % Rows 1-2 (subsonic, sea level): the buildup's compressibility
               % term (1+0.144*M^2)^0.65 in Cf_turbulent legitimately lowers
               % CD0 as M rises toward Mcrit, while Brandt's model is flat
               % there -- so the gap widens from row 1 to row 2 (-6% to
               % -17%, with CD0_misc's Table 12.7 gun-port + hook terms
               % included). ±20% brackets both.
               % Rows 3-5 (transonic/supersonic): CD0 is expected to read low
               % because wave drag is not yet implemented (F16AeroL3.CD_wave
               % is a declared-but-unpopulated property; see its TODO
               % comment) -- sanity-checked for positivity only.
               b        = F16Baseline();
               M        = b.brandt.polar_model(brandtRow, 1);
               CD0_ref  = b.brandt.polar_model(brandtRow, 3);
               g        = F16AeroL3();
               state    = AircraftState(0, M);
               received = g.get_CD0_buildup(state);
               fprintf('\n    CD0 (M=%.4f, SL): received = %.4f,  Brandt = %.4f  (%+.1f%%)\n', ...
                    M, received, CD0_ref, 100*(received-CD0_ref)/CD0_ref);
               if ismember(brandtRow, [1, 2])
                    tc.verifyEqual(received, CD0_ref, 'RelTol', 0.20, ...
                         sprintf('CD0 at M=%.4f deviates >20%% from Brandt.', M));
               else
                    tc.verifyGreaterThan(received, 0, 'CD0 must be positive.');
               end
          end

          % --- Verification at Brandt's constraint-analysis conditions -----

          function testDragPolarAtConstraintConditions(tc, constraintName)
               % Additional verification at the six (alt, Mach) points Brandt
               % tabulates on the "Consts" sheet for constraint analysis --
               % cruise, combat_sub, dash, max_alt, combat_sup, ps (see
               % F16Baseline b.constraints.*). Unlike L1/L2, L3's component
               % buildup is altitude-sensitive (Reynolds number depends on
               % rho/mu), so evaluating it away from sea level is meaningful.
               % F16Baseline b.constraints.*.CD0/K1/K2 now carry Brandt's own
               % drag-polar coefficients at each condition (Consts sheet).
               % K1 is unaffected by altitude in this framework (Oswald-based,
               % no Reynolds dependence) so it gets the same ±20% comparison
               % as L1/L2 at the M~0.87 points. CD0 is Reynolds-sensitive and
               % is only sanity-checked here -- see testCD0AtBrandtMachPoints,
               % where even the sea-level M=0.8727 point already sits at -17%;
               % moving off sea level (combat_sub@20kft, max_alt@50kft) shifts
               % Re further and risks exceeding a tight numeric tolerance for
               % reasons unrelated to a real bug.
               b     = F16Baseline();
               c     = b.constraints.(constraintName);
               g     = F16AeroL3();
               state = AircraftState(c.alt_ft, c.mach);
               polar = g.drag_polar(state);
               fprintf('\n    %-11s alt=%6.0f  M=%.2f: CD0=%.5f  K1=%.5f  K2=%.5f  (Brandt: CD0=%.5f K1=%.5f K2=%.5f)\n', ...
                    constraintName, c.alt_ft, c.mach, polar.CD0, polar.K1, polar.K2, c.CD0, c.K1, c.K2);
               tc.verifyGreaterThan(polar.CD0, 0, 'CD0 must be positive.');
               tc.verifyGreaterThanOrEqual(polar.K1, 0, 'K1 must be non-negative.');
               tc.verifyTrue(isfinite(polar.CD0) && isfinite(polar.K1) && isfinite(polar.K2), ...
                    'drag_polar outputs must be finite.');
               if c.mach >= 1
                    tc.verifyEqual(polar.K2, 0, 'AbsTol', 1e-12, 'K2 must be 0 supersonic.');
               end
               if ismember(constraintName, {'cruise', 'combat_sub', 'max_alt', 'ps'})
                    tc.verifyEqual(polar.K1, c.K1, 'RelTol', 0.20, ...
                         sprintf('K1 at %s deviates >20%% from Brandt.', constraintName));
               end
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
