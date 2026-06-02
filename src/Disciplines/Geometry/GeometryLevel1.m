classdef GeometryLevel1
     %GEOMETRYLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          % Geometric fuselage parameters
          % Source: Roskam, Airplane Design Part II, Table 4.1
          fuselage_geometry_table = GeometryLevel1.build_fuselage_geometry_table();
     end

     methods (Static)

          function [L_fuselage, a, c] = get_fus_len(aircraft_type, W_TO)
               if aircraft_type == "sailplane - unpowered"
                    a = 0.86;
                    C = 0.48;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "sailplane - powered"
                    a = 0.71;
                    C = 0.48;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "homebuilt - metal") || (aircraft_type == "homebuilt - wood")
                    a = 3.68;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "homebuilt - composite"
                    a = 3.50;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "general aviation - single engine"
                    a = 4.37;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "general aviation - twin engine"
                    a = 0.86;
                    C = 0.42;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "agricultural aircraft"
                    a = 4.04;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "twin turboprop"
                    a = 0.37;
                    C = 0.51;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "flying boat"
                    a = 1.05;
                    C = 0.40;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "jet trainer"
                    a = 0.79;
                    C = 0.41;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "Jet fighter") || (aircraft_type == "jet fighter")
                    a = 0.93;
                    C = 0.39;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber")
                    a = 0.23;
                    C = 0.50;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "jet transport")
                    a = 0.67;
                    C = 0.43;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               else
                    error("Unrecognized aircraft type. Accepted inputs: sailplane - unpowered, sailplane - powered, homebuilt - metal, homebuilt - wood, homebuilt - composite, general aviation - single engine, general aviation - twin engine, agricultural aircraft, twin turboprop, flying boat, jet trainer, jet fighter, military cargo, military bomber, jet transport.") % Include list of acceptable parameters
               end
          end

          % Estimate fuselage length based on historical trend
          function output = compute_fus_len(a, C, W_TO)
               output = a*W_TO^(C); % Raymer, 6th ed, table 6.3
          end

          % Estimate the main wing's reference area based on W_TO and
          % desired wing loading.
          function S_ref = compute_wing_area(W_TO, WS_desired)
               S_ref = W_TO/(1/WS_desired);
          end



          % Estimate the wetted area of the aircraft
          function [S_wet, c, d] = get_design_S_wet(aircraft_type, W_TO)
               % Source: Airplane Design, vol 1, Roskam, table 3.5
               if (aircraft_type == "homebuilt")
                    c = 1.2362;
                    d = 0.4319;
               elseif (aircraft_type == "single engine prop")
                    c = 1.0892;
                    d = 0.5147;
               elseif (aircraft_type == "twin engine prop")
                    c = 0.8635;
                    d = 0.5632;
               elseif (aircraft_type == "agricultural")
                    c = 1.0447;
                    d = 0.5326;
               elseif (aircraft_type == "business jet")
                    c = 0.2263;
                    d = 0.6977;
               elseif (aircraft_type == "regional turboprop")
                    c = -0.0866;
                    d = 0.8099;
               elseif (aircraft_type == "transport jet")
                    c = 0.0199;
                    d = 0.7351;
               elseif (aircraft_type == "military trainer") % Clean wet
                    c = 0.8565;
                    d = 0.5423;
               elseif (aircraft_type == "jet fighter") % Clean wet
                    c = -0.1289; % Coefficient for fighter aircraft, given for S_wet equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
                    d = 0.7506; % Coefficient for fighter aicraft, given for S_wet equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               elseif (aircraft_type == "military patrol") || (aircraft_type == "military bomber") || (aircraft_type == "military transport")
                    c = 0.1628;
                    d = 0.7316;
               elseif (aircraft_type == "flying boat") || (aircraft_type == "amphibious") || (aircraft_type == "float")
                    c = 0.6295;
                    d = 0.6708;
               elseif (aircraft_type == "supersonic cruise")
                    c = -1.1868;
                    d = 0.9609;
               else
                    error("Couldn't identify aircraft type.")
               end
               S_wet = 10^(c) * W_TO^(d); % ft^2
               % (Aircraft Design, vol 1, Roskam, eq 3.22)
          end

          function output = tab_fuselage_geometry(aircrafttype, d_f, rangeMode)
               % Tabulate geometric fuselage parameters by aircraft type.
               %
               % Source: Roskam, Airplane Design Part II, Table 4.1
               %
               % Table values:
               %   l_f / d_f    = fuselage length / fuselage diameter
               %   l_fc / d_f   = tailcone length / fuselage diameter
               %   theta_fc_deg = tailcone angle, deg
               %
               % Inputs:
               %   aircrafttype : design/aircraft type
               %   d_f          : fuselage diameter [ft], optional
               %   rangeMode    : "mean", "min", "max", or "range"
               %
               % Usage:
               %   data = GeometryLevel1.tab_fuselage_geometry("fighter")
               %   data = GeometryLevel1.tab_fuselage_geometry("fighter", 5.0)
               %   lf   = GeometryLevel1.tab_fuselage_geometry("fighter", 5.0, "range")

               if nargin < 2
                    d_f = NaN;
               end

               if nargin < 3
                    rangeMode = "mean";
               end

               aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
               rangeMode = lower(strtrim(string(rangeMode)));

               T = GeometryLevel1.fuselage_geometry_table;

               idx = T.AircraftType == aircrafttype;

               if ~any(idx)
                    error("Unrecognized aircraft type: %s", aircrafttype);
               end

               row = T(idx, :);

               lf_df      = L1utils.resolve_range(row.lf_df{1}, rangeMode);
               lfc_df     = L1utils.resolve_range(row.lfc_df{1}, rangeMode);
               theta_fc   = L1utils.resolve_range(row.theta_fc_deg{1}, rangeMode);

               output = struct();
               output.aircrafttype = row.AircraftType;
               output.lf_df = lf_df;
               output.lfc_df = lfc_df;
               output.theta_fc_deg = theta_fc;

               % If fuselage diameter is provided, compute dimensional values.
               if ~isnan(d_f)
                    output.d_f = d_f;
                    output.l_f = lf_df .* d_f;
                    output.l_fc = lfc_df .* d_f;
               end
          end
     end

     methods (Static, Access = private)

          function T = build_fuselage_geometry_table()
               % Currently used geometric fuselage parameters.
               % Source: Roskam, Airplane Design Part II, Table 4.1
               %
               % Notes:
               %   l_f / d_f    = fuselage length ratio
               %   l_fc / d_f   = tailcone length ratio
               %   theta_fc_deg = tailcone angle, deg
               %
               % Some values in the source table are single recommended values.
               % These are stored as [value value] for consistency.

               row = @(aircraftType, lf_df, lfc_df, theta_fc_deg) table( ...
                    string(aircraftType), ...
                    {lf_df}, ...
                    {lfc_df}, ...
                    {theta_fc_deg}, ...
                    'VariableNames', {'AircraftType', 'lf_df', 'lfc_df', 'theta_fc_deg'});

               T = [
                    row("homebuilt",                    [4.0 8.0],    [3.0 3.0],   [2.0 9.0])
                    row("single_engine_propeller",      [5.0 8.0],    [3.0 4.0],   [3.0 9.0])
                    row("twin_engine_propeller",        [3.6 8.0],    [2.6 4.0],   [6.0 13.0])
                    row("agricultural",                 [5.0 8.0],    [3.0 4.0],   [1.0 7.0])
                    row("business_jet",                 [7.0 9.5],    [2.5 5.0],   [6.0 11.0])
                    row("regional_tbp",                 [5.6 10.0],   [2.0 4.0],   [15.0 19.0])
                    row("transport_jet",                [6.8 11.5],   [2.6 4.0],   [11.0 16.0])
                    row("military_trainer",             [5.4 7.5],    [3.0 3.0],   [0.0 14.0])
                    row("fighter",                      [7.0 11.0],   [3.0 5.0],   [0.0 8.0])
                    row("mil_patrol_bomb_transport",    [6.0 13.0],   [2.5 6.0],   [7.0 25.0])
                    row("flying_boat_amphibious_float", [6.0 11.0],   [3.0 6.0],   [8.0 14.0])
                    row("supersonic_cruise",            [12.0 25.0],  [6.0 8.0],   [2.0 9.0])
                    ];
          end

     end
end