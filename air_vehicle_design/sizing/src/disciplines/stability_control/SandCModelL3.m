classdef (Abstract) SandCModelL3 < StabControlBase
     %SANDCMODELL3  Tier-2 abstract enforcer for Level-3 stability & control.
     %
     %   Inherits StabControlBase directly, NOT SandCModelL2 -- L3 satisfies the
     %   Tier-1 x_cg contract independently, reusing the SAME level-agnostic
     %   SandCL2.weighted_cg static that L2 uses (fidelity-collapse rule: the
     %   weighted-average CG identity does not vary by fidelity level, only the
     %   component weight/x-station data fed into it does -- see SandCL3.m's own
     %   header and F16SandCL3.get.x_cg).
     %
     %   L3 is the FULL Raymer 6th ed. Ch. 16 Sec. 16.3 longitudinal-static-
     %   stability equation set that is actually implementable today (primary-
     %   source-corrected 2026-08-04, see docs/subplans/10_stability_control.md):
     %     Eq. 16.8  -- Cm_alpha (pitching-moment derivative)
     %     Eq. 16.9  -- neutral point
     %     Eq. 16.10 -- Cm_alpha restated via the neutral point (bonus cross-check)
     %     Eq. 16.11 -- static margin
     %     Eq. 16.12 -- aerodynamic center, longitudinal location (wing)
     %     Eq. 16.25 -- Cm_alpha,fus (fuselage contribution feeding Eq. 16.8/16.9)
     %     Eqs. 16.15/16.16/16.18 -- Delta alpha_L0 (elevator/control-surface
     %       deflection family)
     %   plus the level-agnostic CL_alpha_h wrapper. Eqs. 16.13/16.14/16.5-16.7's
     %   trim buildup are ALL REAL as of 2026-08-04 (x_p, z_t, F_p, i_w, i_h were
     %   the original citation gaps; all resolved or reframed -- see
     %   F16SandCL3.CL_w/CL_h/Cm_cg_trim). The one remaining open input,
     %   Cm0_airfoil_wing (feeding Eq. 16.19's Cm_acw), is USER/STUDENT-SUPPLIED
     %   by design (no citable NACA 64A204 value found in Ch. 16 or this repo) --
     %   Cm_cg_trim returns NaN, not an error, until it is filled in.
     %
     %   Every equation below is implemented as a LEVEL-AGNOSTIC static on
     %   SandCL3 -- plain scalar/array arguments only, never reading tier-level
     %   obj state (matches AeroL2.CL_alpha / AeroL1.oswald_eff's existing
     %   convention). The DERIVED properties below are the concrete class's own
     %   Dependent getters, which read the injected collaborators' CURRENT state
     %   and call those SandCL3 statics -- never cached (CLAUDE.md
     %   "Optimization-ready property design").
     %
     %   DEPENDENCY INJECTION: F16GeomL3, F16WeightsL3, F16AeroL3, F16PropL2 (no
     %   L3 propulsion tier exists repo-wide -- same DI pattern F16WeightsL3
     %   already uses for its own propulsion collaborator) -- see F16SandCL3.m's
     %   own header for the exact constructor signature.
     %
     %   Toolbox companion: src/disciplines/stability_control/SandCL3.md

     properties (Abstract)
          %X_ACW  Wing aerodynamic-center x-station [ft]. [Raymer 6th ed.
          %   Eq. 16.12]
          x_acw

          %X_ACH  Horizontal-tail aerodynamic-center x-station [ft]. Quarter-MAC
          %   identity, deliberately WITHOUT an Eq. 16.12-style Mach-shift term:
          %   that correction's coefficients (0.26/0.112/0.004) are calibrated
          %   against the WING's own reference area (sqrt(S_wing)), and Raymer
          %   gives no equivalent correction for a tail surface. Documented
          %   simplification, not a citation gap (same standard as this
          %   discipline's downwash/eta_h simplifications).
          x_ach

          %CL_ALPHA_WING  Wing lift-curve slope [1/rad] at the analysis Mach.
          %   Read DIRECTLY from the injected F16AeroL3.get_CL_alpha(M) -- NOT
          %   re-derived in this discipline.
          CL_alpha_wing

          %CL_ALPHA_TAIL  Horizontal-tail lift-curve slope [1/rad] at the
          %   analysis Mach. [Raymer 6th ed. Eq. 12.6/12.8] via SandCL3's
          %   CL_alpha_h, which calls the SAME AeroL2.CL_alpha low-level static
          %   Aero already uses for the wing, substituting the HT's own
          %   AR/quarter-chord sweep -- not a new Aero method (this
          %   discipline's own "link to the Aero toolbox rather than re-derive"
          %   decision).
          CL_alpha_tail
          % Note: if you are using a FLYING WING/TAILLESS DESIGN, THIS WILL
          % BE ZERO.

          %CM_ALPHA_FUS  Fuselage pitching-moment-derivative contribution
          %   [1/rad]. [Raymer 6th ed. Eq. 16.25, explicitly "per deg" in the
          %   book] x (180/pi) unit conversion -- the exact missing factor the
          %   legacy temp_Casey code never applies.
          Cm_alpha_fus

          %X_NP  Neutral point x-station [ft]. [Raymer 6th ed. Eq. 16.9], the
          %   thrust term dropped per Raymer's own "power-off" sanction (p.593:
          %   "It is common to neglect the inlet or propeller force term F_p in
          %   Eq. (16.9) to determine 'power-off' stability... Typically, these
          %   allowances for power-on will reduce the static margin by about
          %   1-3% for jets.").
          x_np

          %SM  Static margin, fraction of the wing MAC. [Raymer 6th ed.
          %   Eq. 16.11]  SM = (x_np - x_cg)/cbar_wing. NO extra division by
          %   100 (the legacy temp_Casey compute_SM bug this discipline avoids).
          SM

          %CM_ALPHA  Pitching-moment derivative w.r.t. angle of attack [1/rad].
          %   [Raymer 6th ed. Eq. 16.8], same power-off thrust-term-dropped
          %   treatment as x_np.
          Cm_alpha

          %CM_ACW  Wing zero-lift pitching-moment coefficient about its own
          %   aerodynamic center [--]. [Raymer 6th ed. Eq. 16.19, p.598] --
          %   found 2026-08-04, closing the "no such quantity exists
          %   anywhere" gap discovered during the x_p/i_w/i_h closure pass.
          %   Needs Cm0_airfoil_wing (the wing section's own 2D moment
          %   coefficient, airfoil-table data Ch. 16 does not supply) as a
          %   USER/STUDENT-SUPPLIED input -- returns NaN, not an error,
          %   until that value is filled in.
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

     % Tabulated values (similar in concept to what's "tabulated" in the
     % Aerodynamics discipline).
     % K_fus

     methods (Abstract)

          %DELTA_ALPHA_L0  Change in zero-lift angle of attack [deg] from a
          %   control-surface deflection. [Raymer 6th ed. Eqs. 16.15/16.16/
          %   16.18 -- the GENERAL plain-flap/control-surface-deflection family
          %   the book applies to "elevator, aileron, and rudder" alike, not an
          %   elevator-only-numbered equation]. Fully implemented -- evaluates
          %   to 0 for the F-16 (c_elev_frac=0, all-moving stabilator), a real
          %   answer for this airframe, not a gap.
          val = Delta_alpha_L0(obj, delta_e_deg)

          %CL_W  Wing lift coefficient. [Raymer 6th ed. Eq. 16.13] CLOSED
          %   2026-08-04: i_w=0deg [T.O. 1F-16A-1 "WINGS" data block] and
          %   alpha_0L=-1.33deg [NACA 64A204, F16AeroL3.alpha_L0] are both real,
          %   cited values. See F16SandCL3.CL_w.
          val = CL_w(obj, alpha_deg)

          %CL_H  Horizontal-tail lift coefficient. [Raymer 6th ed. Eq. 16.14]
          %   CLOSED 2026-08-04, reframed rather than resolved by a spec
          %   lookup: i_h is a REQUIRED CALLER-SUPPLIED trim-condition argument
          %   (the F-16 tail is an all-moving stabilator, so incidence IS the
          %   control variable, not a fixed spec constant to look up).
          %   epsilon/alpha_0Lh=0deg (downwash out of scope; symmetric
          %   biconvex tail section [T.O. 1F-16A-1]). See F16SandCL3.CL_h.
          val = CL_h(obj, alpha_deg, i_h_deg)

          %CM_CG_TRIM  Full pitching-moment-about-CG trim buildup, coefficient
          %   form, at a given angle of attack and tail incidence. [Raymer 6th
          %   ed. Eq. 16.5 (dimensional)/16.7 (arm lengths as fractions of
          %   cbar)] REAL as of 2026-08-04: x_p/z_t/F_p (Casey's original
          %   closure request) are ALL resolved (x_p=geom.x_inlet per Raymer
          %   Eqs. 16.26-16.28's own definition of F_p; z_t=F_p=0, both
          %   explicit Raymer-sanctioned simplifications, p.604/p.609), and
          %   Cm_acw [Eq. 16.19] is now a real, cited formula. Returns NaN
          %   (not an error) until Cm0_airfoil_wing -- Cm_acw's own required
          %   airfoil-table input, USER/STUDENT-SUPPLIED, no citable value
          %   found for this repo's NACA 64A204 wing section -- is filled in.
          %   i_h_deg is a REQUIRED CALLER argument, same reframing as CL_h's
          %   (all-moving stabilator; i_h IS the trim variable). See
          %   F16SandCL3.Cm_cg_trim for the full record.
          val = Cm_cg_trim(obj, alpha_deg, i_h_deg)

     end

end
