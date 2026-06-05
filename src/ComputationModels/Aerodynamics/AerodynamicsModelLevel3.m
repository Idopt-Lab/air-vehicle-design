classdef (Abstract) AerodynamicsModelLevel3 < handle
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          % Are these for the entire design, or for a specific component?
          % I could pick the "component" interpretation. That would be
          % specific enough to stop overthinking stuff.
          % Each "object" could be an individual part of the design.
          airfoiltype % either "cambered" or "uncambered." Leave empty if NOT AIRFOIL.
          e_osw_clean
          e_osw_TO
          e_osw_L
          LD_max
          AR_wet
          K_LD
          K
          K1
          K2
          Cf
          CL_minD
          CL_max_clean
          CL_max_TO
          CL_max_L
          Delta_CL_max_TO
          Delta_CL_max_L
          Delta_cl_max_TO % Contribution from high-lift devices (take-off config)
          Delta_cl_max_L % Contribution from high-lift devices (landing config)
          Delta_CD0_TO
          Delta_CD0_L
          Delta_CD0_geardown
          Delta_CDi
          F % Fuselage interference factor
          R_components
          R_cutoff
          FF
     end

     properties (Abstract, Constant) % These should be values that are tabulated based on geometry.
          hld_TE % High-lift device, trailing edge (type)
          hld_LE % High-lift device, leading edge (type)
          delta_hld_TE_TO % Deflection of high-lift device, trailing edge, take-off config (deg)
          delta_hld_TE_L % Deflection of high-lift device, trailing edge, landing config (deg)
          C1 % Tabulated from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          C2 % Tabulatef from Fig 12.12, lambda = 0.23 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CL_max_base % Tabulated from Fig 12.13 (Raymer, 6th ed) & (C1 + 1)*(AR/beta)*cosd(Lambda_LE_deg) = 2.76.
          sharpness_param % Computed from Table 12.1 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          % Delta_CL_max % (Not using the one from Fig 12.14)
          CL_max_cl_max % Tabulated from Fig 12.9 (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed), Lambda_LE_deg = 40.
          cl_max % Obtained from page 14 of https://ntrs.nasa.gov/api/citations/19870017427/downloads/19870017427.pdf
          alpha_L0 % Zero-lift AOA (deg)
          k % Skin roughness factor
     end

     methods (Abstract)
          e_osw = get_e_osw(AR, Lambda_LE)
          LD_max = get_LD_max(AR, e_osw, CD0)
          % AR_wet = get_AR_wet(b, S_wet)
          K = get_K(e_osw, AR)
          K1 = compute_K1(M, AR, e_osw, LE_sweep)
          K2 = compute_K2(M, K1, CLminD)
          CD = get_CD(CD0, K, CL)
          CD0 = get_CD0(Cf, S_wet, S_ref)
          CDi = get_CDi(statevector, CL, e_osw, AR)
          Delta_CD0 = get_Delta_CD0(configuration, rangeMode) % This should get you the Delta_CD0 values you need. (use Raymer 12.61
          CL_minD = get_CL_minD(airfoil_type, CL_min, CD0)
          Cf = get_Cf(aircraft_type, n_engines) % Using L1 until a suitable replacement is found.
          CL_max = get_CL_max_values(aircraft_type, config, rangeMode) % This should get you the CL_max values you need (CL_max_TO, CL_max_Landing, etc)
          Delta_CL_max = get_Delta_CL_max_values(CL_max_dirty, CL_max_clean, isTakeoffOrLanding) % This should be able to get you the Delta_CL_max values you need.
          Delta_cl_max = get_Delta_cl_max_values(liftdevice, config, cp_c) % this should get you the values you need (Delta_cl_max_TO, Delta_cl_max_L)
          Delta_CDi = get_Delta_CDi(areFlapsFullOrHalfSpan, Delta_CL_flap, Lambda_cbar_q)
          CL_alpha = get_CL_alpha(M, cl_alpha, AR, S_exposed, S_ref, F, Lambda_max_t_deg)
          F = get_F(d, b)
     end
end