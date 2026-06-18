classdef AeroLevel1 < AerodynamicsBase
    % Level I aerodynamics: type-based lookup tables.
    %
    % Drag polar uses an equivalent skin friction coefficient (tabulated by
    % aircraft type) and the Raymer K_LD factor to estimate LD_max, from
    % which K2 is derived.  K1 = 0 (symmetric polar assumption at this
    % fidelity).
    %
    % Usage:
    %   Cf    = AeroLevel1.get_Cf('air force fighter', 1);
    %   K_LD  = AeroLevel1.tab_K_LD('jet fighter');
    %   aero  = AeroLevel1('fighter', Cf, K_LD, S_wet, S_ref, b);
    %   polar = aero.drag_polar(AircraftState(0, 0.9));

    properties
        aircraft_type   % normalized type string, used for CLmax table
        Cf              % equivalent skin friction coefficient (-)
        K_LD            % Raymer K_LD factor (-)
        S_wet           % total aircraft wetted area (ft²)
        S_ref           % wing reference area (ft²)
        b               % wingspan (ft)
    end

    properties (Constant)
        CLmax_table = AeroLevel1.build_CLmax_table()
        Delta_CD0   = AeroLevel1.build_DeltaCD0_table()
    end

    methods
        function obj = AeroLevel1(aircraft_type, Cf, K_LD, S_wet, S_ref, b)
            obj.aircraft_type = aircraft_type;
            obj.Cf  = Cf;
            obj.K_LD = K_LD;
            obj.S_wet = S_wet;
            obj.S_ref = S_ref;
            obj.b = b;
        end

        function polar = drag_polar(obj, state) %#ok<INUSD>
            CD0    = AeroLevel1.compute_CD0(obj.Cf, obj.S_wet, obj.S_ref);
            AR_wet = AeroLevel1.compute_AR_wetted(obj.b, obj.S_wet);
            LD_max = AeroLevel1.compute_LDmax(obj.K_LD, AR_wet);
            K2     = 1 / (4 * LD_max^2 * CD0);
            polar.CD0 = CD0;
            polar.K1  = 0;
            polar.K2  = K2;
        end

        function CL = CLmax(obj, state) %#ok<INUSD>
            CL = AeroLevel1.tab_CLmax_values(obj.aircraft_type, "clean");
        end
    end

    %% Static computation methods (kept for direct use and by subclasses)
    methods (Static)

        function CD = compute_CD(CD0, K, CL)
            CD = CD0 + K*CL^2;
        end

        function output = get_LDmax_cruise(LDmax, enginetype)
            if enginetype == "jet"
                output = 0.866*LDmax;
            elseif enginetype == "prop"
                output = LDmax;
            else
                error("engine type must be 'jet' or 'prop'.")
            end
        end

        function output = get_LDmax_loiter(LDmax, enginetype)
            if enginetype == "jet"
                output = LDmax;
            elseif enginetype == "prop"
                output = 0.866*LDmax;
            else
                error("engine type must be 'jet' or 'prop'.")
            end
        end

        function LD_max = compute_LDmax(K_LD, AR_wetted)
            LD_max = K_LD * sqrt(AR_wetted);  % Raymer, 6th ed, eq 3.12
        end

        function AR_wetted = compute_AR_wetted(b, S_wet)
            AR_wetted = b^2 / S_wet;  % Raymer, 6th ed, eq 3.11
        end

        function K_LD = tab_K_LD(design_type)
            % Raymer, 6th ed, page 40
            if design_type == "civil jet"
                K_LD = 15.5;
            elseif any(design_type == ["military jet", "Jet fighter", "jet fighter"])
                K_LD = 14;
            elseif design_type == "retractable prop"
                K_LD = 11;
            elseif design_type == "nonretractable prop"
                K_LD = 9;
            elseif design_type == "high-AR aircraft"
                K_LD = 13;
            elseif design_type == "sailplane"
                K_LD = 15;
            else
                error("Unrecognized design_type: %s", design_type)
            end
        end

        function equiv_AR = tabulate_equivAR(aircraft_type, engine_type, n_engines, LDbest, M_max)
            if any(aircraft_type == ["sailplane"]) || engine_type == "none"
                equiv_AR = 0.19*(LDbest^(1.3));
            elseif any(engine_type == ["propeller", "prop"])
                if aircraft_type == "homebuilt"
                    equiv_AR = 6.0;
                elseif aircraft_type == "general aviation"
                    if n_engines == 1;      equiv_AR = 7.6;
                    elseif n_engines == 2;  equiv_AR = 7.8;
                    else; warning("Table lacks entry for engine count. Setting equiv_AR=7.8."); equiv_AR = 7.8;
                    end
                elseif aircraft_type == "agricultural";  equiv_AR = 7.5;
                elseif aircraft_type == "turboprop"
                    if n_engines == 2;  equiv_AR = 9.2;
                    else; warning("No entry for engine count. Setting equiv_AR=9.2."); equiv_AR = 9.2;
                    end
                else
                    error("Unrecognized prop aircraft type: %s", aircraft_type)
                end
            elseif engine_type == "jet"
                if aircraft_type == "trainer"
                    a = 4.737; c = -0.979;
                elseif any(aircraft_type == ["fighter", "dogfighter"])
                    a = 5.416; c = -0.622;
                elseif any(aircraft_type == ["military cargo", "military bomber", "cargo", "bomber"])
                    a = 5.570; c = -1.075;
                elseif aircraft_type == "transport"
                    a = 8.75; c = 0;
                else
                    error("Unrecognized jet aircraft type: %s", aircraft_type)
                end
                equiv_AR = AeroLevel1.compute_equiv_AR_jet(a, c, M_max);
            else
                error("Unrecognized engine type: %s", engine_type)
            end
        end

        function equiv_AR = compute_equiv_AR_jet(a, c, M_max)
            equiv_AR = a * M_max^c;
        end

        function CD0 = compute_CD0(Cf, S_wet, S_ref)
            CD0 = Cf * S_wet / S_ref;
        end

        function Cf = get_Cf(aircraft_type, n_engines)
            % Raymer, Table 12.3, 6th edition
            if aircraft_type == "bomber"
                Cf = 0.0030;
            elseif aircraft_type == "civil transport"
                Cf = 0.0026;
            elseif aircraft_type == "military cargo"
                Cf = 0.0035;
            elseif aircraft_type == "air force fighter"
                Cf = 0.0035;
            elseif aircraft_type == "navy fighter"
                Cf = 0.0040;
            elseif aircraft_type == "supercruise aircraft"
                Cf = 0.0025;
            elseif aircraft_type == "light aircraft"
                if n_engines <= 1
                    Cf = 0.0055;
                elseif n_engines <= 2
                    Cf = 0.0045;
                else
                    warning("More engines than table expected. Setting Cf=0.0045.")
                    Cf = 0.0045;
                end
            elseif aircraft_type == "prop seaplane"
                Cf = 0.0065;
            elseif aircraft_type == "jet seaplane"
                Cf = 0.0040;
            else
                error("Unrecognized aircraft type for get_Cf: %s", aircraft_type)
            end
        end

        function output = tab_CLmax_values(aircrafttype, condition, rangeMode)
            if nargin < 2; condition = ""; end
            if nargin < 3; rangeMode = "mean"; end

            aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
            condition    = AeroLevel1.normalize_CL_condition(condition);
            rangeMode    = lower(strtrim(string(rangeMode)));

            CLTable = AeroLevel1.CLmax_table;
            idx     = CLTable.AircraftType == aircrafttype;
            if ~any(idx)
                error("Unrecognized aircraft type: %s", aircrafttype)
            end
            row  = CLTable(idx, :);
            data.aircrafttype  = row.AircraftType;
            data.CL_max_clean  = L1utils.resolve_range(row.CL_max_clean{1}, rangeMode);
            data.CL_max_TO     = L1utils.resolve_range(row.CL_max_TO{1},    rangeMode);
            data.CL_max_L      = L1utils.resolve_range(row.CL_max_L{1},     rangeMode);

            if condition == ""
                output = data; return
            end
            switch condition
                case "clean";   output = data.CL_max_clean;
                case "takeoff"; output = data.CL_max_TO;
                case "landing"; output = data.CL_max_L;
                otherwise;      error("Unrecognized CL condition: %s", condition)
            end
        end

    end

    methods (Static, Access = private)

        function T = build_CLmax_table()
            row = @(at, c, t, l) table(string(at), {c}, {t}, {l}, ...
                'VariableNames', {'AircraftType','CL_max_clean','CL_max_TO','CL_max_L'});
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
            elseif any(condition == ["clean","clmax","cl_max","cl_max_clean"])
                condition = "clean";
            elseif any(condition == ["to","takeoff","take_off","clmax_to","cl_max_to","cl_max_takeoff"])
                condition = "takeoff";
            elseif any(condition == ["l","land","landing","clmax_l","cl_max_l","cl_max_landing"])
                condition = "landing";
            end
        end

        function output = build_DeltaCD0_table()
            row = @(fc, d, e) table(string(fc), {d}, {e}, ...
                'VariableNames', {'flap config','Delta CD0','e Oswald'});
            output = [
                row("Clean",          [0 0],         [0.80 0.85])
                row("Take-Off Flaps", [0.010 0.020], [0.75 0.80])
                row("Landing Flaps",  [0.055 0.075], [0.70 0.75])
                row("Landing Gear",   [0.015 0.025], NaN)
                ];
        end

    end

end
