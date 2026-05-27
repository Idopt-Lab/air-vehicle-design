classdef BrandtEngine < handle
% BrandtEngine  Replicates Brandt-F16-A.xls Engn(s) tab.
%
% Computes installed thrust and TSFC at given altitude and Mach number
% using standard atmosphere ratios (theta, delta, theta0, delta0) and
% throttle-ratio branching.  Source: Engn(s) tab rows 4–7.
%
% Usage:
%   eng = BrandtEngine();
%   eng.analyze();
%   [T_dry, tsfc_dry] = eng.thrust_dry(40000, 0.87);   % lbf, 1/hr
%   [T_AB,  tsfc_AB]  = eng.thrust_AB(40000, 0.87);    % lbf, 1/hr
%
%   % run() dual-return interface:
%   r = eng.run(40000, 0.87, 0.0);
%   r.T
%   eng.run_T_lb

    properties
        inp         (1,1) struct

        T_sl_dry    (1,1) double = NaN   % Engn!T_mil_SLS = 15000 lbf (dry/mil SLS thrust)
        T_sl_AB     (1,1) double = NaN   % Engn!T_AB_SLS  = 23770 lbf (AB SLS thrust)
        TSFC_sl_dry (1,1) double = NaN   % Engn!TSFC_mil  = 0.70 hr⁻¹ (installed, calibrated at M=0)
        TSFC_sl_AB  (1,1) double = NaN   % Engn!TSFC_AB   = 2.20 hr⁻¹ (installed, calibrated at M=0.4)
        TR          (1,1) double = NaN   % Engn!S1        = 1.0 (throttle ratio, temperature-ratio limit)
        n_engines   (1,1) double = NaN   % number of engines = 1

        % run() outputs (set by run(altitude_ft, mach, AB_p))
        run_altitude_ft  (1,1) double = NaN
        run_mach         (1,1) double = NaN
        run_AB_p         (1,1) double = NaN   % afterburner percent [0..1]
        run_alpha        (1,1) double = NaN   % thrust lapse = T / (T_sl_dry * n_engines)
        run_alpha_AB_ref (1,1) double = NaN   % thrust lapse = T / (T_sl_AB  * n_engines) [Miss tab convention]
        run_T_lb         (1,1) double = NaN   % installed thrust [lbf]
        run_TSFC         (1,1) double = NaN   % installed TSFC [1/hr]

        analyzed_   (1,1) logical = false
    end

    methods
        function obj = BrandtEngine()
            json_path = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                'examples', 'F-16A B Block 10 and 15', 'Ground-Truth', 'f16a_geometry.json');
            obj.inp = jsondecode(fileread(json_path));
        end

        function analyze(obj)
            e = obj.inp.engine;
            obj.T_sl_dry    = e.T_mil_SLS_lb;
            obj.T_sl_AB     = e.T_AB_SLS_lb;
            obj.TSFC_sl_dry = e.TSFC_mil_per_hr;
            obj.TSFC_sl_AB  = e.TSFC_AB_per_hr;
            obj.TR          = e.TR;
            obj.n_engines   = e.n_engines;
            obj.analyzed_   = true;
        end

        function prop_results = run(obj, altitude_ft, mach, AB_p)
        % Evaluate installed thrust and TSFC at given flight conditions.
        % Returns struct with fields: alpha, alpha_AB_ref, T, TSFC
        %
        % Dual-return contract:
        %   prop_results = eng_obj.run(altitude_ft, mach, AB_p);
        %   eng_obj.run(altitude_ft, mach, AB_p);  % equivalent: results in run_* properties
        %
        % Level-Brandt mapping:
        %   state_vector   = [altitude_ft, mach]  (flight condition)
        %   control_vector = [AB_p]               (afterburner percent, 0=dry, 1=full AB)
        %
        % alpha definition: T / (T_sl_dry * n_engines)
        %   For dry (AB_p=0): alpha < 1 at altitude
        %   For full AB (AB_p=1): alpha can exceed 1 (T_AB > T_sl_dry)
        %
        % alpha_AB_ref definition: T / (T_sl_AB * n_engines)  [Miss tab normalisation]
        %   This is the thrust lapse used in mission analysis (rows 40–42 of Miss tab).
        %   Exposed here so BrandtMission does not need to re-implement this normalisation.
        %   alpha_AB_ref = (T_sl_dry/T_sl_AB)*alpha_dry*(1-AB_p) + alpha_AB*AB_p
        %   Simplified: alpha_AB_ref = T_total / (T_sl_AB * n_engines)
            obj.requireAnalyzed_();

            [T_dry, tsfc_dry] = obj.thrust_dry(altitude_ft, mach);
            [T_AB,  tsfc_AB ] = obj.thrust_AB(altitude_ft, mach);

            AB_p = max(0, min(1, AB_p));

            T_total = (1 - AB_p) * T_dry + AB_p * T_AB;

            wdot = (1 - AB_p) * (tsfc_dry * T_dry) + AB_p * (tsfc_AB * T_AB);
            if T_total > 0
                tsfc_eff = wdot / T_total;
            else
                tsfc_eff = 0;
            end

            alpha = T_total / (obj.T_sl_dry * obj.n_engines);
            alpha_AB_ref = T_total / (obj.T_sl_AB * obj.n_engines);

            obj.run_altitude_ft  = altitude_ft;
            obj.run_mach         = mach;
            obj.run_AB_p         = AB_p;
            obj.run_alpha        = alpha;
            obj.run_alpha_AB_ref = alpha_AB_ref;
            obj.run_T_lb         = T_total;
            obj.run_TSFC         = tsfc_eff;

            prop_results.alpha        = alpha;
            prop_results.alpha_AB_ref = alpha_AB_ref;
            prop_results.T            = T_total;
            prop_results.TSFC         = tsfc_eff;

            obj.validate_run_();
        end

        function [T, tsfc] = thrust_dry(obj, altitude_ft, mach)
        % Dry (mil) thrust [lbf] and installed TSFC [1/hr] at altitude and Mach.
        %
        % Engn(s) tab equations (theta0 <= TR branch, cells A4:G4):
        %   alpha = delta0 * (1 - 0.3*M)
        %
        % Engn(s) tab equations (theta0 > TR branch, cells H4:S4):
        %   alpha = delta0 * (1 - 0.3*M - 1.7*(theta0 - TR)/theta0)
        %
        % TSFC:
        %   tsfc_dry = TSFC_sl_dry * (1 + 0.35*|M|) * sqrt(alpha)
        %
        % T = T_sl_dry * n_engines * alpha
            obj.requireAnalyzed_();
            [~, theta0, ~, delta0] = BrandtEngine.atmosphereRatios(altitude_ft, mach);
            % max(0,...) gives 0 when theta0<=TR (lo branch) and the actual excess when theta0>TR
            correction = max(0, 1.7 .* (theta0 - obj.TR) ./ theta0);
            alpha = delta0 .* (1 - 0.3 .* mach - correction);
            T    = obj.T_sl_dry .* obj.n_engines .* alpha;
            tsfc = obj.TSFC_sl_dry .* (1 + 0.35 .* abs(mach)) .* sqrt(max(0, alpha));
        end

        function [T, tsfc] = thrust_AB(obj, altitude_ft, mach)
        % Afterburner thrust [lbf] and installed TSFC [1/hr] at altitude and Mach.
        %
        % Engn(s) tab equations (theta0 <= TR branch):
        %   alpha = delta0 * (1 - 0.1*sqrt(M))
        %
        % Engn(s) tab equations (theta0 > TR branch):
        %   alpha = delta0 * (1 - 0.1*sqrt(M) - 2.2*(theta0 - TR)/theta0)
        %
        % TSFC:
        %   tsfc_AB = TSFC_sl_AB * (1 + 0.35*|M - 0.4|) * sqrt(alpha)
        %
        % T = T_sl_AB * n_engines * alpha
            obj.requireAnalyzed_();
            [~, theta0, ~, delta0] = BrandtEngine.atmosphereRatios(altitude_ft, mach);
            correction = max(0, 2.2 .* (theta0 - obj.TR) ./ theta0);
            alpha = delta0 .* (1 - 0.1 .* sqrt(mach) - correction);
            T    = obj.T_sl_AB .* obj.n_engines .* alpha;
            tsfc = obj.TSFC_sl_AB .* (1 + 0.35 .* abs(mach - 0.4)) .* sqrt(max(0, alpha));
        end
    end

    methods (Access = private)
        function validate_run_(obj)
            assert(~isnan(obj.run_T_lb),          'LevelBrandt:nanOutput', 'run_T_lb is NaN');
            assert(~isnan(obj.run_TSFC),           'LevelBrandt:nanOutput', 'run_TSFC is NaN');
            assert(~isnan(obj.run_alpha),          'LevelBrandt:nanOutput', 'run_alpha is NaN');
            assert(~isnan(obj.run_alpha_AB_ref),   'LevelBrandt:nanOutput', 'run_alpha_AB_ref is NaN');
            assert(obj.run_T_lb  >= 0, 'LevelBrandt:invalidOutput', 'run_T_lb must be >= 0');
            assert(obj.run_TSFC  >= 0, 'LevelBrandt:invalidOutput', 'run_TSFC must be >= 0');
        end

        function requireAnalyzed_(obj)
            if ~obj.analyzed_
                error('LevelBrandt:notAnalyzed', ...
                    'Call analyze() before accessing engine results.');
            end
        end
    end

    methods (Static)
        function [theta, theta0, delta, delta0] = atmosphereRatios(altitude_ft, mach)
        % Standard ISA atmosphere ratios at given altitude and Mach number.
        % atmosisa takes SI input (meters); SLS reference: T_SL=288.15 K, P_SL=101325 Pa.
        %
        %   theta  = T(h) / 288.15               (static temperature ratio)
        %   delta  = P(h) / 101325               (static pressure ratio)
        %   theta0 = theta * (1 + 0.2*M^2)      (total temperature ratio)
        %   delta0 = delta * (1 + 0.2*M^2)^3.5  (total pressure ratio)
            alt_m         = altitude_ft .* 0.3048;
            [T_K, ~, P_Pa, ~] = atmosisa(alt_m);
            theta  = T_K  ./ 288.15;
            delta  = P_Pa ./ 101325;
            theta0 = theta .* (1 + 0.2 .* mach.^2);
            delta0 = delta .* (1 + 0.2 .* mach.^2).^3.5;
        end
    end
end
