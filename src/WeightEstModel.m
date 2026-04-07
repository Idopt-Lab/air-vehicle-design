classdef (Abstract) WeightEstModel
     %WEIGHTESTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          MTOW
          total_fuel_used
          eps % Error tolerance
     end

     methods (Abstract)
          MTOW = compute_MTOW(input)

     end
end