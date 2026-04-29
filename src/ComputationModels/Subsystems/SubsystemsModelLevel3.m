classdef (Abstract) SubsystemsModelLevel3 < handle
     %UBSYSTEMSMODELLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          internal_volume
          fuel_volume
     end

     methods (Abstract)
          internal_volume = get_internal_volume(subsys_obj, geometry_obj)
          fuel_volume = get_fuel_volume(subsys_obj, fuel_weight)
     end
end