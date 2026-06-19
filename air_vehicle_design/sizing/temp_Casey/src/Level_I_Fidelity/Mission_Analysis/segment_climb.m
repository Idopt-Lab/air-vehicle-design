% Climb segment - revised
     function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
          g = 32.2; % Acceleration due to gravity (ft/s^2)
          r_e = 20902231; % Radius of Earth (and your mom) (ft)
          n = 20; % Number of segments
          % h = 40000; % desired climb altitude (ft)
          h_increments = linspace(0, h, n);
          T = T0; % Sea level thrust, lbf (dry)

          % Increment altitude
          current_h = h_increments(2);

          % Initialize gravity height array
          gh = ones(1,n);
          gh = gh.*g;

          % Extract density at current altitude
          [~, ~, ~, rho] = atmosisa(current_h);
          rho = rho*0.00194032033; % Convert kg/m^3 into slugs/ft^3

          V = zeros(1,n);

          V(2) = sqrt( (W_in/S)/(3*rho*CD0) * (T/W_in) + sqrt((T/W_in)^2 + 12*CD0*(1/(pi * e * AR))));

          % Compute q
          q = 0.5*rho*V(2)^2;

          CL = (2*W_in)/(q*S);
          CD = CD0 + (1/(pi*e*AR))*CL^2;
          D = q*S*CD;

          % Compute g at new altitude
          gh(2) = g*(r_e/(r_e + current_h))^2;

          he_1 = h_increments(2) + (V(2)^2)/(2*gh(1));
          he_2 = h_increments(1) + (V(1)^2/(2*gh(2)));
          delta_he = he_2 - he_1;
          WF_climb = exp( -((TSFC) * delta_he)/(V(2)*(1-D/T)));
          W_new = WF_climb*W_in;
          % WF_Climb = 1.0065 - 0.0325 * Mach;
          fuel_used = W_in - W_new;
          % W_out = W_in - fuel_used;

          for i=3:n
               % Update rho with new altitude
               current_h = h_increments(i);
               [~, ~, ~, rho] = atmosisa(current_h);
               rho = rho*0.00194032033; % Convert kg/m^3 into slugs/ft^3
               V(i) = sqrt( (W_new/S)/(3*rho*CD0) * (T/W_new) + sqrt((T/W_new)^2 + 12*CD0*(1/(pi * e * AR))));
               q = 0.5*rho*V(i)^2;
               CL = (2*W_new)/(q*S);
               CD = CD0 + (1/(pi*e*AR))*CL^2;
               D = q * S*CD;
               he_1 = h_increments(i-1) + (V(i-1)^2)/(2*g);
               he_2 = h_increments(i) + (V(i)^2/(2*g));
               delta_he = he_2 - he_1;
               WF_climb = exp( -((TSFC) * delta_he)/(V(i)*(1-D/T)));
               W_old = W_new;
               W_new = WF_climb*W_old;
               % WF_Climb = 1.0065 - 0.0325 * Mach;
               % W_out = W_in - fuel_used;
          end
          W_out = W_new;
          fuel_used = W_in - W_out;
     end