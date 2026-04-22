classdef PropulsionLevel1 < PropulsionModelLevel3
     %F16PROPULSIONESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginestats
          TSFC
          T0
     end

     methods

          % Should estimate TSFC via historical regression or something
          % Do I want to create the historical regression here, or should I
          % expect the user to enter it from their own work?
          function enginestats = get_propulsion_stats(obj, TSFC)
               TSFC = get_TSFC(obj, TSFC);
          end

          % Get TSFC
          function TSFC = get_TSFC(obj, TSFC)
               TSFC = compute_TSFC(obj, TSFC);
          end

     end

     methods (Access = private)

          % "Compute" TSFC.
          function TSFC = compute_TSFC(obj, TSFC)
               TSFC = TSFC;
          end

     end
end