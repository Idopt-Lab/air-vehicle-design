classdef PropulsionUtils
     %PROPULSIONUTILS Summary of this class goes here
     %   Detailed explanation goes here

     properties
          T_std = 273.15; % Kelvin
          P_std = 100; %kPa
     end

     methods (Static)

          function output = theta(T_kelvin)
               %METHOD1 Summary of this method goes here
               %   Detailed explanation goes here
               output = T_kelvin/PropulsionUtils.T_std;
          end
     end
end