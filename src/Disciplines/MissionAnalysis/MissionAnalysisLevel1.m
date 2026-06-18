classdef MissionAnalysisLevel1 < MissionBase
    % Level I mission analysis: Roskam fuel fractions + tabulated LD and TSFC.
    %
    % compute_fuel does NOT call aero.drag_polar or prop.TSFC — it uses only
    % Roskam's Table 2.1 (fuel fractions) and Table 2.2 (cruise/loiter LD and
    % TSFC) tabulated by aircraft type.
    %
    % req struct required fields:
    %   req.aircraft_type  — normalized string, e.g., 'fighter'
    %   req.engine_type    — 'jet' or 'prop' (for LD_cruise/loiter correction)
    %   req.S_ref          — wing reference area (ft²)
    %   req.segments       — array of structs, each with:
    %     .name       — 'startup','taxi','takeoff','climb','cruise','dash',
    %                   'combat','loiter','descent','landing'
    %     .altitude_ft — segment altitude (for AircraftState)
    %     .mach        — segment Mach number
    %     .range_ft    — segment range (ft), for cruise/dash
    %     .time_min    — segment time (min), for loiter/combat
    %     .W_drop      — weight released at end of segment (lbf), for combat
    %
    % A 6% trapped-fuel reserve is added to the computed mission fuel.

    properties
        aircraft_type   % Roskam normalized type string
        engine_type     % 'jet' or 'prop' for LD correction
    end

    properties (Constant)
        aircraftTypes = [
            "homebuilt"; "single_engine"; "twin_engine"; "agricultural";
            "business_jet"; "regional_tbp"; "transport_jet"; "military_trainer";
            "fighter"; "mil_patrol_bomb_transport"; "flying_boat_amphibious_float";
            "supersonic_cruise";
            ]

        segmentNames = [
            "engine_start_warmup"; "taxi"; "takeoff"; "climb";
            "descent"; "landing_taxi_shutdown";
            ]

        fuelFractions = {
            0.998, 0.998, 0.998, 0.995, 0.995, 0.995;
            0.995, 0.997, 0.998, 0.992, 0.993, 0.993;
            0.992, 0.996, 0.996, 0.990, 0.992, 0.992;
            0.996, 0.995, 0.996, 0.998, 0.999, 0.998;
            0.990, 0.995, 0.995, 0.980, 0.990, 0.992;
            0.990, 0.995, 0.995, 0.985, 0.985, 0.995;
            0.990, 0.990, 0.995, 0.980, 0.990, 0.992;
            0.990, 0.990, 0.990, 0.980, 0.990, 0.995;
            0.990, 0.990, 0.990, [0.90 0.96], 0.990, 0.995;
            0.990, 0.990, 0.995, 0.980, 0.990, 0.992;
            0.992, 0.990, 0.996, 0.985, 0.990, 0.990;
            0.990, 0.995, 0.995, [0.87 0.92], 0.985, 0.992;
            }

        cruise_LD = {[8 10]; [8 10]; [8 10]; [5 7]; [10 12]; [11 13];
            [13 15]; [8 10]; [4 7]; [13 15]; [10 12]; [4 6]}

        cruise_cj = {NaN; NaN; NaN; NaN; [0.5 0.9]; NaN; [0.5 0.9];
            [0.5 1.0]; [0.6 1.4]; [0.5 0.9]; [0.5 0.9]; [0.7 1.5]}

        loiter_LD = {[10 12]; [10 12]; [9 11]; [8 10]; [12 14]; [14 16];
            [14 18]; [10 14]; [6 9]; [14 18]; [13 15]; [7 9]}

        loiter_cj = {NaN; NaN; NaN; NaN; [0.4 0.6]; NaN; [0.4 0.6];
            [0.4 0.6]; [0.6 0.8]; [0.4 0.6]; [0.4 0.6]; [0.6 0.8]}
    end

    methods
        function obj = MissionAnalysisLevel1(aircraft_type, engine_type)
            obj.aircraft_type = L1utils.normalize_aircraft_type(aircraft_type);
            if nargin < 2; engine_type = "jet"; end
            obj.engine_type = engine_type;
        end

        function fuel = compute_fuel(obj, aero, prop, W_TO, req) %#ok<INUSL>
            W          = W_TO;
            total_fuel = 0;

            row = find(MissionAnalysisLevel1.aircraftTypes == obj.aircraft_type, 1);
            if isempty(row)
                error("Aircraft type '%s' not found in fuel-fraction table.", obj.aircraft_type)
            end

            % Roskam Table 2.2: (L/D)_max values; segment methods apply 0.866 cruise correction.
            LD_cruise = L1utils.resolve_range(MissionAnalysisLevel1.cruise_LD{row}, "mean");
            cj_cr     = L1utils.resolve_range(MissionAnalysisLevel1.cruise_cj{row}, "mean");
            LD_loiter = L1utils.resolve_range(MissionAnalysisLevel1.loiter_LD{row}, "mean");
            cj_lt     = L1utils.resolve_range(MissionAnalysisLevel1.loiter_cj{row}, "mean");
            TSFC_cr   = cj_cr / 3600;  % lb/lb/hr → 1/s
            TSFC_lt   = cj_lt / 3600;

            for i = 1:numel(req.segments)
                seg = req.segments(i);
                switch seg.name
                    case 'startup'
                        WF = L1utils.resolve_range(MissionAnalysisLevel1.fuelFractions{row, 1}, "mean");
                        fuel_seg = (1-WF)*W; W = W - fuel_seg;
                    case 'taxi'
                        WF = L1utils.resolve_range(MissionAnalysisLevel1.fuelFractions{row, 2}, "mean");
                        fuel_seg = (1-WF)*W; W = W - fuel_seg;
                    case 'takeoff'
                        WF = L1utils.resolve_range(MissionAnalysisLevel1.fuelFractions{row, 3}, "mean");
                        fuel_seg = (1-WF)*W; W = W - fuel_seg;
                    case 'climb'
                        [W, fuel_seg] = MissionAnalysisLevel1.segment_climb(W, seg.mach);
                    case {'cruise','dash'}
                        state    = AircraftState(seg.altitude_ft, seg.mach);
                        [W, fuel_seg] = MissionAnalysisLevel1.segment_cruise(W, TSFC_cr, seg.range_ft, state.mach, state.a, LD_cruise);
                    case 'loiter'
                        [W, fuel_seg] = MissionAnalysisLevel1.segment_loiter(W, seg.time_min, TSFC_lt, LD_loiter);
                    case 'combat'
                        W_drop   = 0; if isfield(seg,'W_drop'); W_drop = seg.W_drop; end
                        [W, fuel_seg] = MissionAnalysisLevel1.segment_combat(W, seg.time_min, TSFC_cr, W_drop, LD_cruise);
                    case 'descent'
                        WF = L1utils.resolve_range(MissionAnalysisLevel1.fuelFractions{row, 5}, "mean");
                        fuel_seg = (1-WF)*W; W = W - fuel_seg;
                    case 'landing'
                        [W, fuel_seg] = MissionAnalysisLevel1.segment_landing(W);
                    otherwise
                        fuel_seg = 0;
                end
                total_fuel = total_fuel + fuel_seg;
            end
            fuel = total_fuel * 1.06;  % 6% trapped-fuel reserve
        end
    end

    methods (Static)

        function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
            WF = exp(-(R*TSFC) / (Vend*LD_ratio));
        end

        function [LD_ratio] = compute_LD_ratio(segment_name, LD)
            if any(segment_name == ["cruise","combat","dash"])
                LD_ratio = LD*0.866;
            elseif segment_name == "loiter"
                LD_ratio = LD;
            else
                error("segment_name must be cruise, combat, dash, or loiter.")
            end
        end

        function [W_out, fuel_used] = segment_climb(W_in, Mach)
            WF_Climb  = 1.0065 - 0.0325*Mach;
            fuel_used = (1-WF_Climb)*W_in;
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, LD)
            LD_combat = MissionAnalysisLevel1.compute_LD_ratio("combat", LD);
            WF        = exp(-(time*60*TSFC / LD_combat));
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used - payload;
        end

        function [W_out, fuel_used] = segment_cruise(W_in, TSFC, Distance, Mach, a, LD)
            V         = Mach*a;
            LD_cr     = MissionAnalysisLevel1.compute_LD_ratio("cruise", LD);
            WF        = MissionAnalysisLevel1.compute_weightfraction(TSFC, Distance, V, LD_cr);
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_dash(W_in, TSFC, Distance, V, LD)
            LD_dash   = MissionAnalysisLevel1.compute_LD_ratio("dash", LD);
            WF        = MissionAnalysisLevel1.compute_weightfraction(TSFC, Distance, V, LD_dash);
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_landing(W_in)
            WF        = 0.995;
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_loiter(W_in, time, TSFC, LD)
            LD_loiter = MissionAnalysisLevel1.compute_LD_ratio("loiter", LD);
            WF        = exp(-(time*60*TSFC / LD_loiter));
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_takeoff(W_in)
            WF        = 0.95;
            W_out     = W_in*WF;
            fuel_used = W_in - W_out;
        end

        function output = tab_fuelfraction(aircrafttype, segment)
            if nargin < 2; segment = ""; end
            rangeMode    = "mean";
            aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
            segment      = MissionAnalysisLevel1.normalize_segment(segment);
            row = find(MissionAnalysisLevel1.aircraftTypes == aircrafttype, 1);
            if isempty(row)
                error("Unrecognized aircraft type: %s", aircrafttype)
            end
            if segment == ""
                output = struct();
                names  = MissionAnalysisLevel1.segmentNames;
                for j = 1:numel(names)
                    output.(names(j)) = L1utils.resolve_range(MissionAnalysisLevel1.fuelFractions{row,j}, rangeMode);
                end
                return
            end
            col = find(MissionAnalysisLevel1.segmentNames == segment, 1);
            if isempty(col)
                error("Unrecognized segment: %s", segment)
            end
            output = L1utils.resolve_range(MissionAnalysisLevel1.fuelFractions{row,col}, rangeMode);
        end

        function output = tab_missionphase_values(aircrafttype, phase, quantity)
            if nargin < 2; phase = ""; end
            if nargin < 3; quantity = ""; end
            rangeMode    = "mean";
            aircrafttype = L1utils.normalize_aircraft_type(aircrafttype);
            phase        = MissionAnalysisLevel1.normalize_phase(phase);
            quantity     = MissionAnalysisLevel1.normalize_quantity(quantity);
            row = find(MissionAnalysisLevel1.aircraftTypes == aircrafttype, 1);
            if isempty(row)
                error("Unrecognized aircraft type: %s", aircrafttype)
            end
            data.cruise.LD = L1utils.resolve_range(MissionAnalysisLevel1.cruise_LD{row}, rangeMode);
            data.cruise.cj = L1utils.resolve_range(MissionAnalysisLevel1.cruise_cj{row}, rangeMode);
            data.loiter.LD = L1utils.resolve_range(MissionAnalysisLevel1.loiter_LD{row}, rangeMode);
            data.loiter.cj = L1utils.resolve_range(MissionAnalysisLevel1.loiter_cj{row}, rangeMode);
            if phase == ""; output = data; return; end
            if quantity == ""; output = data.(char(phase)); return; end
            output = data.(char(phase)).(char(quantity));
        end

    end

    methods (Static, Access = private)

        function phase = normalize_phase(phase)
            phase = lower(strtrim(string(phase)));
            phase = regexprep(phase, '[-  ]', '_');
            if any(phase == ["cr","cruise"]); phase = "cruise";
            elseif any(phase == ["ltr","loiter"]); phase = "loiter";
            end
        end

        function quantity = normalize_quantity(quantity)
            quantity = lower(strtrim(string(quantity)));
            quantity = regexprep(quantity, '[-/ ]', '_');
            if any(quantity == ["ld","l_d","lift_drag","lift_to_drag"]); quantity = "LD";
            elseif any(quantity == ["cj","c_j","jet_tsfc"]); quantity = "cj";
            end
        end

        function segment = normalize_segment(segment)
            segment = lower(strtrim(string(segment)));
            segment = regexprep(segment, '[-/ ]', '_');
            if any(segment == ["engine_start","start","startup","warmup","warm_up"]); segment = "engine_start_warmup";
            elseif segment == "take_off"; segment = "takeoff";
            elseif any(segment == ["landing","shutdown","landing_taxi_and_shutdown"]); segment = "landing_taxi_shutdown";
            end
        end

    end

end
