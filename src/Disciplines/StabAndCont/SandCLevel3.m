classdef SandCLevel3 < SandCModelLevel3
     %SANDCLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          CG
          NP
          C_of_L
     end

     methods
          function obj = SandCLevel3(design)
               %SANDCLEVEL3 Construct an instance of this class
               %   Detailed explanation goes here
               obj.Property1 = inputArg1 + inputArg2;
          end

          % Estimate longitudinal location of CG
          function output = get_CG(stability_obj, weight_obj)
               % Function accepts arguments of weight. Uses longitudinal
               % location of weight components to estimate CG location

          end

          % Get MAC of a wing
          function output = get_MAC(stability_obj, c_root, lambda)
               output = (2/3)*c_root*((1+lambda+lambda^2)/(1+lambda));
          end

          % Compute MAC of a lifting surface (y)
          function output = get_y_MAC(stability_obj, b, lambda)
               output = (b/6)*(1 + 2*lambda)/(1+lambda);
          end

          % Compute MAC of a lifting surface (x)
          function output = get_x_MAC(stability_obj, x_loc_wing, y_MAC, Lambda_LE_deg)
               output = x_loc_wing + y_MAC*tand(Lambda_LE_deg);
          end

          % Compute the X-Location of the MAC of a wing
          function output = get_ac_wing(stability_obj, x_MAC, MAC)
               output = x_MAC + 0.25*MAC;
          end
     end
end