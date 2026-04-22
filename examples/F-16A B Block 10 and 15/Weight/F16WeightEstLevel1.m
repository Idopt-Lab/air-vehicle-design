classdef F16WeightEstLevel1 < WeightModelLevel3
     %F16WEIGHTESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          MTOW
          wings
          tail
          subsystems
          engine
          landinggear
          eps % Error tolerance
          W_fixed
     end

     methods
          % function obj = F16WeightEstLevel1(inputArg1,inputArg2)
          %      %F16WEIGHTESTLEVEL1 Construct an instance of this class
          %      %   Detailed explanation goes here
          %      obj.Property1 = inputArg1 + inputArg2;
          % end

          % Estimate subsystem weight
          function output = get_subsystem_weight(weight_obj)
               % This isn't implemented for this fidelity level
               disp("This isn't implemented for this fidelity level")
               output = null;
          end

          % Estimate engine weight
          function output = get_engine_weight(weight_obj)
               % Some sort of regression that estimates engine weight.
               disp("This isn't implemented for this fidelity level")
               output = null;
          end
          % I may need to remove this reference for lower-fidelity sizing
          % classes (<3)

          % Estimate OEW (Raymer, 6th ed, Table 6.1)
          function output = get_OEW(weight_obj, W_TO)
               % Hard-coding some values (placeholders)
               a = 2.34;
               b = -0.13;

               OEW_frac = a*W_TO^b;

               output = OEW_frac*W_TO;
          end
     end
end