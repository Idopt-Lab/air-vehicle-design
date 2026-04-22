classdef (Abstract) AerodynamicsModelLevel3 < handle
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
          CD0 = get_design_CD0(aero_obj, statevector, geometry_obj, design)
          CD = get_design_CD(aero_obj, statevector, geometry_obj);
          DragResults = get_design_drag(aero_obj, statevector, CD0, CL, Cf) % THE MEGA WRAPPER :O
          % obj = aircraftname?, aircraft = excel book thing
     end

     methods (Static)
          % Get CL for some given state
          function output = compute_CL(aero_obj, L, q, S_ref)
               CL = L/(q*S_ref);
               output = CL;
          end

          % Get design drag
          function output = compute_D(aero_obj, q, CD, S_ref)
               D = CD*q*S_ref;
               output = D;
          end

          % Get dynamic pressure for some given state
          function output = compute_q(aero_obj, statevector)
               M = statevector(1);
               h_ft = statevector(2);
               [T,a,P,rho,nu,mu] = atmosisa(h_ft*0.3048);
               a = a*3.2808399; % Convert from m/s -> ft/s
               V = a*M; % Get velocity (ft/s)
               rho = rho*0.00194032033; % Convert from kg/m^3 -> imperial units
               q = 0.5*rho*V^2; % lbf/ft^2
               output = q;
          end
          
     end
end