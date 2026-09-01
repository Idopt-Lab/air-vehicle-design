classdef AeroL1
%AEROL1  Level-1 aerodynamics static toolbox: aircraft type only, no geometry.
%   Call as AeroL1.method(...); never instantiated, not in the inheritance
%   chain. F16AeroL1 inherits AeroModelL1 and delegates to these statics.
%   No static takes a design object. Each takes scalars, strings or arrays.
%
%   Drag polar [Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9]. CD0(M)
%   interpolated from the fighter "Current" type-curve [Mattingly Fig. 2.10].
%   K1 is equation-based (not a curve): k1_from_geometry reuses AeroL2's Raymer
%   equations [Eq. 12.48-12.50 subsonic Oswald-e/K1, Eq. 12.51 supersonic K1]
%   fed the real F-16 wing AR/sweep. K2 = 0 for an uncambered fighter
%   [Mattingly Sec. 2.3.1]. CLmax and high-lift increments [Roskam Vol. I
%   Table 3.1, Table 3.6].
%
%   Transonic gap: Eq. 12.51's pole near M=1 makes k1_from_geometry return NaN
%   in the AeroL2 transonic band (0.95 <= M < 1.05); CD0(M) stays a smooth
%   curve with no gap. No F-16 requirement condition falls in that band.
%
%   TODO: Mattingly Fig. 2.10 is not in this repo. The CD0 curve block in
%   f16a_L1.json is seeded from 5 AAF worked-example points and marked
%   _placeholder. Guarded by TestAeroL1.testTODO_MattinglyCurvesArePlaceholder.
%   History and rationale: docs/decision_log.md
%   Companion doc: src/disciplines/aerodynamics/AeroL1.md

