classdef AircraftDesign < handle
     %AIRCRAFTDESIGN Summary of this class goes here
     %   Detailed explanation goes here
     % Treat this like the entire PHYSICAL AIRCRAFT.

     properties
          Name
          geom
          propulsion
          weights
          % missiondata % Aircraft design doesn't need mission data
          requirements
          constraints

          % S_wet= 1337; % Wetted area, whole aircraft
          % S_ref = 300; % REference area (ft^2)
          % SW_wings = 42; % Wetted area, main wings
          % SW_HT = 13; % Wetted area, horizontal tail
          % SW_VT = 4; % Wetted area, vertical tail
          % SW_struts = 2;% Wetted area, struts (none for the F-16)
          % SW_pylons = 2.1; % Wetted area, pylons (0 is placeholder value)

          WeightResults
          AeroResults
          PropulsionResults
          internalvolume
     end

     methods
          function obj = AircraftDesign()
          end

          % Set W_TO guess (lbf) (just in case you need this)
          function set_W_TO_guess(obj, guess)
               obj.WeightResults.W_TO = guess;
          end

          % Set T0 guess (lbf) (just in case you need this)
          function set_T0_guess(obj, guess)
               obj.PropulsionResults.T0 = guess;
          end
     end
end