classdef PropulsionUtils
     %PROPULSIONUTILS Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          T_std = 273.15; % Kelvin
          P_std = 100; %kPa
          gamma = 1.4;
     end

     methods (Static)

          function output = theta(T_kelvin)
               output = T_kelvin/PropulsionUtils.T_std;
          end

          function output = delta(P_kPa)
               output = P_kPa/PropulsionUtils.P_std;
          end
     end
end