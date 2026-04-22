classdef (Abstract) AerodynamicsModelLevel3 < handle
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
          airfoiltype % either "cambered" or "uncambered." Leave empty if NOT AIRFOIL.
          e_osw
          alpha_L0_deg
          Cf
          CL
          CL_alpha
          CL_max
          CL_minD
          CD0
          CD
          D
          K
          K1
          K2
          R_components
          R_cutoff
          k
          FF
          Q
          DragResults
     end


     methods (Abstract)
          % These should be like wrappers!
          e_osw = get_e_osw(aero_obj, AR, Lambda_LE)
          CD0 = get_design_CD0(aero_obj, statevector, geometry_obj, design)
          CD = get_design_CD(aero_obj, CD0, CDi, CL, CL_minD, airfoiltype, statevector, K1);
          CL_minD = compute_CL_minD(aero_obj, CL_alpha, alpha_L0_deg)
          CL_alpha = get_CL_alpha(aero_obj, statevector, S_exposed, S_ref, Lambda_max_t, Lambda_LE_deg, AR, fuselage_width, b)
          CDi_design = get_design_CDi(aero_obj, statevector, S_ref, e_osw, AR, L)
          DragResults = get_design_drag(aero_obj, geometry_obj, design, propulsion_obj, W, state_input, airfoiltype) % THE MEGA WRAPPER :O
          % obj = aircraftname?, aircraft = excel book thing
     end
end