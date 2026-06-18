classdef WeightLevel1 < WeightsBase
    % Level I weights: historical empty-weight regression (Raymer Table 6.1).
    %
    % OEW = a * W_TO^c, where a and c are tabulated by aircraft type.
    % Also supports Roskam's regression (Table 2.15) via tab_emptyweight.
    %
    % Usage:
    %   wts   = WeightLevel1('jet fighter');
    %   oew   = wts.OEW(31000);

    properties
        aircraft_type   % design type string for Raymer Table 6.1
    end

    properties (Constant)
        aircraftTypes = [
            "homebuilt"; "homebuilt"; "homebuilt";
            "single_engine_propeller";
            "twin_engine_propeller"; "twin_engine_propeller";
            "agricultural"; "business_jet"; "regional_tbp"; "transport_jet";
            "military_trainer"; "military_trainer"; "military_trainer"; "military_trainer";
            "fighter"; "fighter"; "fighter";
            "mil_patrol_bomb_transport"; "mil_patrol_bomb_transport";
            "flying_boat_amphibious_float"; "supersonic_cruise";
            ]

        subtypes = [
            "personal_fun_transportation"; "scaled_fighter"; "composite";
            "default";
            "default"; "composite";
            "default"; "default"; "default"; "default";
            "jet"; "turboprop"; "turboprop_without_number_2"; "piston_prop";
            "jet_external_load"; "jet_clean"; "turboprop_external_load";
            "jet"; "turboprop";
            "default"; "default";
            ]

        A_values = [
            0.3411; 0.5542; 0.8222;
            -0.1440;
            0.0966; 0.1130;
            -0.4398; 0.2678; 0.3774; 0.0833;
            0.6632; -1.4041; 0.1677; 0.5627;
            0.5091; 0.1362; 0.2705;
            -0.2009; -0.4179;
            0.1703; 0.4221;
            ]

        B_values = [
            0.9519; 0.8654; 0.8050;
            1.1162;
            1.0298; 1.0403;
            1.1946; 0.9979; 0.9647; 1.0383;
            0.8640; 1.4660; 0.9978; 0.8761;
            0.9505; 1.0116; 0.9830;
            1.1037; 1.1446;
            1.0083; 0.9876;
            ]
    end

    methods
        function obj = WeightLevel1(aircraft_type)
            obj.aircraft_type = aircraft_type;
        end

        function oew = OEW(obj, W_TO)
            [oew, ~] = WeightLevel1.get_OEW(obj.aircraft_type, W_TO);
        end
    end

    methods (Static)

        function [OEW, OEW_frac] = get_OEW(design_type, W_TO)
            % Raymer, 6th ed, Table 6.1: W_e/W_0 = a * W_0^c
            switch design_type
                case {"sailplane - unpowered"};                   a = 0.86;  c = -0.05;
                case {"sailplane - powered"};                     a = 0.91;  c = -0.05;
                case {"homebuilt - metal","homebuilt - wood"};    a = 1.19;  c = -0.09;
                case "homebuilt - composite";                     a = 1.15;  c = -0.09;
                case "general aviation - single engine";          a = 2.36;  c = -0.18;
                case "general aviation twin engine";              a = 1.51;  c = -0.10;
                case "agricultural aircraft";                     a = 0.74;  c = -0.03;
                case "twin turboprop";                            a = 0.96;  c = -0.05;
                case "flying boat";                               a = 1.09;  c = -0.05;
                case "jet trainer";                               a = 1.59;  c = -0.10;
                case {"jet fighter","Jet fighter"};               a = 2.34;  c = -0.13;
                case {"military cargo","military bomber"};        a = 0.93;  c = -0.07;
                case "jet transport";                             a = 1.02;  c = -0.06;
                case {"UAV","Tac Recce","UCAV"};                 a = 1.67;  c = -0.16;
                case "UAV - high altitude";                       a = 2.75;  c = -0.18;
                case "UAV - small";                               a = 0.97;  c = -0.06;
                otherwise
                    error("Unrecognized design type: %s", design_type)
            end
            OEW_frac = a * W_TO^c;
            OEW      = OEW_frac * W_TO;
        end

        function output = tab_emptyweight(aircrafttype, subtype, W_TO)
            % Roskam, Airplane Design Part I, Table 2.15
            % W_E = 10^((log10(W_TO) - A)/B)
            if nargin < 2; subtype = ""; end
            if nargin < 3; W_TO = NaN; end

            aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
            subtype      = WeightLevel1.normalize_emptyweight_subtype(subtype);
            if subtype == ""
                subtype = WeightLevel1.default_emptyweight_subtype(aircrafttype);
            end

            T = table(WeightLevel1.aircraftTypes, WeightLevel1.subtypes, ...
                WeightLevel1.A_values, WeightLevel1.B_values, ...
                'VariableNames', {'AircraftType','Subtype','A','B'});
            idx = T.AircraftType == aircrafttype & T.Subtype == subtype;
            if ~any(idx)
                available = T.Subtype(T.AircraftType == aircrafttype);
                if isempty(available)
                    error("Unrecognized aircraft type: %s", aircrafttype)
                else
                    error("Unrecognized subtype '%s' for '%s'. Available: %s", ...
                        subtype, aircrafttype, strjoin(available, ", "))
                end
            end

            output.aircrafttype = aircrafttype;
            output.subtype = subtype;
            output.A = T.A(idx);
            output.B = T.B(idx);
            if ~isnan(W_TO)
                output.W_E = 10^((log10(W_TO) - output.A) / output.B);
            end
        end

    end

    methods (Static, Access = private)

        function subtype = default_emptyweight_subtype(aircrafttype)
            switch aircrafttype
                case "homebuilt";                   subtype = "personal_fun_transportation";
                case "fighter";                     subtype = "jet_external_load";
                case "military_trainer";            subtype = "jet";
                case "mil_patrol_bomb_transport";   subtype = "jet";
                otherwise;                          subtype = "default";
            end
        end

        function subtype = normalize_emptyweight_subtype(subtype)
            subtype = lower(strtrim(string(subtype)));
            subtype = replace(subtype, {"-","+"," ","/",".",","}, "_");
            if any(subtype == ["","default"]);                               subtype = "";
            elseif any(subtype == ["personal","personal_fun","personal_fun_transportation"]); subtype = "personal_fun_transportation";
            elseif any(subtype == ["scaled_fighter","scaled_fighters"]);     subtype = "scaled_fighter";
            elseif any(subtype == ["composite","composites"]);               subtype = "composite";
            elseif any(subtype == ["jet","jets"]);                           subtype = "jet";
            elseif any(subtype == ["turboprop","turboprops"]);               subtype = "turboprop";
            elseif any(subtype == ["piston_prop","piston_props"]);           subtype = "piston_prop";
            elseif any(subtype == ["jet_external_load","external_load"]);    subtype = "jet_external_load";
            elseif any(subtype == ["jet_clean","clean"]);                    subtype = "jet_clean";
            elseif any(subtype == ["turboprop_external_load"]);              subtype = "turboprop_external_load";
            end
        end

    end

end
