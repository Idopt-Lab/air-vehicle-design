classdef AerodynamicsModelLevel1 < handle
     %AERODYNAMICSMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          e_osw
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

     end
end