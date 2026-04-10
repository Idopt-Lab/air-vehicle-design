classdef F16PropulsionEstLevel1 < PropulsionModel
     %F16PROPULSIONESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginestats
          TSFC
     end

     methods

          % Should estimate TSFC via historical regression or something
          function enginestats = get_propulsion_stats(input)

          end

     end
end