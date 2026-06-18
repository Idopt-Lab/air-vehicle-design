classdef MissionAnalysisLevel4 < MissionBase
    % Level IV mission analysis: same sub-segmented integration as Level III
    % with Mattingly-based TSFC from PropulsionLevel4 (no change to interface).
    %
    % Bug fix from Casey's original: calls to undefined compute_revised_LD_ratio
    % are replaced with compute_LD_revised (the correct static method name).
    %
    % Inherits from MissionBase (not MissionAnalysisModel).

    properties
        n_sub   % cruise/climb sub-segments (default 20)
    end

    methods
        function obj = MissionAnalysisLevel4(n_sub)
            if nargin < 1; n_sub = 20; end
            obj.n_sub = n_sub;
        end

        function fuel = compute_fuel(obj, aero, prop, W_TO, req)
            % Delegates to Level III logic — the interface is identical.
            % At Level IV, the aero and prop objects are L4 instances that
            % provide higher-fidelity drag polars and TSFC.
            L3 = MissionAnalysisLevel3(obj.n_sub);
            fuel = L3.compute_fuel(aero, prop, W_TO, req);
        end
    end

    methods (Access = private)

        function [LD_ratio] = compute_LD_revised(W, q, S, CD0, e, AR)
            % Correct name used consistently throughout this class.
            CL       = 2*W / (q*S);
            K        = 1/(pi*e*AR);
            LD_ratio = CL / (CD0 + K*CL^2);
        end

        function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
            WF = exp(-(R*TSFC)/(Vend*LD_ratio));
        end

        function [W_out, fuel_used] = segment_startup(W_in)
            WF = 0.99; W_out = W_in*WF; fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_taxi(W_in)
            WF = 0.98; W_out = W_in*WF; fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_takeoff(W_in)
            WF = 0.95; W_out = W_in*WF; fuel_used = W_in - W_out;
        end

        function [W_out, fuel_used] = segment_landing(W_in, W_TO) %#ok<INUSL>
            WF = 0.995; fuel_used = W_in*(1-WF); W_out = W_in - fuel_used;
        end

    end

end
