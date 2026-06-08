classdef AeroUtils
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     % This contains common functions I expect all Aero classes/objects to
     % use.

     methods (Static)

          % Check if design is "low AR"
          % Raymer, 6th ed, eq 12.18
          function output = AR_check(AR_in,C1, Lambda_LE_deg)
               AR_comparison = 3/((C1+1) * cosd(Lambda_LE_deg));
               if (AR_in <= AR_comparison)
                    % Low AR
                    output = "Low";
               else
                    output = "High";
               end
          end

          % Get velocity, mu, and rho, given Mach number and altitude
          function output = get_V_and_mu(M, h_ft)
               [T, a, ~, rho] = atmosisa(h_ft*0.3048);
               rho = rho*0.00194032033; % Convert from kg/m^3 to imperial
               a = a*3.2808399; % Convert from m/s -> ft/s
               V = a*M;
               T = T*1.8; % Convert Kelvin to Rankine
               mu = AeroLevel3.mu(T);   % dynamic viscosity
               output = [V, mu, rho];
          end

          % % Get CL for some given state
          % function output = compute_CL(L, q, S_ref)
          %      CL = L./(q.*S_ref);
          %      output = CL;
          % end

          % Get design drag
          % function output = compute_D(q, CD, S_ref)
          %      D = CD*q*S_ref;
          %      output = D;
          % end

          % % Compute CDi
          % % Compute CDi (subsonic case)
          % function CDi = compute_CDi_subsonic(CL, e_osw, AR)
          %      CDi = ( (CL^2) / (pi * e_osw * AR));
          % end
          %
          % % Compute CDi (supersonic case)
          % function CDi = compute_CDi_supersonic(CL, alpha_deg)
          %      CDi = CL*sind(alpha_deg);
          % end

          % Obtain CL_max for a desired stalling speed
          % Source: Snorri Gudmundsson, General Aviation Aircraft Design,
          % 2nd edition, Appendix B.
          function output = CL_max_from_stall(q_stall, W_S)
               output = (1/q_stall)*W_S;
          end

          % Get dynamic pressure for some given state
          function output = q(statevector)
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