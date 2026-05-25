classdef F16PropulsionLevel1 < PropulsionModelLevel1
     %F16PROPULSIONESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          TSFC
          T0
          T_SL_dry
          T_SL_wet;
     end

     methods
          % Constructor
          function obj = F16PropulsionLevel1(design)
               engine_type = PropulsionUtils.classify_engine_type(design.propulsion_type);
               obj.T_SL_dry = design.propulsion.ThrustseaLevellbf.Dry;
               obj.T_SL_wet = design.propulsion.ThrustseaLevellbf.Wet;
               obj.TSFC = obj.get_TSFC(engine_type);
          end

          % For a level 1 estimate, we're using tabulated values based on
          % both the type of aircraft and engine.
          function TSFC = get_TSFC(propulsion_obj, engine_type)
               TSFC = PropulsionLevel1.get_TSFC(engine_type);
          end
     end

     methods (Access = private)

     end
end