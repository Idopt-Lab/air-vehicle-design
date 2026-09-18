classdef WeightsL2
%WEIGHTSL2  Level-2 weights static toolbox: surface density x area, plus fractions.
%
%   Call as WeightsL2.method(...); never instantiated. F16WeightsL2 inherits
%   WeightsModelL2 and delegates here.
%
%   Structural groups: [Raymer 6th ed. Table 15.2] psf surface densities on
%   real areas. Landing gear, installed engine and all-else-empty: the AE481
%   metabook Sec. 7 fraction table (a separate, unnumbered table).
%
%   OEW(W_TO) evaluates both fraction terms at the PASSED W_TO. It must not
%   read the W_all_else_empty / W_installed_engine properties, which are pinned
%   to the object's own W_TO.
%
%   Companion doc: src/disciplines/weights/WeightsL2.md

    properties (Constant)
        % ---------------------------------------------------------------- %
        % Raymer Table 15.2 -- component structural surface density.
        % [Raymer 6th ed. Table 15.2; metabook_data.md:483-486]
        
        % Rows = components
        % Columns = design categories

        % Syntax:
        % WeightsL2.lookup_component_density_imp(category, component).
        % ---------------------------------------------------------------- %
        TBL152_COMPONENTS = ["wing" "horizontal_tail" "vertical_tail" "fuselage"]
        TBL152_CATEGORIES = ["fighter" "transport_bomber" "general_aviation"]

        TBL152_DENSITY_IMP = [ 9.0  10.0  2.5     % wing
                               4.0   5.5  2.0     % horizontal tail
                               5.3   5.5  2.0     % vertical tail
                               4.8   5.0  1.4 ]   % fuselage

        TBL152_DENSITY_SI  = [ 44.0  49.0  12.0    % wing
                               20.0  27.0  10.0    % horizontal tail
                               26.0  27.0  10.0    % vertical tail
                               23.0  24.0   7.0 ]  % fuselage

        % ---------------------------------------------------------------- %
        % Weight ratios -- the fraction SUB-TABLES of Raymer Table 15.2.
        % [Raymer 6th ed. Table 15.2]  Same table as the densities above; the
        % book prints the fraction rows alongside the per-area rows.
        %
        % Rows = components
        % Columns = design categories.
        % Syntax:
        % WeightsL2.lookup_weight_ratio(category, component, isNavy).
        % ---------------------------------------------------------------- %
        WR_COMPONENTS = ["landing_gear" "installed_engine" "all_else_empty"]
        WR_CATEGORIES = ["fighter" "navy_fighter" "transport_bomber" "general_aviation"]

        WR_RATIOS = [ 0.033  0.045  0.043  0.057    % landing gear     [Raymer 6th ed. Tbl 15.2]
                      1.3    1.3    1.3    1.4      % installed engine [Raymer 6th ed. Tbl 15.2]
                      0.17   0.17   0.17   0.1  ]   % all-else empty   [Raymer 6th ed. Tbl 15.2]
    end

    methods (Static)

        % ================================================================== %
        % LOW-LEVEL: unit-weight / fraction lookups, and the Brandt engine
        % alternate. Pure scalars in, scalar out.
        % ================================================================== %

        function W = compute_weight_wing(aircraft_category, S_w)
            rho_w = WeightsL2.lookup_component_density(aircraft_category, "wing", "imperial");
            W   = rho_w * S_w;
        end

        function W = compute_weight_HT(aircraft_category, S_ht)
            rho_ht = WeightsL2.lookup_component_density(aircraft_category, "horizontal_tail", "imperial");
            W = rho_ht * S_ht;
        end

        function W = compute_weight_VT(aircraft_category, S_vt)
            rho_vt = WeightsL2.lookup_component_density(aircraft_category, "vertical_tail", "imperial");
            W = rho_vt * S_vt;
        end

        function W = compute_weight_fuselage(aircraft_category, S_wet_fus)
            rho_fus = WeightsL2.lookup_component_density(aircraft_category, "fuselage", "imperial");
            W   = rho_fus * S_wet_fus;
        end

        function W = compute_weight_landing_gear(aircraft_category, W_TO, isNavy)
            arguments
                aircraft_category (1,1) string
                W_TO              (1,1) double {mustBePositive}
                isNavy            (1,1) logical = false % false = default value.
            end
            f = WeightsL2.lookup_weight_ratio(aircraft_category, "landing_gear", isNavy);
            W = f * W_TO;
        end

        function W = compute_weight_installed_engine(aircraft_category, N_en, W_en, isNavy)
            arguments
                aircraft_category (1,1) string
                N_en              (1,1) double {mustBePositive}
                W_en              (1,1) double {mustBePositive}
                isNavy            (1,1) logical = false % false = default value.
            end
            coeff = WeightsL2.lookup_weight_ratio(aircraft_category, "installed_engine", isNavy);
            W = coeff * N_en * W_en;
        end

        function W = compute_weight_all_else_empty(aircraft_category, W_TO, isNavy)
            arguments
                aircraft_category (1,1) string
                W_TO              (1,1) double {mustBePositive}
                isNavy            (1,1) logical = false % false = default value.
            end
            coeff = WeightsL2.lookup_weight_ratio(aircraft_category, "all_else_empty", isNavy);
            W = coeff * W_TO;
        end

        function W = jet_engine_weight_roskam(T0_lbf)
        %JET_ENGINE_WEIGHT_ROSKAM  Uninstalled weight [lbf] of ONE jet engine
        %   from its SLS thrust, via the Roskam multi-term regression.
        %   TURBOJET / TURBOFAN ONLY
        %   [Roskam Airplane Design Part V, Eqs. 7.13-7.19
        %
        %     Weng_dry     = 0.521 * T0^0.9                 (7.13)
        %     Weng_oil     = 0.082 * T0^0.65                (7.14)
        %     Weng_rev     = 0.034 * T0   [thrust reverser] (7.15)
        %     Weng_control = 0.26  * T0^0.5                 (7.16)
        %     Weng_start   = 9.33  * (Weng_dry/1000)^1.078  (7.18)
        %     Wengine_total = sum of the above              (7.19)
        %
        %   Turboprops take a different equation entirely:
        %     Weng = P^0.9306 * 10^-0.1205, P in shp        (7.20)
        %
        %   T0_lbf -- max SLS thrust per engine [lbf]. Returns the total weight
        %   of ONE engine [lbf]. No Eq. 7.17 term is listed; sum is Eq. 7.19.
            arguments
                T0_lbf (1,1) double {mustBePositive}
            end
            W_dry     = 0.521 * T0_lbf.^0.9;
            W_oil     = 0.082 * T0_lbf.^0.65;
            W_rev     = 0.034 * T0_lbf;
            W_control = 0.26  * T0_lbf.^0.5;
            W_start   = 9.33  * (W_dry / 1000).^1.078;
            W = W_dry + W_oil + W_rev + W_control + W_start;
        end

        function W = turboprop_engine_weight_roskam(P_shp)
        %TURBOPROP_ENGINE_WEIGHT_ROSKAM  Uninstalled weight [lbf] of ONE
        %   turboprop engine from its rated shaft power.
        %   ARGS:
        %       P_shp = Shaft horsepower (hp)
        %   RETURNS:
        %       W = Engine weight (lbf)
        %   CITATION:
        %       Roskam Airplane Design Part V, Eq. 7.20
        %
        %   P_shp -- rated shaft power per engine [shp].
        %   _TODO -- does Eq. 7.20 include the propeller and
        %   gearbox? The extract does not say, and Part V is not in the repo.
            arguments
                P_shp (1,1) double {mustBePositive}
            end
            W = P_shp.^0.9306 .* 10.^-0.1205;
        end

        function W = engine_weight_brandt(T_AB_SLS)
            W = 0.199 * T_AB_SLS;
        end

    end

    methods (Static, Access = private)

        % ================================================================== %
        % TABLE 15.2 -- one two-index lookup covering all four components.
        % ================================================================== %

        function rho = lookup_component_density(aircraft_category, component, unit_system)
        %LOOKUP_COMPONENT_DENSITY_IMP  Structural surface density [lbf/ft^2].
        %   [Raymer 6th ed. Table 15.2; metabook_data.md:483-486]
        %
        %     rho = WeightsL2.lookup_component_density_imp("fighter", "wing")
        %         -> 9.0
        %
        %   aircraft_category -- canonical flag, or the printed column name.
        %   component         -- "wing" | "horizontal_tail" | "vertical_tail"
        %                        | "fuselage". Short forms ht/vt/fus accepted.
            arguments
                aircraft_category (1,1) string
                component         (1,1) string
                unit_system       (1,1) string
            end
            col = WeightsL2.to_tbl152_category(aircraft_category);
            row = WeightsL2.to_tbl152_component(component);
            r = WeightsL2.TBL152_COMPONENTS == row;
            c = WeightsL2.TBL152_CATEGORIES == col;
            switch lower(unit_system)
                case {"imperial", "imp", "english", "us"}
                    rho = WeightsL2.TBL152_DENSITY_IMP(r, c);
                case {"metric", "si"}
                    rho = WeightsL2.TBL152_DENSITY_SI(r, c);
                otherwise
                    error('WeightsL2:UnknownUnitSystem', ...
                          'unit_system must be "imperial" or "metric", got "%s".', ...
                          unit_system);
            end
        end

        function r = lookup_weight_ratio(aircraft_category, component, isNavy)
        %LOOKUP_WEIGHT_RATIO  Fraction-based weight ratio [--].
        %   [Raymer 6th ed. Table 15.2, the fraction sub-tables]
        %
        %     r = WeightsL2.lookup_weight_ratio("fighter", "landing gear")
        %       -> 0.033
        %
        %   aircraft_category -- canonical flag, or the printed column name.
        %   isNavy            -- pick the Navy column; defaults false. Only
        %                        landing_gear differs. FIGHTERS ONLY.
        %   component         -- "landing_gear" | "installed_engine"
        %                        | "all_else_empty". Spaces and short forms
        %                        accepted ("landing gear", "lg", "engine").
        %
        %   The rows carry DIFFERENT meanings -- see the WR_RATIOS comment.
        %   A NaN cell means the book prints no such value, and raises
        %   WeightsL2:UncitedCell rather than returning it.
            arguments
                aircraft_category (1,1) string
                component         (1,1) string
                isNavy            (1,1) logical = false
            end
                if isNavy
                if WeightsL2.to_wr_category(aircraft_category) ~= "fighter"
                    error('WeightsL2:UncitedCell', ...
                          ['Table 15.2 gives Navy values for fighters only; ' ...
                           '"%s" has none.'], aircraft_category);
                end
                aircraft_category = "navy_fighter";
            end
            col = WeightsL2.to_wr_category(aircraft_category);
            row = WeightsL2.to_wr_component(component);
            r = WeightsL2.WR_RATIOS( ...
                WeightsL2.WR_COMPONENTS == row, ...
                WeightsL2.WR_CATEGORIES == col);
            if isnan(r)
                error('WeightsL2:UncitedCell', ...
                      ['The fraction table has no "%s" value for category ' ...
                       '"%s". Supply a citation before adding one.'], row, col);
            end
        end

        function col = to_wr_category(aircraft_category)
        %TO_WR_CATEGORY  Canonical category -> a column of WR_CATEGORIES.
        %   navy_fighter stays DISTINCT from fighter: the book gives it its
        %   own landing-gear value.
            arguments
                aircraft_category (1,1) string
            end
            switch lower(aircraft_category)
                case {"navy_fighter", "navy fighter"}
                    col = "navy_fighter";
                case {"jet_fighter", "fighter", "fighters"}
                    col = "fighter";
                case {"jet_transport", "transport_jet", "jet_bomber", ...
                      "bomber", "military_cargo", "transport_bomber", ...
                      "transport", "transport/bomber"}
                    col = "transport_bomber";
                case {"general_aviation", "ga"}
                    col = "general_aviation";
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No fraction-table column for category "%s".', aircraft_category);
            end
        end

        function row = to_wr_component(component)
        %TO_WR_COMPONENT  Component name -> a row of WR_COMPONENTS.
            arguments
                component (1,1) string
            end
            switch lower(component)
                case {"landing_gear", "landing gear", "lg", "gear"}
                    row = "landing_gear";
                case {"installed_engine", "installed engine", "engine", ...
                      "inst_eng", "propulsion"}
                    row = "installed_engine";
                case {"all_else_empty", "all else empty", "all_else", ...
                      "all-else-empty", "systems"}
                    row = "all_else_empty";
                otherwise
                    error('WeightsL2:UnknownComponent', ...
                          'No fraction-table row for component "%s".', component);
            end
        end

        function col = to_tbl152_category(aircraft_category)
        %TO_TBL152_CATEGORY  Canonical category -> the column name Raymer prints.
        %   Raymer prints Fighters / Transport-Bomber / GA. Do NOT rename a
        %   column to match a key: the citation depends on the printed name.
        %   Same shape as AeroL1.to_CLmax_table_row. Table 15.2 has no Navy
        %   column, so a navy fighter takes the fighter column.
            arguments
                aircraft_category (1,1) string
            end
            switch lower(aircraft_category)
                case {"jet_fighter", "navy_fighter", "fighter"}
                    col = "fighter";
                case {"jet_transport", "transport_jet", "jet_bomber", ...
                      "bomber", "military_cargo", "transport_bomber"}
                    col = "transport_bomber";
                case {"general_aviation", "ga"}
                    col = "general_aviation";
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No Table 15.2 column for category "%s".', aircraft_category);
            end
        end

        function row = to_tbl152_component(component)
        %TO_TBL152_COMPONENT  Component name -> a row of TBL152_COMPONENTS.
            arguments
                component (1,1) string
            end
            switch lower(component)
                case {"wing", "w"}
                    row = "wing";
                case {"horizontal_tail", "htail", "ht", "h-tail"}
                    row = "horizontal_tail";
                case {"vertical_tail", "vtail", "vt", "v-tail"}
                    row = "vertical_tail";
                case {"fuselage", "fus", "body"}
                    row = "fuselage";
                otherwise
                    error('WeightsL2:UnknownComponent', ...
                          'No Table 15.2 row for component "%s".', component);
            end
        end


    end


end
