classdef AeroL1
%AEROL1  Level-1 aerodynamics static toolbox: aircraft type only, no geometry.
%
%   Call as AeroL1.method(...); never instantiated, not in the inheritance
%   chain. F16AeroL1 inherits AeroModelL1 and delegates to these statics.
%
%   Two tiers: high-level statics take the concrete object; low-level statics
%   take only scalars and arrays.
%
%   Drag polar: [Mattingly 2nd ed. Eq. 2.9], with CD0(M) and K1(M) interpolated
%   from the fighter "Current" type-curves [Mattingly 2nd ed. Fig. 2.10, 2.11]
%   and K2 = 0 for an uncambered fighter [Mattingly 2nd ed. Sec. 2.3.1].
%   CLmax and the high-lift increments: [Roskam Vol. I Table 3.1, Table 3.6].
%
%   TODO: Mattingly Fig. 2.10/2.11 are not in this repo. The curve blocks in
%   f16a_L1.json are seeded from 5 AAF worked-example points and marked
%   _placeholder. Guarded by TestAeroL1.testTODO_MattinglyCurvesArePlaceholder.
%
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
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Assemble the Mattingly type-curve drag polar.
        %   Returns struct(CD0, K1, K2). CD0(M)/K1(M) are interpolated from the
        %   student object's Mattingly Fig. 2.10/2.11 "Current" curve tables;
        %   K2 = 0 for the fighter/uncambered type.  Mattingly AED Eq. 2.9.
            polar = AeroL1.mattingly_polar(obj.cd0_curve_mach, obj.cd0_curve_value, ...
                                           obj.k1_curve_mach,  obj.k1_curve_value, ...
                                           state.mach, obj.design_type);
        end

        function CLmax = get_CLmax(obj)
            CLmax = AeroL1.roskam_CLmax_value(obj.aircraft_category, "CL_max_clean");
        end

        % ================================================================== %
        % LOW-LEVEL: pure math -- scalars/arrays only, no object access.
        % ================================================================== %

        function polar = mattingly_polar(cd0_mach, cd0_value, k1_mach, k1_value, M, design_type)
        %MATTINGLY_POLAR  {CD0(M), K1(M), K2} from the Mattingly Fig. 2.10/2.11
        %   curves.  Mattingly AED 2nd ed. Eq. 2.9 (fighter K2=0, Sec. 2.3.1).
        %   cd0_mach/cd0_value, k1_mach/k1_value -- the "Current" curve (mach,
        %   value) breakpoint vectors. M -- flight Mach. design_type -- airfoil
        %   camber class ("uncambered" -> K2=0).
            cd0 = AeroL1.interp_curve(cd0_mach, cd0_value, M);
            k1  = AeroL1.interp_curve(k1_mach,  k1_value,  M);
            k2  = AeroL1.mattingly_K2(design_type);
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
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
            arguments
                aircraft_category (1,1) string
            end
            switch aircraft_category
                case {"jet_fighter", "fighter"}
                    rowName = "fighter";          % Roskam Vol. I Table 3.1's own name
                otherwise
                    rowName = aircraft_category;  % pass through; the caller validates
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

        function CLmax = lookup_CLmax(aircraft_type)
            switch string(aircraft_type)
                case {"fighter", "jet_fighter"}, CLmax = 0.90;
                case "military_cargo",           CLmax = 1.20;
                case "transport_jet",            CLmax = 1.30;
                case "business_jet",             CLmax = 1.10;
                case "general_aviation_single",  CLmax = 1.30;
                case "general_aviation_twin",    CLmax = 1.20;
                case "sailplane",                CLmax = 1.40;
                otherwise
                    error('AeroL1:unknownCategory', ...
                        'Unknown aircraft_type "%s". Add it to AeroL1.lookup_CLmax.', ...
                        aircraft_type);
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
