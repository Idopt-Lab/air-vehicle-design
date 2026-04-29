classdef PropulsionLevel1
     %F16PROPULSIONESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginestats
          TSFC
          T0
     end

     methods

          % Constructor
          function obj = PropulsionLevel1(design)
               engine_type = PropulsionUtils.classify_engine_type(design.propulsion_type);
               obj.TSFC = obj.get_TSFC(engine_type);
          end

          % Get TSFC (1/sec)
          function TSFC = get_TSFC(propulsion_obj, engine_type)

               % Need to normalize input here, too
               engine_type = PropulsionUtils.classify_engine_type(engine_type);

               if (engine_type == "turbojet")
                    TSFC.cruise = 0.9 * (1/3600);
                    TSFC.loiter = 0.8 * (1/3600);
               elseif (engine_type == "low_bypass_mixed_turbofan")
                    TSFC.cruise = 0.8 * (1/3600);
                    TSFC.loiter = 0.7 * (1/3600);
               elseif (engine_type == "high_bypass_mixed_turbofan")
                    TSFC.cruise = 0.5 * (1/3600);
                    TSFC.loiter = 0.4 * (1/3600);
               elseif (engine_type == "Piston_prop_fixed_pitch")
                    TSFC.cruise = 0.4 * (1/3600);
                    TSFC.loiter = 0.5 * (1/3600);
               elseif (engine_type == "Piston_prop_variable_pitch")
                    TSFC.cruise = 0.4 * (1/3600);
                    TSFC.loiter = 0.5 * (1/3600);
               elseif (engine_type == "turboprop")
                    TSFC.cruise = 0.9 * (1/3600);
                    TSFC.loiter = 0.8 * (1/3600);
               else
                    error("Couldn't identify engine type.")
               end

               propulsion_obj.TSFC = TSFC;
          end

     end
end