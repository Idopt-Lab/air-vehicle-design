classdef ConstraintAnalysisClass
     %F16CONSTRAINTEST Summary of this class goes here
     %   Detailed explanation goes here
     % YTup

     properties (Constant) % So these are the CONSTRAINT RESULTS, compared to the CONSTRAINTS THEMSELVES IN THE DESIGN!!!
          Wto_S_range = 20:7:160
     end

     methods (Static)

          % % Solve for the optimal point
          % function [optimal_WS, min_TW] = solveOptimalPoint(obj, TW_table, T_Wto_takeoff, Wto_S_range)
          %      obj.T_Wto_required = max([TW_table; T_Wto_takeoff], [], 1);
          %      [min_TW, min_idx] = min(obj.T_Wto_required);
          %      optimal_WS = Wto_S_range(min_idx);
          % end

          % Solve for landing constraints
          function Wto_S = landing_constraint(distance, beta, rho, CLmax, CD0, mu)
               g = 32.174;

               Wto_S = (distance * rho * g * (mu * CLmax + 0.83 * CD0)) / (1.69 * beta);
          end


          % Master Equation
          function T_Wto = computeWingLoading(Wto_S, beta, alpha, n, q, V, CD0, K1, Ps)
               % beta = constraints.W_Wto;
               % alpha = thrust.throttleLapse;
               % n = constraints.n;
               % q = aero.("q (lbf/ft^2)");
               % V = aero.("V (ft/s)");
               % CD0 = aero.("CD0"); % Values should emerge from calculations performed here
               % % Validate functionality independence of fidelity level (should work
               % % for all)
               % K1 = aero.K1;
               % Ps = constraints.PS_ft_s_;

               z = (n .* beta) ./ q;
               induced = K1 .* (z.^2) .* Wto_S;
               linear_drag = CD0 ./ Wto_S;
               parasite = Ps ./ V;

               T_Wto = (beta ./ alpha) .* (q ./ beta .* (linear_drag + induced) + parasite);
          end

          %% ---------------------------------------------------
          % Takeoff Constraint
          function T_Wto = takeoff_constraint(Wto_S, V_Vstall, beta, alpha, rho, CLmax, distance, CD0, mu)
               g = 32.174;

               term1 = V_Vstall.^2 .* beta^2 .* Wto_S ./ (alpha * rho * CLmax * g * distance);
               term2 = 0.7 * CD0 / (beta * CLmax) + mu;
               T_Wto = term1 + term2;
          end

     end

     % HELPER METHODS
     methods (Access = private)



     end
end