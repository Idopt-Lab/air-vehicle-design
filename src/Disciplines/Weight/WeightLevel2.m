classdef WeightLevel2 < WeightsBase
    % Level II weights: Raymer gross-weight empty-weight fraction (Table 6.1 with
    % correction factors AR, T/W, W/S, Mach).
    %
    % OEW = W_TO * (a + b * W_TO^c1 * AR^c2 * (T/W)^c3 * (W/S)^c4 * M^c5) * K_vs
    %
    % Usage:
    %   wts = WeightLevel2('jet fighter', AR, T_W, W_S, M_max, K_vs);
    %   oew = wts.OEW(31000);

    properties
        aircraft_type
        AR      % wing aspect ratio
        T_W     % thrust-to-weight ratio at design point
        W_S     % wing loading at design point (lbf/ft²)
        M_max   % maximum Mach number
        K_vs    % variable-sweep penalty factor (1.0 for fixed)
    end

    methods
        function obj = WeightLevel2(aircraft_type, AR, T_W, W_S, M_max, K_vs)
            if nargin < 6; K_vs = 1.0; end
            obj.aircraft_type = aircraft_type;
            obj.AR    = AR;
            obj.T_W   = T_W;
            obj.W_S   = W_S;
            obj.M_max = M_max;
            obj.K_vs  = K_vs;
        end

        function oew = OEW(obj, W_TO)
            oew = WeightLevel2.get_OEW(obj.aircraft_type, W_TO, W_TO, ...
                obj.AR, obj.T_W*W_TO, obj.W_S, obj.M_max, obj.K_vs);
        end
    end

    methods (Static)

        function OEW = get_OEW(aircraft_type, W_TO, W0, AR, T, S_ref, M_max, K_vs)
            switch aircraft_type
                case "jet trainer"
                    a=0; b=4.28; c1=-0.10; c2=0.10; c3=0.20; c4=-0.24; c5=0.11;
                case "jet fighter"
                    a=-0.02; b=2.16; c1=-0.10; c2=0.20; c3=0.04; c4=-0.10; c5=0.08;
                case {"military cargo","military bomber"}
                    a=0.07; b=1.71; c1=-0.10; c2=0.10; c3=0.06; c4=-0.10; c5=0.05;
                case "jet transport"
                    a=0.32; b=0.66; c1=-0.13; c2=0.30; c3=0.06; c4=-0.05; c5=0.05;
                case "sailplane - unpowered"
                    a=0; b=0.76; c1=-0.05; c2=0.14; c3=0; c4=-0.30; c5=0.06;
                case "sailplane - powered"
                    a=0; b=1.21; c1=-0.04; c2=0.14; c3=0.19; c4=-0.20; c5=0.05;
                case {"homebuilt - metal","homebuilt - wood"}
                    a=0; b=0.71; c1=-0.10; c2=0.05; c3=0.10; c4=-0.05; c5=0.17;
                case "homebuilt - composite"
                    a=0; b=0.69; c1=-0.10; c2=0.05; c3=0.10; c4=-0.05; c5=0.17;
                case "general aviation - single engine"
                    a=-0.25; b=1.18; c1=-0.20; c2=0.08; c3=0.05; c4=-0.05; c5=0.27;
                case "general aviation - twin engine"
                    a=-0.90; b=1.36; c1=-0.10; c2=0.08; c3=0.05; c4=-0.05; c5=0.20;
                case "agricultural aircraft"
                    a=0; b=1.67; c1=-0.14; c2=0.07; c3=0.10; c4=-0.10; c5=0.11;
                case "twin turboprop"
                    a=0.37; b=0.09; c1=-0.06; c2=0.08; c3=0.08; c4=-0.05; c5=0.30;
                case "flying boat"
                    a=0; b=0.42; c1=-0.01; c2=0.10; c3=0.05; c4=-0.12; c5=0.18;
                otherwise
                    error("Unrecognized aircraft type for WeightLevel2: %s", aircraft_type)
            end
            OEW = W_TO * (a + b*W0^c1 * AR^c2 * (T/W0)^c3 * (W0/S_ref)^c4 * M_max^c5) * K_vs;
        end

        function W_wing = estimate_mainwing_weight(aircraft_type, S_exposed_planform)
            switch aircraft_type
                case "fighter";                     W_wing = 9   * S_exposed_planform;
                case {"transport","bomber"};         W_wing = 10  * S_exposed_planform;
                case "general aviation";             W_wing = 2.5 * S_exposed_planform;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function W_ht = estimate_HT_weight(aircraft_type, S_exposed_planform)
            switch aircraft_type
                case "fighter";              W_ht = 4   * S_exposed_planform;
                case {"transport","bomber"}; W_ht = 5.5 * S_exposed_planform;
                case "general aviation";     W_ht = 2   * S_exposed_planform;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function W_vt = estimate_VT_weight(aircraft_type, S_exposed_planform)
            switch aircraft_type
                case "fighter";              W_vt = 5.3 * S_exposed_planform;
                case {"transport","bomber"}; W_vt = 5.5 * S_exposed_planform;
                case "general aviation";     W_vt = 2   * S_exposed_planform;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function W_fus = estimate_fuselage_weight(aircraft_type, S_exposed_planform)
            switch aircraft_type
                case "fighter";              W_fus = 4.8 * S_exposed_planform;
                case {"transport","bomber"}; W_fus = 5   * S_exposed_planform;
                case "general aviation";     W_fus = 1.4 * S_exposed_planform;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function W_lg = estimate_landinggear_weight(aircraft_type, isnavy, W_TO)
            switch aircraft_type
                case "fighter"
                    if isnavy; W_lg = 0.045*W_TO; else; W_lg = 0.033*W_TO; end
                case {"transport","bomber"};  W_lg = 0.043*W_TO;
                case "general aviation";      W_lg = 0.057*W_TO;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function W_eng = estimate_W_eng_installed(aircraft_type, engine_weight)
            switch aircraft_type
                case {"fighter","transport","bomber"}; W_eng = 1.3 * engine_weight;
                case "general aviation";               W_eng = 1.4 * engine_weight;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function W_ae = estimate_allelseempty_weight(aircraft_type, W_TO)
            switch aircraft_type
                case {"fighter","transport","bomber"}; W_ae = 0.17 * W_TO;
                case "general aviation";               W_ae = 0.10 * W_TO;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

    end

end
