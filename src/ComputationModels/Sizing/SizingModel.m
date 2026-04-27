classdef SizingModel
     %SIZINGMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          results_table
     end

     methods (Abstract)
          size_aircraft(sizing_obj, design, geometry_obj, mission_obj, weight_obj, propulsion_obj, constraint_obj, requirements_obj)
     end
end