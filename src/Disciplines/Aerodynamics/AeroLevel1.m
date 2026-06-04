classdef AeroLevel1
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     % Level 1 fidelity: estimation based on aircraft type. So, the user
     % tabulates the value, then enters that here (e.g., CD0, K, etc).
     % alternatively, I can have the user specify the aircraft type, then
     % pull values from a pre-configured table. That... might work.

     properties (Constant)
          CLmax_table = AeroLevel1.build_CLmax_table()
          Delta_CD0 = AeroLevel1.build_DeltaCD0_table()
     end

     methods (Static)

          % Get CD
          function CD = compute_CD(CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               CD = CD0 + K*CL^2;
          end

          %% FOR MISSION ANALYSIS
          % Tabulate L/Dmax (cruise)
          function output = get_LDmax_cruise(LDmax, enginetype)
               if (enginetype == "jet")
                    LDmax_cruise = 0.866*LDmax;
               elseif (enginetype == "prop")
                    LDmax_cruise = LDmax;
               else
                    error("Error handler.")
               end
               output = LDmax_cruise;
          end

          % Tabulate L/Dmax (loiter)
          function output = get_LDmax_loiter(LDmax, enginetype)
               if (enginetype == "jet")
                    LDmax_loiter = LDmax;
               elseif (enginetype == "prop")
                    LDmax_loiter = 0.866*LDmax;
               else
                    error("Error handler.")
               end
               output = LDmax_loiter;
          end

          % Compute LD_max
          function LD_max = compute_LDmax(K_LD, AR_wetted)
               LD_max = K_LD*sqrt(AR_wetted); % Raymer, 6th ed, eq 3.12
          end

          % Compute AR wetted
          function AR_wetted = compute_AR_wetted(b, S_wet)
               AR_wetted = b^2/S_wet; % Raymer, 6th ed, eq 3.11
          end

          % Tabulate K_LD
          % Raymer, 6th ed, page 40
          function K_LD = tab_K_LD(design_type)
               if (design_type == "civil jet")
                    K_LD = 15.5;
               elseif (design_type == "military jet") || (design_type == "Jet fighter") || (design_type == "jet fighter")
                    K_LD = 14;
               elseif (design_type == "retractable prop")
                    K_LD = 11;
               elseif (design_type == "nonretractable prop")
                    K_LD = 9;
               elseif (design_type == "high-AR aircraft")
                    K_LD = 13;
               elseif (design_type == "sailplane")
                    K_LD = 15;
               else
                    error("Error handler.")
               end
          end

          % Equivalent aspect ratio
          % Raymer, table 4.1, 6th edition
          function equiv_AR = tabulate_equivAR(aircraft_type, engine_type, n_engines, LDbest, M_max)
               if ((aircraft_type == "sailplane") && (engine_type == "none")) || (aircraft_type == "sailplane")
                    equiv_AR = 0.19*(LDbest^(1.3));
               elseif (engine_type == "propeller") || (engine_type == "prop")
                    if (aircraft_type == "homebuilt")
                         equiv_AR = 6.0;
                    elseif (aircraft_type == "general aviation")
                         if (n_engines == 1)
                              equiv_AR = 7.6;
                         elseif (n_engines == 2)
                              equiv_AR = 7.8;
                         else
                              warning("Table lacks entry for engine count. Setting equiv_AR to 7.8.")
                              equiv_AR = 7.8;
                         end
                    elseif (aircraft_type == "agricultural")
                         equiv_AR = 7.5;
                    elseif (aircraft_type == "turboprop")
                         if (n_engines == 2)
                              equiv_AR = 9.2;
                         else
                              warning("No entry for engine count. Setting equiv_AR = 9.2.")
                              equiv_AR = 9.2;
                         end
                    else
                         error(sprintf("Couldn't determine aircraft type.\nAccepted types for engine class 'propeller'/'prop': \n   * homebuilt \n   * general aviation \n   * agricultural \n   * turboprop"))
                    end
               elseif (engine_type == "jet")
                    if (aircraft_type == "trainer")
                         a = 4.737;
                         c = -0.979;
                    elseif (aircraft_type == "fighter") || (aircraft_type == "dogfighter")
                         a = 5.416;
                         c = -0.622;
                    elseif (aircraft_type == "fighter") && (aircraft_type ~= "dogfighter") % e.g., interceptors, fighter-bombers, etc.
                         a = 4.110;
                         c = -0.622;
                    elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber") || (aircraft_type == "cargo") || (aircraft_type == "bomber")
                         a = 5.570;
                         c = -1.075;
                    elseif (aircraft_type == "transport")
                         a = 8.75;
                         c = 0;
                    else
                         error(sprintf("Couldn't determine aircraft type.\nAccepted types for engine class 'jet': \n   * trainer\n   * fighter/dogfighter/other\n   * military cargo/bomber\n   * transport"))
                    end
                    % Compute equivalent AR
                    equiv_AR = AeroLevel1.compute_equiv_AR_jet(a, c, M_max);
               else
                    error(sprintf("Couldn't determine engine type.\nAccepted types:\n   * propeller\n   * jet\n   * none"))
               end
          end

          % Compute equivalent AR for jet
          function equiv_AR = compute_equiv_AR_jet(a, c, M_max)
               equiv_AR = a*M_max^c;
          end

          % Estimate CD0
          function CD0 = compute_CD0(Cf, S_wet, S_ref)
               CD0 = Cf*S_wet/S_ref;
          end

          % Get equivalent skin friction coefficient
          % Source: Raymer, Table 12.3, 6th edition
          % Revise this to use more universal type recognition.
          function Cf = get_Cf(aircraft_type, n_engines)
               if (aircraft_type == "bomber")
                    Cf = 0.0030;
               elseif (aircraft_type == "civil transport")
                    Cf = 0.0026;
               elseif (aircraft_type == "military cargo")
                    Cf = 0.0035;
               elseif (aircraft_type == "air force fighter")
                    Cf = 0.0035;
               elseif (aircraft_type == "navy fighter")
                    Cf = 0.0040;
               elseif (aircraft_type == "supercruise aircraft")
                    Cf = 0.0025;
               elseif (aircraft_type == "light aircraft")
                    if (0 < n_engines <= 1)
                         Cf = 0.0055;
                    elseif (1 < n_engines <= 2)
                         Cf = 0.0045;
                    else
                         warning("More engines than the table expected. Setting Cf = 0.0045.")
                         Cf = 0.0045;
                    end
               elseif (aircraft_type == "prop seaplane")
                    Cf = 0.0065;
               elseif (aircraft_type == "jet seaplane")
                    Cf = 0.0040;
               else
                    error("Couldn't identify aircraft type.")
               end
          end




          % Using Roskam's work here
          function output = tab_CLmax_values(aircrafttype, condition, rangeMode)
               % Preliminary maximum lift coefficient lookup
               % Source: Roskam, Airplane Design Part I, Table 3.1
               %
               % Table values:
               %   CL_max_clean : maximum lift coefficient, clean
               %   CL_max_TO    : maximum lift coefficient, takeoff
               %   CL_max_L     : maximum lift coefficient, landing
               %
               % Usage:
               %   CL = tab_CLmax_values("fighter", "clean")
               %   CL = tab_CLmax_values("fighter", "takeoff", "range")
               %   CL = tab_CLmax_values("fighter", "landing", "max")
               %   data = tab_CLmax_values("fighter")
               if nargin < 2
                    condition = "";
               end

               if nargin < 3
                    rangeMode = "mean";
                    % Options: "mean", "min", "max", "range"
               end

               aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
               condition = AeroLevel1.normalize_CL_condition(condition);
               rangeMode = lower(strtrim(string(rangeMode)));

               CLTable = AeroLevel1.CLmax_table;

               idx = CLTable.AircraftType == aircrafttype;

               if ~any(idx)
                    error("Unrecognized aircraft type: %s", aircrafttype);
               end

               row = CLTable(idx, :);

               data = struct();
               data.aircrafttype = row.AircraftType;
               data.CL_max_clean = L1utils.resolve_range(row.CL_max_clean{1}, rangeMode);
               data.CL_max_TO    = L1utils.resolve_range(row.CL_max_TO{1}, rangeMode);
               data.CL_max_L     = L1utils.resolve_range(row.CL_max_L{1}, rangeMode);

               % If no condition requested, return all values.
               if condition == ""
                    output = data;
                    return
               end

               switch condition
                    case "clean"
                         output = data.CL_max_clean;

                    case "takeoff"
                         output = data.CL_max_TO;

                    case "landing"
                         output = data.CL_max_L;

                    otherwise
                         error("Unrecognized CL condition: %s", condition);
               end
          end



     end

     methods (Static, Access = private)


          function T = build_CLmax_table()

               row = @(aircraftType, CL_clean, CL_TO, CL_L) table( ...
                    string(aircraftType), ...
                    {CL_clean}, ...
                    {CL_TO}, ...
                    {CL_L}, ...
                    'VariableNames', {'AircraftType', 'CL_max_clean', 'CL_max_TO', 'CL_max_L'});

               T = [
                    row("homebuilt",                    [1.2 1.8], [1.2 1.8], [1.2 2.0])
                    row("single_engine_propeller",      [1.3 1.9], [1.3 1.9], [1.6 2.3])
                    row("twin_engine_propeller",        [1.2 1.8], [1.4 2.0], [1.6 2.5])
                    row("agricultural",                 [1.3 1.9], [1.3 1.9], [1.3 1.9])
                    row("business_jet",                 [1.4 1.8], [1.6 2.2], [1.6 2.6])
                    row("regional_tbp",                 [1.5 1.9], [1.7 2.1], [1.9 3.3])
                    row("transport_jet",                [1.2 1.8], [1.6 2.2], [1.8 2.8])
                    row("military_trainer",             [1.2 1.8], [1.4 2.0], [1.6 2.2])
                    row("fighter",                      [1.2 1.8], [1.4 2.0], [1.6 2.6])
                    row("mil_patrol_bomb_transport",    [1.2 1.8], [1.6 2.2], [1.8 3.0])
                    row("flying_boat_amphibious_float", [1.2 1.8], [1.6 2.2], [1.8 3.4])
                    row("supersonic_cruise",            [1.2 1.8], [1.6 2.0], [1.8 2.2])
                    ];
          end

          function condition = normalize_CL_condition(condition)

               condition = lower(strtrim(string(condition)));
               condition = replace(condition, "-", "_");
               condition = replace(condition, " ", "_");

               if any(condition == ["", "all"])
                    condition = "";

               elseif any(condition == ["clean", ...
                         "clmax", ...
                         "cl_max", ...
                         "cl_max_clean"])
                    condition = "clean";

               elseif any(condition == ["to", ...
                         "takeoff", ...
                         "take_off", ...
                         "clmax_to", ...
                         "cl_max_to", ...
                         "cl_max_takeoff"])
                    condition = "takeoff";

               elseif any(condition == ["l", ...
                         "land", ...
                         "landing", ...
                         "clmax_l", ...
                         "cl_max_l", ...
                         "cl_max_landing"])
                    condition = "landing";
               end
          end

          function output = build_DeltaCD0_table()

               row = @(flapconfig, DeltaCD0, e_osw) table( ...
                    string(flapconfig), ...
                    {DeltaCD0}, ...
                    {e_osw}, ...
                    'VariableNames', {'flap config', 'Delta CD0', 'e Oswald'});

               output = [
                    row("Clean",                    [0 0], [0.8 0.85])
                    row("Take-Off Flaps",           [0.010 0.020], [0.75 0.80])
                    row("Landing Flaps",            [0.055 0.075], [0.70 0.75])
                    row("Landing Gear",             [0.015 0.025], NaN)
                    ];
          end


     end

end