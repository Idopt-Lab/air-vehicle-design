classdef (Abstract) PropulsionModelLevel3 < PropulsionBase
     %PROPULSIONMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          T0 % This is your guess thrust, for the sizing script.
     end

     methods (Abstract)
          TSFC = get_TSFC()
     end
end