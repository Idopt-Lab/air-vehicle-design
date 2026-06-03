classdef (Abstract) ConstraintModel < handle
     %CONSTRAINTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          Wto_S_range
          optimal_WS
          min_TW
     end

     methods (Abstract) % Bare minimum requirements
          Wto_S = landing_constraint(distance, beta, rho, CLmax, CD0, mu)
          T_Wto = computeWingLoading(Wto_S, beta, alpha, n, q, V, CD0, K1, Ps) % I KNOW IT SAYS "COMPUTEWINGLOADING" BUT THE OUTPUT IS T/W RATIO.
          T_Wto = takeoff_constraint(Wto_S, V_Vstall, beta, alpha, rho, CLmax, distance, CD0, mu)
     end
end