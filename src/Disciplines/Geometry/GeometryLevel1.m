classdef GeometryLevel1 < GeometryBase
    % Level I geometry: Roskam historical regression for S_wet and L_fus.
    %
    % S_ref is set by the sizing loop (W_TO/W_S) or supplied as an input.
    % S_wet is estimated from Roskam Table 3.5: S_wet = 10^c * W_TO^d.
    % L_fus is estimated from Roskam Table 3.3: L_fus = a * W_TO^C.
    %
    % Usage (standalone):
    %   geom = GeometryLevel1('jet fighter', 31000, 300);
    %   geom.S_wet   % total wetted area (ft²)

    properties
        aircraft_type   % type string for S_wet and L_fus regressions
        L_fus           % fuselage length (ft) — from regression
    end

    methods
        function obj = GeometryLevel1(aircraft_type, W_TO, S_ref_in)
            obj.aircraft_type = aircraft_type;
            obj.S_ref = S_ref_in;
            [obj.S_wet, ~, ~]  = GeometryLevel1.get_design_S_wet(aircraft_type, W_TO);
            [obj.L_fus, ~, ~]  = GeometryLevel1.get_fus_len(aircraft_type, W_TO);
        end
    end

    methods (Static)

        function [L_fuselage, a, c] = get_fus_len(aircraft_type, W_TO)
            % Roskam, Airplane Design Vol 1, Table 3.3
            switch aircraft_type
                case "sailplane - unpowered";                   a=0.86; c=0.48;
                case "sailplane - powered";                     a=0.71; c=0.48;
                case {"homebuilt - metal","homebuilt - wood"};  a=3.68; c=0.23;
                case "homebuilt - composite";                   a=3.50; c=0.23;
                case "general aviation - single engine";        a=4.37; c=0.23;
                case "general aviation - twin engine";          a=0.86; c=0.42;
                case "agricultural aircraft";                   a=4.04; c=0.23;
                case "twin turboprop";                          a=0.37; c=0.51;
                case "flying boat";                             a=1.05; c=0.40;
                case "jet trainer";                             a=0.79; c=0.41;
                case {"Jet fighter","jet fighter"};             a=0.93; c=0.39;
                case {"military cargo","military bomber"};      a=0.23; c=0.50;
                case "jet transport";                           a=0.67; c=0.43;
                otherwise
                    error("Unrecognized aircraft type for get_fus_len: %s", aircraft_type)
            end
            L_fuselage = GeometryLevel1.compute_fus_len(a, c, W_TO);
        end

        function output = compute_fus_len(a, C, W_TO)
            output = a * W_TO^C;  % Raymer, 6th ed, Table 6.3
        end

        function S_ref = compute_wing_area(W_TO, WS_desired)
            S_ref = W_TO / WS_desired;
        end

        function [S_wet, c, d] = get_design_S_wet(aircraft_type, W_TO)
            % Roskam, Airplane Design Vol 1, Table 3.5
            % S_wet = 10^c * W_TO^d  (ft²)
            switch aircraft_type
                case "homebuilt";                   c=1.2362;  d=0.4319;
                case "single engine prop";          c=1.0892;  d=0.5147;
                case "twin engine prop";            c=0.8635;  d=0.5632;
                case "agricultural";                c=1.0447;  d=0.5326;
                case "business jet";                c=0.2263;  d=0.6977;
                case "regional turboprop";          c=-0.0866; d=0.8099;
                case "transport jet";               c=0.0199;  d=0.7351;
                case "military trainer";            c=0.8565;  d=0.5423;
                case {"jet fighter","Jet fighter"}; c=-0.1289; d=0.7506;
                case {"military patrol","military bomber","military transport"}; c=0.1628; d=0.7316;
                case {"flying boat","amphibious","float"}; c=0.6295; d=0.6708;
                case "supersonic cruise";           c=-1.1868; d=0.9609;
                otherwise
                    error("Unrecognized aircraft type for get_design_S_wet: %s", aircraft_type)
            end
            S_wet = 10^c * W_TO^d;
        end

    end

end
