classdef AeroLevel2
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     properties (Constant)
          k_lambda = [0.88, 0.95]
     end

     methods (Static)

          

          % Get CD
          function CD = compute_CD(CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               CD = CD0 + K*CL^2;
          end

          % Get CD0
          function CD0 = compute_CD0(Cf, S_wet_aircraft, S_ref)
               CD0 = Cf * S_wet_aircraft/S_ref;
          end

          % Estimate CL_max_w (clean)
          % Source: Airplane Design Vol 2, Roskam, eq 7.3
          function output = CL_max_w(cl_max_r, cl_max_t)
               if (0.4 < lambda) && (lambda <= 1.0)
                 % use k_lambda = 0.88 (k_lambda(1))
                 output = k_lambda(1)*(cl_max_r + cl_max_t)^(2);
               elseif (0.0 < lambda) && (lambda <= 0.4)
                    output = k_lambda(2)*(cl_max_r + cl_max_t)^(2);
               else
                    error("Error handler.")
               end
          end

     end

     methods (Access = private)
     end
end