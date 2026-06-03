classdef (Abstract) AerodynamicsModelLevel2 < handle
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
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
          cl_max_TO
          cl_max_L
          CL_minD
          CL_max_clean
          CL_max_TO
          CL_max_L
          Delta_CL_max_TO
          Delta_CL_max_L
          Delta_cl_max_TO % Contribution from high-lift devices (take-off config)
          Delta_cl_max_L % Contribution from high-lift devices (landing config)
          Delta_CD0_TO
          Delta_CD0_Landing
          Delta_CD0_geardown
          Delta_CDi
          % I should definitely add the properties of high-lift devices'
          % deflections for take-off and landing configurations, as well as
          % properties for their types.
     end

     properties (Abstract, Constant)
          hld_TE
          hld_LE
          delta_hld_TE_TO
          delta_hld_TE_L
          C1
          C2
          CL_max_base
          sharpness_param
          CL_max_cl_max
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
          cl_max = get_cl_max()
     end
end