classdef (Abstract) AeroModelL3 < AerodynamicsBase
     %AEROMODELL3  Tier-2a abstract enforcer for Level-3 aerodynamics.
     %
     %   Inherits AerodynamicsBase directly (NOT a subclass of AeroModelL1/L2).
     %
     %   Level-3 replaces the category-based Cf with a full component CD0 buildup.
     %   Component geometry is stored as parallel arrays (one entry per component).
     %   Surfaces (wing, HT, VT) use FF_surface (Raymer Eq 12.30).
     %   Bodies (fuselage, duct) use FF_body (Raymer Eq 12.31) via is_body_comp flag.
     %
     %   K1 and K2 use the same Raymer/Brandt equations as L1/L2.

     properties (Abstract)
          % --- Aircraft-specific inputs

          % --- Miscellaneous drag (set to 0 if not applicable)
          CD0_misc        % double; — upsweep + base drag allowance
          CD0_LandP       % double; — leakage and protuberance allowance

          % --- Component-level buildup results (store after calling methods)
          R_components    % double array; — Reynolds number per component
          R_cutoff        % double array; — cutoff Reynolds number per component
          FF              % double array; — form factor per component
     end

     properties (Abstract, Constant)
          % Tabulated constants — must be set by the student class from figures/tables.
          airfoiltype     % string; "cambered" or "uncambered"
          C1              % double; from Raymer 6th ed. Fig. 12.12
          C2              % double; from Raymer 6th ed. Fig. 12.12
          CL_max_base     % double; from Raymer 6th ed. Fig. 12.13
          sharpness_param % double; from Raymer 6th ed. Table 12.1
          CL_max_cl_max   % double; from Raymer 6th ed. Fig. 12.9
          cl_max          % double; 2D section cl_max (from airfoil data)
          alpha_L0        % double; deg — zero-lift angle of attack
          k               % double; ft  — equiv. surface skin roughness; for F-16, using smooth paint: k = 2.08e-5 ft [Raymer 6th ed. Table 12.2]
     end

     methods (Abstract)

          %COMPUTE_RE  Re = rho*V*l/mu  (Raymer Eq. 12.25).
          val = compute_Re(obj, state, l_ref)

          %COMPUTE_CF_LAM  Laminar Cf (Raymer Eq. 12.26).
          val = compute_Cf_lam(obj, Re)

          %COMPUTE_CF_TURB  Turbulent Cf (Raymer Eq. 12.27).
          val = compute_Cf_turb(obj, Re, M)

          %COMPUTE_FF_SURFACE  Form factor for a lifting surface (Raymer Eq. 12.30).
          val = compute_FF_surface(obj, tc, x_c_max, Lambda_m_deg, M)

          %COMPUTE_FF_FUS  Form factor for a body/fuselage (Raymer Eq. 12.31).
          val = compute_FF_fus(obj, L_body, D_body)

          %GET_CD0_BUILDUP  Sum all component drag contributions.
          val = get_CD0_buildup(obj, state)

          %GET_K1  Induced-drag factor (same equations as L1/L2).
          val = get_K1(obj, M)

          %GET_K2  Polar-offset term (same equations as L1/L2).
          val = get_K2(obj, K1_sub, M)

          %COMPUTE_CL_MIND  CL at minimum drag (airfoil-type lookup).
          val = compute_CL_minD(obj, airfoil_type, CL_min, CD0)

          %COMPUTE_CF  Per-component Cf: returns [Cf_lam, Cf_turb] at given Re and Mach.
          [Cf_lam_result, Cf_turb_result] = compute_Cf(obj, R, M)

          %GET_R_CUTOFF  Cutoff Reynolds number for a given reference length and Mach.
          val = get_R_cutoff(obj, ref_length, M)

          %GET_CL_MAX_VALUES  CLmax for various configurations.
          val = get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)

          %GET_CL_ALPHA  Finite-wing lift-curve slope; reads geometry from obj.
          val = get_CL_alpha(obj, M)

          %COMPUTE_F  Fuselage lift interference factor.
          val = compute_F(obj, d, b)

          %COMPUTE_DELTA_CL_MAX_VALUES  Wing CLmax increment from deployed HLD.
          %   Formula: 0.9 * Delta_cl_max * (S_flapped/S_ref) * cos(Lambda_HL)
          %   Source: Raymer 6th ed. Eq. 12.21
          val = compute_Delta_CL_max_values(obj, Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)

          %LOOKUP_DELTA_CL_MAX_VALUES  Section cl_max increment for a given HLD type.
          %   liftdevice: "plain", "split", "slotted", "fowler", "double slotted", etc.
          %   config: "takeoff"/"TO" or "landing"/"L"
          %   cp_c: c'/c for chord-changing devices
          %   Source: Raymer 6th ed. §12.5
          val = lookup_Delta_cl_max_values(obj, liftdevice, config, cp_c)

     end

end
