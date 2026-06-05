classdef BrandtPerformance < handle
% BrandtPerformance  Ps, maneuver, and V-n calculations for Level-Brandt.

    properties
        inp   (1,1) struct
        geom
        aero
        eng
        wt

        Mmax         (1,1) double = NaN
        mach_perf    (1,:) double = []
        mach_ps      (1,:) double = []
        alt_ps_ft    (:,1) double = []

        perf_table       (1,1) struct = struct()
        Ps_grid          double = []
        turn_rate_table  (1,1) struct = struct()
        vn_diagram       (1,1) struct = struct()
        Ps_peak_fps         (1,1) double = NaN
        turn_rate_peak_deg_s (1,1) double = NaN

        analyzed_ (1,1) logical = false
        run_done_ (1,1) logical = false
    end

    methods
        function obj = BrandtPerformance(geom, aero, eng, wt)
            if nargin < 1 || isempty(geom)
                geom = BrandtGeometry();
                geom.analyze();
            end
            if nargin < 2 || isempty(aero)
                aero = BrandtAerodynamics(geom);
                aero.analyze();
            end
            if nargin < 3 || isempty(eng)
                eng = BrandtEngine();
                eng.analyze();
            end
            if nargin < 4 || isempty(wt)
                wt = BrandtWeight(geom);
                wt.analyze();
            end

            obj.geom = geom;
            obj.aero = aero;
            obj.eng = eng;
            obj.wt = wt;
            obj.inp = geom.inp;
        end

        function analyze(obj)
            if ~obj.geom.analyzed_ || ~obj.aero.analyzed_ || ~obj.eng.analyzed_ || ~obj.wt.analyzed_
                error('LevelBrandt:notAnalyzed', 'geom, aero, eng, and wt must be analyzed before BrandtPerformance.analyze().');
            end

            obj.Mmax = obj.inp.aircraft.Mmax;
            obj.mach_perf = linspace(0.3, obj.Mmax, 25);
            obj.mach_ps = 0.2:0.1:obj.Mmax;
            obj.alt_ps_ft = (0:5000:70000)';
            obj.analyzed_ = true;
        end

        function results = run(obj, W_lb, options)
            obj.requireAnalyzed_();
            if nargin < 2 || ~isscalar(W_lb) || ~isfinite(W_lb) || W_lb <= 0
                error('LevelBrandt:invalidInput', 'W_lb must be a positive scalar.');
            end
            if nargin < 3 || isempty(options)
                options = struct();
            elseif ~isstruct(options)
                error('LevelBrandt:invalidInput', 'options must be a struct.');
            end

            alt_perf_ft = BrandtPerformance.optionField_(options, 'altitude_ft', obj.inp.performance.altitude_perf_ft);
            pct_AB = BrandtPerformance.optionField_(options, 'pct_AB', 0);
            alt_maneuv_ft = BrandtPerformance.optionField_(options, 'altitude_maneuv_ft', obj.inp.performance.altitude_maneuv_ft);
            pct_AB_maneuv = BrandtPerformance.optionField_(options, 'pct_AB_maneuv', obj.inp.performance.pct_AB_maneuv);
            n_max_pos = BrandtPerformance.optionField_(options, 'n_max_pos', obj.inp.performance.n_max_pos);

            obj.perf_table = obj.run_perf(W_lb, alt_perf_ft, pct_AB);
            [obj.Ps_grid, obj.mach_ps, obj.alt_ps_ft] = obj.run_ps(W_lb, pct_AB);
            obj.turn_rate_table = obj.run_maneuv(W_lb, alt_maneuv_ft, pct_AB_maneuv, n_max_pos);
            obj.vn_diagram = obj.run_struct(W_lb, n_max_pos);

            obj.Ps_peak_fps = max(obj.Ps_grid(:));
            obj.turn_rate_peak_deg_s = max(obj.turn_rate_table.turn_rate_sustained_deg_s);
            obj.run_done_ = true;

            results.perf_table = obj.perf_table;
            results.Ps_grid = obj.Ps_grid;
            results.mach_ps = obj.mach_ps;
            results.alt_ps_ft = obj.alt_ps_ft;
            results.turn_rate_table = obj.turn_rate_table;
            results.vn_diagram = obj.vn_diagram;
            results.Ps_peak_fps = obj.Ps_peak_fps;
            results.turn_rate_peak_deg_s = obj.turn_rate_peak_deg_s;

            obj.validate_run_();
        end

        function perf = run_perf(obj, W_lb, altitude_ft, pct_AB)
            obj.requireAnalyzed_();
            [a_fps, rho_slugft3] = obj.atmEnglish_(altitude_ft);
            S_ref_ft2 = obj.inp.wing.S_ref_ft2;
            AB_p = obj.normalizeAB_(pct_AB);

            mach_vec = obj.mach_perf;
            n = numel(mach_vec);
            V_fps = nan(1, n);
            q_psf = nan(1, n);
            CL = nan(1, n);
            CD = nan(1, n);
            D_lb = nan(1, n);
            T_lb = nan(1, n);
            Ps_fps = nan(1, n);

            for i = 1:n
                M = mach_vec(i);
                V_fps(i) = M * a_fps;
                q_psf(i) = 0.5 * rho_slugft3 * V_fps(i)^2;
                aero_r = obj.aero.run(M);
                CL(i) = W_lb / (q_psf(i) * S_ref_ft2);
                CD(i) = aero_r.CD0 + aero_r.K1 * CL(i)^2 + aero_r.K2 * CL(i);
                D_lb(i) = CD(i) * q_psf(i) * S_ref_ft2;
                T_lb(i) = obj.thrustSafe_(altitude_ft, M, AB_p);
                Ps_fps(i) = (T_lb(i) - D_lb(i)) * V_fps(i) / W_lb;
            end

            perf.altitude_ft = altitude_ft;
            perf.pct_AB = pct_AB;
            perf.mach = mach_vec;
            perf.V_fps = V_fps;
            perf.q_psf = q_psf;
            perf.CL = CL;
            perf.CD = CD;
            perf.D_lb = D_lb;
            perf.T_lb = T_lb;
            perf.Ps_fps = Ps_fps;
        end

        function [Ps_grid, mach_vec, alt_vec] = run_ps(obj, W_lb, pct_AB)
            obj.requireAnalyzed_();
            S_ref_ft2 = obj.inp.wing.S_ref_ft2;
            AB_p = obj.normalizeAB_(pct_AB);
            mach_vec = obj.mach_ps;
            alt_vec = obj.alt_ps_ft;
            Ps_grid = nan(numel(alt_vec), numel(mach_vec));

            for i = 1:numel(alt_vec)
                [a_fps, rho_slugft3] = obj.atmEnglish_(alt_vec(i));
                for j = 1:numel(mach_vec)
                    M = mach_vec(j);
                    V_fps = M * a_fps;
                    q_psf = 0.5 * rho_slugft3 * V_fps^2;
                    aero_r = obj.aero.run(M);
                    CL = W_lb / (q_psf * S_ref_ft2);
                    CD = aero_r.CD0 + aero_r.K1 * CL^2 + aero_r.K2 * CL;
                    D_lb = CD * q_psf * S_ref_ft2;
                    T_lb = obj.thrustSafe_(alt_vec(i), M, AB_p);
                    Ps_grid(i, j) = (T_lb - D_lb) * V_fps / W_lb;
                end
            end
        end

        function maneuv = run_maneuv(obj, W_lb, altitude_ft, pct_AB, n_max_pos)
            obj.requireAnalyzed_();
            if nargin < 5 || isempty(n_max_pos)
                n_max_pos = obj.inp.performance.n_max_pos;
            end

            [a_fps, rho_slugft3] = obj.atmEnglish_(altitude_ft);
            S_ref_ft2 = obj.inp.wing.S_ref_ft2;
            AB_p = obj.normalizeAB_(pct_AB);
            mach_vec = 0.3:0.05:min(1.2, obj.Mmax);
            n = numel(mach_vec);

            n_sustained = nan(1, n);
            n_instant = nan(1, n);
            turn_rate_sustained = nan(1, n);
            turn_rate_inst = nan(1, n);

            for i = 1:n
                M = mach_vec(i);
                V_fps = M * a_fps;
                q_psf = 0.5 * rho_slugft3 * V_fps^2;
                aero_r = obj.aero.run(M);
                T_lb = obj.thrustSafe_(altitude_ft, M, AB_p);

                n_stall = q_psf * S_ref_ft2 * aero_r.CLmax_clean / W_lb;
                n_instant(i) = min(n_max_pos, n_stall);

                disc = aero_r.K2^2 - 4 * aero_r.K1 * (aero_r.CD0 - T_lb / (q_psf * S_ref_ft2));
                if disc >= 0
                    X = (-aero_r.K2 + sqrt(disc)) / (2 * aero_r.K1);
                    n_sus = X * q_psf * S_ref_ft2 / W_lb;
                else
                    n_sus = 1.0;
                end

                n_sustained(i) = min(max(n_sus, 1.0), n_instant(i));
                turn_rate_sustained(i) = obj.turnRate_(n_sustained(i), V_fps);
                turn_rate_inst(i) = obj.turnRate_(n_instant(i), V_fps);
            end

            maneuv.altitude_ft = altitude_ft;
            maneuv.pct_AB = pct_AB;
            maneuv.mach = mach_vec;
            maneuv.n_sustained = n_sustained;
            maneuv.n_instant = n_instant;
            maneuv.turn_rate_sustained_deg_s = turn_rate_sustained;
            maneuv.turn_rate_instant_deg_s = turn_rate_inst;
        end

        function vn = run_struct(obj, W_lb, n_max_pos)
            obj.requireAnalyzed_();
            if nargin < 3 || isempty(n_max_pos)
                n_max_pos = obj.inp.performance.n_max_pos;
            end

            [~, rho_slugft3] = obj.atmEnglish_(0);
            S_ref_ft2 = obj.inp.wing.S_ref_ft2;
            CLmax_clean = obj.aero.run(0.3).CLmax_clean;
            CLmax_neg = 0.8 * CLmax_clean;
            n_max_neg = obj.inp.performance.n_max_neg;

            V_stall_pos = sqrt(2 * W_lb / (rho_slugft3 * S_ref_ft2 * CLmax_clean));
            V_stall_neg = sqrt(2 * W_lb / (rho_slugft3 * S_ref_ft2 * CLmax_neg));
            V_qmax = sqrt(2 * obj.inp.performance.q_max_psf / rho_slugft3);
            V_corner = V_stall_pos * sqrt(n_max_pos);

            V_fps = linspace(0, V_qmax, 250);
            n_pos_stall = (V_fps / V_stall_pos).^2;
            n_neg_stall = -(V_fps / V_stall_neg).^2;

            vn.V_fps = V_fps;
            vn.n_pos_stall = min(n_pos_stall, n_max_pos);
            vn.n_neg_stall = max(n_neg_stall, -n_max_neg);
            vn.n_max_pos = n_max_pos;
            vn.n_max_neg = n_max_neg;
            vn.V_stall_pos_fps = V_stall_pos;
            vn.V_stall_neg_fps = V_stall_neg;
            vn.V_corner_fps = V_corner;
            vn.V_qmax_fps = V_qmax;
        end

        function plot_ps(obj)
            obj.requireRun_();
            contour(obj.mach_ps, obj.alt_ps_ft, obj.Ps_grid, [0 200 400], 'ShowText', 'on');
            xlabel('Mach'); ylabel('Altitude [ft]'); title('Specific Excess Power [ft/s]'); grid on;
        end

        function plot_maneuv(obj)
            obj.requireRun_();
            plot(obj.turn_rate_table.mach, obj.turn_rate_table.turn_rate_sustained_deg_s, 'LineWidth', 1.5); hold on;
            plot(obj.turn_rate_table.mach, obj.turn_rate_table.turn_rate_instant_deg_s, '--', 'LineWidth', 1.5); hold off;
            xlabel('Mach'); ylabel('Turn rate [deg/s]'); legend('Sustained', 'Instantaneous', 'Location', 'best'); grid on;
        end

        function plot_vn(obj)
            obj.requireRun_();
            plot(obj.vn_diagram.V_fps, obj.vn_diagram.n_pos_stall, 'LineWidth', 1.5); hold on;
            plot(obj.vn_diagram.V_fps, obj.vn_diagram.n_neg_stall, 'LineWidth', 1.5);
            yline(obj.vn_diagram.n_max_pos, '--');
            yline(-obj.vn_diagram.n_max_neg, '--');
            xline(obj.vn_diagram.V_corner_fps, ':');
            xline(obj.vn_diagram.V_qmax_fps, ':');
            hold off;
            xlabel('Velocity [ft/s]'); ylabel('Load factor n'); title('V-n Diagram'); grid on;
        end
    end

    methods (Access = private)
        function requireAnalyzed_(obj)
            if ~obj.analyzed_
                error('LevelBrandt:notAnalyzed', 'Call analyze() before calling run().');
            end
        end

        function requireRun_(obj)
            if ~obj.run_done_
                error('LevelBrandt:notAnalyzed', 'Call run() before plotting results.');
            end
        end

        function validate_run_(obj)
            assert(~isnan(obj.Ps_peak_fps), 'LevelBrandt:nanOutput', 'Ps_peak_fps is NaN');
            assert(~isnan(obj.turn_rate_peak_deg_s), 'LevelBrandt:nanOutput', 'turn_rate_peak_deg_s is NaN');
            assert(~isempty(obj.Ps_grid), 'LevelBrandt:nanOutput', 'Ps_grid is empty');
            assert(~isempty(obj.vn_diagram), 'LevelBrandt:nanOutput', 'vn_diagram is empty');
        end

        function T_lb = thrustSafe_(obj, altitude_ft, mach, AB_p)
            try
                eng_r = obj.eng.run(altitude_ft, mach, AB_p);
                T_lb = max(eng_r.T, 0);
            catch ME
                if strcmp(ME.identifier, 'LevelBrandt:invalidOutput')
                    T_lb = 0;
                else
                    rethrow(ME);
                end
            end
        end

        function [a_fps, rho_slugft3] = atmEnglish_(~, altitude_ft)
            alt_m = altitude_ft * 0.3048;
            [~, a_mps, ~, rho_kgm3] = atmosisa(alt_m);
            a_fps = a_mps / 0.3048;
            rho_slugft3 = rho_kgm3 / 515.379;
        end

        function AB_p = normalizeAB_(~, pct_AB)
            AB_p = pct_AB;
            if AB_p > 1
                AB_p = AB_p / 100;
            end
            AB_p = max(0, min(1, AB_p));
        end

        function turn_rate_deg_s = turnRate_(~, n, V_fps)
            if n <= 1 || V_fps <= 0
                turn_rate_deg_s = 0;
            else
                turn_rate_deg_s = (32.174 * sqrt(n^2 - 1) / V_fps) * 180 / pi;
            end
        end
    end

    methods (Static, Access = private)
        function value = optionField_(options, name, defaultValue)
            if isfield(options, name)
                value = options.(name);
            else
                value = defaultValue;
            end
        end
    end
end
