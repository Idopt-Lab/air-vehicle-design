classdef MissionAnalysisLevel2 < MissionBase
    % Level II mission analysis: segment-by-segment Breguet using aero/prop objects.
    %
    % compute_fuel calls aero.drag_polar(state) and prop.TSFC(state) for the
    % mission-relevant flight condition in each segment.  Cruise and dash use
    % a single-point Breguet evaluation.
    %
    % req struct required fields (same as MissionAnalysisLevel1):
    %   req.aircraft_type, req.S_ref, req.segments(i).{name, altitude_ft,
    %   mach, range_ft, time_min, W_drop}

    properties
        % no stored configuration beyond what's in req
    end

    methods
        function obj = MissionAnalysisLevel2()
            % No configuration at construction; aero/prop passed to compute_fuel.
        end

        function fuel = compute_fuel(obj, aero, prop, W_TO, req) %#ok<INUSL>
            W          = W_TO;
            S_ref      = req.S_ref;
            total_fuel = 0;

            for i = 1:numel(req.segments)
                seg   = req.segments(i);
                state = AircraftState(seg.altitude_ft, seg.mach);
                polar = aero.drag_polar(state);
                CD0   = polar.CD0;
                K2    = polar.K2;
                e_osw = 1/(pi * req.AR * K2);  % back-compute e
                tsfc  = prop.TSFC(state);

                switch seg.name
                    case 'startup'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_startup(W);
                    case 'taxi'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_taxi(W);
                    case 'takeoff'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_takeoff(W);
                    case 'climb'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_climb(W_TO, W, state.mach, S_ref, CD0, e_osw, req.AR, tsfc, seg.altitude_ft, prop.T0);
                    case 'cruise'
                        W_S = W / S_ref;
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_cruise(W, W_S, tsfc, seg.range_ft, state.mach, state.a, state.q, CD0, e_osw, req.AR, W_TO, S_ref);
                    case 'dash'
                        W_S = W / S_ref;
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_dash(W, W_S, W_TO, state.q, CD0, e_osw, req.AR, tsfc, seg.range_ft, state.V);
                    case 'combat'
                        W_drop = 0; if isfield(seg,'W_drop'); W_drop = seg.W_drop; end
                        W_S = W / S_ref;
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_combat(W, seg.time_min, tsfc, W_drop, CD0, e_osw, req.AR, W_TO, state.q, W_S);
                    case 'loiter'
                        W_S = W / S_ref;
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_loiter(W_TO, W, W_S, state.q, CD0, e_osw, req.AR, seg.time_min, tsfc);
                    case 'descent'
                        fuel_seg = 0.990*W*0.010; W = W - fuel_seg;  % ~1% fuel for descent
                    case 'landing'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_landing(W, W_TO);
                    otherwise
                        fuel_seg = 0;
                end
                total_fuel = total_fuel + fuel_seg;
            end
            fuel = total_fuel * 1.06;
        end
    end

    methods (Static)

        function [LD_ratio] = compute_LD_ratio(W, W_TO, q, CD0, W_S, e, AR)
            W_by_W_TO = W / W_TO;
            W_by_S    = W_by_W_TO * W_S;
            LD_ratio  = 1 / ((q*CD0/W_by_S) + (W_by_S/(q*pi*e*AR)));
        end

        function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
            WF = exp(-(R*TSFC)/(Vend*LD_ratio));
        end

        function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0) %#ok<INUSL>
            WF_Climb  = 1.0065 - 0.0325*Mach;
            fuel_used = (1-WF_Climb)*W_in;
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q, W_S)
            LD        = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
            WF        = exp(-(time*60*TSFC/LD));
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used - payload;
        end

        function [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S) %#ok<INUSL>
            V         = Mach*a;
            LD        = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
            WF        = MissionAnalysisLevel2.compute_weightfraction(TSFC, Distance, V, LD);
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_dash(W_in, W_S, W_TO, q, CD0, e, AR, TSFC, Distance, V)
            LD        = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
            WF        = MissionAnalysisLevel2.compute_weightfraction(TSFC, Distance, V, LD);
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_landing(W_in, W_TO) %#ok<INUSL>
            WF        = 0.995;
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_loiter(W_TO, W_in, W_S, q, CD0, e, AR, time, TSFC)
            LD        = MissionAnalysisLevel2.compute_LD_ratio(W_in, W_TO, q, CD0, W_S, e, AR);
            WF        = exp(-(time*60*TSFC/LD));
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_startup(W_in)
            WF        = 0.99;
            W_out     = W_in*WF;
            fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_takeoff(W_in)
            WF        = 0.95;
            W_out     = W_in*WF;
            fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_taxi(W_in)
            WF        = 0.98;
            W_out     = W_in*WF;
            fuel_used = W_in - W_out;
        end

    end

end
