classdef BrandtWeight < handle
% BrandtWeight  Component weight estimate (Brandt 1997, Wt tab A14:B38).
%
% Implements the three-tier pattern:
%   constructor(geom)  — store inputs from BrandtGeometry; init NaN properties
%   analyze()          — geometry-dependent structural weights (no W_TO needed)
%   run(W_TO_lb)       — W_TO-dependent weights, OEW, fuel; returns results struct
%
% WEIGHT FORMULA REFERENCES (Wt tab, Brandt 1997):
%
%   Structural weights (Wt C9:H9):
%     W_wing     = S_ref × (k_wing/7) × 0.04 × n_ult^0.2 × AR^1.8 × √(1+λ)
%                  / t_c^0.7 / cos(Λ_LE) × scale                        (Wt C9)
%     W_fuse     = k_fuse × S_wet_fuse × MAX(1, L/(√(w·h)·19)) × scale  (Wt D9)
%     W_pitch    = k_pitch × S_pitch × scale                             (Wt E9)
%     W_vert     = k_vert × S_vert × scale × MAX(1+I_twin, 1)           (Wt F9)
%     W_nacelles = k_nac × S_nac_eff × scale                            (Wt G9)
%     W_strakes  = k_strake × S_strakes × scale                          (Wt H9)
%
%   Weight factors (Wt row 7):
%     k_wing=6.75, k_fuse=5.0, k_pitch=6.0, k_vert=6.0, k_nac=4.5, k_strake=4.5
%
%   Engine weight:   W_engine = 0.199 × T_sl_AB     (Wt B11/B22)
%   Structure total: W_structure = SUM(C9:H9)        (Wt B9)
%
%   W_TO-dependent systems (Wt B23:B31):
%     W_gear     = 0.034 × W_TO                                          (Wt B23)
%     W_inlet    = 3.9 × W_nacelles                                      (Wt B24)
%     W_ctrl     = 0.012 × W_TO + (S_LE_flap/S_wing) × 6.75 × 200      (Wt B25)
%     W_elec     = 0.017 × W_TO                                          (Wt B26)
%     W_hyd      = 0.0117 × W_TO                                         (Wt B27)
%     W_ECS      = 0.0115 × W_TO                                         (Wt B28)
%     W_other    = 0.30 × W_structure                                    (Wt B29)
%     W_avionics = 0.081 × W_TO                                          (Wt B30)
%     W_armament = 0.10 × W_exp_payload                                  (Wt B31)
%
%   W_airframe = W_structure + SUM(B23:B31)           (Wt B10; engine excluded)
%   W_empty    = W_airframe + W_engine                (Wt B12 = B10 + B11)
%   W_fuel     = W_TO - perm_payload - exp_payload - W_empty  (Wt B6)
%
% ASSUMPTIONS:
%   - Wing loiter factor = MAX(1, (CL_max_clean-CL_cr)/(CD0·8)) = 1 for fighter
%   - Weight scale = Main!O27/100 = 100% (nominal, no scaling)
%   - Single vertical tail: twin-VT penalty factor = 1
%   - Centerline engine (Y-offset=0): nacelle half-buried in fuselage (Geom!B4/2)
%   - Fuselage fineness ratio ≤ 19 for F-16A (MAX correction = 1)
%
% CROSS-TAB DEPENDENCIES (Wt → Main/Geom):
%   Main!B19-B22: wing AR, taper, sweep, airfoil → wing weight
%   Main!Q27: n_ult = 9 (design load factor)
%   Main!O27: weight_scale_pct = 100
%   Main!B31-D32: fuselage L/w/h → fuselage weight
%   Main!O16-O17: perm/exp payload → fuel calculation
%   Geom!B3 (S_wet_fuse_simple): fuselage wetted area for fuselage weight
%   Geom!B4 (S_wet_nacelle_gt): nacelle effective area for nacelle weight
%   Main!F18 (le_flap.S_ft2): LE flap area for controls weight
%
% F-16A GROUND-TRUTH VALUES (Wt tab, W_TO = 31377 lb):
%   W_wing=1785.95  W_fuse=3652.11  W_pitch=648.00  W_vert=360.00
%   W_nacelles=186.82  W_strakes=90.00  W_structure=6722.87
%   W_engine=4730.23  W_gear=1066.82  W_ctrl=472.44
%   W_elec=533.41  W_hyd=367.11  W_ECS=360.84
%   W_other=2016.86  W_avionics=2541.54  W_armament=440.00
%   W_airframe=15250.47  W_empty=19980.70  W_fuel=6296.30
%
% DISCREPANCIES FROM GROUND-TRUTH:
%   Nacelle area uses π vs Excel's 3.1516 → ~0.4% error in W_nacelles.
%   All other deviations < 0.1% (rounding in intermediate calculations).
%   See readme_wt.md for full discussion.
%
% Usage:
%   geom = BrandtGeometry();
%   geom.analyze();
%   wt = BrandtWeight(geom);
%   wt.analyze();
%   r = wt.run(31377);
%   fprintf('OEW = %.1f lb,  W_fuel = %.1f lb\n', r.W_empty_lb, r.W_fuel_lb);

    properties
        inp   (1,1) struct
        geom  (1,1) BrandtGeometry

        % analyze() outputs — geometry-dependent (no W_TO needed)
        W_wing_lb       (1,1) double = NaN  % Wt C9  / C16
        W_fuse_lb       (1,1) double = NaN  % Wt D9  / D17
        W_pitch_lb      (1,1) double = NaN  % Wt E9  / E18
        W_vert_lb       (1,1) double = NaN  % Wt F9  / F19
        W_nacelles_lb   (1,1) double = NaN  % Wt G9  / G20  (uses Geom!B4)
        W_strakes_lb    (1,1) double = NaN  % Wt H9  / H21
        W_structure_lb  (1,1) double = NaN  % Wt B9  = SUM(C9:H9)
        W_engine_lb     (1,1) double = NaN  % Wt B11 / B22  = 0.199×T_sl_AB
        W_inlet_duct_lb (1,1) double = NaN  % Wt B24 = 3.9×W_nacelles

        % run() outputs — W_TO dependent
        W_gear_lb       (1,1) double = NaN  % Wt B23 = 0.034×W_TO
        W_ctrl_lb       (1,1) double = NaN  % Wt B25 = 0.012×W_TO + LE_flap term
        W_elec_lb       (1,1) double = NaN  % Wt B26 = 0.017×W_TO
        W_hyd_lb        (1,1) double = NaN  % Wt B27 = 0.0117×W_TO
        W_ECS_lb        (1,1) double = NaN  % Wt B28 = 0.0115×W_TO
        W_other_lb      (1,1) double = NaN  % Wt B29 = 0.30×W_structure
        W_avionics_lb   (1,1) double = NaN  % Wt B30 = 0.081×W_TO
        W_armament_lb   (1,1) double = NaN  % Wt B31 = 0.10×W_exp_payload
        W_airframe_lb   (1,1) double = NaN  % Wt B10 = struct + systems (no engine)
        W_empty_lb      (1,1) double = NaN  % Wt B12 = B10 + B11 (OEW)
        W_fuel_lb       (1,1) double = NaN  % Wt B6  = W_TO - payload - OEW
        W_TO_lb         (1,1) double = NaN  % W_TO from last run()

        analyzed_ (1,1) logical = false
        run_done_ (1,1) logical = false
    end

    methods
        function obj = BrandtWeight(geom)
            % BrandtWeight  Constructor. Loads inputs; does NOT compute.
            %   wt = BrandtWeight(geom)
            %     geom : analyzed BrandtGeometry handle
            %   wt = BrandtWeight()
            %     auto-creates and analyzes a default BrandtGeometry
            if nargin == 0
                geom = BrandtGeometry();
                geom.analyze();
            end
            obj.geom = geom;
            obj.inp  = geom.inp;   % weight section comes from same JSON
        end

        function analyze(obj)
            % analyze  Compute geometry-dependent weight components.
            % Must be called before run(). Does NOT require W_TO.

            inp   = obj.inp;
            geom  = obj.geom;

            scale = inp.weight.weight_scale_pct / 100;  % Main!O27/100 = 1.0

            % Weight factors (Wt row 7, lb/ft²):
            k_wing   = 6.75;   % Wt!C7
            k_fuse   = 5.0;    % Wt!D7
            k_pitch  = 6.0;    % Wt!E7
            k_vert   = 6.0;    % Wt!F7
            k_nac    = 4.5;    % Wt!G7
            k_strake = 4.5;    % Wt!H7

            % --- Wing weight (Wt C9) ---
            % W = S × (k/7) × 0.04 × n_ult^0.2 × AR^1.8 × √(1+λ) / t_c^0.7 / cos(Λ_LE) × scale
            % Loiter correction = MAX(1, (CL_max_clean-CL_cr)/(CD0·8)) = 1 for fighter.
            w     = inp.wing;
            n_ult = inp.weight.n_design_load;    % Main!Q27 = 9
            W_wing = w.S_ref_ft2 * (k_wing/7) * 0.04 * n_ult^0.2 ...
                * w.AR^1.8 * sqrt(1 + w.taper) / w.tc_ratio^0.7 / cosd(w.sweep_LE_deg) * scale;
            obj.W_wing_lb = W_wing;

            % --- Fuselage weight (Wt D9) ---
            % W = k_fuse × S_wet_fuse × MAX(1, L/(√(w·h)·19)) × scale
            % S_wet_fuse = Geom!B3 (simple model: 5/6 × π × D_avg × L)
            L_fuse = inp.fuselage.length_ft;       % Main!B32 = 46.5 ft
            w_fuse = inp.fuselage.max_width_ft;    % Main!C32 = 7.0 ft
            h_fuse = inp.fuselage.max_height_ft;   % Main!D32 = 5.0 ft
            fineness_factor = max(1.0, (L_fuse / sqrt(w_fuse * h_fuse)) / 19);
            W_fuse = k_fuse * geom.S_wet_fuse_simple_ft2 * scale * fineness_factor;
            obj.W_fuse_lb = W_fuse;

            % --- Pitch control (stabilator) weight (Wt E9) ---
            W_pitch = k_pitch * inp.pitch_ctrl.S_ft2 * scale;
            obj.W_pitch_lb = W_pitch;

            % --- Vertical tail weight (Wt F9) ---
            % Twin-VT penalty: MAX(1+I_twin, 1) where I_twin=1 for twin-VT, 0 otherwise.
            n_vt     = inp.weight.n_vert_tails;
            vt_scale = max(1 + (n_vt > 1), 1);   % =1 single VT, =2 twin VT
            W_vert   = k_vert * inp.vert_tail.S_ft2 * scale * vt_scale;
            obj.W_vert_lb = W_vert;

            % --- Nacelle weight (Wt G9) ---
            % W = k_nac × S_nac_eff × scale
            % S_nac_eff = Geom!B4 = n_eng × D × L × π × E_aft / 2  (formula decoded).
            % BrandtGeometry computes this as S_wet_nacelle_gt_ft2.
            W_nacelles = k_nac * geom.S_wet_nacelle_gt_ft2 * scale;
            obj.W_nacelles_lb = W_nacelles;

            % --- Strake weight (Wt H9) ---
            W_strakes = k_strake * inp.strake.S_ft2 * scale;
            obj.W_strakes_lb = W_strakes;

            % --- Structural total (Wt B9 = SUM(C9:H9)) ---
            obj.W_structure_lb = W_wing + W_fuse + W_pitch + W_vert + W_nacelles + W_strakes;

            % --- Engine weight (Wt B11 / B22) ---
            % W_engine = 0.199 × T_sl_AB  (afterburner engine formula)
            obj.W_engine_lb = 0.199 * inp.engine.T_AB_SLS_lb;

            % --- Inlet duct weight (Wt B24) ---
            % W_inlet = F24 × W_nacelles where F24 = 3.9  (Wt!F24 = 3.9)
            obj.W_inlet_duct_lb = 3.9 * W_nacelles;

            obj.analyzed_ = true;
        end

        function wt_results = run(obj, W_TO_lb)
            % run  Compute W_TO-dependent weight components. Returns results struct.
            %
            %   wt_results = wt.run(W_TO_lb)
            %     W_TO_lb : takeoff gross weight (lb)   — sizing state variable
            %
            % Results struct fields:
            %   W_wing_lb, W_fuse_lb, W_pitch_lb, W_vert_lb, W_nacelles_lb,
            %   W_strakes_lb, W_structure_lb, W_engine_lb, W_inlet_duct_lb,
            %   W_gear_lb, W_ctrl_lb, W_elec_lb, W_hyd_lb, W_ECS_lb,
            %   W_other_lb, W_avionics_lb, W_armament_lb,
            %   W_airframe_lb, W_empty_lb, W_fuel_lb, W_TO_lb
            obj.requireAnalyzed_();

            inp          = obj.inp;
            perm_payload = inp.weight.perm_payload_lb;   % Main!O16 = 700 lb
            exp_payload  = inp.weight.exp_payload_lb;    % Main!O17 = 4400 lb
            S_wing       = inp.wing.S_ref_ft2;           % 300 ft²

            % --- Landing gear (Wt B23) ---
            W_gear = 0.034 * W_TO_lb;
            obj.W_gear_lb = W_gear;

            % --- Controls (Wt B25) --- two-term formula
            % Term 1: base fraction = 0.012 × W_TO
            % Term 2: LE flap structural = (S_LE_flap / S_wing) × k_wing × 200
            %   where S_LE_flap = Main!F18 = BrandtGeometry.le_flap.S_ft2 ≈ 21.314 ft²
            LE_flap_S = obj.geom.le_flap.S_ft2;   % computed by BrandtGeometry
            W_ctrl = 0.012 * W_TO_lb + (LE_flap_S / S_wing) * 6.75 * 200;
            obj.W_ctrl_lb = W_ctrl;

            % --- Electrical (Wt B26) ---
            W_elec = 0.017 * W_TO_lb;
            obj.W_elec_lb = W_elec;

            % --- Hydraulics (Wt B27) ---
            W_hyd = 0.0117 * W_TO_lb;
            obj.W_hyd_lb = W_hyd;

            % --- ECS (Wt B28) ---
            W_ECS = 0.0115 * W_TO_lb;
            obj.W_ECS_lb = W_ECS;

            % --- Other structure (Wt B29) ---
            % Based on W_structure, not W_TO
            W_other = 0.30 * obj.W_structure_lb;
            obj.W_other_lb = W_other;

            % --- Avionics (Wt B30) ---
            W_avionics = 0.081 * W_TO_lb;
            obj.W_avionics_lb = W_avionics;

            % --- Armament (Wt B31) ---
            % Fraction of expendable payload (weapons, external stores)
            W_armament = 0.10 * exp_payload;
            obj.W_armament_lb = W_armament;

            % --- Airframe (Wt B10 = B9 + SUM(B23:B31)) ---
            % NOTE: W_engine is NOT included in airframe; added separately for OEW.
            W_airframe = obj.W_structure_lb + W_gear + obj.W_inlet_duct_lb ...
                + W_ctrl + W_elec + W_hyd + W_ECS + W_other + W_avionics + W_armament;
            obj.W_airframe_lb = W_airframe;

            % --- Empty weight / OEW (Wt B12 = B10 + B11) ---
            W_empty = W_airframe + obj.W_engine_lb;
            obj.W_empty_lb = W_empty;

            % --- Fuel weight (Wt B6 = B3-B4-B5-B12) ---
            W_fuel = W_TO_lb - perm_payload - exp_payload - W_empty;
            obj.W_fuel_lb = W_fuel;

            obj.W_TO_lb   = W_TO_lb;
            obj.run_done_ = true;

            wt_results = obj.packResults_();
            obj.validate_run_();
        end
    end

    methods (Access = private)
        function r = packResults_(obj)
            r.W_wing_lb       = obj.W_wing_lb;
            r.W_fuse_lb       = obj.W_fuse_lb;
            r.W_pitch_lb      = obj.W_pitch_lb;
            r.W_vert_lb       = obj.W_vert_lb;
            r.W_nacelles_lb   = obj.W_nacelles_lb;
            r.W_strakes_lb    = obj.W_strakes_lb;
            r.W_structure_lb  = obj.W_structure_lb;
            r.W_engine_lb     = obj.W_engine_lb;
            r.W_inlet_duct_lb = obj.W_inlet_duct_lb;
            r.W_gear_lb       = obj.W_gear_lb;
            r.W_ctrl_lb       = obj.W_ctrl_lb;
            r.W_elec_lb       = obj.W_elec_lb;
            r.W_hyd_lb        = obj.W_hyd_lb;
            r.W_ECS_lb        = obj.W_ECS_lb;
            r.W_other_lb      = obj.W_other_lb;
            r.W_avionics_lb   = obj.W_avionics_lb;
            r.W_armament_lb   = obj.W_armament_lb;
            r.perm_payload_lb = obj.inp.weight.perm_payload_lb;
            r.exp_payload_lb  = obj.inp.weight.exp_payload_lb;
            r.W_airframe_lb   = obj.W_airframe_lb;
            r.W_empty_lb      = obj.W_empty_lb;
            r.W_fuel_lb       = obj.W_fuel_lb;
            r.W_TO_lb         = obj.W_TO_lb;
        end

        function validate_run_(obj)
            fields = {'W_empty_lb','W_fuel_lb','W_gear_lb','W_structure_lb'};
            for k = 1:numel(fields)
                val = obj.(fields{k});
                assert(~isnan(val), 'LevelBrandt:nanOutput', '%s is NaN', fields{k});
                assert(val > 0,     'LevelBrandt:invalidOutput', '%s must be positive', fields{k});
            end
        end

        function requireAnalyzed_(obj)
            if ~obj.analyzed_
                error('LevelBrandt:notAnalyzed', ...
                    'Call analyze() before calling run().');
            end
        end
    end
end
