classdef L1utils < handle
     % This is basically a collection of things that all L1 disciplines can pull
     % from. aircraftTypes, segmentNames, etc, instead of having to copy+paste
     % them into every single L1 class.

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

          function aircrafttype = normalize_aircraft_type(aircrafttype)

               aircrafttype = lower(strtrim(string(aircrafttype)));

               aircrafttype = replace(aircrafttype, "-", "_");
               aircrafttype = replace(aircrafttype, " ", "_");
               aircrafttype = replace(aircrafttype, "'", "");

               if any(aircrafttype == ["homebuilt"])
                    aircrafttype = "homebuilt";

               elseif any(aircrafttype == ["single_engine", "single_engine_prop", ...
                         "single_engine_propeller"])
                    aircrafttype = "single_engine";

               elseif any(aircrafttype == ["twin_engine", "twin_engine_prop", ...
                         "twin_engine_propeller"])
                    aircrafttype = "twin_engine";

               elseif any(aircrafttype == ["agricultural", "agricultural_aircraft"])
                    aircrafttype = "agricultural";

               elseif any(aircrafttype == ["business_jet", "business_jets"])
                    aircrafttype = "business_jet";

               elseif any(aircrafttype == ["regional_tbp", "regional_tbps", ...
                         "regional_turboprop"])
                    aircrafttype = "regional_tbp";

               elseif any(aircrafttype == ["transport_jet", "transport_jets", "jet_transport"])
                    aircrafttype = "transport_jet";

               elseif any(aircrafttype == ["military_trainer", "military_trainers"])
                    aircrafttype = "military_trainer";

               elseif any(aircrafttype == ["fighter", "fighters", "jet_fighter"])
                    aircrafttype = "fighter";

               elseif any(aircrafttype == ["mil_patrol_bomb_transport", ...
                         "military_patrol", ...
                         "bomber", ...
                         "military_bomber", ...
                         "military_transport", ...
                         "patrol_bomb_transport"])
                    aircrafttype = "mil_patrol_bomb_transport";

               elseif any(aircrafttype == ["flying_boat", "flying_boats", ...
                         "amphibious", "float_airplane", ...
                         "float_airplanes"])
                    aircrafttype = "flying_boat_amphibious_float";

               elseif any(aircrafttype == ["supersonic_cruise"])
                    aircrafttype = "supersonic_cruise";
               end
          end

          function value = resolve_range(value, rangeMode)

               if ~isnumeric(value) || isscalar(value)
                    return
               end

               switch rangeMode
                    case "range"
                         % Return [min max]
                         return

                    case "min"
                         value = min(value);

                    case "max"
                         value = max(value);

                    case "mean"
                         value = mean(value);

                    otherwise
                         error("rangeMode must be 'mean', 'min', 'max', or 'range'.");
               end
          end
     end

end