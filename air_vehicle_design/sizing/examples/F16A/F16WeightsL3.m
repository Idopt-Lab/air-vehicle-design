classdef F16WeightsL3 < WeightsModelL3
%F16WEIGHTSL3  F-16A Block 10 Level-3 weight estimation student class.
%
%   Inherits from WeightsModelL3 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to WeightsL3 statics.
%
%   METHOD: Raymer §15.3.1 Fighter/Attack component-buildup (Eqs. 15.1–15.24).
%
%   SOURCES:
%     [TO]    T.O. 1F-16A-1, Flight Manual, USAF/EPAF F-16A/B Blocks 10/15.
%     [Brandt] S. Brandt, F-16A.xls workbook.
%     [Raymer] D.P. Raymer, Aircraft Design 6th ed., AIAA, 2018, §15.3.1.
%
%   PARAMETER STATUS LEGEND:
%     [TO]       — from T.O. 1F-16A-1 directly
%     [Brandt]   — from Brandt F-16A.xls
%     [derived]  — computed from cited sources
%     [estimate] — engineering estimate; verify before citing
%     [code]     — from prior working WeightLevel3.m implementation
%     [Raymer]   — Raymer definition / category constant

    properties

        % ================================================================== %
        %  WEIGHTSBASE ABSTRACT PROPERTIES (sizing-loop closure variables)
        % ================================================================== %
        W_TO               = NaN      % candidate gross takeoff weight [lbf]; set by sizing loop
        W_energy           = 6296.3   % internal fuel [lbf]                   [Brandt B6]
        W_payload_expendable = 0      % expendable payload [lbf]; set by mission profile
        W_payload_fixed    = 220      % fixed equipment + crew [lbf; estimate: 1 pilot + survival gear]

        % ================================================================== %
        %  WEIGHTSMODELG3 ABSTRACT PROPERTIES (computed component totals)
        % ================================================================== %
        W_wings           = NaN   % wing structural weight [lbf]; set by weight_wing
        W_tail            = NaN   % tail weight struct(HT,VT) [lbf]; set by weight_tail
        W_fuselage        = NaN   % fuselage structural weight [lbf]; set by weight_fuselage
        W_installed_engine = NaN  % engine section group total [lbf]; set by weight_engine_section
        W_subsystems      = NaN   % systems group total [lbf]; set by weight_systems

        % ================================================================== %
        %  STRUCTURAL GROUP INPUTS
        % ================================================================== %

        % --- Wing (Eq. 15.1) ---
        N_z        = 13.5     % --    ultimate load factor = 1.5 × 9g limit  [TO 1F-16A-1 §5, Raymer Nz=1.5×n_lim]
        S_w        = 300      % ft²   wing reference area  [TO 1F-16A-1, Fig. 1-2]
        AR_w       = 3.0      % --    wing aspect ratio    [TO 1F-16A-1, Fig. 1-2]
        tc_root    = 0.04     % --    root thickness ratio [NACA 64A204]
        lambda_w   = 0.2275   % --    wing taper ratio     [TO 1F-16A-1, Fig. 1-2]
        Lambda_LE_w = 40      % deg   LE sweep             [TO 1F-16A-1, Fig. 1-2]
        S_csw      = 69.0     % ft²   wing control-surface area [estimate; from WeightLevel3.m hardcode; verify TO 1F-16A-1]
        K_dw       = 1.0      % --    not a delta wing     [Raymer]
        K_vs       = 1.0      % --    not variable sweep   [Raymer]

        % --- Horizontal tail (Eq. 15.2) ---
        S_ht       = 63.70    % ft²   HT area              [TO 1F-16A-1]
        AR_ht      = 2.114    % --    HT aspect ratio      [Brandt / TO 1F-16A-1]
        lambda_ht  = 0.390    % --    HT taper             [Brandt / TO 1F-16A-1]
        F_w        = 7.0      % ft    fuselage width at HT [Brandt, b.geom.W_fus]
        B_h        = 11.61    % ft    HT full span = sqrt(AR_ht × S_ht) [derived]
        K_rht      = 1.047    % --    rolling (all-moving) tail [Raymer §15.3]

        % --- Vertical tail (Eq. 15.3) ---
        S_vt       = 54.75    % ft²   VT area              [TO 1F-16A-1]
        AR_vt      = 1.294    % --    VT aspect ratio      [Brandt / TO 1F-16A-1]
        lambda_vt  = 0.437    % --    VT taper             [Brandt / TO 1F-16A-1]
        Lambda_LE_vt = 47.5   % deg   VT LE sweep          [TO 1F-16A-1]
        H_t        = 0        % ft    HT height above fuselage CL  [F-16 conventional (non-T) tail]
        H_v        = 1        % ft    any nonzero; H_t/H_v = 0  [F-16 conventional tail]
        M_design   = 2.0      % --    max Mach             [Brandt polar_model]
        L_t        = 22.0     % ft    wing ¼MAC to HT ¼MAC [estimate; verify TO 1F-16A-1]
        S_r        = 50.0     % ft²   VT rudder area       [estimate; from WeightLevel3.m code]
        K_dwf      = 1.0      % --    not a delta wing fuselage [Raymer]

        % --- Fuselage (Eq. 15.4) ---
        L_fus      = 47.5     % ft    fuselage length (excl. probe) [TO 1F-16A-1]
        D_fus      = 5.0      % ft    max fuselage depth   [estimate; verify TO 1F-16A-1 cross-section]
        W_fus      = 7.0      % ft    max fuselage width   [TO 1F-16A-1 / Brandt, b.geom.W_fus]

        % ================================================================== %
        %  LANDING GEAR INPUTS
        % ================================================================== %
        W_l        = 20681    % lbf   landing weight       [Brandt B41]
        N_l        = 2.67     % --    landing load factor  [standard military; verify TO 1F-16A-1 §5]
        L_m        = 5.5      % ft    main gear strut length [estimate; verify TO 1F-16A-1]
        L_n        = 3.5      % ft    nose gear strut length [estimate; verify TO 1F-16A-1]
        K_cb       = 1.0      % --    not carrier-based    [Raymer]
        K_tpg      = 1.0      % --    not kneeling gear    [Raymer]
        N_nw       = 1        % --    nose wheels          [TO 1F-16A-1]

        % ================================================================== %
        %  ENGINE SECTION INPUTS
        % ================================================================== %
        N_en       = 1        % --    number of engines    [TO 1F-16A-1]
        T_max      = 23770    % lbf   SLS AB thrust        [Brandt D29]
        W_en       = 3030     % lbf   engine dry weight    [estimate; verify TO 1F-16A-1 or Jane's All the World's Aircraft]
        S_fw       = 0        % ft²   firewall area (no piston firewall on jet) [Raymer note]
        D_e        = 3.33     % ft    engine exit nozzle diameter ≈40 in [estimate; verify TO 1F-16A-1 §Engine]
        L_tp       = 4.5      % ft    tailpipe length      [estimate; verify TO 1F-16A-1]
        L_sh       = 8.0      % ft    engine shroud length [estimate]
        L_ec       = 5.0      % ft    engine controls run  [estimate]
        K_vg       = 1.0      % --    fixed-geometry inlet [Raymer; F-16 has fixed DSI-like inlet]
        L_d        = 7.5      % ft    inlet duct length    [estimate; F-16 ventral inlet to engine face]
        K_d        = 1.0      % --    inlet geometry factor [Raymer; use 1.0 as baseline; verify from §15.3.1]
        L_s        = 3.0      % ft    splitter length      [estimate]

        % ================================================================== %
        %  SYSTEMS INPUTS
        % ================================================================== %
        % --- Fuel system (Eq. 15.16) ---
        V_t        = 940      % gal   total internal fuel volume [derived: 6296 lbf ÷ 6.7 lb/gal ≈ 940 gal; Brandt B6]
        V_i        = 500      % gal   integral (wing) tank volume [estimate; F-16 wing integral tanks]
        V_p        = 0        % gal   pressurized tank volume [estimate]
        N_t        = 3        % --    number of tanks (2 wing + 1 fuselage) [estimate; verify TO 1F-16A-1]
        SFC_mission = 0.70    % 1/hr  mil-power SFC for structural sizing [Brandt C30]

        % --- Flight controls (Eq. 15.17) ---
        S_cs       = 190      % ft²   total control surface area [estimate: flaperon+HT+rudder+LEF]
        N_s        = 4        % --    no. of control surfaces (flaperon, stab, rudder, LEF) [estimate]
        N_c        = 1        % --    no. of cockpits (single-seat)

        % --- Instruments (Eq. 15.18) ---
        N_ci       = 3        % --    no. of comm/ID items [estimate; F-16 Block 10]

        % --- Hydraulics (Eq. 15.19) ---
        K_vsh      = 1.0      % --    no variable-sweep hydraulics [Raymer]
        N_u        = 5        % --    no. of hydraulic utility functions [estimate]

        % --- Electrical (Eq. 15.20) ---
        K_mc       = 1.0      % --    ≤2 generators [Raymer]
        R_kva      = 80       % kVA   generator power [estimate; F-16 Block 10 ≈ 60-80 kVA]
        L_a        = 10.0     % ft    electrical lead length [estimate]
        N_gen      = 1        % --    number of generators [TO 1F-16A-1]

        % --- Avionics (Eq. 15.21) ---
        W_uav      = 1500     % lbf   uninstalled avionics [estimate; F-16 Block 10 simple suite]

    end

    methods

        function obj = F16WeightsL3()
            obj.B_h = sqrt(obj.AR_ht * obj.S_ht);  % 11.61 ft [derived]
        end

        function oew = OEW(obj, W_TO)
            oew = WeightsL3.OEW(obj, W_TO);
        end

        function W = weight_wing(obj, W_TO)
            W = WeightsL3.weight_wing(obj, W_TO);
        end

        function W = weight_tail(obj, W_TO)
            W = WeightsL3.weight_tail(obj, W_TO);
        end

        function W = weight_fuselage(obj, W_TO)
            W = WeightsL3.weight_fuselage(obj, W_TO);
        end

        function W = weight_landing_gear(obj)
            W = WeightsL3.weight_landing_gear(obj);
        end

        function W = weight_engine_section(obj, W_TO)
            W = WeightsL3.weight_engine_section(obj, W_TO);
        end

        function W = weight_systems(obj, W_TO)
            W = WeightsL3.weight_systems(obj, W_TO);
        end

    end

end
