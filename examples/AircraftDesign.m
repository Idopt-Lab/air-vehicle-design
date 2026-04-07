classdef AircraftDesign < handle
     %AIRCRAFTDESIGN Summary of this class goes here
     %   Detailed explanation goes here

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
     end
end