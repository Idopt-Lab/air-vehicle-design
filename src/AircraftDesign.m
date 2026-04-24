classdef AircraftDesign < handle
     %AIRCRAFTDESIGN Summary of this class goes here
     %   Detailed explanation goes here
     % Treat this like the entire PHYSICAL AIRCRAFT.

     properties
          Name
          geom
          general
          propulsion
          propulsion_type
          weights
          type
          % missiondata % Aircraft design doesn't need mission data
          requirements % Should divorce this from AircraftDesign
          requirements_filename
          % constraints % Should also divorce this from AircraftDesign
          constraints_filename

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
          function obj = AircraftDesign(name, opts)
               arguments
                    name                  string = ""
                    opts.RequirementsName string = ""
                    opts.ConstraintsName  string = ""
                    opts.MissionName      string = ""
                    opts.AutoLoad        logical = true
               end

               % Important: allow zero-input construction
               if name == ""
                    return
               end

               obj.Name = name;

               if opts.AutoLoad
                    [obj.geom.wings, obj.geom.fuselage, obj.propulsion, obj.weights, obj.general] = Import_Design(obj.Name);
                    obj.requirements = Import_Requirements(opts.RequirementsName);
                    % obj.constraints  = Import_Constraints(opts.ConstraintsName);
                    obj.constraints_filename = opts.ConstraintsName;

                    % Sort through "general" stuff
                    obj.type = obj.general.Type;
                    obj.propulsion_type = obj.general.engineType;

                    % Come back to this. This is supposed to create a
                    % mission object automatically.
                    % if opts.MissionName ~= ""
                    %      % mission_obj.missiondata = Mission_Profiles(opts.MissionName);
                    %      % or:
                    %      % mission_obj.missiondata = F16MissionAnalysis(opts.MissionName);
                    %      % mission_obj.missiondata = mission_obj.get_mission_data(obj, opts.MissionName);
                    % end
               end

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

     methods (Static)
          function mission = createMission(missionName)
               arguments
                    missionName string
               end

               mission = F16MissionAnalysis3(missionName);
          end

          function [design, mission] = create(name, opts)
               arguments
                    name string
                    opts.DesignFile       string = ""
                    opts.RequirementsName string = "Requirements"
                    opts.ConstraintsName  string = "Constraints"
                    opts.MissionName      string = ""
               end

               design = AircraftDesign( ...
                    name, ...
                    DesignFile       = opts.DesignFile, ...
                    RequirementsName = opts.RequirementsName, ...
                    ConstraintsName  = opts.ConstraintsName);

               if opts.MissionName == ""
                    mission = [];
               else
                    mission = AircraftDesign.createMission(opts.MissionName);
               end
          end
     end
end