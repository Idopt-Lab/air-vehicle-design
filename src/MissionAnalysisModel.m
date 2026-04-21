classdef (Abstract) MissionAnalysisModel < handle
     %MISSIONANALYSISMODEL Summary of this class goes here
     %   Detailed explanation goes here
     % THIS IS FOR ESTIMATING MISSION FUEL
     % MISSION FUEL, NOT MTOW
     % BUT MISSION FUEL IS IMPORTANT FOR ESTIMATING MTOW

     properties (Abstract)
          % What the heck do I put here?
          % MTOW
          missiondata
          mission_fuel
          eps
     end

     methods (Abstract)
          mission_fuel = get_mission_fuel(mission_obj, constraint_obj, design)
          % [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
          % [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  S_ref)
          % [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
          % [W_out, fuel_used] = segment_dash(W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V)
          % [W_out, fuel_used] = segment_landing(W_in, W_TO)
          % [W_out, fuel_used] = segment_loiter(W_TO, W_in, S_ref, q, CD0, e, AR, time, TSFC)
          % [W_out, fuel_used] = segment_startup(W_in)
          % [W_out, fuel_used] = segment_takeoff(W_in)
          % [W_out, fuel_used] = segment_taxi(W_in)
     end

     methods (Static) % Common code
          % Assign data to "missiondata" property
          function output = get_mission_data(obj, Chosen_Mission)

               file_name = "Mission_Profile.xlsx";
               mission_name = Chosen_Mission; % This will be the SHEET the program checks for mission_obj data!

               % Mission segments should scan row F8 until it encounters a blank
               mission_table = readtable(file_name, 'Sheet', mission_name, 'ReadRowNames', true);
               % Try cleaning up all cells


               % Extract some data from the mission segment setup
               segment_count = length(mission_table.Properties.VariableNames);
               rowcount = length(mission_table.Properties.RowNames);

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
               output = [mission_table;atmospheredata];

               output = tableToNestedStruct(output, Orientation="variables");

          end

     end

end