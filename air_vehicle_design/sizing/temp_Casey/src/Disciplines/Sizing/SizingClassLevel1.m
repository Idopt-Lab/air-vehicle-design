classdef SizingClassLevel1
     %SIZING Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          % Existing table
          W_L_W_TO_table = SizingClassLevel1.landingweightratiotable();

          % Absolute ceiling lookup table
          % Source: Roskam, Airplane Design Part I, Table 3.7
          h_abs_table = SizingClassLevel1.absoluteceilingtable();

          % Ceiling definition / required climb-rate lookup table
          % Source: Roskam, Airplane Design Part I, Table 3.8
          ceiling_ROC_table = SizingClassLevel1.ceilingclimbratetable();
     end

     methods (Static)




          function output = tab_ceilingclimbrate(ceilingtype, subtype, outputType)
               % Minimum required climb-rate lookup for airplane ceilings.
               % Source: Roskam, Airplane Design Part I, Table 3.8
               %
               % Usage:
               %   data = SizingClassLevel1.tab_ceilingclimbrate("service")
               %   data = SizingClassLevel1.tab_ceilingclimbrate("service", "commercial jet")
               %   roc  = SizingClassLevel1.tab_ceilingclimbrate("service", "commercial jet", "rate")
               %
               % Output:
               %   Minimum required climb rate in fpm.

               if nargin < 2
                    subtype = "";
               end

               if nargin < 3
                    outputType = "";
               end

               ceilingtype = SizingClassLevel1.normalize_ceiling_type(ceilingtype);
               subtype = SizingClassLevel1.normalize_ceiling_subtype(subtype);
               outputType = lower(strtrim(string(outputType)));

               T = SizingClassLevel1.ceiling_ROC_table;

               idx = T.CeilingType == ceilingtype;

               if subtype ~= ""
                    idx = idx & T.Subtype == subtype;
               end

               if ~any(idx)
                    availableSubtypes = T.Subtype(T.CeilingType == ceilingtype);

                    if isempty(availableSubtypes)
                         error("Unrecognized ceiling type: %s", ceilingtype);
                    else
                         error("Unrecognized subtype '%s' for ceiling type '%s'. Available subtypes: %s", ...
                              subtype, ceilingtype, strjoin(availableSubtypes, ", "));
                    end
               end

               rows = T(idx, :);

               switch outputType
                    case {"", "table", "data"}
                         output = rows;

                    case {"rate", "roc", "climbrate", "climb_rate", "fpm"}
                         output = rows.MinRequiredClimbRate_fpm;

                    case {"mach", "machcondition", "mach_condition"}
                         output = rows.MachCondition;

                    case {"power", "powercondition", "power_condition"}
                         output = rows.PowerCondition;

                    otherwise
                         error("outputType must be '', 'table', 'rate', 'mach', or 'power'.");
               end
          end


          function output = tab_absoluteceiling(aircrafttype, subtype, valueType)
               % Typical absolute ceiling lookup
               % Source: Roskam, Airplane Design Part I, Table 3.7
               %
               % Table values in Roskam are h_abs (ft) x 10^-3.
               % This function returns values in ft.
               %
               % Usage:
               %   h = SizingClassLevel1.tab_absoluteceiling("fighter", "", "range")
               %   h = SizingClassLevel1.tab_absoluteceiling("jet", "commercial", "average")
               %   h = SizingClassLevel1.tab_absoluteceiling("piston prop", "supercharged")
               %   data = SizingClassLevel1.tab_absoluteceiling("fighter")

               if nargin < 2
                    subtype = "";
               end

               if nargin < 3
                    valueType = "";
               end

               aircrafttype = SizingClassLevel1.normalize_absoluteceiling_type(aircrafttype);
               subtype = SizingClassLevel1.normalize_absoluteceiling_subtype(subtype);
               valueType = lower(strtrim(string(valueType)));

               if subtype == ""
                    subtype = SizingClassLevel1.default_absoluteceiling_subtype(aircrafttype);
               end

               T = SizingClassLevel1.h_abs_table;

               idx = T.AircraftType == aircrafttype & T.Subtype == subtype;

               if ~any(idx)
                    availableSubtypes = T.Subtype(T.AircraftType == aircrafttype);

                    if isempty(availableSubtypes)
                         error("Unrecognized aircraft type: %s", aircrafttype);
                    else
                         error("Unrecognized subtype '%s' for aircraft type '%s'. Available subtypes: %s", ...
                              subtype, aircrafttype, strjoin(availableSubtypes, ", "));
                    end
               end

               row = T(idx, :);

               output = struct();
               output.aircrafttype = row.AircraftType;
               output.subtype = row.Subtype;
               output.h_abs_min_ft = row.h_abs_min_ft;
               output.h_abs_avg_ft = row.h_abs_avg_ft;
               output.h_abs_max_ft = row.h_abs_max_ft;

               if valueType == ""
                    return
               end

               switch valueType
                    case {"min", "minimum"}
                         output = row.h_abs_min_ft;

                    case {"avg", "average", "mean", "nominal"}
                         output = row.h_abs_avg_ft;

                    case {"max", "maximum"}
                         output = row.h_abs_max_ft;

                    case {"range"}
                         output = [row.h_abs_min_ft, row.h_abs_max_ft];

                    otherwise
                         error("valueType must be 'minimum', 'average', 'maximum', or 'range'.");
               end
          end

          % Size to FAR 23 Take-off distance requirements (TAKE-OFF PARAMETER, FAR 23
          % = TOP 23)
          function output = TOP_23(W_S_TO, W_P_TO, sigma, CL_max_TO)
               % Source: Airplane design vol 1, Roskam, 3.2
               output = (W_S_TO*W_P_TO)/(sigma*CL_max_TO);
          end

          % Get takeoff distance
          % Roskam, Airplane design, vol1, eq 3.6
          function output = S_TO(TOP_23)
               output = 8.134*TOP_23 + 0.0149*TOP_23^2;
          end

          % Sizing to FAR 25 Take-Off distance requirements
          % Source: Roskam, Airplane design, vol1, eq 3.6
          % Output: lbf/ft^2 ?
          function output = TOP_25(W_S_TO, sigma, CL_max_TO, T_W_TO)
               output = (W_S_TO)/(sigma*CL_max_TO*T_W_TO);
          end

          % Compute the take-off field length from the TOP_25 requirement
          % Source: Roskam, Airplane design, vol1, eq 3.8
          function output = S_TOFL(TOP_25)
               output = 37.5*TOP_25;
          end

          % Military sizing req
          % Take-Off ground roll
          % Source: Roskam, Airplane design, vol1, eq 3.9
          % X = T for jets, P for props
          function output = S_TOG_jet(W_S_TO, rho, CL_max_TO, T, W_TO, mu_G, CD0)
               kk_1 = 0.0447;
               kk_2 = (0.75*((5+bpr)/(4+bpr)));

               output = (kk_1*W_S_TO)/((rho*(CL_max_TO*(kk_2*(T/W_TO) - mu_G) - 0.72*CD0)));
          end

          % S_TOG but for props.
          % Source: Roska, Airplane Design, Vol1, eq 3.9
          function output = S_TOG_prop(W_S_TO, rho, CL_max_TO, P_TO, W_TO, mu_G, CD0, l_p, N, D_P)
               % N = number of engines operating
               kk_1 = 0.0376;
               kk_2 = (l_p*((sigma*N*D_P^2)/(P_TO))^(1/3));

               output = (kk_1*W_S_TO)/((rho*(CL_max_TO*(kk_2*(P_TO/W_TO) - mu_G) - 0.72*CD0)));
          end


          % Estimate takeoff weight based on catapult limitations
          % Source: Roskam, Airplane Design, Vol1, eq 3.10
          % Valid for: USN carriers
          function output = size_from_catapult(V_wod, V_cat, S_ref, CL_max_TO, rho)
               output = (0.5*rho(V_wod + V_cat)^(2) * S_ref * CL_max_TO)/1.21;
          end



          function output = tab_landingweight_ratio(aircrafttype, subtype, valueType)
               % Landing weight to takeoff weight ratio lookup
               % Source: Roskam, Airplane Design Part I, Table 3.3
               %
               % Table values:
               %   W_L_W_TO_min
               %   W_L_W_TO_avg
               %   W_L_W_TO_max
               %
               % Usage:
               %   value = SizingUtils.tab_landingweight_ratio("fighter", "jets", "average")
               %   value = SizingUtils.tab_landingweight_ratio("transport jet", "", "minimum")
               %   data  = SizingUtils.tab_landingweight_ratio("fighter", "jets")
               if nargin < 2
                    subtype = "";
               end

               if nargin < 3
                    valueType = "";
               end

               aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
               subtype = SizingClassLevel1.normalize_landingweight_subtype(subtype);
               valueType = lower(strtrim(string(valueType)));

               if subtype == ""
                    subtype = SizingClassLevel1.default_landingweight_subtype(aircrafttype);
               end

               T = SizingClassLevel1.W_L_W_TO_table;

               idx = T.AircraftType == aircrafttype & T.Subtype == subtype;

               if ~any(idx)
                    availableSubtypes = T.Subtype(T.AircraftType == aircrafttype);

                    if isempty(availableSubtypes)
                         error("Unrecognized aircraft type: %s", aircrafttype);
                    else
                         error("Unrecognized subtype '%s' for aircraft type '%s'. Available subtypes: %s", ...
                              subtype, aircrafttype, strjoin(availableSubtypes, ", "));
                    end
               end

               row = T(idx, :);

               output = struct();
               output.aircrafttype = row.AircraftType;
               output.subtype = row.Subtype;
               output.W_L_W_TO_min = row.W_L_W_TO_min;
               output.W_L_W_TO_avg = row.W_L_W_TO_avg;
               output.W_L_W_TO_max = row.W_L_W_TO_max;

               if valueType == ""
                    return
               end

               switch valueType
                    case {"min", "minimum"}
                         output = row.W_L_W_TO_min;

                    case {"avg", "average", "mean"}
                         output = row.W_L_W_TO_avg;

                    case {"max", "maximum"}
                         output = row.W_L_W_TO_max;

                    case {"range"}
                         output = [row.W_L_W_TO_min, row.W_L_W_TO_max];

                    otherwise
                         error("valueType must be 'minimum', 'average', 'maximum', or 'range'.");
               end
          end


          % FAR 23 requirement. landing distance.

          % S_LG (ft) from stall speed (kts)
          % Source: Roskam, Airplane Design Vol I, eq 3.12
          function output = S_LG(V_S_L)
               output = 0.265*V_S_L^2;
          end

          % Maximum allowable landing distance S_L (ft) from S_LG (ft)
          % Source: Roskam, Airplane Design Vol I, eq 3.13
          function output = S_L(S_LG)
               output = 1.938*S_LG;
          end


          % FAR 25 requirements. Landing distance.

          % Field length, S_FL (ft) from approach speed, V_A (kts).
          % Source: Roskam, Airplane Design Vol I, eq 3.16
          function output = S_FL(V_A)
               output = 0.3*V_A^2;
          end


          % Sizing to military landing distance requirements
          % land-based aircraft

          % Compute approach speed from stall speed
          % Source: Roskam, Airplane Design Vol I, eq 3.17
          function output = V_A_landbased(V_S_L)
               output = 1.2*V_S_L;
          end


          % Carrier-based aircraft
          % Compute approach speed from stall speed
          % Source: Roskam, Airplane Design Vol I, eq 3.18
          function output = V_A_carrierbased(V_S_PA)
               output = 1.15*V_S_PA;
          end













          % function W_TO = size_aircraft(obj, design, geometry_obj, mission_obj, weight_obj, propulsion_obj, constraint_obj, requirements_obj, aero_obj)
          %
          %      weight_obj.W_fixed = mission_obj.missiondata.Startup.PayloadFixedlbf;
          %
          %      % W_S = 104.59;
          %      W_S = constraint_obj.optimal_WS;
          %      W_TO = weight_obj.W_TO_guess;
          %      weight_obj.W_TO = W_TO;
          %      tol = 1e-3;
          %      max_iteration = 40;
          %      results = [];
          %      T_W = constraint_obj.min_TW; % Desired thrust-to-weight ratio (figure out how to get this naturally later)
          %      total_fuel_used = 0;
          %      for iteration = 1:max_iteration
          %           geometry_obj.mainwings.S_ref = W_TO / W_S;
          %
          %           %% ----------------------------------------------------------------------
          %           % Estimate wetted areas
          %           geometry_obj.design.S_wet = geometry_obj.get_design_S_wet(W_TO);
          %
          %           %% ----------------------------------------------------------------------
          %           % Size the tail (should be a geometry thing)
          %           % [geometry_obj.VT.S_ref, geometry_obj.HT.S_ref] = geometry_obj.size_tail(design, geometry_obj.mainwings.S_ref);
          %
          %
          %           %% ----------------------------------------------------------------------
          %           % Get thrust at takeoff
          %           propulsion_obj.T0 = T_W*W_TO; % Fidelity III
          %
          %           %% -------------------------------------------------
          %           % Get mission fuel
          %           [weight_obj.total_fuel_used, weight_obj.fuel_fraction] = mission_obj.get_mission_fuel(constraint_obj, design, geometry_obj, propulsion_obj, weight_obj, aero_obj);
          %
          %
          %           % Compute design weight
          %           % Then compute the empty weight
          %           weight_obj.OEW = weight_obj.get_OEW(design.type, W_TO);
          %
          %           weight_obj.OEW_frac = weight_obj.OEW/weight_obj.W_TO;
          %
          %           % W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
          %           W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW;
          %
          %           difference = W_TO_new - weight_obj.W_TO;
          %           percent_diff = 100 * difference / weight_obj.W_TO;
          %           % Iterate
          %
          %           % complete iteration loop, return MTOW and such
          %           W_TO_new = weight_obj.total_fuel_used + weight_obj.W_fixed + weight_obj.OEW;
          %
          %           difference = W_TO_new - weight_obj.W_TO;
          %           percent_diff = 100 * difference / weight_obj.W_TO;
          %
          %           results(end+1, :) = [weight_obj.W_TO, weight_obj.W_fixed, weight_obj.fuel_fraction, weight_obj.OEW_frac, weight_obj.OEW, W_TO_new, difference, percent_diff];
          %
          %           if abs(difference) < tol
          %                break;
          %           end
          %           weight_obj.W_TO = W_TO_new;
          %           W_TO = W_TO_new;
          %           geometry_obj.mainwings.S_ref = geometry_obj.mainwings.S_ref;
          %      end
          %      beta = 1 - (total_fuel_used / (2 * W_TO));
          %      obj.results_table = array2table(results, 'VariableNames', {'WTO', 'W_fixed', 'Fuel_fraction', 'Empty_weight_fraction', 'Empty_weight', 'WTO_new', 'Difference', 'Percent_Diff'});
          %      disp(obj.results_table)
          % end


     end

     methods (Static, Access = private)

          function subtype = normalize_ceiling_subtype(subtype)

               subtype = lower(strtrim(string(subtype)));
               subtype = replace(subtype, "-", "_");
               subtype = replace(subtype, "/", "_");
               subtype = replace(subtype, " ", "_");
               subtype = replace(subtype, "'", "");
               subtype = replace(subtype, ".", "");
               subtype = replace(subtype, ",", "");

               if any(subtype == ["", "default"])
                    subtype = "";

               elseif any(subtype == ["commercial_piston", ...
                         "commercial_piston_prop", ...
                         "commercial_piston_propeller", ...
                         "piston_prop", ...
                         "piston_propeller"])
                    subtype = "commercial_piston_propeller";

               elseif any(subtype == ["commercial_jet", ...
                         "commercial_turbojet", ...
                         "commercial_turbofan", ...
                         "jet"])
                    subtype = "commercial_jet";

               elseif any(subtype == ["military", ...
                         "military_max", ...
                         "military_max_power", ...
                         "military_at_maximum_power"])
                    subtype = "military_max_power";

               elseif any(subtype == ["military_subsonic", ...
                         "subsonic", ...
                         "military_subsonic_max_power", ...
                         "military_subsonic_maximum_power"])
                    subtype = "military_subsonic_max_power";

               elseif any(subtype == ["military_supersonic", ...
                         "supersonic", ...
                         "military_supersonic_max_power", ...
                         "military_supersonic_maximum_power"])
                    subtype = "military_supersonic_max_power";

               elseif any(subtype == ["military_subsonic_max_cont_power", ...
                         "military_subsonic_max_continuous_power", ...
                         "subsonic_max_continuous_power"])
                    subtype = "military_subsonic_max_continuous_power";

               elseif any(subtype == ["military_supersonic_max_cont_power", ...
                         "military_supersonic_max_continuous_power", ...
                         "supersonic_max_continuous_power"])
                    subtype = "military_supersonic_max_continuous_power";
               end
          end

          function ceilingtype = normalize_ceiling_type(ceilingtype)

               ceilingtype = lower(strtrim(string(ceilingtype)));
               ceilingtype = replace(ceilingtype, "-", "_");
               ceilingtype = replace(ceilingtype, " ", "_");
               ceilingtype = replace(ceilingtype, "'", "");
               ceilingtype = replace(ceilingtype, ".", "");
               ceilingtype = replace(ceilingtype, ",", "");

               if any(ceilingtype == ["absolute", "absolute_ceiling", "h_abs"])
                    ceilingtype = "absolute";

               elseif any(ceilingtype == ["service", "service_ceiling"])
                    ceilingtype = "service";

               elseif any(ceilingtype == ["combat", "combat_ceiling"])
                    ceilingtype = "combat";

               elseif any(ceilingtype == ["cruise", "cruise_ceiling"])
                    ceilingtype = "cruise";
               end
          end

          function T = ceilingclimbratetable()
               % Definition of airplane ceilings.
               % Source: Roskam, Airplane Design Part I, Table 3.8
               %
               % Minimum required climb rate is stored in fpm.

               row = @(ceilingType, subtype, climbRate, machCondition, powerCondition) table( ...
                    string(ceilingType), ...
                    string(subtype), ...
                    climbRate, ...
                    string(machCondition), ...
                    string(powerCondition), ...
                    'VariableNames', {'CeilingType', 'Subtype', ...
                    'MinRequiredClimbRate_fpm', ...
                    'MachCondition', ...
                    'PowerCondition'});

               T = [
                    row("absolute", "default", 0, "any", "any")

                    row("service", "commercial_piston_propeller", 100, "any", "service")
                    row("service", "commercial_jet",              500, "any", "service")
                    row("service", "military_max_power",          100, "any", "maximum_power")

                    row("combat",  "military_subsonic_max_power",   500, "M < 1", "maximum_power")
                    row("combat",  "military_supersonic_max_power", 1000, "M > 1", "maximum_power")

                    row("cruise",  "military_subsonic_max_continuous_power",   300, "M < 1", "maximum_continuous_power")
                    row("cruise",  "military_supersonic_max_continuous_power", 1000, "M > 1", "maximum_continuous_power")
                    ];
          end



          function subtype = default_absoluteceiling_subtype(aircrafttype)

               switch aircrafttype
                    case "piston_prop"
                         subtype = "normally_aspirated";

                    case "jet"
                         subtype = "commercial";

                    case "turboprop_propfan"
                         subtype = "commercial";

                    case "supersonic_cruise"
                         subtype = "jet";

                    otherwise
                         subtype = "default";
               end
          end


          function subtype = normalize_absoluteceiling_subtype(subtype)

               subtype = lower(strtrim(string(subtype)));
               subtype = replace(subtype, "-", "_");
               subtype = replace(subtype, " ", "_");
               subtype = replace(subtype, "'", "");
               subtype = replace(subtype, ".", "");
               subtype = replace(subtype, ",", "");

               if any(subtype == ["", "default"])
                    subtype = "";

               elseif any(subtype == ["normal", ...
                         "normally_aspirated", ...
                         "normallyaspirated"])
                    subtype = "normally_aspirated";

               elseif any(subtype == ["supercharged", ...
                         "super_charge", ...
                         "super_chargeed"])
                    subtype = "supercharged";

               elseif any(subtype == ["commercial", ...
                         "civil"])
                    subtype = "commercial";

               elseif any(subtype == ["military", ...
                         "mil"])
                    subtype = "military";

               elseif any(subtype == ["fighter", ...
                         "fighters", ...
                         "jet_fighter"])
                    subtype = "fighter";

               elseif any(subtype == ["military_trainer", ...
                         "military_trainers", ...
                         "trainer", ...
                         "trainers"])
                    subtype = "military_trainer";

               elseif any(subtype == ["jet", ...
                         "jets"])
                    subtype = "jet";
               end
          end


          function aircrafttype = normalize_absoluteceiling_type(aircrafttype)

               aircrafttype = lower(strtrim(string(aircrafttype)));
               aircrafttype = replace(aircrafttype, "-", "_");
               aircrafttype = replace(aircrafttype, " ", "_");
               aircrafttype = replace(aircrafttype, "'", "");
               aircrafttype = replace(aircrafttype, ".", "");
               aircrafttype = replace(aircrafttype, ",", "");

               if any(aircrafttype == ["piston", ...
                         "piston_prop", ...
                         "piston_propeller", ...
                         "propeller", ...
                         "propeller_driven"])
                    aircrafttype = "piston_prop";

               elseif any(aircrafttype == ["jet", ...
                         "turbojet", ...
                         "turbofan", ...
                         "turbojet_turbofan"])
                    aircrafttype = "jet";

               elseif any(aircrafttype == ["fighter", ...
                         "fighters", ...
                         "jet_fighter"])
                    aircrafttype = "jet";

               elseif any(aircrafttype == ["military_trainer", ...
                         "military_trainers"])
                    aircrafttype = "jet";

               elseif any(aircrafttype == ["turboprop", ...
                         "turboprops", ...
                         "propfan", ...
                         "propfans", ...
                         "turboprop_propfan"])
                    aircrafttype = "turboprop_propfan";

               elseif any(aircrafttype == ["supersonic", ...
                         "supersonic_cruise", ...
                         "supersonic_cruise_airplane", ...
                         "supersonic_cruise_airplanes"])
                    aircrafttype = "supersonic_cruise";
               end
          end


          function T = absoluteceilingtable()
               % Typical values for absolute ceiling, h_abs
               % Source: Roskam, Airplane Design Part I, Table 3.7
               %
               % Original table values are h_abs (ft) x 10^-3.
               % Stored here in ft.

               row = @(aircraftType, subtype, minVal, maxVal) table( ...
                    string(aircraftType), ...
                    string(subtype), ...
                    minVal * 1000, ...
                    mean([minVal, maxVal]) * 1000, ...
                    maxVal * 1000, ...
                    'VariableNames', {'AircraftType', 'Subtype', ...
                    'h_abs_min_ft', 'h_abs_avg_ft', 'h_abs_max_ft'});

               T = [
                    % Airplanes with piston-propeller combinations
                    row("piston_prop",       "normally_aspirated", 12, 18)
                    row("piston_prop",       "supercharged",       15, 25)

                    % Airplanes with turbojet or turbofan engines
                    row("jet",               "commercial",         40, 50)
                    row("jet",               "military",           40, 55)
                    row("jet",               "fighter",            55, 75)
                    row("jet",               "military_trainer",   35, 45)

                    % Airplanes with turbopropeller or propfan engines
                    row("turboprop_propfan", "commercial",         30, 45)
                    row("turboprop_propfan", "military",           30, 50)

                    % Supersonic cruise airplanes, jets
                    row("supersonic_cruise", "jet",                55, 80)
                    ];
          end

          function T = landingweightratiotable()

               row = @(aircraftType, subtype, minVal, avgVal, maxVal) table( ...
                    string(aircraftType), ...
                    string(subtype), ...
                    minVal, ...
                    avgVal, ...
                    maxVal, ...
                    'VariableNames', {'AircraftType', 'Subtype', ...
                    'W_L_W_TO_min', 'W_L_W_TO_avg', 'W_L_W_TO_max'});

               T = [
                    row("homebuilt",                    "default", 0.96, 1.000, 1.00)
                    row("single_engine_propeller",      "default", 0.95, 0.997, 1.00)
                    row("twin_engine_propeller",        "default", 0.88, 0.990, 1.00)
                    row("agricultural",                 "default", 0.70, 0.940, 1.00)
                    row("business_jet",                 "default", 0.69, 0.880, 0.96)
                    row("regional_tbp",                 "default", 0.92, 0.980, 1.00)
                    row("transport_jet",                "default", 0.65, 0.840, 1.00)
                    row("military_trainer",             "default", 0.87, 0.990, 1.10)

                    row("fighter",                      "jets",    0.78, NaN,   1.00)
                    row("fighter",                      "tbp",     0.57, NaN,   1.00)

                    row("mil_patrol_bomb_transport",    "jets",    0.68, 0.760, 0.83)
                    row("mil_patrol_bomb_transport",    "tbp",     0.77, 0.840, 1.00)

                    row("flying_boat_amphibious_float", "land",    0.79, NaN,   0.95)
                    row("flying_boat_amphibious_float", "water",   0.98, NaN,   1.00)

                    row("supersonic_cruise",            "default", 0.63, 0.750, 0.88)
                    ];
          end

          function subtype = normalize_landingweight_subtype(subtype)

               subtype = lower(strtrim(string(subtype)));
               subtype = replace(subtype, "-", "_");
               subtype = replace(subtype, " ", "_");
               subtype = replace(subtype, "'", "");
               subtype = replace(subtype, ".", "");
               subtype = replace(subtype, ",", "");
               subtype = replace(subtype, "(", "");
               subtype = replace(subtype, ")", "");

               if any(subtype == ["", "default"])
                    subtype = "";

               elseif any(subtype == ["jet", "jets"])
                    subtype = "jets";

               elseif any(subtype == ["tbp", "tbps", "turboprop", "turboprops"])
                    subtype = "tbp";

               elseif any(subtype == ["land"])
                    subtype = "land";

               elseif any(subtype == ["water"])
                    subtype = "water";
               end
          end

          function subtype = default_landingweight_subtype(aircrafttype)

               switch aircrafttype
                    case "fighter"
                         subtype = "jets";

                    case "mil_patrol_bomb_transport"
                         subtype = "jets";

                    case "flying_boat_amphibious_float"
                         subtype = "land";

                    otherwise
                         subtype = "default";
               end
          end

     end
end