classdef (Abstract) AerodynamicsModel
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
     end


     methods (Abstract)
          e_osw = compute_e_osw(obj, Aircraft, Mission, Requirements)
          DragResults = compute_drag(obj, Aircraft, Mission, Requirements)
          % obj = aircraftname?, aircraft = excel book thing
     end
end