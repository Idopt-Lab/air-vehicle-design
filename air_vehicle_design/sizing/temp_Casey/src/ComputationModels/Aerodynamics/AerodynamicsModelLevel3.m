classdef (Abstract) AerodynamicsModelLevel3 < AeroBase
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          % e_osw_clean
          % K_LD
          % K
          % K1
          % K2
          % Cf
          % CL_minD
          % CL_max_clean
          % CD0
          % CDi
          CD0_misc
          CD0_LandP
          R_components
          R_cutoff
          FF % Fuselage interference factor
     end

     properties (Abstract, Constant) % These should be values that are tabulated based on geometry.
          airfoiltype % either "cambered" or "uncambered." Leave empty if NOT AIRFOIL.
          C1 % Tabulated from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          C2 % Tabulatef from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CL_max_base % Tabulated from Fig 12.13 (Raymer, 6th ed) & (C1 + 1)*(AR/beta)*cosd(Lambda_LE_deg) = 2.76.
          sharpness_param % Computed from Table 12.1 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CL_max_cl_max % Tabulated from Fig 12.9 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed), Lambda_LE_deg = 40.
          cl_max % Obtained from page 14 of https://ntrs.nasa.gov/api/citations/19870017427/downloads/19870017427.pdf
          alpha_L0 % Zero-lift AOA (deg)
          k % Skin roughness factor

     end

     methods (Abstract)
          % e_osw_clean = get_e_osw(AR, Lambda_LE)
          % K = get_K(e_osw, AR)
          % K1 = compute_K1(M, AR, e_osw, LE_sweep)
          % K2 = compute_K2(M, K1, CLminD)
          % CD = get_CD(CD0, K, CL)
          CD0 = get_CD0(Cf, S_wet, S_ref)
          % CDi = get_CDi(statevector, CL, e_osw, AR)
          % CL_minD = get_CL_minD(airfoil_type, CL_min, CD0)
          [Cf_lam_result, Cf_turb_result] = get_Cf(R, M) % Using L3 method.
          R_cutoff = get_R_cutoff(ref_length, M)
          Delta_CL_max = get_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg) % This should be able to get you the Delta_CL_max values you need.
          Delta_cl_max = get_Delta_cl_max_values(liftdevice, config, cp_c) % this should get you the values you need (Delta_cl_max_TO, Delta_cl_max_L)
          CL_max = get_CL_max_values(AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max) % This should get you the CL_max values you need (CL_max_TO, CL_max_Landing, etc)
          CL_alpha = get_CL_alpha(M, cl_alpha, AR, S_exposed, S_ref, F, Lambda_max_t_deg)
          F = get_F(d, b)
     end
end