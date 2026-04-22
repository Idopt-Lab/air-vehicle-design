classdef (Abstract) ConstraintModel < handle
     %CONSTRAINTMODEL Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract)
          TW_table
          T_Wto_takeoff
          optimal_WS
          min_TW
          Landing
          Wto_S_landing
          T0_W0
          W0_S_ref
     end

     methods (Abstract) % Bare minimum requirements
          Constraint_Results = constraint_est(obj, design)
     end

     methods (Access = private) % Commonly shared functions
          % Importing the constraints
          function output = get_design_constraints(constraint_obj, filename)
               % Load information from Excel sheet
               file_name = "Constraints.xlsx";

               % Mission segments should scan row F8 until it encounters a blank
               Constraints = readtable(file_name, 'Sheet', Constraints, 'ReadRowNames', true);
               % Try cleaning up all cells

               for i=1:length(Constraints{:,1}) % For each constraint...
                    alt = Constraints{i, "Altitude_ft_"}; % Get the altitude (ft)
                    [Temp, a, P, rho, nu, mu] = atmosisa(alt*0.3048); % Acquire atmospheric data (Kelvin, m/s, Pascals, kg/m^3, m^2/s, kg/(m*s)
                    % Density, pressure, temperature, local speed of sound, dynamic
                    % pressure
                    % Convert to imperial units
                    Temp = Temp*1.8; % Ambient temperature (Rankine)
                    a = a/0.3048; % Local speed of sound (ft/s)
                    P = P*0.00014504; % Ambient pressure (PSI)
                    rho = rho*0.00194032033; % density (slug/ft^3)
                    nu = nu/0.3048 * (1/0.3048); % kinematic viscosity (ft^2/s)
                    mu = mu * (0.06852177/1) * (0.3048/1); % dynamic viscosity (slugs/(ft*s))

                    % Compute aerodynamic stuff
                    V = Constraints{i, "MachNumber"}*a;
                    q = 0.5*rho*V^2;

                    % add data to corresponding segment
                    atmospheredata(i,:) = [Temp, a, P, rho, nu, mu, V, q];
                    % mission_data = [mission_data;newdata]
                    % Move to next segment
               end

               % Concatenate new table onto constraints table
               atmospheredata = array2table(atmospheredata,"RowNames", Constraints.Properties.RowNames, "VariableNames", {'Temp (R)', 'a (ft/s)', 'P (psi)', 'rho (lb/ft^3)', 'nu (ft^2/s)', 'mu slugs/(ft*s)', 'V (ft/s)', 'q (lbf/ft^2)'});
               output = [Constraints, atmospheredata];
               % Constraints = tableToNestedStruct(Constraints, Orientation="variables");
          end
     end
end