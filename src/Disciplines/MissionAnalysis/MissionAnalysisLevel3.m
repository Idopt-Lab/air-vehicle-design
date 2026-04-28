classdef MissionAnalysisLevel3 < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties

          missiondata % This is all the mission_obj information. Altitudes, aerodynamics, etc.
          mission_fuel
     end

     methods
          % Constructor
          function obj = MissionAnalysisLevel3(Chosen_Mission)
               obj.missiondata = MissionAnalysisModel.get_mission_data(obj, Chosen_Mission);
          end

          % Compute mission fuel
          function [total_fuel_used, fuel_fraction] = get_mission_fuel(mission_obj, constraint_obj, design, geometry_obj, propulsion_obj, weight_obj)
               % This is where we actually compute the fuel for the mission
               AR = design.geom.wings.Main.AspectRatio;

               % W_S = 104.59;
               W_S = constraint_obj.optimal_WS;
               W_TO = weight_obj.W_TO;
               T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
               S_ref = geometry_obj.mainwings.S_ref;
               T0 = propulsion_obj.T0;

               % [enginestats] = propulsion_est_IV(T0, missiondata.Dash.MachNumber, BPR);

               % OEW update from wing and engine change
               % WingDelta = WingDensity * (S_ref - W_TO/(W_S));
               % EngineDelta = W_Engine - Engine_Sizing(T_W*W_TO);

               % Loop stuff - should automate segment naming extraction
               % (future)
               [W_startup, f1] = mission_obj.segment_startup(W_TO);
               [W_taxi, f2]    = mission_obj.segment_taxi(W_startup);
               [W_Takeoff, f3] = mission_obj.segment_takeoff(W_taxi);
               [W_Climb, f4]   = mission_obj.segment_climb(W_TO, W_Takeoff, mission_obj.missiondata.Climb.MachNumber, S_ref, mission_obj.missiondata.Cruise.CD0, mission_obj.missiondata.Cruise.e, AR, propulsion_obj.get_TSFC([mission_obj.missiondata.Climb.MachNumber, mission_obj.missiondata.Climb.Altitudeft], "dry", design.propulsion.ThrustseaLevellbf.Dry, design.propulsion.TSFCseaLevelperHour.Dry, design.propulsion.E.Dry, design.propulsion.F1.Dry, design.propulsion.F2.Dry, 1.0), mission_obj.missiondata.Climb.Altitudeft, T0);
               [W_Cruise, f5]  = mission_obj.segment_cruise(W_Climb, W_S, propulsion_obj.get_TSFC([mission_obj.missiondata.Cruise.MachNumber, mission_obj.missiondata.Cruise.Altitudeft], "dry", design.propulsion.ThrustseaLevellbf.Dry, design.propulsion.TSFCseaLevelperHour.Dry, design.propulsion.E.Dry, design.propulsion.F1.Dry, design.propulsion.F2.Dry, 1.0), mission_obj.missiondata.Cruise.Rangeft, mission_obj.missiondata.Cruise.MachNumber, mission_obj.missiondata.Cruise.afts, mission_obj.missiondata.Cruise.qlbfft2, mission_obj.missiondata.Cruise.CD0, mission_obj.missiondata.Cruise.e, AR, W_TO, S_ref);
               [W_Dash, f6]    = mission_obj.segment_dash(W_Cruise, S_ref, W_TO, mission_obj.missiondata.Dash.qlbfft2, mission_obj.missiondata.Dash.CD0, mission_obj.missiondata.Dash.e, AR, propulsion_obj.get_TSFC([mission_obj.missiondata.Dash.MachNumber, mission_obj.missiondata.Dash.Altitudeft], "wet", design.propulsion.ThrustseaLevellbf.Wet, design.propulsion.TSFCseaLevelperHour.Wet, design.propulsion.E.Wet, design.propulsion.F1.Wet, design.propulsion.F2.Wet, 1.0), mission_obj.missiondata.Dash.Rangeft, mission_obj.missiondata.Dash.MachNumber * mission_obj.missiondata.Dash.afts);
               [W_Combat, f7]  = mission_obj.segment_combat(W_Dash, mission_obj.missiondata.Combat.Timemin, propulsion_obj.get_TSFC([mission_obj.missiondata.Combat.MachNumber, mission_obj.missiondata.Combat.Altitudeft], "wet", design.propulsion.ThrustseaLevellbf.Wet, design.propulsion.TSFCseaLevelperHour.Wet, design.propulsion.E.Wet, design.propulsion.F1.Wet, design.propulsion.F2.Wet, 1.0), mission_obj.missiondata.Combat.PayloadDroplbf, mission_obj.missiondata.Combat.CD0, mission_obj.missiondata.Combat.e, AR, W_TO, mission_obj.missiondata.Combat.qlbfft2, S_ref);
               [W_Cruise2, f8] = mission_obj.segment_cruise(W_Combat, W_S, propulsion_obj.get_TSFC([mission_obj.missiondata.Cruise_1.MachNumber, mission_obj.missiondata.Cruise_1.Altitudeft], "dry", design.propulsion.ThrustseaLevellbf.Dry, design.propulsion.TSFCseaLevelperHour.Dry, design.propulsion.E.Dry, design.propulsion.F1.Dry, design.propulsion.F2.Dry, 1.0), mission_obj.missiondata.Cruise_1.Rangeft, mission_obj.missiondata.Cruise_1.MachNumber, mission_obj.missiondata.Cruise_1.afts, mission_obj.missiondata.Cruise_1.qlbfft2, mission_obj.missiondata.Cruise_1.CD0, mission_obj.missiondata.Cruise_1.e, AR, W_TO, S_ref);
               [W_Loiter, f9]  = mission_obj.segment_loiter(W_TO, W_Cruise2, S_ref, mission_obj.missiondata.Loiter.qlbfft2, mission_obj.missiondata.Loiter.CD0, mission_obj.missiondata.Loiter.e, AR, mission_obj.missiondata.Loiter.Timemin, propulsion_obj.get_TSFC([mission_obj.missiondata.Loiter.MachNumber, mission_obj.missiondata.Loiter.Altitudeft], "dry", design.propulsion.ThrustseaLevellbf.Dry, design.propulsion.TSFCseaLevelperHour.Dry, design.propulsion.E.Dry, design.propulsion.F1.Dry, design.propulsion.F2.Dry, 1.0));
               [W_Landing, f10]         = mission_obj.segment_landing(W_Loiter, W_TO);
               total_fuel_used = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10;
               fuel_fraction = total_fuel_used * 1.06 / W_TO;
          end
     end

     %% ----------------------------------------------------------
     % HELPER FUNCTIONS

     methods (Access = private)
          % Arguments should be design-specific geometric or aerodynamic
          % properties extracted from objects (... which are themselves the
          % design).
          % I probably don't even need this any more.
          function segment_names = get_segment_names(mission_obj, design, missiondata)
               segment_names = string(missiondata.Properties.VariableNames);
               for i=1:lenght(segment_names)
                    current_segment = segment_names(i);
                    mission.(current_segment) = missiondata(:, (current_segment));
               end
          end






          function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
               W_by_W_TO = W / W_TO;
               W_by_S = W_by_W_TO * W_S;
               LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
          end

          function [LD_ratio] = compute_LD_revised(mission_obj, W, q, S, CD0, e, AR)
               CL = 2*W/(q*S);
               K = 1/(pi*e*AR);
               LD_ratio = CL/(CD0 + K * CL^2);
          end


          function [WF] = compute_weightfraction(mission_obj, TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Climb segment - revised
          function [W_out, fuel_used] = segment_climb(mission_obj, W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
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




          function [W_out, fuel_used] = segment_combat(mission_obj, W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  S_ref)
               LD = mission_obj.compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end


          function [W_out, fuel_used] = segment_cruise(mission_obj, W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
               n=20; % Number of segments
               seg_dist = Distance/n; % Divide the total distance into equi-spatial cruise segments.
               % Loop through the cruise segments
               % Compute the nth segment weight
               % Pass that into the next segment
               V = Mach * a;
               % disp("Starting loop...")
               LD = mission_obj.compute_LD_revised(W_in, q, S, CD0, e, AR);
               W_out = mission_obj.compute_revised_w_out(W_in, seg_dist, TSFC, V, LD);
               % WF = compute_weightfraction(TSFC, seg_dist, V, LD);
               fuel_used = W_in - W_out;
               % W_out = W_in - fuel_used;
               % seg_dist_i = 0;
               for i=2:n
                    % seg_dist_i = seg_dist - Distance; % Increment the segment distance
                    % LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
                    LD = mission_obj.compute_LD_revised(W_out, q, S, CD0, e, AR);
                    W_out = mission_obj.compute_revised_w_out(W_in, seg_dist, TSFC, V, LD);
                    % WF = compute_weightfraction(TSFC, seg_dist, V, LD);
                    fuel_used = W_in - W_out;
                    % W_out = W_in - fuel_used;
                    % disp("Segment " + i)
                    % disp("W_out: " + W_out + " lbf")
               end
               % disp("Exiting loop...")

          end

          function [W_out, fuel_used] = segment_dash(mission_obj, W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V)
               LD = mission_obj.compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
               WF = mission_obj.compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_landing(mission_obj, W_in, W_TO)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_loiter(mission_obj, W_TO, W_in, S_ref, q, CD0, e, AR, time, TSFC)
               LD = mission_obj.compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end


          function [W_out, fuel_used] = segment_startup(mission_obj, W_in)
               WF = 0.99;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_takeoff(mission_obj, W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_taxi(mission_obj, W_in)
               WF = 0.98;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end

          function [W_out] = compute_revised_w_out(mission_obj, W_in, seg_dist, TSFC, V, LD)
               W_out = W_in * exp( -(seg_dist*TSFC)/(V*LD));
          end
     end
end