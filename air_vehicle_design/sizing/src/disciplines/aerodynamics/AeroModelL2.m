classdef (Abstract) AeroModelL2 < AerodynamicsBase
     %AEROMODELL2  Tier-2a abstract enforcer for Level-2 aerodynamics.
     %
     %   Inherits AerodynamicsBase directly (NOT a subclass of AeroModelL1).
     %   Each fidelity enforcer independently inherits the base contract.
     %
     %   Level-2 adds lift-curve slope (CL_alpha from wing geometry) and
     %   geometry-based CLmax (no high-lift devices) over Level-1.  The CD0
     %   formula (Cf * S_wet / S_ref) is the same as Level-1; Cf still comes
     %   from an aircraft-type table lookup.
     %
     %   Equations added at L2 vs L1:
     %     CL_alpha: Raymer, 6th ed., Eq. 12.6 (Datcom-based finite-wing lift slope)
     %     CLmax   : 0.9 * cl_max_2D * cos(Lambda_c4_deg)   [Raymer 6th ed., §12.2]

     properties (Abstract)
          % --- Computed aerodynamic quantities
          F                   % double; — fuselage lift interference factor
     end

     properties (Abstract, Constant)
          % Tabulated constants — must be set by the student class from figures/tables.
          airfoiltype     % string; "cambered" or "uncambered"
          C1              % double; from Raymer 6th ed. Fig. 12.12 (lambda = 0.23)
          C2              % double; from Raymer 6th ed. Fig. 12.12 (lambda = 0.23)
          CL_max_base     % double; from Raymer 6th ed. Fig. 12.13
          sharpness_param % double; from Raymer 6th ed. Table 12.1
          CL_max_cl_max   % double; from Raymer 6th ed. Fig. 12.9 (at Lambda_LE)
          cl_max          % double; 2D section cl_max (from airfoil data)
          alpha_L0        % double; deg — zero-lift angle of attack
     end

     methods (Abstract)

          %GET_E_OSW  Oswald span efficiency factor.
          val = get_e_osw(obj)

          %GET_K1  Induced-drag factor (same equations as L1).
          val = get_K1(obj, M)

          %GET_K2  Polar-offset term (same equations as L1).
          val = get_K2(obj, K1_sub, M)

          %GET_CD0  Zero-lift drag (same formula as L1: Cf * S_wet/S_ref).
          val = get_CD0(obj)

          %COMPUTE_CL_MIND  CL at minimum drag from lift-curve slope and zero-lift AOA.
          val = compute_CL_minD(obj, CL_alpha, alpha_L0)

          %LOOKUP_CF  Skin-friction coefficient (type-based lookup, same as L1).
          val = lookup_Cf(obj, aircraft_type, n_engines)

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
