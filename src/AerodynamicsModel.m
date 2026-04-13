classdef (Abstract) AerodynamicsModel < handle
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
          e_osw
          CL
          CD
          CD0
          K1
          K2
     end


     methods (Abstract)
          e_osw = get_e_osw(aero_obj, Aircraft, Mission, Requirements)
          DragResults = get_drag(aero_obj, geometry_obj, CD0, CL, Cf)
          % obj = aircraftname?, aircraft = excel book thing
     end
end