classdef (Abstract) AeroBase < handle
     %AEROBASE Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          CL
          CL_minD % Even without an explicit airfoil declaration, user may assume a flat plate, and set CL_minD = CL at CD0; CL = 0. Therefore, CL_minD = 0.
          K
          K1
          K2 % CONSIDER: K2 isn't required at all levels because it requires
          % CL_minD, which requires the airfoil... which isn't at L1,
          % unless using a flat plate.
          CD
          CD0
          CDi
          CL_max
          e_osw_clean
          CL_max_clean
          Cf
     end

     methods (Abstract)
          e_osw_clean = get_e_osw_clean(AR, Lambda_LE) % This function is supposed to COMPUTE e_osw, without accounting for flaps
          CD = get_CD(CD0, K, CL)
          CD0 = get_CD0_simple(Cf, S_wet, S_ref) % This is the "simplified" form of CD0 estimation. Could be useful for comparison with the component-level buildup method.
          CDi = get_CDi(statevector, CL, e_osw, AR)
          CL_max_clean = get_CL_max_values(aircraft_type, config, rangeMode)
          CL = get_CL(L, q, S_ref)
          K1 = compute_K1(M, AR, e_osw, LE_sweep)
          K2 = compute_K2(M, K1, CLminD)
          Cf = get_Cf(aircraft_type, n_engines)
     end
end