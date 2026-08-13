classdef SandCL3
%SANDCL3  Level-3 stability & control static toolbox: Raymer 6th ed. Ch. 16
%   Sec. 16.3 longitudinal-static-stability equation set.
%
%   Call as SandCL3.method(...); never instantiated, not in the inheritance
%   chain. F16SandCL3 inherits SandCModelL3 and delegates here.
%
%   Every method below is LEVEL-AGNOSTIC: plain scalar arguments only, never
%   reading tier-level obj state -- exactly like AeroL2.CL_alpha or
%   AeroL1.oswald_eff (the original stability-and-control design's
%   "Fidelity-collapse contingency"). F16SandCL3 reads its injected
%   collaborators' CURRENT state, converts units, and calls these statics;
%   none of that glue lives here.
%
%   SCOPE: longitudinal static stability only, steady level flight. Downwash
%   (d(epsilon)/d(alpha)) is OUT OF SCOPE -- every method that would need it
%   takes it as a REQUIRED argument (dalphah_dalpha / epsilon_deg); F16SandCL3
%   passes 1.0 / 0 explicitly, commented, never a silent default inside this
%   toolbox. Same convention for the tail dynamic-pressure ratio eta_h and
%   the Eq. 16.8/16.9 thrust-correction terms.
%
%   Sources: [Raymer 6th ed.] Aircraft Design: A Conceptual Approach, Ch. 16
%   Sec. 16.3 "Longitudinal Static Stability and Control" (Eqs. 16.8-16.18,
%   16.25), primary-source page read 2026-08-04 (book pp.585-619).
%
%   Companion doc: src/disciplines/stability_control/SandCL3.md

    methods (Static)

        % ================================================================== %
        % Eq. 16.12 -- aerodynamic center, longitudinal location.
        % ================================================================== %

        function y = y_MAC_span(b, lambda)
        %Y_MAC_SPAN  Spanwise station of a lifting surface's MAC, measured
        %   from the centerline [ft]. [Standard linearly-tapered-wing
        %   planform identity -- no single pinned Raymer equation number, the
        %   same citation status as GeometryBase.compute_Amax_elliptical;
        %   matches VnV/BrandtF16A/readme_bsc.md's own "y_MAC" term feeding
        %   its x_MAC = x_LE,r + y_MAC*tan(Lambda_LE) formula]:
        %     y_MAC = (b/6) * (1 + 2*lambda) / (1 + lambda)
        %   b is the FULL span (not semispan).
            arguments
                b      (1,1) double {mustBePositive}
                lambda (1,1) double {mustBeNonnegative}
            end
            y = (b/6) * (1 + 2*lambda) / (1 + lambda);
        end

        function x = x_LE_MAC(x_apex, y_mac, LE_sweep_deg)
        %X_LE_MAC  x-station of the leading edge of a lifting surface's MAC
        %   [ft]. [matches readme_bsc.md's "x_MAC = x_LE,r + y_MAC*tan(Lambda_LE)"]
            arguments
                x_apex       (1,1) double {mustBeReal}
                y_mac        (1,1) double {mustBeReal}
                LE_sweep_deg (1,1) double {mustBeReal}
            end
            x = x_apex + y_mac * tand(LE_sweep_deg);
        end

        function d = delta_x_ac(M)
        %DELTA_X_AC  Wing aerodynamic-center Mach shift, dimensionless
        %   fraction. [Raymer 6th ed. Eq. 16.12 "where" coefficients, p.594 --
        %   all 5 coefficients (0.26/0.4/1.1/2.5/0.112/0.004) primary-source-
        %   confirmed 2026-08-04]:
        %     0                    M < 0.4
        %     0.26*(M-0.4)^2.5     0.4 <= M <= 1.1
        %     0.112 - 0.004*M      M > 1.1
            arguments
                M (1,1) double {mustBeReal, mustBeNonnegative}
            end
            if M < 0.4
                d = 0;
            elseif M <= 1.1
                d = 0.26 * (M - 0.4)^2.5;
            else
                d = 0.112 - 0.004*M;
            end
        end

        function x_ac = x_ac_wing(x_apex, LE_sweep_deg, b, lambda, cbar, S_wing, M)
        %X_AC_WING  Wing aerodynamic-center x-station [ft]. [Raymer 6th ed.
        %   Eq. 16.12]:
        %     x_ac = x_c/4 + Delta_x_ac(M) * sqrt(S_wing)
        %   x_c/4 (the quarter-chord point of the wing MAC, the subsonic
        %   reference position) is built from x_apex/LE_sweep/b/lambda via
        %   y_MAC_span/x_LE_MAC -- matches readme_bsc.md's own x_ac formula
        %   exactly, modulo the Mach-shift term (Brandt's simplified neutral-
        %   point approximation omits it). Hand-checked against Brandt's
        %   live S&C(2) sheet xacW = 25.589 ft (the original stability-and-
        %   control design's "Ground Truth"): this formula, fed
        %   F16GeomL3's own inputs at M<0.4 (Delta_x_ac=0), gives 25.591 ft
        %   (+0.01%) -- strong corroboration despite the different geometry
        %   basis (GeomL3 physical vs. Brandt's own).
            arguments
                x_apex       (1,1) double {mustBeReal}
                LE_sweep_deg (1,1) double {mustBeReal}
                b            (1,1) double {mustBePositive}
                lambda       (1,1) double {mustBeNonnegative}
                cbar         (1,1) double {mustBePositive}
                S_wing       (1,1) double {mustBePositive}
                M            (1,1) double {mustBeReal, mustBeNonnegative}
            end
            y_mac = SandCL3.y_MAC_span(b, lambda);
            x_c4  = SandCL3.x_LE_MAC(x_apex, y_mac, LE_sweep_deg) + 0.25*cbar;
            x_ac  = x_c4 + SandCL3.delta_x_ac(M) * sqrt(S_wing);
        end

        function x_ac = x_ac_surface(x_apex, LE_sweep_deg, b, lambda, cbar)
        %X_AC_SURFACE  Generic lifting-surface quarter-MAC x-station [ft],
        %   WITHOUT the Eq. 16.12 Mach-shift term. Used for the horizontal-
        %   tail aerodynamic center: Eq. 16.12's Delta_x_ac(M) coefficients
        %   are calibrated against the WING's own reference area
        %   (sqrt(S_wing)), and Raymer gives no equivalent correction for a
        %   tail surface -- applying the wing's coefficients to S_ht would be
        %   an uncited extension, not a citable simplification. DOCUMENTED
        %   SIMPLIFICATION (same standard as this discipline's downwash/eta_h
        %   simplifications): the tail AC is taken at its own quarter-MAC
        %   point with no compressibility shift.
            arguments
                x_apex       (1,1) double {mustBeReal}
                LE_sweep_deg (1,1) double {mustBeReal}
                b            (1,1) double {mustBePositive}
                lambda       (1,1) double {mustBeNonnegative}
                cbar         (1,1) double {mustBePositive}
            end
            y_mac = SandCL3.y_MAC_span(b, lambda);
            x_ac  = SandCL3.x_LE_MAC(x_apex, y_mac, LE_sweep_deg) + 0.25*cbar;
        end

        % ================================================================== %
        % Eq. 16.25 -- fuselage pitching-moment-derivative contribution.
        % ================================================================== %

        function val = Cm_alpha_fus_per_deg(K_fus, W_f, L_f, c, S_w)
        %CM_ALPHA_FUS_PER_DEG  Fuselage pitching-moment-derivative
        %   contribution, PER DEGREE exactly as printed in the book.
        %   [Raymer 6th ed. Eq. 16.25, p.603, explicitly labeled "per deg";
        %   K_fus off Fig. 16.14, NACA TR 711]:
        %     Cm_alpha,fus [per deg] = K_fus * W_f^2 * L_f / (c * S_w)
            arguments
                K_fus (1,1) double {mustBeNonnegative}
                W_f   (1,1) double {mustBePositive}
                L_f   (1,1) double {mustBePositive}
                c     (1,1) double {mustBePositive}
                S_w   (1,1) double {mustBePositive}
            end
            val = K_fus * W_f^2 * L_f / (c * S_w);
        end

        function val = Cm_alpha_fus_per_rad(K_fus, W_f, L_f, c, S_w)
        %CM_ALPHA_FUS_PER_RAD  Same term, converted to PER RADIAN for use
        %   inside Eqs. 16.8/16.9 (per-radian throughout). [Raymer 6th ed.
        %   Eq. 16.25's own "per deg" label vs. Eqs. 16.8/16.9's per-radian
        %   convention -- the exact missing x(180/pi) conversion the legacy
        %   temp_Casey SandCLevel3.compute_cm_alpha_fuselage never applies.]
            val = SandCL3.Cm_alpha_fus_per_deg(K_fus, W_f, L_f, c, S_w) * (180/pi);
        end

        % ================================================================== %
        % Tail lift-curve slope -- reused from the Aero toolbox, not
        % re-derived (the original stability-and-control design's "Eqs. 16.13/
        % 16.14/16.15 stay in scope" decision note).
        % ================================================================== %

        function val = CL_alpha_h(AR_ht, Lambda_c4_ht_deg, M)
        %CL_ALPHA_H  Horizontal-tail lift-curve slope [1/rad]. [Raymer 6th
        %   ed. Eq. 12.6/12.8] -- reuses the SAME AeroL2.CL_alpha low-level
        %   static Aero already uses for the wing, a second time, with the
        %   HT's own AR/quarter-chord sweep substituted for the wing's. The
        %   exposed-area knockdown factor (S_exposed/S_ref)*F and the 2-D
        %   section lift slope are left empty -- EXACTLY as
        %   F16AeroL2/L3.get_CL_alpha already does for the WING itself (no F
        %   factor is cited anywhere in this repo, and no HT-specific 2-D
        %   airfoil slope exists either -- the HT's biconvex section is not
        %   the wing's cambered NACA 64A204). This invokes AeroL2.CL_alpha's
        %   own documented eta=0.95 default [Raymer Eq. 12.8], not a silent
        %   or invented value.
            arguments
                AR_ht            (1,1) double {mustBePositive}
                Lambda_c4_ht_deg (1,1) double {mustBeReal}
                M                (1,1) double {mustBeReal, mustBeNonnegative}
            end
            val = AeroL2.CL_alpha(AR_ht, Lambda_c4_ht_deg, M, [], [], [], []);
        end

        % ================================================================== %
        % Eq. 16.8 -- Cm_alpha; Eq. 16.9 -- neutral point; Eq. 16.10 -- bonus
        % cross-check; Eq. 16.11 -- static margin.
        % ================================================================== %

        function Cma = Cm_alpha(CL_alpha, Xcg_bar, Xacw_bar, Cm_alpha_fus_rad, ...
                                  eta_h, Sh_Sw, CL_alpha_h, dalphah_dalpha, Xach_bar, ...
                                  Fp_alpha_over_qSw, dalphap_dalpha, Xp_bar)
        %CM_ALPHA  Pitching-moment derivative w.r.t. angle of attack [1/rad].
        %   [Raymer 6th ed. Eq. 16.8, p.592, verbatim]:
        %     Cm_alpha = CL_alpha*(Xcg_bar - Xacw_bar) + Cm_alpha,fus
        %                - eta_h*(Sh/Sw)*CL_alpha_h*(dalpha_h/dalpha)*(Xach_bar-Xcg_bar)
        %                + (Fp_alpha/(q*Sw))*(dalpha_p/dalpha)*(Xcg_bar-Xp_bar)
        %   All *_bar terms are x-STATIONS DIVIDED BY THE WING MAC (cbar_wing)
        %   -- dimensionless, referenced to a common datum (matches
        %   readme_bsc.md's SM = (x_np-x_cg)/MAC_W convention: only
        %   DIFFERENCES of *_bar terms appear, so any common x-datum works as
        %   long as every term shares the same cbar_wing divisor).
        %   CL_alpha/CL_alpha_h are PER RADIAN; Cm_alpha_fus_rad MUST already
        %   be converted from Eq. 16.25's per-deg form (Cm_alpha_fus_per_rad)
        %   before being passed here.
        %   The thrust term (last line) is a REQUIRED argument set here --
        %   pass Fp_alpha_over_qSw=0 (and/or dalphap_dalpha=0) explicitly at
        %   the call site to invoke Raymer's own "power-off" simplification
        %   [p.593: "It is common to neglect the inlet or propeller force
        %   term F_p in Eq. (16.9) to determine 'power-off' stability...
        %   Typically, these allowances for power-on will reduce the static
        %   margin by about 1-3% for jets."] -- never silently defaulted
        %   inside this toolbox.
            arguments
                CL_alpha          (1,1) double
                Xcg_bar           (1,1) double
                Xacw_bar          (1,1) double
                Cm_alpha_fus_rad  (1,1) double
                eta_h             (1,1) double {mustBePositive}
                Sh_Sw             (1,1) double {mustBePositive}
                CL_alpha_h        (1,1) double
                dalphah_dalpha    (1,1) double
                Xach_bar          (1,1) double
                Fp_alpha_over_qSw (1,1) double
                dalphap_dalpha    (1,1) double
                Xp_bar            (1,1) double
            end
            Cma = CL_alpha*(Xcg_bar - Xacw_bar) + Cm_alpha_fus_rad ...
                - eta_h*Sh_Sw*CL_alpha_h*dalphah_dalpha*(Xach_bar - Xcg_bar) ...
                + Fp_alpha_over_qSw*dalphap_dalpha*(Xcg_bar - Xp_bar);
        end

        function Xnp_bar = neutral_point(CL_alpha, Xacw_bar, Cm_alpha_fus_rad, ...
                                           eta_h, Sh_Sw, CL_alpha_h, dalphah_dalpha, Xach_bar, ...
                                           Fp_alpha_over_qSw, dalphap_dalpha, Xp_bar)
        %NEUTRAL_POINT  [Raymer 6th ed. Eq. 16.9, p.592, verbatim]:
        %     Xnp_bar = [ CL_alpha*Xacw_bar - Cm_alpha,fus
        %                 + eta_h*(Sh/Sw)*CL_alpha_h*(dalpha_h/dalpha)*Xach_bar
        %                 + (Fp_alpha/(q*Sw))*(dalpha_p/dalpha)*Xp_bar ]
        %               / [ CL_alpha + eta_h*(Sh/Sw)*CL_alpha_h*(dalpha_h/dalpha)
        %                   + (Fp_alpha/(q*Sw))*(dalpha_p/dalpha) ]
        %   Same power-off thrust-term-dropped treatment as Cm_alpha -- pass
        %   Fp_alpha_over_qSw=0 (and/or dalphap_dalpha=0) explicitly
        %   [Raymer p.593].
            arguments
                CL_alpha          (1,1) double
                Xacw_bar          (1,1) double
                Cm_alpha_fus_rad  (1,1) double
                eta_h             (1,1) double {mustBePositive}
                Sh_Sw             (1,1) double {mustBePositive}
                CL_alpha_h        (1,1) double
                dalphah_dalpha    (1,1) double
                Xach_bar          (1,1) double
                Fp_alpha_over_qSw (1,1) double
                dalphap_dalpha    (1,1) double
                Xp_bar            (1,1) double
            end
            num = CL_alpha*Xacw_bar - Cm_alpha_fus_rad ...
                + eta_h*Sh_Sw*CL_alpha_h*dalphah_dalpha*Xach_bar ...
                + Fp_alpha_over_qSw*dalphap_dalpha*Xp_bar;
            den = CL_alpha + eta_h*Sh_Sw*CL_alpha_h*dalphah_dalpha + Fp_alpha_over_qSw*dalphap_dalpha;
            Xnp_bar = num / den;
        end

        function Cma = Cm_alpha_from_neutral_point(CL_alpha, eta_h, Sh_Sw, CL_alpha_h, ...
                                                      dalphah_dalpha, Xnp_bar, Xcg_bar)
        %CM_ALPHA_FROM_NEUTRAL_POINT  [Raymer 6th ed. Eq. 16.10] -- Cm_alpha
        %   restated in terms of the neutral point; a cross-check against
        %   Cm_alpha (Eq. 16.8) at consistent inputs. Not required by the
        %   original stability-and-control design, implemented because it is
        %   essentially free once neutral_point/Cm_alpha exist:
        %     Cm_alpha = -(CL_alpha + eta_h*(Sh/Sw)*CL_alpha_h*(dalpha_h/dalpha))
        %                * (Xnp_bar - Xcg_bar)
            arguments
                CL_alpha       (1,1) double
                eta_h          (1,1) double {mustBePositive}
                Sh_Sw          (1,1) double {mustBePositive}
                CL_alpha_h     (1,1) double
                dalphah_dalpha (1,1) double
                Xnp_bar        (1,1) double
                Xcg_bar        (1,1) double
            end
            Cma = -(CL_alpha + eta_h*Sh_Sw*CL_alpha_h*dalphah_dalpha) * (Xnp_bar - Xcg_bar);
        end

        function SM = static_margin(Xnp_bar, Xcg_bar)
        %STATIC_MARGIN  [Raymer 6th ed. Eq. 16.11]  SM = Xnp_bar - Xcg_bar.
        %   Both arguments already dimensionless (station / wing MAC) -- NO
        %   further division by anything. The legacy temp_Casey
        %   SandCLevel3.compute_SM divides by an extra, uncited 100; this
        %   static deliberately does not.
            arguments
                Xnp_bar (1,1) double
                Xcg_bar (1,1) double
            end
            SM = Xnp_bar - Xcg_bar;
        end

        % ================================================================== %
        % Eqs. 16.13/16.14 -- wing/tail lift coefficients.
        % ================================================================== %

        function CLw = CL_w(CL_alpha, alpha_deg, i_w_deg, alpha_0L_deg)
        %CL_W  Wing lift coefficient. [Raymer 6th ed. Eq. 16.13]:
        %     CL_w = CL_alpha * (alpha + i_w - alpha_0L)
        %   Angle sum converted deg->rad before multiplying the per-radian
        %   CL_alpha (matches this repo's existing deg2rad convention, e.g.
        %   AeroL2.compute_CL_minD).
            arguments
                CL_alpha     (1,1) double
                alpha_deg    (1,1) double {mustBeReal}
                i_w_deg      (1,1) double {mustBeReal}
                alpha_0L_deg (1,1) double {mustBeReal}
            end
            CLw = CL_alpha * deg2rad(alpha_deg + i_w_deg - alpha_0L_deg);
        end

        function CLh = CL_h(CL_alpha_h, alpha_deg, i_h_deg, epsilon_deg, alpha_0Lh_deg)
        %CL_H  Horizontal-tail lift coefficient. [Raymer 6th ed. Eq. 16.14]:
        %     CL_h = CL_alpha_h * (alpha + i_h - epsilon - alpha_0Lh)
        %   epsilon (downwash angle) is a REQUIRED argument -- pass 0
        %   explicitly at the call site to invoke this discipline's
        %   documented downwash simplification (downwash is out of scope
        %   this pass), never a silent default inside this toolbox.
            arguments
                CL_alpha_h    (1,1) double
                alpha_deg     (1,1) double {mustBeReal}
                i_h_deg       (1,1) double {mustBeReal}
                epsilon_deg   (1,1) double {mustBeReal}
                alpha_0Lh_deg (1,1) double {mustBeReal}
            end
            CLh = CL_alpha_h * deg2rad(alpha_deg + i_h_deg - epsilon_deg - alpha_0Lh_deg);
        end

        % ================================================================== %
        % Eqs. 16.15/16.16/16.18 -- Delta alpha_L0 (control-surface
        % deflection family).
        % ================================================================== %

        function val = delta_alpha_L0_elevator(c_e_over_c, delta_e_deg)
        %DELTA_ALPHA_L0_ELEVATOR  Change in zero-lift angle of attack from a
        %   plain control-surface deflection [deg]. [Raymer 6th ed.
        %   Eqs. 16.16/16.18, p.596-598 -- the GENERAL plain-flap/control-
        %   surface family the book applies to "elevator, aileron, and
        %   rudder" alike (primary-source-confirmed 2026-08-04), NOT a
        %   separately-numbered elevator-only equation]:
        %     alpha_hL0 = -[1.576*(c_e/c)^3 - 3.458*(c_e/c)^2 + 2.882*(c_e/c)] * delta_e
        %   Evaluates to 0 identically for the F-16 (c_elev_frac=0, all-
        %   moving stabilator, Raymer Table 6.5 footnote "Supersonic usually
        %   all-moving tail without separate elevator") -- a real, expected
        %   answer for THIS airframe, not a special case hardcoded here.
            arguments
                c_e_over_c  (1,1) double {mustBeNonnegative}
                delta_e_deg (1,1) double {mustBeReal}
            end
            val = -(1.576*c_e_over_c^3 - 3.458*c_e_over_c^2 + 2.882*c_e_over_c) * delta_e_deg;
        end

        function Cmacw = Cm_acw_wing(Cm0_airfoil, AR, sweep_deg)
        %CM_ACW_WING  Wing zero-lift pitching-moment coefficient about its
        %   own aerodynamic center. [Raymer 6th ed. Eq. 16.19, p.598,
        %   Sec. "Wing Pitching Moment" -- found 2026-08-04 while closing
        %   x_p/i_w/i_h; confirms this term DOES have a citable Ch. 16
        %   formula, closing the "no such quantity exists anywhere" gap
        %   flagged during that pass]:
        %     Cm_acw = Cm0_airfoil * (AR*cos(sweep)^2) / (AR + 2*cos(sweep))
        %   "for a straight wing or an untwisted swept wing at low subsonic
        %   speeds." Cm0_airfoil is the wing section's OWN 2D zero-lift
        %   pitching-moment coefficient about its aerodynamic center -- an
        %   airfoil-table value (e.g. NACA report / Abbott & von Doenhoff),
        %   not something Ch. 16 derives; Raymer only gives the AR/sweep
        %   adjustment from the 2D value to the 3D wing value. Two further
        %   terms the same page documents and this static deliberately
        %   OMITS (call out at the wrapper level, not silently): wing twist
        %   ("adds an increment of approximately (-0.01) times the twist in
        %   degrees for a typical swept wing") and a transonic increment
        %   ("about 30% at Mach 0.8").
            arguments
                Cm0_airfoil (1,1) double {mustBeReal}
                AR          (1,1) double {mustBePositive}
                sweep_deg   (1,1) double {mustBeReal}
            end
            Cmacw = Cm0_airfoil * (AR*cosd(sweep_deg)^2) / (AR + 2*cosd(sweep_deg));
        end

        % ================================================================== %
        % Eqs. 16.4/16.5/16.7 -- full pitching-moment-about-CG trim buildup.
        % COMPLETE AND REAL -- ready the instant a citable x_p/z_t value
        % exists. F16SandCL3.Cm_cg_trim errors BEFORE ever calling this (the
        % GAP is the F-16 wrapper's missing inputs, not this formula).
        % ================================================================== %

        function Cmcg = Cm_cg_coefficient(CL, x_cg, x_acw, cbar, Cm_acw, Cm_w_delta_f, delta_f_deg, ...
                                             eta_h, S_h, S_w, CL_h, x_ach, q, T, z_t, F_p, x_p)
        %CM_CG_COEFFICIENT  Full pitching-moment-about-CG coefficient (the
        %   actual trim equation), INCLUDING the direct thrust-moment terms.
        %   [Raymer 6th ed. Eq. 16.5 (dimensional arm lengths, ft) / Eq. 16.7
        %   (same relation, arm lengths as fractions of cbar) -- confirmed
        %   the SAME relation, two forms, Casey's 2026-08-03 physical-book
        %   read]:
        %     Cm_cg = CL*(x_cg-x_acw)/cbar + Cm_acw + Cm_w,delta_f*delta_f
        %             - eta_h*(S_h/S_w)*CL_h*(x_ach-x_cg)/cbar
        %             - T*z_t/(q*S_w*cbar) + F_p*(x_cg-x_p)/(q*S_w*cbar)
        %   x_cg/x_acw/x_ach/x_p/z_t/cbar all in the SAME length unit (ft).
        %   eta_h*(S_h/S_w) here stands in for Raymer's own (q_h*S_h)/(q*S_w)
        %   -- eta_h = q_h/q, the same tail dynamic-pressure ratio used in
        %   Eqs. 16.8/16.9, kept consistent rather than introducing a second
        %   q_h variable.
            arguments
                CL           (1,1) double
                x_cg         (1,1) double
                x_acw        (1,1) double
                cbar         (1,1) double {mustBePositive}
                Cm_acw       (1,1) double
                Cm_w_delta_f (1,1) double
                delta_f_deg  (1,1) double
                eta_h        (1,1) double {mustBePositive}
                S_h          (1,1) double {mustBePositive}
                S_w          (1,1) double {mustBePositive}
                CL_h         (1,1) double
                x_ach        (1,1) double
                q            (1,1) double {mustBePositive}
                T            (1,1) double
                z_t          (1,1) double
                F_p          (1,1) double
                x_p          (1,1) double
            end
            Cmcg = CL*(x_cg - x_acw)/cbar + Cm_acw + Cm_w_delta_f*delta_f_deg ...
                 - eta_h*(S_h/S_w)*CL_h*(x_ach - x_cg)/cbar ...
                 - (T*z_t)/(q*S_w*cbar) ...
                 + (F_p*(x_cg - x_p))/(q*S_w*cbar);
        end

    end

end
