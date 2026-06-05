classdef BrandtCost < handle
% BrandtCost  DAPCA IV life-cycle cost model for the Level-Brandt F-16A.
%
% Three-tier interface:
%   constructor(geom, eng)          - store dependency handles and JSON input
%   analyze()                       - compute fixed material design factor D47
%   run(W_TO_lb, wt_results, miss_results)
%                                   - compute cost outputs, store them, and
%                                     return a results struct

    properties
        inp   (1,1) struct
        geom  (1,1) BrandtGeometry
        eng   (1,1) BrandtEngine

        % analyze() output
        D47                 (1,1) double = NaN

        % run() outputs
        H_eng_hr            (1,1) double = NaN
        H_tool_hr           (1,1) double = NaN
        H_mfg_hr            (1,1) double = NaN
        H_qc_hr             (1,1) double = NaN
        C_eng_usd           (1,1) double = NaN
        C_tool_usd          (1,1) double = NaN
        C_mfg_usd           (1,1) double = NaN
        C_qc_usd            (1,1) double = NaN
        C_ds_usd            (1,1) double = NaN
        C_ft_usd            (1,1) double = NaN
        C_mm_usd            (1,1) double = NaN
        C_ep_usd            (1,1) double = NaN
        C_subtotal_usd      (1,1) double = NaN
        C_avionics_usd      (1,1) double = NaN
        C_invest_usd        (1,1) double = NaN
        C_total_1999_usd    (1,1) double = NaN
        C_unit_flyaway_usd  (1,1) double = NaN
        C_total_program_usd (1,1) double = NaN
        C_OM_annual_usd     (1,1) double = NaN
        C_OM_life_usd       (1,1) double = NaN
        C_LCC_usd           (1,1) double = NaN
        We_lb               (1,1) double = NaN
        V_max_kts           (1,1) double = NaN

        analyzed_ (1,1) logical = false
        run_done_ (1,1) logical = false
    end

    methods
        function obj = BrandtCost(geom, eng)
            if nargin < 1 || isempty(geom)
                geom = BrandtGeometry();
                geom.analyze();
            end
            if nargin < 2 || isempty(eng)
                eng = BrandtEngine();
                eng.analyze();
            end

            obj.geom = geom;
            obj.eng = eng;
            obj.inp = geom.inp;
        end

        function analyze(obj)
            c = obj.inp.cost;
            obj.D47 = ( ...
                c.material_Al_pct    * c.material_Al_fac + ...
                c.material_CF_pct    * c.material_CF_fac + ...
                c.material_FG_pct    * c.material_FG_fac + ...
                c.material_Steel_pct * c.material_Steel_fac + ...
                c.material_Ti_pct    * c.material_Ti_fac) / 100;
            obj.analyzed_ = true;
        end

        function results = run(obj, W_TO_lb, wt_results, miss_results)
            obj.requireAnalyzed_();

            if nargin < 2 || ~isscalar(W_TO_lb) || ~isfinite(W_TO_lb) || W_TO_lb <= 0
                error('LevelBrandt:invalidInput', 'W_TO_lb must be a positive scalar.');
            end
            if nargin < 3 || ~isstruct(wt_results)
                error('LevelBrandt:invalidInput', 'wt_results must be a scalar struct from BrandtWeight.run().');
            end
            if nargin < 4 || ~isstruct(miss_results)
                error('LevelBrandt:invalidInput', 'miss_results must be a scalar struct from BrandtMission.run().');
            end

            c = obj.inp.cost;
            Mmax = BrandtCost.getField_(obj.inp.aircraft, 'Mmax');
            We = BrandtCost.getField_(wt_results, 'W_empty_lb');
            W_fuel_lb = BrandtCost.getField_(miss_results, 'total_fuel_lb');
            total_time_min = BrandtCost.getField_(miss_results, 'total_time_min');

            V_kts = Mmax * 968.1 / 1.68781;
            Q = c.Q;
            Neng = Q * obj.inp.engine.n_engines;
            Tmax = obj.inp.engine.T_AB_SLS_lb;
            FTA = c.FTA;
            total_time_hr = total_time_min / 60;

            obj.We_lb = We;
            obj.V_max_kts = V_kts;

            obj.H_eng_hr  = 7.07  * We^0.777 * V_kts^0.894 * Q^0.163 * obj.D47;
            obj.H_tool_hr = 8.71  * We^0.777 * V_kts^0.696 * Q^0.263 * obj.D47;
            obj.H_mfg_hr  = 10.72 * We^0.82  * V_kts^0.484 * Q^0.641 * obj.D47;
            obj.H_qc_hr   = 0.133 * obj.H_mfg_hr * obj.D47;

            obj.C_eng_usd  = obj.H_eng_hr  * c.RE_dol_hr;
            obj.C_tool_usd = obj.H_tool_hr * c.RT_dol_hr;
            obj.C_mfg_usd  = obj.H_mfg_hr  * c.RM_dol_hr;
            obj.C_qc_usd   = obj.H_qc_hr   * c.RQ_dol_hr;
            obj.C_ds_usd   = 66     * We^0.63  * V_kts^1.3;
            obj.C_ft_usd   = 1807.1 * We^0.325 * V_kts^0.822 * FTA^1.21;
            obj.C_mm_usd   = 16     * We^0.921 * V_kts^0.621 * Q^0.799;
            obj.C_ep_usd   = 2.251  * (0.043 * Tmax + 243.25 * Mmax + 0.969 * c.Tt4_R - 2228) * 1000 * Neng;

            obj.C_subtotal_usd   = obj.C_eng_usd + obj.C_tool_usd + obj.C_mfg_usd + obj.C_qc_usd ...
                                 + obj.C_ds_usd + obj.C_ft_usd + obj.C_mm_usd + obj.C_ep_usd;
            obj.C_avionics_usd   = c.AF  * obj.C_subtotal_usd;
            obj.C_invest_usd     = c.ICF * (obj.C_subtotal_usd + obj.C_avionics_usd);
            obj.C_total_1999_usd = obj.C_subtotal_usd + obj.C_avionics_usd + obj.C_invest_usd;

            C_escalated = (1 + c.EF) * obj.C_total_1999_usd;
            obj.C_unit_flyaway_usd  = C_escalated / Q;
            obj.C_total_program_usd = C_escalated;

            obj.C_OM_annual_usd = (c.FH_yr / total_time_hr) * W_fuel_lb * c.F_dol_lb ...
                                + c.CR * c.CH_yr * c.RE_dol_hr * (1 + c.EF) ...
                                + c.MMH_FH * c.FH_yr * c.RM_dol_hr * (1 + c.EF);
            obj.C_OM_life_usd = obj.C_OM_annual_usd * c.life_yr;
            obj.C_LCC_usd = obj.C_OM_life_usd + obj.C_unit_flyaway_usd;

            obj.run_done_ = true;
            results = obj.packResults_();
            obj.validate_run_();
        end
    end

    methods (Access = private)
        function results = packResults_(obj)
            results.D47 = obj.D47;
            results.H_eng_hr = obj.H_eng_hr;
            results.H_tool_hr = obj.H_tool_hr;
            results.H_mfg_hr = obj.H_mfg_hr;
            results.H_qc_hr = obj.H_qc_hr;
            results.C_eng_usd = obj.C_eng_usd;
            results.C_tool_usd = obj.C_tool_usd;
            results.C_mfg_usd = obj.C_mfg_usd;
            results.C_qc_usd = obj.C_qc_usd;
            results.C_ds_usd = obj.C_ds_usd;
            results.C_ft_usd = obj.C_ft_usd;
            results.C_mm_usd = obj.C_mm_usd;
            results.C_ep_usd = obj.C_ep_usd;
            results.C_subtotal_usd = obj.C_subtotal_usd;
            results.C_avionics_usd = obj.C_avionics_usd;
            results.C_invest_usd = obj.C_invest_usd;
            results.C_total_1999_usd = obj.C_total_1999_usd;
            results.C_unit_flyaway_usd = obj.C_unit_flyaway_usd;
            results.C_total_program_usd = obj.C_total_program_usd;
            results.C_OM_annual_usd = obj.C_OM_annual_usd;
            results.C_OM_life_usd = obj.C_OM_life_usd;
            results.C_LCC_usd = obj.C_LCC_usd;
            results.We_lb = obj.We_lb;
            results.V_max_kts = obj.V_max_kts;
        end

        function requireAnalyzed_(obj)
            if ~obj.analyzed_
                error('LevelBrandt:notAnalyzed', 'Call analyze() before calling run().');
            end
        end

        function validate_run_(obj)
            fields = {'D47', 'C_unit_flyaway_usd', 'C_total_program_usd', 'C_OM_life_usd', 'C_LCC_usd'};
            for k = 1:numel(fields)
                val = obj.(fields{k});
                assert(~isnan(val), 'LevelBrandt:nanOutput', '%s is NaN', fields{k});
            end
        end
    end

    methods (Static, Access = private)
        function value = getField_(s, field)
            if ~isfield(s, field)
                error('LevelBrandt:invalidInput', 'Missing required field: %s', field);
            end
            value = s.(field);
        end

    end
end
