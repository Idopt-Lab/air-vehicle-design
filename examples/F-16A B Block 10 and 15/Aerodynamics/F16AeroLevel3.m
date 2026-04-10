classdef F16AeroLevel3 < AerodynamicsModel
     %F16AEROLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 3 aerodynamics equations go here.

     properties
          Property1
     end

     methods
          function obj = F16AeroLevel3(inputArg1,inputArg2)
               %F16AEROLEVEL3 Construct an instance of this class
               %   Detailed explanation goes here
               obj.Property1 = inputArg1 + inputArg2;
          end

          function outputArg = method1(obj,inputArg)
               %METHOD1 Summary of this method goes here
               %   Detailed explanation goes here
               outputArg = obj.Property1 + inputArg;
          end
     end
end