classdef AerodynamicsModelLevel1 < handle
     %AERODYNAMICSMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          e_osw_clean % e, clean (no flaps, no gear down/out)
          e_osw_TO % e, flaps in take-off config
          e_osw_Landing % e, flaps in landing config
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
          CL_max_Land
          Delta_CD0_TO % Change in CD0 due to flaps in take-off configuration
          Delta_CD0_Landing % Change in CD0 due to flaps in landing config
          Delta_CD0_geardown % Change in CD0 due to landing gear down/out
     end

     methods (Abstract)
          e_osw = get_e_osw(AR, Lambda_LE)
          LD_max = get_LD_max(aircraft_type)
          AR_wet = get_AR_wet(b, S_wet)
          K = get_K(e_osw, AR)
          K1 = compute_K1(M, AR, e_osw, LE_sweep)
          K2 = compute_K2(M, K1, CLminD)
          CD = get_CD(CD0, K, CL)
          CD0 = get_CD0(Cf, S_wet, S_ref)
          CDi = get_CDi(statevector, CL, e_osw, AR)
          Delta_CD0 = get_Delta_CD0(aircraft_type, configuration)

     end
end