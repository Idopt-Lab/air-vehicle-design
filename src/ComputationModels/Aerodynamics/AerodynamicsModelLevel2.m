classdef (Abstract) AerodynamicsModelLevel2 < handle
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
          e_osw % I have no idea what this is for (probably constraint analysis)
          Cf % Needed for constraint analysis
          CL_max % Needed for constraint analysis
          CL_minD % Needed for constraint analysis
          CD0 % Also constraint analysis
          K % Needed for CD calculations
          K1 % Needed for constraint analysis
          K2 % Needed for constraint analysis
     end


     methods (Abstract)
          % These should be like wrappers!
          e_osw = get_e_osw(aero_obj, e_osw) % Just manually input it, I think.
          CD0 = get_design_CD0(aero_obj, Cf, S_wet_aircraft, S_ref)
          CD = get_design_CD(aero_obj, CD0, K, CL);
          DragResults = get_design_drag(aero_obj, geometry_obj, state_input) % THE MEGA WRAPPER :O
          % obj = aircraftname?, aircraft = excel book thing
     end
end