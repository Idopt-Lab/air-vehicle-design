classdef (Abstract) AeroUtils < handle
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     % This contains common functions I expect all Aero classes/objects to
     % use.

     properties (Abstract) % Initialization not allowed
     end


     methods (Abstract)
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