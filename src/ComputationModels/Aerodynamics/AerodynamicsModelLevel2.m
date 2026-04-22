classdef (Abstract) AerodynamicsModelLevel2 < handle
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
          % These should be like wrappers!
          e_osw = get_e_osw(aero_obj, Aircraft, Mission, Requirements)
          CD0 = get_design_CD0(aero_obj, Cf, S_wet_aircraft, S_ref)
          CD = get_design_CD(aero_obj, CD0, K, CL);
          DragResults = get_design_drag(aero_obj, geometry_obj, state_input) % THE MEGA WRAPPER :O
          % obj = aircraftname?, aircraft = excel book thing
     end
end