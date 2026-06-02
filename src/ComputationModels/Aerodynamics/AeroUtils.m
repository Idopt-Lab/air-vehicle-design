classdef AeroUtils
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     % This contains common functions I expect all Aero classes/objects to
     % use.

     methods (Static)
          % Get K1 subsonic value (Source: Brandt)
          function K1 = compute_K1_sub(AR, e_osw)
               K1 = 1/(pi*AR*e_osw);
          end

          % Get K1 supersonic value (Source: Brandt)
          function K1 = compute_K1_sup(AR, M, LE_sweep_deg)
               K1 = ((AR*(M^2 - 1))/(4*AR*sqrt(M^2 - 1)-2))*cosd(LE_sweep_deg);
          end

          % Get K2 subsonic value (Source: Brandt)
          function K2 = compute_K2_sub(K1, CLminD)
               K2 = -2*K1*CLminD;
          end

          % Get K2 supersonic value (Source: Brandt)
          function K2 = compute_K2_sup()
               K2 = 0; % This is always zero
          end

          % Get e_osw for a design
          function output = e_straight(AR)
               output = (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
          end

          function output = e_swept(AR, Lambda_LE_deg)
               output = (4.61*(1-0.045*AR^(0.68))*cosd(Lambda_LE_deg)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)
          end

          % Get CL for some given state
          function output = compute_CL(L, q, S_ref)
               CL = L./(q.*S_ref);
               output = CL;
          end

          % Get design drag
          function output = compute_D(q, CD, S_ref)
               D = CD*q*S_ref;
               output = D;
          end

          % Compute CDi
          % Compute CDi (subsonic case)
          function CDi = compute_CDi_subsonic(CL, e_osw, AR)
               CDi = ( (CL^2) / (pi * e_osw * AR));
          end

          % Compute CDi (supersonic case)
          function CDi = compute_CDi_supersonic(CL, alpha_deg)
               CDi = CL*sind(alpha_deg);
          end

          % Get dynamic pressure for some given state
          function output = compute_q(statevector)
               M = statevector(:, 1);
               h_ft = statevector(:, 2);
               [T,a,P,rho,nu,mu] = atmosisa(h_ft.*0.3048);
               a = a.*3.2808399; % Convert from m/s -> ft/s
               V = a.*M; % Get velocity (ft/s)
               rho = rho.*0.00194032033; % Convert from kg/m^3 -> imperial units
               q = 0.5.*rho.*V.^2; % lbf/ft^2
               output = q;
          end

          % Get airspeed for some given state
          function V = compute_airspeed(statevector)
               M = statevector(1);
               h_ft = statevector(2);
               [T,a,P,rho,nu,mu] = atmosisa(h_ft*0.3048);
               a = a*3.2808399; % Convert from m/s -> ft/s
               V = a*M; % Get velocity (ft/s)
          end

          % Compute V_stall (this is more performance than aero I think).
          function output = V_stall(W_S, CL_max, rho)
               output = sqrt(W_S*(1/(0.5*rho*CL_max)));
          end

     end
end