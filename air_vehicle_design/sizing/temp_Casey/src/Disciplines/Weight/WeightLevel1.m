classdef WeightLevel1
     %F16WEIGHTESTLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)

          % C.G. range lookup table
          % Source: Roskam, Airplane Design Part II, Table 10.3
          cg_range_table = WeightLevel1.build_cg_range_table(); % These are TYPICAL CG RANGES

          % Composite construction weight reduction factors
          % Source: Roskam, Airplane Design Part I, Table 2.16
          %
          % W_comp / W_metal
          composite_weight_reduction_table = WeightLevel1.compositeweightreductiontable();

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

          function output = tab_cg_range(aircrafttype, valueType)
               % Tabulate approximate C.G. range by aircraft type.
               %
               % Source: Roskam, Airplane Design Part II, Table 10.3
               %
               % Table values:
               %   cg_range_in      = C.G. range in inches
               %   cg_range_frac_cw = C.G. range as fraction of wing chord
               %
               % Usage:
               %   data = WeightLevel1.tab_cg_range("fighter")
               %   xcg  = WeightLevel1.tab_cg_range("fighter", "in")
               %   frac = WeightLevel1.tab_cg_range("fighter", "frac_cw")
               %   rng  = WeightLevel1.tab_cg_range("jet transport", "range")

               if nargin < 2
                    valueType = "";
               end

               aircrafttype = WeightLevel1.normalize_cg_aircraft_type(aircrafttype);
               valueType = lower(strtrim(string(valueType)));

               T = WeightLevel1.cg_range_table;

               idx = T.AircraftType == aircrafttype;

               if ~any(idx)
                    error("Unrecognized aircraft type: %s", aircrafttype);
               end

               row = T(idx, :);

               output = struct();
               output.aircrafttype = row.AircraftType;

               output.cg_range_in_min = row.cg_range_in_min;
               output.cg_range_in_avg = row.cg_range_in_avg;
               output.cg_range_in_max = row.cg_range_in_max;

               output.cg_range_frac_cw_min = row.cg_range_frac_cw_min;
               output.cg_range_frac_cw_avg = row.cg_range_frac_cw_avg;
               output.cg_range_frac_cw_max = row.cg_range_frac_cw_max;

               if valueType == ""
                    return
               end

               switch valueType
                    case {"in", "inch", "inches", "cg_range_in"}
                         output = row.cg_range_in_avg;

                    case {"frac", "frac_cw", "fraction", "fraction_cw", "cg_range_frac_cw"}
                         output = row.cg_range_frac_cw_avg;

                    case {"range_in", "in_range", "inches_range"}
                         output = [row.cg_range_in_min, row.cg_range_in_max];

                    case {"range_frac", "frac_range", "frac_cw_range"}
                         output = [row.cg_range_frac_cw_min, row.cg_range_frac_cw_max];

                    case {"range", "all_range"}
                         output.cg_range_in = [row.cg_range_in_min, row.cg_range_in_max];
                         output.cg_range_frac_cw = [row.cg_range_frac_cw_min, row.cg_range_frac_cw_max];

                    otherwise
                         error("valueType must be '', 'in', 'frac_cw', 'range_in', 'range_frac', or 'range'.");
               end
          end


          function output = tab_compositeweightfactor(component, valueType)
               % Composite construction weight reduction factor lookup.
               % Source: Roskam, Airplane Design Part I, Table 2.16
               %
               % Returns W_comp / W_metal.
               %
               % Usage:
               %   factor = WeightLevel1.tab_compositeweightfactor("fuselage", "average")
               %   factor = WeightLevel1.tab_compositeweightfactor("air induction system", "range")
               %   data   = WeightLevel1.tab_compositeweightfactor("landing gear")

               if nargin < 2
                    valueType = "";
               end

               component = WeightLevel1.normalize_composite_component(component);
               valueType = lower(strtrim(string(valueType)));

               T = WeightLevel1.composite_weight_reduction_table;

               idx = T.Component == component;

               if ~any(idx)
                    error("Unrecognized composite component: %s", component);
               end

               row = T(idx, :);

               output = struct();
               output.component = row.Component;
               output.structure_group = row.StructureGroup;
               output.W_comp_W_metal_min = row.W_comp_W_metal_min;
               output.W_comp_W_metal_avg = row.W_comp_W_metal_avg;
               output.W_comp_W_metal_max = row.W_comp_W_metal_max;

               if valueType == ""
                    return
               end

               switch valueType
                    case {"min", "minimum"}
                         output = row.W_comp_W_metal_min;

                    case {"avg", "average", "mean", "nominal"}
                         output = row.W_comp_W_metal_avg;

                    case {"max", "maximum"}
                         output = row.W_comp_W_metal_max;

                    case {"range"}
                         output = [row.W_comp_W_metal_min, row.W_comp_W_metal_max];

                    otherwise
                         error("valueType must be 'minimum', 'average', 'maximum', or 'range'.");
               end
          end

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


          function aircrafttype = normalize_cg_aircraft_type(aircrafttype)

               aircrafttype = lower(strtrim(string(aircrafttype)));
               aircrafttype = replace(aircrafttype, "-", "_");
               aircrafttype = replace(aircrafttype, " ", "_");
               aircrafttype = replace(aircrafttype, "'", "");
               aircrafttype = replace(aircrafttype, ".", "");
               aircrafttype = replace(aircrafttype, ",", "");

               if any(aircrafttype == ["homebuilt", "homebuilts"])
                    aircrafttype = "homebuilt";

               elseif any(aircrafttype == ["single_engine", ...
                         "single_engine_prop", ...
                         "single_engine_propeller", ...
                         "single_engine_propeller_driven"])
                    aircrafttype = "single_engine_propeller";

               elseif any(aircrafttype == ["twin_engine", ...
                         "twin_engine_prop", ...
                         "twin_engine_propeller", ...
                         "twin_engine_propeller_driven"])
                    aircrafttype = "twin_engine_propeller";

               elseif any(aircrafttype == ["agricultural", ...
                         "ag_airpl", ...
                         "ag_airplane", ...
                         "agricultural_airplane"])
                    aircrafttype = "agricultural";

               elseif any(aircrafttype == ["business_jet", ...
                         "business_jets"])
                    aircrafttype = "business_jet";

               elseif any(aircrafttype == ["regional_tbp", ...
                         "regional_tbp", ...
                         "regional_turboprop", ...
                         "regional_turbopropeller"])
                    aircrafttype = "regional_tbp";

               elseif any(aircrafttype == ["jet_transport", ...
                         "jet_transp", ...
                         "transport_jet", ...
                         "transport_jets"])
                    aircrafttype = "transport_jet";

               elseif any(aircrafttype == ["military_trainer", ...
                         "military_trainers", ...
                         "trainer", ...
                         "trainers"])
                    aircrafttype = "military_trainer";

               elseif any(aircrafttype == ["fighter", ...
                         "fighters", ...
                         "jet_fighter"])
                    aircrafttype = "fighter";

               elseif any(aircrafttype == ["mil_patrol_bomb_transport", ...
                         "military_patrol_bomb_transport", ...
                         "military_patrol", ...
                         "military_bomber", ...
                         "military_transport", ...
                         "patrol_bomb_transport"])
                    aircrafttype = "mil_patrol_bomb_transport";

               elseif any(aircrafttype == ["flying_boat", ...
                         "flying_boats", ...
                         "amphibious", ...
                         "float", ...
                         "float_airplane", ...
                         "float_airplanes", ...
                         "flying_boat_amphibious_float"])
                    aircrafttype = "flying_boat_amphibious_float";

               elseif any(aircrafttype == ["supersonic", ...
                         "supersonic_cruise", ...
                         "supersonic_cruise_airplane"])
                    aircrafttype = "supersonic_cruise";
               end
          end

          function T = build_cg_range_table()
               % Examples of center of gravity ranges.
               % Source: Roskam, Airplane Design Part II, Table 10.3
               %
               % cg_range_in      = C.G. range in inches
               % cg_range_frac_cw = C.G. range as fraction of wing chord

               row = @(aircraftType, cgRangeIn, cgRangeFracCw) table( ...
                    string(aircraftType), ...
                    min(cgRangeIn), ...
                    mean(cgRangeIn), ...
                    max(cgRangeIn), ...
                    min(cgRangeFracCw), ...
                    mean(cgRangeFracCw), ...
                    max(cgRangeFracCw), ...
                    'VariableNames', {'AircraftType', ...
                    'cg_range_in_min', ...
                    'cg_range_in_avg', ...
                    'cg_range_in_max', ...
                    'cg_range_frac_cw_min', ...
                    'cg_range_frac_cw_avg', ...
                    'cg_range_frac_cw_max'});

               T = [
                    row("homebuilt",                    [5 5],       [0.10 0.10])
                    row("single_engine_propeller",      [7 18],      [0.06 0.27])
                    row("twin_engine_propeller",        [9 15],      [0.12 0.22])
                    row("agricultural",                 [5 5],       [0.10 0.10])
                    row("business_jet",                 [8 17],      [0.10 0.21])
                    row("regional_tbp",                 [12 20],     [0.14 0.27])
                    row("transport_jet",                [26 91],     [0.12 0.32])
                    row("military_trainer",             [8 8],       [0.10 0.10])
                    row("fighter",                      [15 15],     [0.20 0.20])
                    row("mil_patrol_bomb_transport",    [26 90],     [0.30 0.30])
                    row("flying_boat_amphibious_float", [7 28],      [0.25 0.25])
                    row("supersonic_cruise",            [20 100],    [0.30 0.30])
                    ];
          end


          function component = normalize_composite_component(component)

               component = lower(strtrim(string(component)));
               component = replace(component, "-", "_");
               component = replace(component, "/", "_");
               component = replace(component, ",", "");
               component = replace(component, ".", "");
               component = replace(component, " ", "_");

               if any(component == ["fuselage"])
                    component = "fuselage";

               elseif any(component == ["wing", ...
                         "wings", ...
                         "vertical_tail", ...
                         "vt", ...
                         "canard", ...
                         "horizontal_tail", ...
                         "ht", ...
                         "htail", ...
                         "wing_vertical_tail_canard_htail", ...
                         "wing_vertical_tail_canard_or_horizontal_tail"])
                    component = "wing_vertical_tail_canard_htail";

               elseif any(component == ["landing_gear", ...
                         "gear", ...
                         "main_gear", ...
                         "nose_gear"])
                    component = "landing_gear";

               elseif any(component == ["flaps", ...
                         "slats", ...
                         "access_panels", ...
                         "fairings", ...
                         "flaps_slats_access_panels_fairings"])
                    component = "flaps_slats_access_panels_fairings";

               elseif any(component == ["interior", ...
                         "furnishings", ...
                         "interior_furnishings"])
                    component = "interior_furnishings";

               elseif any(component == ["air_induction", ...
                         "air_induction_system", ...
                         "induction_system", ...
                         "inlet"])
                    component = "air_induction_system";
               end
          end


          function T = compositeweightreductiontable()
               % Weight reduction data for composite construction.
               % Source: Roskam, Airplane Design Part I, Table 2.16
               %
               % Values are W_comp / W_metal.

               row = @(structureGroup, component, minVal, maxVal) table( ...
                    string(structureGroup), ...
                    string(component), ...
                    minVal, ...
                    mean([minVal, maxVal]), ...
                    maxVal, ...
                    'VariableNames', {'StructureGroup', 'Component', ...
                    'W_comp_W_metal_min', ...
                    'W_comp_W_metal_avg', ...
                    'W_comp_W_metal_max'});

               T = [
                    % Primary structure
                    row("primary_structure",   "fuselage",                         0.85, 0.85)
                    row("primary_structure",   "wing_vertical_tail_canard_htail",  0.75, 0.75)
                    row("primary_structure",   "landing_gear",                     0.88, 0.88)

                    % Secondary structure
                    row("secondary_structure", "flaps_slats_access_panels_fairings", 0.60, 0.60)
                    row("secondary_structure", "interior_furnishings",              0.50, 0.50)
                    row("secondary_structure", "air_induction_system",              0.70, 0.80)
                    ];
          end

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