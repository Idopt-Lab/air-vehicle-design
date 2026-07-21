classdef (Abstract) PropulsionModelLevel2 < PropulsionBase
     %PROPULSIONMODELLEVEL2 Summary of this class goes here
     %   This is for preliminary estimation.

     properties (Abstract)
          engine_type
          T0 % This is your guess thrust, for the sizing script.
     end

     methods (Abstract)
          TSFC = get_TSFC(propulsion_obj, engine_type, state_input, theta, mil_or_max_power)
     end
end