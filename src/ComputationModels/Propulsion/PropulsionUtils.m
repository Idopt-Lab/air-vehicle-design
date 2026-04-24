classdef PropulsionUtils
     %PROPULSIONUTILS Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          T_std = 273.15; % Kelvin
          P_std = 100; %kPa
     end

     methods (Static)

          function output = theta(h_ft)
               [T] = atmosisa(h_ft*0.3048);
               output = T/PropulsionUtils.T_std;
          end
     end
end