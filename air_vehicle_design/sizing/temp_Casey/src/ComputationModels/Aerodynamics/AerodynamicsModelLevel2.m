classdef (Abstract) AerodynamicsModelLevel2 < AeroBase
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
          % e_osw_clean
          % K_LD
          % K % This is just K = 1/(pi*e_osw*AR), which is K1 subsonic. Kept "just in case".
          % K1
          % K2
          % Cf
          % CL_minD
          % CL_max_clean
          % CD0
          % CDi
          % CD
          % CL
          F % Fuselage interference factor
          % I should definitely add the properties of high-lift devices'
          % deflections for take-off and landing configurations, as well as
          % properties for their types.
     end

     properties (Abstract, Constant)
          airfoiltype % "cambered" or "uncambered".
          % N.B: Consider installing a NACA airfoil database for airfoil
          % data lookup (instead of having to troll the internet).
          % IF YOU HAVE HIGH-LIFT DEVICES, BEGIN ACCOUNTING FOR THEM HERE.
          C1 % Tabulated from Fig 12.12, (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          C2 % Tabulatef from Fig 12.12, (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CL_max_base % Tabulated from Fig 12.13 (Raymer, 6th ed) & (C1 + 1)*(AR/beta)*cosd(Lambda_LE_deg)
          sharpness_param % Should be tabulated
          CL_max_cl_max % Should be tabulated
          cl_max % Should be taken directly from the chosen airfoil
          alpha_L0 % Zero-lift AOA (deg)
     end


     methods (Abstract)
          % e_osw = get_e_osw(AR, Lambda_LE)
          % K = get_K(e_osw, AR)
          % K1 = compute_K1(M, AR, e_osw, LE_sweep)
          % K2 = compute_K2(M, K1, CLminD)
          % CD = get_CD(CD0, K, CL)
          % CD0 = get_CD0(Cf, S_wet, S_ref)
          % CDi = get_CDi(statevector, CL, e_osw, AR)
          CL_minD = get_CL_minD(CL_alpha, alpha_L0)
          % Cf = get_Cf(aircraft_type, n_engines) % Using L1 until a suitable replacement is found.
          Delta_CL_max = get_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg) % This should be able to get you the Delta_CL_max values you need.
          Delta_cl_max = get_Delta_cl_max_values(liftdevice, config, cp_c) % this should get you the values you need (Delta_cl_max_TO, Delta_cl_max_L)
          CL_max = get_CL_max_values(AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max) % This should get you the CL_max values you need (CL_max_TO, CL_max_Landing, etc)
          CL_alpha = get_CL_alpha(M, cl_alpha, AR, S_exposed, S_ref, F, Lambda_max_t_deg)
          F = get_F(d, b)
     end
end