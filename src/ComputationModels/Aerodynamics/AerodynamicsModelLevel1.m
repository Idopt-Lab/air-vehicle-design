classdef AerodynamicsModelLevel1
     %AERODYNAMICSMODELLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     % These are the properties that MUST BE IMPLEMENTED BY SUBCLASSES.
     properties (Abstract)
          e_osw_clean % e, clean (no flaps, no gear down/out)
          e_osw_TO % e, flaps in take-off config
          e_osw_L % e, flaps in landing config
          LD_max
          AR_wet
          K_LD
          K % This is just K = 1/(pi*e_osw*AR), which is K1 subsonic. Kept "just in case".
          K1
          K2
          Cf
          CL_minD
          CL_max_clean
          CL_max_TO
          CL_max_L
          % I THINK I can squeeze Delta_CL_max into this. Consider this for
          % later.
          Delta_CD0_TO % Change in CD0 due to flaps in take-off configuration
          Delta_CD0_L % Change in CD0 due to flaps in landing config
          Delta_CD0_geardown % Change in CD0 due to landing gear down/out
     end

     % These are the method functions that MUST BE IMPLEMENTED BY
     % SUBCLASSES.
     methods (Abstract)
          e_osw = get_e_osw(AR, Lambda_LE) % This function is supposed to COMPUTE e_osw
          % You'll need a method to tabulate e_osw for takeoff and landing
          % (e_osw_TO, e_osw_L)
          % conditions (Roskam's "Airplane Design Vol I/II" has tables on
          % this).
          LD_max = get_LD_max(aircraft_type, b, S_wet) % You'll also need AR_wet for this.
          % AR_wet = get_AR_wet(b, S_wet)
          K = get_K(e_osw, AR)
          K1 = compute_K1(M, AR, e_osw, LE_sweep)
          K2 = compute_K2(M, K1, CLminD)
          CD = get_CD(CD0, K, CL)
          CD0 = get_CD0(Cf, S_wet, S_ref)
          CDi = get_CDi(statevector, CL, e_osw, AR)
          Delta_CD0 = get_Delta_CD0(configuration, rangeMode)
          CL_minD = get_CL_minD(airfoil_type, CL_min, CD0)
          Cf = get_Cf(aircraft_type, n_engines)
          CL_max = get_CL_max_values(aircraft_type, config, rangeMode)
          CL = get_CL(L, q, S_ref)
          
     end


     %% ---------------------------------------------------------------

     properties (Constant)
          CLmax_table = AerodynamicsModelLevel1.build_CLmax_table()
          Delta_CD0 = AerodynamicsModelLevel1.build_DeltaCD0_table()
     end


     % These are common functions that should be available at every
     % fidelity level.
     methods

          % Constructor
          function obj = AerodynamicsModelLevel1()

          end

          % Get K1 subsonic value (Source: Brandt)
          function output = K1_sub(~, AR, e_osw)
               output = 1/(pi*AR*e_osw);
          end

          % Get K1 supersonic value (Source: Brandt)
          function output = K1_sup(~, AR, M, LE_sweep_deg)
               output = ((AR*(M^2 - 1))/(4*AR*sqrt(M^2 - 1)-2))*cosd(LE_sweep_deg);
          end

          % Get K2 subsonic value (Source: Brandt)
          function output = K2_sub(~, K1, CLminD)
               output = -2*K1*CLminD;
          end

          % Get K2 supersonic value (Source: Brandt)
          function output = K2_sup(obj)
               output = 0; % This is always zero
          end

          % Get e_osw for a design (straight wings)
          function output = e_straight(~, AR)
               output = (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
          end

          % Get e_osw for a design (swept wings)
          function output = e_swept(~, AR, Lambda_LE_deg)
               output = (4.61*(1-0.045*AR^(0.68))*cosd(Lambda_LE_deg)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)
          end

          % Get design drag
          function output = D(q, CD, S_ref)
               output = CD*q*S_ref;
          end

          % Get CL for some given state
          function output = CL(~, L, q, S_ref)
               output = L./(q.*S_ref);
          end

          % % Get CL_minD (using brandt's equation)
          % function output = comp_CL_minD(CL_alpha, alpha_L0_deg)
          %      alpha_L0_rad = deg2rad(alpha_L0_deg);
          %      output = CL_alpha*(-1*alpha_L0_rad/2);
          % end
          % 
          % % Estimate theoretical lift-curve slope for 2-D airfoil
          % % (subsonic)
          % % Raymer, 6th ed, fig 12.6
          % function output = CL_alpha_2D_sub(M)
          %      output = 2*pi/(sqrt(1-M^2));
          % end
          % 
          % % Estimate theoretical lift-curve slope for a supersonic 2-D
          % % airfoil
          % % Raymer, 6th ed, fig 12.6
          % function output = CL_alpha_2D_sup(M)
          %      output = 4/(sqrt(M^2 - 1));
          % end

          % Get CD (uncambered)
          function output = CD_uncambered(CD0, K, CL)
               output = CD0 + K.*CL.^2;
          end

          % % Get CD (cambered)
          % function output = CD_cambered(CD_min, K, CL, CL_minD)
          %      output = CD_min + K.*(CL - CL_minD).^2;
          % end

          % Compute CDi
          % Compute CDi (subsonic case)
          function CDi = CDi_subsonic(~, CL, e_osw, AR)
               CDi = ( (CL^2) / (pi * e_osw * AR));
          end

          % Compute CDi (supersonic case)
          function CDi = CDi_supersonic(~, CL, alpha_deg)
               CDi = CL*sind(alpha_deg);
          end

          % Estimate CD0
          function output = CD0(~, Cf, S_wet, S_ref)
               output = Cf*S_wet/S_ref;
          end


          % This might be better in L1
          % Estimate Delta_CL_max_TO
          % Source: Aircraft Design Vol 2, Roskam, eq 7.6
          function output = comp_Delta_CL_max_TO(~, CL_max_TO, CL_max)
               output = 1.05*(CL_max_TO - CL_max);
          end

          % This might be better in L1
          % Estimate Delta_CL_max_L (landing)
          % Source: Aircraft Design Vol 2, Roskam, eq 7.7
          function output = comp_Delta_CL_max_L(~, CL_max_L, CL_max)
               output = 1.05*(CL_max_L - CL_max); % Yes, this is the same as the one for Delta_CL_max_TO
          end

          % % This might be better in L2
          % % Estimate the required incrementatl section maximum lift
          % % coefficient with the flaps down
          % % Source: Airplane Design Vol 2, Roskam, eq 7.8
          % function output = Delta_cl_max(Delta_CL_max, S_ref, S_wf, K_Lambda)
          %      output = Delta_CL_max*(S_ref/S_wf)/(K_Lambda);
          % end


          % Estimate CL_max_w (clean)
          % Source: Airplane Design Vol 2, Roskam, eq 7.3
          function output = CL_max_w(~, k_lambda, cl_max_r, cl_max_t)
               output = k_lambda*(cl_max_r + cl_max_t)/2;
          end

          % Determine if aircraf is "short-coupled" or "long-coupled"
          % Source: Aircraft Design Vol 2, Roskam, page 168
          function output = isShortOrLongCoupled(~, l_h, c_bar)
               if (0.0 <= l_h/c_bar) && (l_h/c_bar < 3.0)
                    output = "short coupled";
               elseif (l_h/c_bar >= 5.0)
                    output = "long coupled";
               else
                    output = "medium coupled";
               end
          end

          % Correct for sweep effects using the "cosine rule"
          % Source: Airplane Design Vol 2, Roskam, eq 7.2
          % outputs CL_max_w_unswept
          function output = CL_max_w_unswept(~, CL_max_w_swept, Lambda_qc)
               output = CL_max_w_swept/cosd(Lambda_qc);
          end

          %% FOR MISSION ANALYSIS
          % Tabulate L/Dmax (cruise)
          function output = get_LDmax_cruise(~, LDmax, enginetype)
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
          function LD_max = compute_LDmax(~, K_LD, AR_wetted)
               LD_max = K_LD*sqrt(AR_wetted); % Raymer, 6th ed, eq 3.12
          end

          % Compute AR wetted
          function AR_wetted = compute_AR_wetted(~, b, S_wet)
               AR_wetted = b^2/S_wet; % Raymer, 6th ed, eq 3.11
          end

          % Tabulate K_LD
          % Raymer, 6th ed, page 40
          function K_LD = tab_K_LD(~, design_type)
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

          % Get equivalent skin friction coefficient
          % Source: Raymer, Table 12.3, 6th edition
          % Revise this to use more universal type recognition.
          function output = tab_Cf(~, aircraft_type, n_engines)
               if (aircraft_type == "bomber")
                    output = 0.0030;
               elseif (aircraft_type == "civil transport")
                    output = 0.0026;
               elseif (aircraft_type == "military cargo")
                    output = 0.0035;
               elseif (aircraft_type == "air force fighter")
                    output = 0.0035;
               elseif (aircraft_type == "navy fighter")
                    output = 0.0040;
               elseif (aircraft_type == "supercruise aircraft")
                    output = 0.0025;
               elseif (aircraft_type == "light aircraft")
                    if (0 < n_engines <= 1)
                         output = 0.0055;
                    elseif (1 < n_engines <= 2)
                         output = 0.0045;
                    else
                         warning("More engines than the table expected. Setting Cf = 0.0045.")
                         output = 0.0045;
                    end
               elseif (aircraft_type == "prop seaplane")
                    output = 0.0065;
               elseif (aircraft_type == "jet seaplane")
                    output = 0.0040;
               else
                    error("Couldn't identify aircraft type.")
               end
          end




          % Using Roskam's work here
          function output = tab_DeltaCD0(~, flapconfig, quantity, rangeMode)
               % Tabulate Delta_CD0 and optional Oswald efficiency factor by flap configuration.
               %
               % Usage:
               %   dCD0 = AeroLevel1.tab_DeltaCD0("takeoff flaps")
               %   dCD0 = AeroLevel1.tab_DeltaCD0("landing flaps", "Delta_CD0", "max")
               %   e    = AeroLevel1.tab_DeltaCD0("clean", "e_osw", "range")
               %   data = AeroLevel1.tab_DeltaCD0("landing gear", "all")

               if nargin < 2
                    quantity = "Delta_CD0";
               end

               if nargin < 3
                    rangeMode = "mean";
                    % Options: "mean", "min", "max", "range"
               end

               flapconfig = AerodynamicsModelLevel1.normalize_flapconfig(flapconfig);
               quantity = AerodynamicsModelLevel1.normalize_DeltaCD0_quantity(quantity);
               rangeMode = lower(strtrim(string(rangeMode)));

               T = AerodynamicsModelLevel1.Delta_CD0;

               idx = T.FlapConfig == flapconfig;

               if ~any(idx)
                    error("Unrecognized flap configuration: %s", flapconfig);
               end

               row = T(idx, :);

               data = struct();
               data.flapconfig = row.FlapConfig;
               data.Delta_CD0 = L1utils.resolve_range(row.Delta_CD0{1}, rangeMode);
               data.e_osw = L1utils.resolve_range(row.e_osw{1}, rangeMode);

               if quantity == "all"
                    output = data;
                    return
               end

               switch quantity
                    case "Delta_CD0"
                         output = data.Delta_CD0;

                    case "e_osw"
                         output = data.e_osw;

                    otherwise
                         error("quantity must be 'Delta_CD0', 'e_osw', or 'all'.");
               end
          end


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

          function quantity = normalize_DeltaCD0_quantity(quantity)

               quantity = lower(strtrim(string(quantity)));
               quantity = replace(quantity, "-", "_");
               quantity = replace(quantity, " ", "_");

               if any(quantity == ["all", "data", "table"])
                    quantity = "all";

               elseif any(quantity == ["dcd0", ...
                         "delta_cd0", ...
                         "delta_c_d0", ...
                         "cd0_increment"])
                    quantity = "Delta_CD0";

               elseif any(quantity == ["e", ...
                         "e_osw", ...
                         "eosw", ...
                         "oswald", ...
                         "oswald_efficiency"])
                    quantity = "e_osw";
               end
          end


          function flapconfig = normalize_flapconfig(flapconfig)

               flapconfig = lower(strtrim(string(flapconfig)));
               flapconfig = replace(flapconfig, "-", "_");
               flapconfig = replace(flapconfig, " ", "_");
               flapconfig = replace(flapconfig, "/", "_");

               if any(flapconfig == ["clean", "none", "no_flaps"])
                    flapconfig = "clean";

               elseif any(flapconfig == ["takeoff", ...
                         "takeoff_flaps", ...
                         "take_off", ...
                         "take_off_flaps", ...
                         "to_flaps"])
                    flapconfig = "takeoff_flaps";

               elseif any(flapconfig == ["landing", ...
                         "landing_flaps", ...
                         "land_flaps"])
                    flapconfig = "landing_flaps";

               elseif any(flapconfig == ["landing_gear", ...
                         "gear", ...
                         "lg",...
                         "geardown"])
                    flapconfig = "landing_gear";
               end
          end

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
                    'VariableNames', {'FlapConfig', 'Delta_CD0', 'e_osw'});

               output = [
                    row("clean",          [0.000 0.000], [0.80 0.85])
                    row("takeoff_flaps",  [0.010 0.020], [0.75 0.80])
                    row("landing_flaps",  [0.055 0.075], [0.70 0.75])
                    row("landing_gear",   [0.015 0.025], NaN)
                    ];
          end


     end

end