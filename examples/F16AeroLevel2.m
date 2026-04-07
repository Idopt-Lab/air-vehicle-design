classdef F16AeroLevel2 < AerodynamicsModel
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.

     properties
          e_osw = 0;
          LD_cruise = 0;
     end

     methods


          function output = compute_e_osw(input1)
               % Level 2: Should be rough estimate.
               output = input1;
          end

          function output = compute_LoverD_cruise(input1)
               output = input1;
          end

          function output = compute_LD_revised(input1)
               output = input1;
          end
          
     end
end