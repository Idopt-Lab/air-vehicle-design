classdef (Abstract) PropulsionModelLevel2 < handle
     %PROPULSIONMODELLEVEL2 Summary of this class goes here
     %   This is for preliminary estimation.

     properties (Abstract) % Possibly unnecessary in general
          TSFC
     end

     methods (Abstract)
          TSFC = get_TSFC_installed(propulsion_obj, engine_type, state_input, theta, mil_or_max_power)
     end
end