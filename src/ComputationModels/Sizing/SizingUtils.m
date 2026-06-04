classdef SizingUtils
     %SIZINGUTILS Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          mu_G = SizingUtils.groundfrictioncoefficienttable();
     end

     methods (Static)

          function output = groundfrictioncoefficienttable()
               surface_type = [
                    "Concrete"
                    "Asphalt"
                    "Hard Turf"
                    "Short Grass"
                    "Long Grass"
                    "Soft Ground"
               ];

               mu_G_min = [
                    0.02
                    0.02
                    0.05
                    0.05
                    0.10
                    0.10
               ];

               mu_G_max = [
                    0.03
                    0.03
                    0.05
                    0.05
                    0.10
                    0.30
               ];

               mu_G_nominal = [
                    0.025
                    0.025
                    0.05
                    0.05
                    0.10
                    0.20
               ];

               output = table( ...
                    surface_type, ...
                    mu_G_min, ...
                    mu_G_max, ...
                    mu_G_nominal, ...
                    'VariableNames', {'SurfaceType', 'mu_G_min', 'mu_G_max', 'mu_G_nominal'});
          end

     end
end