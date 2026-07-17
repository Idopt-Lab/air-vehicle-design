classdef Atmosphere < handle
     %ATMOSPHERE This class contains properties pertaining to the
     %atmosphere being used (sea level conditions, possbibly even
     %composition)
     %   Detailed explanation goes here

     properties (SetAccess = immutable)
          rho_sl = 27.45*10^(-4); % Density (Slugs/ft^3)
          t_sl = 518.67; % Temperature (Rankine)
          p_sl = 14.696*144; % Pressure (lb/ft^2)
          mu = 3.737*10^(-7); % Dynamic viscosity (lb*s/ft^2)
     end
end