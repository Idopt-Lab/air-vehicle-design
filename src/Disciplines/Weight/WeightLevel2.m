classdef WeightLevel2 < WeightModelLevel3
     %F16WEIGHTESTLEVEL2 Summary of this class goes here
     %   Detailed explanation goes here
     % This is NOT purely component-level.

     properties
          MTOW
          OEW
          W_fixed
     end

     methods
          % Constructor
          % function obj = F16WeightEstLevel2(inputArg1,inputArg2)
          %      %F16WEIGHTESTLEVEL2 Construct an instance of this class
          %      %   Detailed explanation goes here
          %      obj.Property1 = inputArg1 + inputArg2;
          % end

          % Estimate OEW (Raymer, 6th ed, Table 6.1)
          function output = get_OEW(weight_obj, W0, AR, T, S_ref, M_max, K_vs)
               % Hard-coding some values (placeholders)
               a = -0.02;
               b = 2.16;
               c1 = -0.10;
               c2 = 0.20;
               c3 = 0.04;
               c4 = -0.10;
               c5 = 0.08;
               output = (a + b*W0^(c1) * AR^(c2) * (T/W0)^(c3) * (W0/S_ref)^(c4) * M_max^(c5))*K_vs;
          end
     end
end