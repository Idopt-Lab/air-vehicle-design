classdef (Abstract) SandCModelL3 < StabControlBase
     %SANDCMODELL3  Tier-2 abstract enforcer for Level-3 stability & control.
     %
     %   The full Raymer 6th ed. Ch. 16 Sec. 16.3 longitudinal-static-stability
     %   set that is implementable today:
     %     Eq. 16.8  -- Cm_alpha (pitching-moment derivative)
     %     Eq. 16.9  -- neutral point
     %     Eq. 16.10 -- Cm_alpha restated via the neutral point (cross-check)
     %     Eq. 16.11 -- static margin
     %     Eq. 16.12 -- wing aerodynamic-center location
     %     Eq. 16.25 -- Cm_alpha,fus (fuselage contribution)
     %     Eqs. 16.15/16.16/16.18 -- Delta alpha_L0 (control-surface family)
     %   plus the CL_alpha_h wrapper and the Eqs. 16.13/16.14/16.5-16.7 trim
     %   buildup. Cm_cg_trim returns NaN until Cm0_airfoil_wing (feeding
     %   Eq. 16.19's Cm_acw) is user-supplied.
     %
     %   Each equation is a level-agnostic static on SandCL3; the Dependent
     %   getters below read the injected collaborators live and call those
     %   statics (never cached). Injects F16GeomL3, F16WeightsL3, F16AeroL3,
     %   F16PropL2. History and rationale: docs/decision_log.md.
     %
     %   Toolbox companion: src/disciplines/stability_control/SandCL3.md

     properties (Abstract)
          %X_ACW  Wing aerodynamic-center x-station [ft]. [Raymer 6th ed.
          %   Eq. 16.12]
          x_acw

          %X_ACH  Horizontal-tail aerodynamic-center x-station [ft]. Quarter-MAC
          %   identity, without an Eq. 16.12-style Mach-shift term (Raymer gives
          %   no equivalent correction for a tail surface). Documented
          %   simplification, not a citation gap.
          x_ach

          %CL_ALPHA_WING  Wing lift-curve slope [1/rad] at the analysis Mach.
          %   Read DIRECTLY from the injected F16AeroL3.get_CL_alpha(M) -- NOT
          %   re-derived in this discipline.
          CL_alpha_wing

          %CL_ALPHA_TAIL  Horizontal-tail lift-curve slope [1/rad] at the
          %   analysis Mach. [Raymer 6th ed. Eq. 12.6/12.8] via SandCL3's
          %   CL_alpha_h, which calls the same AeroL2.CL_alpha static used for
          %   the wing with the HT's own AR/quarter-chord sweep. Zero for a
          %   flying-wing/tailless design.
          CL_alpha_tail

          %CM_ALPHA_FUS  Fuselage pitching-moment-derivative contribution
          %   [1/rad]. [Raymer 6th ed. Eq. 16.25, "per deg" in the book] x
          %   (180/pi) unit conversion.
          Cm_alpha_fus

          %X_NP  Neutral point x-station [ft]. [Raymer 6th ed. Eq. 16.9], the
          %   thrust term dropped per Raymer's "power-off" sanction (p.593).
          x_np

          %SM  Static margin, fraction of the wing MAC. [Raymer 6th ed.
          %   Eq. 16.11]  SM = (x_np - x_cg)/cbar_wing.
          SM

          %CM_ALPHA  Pitching-moment derivative w.r.t. angle of attack [1/rad].
          %   [Raymer 6th ed. Eq. 16.8], same power-off thrust-term-dropped
          %   treatment as x_np.
          Cm_alpha

          %CM_ACW  Wing zero-lift pitching-moment coefficient about its own
          %   aerodynamic center [--]. [Raymer 6th ed. Eq. 16.19, p.598]. Needs
          %   Cm0_airfoil_wing (the wing section's 2D moment coefficient,
          %   user-supplied airfoil-table data) -- returns NaN until filled in.
          Cm_acw
     end

     % TODO (8/4/2026): There should definitely be some properties here.
     % Stored properties:
     % M_cg
     % Cm_c
     % eta_h (eq 16.6, if possible)
     % Cm_alpha
     % X_np (x-location of the neutral point)
     % SM (static margin)
     methods (Abstract)

          %DELTA_ALPHA_L0  Change in zero-lift angle of attack [deg] from a
          %   control-surface deflection. [Raymer 6th ed. Eqs. 16.15/16.16/
          %   16.18, the general control-surface-deflection family]. Evaluates
          %   to 0 for the F-16 (c_elev_frac=0, all-moving stabilator).
          val = Delta_alpha_L0(obj, delta_e_deg)

          %CL_W  Wing lift coefficient. [Raymer 6th ed. Eq. 16.13]. Uses
          %   i_w=0deg [T.O. 1F-16A-1 "WINGS" data block] and alpha_0L=-1.33deg
          %   [NACA 64A204, F16AeroL3.alpha_L0]. See F16SandCL3.CL_w.
          val = CL_w(obj, alpha_deg)

          %CL_H  Horizontal-tail lift coefficient. [Raymer 6th ed. Eq. 16.14].
          %   i_h is a required caller-supplied trim argument (the F-16 tail is
          %   an all-moving stabilator, so incidence is the control variable).
          %   epsilon/alpha_0Lh=0deg (downwash out of scope; symmetric biconvex
          %   tail section [T.O. 1F-16A-1]). See F16SandCL3.CL_h.
          val = CL_h(obj, alpha_deg, i_h_deg)

          %CM_CG_TRIM  Full pitching-moment-about-CG trim buildup, coefficient
          %   form, at a given angle of attack and tail incidence. [Raymer 6th
          %   ed. Eq. 16.5 (dimensional)/16.7 (arms as fractions of cbar)].
          %   x_p=geom.x_inlet [Raymer Eqs. 16.26-16.28]; z_t=F_p=0
          %   [Raymer-sanctioned simplifications, p.604/p.609]; Cm_acw
          %   [Eq. 16.19]. Returns NaN until user-supplied Cm0_airfoil_wing is
          %   filled in. i_h_deg is a required caller argument (all-moving
          %   stabilator; i_h is the trim variable). See F16SandCL3.Cm_cg_trim.
          val = Cm_cg_trim(obj, alpha_deg, i_h_deg)

     end

end
