classdef BrandtBalanceStabControl < handle
% BrandtBalanceStabControl  Balance, stability, control, and gear checks.
%
% Three-tier interface:
%   constructor(geom, wt, aero) - store handles and inputs
%   analyze()                   - geometry-only MAC/AC/CG/NP quantities
%   run(W_TO_lb)                - weight-dependent CG and gear metrics

    properties
        inp   (1,1) struct
        geom
        wt
        aero

        MAC_wing_ft     (1,1) double = NaN
        MAC_pitch_ft    (1,1) double = NaN
        MAC_strake_ft   (1,1) double = NaN
        MAC_vert_ft     (1,1) double = NaN
        xMAC_wing_ft    (1,1) double = NaN
        xMAC_pitch_ft   (1,1) double = NaN
        xMAC_strake_ft  (1,1) double = NaN
        xMAC_vert_ft    (1,1) double = NaN
        x_ac_wing_ft    (1,1) double = NaN
        x_ac_pitch_ft   (1,1) double = NaN
        x_ac_strake_ft  (1,1) double = NaN
        x_ac_vert_ft    (1,1) double = NaN
        x_ac_wing_strake_ft      (1,1) double = NaN
        x_ac_wing_strake_fuse_ft (1,1) double = NaN
        xnp_ft          (1,1) double = NaN
        CLa_wing_rad    (1,1) double = NaN
        CLa_pitch_rad   (1,1) double = NaN
        CLa_vert_rad    (1,1) double = NaN
        fuselage_xcg_ft (1,1) double = NaN
        balance_datum_shift_ft (1,1) double = -0.52223

        xcg_wing_ft     (1,1) double = NaN
        xcg_fuse_ft     (1,1) double = NaN
        xcg_pitch_ft    (1,1) double = NaN
        xcg_vert_ft     (1,1) double = NaN
        xcg_nacelle_ft  (1,1) double = NaN
        xcg_strake_ft   (1,1) double = NaN
        xcg_engine_ft   (1,1) double = NaN
        xcg_gear_ft     (1,1) double = NaN
        xcg_inlet_ft    (1,1) double = NaN
        xcg_ctrl_ft     (1,1) double = NaN
        xcg_elec_ft     (1,1) double = NaN
        xcg_hyd_ft      (1,1) double = NaN
        xcg_ECS_ft      (1,1) double = NaN
        xcg_other_ft    (1,1) double = NaN
        xcg_avionics_ft (1,1) double = NaN
        xcg_armament_ft (1,1) double = NaN
        xcg_perm_pay_ft (1,1) double = NaN
        xcg_exp_pay_ft  (1,1) double = NaN
        xcg_fuel1_ft    (1,1) double = NaN
        xcg_fuel2_ft    (1,1) double = NaN
        xcg_fuel3_ft    (1,1) double = NaN

        xcg_TO_ft       (1,1) double = NaN
        xcg_land_ft     (1,1) double = NaN
        SM_TO           (1,1) double = NaN
        SM_land         (1,1) double = NaN
        gear_main_pct   (1,1) double = NaN
        gear_nose_pct   (1,1) double = NaN
        tipback_deg     (1,1) double = NaN
        rollover_deg    (1,1) double = NaN

        analyzed_ (1,1) logical = false
        run_done_ (1,1) logical = false
    end

    methods
        function obj = BrandtBalanceStabControl(geom, wt, aero)
            if nargin < 1 || isempty(geom)
                geom = BrandtGeometry();
                geom.analyze();
            end
            if nargin < 2 || isempty(wt)
                wt = BrandtWeight(geom);
                wt.analyze();
            end
            if nargin < 3 || isempty(aero)
                aero = BrandtAerodynamics(geom);
                aero.analyze();
            end

            obj.geom = geom;
            obj.wt = wt;
            obj.aero = aero;
            obj.inp = geom.inp;
        end

        function analyze(obj)
            if ~obj.geom.analyzed_ || ~obj.wt.analyzed_ || ~obj.aero.analyzed_
                error('LevelBrandt:notAnalyzed', 'geom, wt, and aero must be analyzed before BrandtBalanceStabControl.analyze().');
            end

            [obj.MAC_wing_ft, obj.xMAC_wing_ft, obj.x_ac_wing_ft] = obj.surfaceGeom_( ...
                obj.geom.wing.c_root_ft, obj.geom.wing.c_tip_ft, obj.geom.wing.half_span_ft, ...
                obj.inp.wing.sweep_LE_deg, obj.inp.wing.x_apex_ft);
            [obj.MAC_pitch_ft, obj.xMAC_pitch_ft, obj.x_ac_pitch_ft] = obj.surfaceGeom_( ...
                obj.geom.pitch_ctrl.c_root_ft, obj.geom.pitch_ctrl.c_tip_ft, obj.geom.pitch_ctrl.half_span_ft, ...
                obj.inp.pitch_ctrl.sweep_LE_deg, obj.inp.pitch_ctrl.x_le_ft);
            [obj.MAC_strake_ft, obj.xMAC_strake_ft, obj.x_ac_strake_ft] = obj.surfaceGeom_( ...
                obj.geom.strake.c_root_ft, obj.geom.strake.c_tip_ft, obj.geom.strake.half_span_ft, ...
                obj.inp.strake.sweep_LE_deg, obj.inp.strake.x_le_ft);

            span_vert_eff = max(obj.geom.vert_tail.span_exp_ft - obj.inp.fuselage.max_height_ft / 2, 0);
            [obj.MAC_vert_ft, obj.xMAC_vert_ft, obj.x_ac_vert_ft] = obj.surfaceGeom_( ...
                obj.geom.vert_tail.c_root_ft, obj.geom.vert_tail.c_tip_ft, span_vert_eff, ...
                obj.inp.vert_tail.sweep_LE_deg, obj.inp.vert_tail.x_le_ft);

            obj.CLa_wing_rad  = obj.clalpha_(obj.inp.wing.AR, obj.inp.wing.taper, obj.inp.wing.sweep_LE_deg);
            obj.CLa_pitch_rad = obj.clalpha_(obj.inp.pitch_ctrl.AR, obj.inp.pitch_ctrl.taper, obj.inp.pitch_ctrl.sweep_LE_deg);
            obj.CLa_vert_rad  = obj.clalpha_(obj.inp.vert_tail.AR, obj.inp.vert_tail.taper, obj.inp.vert_tail.sweep_LE_deg);

            if ~isnan(obj.geom.fuselage_xcg_ft)
                obj.fuselage_xcg_ft = obj.geom.fuselage_xcg_ft;
            else
                x_all = [0, obj.geom.frame_x];
                x_mid = (x_all(1:end-1) + x_all(2:end)) / 2;
                obj.fuselage_xcg_ft = sum(obj.geom.fuselage_dSwet .* x_mid) / sum(obj.geom.fuselage_dSwet);
            end

            S_wing = obj.inp.wing.S_ref_ft2;
            S_strake = obj.inp.strake.S_ft2;
            S_pitch = obj.inp.pitch_ctrl.S_ft2;

            obj.x_ac_wing_strake_ft = obj.x_ac_wing_ft + 0.5 * ((obj.x_ac_strake_ft - obj.x_ac_wing_ft) * S_strake) / (S_wing + S_strake);
            delta_xac_fuse_ft = 0.022 * obj.inp.fuselage.max_width_ft;
            obj.x_ac_wing_strake_fuse_ft = obj.x_ac_wing_strake_ft - delta_xac_fuse_ft;

            l_HS_ft = obj.x_ac_pitch_ft - obj.x_ac_wing_strake_fuse_ft;
            obj.xnp_ft = obj.x_ac_wing_strake_fuse_ft ...
                + (S_pitch / S_wing) * (l_HS_ft / obj.MAC_wing_ft) * (1 - obj.aero.downwash) * obj.MAC_wing_ft;

            obj.xcg_wing_ft     = obj.xMAC_wing_ft + 0.4 * obj.MAC_wing_ft;
            obj.xcg_fuse_ft     = obj.fuselage_xcg_ft;
            obj.xcg_pitch_ft    = obj.xMAC_pitch_ft + 0.4 * obj.MAC_pitch_ft;
            obj.xcg_vert_ft     = obj.xMAC_vert_ft + 0.4 * obj.MAC_vert_ft;
            obj.xcg_strake_ft   = obj.xMAC_strake_ft + 0.4 * obj.MAC_strake_ft;

            x_inlet_entry = BrandtBalanceStabControl.engineField_(obj.inp.engine, 'inlet_entry_x_ft', 15.0);
            duct_length = BrandtBalanceStabControl.engineField_(obj.inp.engine, 'duct_length_ft', 14.0);
            x_nozzle_exit = x_inlet_entry + obj.geom.nozzle_x_ft;
            x_inlet_exit = x_inlet_entry + duct_length;
            T_dry = BrandtBalanceStabControl.engineField_(obj.inp.engine, 'T_dry_SLS_lb', obj.inp.engine.T_mil_SLS_lb);

            obj.xcg_nacelle_ft = (x_inlet_entry + x_nozzle_exit) / 2;
            if obj.inp.engine.T_AB_SLS_lb ~= T_dry
                obj.xcg_engine_ft = x_inlet_exit + 0.3 * (x_nozzle_exit - x_inlet_exit);
            else
                obj.xcg_engine_ft = (x_inlet_exit + x_nozzle_exit) / 2;
            end

            obj.xcg_gear_ft     = obj.xnp_ft;
            obj.xcg_inlet_ft    = x_inlet_entry + duct_length / 2;
            obj.xcg_ctrl_ft     = obj.xcg_wing_ft;
            obj.xcg_elec_ft     = obj.xcg_engine_ft;
            obj.xcg_hyd_ft      = obj.xcg_engine_ft;
            obj.xcg_ECS_ft      = obj.xcg_wing_ft;
            obj.xcg_other_ft    = 20.0;
            obj.xcg_avionics_ft = 15.0;
            obj.xcg_armament_ft = 26.3;
            obj.xcg_perm_pay_ft = 16.0;
            obj.xcg_exp_pay_ft  = 26.3;
            obj.xcg_fuel2_ft    = 26.3;
            obj.xcg_fuel1_ft    = obj.xcg_fuel2_ft - 2.0;
            obj.xcg_fuel3_ft    = obj.xcg_fuel2_ft + 2.0;

            obj.analyzed_ = true;
        end

        function results = run(obj, W_TO_lb)
            obj.requireAnalyzed_();
            if nargin < 2 || ~isscalar(W_TO_lb) || ~isfinite(W_TO_lb) || W_TO_lb <= 0
                error('LevelBrandt:invalidInput', 'W_TO_lb must be a positive scalar.');
            end

            wt_results = obj.wt.run(W_TO_lb);
            W_fuel = wt_results.W_fuel_lb;

            W = [wt_results.W_wing_lb, wt_results.W_fuse_lb, wt_results.W_pitch_lb, ...
                 wt_results.W_vert_lb, wt_results.W_nacelles_lb, wt_results.W_strakes_lb, ...
                 wt_results.W_engine_lb, wt_results.W_gear_lb, wt_results.W_inlet_duct_lb, ...
                 wt_results.W_ctrl_lb, wt_results.W_elec_lb, wt_results.W_hyd_lb, ...
                 wt_results.W_ECS_lb, wt_results.W_other_lb, wt_results.W_avionics_lb, ...
                 wt_results.W_armament_lb, wt_results.perm_payload_lb, wt_results.exp_payload_lb, ...
                 W_fuel / 3, W_fuel / 3, W_fuel / 3];

            xcg = [obj.xcg_wing_ft, obj.xcg_fuse_ft, obj.xcg_pitch_ft, ...
                   obj.xcg_vert_ft, obj.xcg_nacelle_ft, obj.xcg_strake_ft, ...
                   obj.xcg_engine_ft, obj.xcg_gear_ft, obj.xcg_inlet_ft, ...
                   obj.xcg_ctrl_ft, obj.xcg_elec_ft, obj.xcg_hyd_ft, ...
                   obj.xcg_ECS_ft, obj.xcg_other_ft, obj.xcg_avionics_ft, ...
                   obj.xcg_armament_ft, obj.xcg_perm_pay_ft, obj.xcg_exp_pay_ft, ...
                   obj.xcg_fuel1_ft, obj.xcg_fuel2_ft, obj.xcg_fuel3_ft];

            xcg_balance = xcg;
            xcg_balance(1:16) = xcg_balance(1:16) + obj.balance_datum_shift_ft;

            obj.xcg_TO_ft = sum(W .* xcg_balance) / sum(W);

            W_land = W;
            W_land(18) = 0;
            W_land(19:21) = 0;
            obj.xcg_land_ft = sum(W_land .* xcg_balance) / sum(W_land);

            obj.SM_TO   = (obj.xnp_ft - obj.xcg_TO_ft) / obj.MAC_wing_ft;
            obj.SM_land = (obj.xnp_ft - obj.xcg_land_ft) / obj.MAC_wing_ft;

            x_nose = obj.inp.gear.x_nose_ft;
            x_main = obj.inp.gear.x_main_ft;
            wheelbase = x_main - x_nose;
            obj.gear_main_pct = (obj.xcg_TO_ft - x_nose) / wheelbase * 100;
            obj.gear_nose_pct = (x_main - obj.xcg_TO_ft) / wheelbase * 100;

            z_tail_bottom = obj.inp.fuselage.frames(end).z_ft - obj.inp.fuselage.frames(end).h_ft / 2;
            obj.tipback_deg = atand((obj.inp.gear.h_main_ft + z_tail_bottom) / (obj.inp.fuselage.length_ft - x_main));

            d_axis = obj.inp.gear.y_main_ft * (obj.xcg_TO_ft - x_nose) / sqrt((x_main - x_nose)^2 + obj.inp.gear.y_main_ft^2);
            obj.rollover_deg = atand(obj.inp.gear.h_main_ft / d_axis);

            obj.run_done_ = true;
            results = obj.packResults_();
            obj.validate_run_();
        end
    end

    methods (Access = private)
        function results = packResults_(obj)
            results.xcg_TO_ft = obj.xcg_TO_ft;
            results.xcg_land_ft = obj.xcg_land_ft;
            results.SM_TO = obj.SM_TO;
            results.SM_land = obj.SM_land;
            results.gear_main_pct = obj.gear_main_pct;
            results.gear_nose_pct = obj.gear_nose_pct;
            results.tipback_deg = obj.tipback_deg;
            results.rollover_deg = obj.rollover_deg;
            results.xnp_ft = obj.xnp_ft;
        end

        function requireAnalyzed_(obj)
            if ~obj.analyzed_
                error('LevelBrandt:notAnalyzed', 'Call analyze() before calling run().');
            end
        end

        function validate_run_(obj)
            fields = {'xnp_ft', 'xcg_TO_ft', 'xcg_land_ft', 'gear_main_pct', 'gear_nose_pct'};
            for k = 1:numel(fields)
                val = obj.(fields{k});
                assert(~isnan(val), 'LevelBrandt:nanOutput', '%s is NaN', fields{k});
            end
        end

        function [MAC_ft, xMAC_ft, xac_ft] = surfaceGeom_(obj, c_root_ft, c_tip_ft, span_ft, sweep_LE_deg, x_le_root_ft)
            lambda = c_tip_ft / c_root_ft;
            MAC_ft = (2 / 3) * c_root_ft * (1 + lambda + lambda^2) / (1 + lambda);
            y_MAC = (span_ft / 3) * (1 + 2 * lambda) / (1 + lambda);
            xMAC_ft = x_le_root_ft + y_MAC * tand(sweep_LE_deg);
            xac_ft = xMAC_ft + 0.25 * MAC_ft;
        end

        function CLa_rad = clalpha_(~, AR, ~, sweep_LE_deg)
            sweep_rad = deg2rad(sweep_LE_deg);
            e = 2 / (2 - AR + sqrt(4 + AR^2 * (1 + tan(sweep_rad)^2)));
            CLa_rad = 2 * pi / (1 + 2 * pi / (pi * e * AR));
        end
    end

    methods (Static, Access = private)
        function value = engineField_(engineStruct, fieldName, defaultValue)
            if isfield(engineStruct, fieldName)
                value = engineStruct.(fieldName);
            else
                value = defaultValue;
            end
        end
    end
end
