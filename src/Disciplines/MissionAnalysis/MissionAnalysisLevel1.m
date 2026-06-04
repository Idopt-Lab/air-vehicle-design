classdef MissionAnalysisLevel1
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % Lower fidelity level than 2.

     properties (Constant)
          aircraftTypes = [
               "homebuilt"
               "single_engine"
               "twin_engine"
               "agricultural"
               "business_jet"
               "regional_tbp"
               "transport_jet"
               "military_trainer"
               "fighter"
               "mil_patrol_bomb_transport"
               "flying_boat_amphibious_float"
               "supersonic_cruise"
               ];

          segmentNames = [
               "engine_start_warmup"
               "taxi"
               "takeoff"
               "climb"
               "descent"
               "landing_taxi_shutdown"
               ];

          % Use a cell array because two climb entries are ranges.
          fuelFractions = {
               0.998, 0.998, 0.998, 0.995,       0.995, 0.995;
               0.995, 0.997, 0.998, 0.992,       0.993, 0.993;
               0.992, 0.996, 0.996, 0.990,       0.992, 0.992;
               0.996, 0.995, 0.996, 0.998,       0.999, 0.998;
               0.990, 0.995, 0.995, 0.980,       0.990, 0.992;
               0.990, 0.995, 0.995, 0.985,       0.985, 0.995;
               0.990, 0.990, 0.995, 0.980,       0.990, 0.992;
               0.990, 0.990, 0.990, 0.980,       0.990, 0.995;
               0.990, 0.990, 0.990, [0.90 0.96], 0.990, 0.995;
               0.990, 0.990, 0.995, 0.980,       0.990, 0.992;
               0.992, 0.990, 0.996, 0.985,       0.990, 0.990;
               0.990, 0.995, 0.995, [0.87 0.92], 0.985, 0.992;
               };

          % ---------------------------------------------------------------------
          % Roskam Table 2.2 data
          % Cell arrays are used because most entries are ranges and some are NaN.
          % NaN means the table gives no value for that aircraft/phase/quantity.
          % ---------------------------------------------------------------------

          cruise_LD = {
               [8 10]
               [8 10]
               [8 10]
               [5 7]
               [10 12]
               [11 13]
               [13 15]
               [8 10]
               [4 7]
               [13 15]
               [10 12]
               [4 6]
               };

          cruise_cj = {
               NaN
               NaN
               NaN
               NaN
               [0.5 0.9]
               NaN
               [0.5 0.9]
               [0.5 1.0]
               [0.6 1.4]
               [0.5 0.9]
               [0.5 0.9]
               [0.7 1.5]
               }; % LBS/LBS/HR

          cruise_cp = {
               [0.6 0.8]
               [0.5 0.7]
               [0.5 0.7]
               [0.5 0.7]
               NaN
               [0.4 0.6]
               NaN
               [0.4 0.6]
               [0.5 0.7]
               [0.4 0.7]
               [0.5 0.7]
               NaN
               }; % LBS/HP/HR

          cruise_eta_p = {
               0.70
               0.80
               0.82
               0.82
               NaN
               0.85
               NaN
               0.82
               0.82
               0.82
               0.82
               NaN
               };

          loiter_LD = {
               [10 12]
               [10 12]
               [9 11]
               [8 10]
               [12 14]
               [14 16]
               [14 18]
               [10 14]
               [6 9]
               [14 18]
               [13 15]
               [7 9]
               };

          loiter_cj = {
               NaN
               NaN
               NaN
               NaN
               [0.4 0.6]
               NaN
               [0.4 0.6]
               [0.4 0.6]
               [0.6 0.8]
               [0.4 0.6]
               [0.4 0.6]
               [0.6 0.8]
               }; % LBS/LBS/HR

          loiter_cp = {
               [0.5 0.7]
               [0.5 0.7]
               [0.5 0.7]
               [0.5 0.7]
               NaN
               [0.5 0.7]
               NaN
               [0.5 0.7]
               [0.5 0.7]
               [0.5 0.7]
               [0.5 0.7]
               NaN
               }; % LBS/HP/HR

          loiter_eta_p = {
               0.60
               0.70
               0.72
               0.72
               NaN
               0.77
               NaN
               0.77
               0.77
               0.77
               0.77
               NaN
               };


     end

     methods (Static)

          % Get LD ratio (wrapper)
          function [LD_ratio] = compute_LD_ratio(segment_name, LD)
               if (segment_name == "cruise") || (segment_name == "combat") || (segment_name == "dash")
                    LD_ratio = LD*0.866;
               elseif (segment_name == "loiter")
                    LD_ratio = LD;
               else
                    error("Error handler.")
               end
          end


          % Computing weight fraction (should go in "weight" class?
          function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Climb segment - un-revised.
          function [W_out, fuel_used] = segment_climb(W_in, Mach)
               WF_Climb = 1.0065 - 0.0325 * Mach;
               fuel_used = (1 - WF_Climb) * W_in;
               W_out = W_in - fuel_used;
          end



          % Combat segment - un-revised
          function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, LD)
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "combat");
               LD_combat = MissionAnalysisLevel1.compute_LD_ratio("combat", LD);
               WF = exp(-(time * 60 * TSFC / LD_combat));
               fuel_used = W_in*(1-WF);
               W_out = W_in - fuel_used - payload;
          end

          % Cruise segment - un-revised
          function [W_out, fuel_used] = segment_cruise(W_in, TSFC, Distance, Mach, a, LD)
               V = Mach * a;
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "cruise");
               LD_cruise = MissionAnalysisLevel1.compute_LD_ratio("dash", LD);
               WF = MissionAnalysisLevel1.compute_weightfraction(TSFC, Distance, V, LD_cruise);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Dash segment
          function [W_out, fuel_used] = segment_dash(W_in, TSFC, Distance, V, LD)
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "dash");
               LD_dash = MissionAnalysisLevel1.compute_LD_ratio("dash", LD);
               WF = MissionAnalysisLevel1.compute_weightfraction(TSFC, Distance, V, LD_dash);
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Landing segment
          function [W_out, fuel_used] = segment_landing(W_in)
               WF = 0.995;
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Loiter segment
          function [W_out, fuel_used] = segment_loiter(W_in, time, TSFC, LD)
               % LD = MissionAnalysisLevel1.compute_LD_ratio(design_type, b, S_wet,  "loiter");
               LD_loiter = MissionAnalysisLevel1.compute_LD_ratio("loiter", LD);
               WF = exp(-(time * 60 * TSFC / LD_loiter));
               fuel_used = W_in * (1 - WF);
               W_out = W_in - fuel_used;
          end

          % Takeoff segment
          function [W_out, fuel_used] = segment_takeoff(W_in)
               WF = 0.95;
               W_out = W_in * WF;
               fuel_used = W_in - W_out;
          end



          function output = tab_fuelfraction(aircrafttype, segment)
               % Preliminary fuel-fractions based on aircraft type
               % Source: Roskam, Airplane Design Part I, Table 2.1
               %
               % Usage:
               %   ff = tab_fuelfraction("fighter", "takeoff")
               %   ff = tab_fuelfraction("fighter", "climb", "mean")
               %   ff_table = tab_fuelfraction("fighter")

               if nargin < 2
                    segment = "";
               end

               % if nargin < 3
               %      rangeMode = "mean";
               %      % Options for range entries:
               %      % "mean", "min", "max", or "range"
               % end
               rangeMode = "mean";
               % Set to "mean" for consistent values.

               aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
               segment = MissionAnalysisLevel1.normalize_segment(segment);
               rangeMode = lower(strtrim(string(rangeMode)));

               row = find(MissionAnalysisLevel1.aircraftTypes == aircrafttype, 1);

               if isempty(row)
                    error("Unrecognized aircraft type: %s", aircrafttype);
               end

               % If no segment is requested, return the full row as a struct.
               if segment == ""
                    output = struct();

                    for j = 1:numel(segmentNames)
                         value = MissionAnalysisLevel1.fuelFractions{row, j};
                         output.(segmentNames(j)) = L1utils.resolve_range(value, rangeMode);
                    end

                    return
               end

               col = find(MissionAnalysisLevel1.segmentNames == segment, 1);

               if isempty(col)
                    error("Unrecognized mission segment: %s", segment);
               end

               value = MissionAnalysisLevel1.fuelFractions{row, col};
               output = L1utils.resolve_range(value, rangeMode);
          end




          function output = tab_missionphase_values(aircrafttype, phase, quantity)
               % Preliminary cruise/loiter values based on aircraft type
               % Source: Roskam, Airplane Design Part I, Table 2.2
               %
               % Table values:
               %   LD    = lift-to-drag ratio [-]
               %   cj    = jet TSFC [lb/lb/hr]
               %   cp    = propeller TSFC [lb/hp/hr]
               %   eta_p = propeller efficiency [-]
               %
               % Usage:
               %   value = tab_missionphase_values("fighter", "cruise", "LD")
               %   value = tab_missionphase_values("fighter", "cruise", "cj", "range")
               %   data  = tab_missionphase_values("fighter", "loiter")
               %   data  = tab_missionphase_values("fighter")
               if nargin < 2
                    phase = "";
               end

               if nargin < 3
                    quantity = "";
               end

               % if nargin < 4
               %     rangeMode = "mean";
               %     % Options: "mean", "min", "max", "range"
               % end
               rangeMode = "mean";

               aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
               phase = MissionAnalysisLevel1.normalize_phase(phase);
               quantity = MissionAnalysisLevel1.normalize_quantity(quantity);
               rangeMode = lower(strtrim(string(rangeMode)));

               row = find(MissionAnalysisLevel1.aircraftTypes == aircrafttype, 1);

               if isempty(row)
                    error("Unrecognized aircraft type: %s", aircrafttype);
               end



               % Build output struct for selected aircraft row.
               data.cruise.LD    = L1utils.resolve_range(MissionAnalysisLevel1.cruise_LD{row}, rangeMode);
               data.cruise.cj    = L1utils.resolve_range(MissionAnalysisLevel1.cruise_cj{row}, rangeMode);
               data.cruise.cp    = L1utils.resolve_range(MissionAnalysisLevel1.cruise_cp{row}, rangeMode);
               data.cruise.eta_p = L1utils.resolve_range(MissionAnalysisLevel1.cruise_eta_p{row}, rangeMode);

               data.loiter.LD    = L1utils.resolve_range(MissionAnalysisLevel1.loiter_LD{row}, rangeMode);
               data.loiter.cj    = L1utils.resolve_range(MissionAnalysisLevel1.loiter_cj{row}, rangeMode);
               data.loiter.cp    = L1utils.resolve_range(MissionAnalysisLevel1.loiter_cp{row}, rangeMode);
               data.loiter.eta_p = L1utils.resolve_range(MissionAnalysisLevel1.loiter_eta_p{row}, rangeMode);

               % Return full aircraft data if no phase requested.
               if phase == ""
                    output = data;
                    return
               end

               % Return all quantities for selected phase if no quantity requested.
               if quantity == ""
                    output = data.(char(phase));
                    return
               end

               % Optional convenience: return both TSFC columns if quantity == "tsfc".
               if quantity == "tsfc"
                    output.cj = data.(char(phase)).cj;
                    output.cp = data.(char(phase)).cp;
                    return
               end

               output = data.(char(phase)).(char(quantity));
          end
















     end





     %% ============ STATIC PRIVATE METHODS ============

     methods (Static, Access = private)


          function phase = normalize_phase(phase)

               phase = lower(strtrim(string(phase)));
               phase = replace(phase, "-", "_");
               phase = replace(phase, " ", "_");

               if any(phase == ["cr", "cruise"])
                    phase = "cruise";

               elseif any(phase == ["ltr", "loiter"])
                    phase = "loiter";
               end
          end


          function quantity = normalize_quantity(quantity)

               quantity = lower(strtrim(string(quantity)));
               quantity = replace(quantity, "-", "_");
               quantity = replace(quantity, " ", "_");
               quantity = replace(quantity, "/", "");

               if any(quantity == ["ld", "l_d", "lift_drag", "lift_to_drag"])
                    quantity = "LD";

               elseif any(quantity == ["cj", "c_j", "jet_tsfc", "tsfc_jet"])
                    quantity = "cj";

               elseif any(quantity == ["cp", "c_p", "prop_tsfc", "tsfc_prop"])
                    quantity = "cp";

               elseif any(quantity == ["eta", "eta_p", "prop_efficiency", ...
                         "propeller_efficiency"])
                    quantity = "eta_p";

               elseif any(quantity == ["tsfc"])
                    quantity = "tsfc";
               end
          end

          % function aircrafttype = normalize_aircraft_type(aircrafttype)
          % 
          %      aircrafttype = lower(strtrim(string(aircrafttype)));
          % 
          %      aircrafttype = replace(aircrafttype, "-", "_");
          %      aircrafttype = replace(aircrafttype, " ", "_");
          %      aircrafttype = replace(aircrafttype, "'", "");
          % 
          %      if any(aircrafttype == ["homebuilt"])
          %           aircrafttype = "homebuilt";
          % 
          %      elseif any(aircrafttype == ["single_engine", "single_engine_prop", ...
          %                "single_engine_propeller"])
          %           aircrafttype = "single_engine";
          % 
          %      elseif any(aircrafttype == ["twin_engine", "twin_engine_prop", ...
          %                "twin_engine_propeller"])
          %           aircrafttype = "twin_engine";
          % 
          %      elseif any(aircrafttype == ["agricultural", "agricultural_aircraft"])
          %           aircrafttype = "agricultural";
          % 
          %      elseif any(aircrafttype == ["business_jet", "business_jets"])
          %           aircrafttype = "business_jet";
          % 
          %      elseif any(aircrafttype == ["regional_tbp", "regional_tbps", ...
          %                "regional_turboprop"])
          %           aircrafttype = "regional_tbp";
          % 
          %      elseif any(aircrafttype == ["transport_jet", "transport_jets", "jet_transport"])
          %           aircrafttype = "transport_jet";
          % 
          %      elseif any(aircrafttype == ["military_trainer", "military_trainers"])
          %           aircrafttype = "military_trainer";
          % 
          %      elseif any(aircrafttype == ["fighter", "fighters", "jet_fighter"])
          %           aircrafttype = "fighter";
          % 
          %      elseif any(aircrafttype == ["mil_patrol_bomb_transport", ...
          %                "military_patrol", ...
          %                "bomber", ...
          %                "military_bomber", ...
          %                "military_transport", ...
          %                "patrol_bomb_transport"])
          %           aircrafttype = "mil_patrol_bomb_transport";
          % 
          %      elseif any(aircrafttype == ["flying_boat", "flying_boats", ...
          %                "amphibious", "float_airplane", ...
          %                "float_airplanes"])
          %           aircrafttype = "flying_boat_amphibious_float";
          % 
          %      elseif any(aircrafttype == ["supersonic_cruise"])
          %           aircrafttype = "supersonic_cruise";
          %      end
          % end

          function segment = normalize_segment(segment)

               segment = lower(strtrim(string(segment)));

               segment = replace(segment, "-", "_");
               segment = replace(segment, " ", "_");
               segment = replace(segment, "/", "_");

               if any(segment == ["engine_start", "start", "startup", ...
                         "warmup", "warm_up", "engine_start_warmup"])
                    segment = "engine_start_warmup";

               elseif segment == "take_off"
                    segment = "takeoff";

               elseif any(segment == ["landing", "shutdown", "landing_taxi_shutdown", ...
                         "landing_taxi_and_shutdown"])
                    segment = "landing_taxi_shutdown";
               end
          end


          % function value = resolve_range(value, rangeMode)
          % 
          %      if ~isnumeric(value) || isscalar(value)
          %           return
          %      end
          % 
          %      switch rangeMode
          %           case "range"
          %                % Return [min max]
          %                return
          % 
          %           case "min"
          %                value = min(value);
          % 
          %           case "max"
          %                value = max(value);
          % 
          %           case "mean"
          %                value = mean(value);
          % 
          %           otherwise
          %                error("rangeMode must be 'mean', 'min', 'max', or 'range'.");
          %      end
          % end
     end
end