% Type-based tables (no geometry): Roskam CLmax by category and the
% high-lift-device Delta_CD0 / e-osw table. Consumed by F16AeroL1's
% CLmax and HLD-delta methods.
     properties (Constant)
          CLmax_table = AeroL1.build_CLmax_table()    % Roskam Vol. I Table 3.1 (clean/TO/landing CLmax by type)
          Delta_CD0   = AeroL1.build_DeltaCD0_table() % Roskam Vol. I Table 3.6 (Delta_CD0/e by flap+gear config)
     end

    methods (Static)
        

        % ================================================================== %
        % LOW-LEVEL: pure math -- scalars/arrays only, no object access.
        % ================================================================== %

        function K1 = k1_from_geometry(AR, Lambda_LE_deg, M)
        %K1_FROM_GEOMETRY  Induced-drag factor from wing AR/sweep, reusing
        %   AeroL2's low-level Raymer equations.
        %     Subsonic (M < AeroL2.MACH_SUBSONIC_MAX):
        %       e  = AeroL2.oswald_eff(AR, Lambda_LE_deg)   [Raymer Eq. 12.48/12.49]
        %       K1 = AeroL2.K1_subsonic(e, AR)              [Raymer Eq. 12.50]
        %     Supersonic (M >= AeroL2.MACH_SUPERSONIC_MIN):
        %       K1 = AeroL2.K1_supersonic(M, AR, Lambda_LE_deg)  [Raymer Eq. 12.51]
        %     Transonic band: NaN (Eq. 12.51 pole near M=1).
            arguments
                AR            (1,1) double {mustBePositive}
                Lambda_LE_deg (1,1) double {mustBeReal}
                M             (1,1) double {mustBeReal, mustBeNonnegative}
            end
            regime = AeroL2.flight_regime(M);
            switch regime
                case "subsonic"
                    e_osw = AeroL2.oswald_eff(AR, Lambda_LE_deg); % TODO (8/13/2026): AeroL1 should not be using AeroL2. Move
                    K1    = AeroL2.K1_subsonic(e_osw, AR);
                case "supersonic"
                    K1 = AeroL2.K1_supersonic(M, AR, Lambda_LE_deg);
                otherwise   % "transonic"
                    K1 = NaN;
            end
        end

    
        function v = interp_curve(mach_pts, val_pts, M)
            arguments
                mach_pts (1,:) double {mustBeReal}
                val_pts  (1,:) double {mustBeReal}
                M        (1,1) double {mustBeReal}
            end
            if numel(mach_pts) ~= numel(val_pts)
                error('AeroL1:curveLengthMismatch', ...
                    'mach_pts has %d elements but val_pts has %d.', ...
                    numel(mach_pts), numel(val_pts));
            end
            if numel(mach_pts) < 2
                error('AeroL1:curveTooShort', ...
                    'A value-vs-Mach curve needs at least 2 breakpoints (got %d).', ...
                    numel(mach_pts));
            end
            if any(diff(mach_pts) <= 0)
                error('AeroL1:curveNotAscending', ...
                    ['Curve Mach breakpoints must be strictly ascending (got %s). ', ...
                     'interp_curve clamps to the first/last element as the range ', ...
                     'bounds, so an unsorted or duplicated vector clamps wrongly ', ...
                     'or returns NaN.'], mat2str(mach_pts));
            end
            Mc = min(max(M, mach_pts(1)), mach_pts(end));
            v  = interp1(mach_pts, val_pts, Mc, 'linear');
        end

        function K2 = mattingly_K2(design_type)
            switch string(design_type)
                case "uncambered"
                    K2 = 0;
                otherwise
                    error('AeroL1:unsupportedDesignType', ...
                        ['L1 Mattingly type-curve K2 is only defined for the ' ...
                         'uncambered (fighter) type (K2=0, Mattingly Sec. 2.3.1). ' ...
                         'design_type="%s" needs a cambered-type K2=-2*K''''*CL_min ' ...
                         'curve fit that is not yet in the repo (TODO).'], design_type);
            end
        end

        function rowName = to_CLmax_table_row(aircraft_category)
        %TO_CLMAX_TABLE_ROW  Canonical category -> the row name Roskam prints.
        %   [Roskam Vol. I Table 3.1, p. 91]. The row name is the textbook's, so
        %   do NOT rename a row to match a key. Each printed name also maps to
        %   itself, so either spelling works.
        %   Roskam has no sailplane row, so "sailplane" passes through and
        %   roskam_CLmax_value then reports the known rows.
            arguments
                aircraft_category (1,1) string
            end
            switch aircraft_category
                case {"jet_fighter", "navy_fighter", "fighter"}
                    rowName = "fighter";
                case {"jet_transport", "civil_transport", "transport_jet"}
                    rowName = "transport_jet";
                case {"military_cargo", "jet_bomber", "bomber", ...
                      "military_patrol", "mil_patrol_bomb_transport"}
                    rowName = "mil_patrol_bomb_transport";
                case {"general_aviation_single", "light_aircraft_single", ...
                      "single_engine_propeller"}
                    rowName = "single_engine_propeller";
                case {"general_aviation_twin", "light_aircraft_twin", ...
                      "twin_engine_propeller"}
                    rowName = "twin_engine_propeller";
                case {"regional_turboprop", "regional_tbp"}
                    rowName = "regional_tbp";
                case {"jet_seaplane", "prop_seaplane", "flying_boat", ...
                      "amphibious", "flying_boat_amphibious_float"}
                    rowName = "flying_boat_amphibious_float";
                case {"supersonic_transport", "supersonic_cruise"}
                    rowName = "supersonic_cruise";
                case {"homebuilt", "agricultural", "business_jet", "military_trainer"}
                    rowName = aircraft_category;   % printed name already
                otherwise
                    rowName = aircraft_category;   % pass through; the caller validates
            end
        end

        function CLmax = roskam_CLmax_value(aircraft_category, column)
            arguments
                aircraft_category (1,1) string
                column            (1,1) string {mustBeMember(column, ["CL_max_clean","CL_max_TO","CL_max_L"])}
            end
            T   = AeroL1.CLmax_table;
            row = T(T.AircraftType == AeroL1.to_CLmax_table_row(aircraft_category), :);
            if isempty(row)
                error('AeroL1:unknownAircraftType', ...
                    ['Unknown aircraft_category "%s" for Roskam Table 3.1 (no row "%s"). ', ...
                     'Known rows: %s.'], aircraft_category, ...
                     AeroL1.to_CLmax_table_row(aircraft_category), ...
                     strjoin(cellstr(T.AircraftType), ', '));
            end
            CLmax = mean(row.(column){1});
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
