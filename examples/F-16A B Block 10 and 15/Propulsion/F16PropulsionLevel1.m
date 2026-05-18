classdef F16PropulsionLevel1 < PropulsionModelLevel1
     %F16PROPULSIONESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginestats
          TSFC
          T0
     end

     methods
          % Constructor
          function obj = F16PropulsionLevel1(design)
               engine_type = PropulsionUtils.classify_engine_type(design.propulsion_type);
               obj.TSFC = obj.get_TSFC(engine_type);
          end

          function TSFC = get_TSFC(propulsion_obj, engine_type)
               TSFC = PropulsionLevel1.get_TSFC(engine_type);
          end
     end

     methods (Access = private)

     end
end