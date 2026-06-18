classdef MissionAnalysisLevel3 < MissionBase
    % Level III mission analysis: sub-segmented numerical integration for
    % cruise and climb; otherwise same interface as Level II.
    %
    % Cruise is divided into n sub-segments (default 20) with LD recomputed
    % at each sub-segment weight.  Climb uses energy-height integration.

    properties
        n_sub   % number of cruise/climb sub-segments (default 20)
    end

    methods
        function obj = MissionAnalysisLevel3(n_sub)
            if nargin < 1; n_sub = 20; end
            obj.n_sub = n_sub;
        end

        function fuel = compute_fuel(obj, aero, prop, W_TO, req)
            W          = W_TO;
            S_ref      = req.S_ref;
            total_fuel = 0;

            for i = 1:numel(req.segments)
                seg   = req.segments(i);
                state = AircraftState(seg.altitude_ft, seg.mach);
                polar = aero.drag_polar(state);
                CD0   = polar.CD0;
                K2    = polar.K2;
                e_osw = 1/(pi * req.AR * K2);
                tsfc  = prop.TSFC(state);

                switch seg.name
                    case 'startup'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_startup(W);
                    case 'taxi'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_taxi(W);
                    case 'takeoff'
                        [W, fuel_seg] = MissionAnalysisLevel2.segment_takeoff(W);
                    case 'climb'
                        [W, fuel_seg] = MissionAnalysisLevel3.segment_climb(W_TO, W, state.mach, S_ref, CD0, e_osw, req.AR, tsfc, seg.altitude_ft, prop.T0);
                    case 'cruise'
                        [W, fuel_seg] = MissionAnalysisLevel3.segment_cruise(W, tsfc, seg.range_ft, state.mach, state.a, state.q, CD0, e_osw, req.AR, S_ref, obj.n_sub);
                    case 'dash'
                        [W, fuel_seg] = MissionAnalysisLevel3.segment_dash(W, S_ref, W_TO, state.q, CD0, e_osw, req.AR, tsfc, seg.range_ft, state.V);
                    case 'combat'
                        W_drop = 0; if isfield(seg,'W_drop'); W_drop = seg.W_drop; end
                        [W, fuel_seg] = MissionAnalysisLevel3.segment_combat(W, seg.time_min, tsfc, W_drop, CD0, e_osw, req.AR, W_TO, state.q, S_ref);
                    case 'loiter'
                        [W, fuel_seg] = MissionAnalysisLevel3.segment_loiter(W_TO, W, S_ref, state.q, CD0, e_osw, req.AR, seg.time_min, tsfc);
                    case 'descent'
                        fuel_seg = 0.010*W; W = W - fuel_seg;
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

        function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
            W_by_W_TO = W / W_TO;
            W_by_S    = W_by_W_TO * W_S;
            LD_ratio  = 1 / ((q*CD0/W_by_S) + (W_by_S/(q*pi*e*AR)));
        end

        function [LD_ratio] = compute_LD_revised(W, q, S, CD0, e, AR)
            CL       = 2*W / (q*S);
            K        = 1/(pi*e*AR);
            LD_ratio = CL / (CD0 + K*CL^2);
        end

        function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
            WF = exp(-(R*TSFC)/(Vend*LD_ratio));
        end

        function [W_out] = compute_revised_w_out(W_in, seg_dist, TSFC, V, LD)
            W_out = W_in * exp(-(seg_dist*TSFC)/(V*LD));
        end

        function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach, S, CD0, e, AR, TSFC, h, T0)
            g     = 32.2;
            r_e   = 20902231;
            n     = 20;
            h_inc = linspace(0, h, n);
            T     = T0;
            W     = W_in;
            he_prev = h_inc(1);  % initial energy height: assume climb begins near rest at SL

            for i = 2:n
                [~, ~, ~, rho] = atmosisa(h_inc(i)*0.3048);
                rho = rho * 0.00194032033;
                Vi  = sqrt((W/S)/(3*rho*CD0)*(T/W) + sqrt((T/W)^2 + 12*CD0/(pi*e*AR)));
                qi  = 0.5*rho*Vi^2;
                CL  = 2*W/(qi*S);
                CD  = CD0 + CL^2/(pi*e*AR);
                D   = qi*S*CD;
                gh_i  = g*(r_e/(r_e+h_inc(i)))^2;
                he_i  = h_inc(i) + Vi^2/(2*gh_i);
                dh    = he_i - he_prev;    % correct energy-height increment
                WF    = exp(-(TSFC*dh)/(Vi*(1-D/T)));
                W     = WF * W;
                he_prev = he_i;            % carry energy height to next sub-step
            end
            W_out     = W;
            fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q, S_ref)
            LD        = MissionAnalysisLevel3.compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
            WF        = exp(-(time*60*TSFC/LD));
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used - payload;
        end

        function [W_current, fuel_used] = segment_cruise(W_in, TSFC, Distance, Mach, a, q, CD0, e, AR, S, n)
            if nargin < 11; n = 20; end
            seg_dist  = Distance/n;
            V         = Mach*a;
            W_current = W_in;
            for i = 1:n
                LD        = MissionAnalysisLevel3.compute_LD_revised(W_current, q, S, CD0, e, AR);
                W_current = MissionAnalysisLevel3.compute_revised_w_out(W_current, seg_dist, TSFC, V, LD);
            end
            fuel_used = W_in - W_current;
        end

        function [W_out, fuel_used] = segment_dash(W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V) %#ok<INUSL>
            LD        = MissionAnalysisLevel3.compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
            WF        = MissionAnalysisLevel3.compute_weightfraction(TSFC, Distance, V, LD);
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_landing(W_in, W_TO) %#ok<INUSL>
            WF        = 0.995;
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_loiter(W_TO, W_in, S_ref, q, CD0, e, AR, time, TSFC) %#ok<INUSL>
            LD        = MissionAnalysisLevel3.compute_LD_revised(W_in, q, S_ref, CD0, e, AR);
            WF        = exp(-(time*60*TSFC/LD));
            fuel_used = W_in*(1-WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_startup(W_in)
            WF = 0.99; W_out = W_in*WF; fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_takeoff(W_in)
            WF = 0.95; W_out = W_in*WF; fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_taxi(W_in)
            WF = 0.98; W_out = W_in*WF; fuel_used = W_in - W_out;
        end

    end

end
