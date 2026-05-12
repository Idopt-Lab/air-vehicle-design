classdef F16AeroLevel3 < AerodynamicsModelLevel3
     %F16AEROLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 3 aerodynamics equations go here.
     % Should utilize textbook methods, like Raymer and Nicolai.
     % Should compute:
     %    - drag (CD, CD0 [sub & sup])
     %    - lift
     %    - Mach drag divergence
     %    - Sears-Haack stuff? (Should probably leave that to Level IV)
     % USE STUFF FROM AERO LEVEL 4 YOU'VE ALREADY DONE THIS

     properties
          % Are these for the entire design, or for a specific component?
          % I could pick the "component" interpretation. That would be
          % specific enough to stop overthinking stuff.
          % Each "object" could be an individual part of the design.
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

     methods
          % Put high-level function wrappers here!

          % Constructor
          function obj = F16AeroLevel3(design)
               % Stuff
          end
     end

end