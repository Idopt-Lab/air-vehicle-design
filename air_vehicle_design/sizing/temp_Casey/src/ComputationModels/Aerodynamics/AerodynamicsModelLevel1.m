classdef (Abstract) AerodynamicsModelLevel1 < AeroBase
     %AERODYNAMICSMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     % These are the properties that MUST BE IMPLEMENTED BY SUBCLASSES.
     properties (Abstract)
          LD_max
          AR_wet
     end

     % These are the method functions that MUST BE IMPLEMENTED BY
     % SUBCLASSES.
     methods (Abstract)
          % e_osw_clean = get_e_osw(AR, Lambda_LE) % This function is supposed to COMPUTE e_osw
          LD_max = get_LD_max(aircraft_type, b, S_wet) % You'll also need AR_wet for this.
          AR_wet = get_AR_wet(b, S_wet)
          % K = get_K(e_osw, AR)
          % K1 = compute_K1(M, AR, e_osw, LE_sweep)
          % K2 = compute_K2(M, K1, CLminD)
          % CD = get_CD(CD0, K, CL)
          CD0 = get_CD0(Cf, S_wet, S_ref)
          % CDi = get_CDi(statevector, CL, e_osw, AR)
          % CL_minD = get_CL_minD(airfoil_type, CL_min, CD0)
          % Cf = get_Cf(aircraft_type, n_engines)
          % CL_max = get_CL_max_values(aircraft_type, config, rangeMode)
          % CL = get_CL(L, q, S_ref)
     end
end