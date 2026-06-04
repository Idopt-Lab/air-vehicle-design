classdef WeightLevel1
     %F16WEIGHTESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)

          aircraftTypes = [
               "homebuilt"
               "homebuilt"
               "homebuilt"

               "single_engine_propeller"

               "twin_engine_propeller"
               "twin_engine_propeller"

               "agricultural"
               "business_jet"
               "regional_tbp"
               "transport_jet"

               "military_trainer"
               "military_trainer"
               "military_trainer"
               "military_trainer"

               "fighter"
               "fighter"
               "fighter"

               "mil_patrol_bomb_transport"
               "mil_patrol_bomb_transport"

               "flying_boat_amphibious_float"
               "supersonic_cruise"
               ];

          subtypes = [
               "personal_fun_transportation"
               "scaled_fighter"
               "composite"

               "default"

               "default"
               "composite"

               "default"
               "default"
               "default"
               "default"

               "jet"
               "turboprop"
               "turboprop_without_number_2"
               "piston_prop"

               "jet_external_load"
               "jet_clean"
               "turboprop_external_load"

               "jet"
               "turboprop"

               "default"
               "default"
               ];

          A_values = [
               0.3411
               0.5542
               0.8222

               -0.1440

               0.0966
               0.1130

               -0.4398
               0.2678
               0.3774
               0.0833

               0.6632
               -1.4041
               0.1677
               0.5627

               0.5091
               0.1362
               0.2705

               -0.2009
               -0.4179

               0.1703
               0.4221
               ];

          B_values = [
               0.9519
               0.8654
               0.8050

               1.1162

               1.0298
               1.0403

               1.1946
               0.9979
               0.9647
               1.0383

               0.8640
               1.4660
               0.9978
               0.8761

               0.9505
               1.0116
               0.9830

               1.1037
               1.1446

               1.0083
               0.9876
               ];

          % % High-level types and their subtypes
          % types = {'homebuilt'; 'single engine'; 'twin engine'; 'agricultural'; 'business'; 'regional turboprop'; 'transport'; 'military trainer'; 'fighter'; 'military patrol'; 'military bomber'; 'military transport'; 'flying boat'; 'supersonic cruise'};
          % 
          % % Subtypes and coefficients
          % homebuilt_subtypes = {'Personal fun'; 'transportation'; 'scaled fighters'; 'composite'};
          % homebuilt_coeffs_A = [0.3411; 0.3411; 0.5542; 0.8222];
          % homebuilt_coeffs_B = [0.9519; 0.9519; 0.8654; 0.8050];
          % 
          % singleengine_subtypes = {'propeller driven'};
          % singleengine_coeffs_A = [-0.1440];
          % singleengine_coeffs_B = [1.1162];
          % 
          % twinengine_subtypes = {'propeller driven'; 'composite'};
          % twinengine_coeffs_A = [0.0966; 0.1130];
          % twinengine_coeffs_B = [1.0298; 1.0403];
          % 
          % agricultural_subtypes = {};
          % agricultural_coeffs_A = [-0.4398];
          % agrucultural_coeffs_B = [1.1946];
          % 
          % businessjets_subtypes = {};
          % businessjets_coeffs_A = [0.2678];
          % businessjets_coeff_B = [0.9979];
          % 
          % regionalturboprop_subtypes = {};
          % regionalturboprop_coeffs_A = [0.3774];
          % regionalturboprop_coeffs_B = [0.9647];
          % 
          % transportjet_subtypes = {};
          % transportjet_coeffs_A = [0.0833];
          % transportjet_coeffs_B = [1.0383];
          % 
          % militarytrainers_subtypes = {'jets'; 'turboprops'; 'turboprops w.o No.2'; 'piston'; 'prop'};
          % militarytrainers_coeffs_A = [0.6632; -1.4041; 0.1677; 0.5627; 0.5627];
          % militarytrainers_coeffs_B = [0.8640; 1.4660; 0.9978; 0.8761; 0.8761];
          % 
          % fighters_subtypes = {'jets'; 'turboprops'};
          % fighterjet_subtypes = {'ext load'; 'clean'};
          % fightertbp_subtypes = {'ext load'};
          % fighters_coeffs_A = [0.5091; 0.1362; 0.2705];
          % fighters_coeffs_B = [0.9505; 1.0116; 0.9830];
          % 
          % militarypatrolbombertransport_subtypes = {'jets'; 'turboprops'};
          % militarypatrolbombertransport_coeffs_A = [-0.2009; -0.4179];
          % militarypatrolbombertransport_coeffs_B = [1.1037; 1.1446];
          % 
          % flyingboats_subtypes = {};
          % flyingboats_coeffs_A = [0.1703];
          % flyingboats_coeffs_B = [1.0083];
          % 
          % supersoniccruise_subtypes = {};
          % supersoniccruise_coeffs_A = [0.4221];
          % supersoniccruise_coeffs_B = [0.9876];

     end

     methods (Static)

          % Estimate OEW (Raymer, 6th ed, Table 6.1)
          function [OEW, OEW_frac] = get_OEW(design_type, W_TO)
               % Hard-coding some values (placeholders)
               if (design_type == "sailplane - unpowered")
                    a = 0.86;
                    c = -0.05;
               elseif (design_type == "sailplane - powered")
                    a = 0.91;
                    c = -0.05;
               elseif (design_type == "homebuilt metal or wood") || (design_type == "homebuilt - metal") || (design_type == "homebuilt - wood")
                    a = 1.19;
                    c = -0.09;
               elseif (design_type == "homebuilt - composite")
                    a = 1.15;
                    c = -0.09;
               elseif (design_type == "general aviation - single engine")
                    a = 2.36;
                    c = -0.18;
               elseif (design_type == "general aviation twin engine")
                    a = 1.51;
                    c = -0.10;
               elseif (design_type == "agricultural aircraft")
                    a = 0.74;
                    c = -0.03;
               elseif (design_type == "twin turboprop")
                    a = 0.96;
                    c = -0.05;
               elseif (design_type == "flying boat")
                    a = 1.09;
                    c = -0.05;
               elseif (design_type == "jet trainer")
                    a = 1.59;
                    c = -0.10;
               elseif (design_type == "jet fighter") || (design_type == "Jet fighter")
                    a = 2.34;
                    c = -0.13;
               elseif (design_type == "military cargo") || (design_type == "military bomber")
                    a = 0.93;
                    c = -0.07;
               elseif (design_type == "jet transport")
                    a = 1.02;
                    c = -0.06;
               elseif (design_type == "UAV") || (design_type == "Tac Recce") || (design_type == "UCAV")
                    a = 1.67;
                    c = -0.16;
               elseif (design_type == "UAV - high altitude")
                    a = 2.75;
                    c = -0.18;
               elseif (design_type == "UAV - small")
                    a = 0.97;
                    c = -0.06;
               else
                    error("Error handler.")
               end

               OEW_frac = a*W_TO^c;

               OEW = OEW_frac*W_TO;
          end





          function output = tab_emptyweight(aircrafttype, subtype, W_TO)
               % Preliminary empty-weight regression constants based on aircraft type
               % Source: Roskam, Airplane Design Part I, Table 2.15
               %
               % Equation 2.16:
               %   W_E = 10^((log10(W_TO) - A)/B)
               %
               % Usage:
               %   coeffs = tab_emptyweight_coefficients("fighter", "jet external load")
               %   coeffs = tab_emptyweight_coefficients("fighter", "jet clean")
               %   coeffs = tab_emptyweight_coefficients("business jet")
               %   coeffs = tab_emptyweight_coefficients("fighter", "jet external load", 45000)
               if nargin < 2
                    subtype = "";
               end

               if nargin < 3
                    W_TO = NaN;
               end

               aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
               subtype = WeightLevel1.normalize_emptyweight_subtype(subtype);

               if subtype == ""
                    subtype = WeightLevel1.default_emptyweight_subtype(aircrafttype);
               end



               tableData = table(WeightLevel1.aircraftTypes, WeightLevel1.subtypes, WeightLevel1.A_values, WeightLevel1.B_values, ...
                    'VariableNames', {'AircraftType', 'Subtype', 'A', 'B'});

               idx = tableData.AircraftType == aircrafttype & ...
                    tableData.Subtype == subtype;

               if ~any(idx)
                    availableSubtypes = tableData.Subtype(tableData.AircraftType == aircrafttype);

                    if isempty(availableSubtypes)
                         error("Unrecognized aircraft type: %s", aircrafttype);
                    else
                         error("Unrecognized subtype '%s' for aircraft type '%s'. Available subtypes: %s", ...
                              subtype, aircrafttype, strjoin(availableSubtypes, ", "));
                    end
               end

               output = struct();
               output.aircrafttype = aircrafttype;
               output.subtype = subtype;
               output.A = tableData.A(idx);
               output.B = tableData.B(idx);

               if ~isnan(W_TO)
                    if W_TO <= 0
                         error("W_TO must be positive.");
                    end

                    % output.W_TO = W_TO;
                    output.W_E = 10^((log10(W_TO) - output.A) / output.B);
               end
          end






     end

     methods (Static, Access = private)

          function subtype = default_emptyweight_subtype(aircrafttype)

               switch aircrafttype
                    case "homebuilt"
                         subtype = "personal_fun_transportation";

                    case "single_engine_propeller"
                         subtype = "default";

                    case "twin_engine_propeller"
                         subtype = "default";

                    case "agricultural"
                         subtype = "default";

                    case "business_jet"
                         subtype = "default";

                    case "regional_tbp"
                         subtype = "default";

                    case "transport_jet"
                         subtype = "default";

                    case "military_trainer"
                         subtype = "jet";

                    case "fighter"
                         subtype = "jet_external_load";

                    case "mil_patrol_bomb_transport"
                         subtype = "jet";

                    case "flying_boat_amphibious_float"
                         subtype = "default";

                    case "supersonic_cruise"
                         subtype = "default";

                    otherwise
                         subtype = "";
               end
          end

          function subtype = normalize_emptyweight_subtype(subtype)

               subtype = lower(strtrim(string(subtype)));
               subtype = replace(subtype, "-", "_");
               subtype = replace(subtype, "+", "_");
               subtype = replace(subtype, "/", "_");
               subtype = replace(subtype, " ", "_");
               subtype = replace(subtype, ".", "");
               subtype = replace(subtype, ",", "");

               if any(subtype == ["", "default"])
                    subtype = "";

               elseif any(subtype == ["personal", ...
                         "personal_fun", ...
                         "pers_fun", ...
                         "personal_fun_transportation", ...
                         "pers_fun_transportation"])
                    subtype = "personal_fun_transportation";

               elseif any(subtype == ["scaled_fighter", ...
                         "scaled_fighters"])
                    subtype = "scaled_fighter";

               elseif any(subtype == ["composite", ...
                         "composites"])
                    subtype = "composite";

               elseif any(subtype == ["jet", ...
                         "jets"])
                    subtype = "jet";

               elseif any(subtype == ["turboprop", ...
                         "turboprops"])
                    subtype = "turboprop";

               elseif any(subtype == ["turboprop_without_no2", ...
                         "turboprop_without_number_2", ...
                         "turboprops_without_no2", ...
                         "turboprops_without_number_2"])
                    subtype = "turboprop_without_number_2";

               elseif any(subtype == ["piston_prop", ...
                         "piston_props", ...
                         "pistonprops"])
                    subtype = "piston_prop";

               elseif any(subtype == ["jet_ext_load", ...
                         "jets_ext_load", ...
                         "jet_external_load", ...
                         "jets_external_load", ...
                         "external_load"])
                    subtype = "jet_external_load";

               elseif any(subtype == ["jet_clean", ...
                         "jets_clean", ...
                         "clean"])
                    subtype = "jet_clean";

               elseif any(subtype == ["turboprop_ext_load", ...
                         "turboprop_external_load", ...
                         "turboprops_ext_load", ...
                         "turboprops_external_load"])
                    subtype = "turboprop_external_load";
               end
          end



     end
end