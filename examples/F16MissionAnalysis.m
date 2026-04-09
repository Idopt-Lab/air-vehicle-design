classdef F16MissionAnalysis < MissionAnalysisModel
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties

          missiondata % This is all the mission information. Altitudes, aerodynamics, etc.
          mission_fuel
          eps
     end

     methods
          % Decide if weight estimation goes in "MissionAnalysis" or
          % "WeightEstimation". Don't overcomplicate it.

          function obj = F16MissionAnalysis(chosenMission)
               arguments
                    chosenMission string = ""
               end

               if chosenMission == ""
                    return
               end

               obj.missiondata = get_mission_data(obj, chosenMission);
          end

          % Assign data to "missiondata" property (probably an extra layer
          % I can remove)
          function missiondata = get_mission_data(obj, Chosen_Mission)
               obj.missiondata = construct_mission_data(obj, Chosen_Mission);
          end

          % Compute mission fuel weight
          function mission_fuel = run_mission_analysis(mission_obj, constraint_obj, design)
               % segment_names = get_segment_names(obj, design, obj.missiondata);
               mission_fuel = compute_mission_fuel_weight(mission_obj, constraint_obj, design, mission_obj.missiondata);
          end

     end

     %% ----------------------------------------------------------
     % HELPER FUNCTIONS

     methods (Access = private)
          % Arguments should be design-specific geometric or aerodynamic
          % properties extracted from objects (... which are themselves the
          % design).



          function output = construct_mission_data(obj, Chosen_Mission)

               file_name = "Mission_Profile.xlsx";
               mission_name = Chosen_Mission; % This will be the SHEET the program checks for mission data!

               % Mission segments should scan row F8 until it encounters a blank
               mission_table = readtable(file_name, 'Sheet', mission_name, 'ReadRowNames', true);
               % Try cleaning up all cells


               % Extract some data from the mission segment setup
               segment_count = length(mission_table.Properties.VariableNames);
               rowcount = length(mission_table.Properties.RowNames);

               % Pre-allocate mission_segments for a nanosecond speed advantage (it's
               % worth it) (it's not lol)
               % mission_segments = strings(1, segment_count);
               % altitudes = zeros(1, segment_count);

               % Acquire segment names
               % Load segment names into an array or something (IN ORDER)
               % mission_segments(:) = string(mission_data.Properties.VariableNames(:));

               %% OBTAIN SEGMENT INFO
               % Extract rows from mission table
               % Load segment altitudes
               % altitudes(:) = table2array(mission_data("Altitude (ft)", mission_segments(:)));
               % payloads(:) = table2array(mission_data("Payload (lbf)", mission_segments(:))); % Payloads (all/relevant)
               % turns(:) = table2array(mission_data("Turns", mission_segments(:))); % Combat turns (combat)
               % range(:) = table2array(mission_data("Range (nm)", mission_segments(:))); % Segment range (cruise)
               % loiter_time(:) = table2array(mission_data("Loiter time (hrs)", mission_segments(:))); % Loitering time (loiter)

               % Cannot do this iteratively without expanding mission_data table to
               % incorporate new entries, first.
               % Make a new cell
               for i=1:segment_count % For each segment...
                    alt = mission_table{"Altitude (ft)", i}; % Get the altitude (ft)
                    [Temp, a, P, rho, nu, mu] = atmosisa(alt*0.3048); % Acquire atmospheric data (Kelvin, m/s, Pascals, kg/m^3, m^2/s, kg/(m*s)
                    % Density, pressure, temperature, local speed of sound, dynamic
                    % pressure
                    % Convert to imperial units
                    Temp = Temp*1.8; % Rankine
                    a = a/0.3048; % ft/s
                    P = P*0.00014504; % PSI
                    rho = rho*0.00194032033; % slug/ft^3
                    % rho = rho*0.0624279606; % lbm/ft^3
                    nu = nu/0.3048 * (1/0.3048); % ft^2/s
                    mu = mu * (0.06852177/1) * (0.3048/1); % slugs/(ft*s)

                    % Compute aerodynamic stuff
                    V = mission_table{"Mach number",i}*a;
                    q = 0.5*rho*(V^2);

                    % add data to corresponding segment
                    atmospheredata(:,i) = [Temp, a, P, rho, nu, mu, V, q]';
                    % mission_data = [mission_data;newdata]
                    % Move to next segment
               end

               % Concatenate new table onto mission table
               atmospheredata = array2table(atmospheredata,"VariableNames", mission_table.Properties.VariableNames, "RowNames", {'Temp (R)', 'a (ft/s)', 'P (psi)', 'rho (slug/ft^3)', 'nu (ft^2/s)', 'mu slugs/(ft*s)', 'V (ft/s)', 'q (lbf/ft^2)'});
               missiondata = [mission_table;atmospheredata];

               output = missiondata;

          end




          function segment_names = get_segment_names(obj, design, missiondata)
               segment_names = string(missiondata.Properties.VariableNames);

               for i=1:lenght(segment_names)
                    current_segment = segment_names(i);
                    mission.(current_segment) = missiondata(:, (current_segment));
               end

          end



          % This is where we actually compute the fuel for the mission
          function mission_fuel = compute_mission_fuel_weight(mission_obj, constraint_obj, design, missiondata)
               AR = design.geom.wings.Main("Aspect ratio");
               L_fus = design.geom.fuselage.Fuselage("Length (ft)");
               D_fus = design.geom.fuselage.Fuselage("Max width (ft)");
               c_root = design.geom.wings.Main("Root chord length (ft)");
               b_W = design.geom.wings.Main("Span (ft)");
               Cbar_W = design.geom.wings.Main("Mean geometric chord");
               lambda = design.geom.wings.Main("Taper ratio");
               Lambda_qc = design.geom.wings.Main("Taper ratio, qc");
               tc_root = design.geom.wings.Main("t/c");
               c_VT = design.geom.wings.VerticalTail("c_VT");
               c_HT = design.geom.wings.HorizontalTail("c_HT");
               BPR = design.propulsion.BypassRatio("Bypass Ratio");

               W_fixed = missiondata.Startup("Payload, fixed (lbf)");

               % W_S = 104.59;
               W_S = constraint_obj.optimal_WS;
               W_TO = 45000;
               tol = 1e-3;
               max_iteration = 40;
               results = [];
               S_ref = 0;
               T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)

               %% ----------------------------------------------------------------------

               for iteration = 1:max_iteration
                    S_ref = W_TO / W_S;
                    total_fuel_used = 0;

                    %% ----------------------------------------------------------------------
                    % Size the tail
                    [S_VT, S_HT] = Tail_Sizing(c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W);

                    %% ----------------------------------------------------------------------
                    % Estimate wetted areas
                    c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
                    d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
                    S_wet = 10^(c) * W_TO^(d); % ft^2

                    %% ----------------------------------------------------------------------
                    % Get thrust at takeoff
                    T0 = T_W*W_TO; % Fidelity III

                    [enginestats] = propulsion_est_IV(T0, missiondata.Dash("Mach number"), BPR);

                    %% ----------------------------------------------------------------------
                    % OEW update from wing and engine change
                    % WingDelta = WingDensity * (S_ref - W_TO/(W_S));
                    % EngineDelta = W_Engine - Engine_Sizing(T_W*W_TO);

                    % Loop stuff - should automate segment naming extraction
                    % (future)
                    [W_startup, f1] = segment_startup(W_TO);
                    [W_taxi, f2] = segment_taxi(W_startup);
                    [W_Takeoff, f3] = segment_takeoff(W_taxi);
                    [W_Climb, f4]   = segment_climb(W_TO, W_Takeoff, missiondata.Climb("Mach number"), S_ref, missiondata.Cruise("CD0"), missiondata.Cruise("e"), AR, missiondata.Loiter("TSFC"), missiondata.Climb("Altitude (ft)"), T0);
                    [W_Cruise, f5]  = segment_cruise(W_Climb, W_S, missiondata.Cruise("TSFC"), missiondata.Cruise("Range (ft)"), missiondata.Cruise("Mach number"), missiondata.Cruise("a (ft/s)"), missiondata.Cruise("q (lbf/ft^2)"), missiondata.Cruise("CD0"), missiondata.Cruise("e"), AR, W_TO, S_ref);
                    [W_Dash, f6]    = segment_dash(W_Cruise, S_ref, W_TO, missiondata.Dash("q (lbf/ft^2)"), missiondata.Dash("CD0"), missiondata.Dash("e"), AR, missiondata.Dash("TSFC"), missiondata.Dash("Range (ft)"), missiondata.Dash("Mach number") * missiondata.Dash("a (ft/s)"));
                    [W_Combat, f7]  = segment_combat(W_Dash, missiondata.Combat("Time (min)"), missiondata.Combat("TSFC"), missiondata.Combat("Payload, drop (lbf)"), missiondata.Combat("CD0"), missiondata.Combat("e"), AR, W_TO, missiondata.Combat("q (lbf/ft^2)"), S_ref);
                    [W_Cruise2, f8] = segment_cruise(W_Combat, W_S, missiondata.Cruise_1("TSFC"), missiondata.Cruise_1("Range (ft)"), missiondata.Cruise_1("Mach number"), missiondata.Cruise_1("a (ft/s)"), missiondata.Cruise_1("q (lbf/ft^2)"), missiondata.Cruise_1("CD0"), missiondata.Cruise_1("e"), AR, W_TO, S_ref);
                    [W_Loiter, f9]  = segment_loiter(W_TO, W_Cruise2, S_ref, missiondata.Loiter("q (lbf/ft^2)"), missiondata.Loiter("CD0"), missiondata.Loiter("e"), AR, missiondata.Loiter("Time (min)"), missiondata.Loiter("TSFC"));
                    [W_Landing, f10]         = segment_landing(W_Loiter, W_TO);
                    total_fuel_used = f1 + f2 + f3 + f4 + f5 + f6 + f7 + f8 + f9 + f10;
                    fuel_fraction = total_fuel_used * 1.06 / W_TO;

                    % Compute empty weight
                    W_engine_installed = 1.3*Engine_Sizing(T0); % Installed engine weight (lbf) (table 15.2, Raymer, 6th ed)
                    [empty_weight] = Compute_OEW_IV(W_TO, S_ref, S_HT, S_VT, S_wet, T0, design.weights, c_HT, c_VT, W_engine_installed);

                    % OEW - update new OEW fraction
                    empty_weight_fraction = empty_weight/W_TO;

                    % W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
                    W_TO_new = total_fuel_used + W_fixed + empty_weight;

                    difference = W_TO_new - W_TO;
                    percent_diff = 100 * difference / W_TO;

                    results(end+1, :) = [W_TO, W_fixed, fuel_fraction, empty_weight_fraction, empty_weight, W_TO_new, difference, percent_diff];

                    if abs(difference) < tol
                         break;
                    end
                    W_TO = W_TO_new;
                    S_ref = S_ref;
               end
               mission_fuel = total_fuel_used;
               S_ref = S_ref;
               beta = 1 - (total_fuel_used / (2 * W_TO));
               results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
          end




          function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
               W_by_W_TO = W / W_TO;
               W_by_S = W_by_W_TO * W_S;
               LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
          end

          function [LD_ratio] = compute_LD_revised(W, q, S, CD0, e, AR)
               CL = 2*W/(q*S);
               K = 1/(pi*e*AR);
               LD_ratio = CL/(CD0 + K * CL^2);
          end


          function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


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




          function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  S_ref)
               LD = compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end


          function [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
               n=20; % Number of segments
               seg_dist = Distance/n; % Divide the total distance into equi-spatial cruise segments.
               % Loop through the cruise segments
               % Compute the nth segment weight
               % Pass that into the next segment
               V = Mach * a;
               % disp("Starting loop...")
               LD = compute_LD_revised(W_in, q, S, CD0, e, AR);
               W_out = compute_revised_w_out(W_in, seg_dist, TSFC, V, LD);
               % WF = compute_weightfraction(TSFC, seg_dist, V, LD);
               fuel_used = W_in - W_out;
               % W_out = W_in - fuel_used;
               % seg_dist_i = 0;
               for i=2:n
                    % seg_dist_i = seg_dist - Distance; % Increment the segment distance
                    % LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
                    LD = compute_LD_revised(W_out, q, S, CD0, e, AR);
                    W_out = compute_revised_w_out(W_in, seg_dist, TSFC, V, LD);
                    % WF = compute_weightfraction(TSFC, seg_dist, V, LD);
                    fuel_used = W_in - W_out;
                    % W_out = W_in - fuel_used;
                    % disp("Segment " + i)
                    % disp("W_out: " + W_out + " lbf")
               end
               % disp("Exiting loop...")

          end

          function [W_out, fuel_used] = segment_dash(W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V)
               LD = compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
               WF = compute_weightfraction(TSFC, Distance, V, LD);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_landing(W_in, W_TO)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          function [W_out, fuel_used] = segment_loiter(W_TO, W_in, S_ref, q, CD0, e, AR, time, TSFC)
               LD = compute_revised_LD_ratio(W_in, q, S_ref, CD0, e, AR);
               WF = exp(-(time * 60 * TSFC / LD));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end


          function [W_out, fuel_used] = segment_startup(W_in)
               WF = 0.99;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_takeoff(W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end


          function [W_out, fuel_used] = segment_taxi(W_in)
               WF = 0.98;
               W_out = W_in*WF;
               fuel_used = W_in - W_out;
          end
     end
end