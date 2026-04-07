%% Mission Profiles
% Written by Casey Chamberlain
%
% This loads the mission segments for the design.

% ARGUMENTS
% Chosen_Mission (string) = Name of mission profile (Excel file)

% RETURNS
% Mission_Profile (table) = table containing mission segments (names,
% ranges, times, altitudes, atmospheric data, etc)

function [mission_table] = Mission_Profiles(Chosen_Mission)

% Load information from Excel sheet

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
mission_table = [mission_table;atmospheredata]

end