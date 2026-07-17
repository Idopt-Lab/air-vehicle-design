classdef F16GeomL3 < GeomL3
%F16GEOML3  F-16A Block 10 Level-3 geometry student class.
%
%   Inherits all L3 S_wet formulas from GeomL3.  Sets F-16-specific property
%   values in the constructor; no equations are duplicated here.
%
%   S_wet breakdown (expected for validation):
%     Wing (Roskam Eq. 12.1, tc_r=tc_t=0.04, lambda=0.2275) ≈ 397 ft^2
%     HT  (Roskam Eq. 12.1, tc_r=0.06, tc_t=0.035, lambda=0.390) ≈ 130 ft^2
%     VT  (Roskam Eq. 12.1, tc_r=0.053, tc_t=0.030, lambda=0.437) ≈ 111 ft^2
%     Fuselage (Roskam Eq. 12.3, D=5.0, L=47.5)                   ≈ 645 ft^2
%     Duct (frustum, D_in=3.4, D_exit=2.9, L=14)                   ≈ 139 ft^2
%     Total                                                         ≈ 1422 ft^2
%   Reference: Brandt 1371 ft^2 (+3.7%; duct dimensions are estimated).
%
%   SOURCES:
%     [TO]     T.O. 1F-16A-1, Fig. 1-2, Sec. I
%     [Brandt] Brandt F-16A.xls, Geom sheet

    properties (Constant)
        mainwheel_S_front = (25.5*8.0)/(12^2);   % ft^2  frontal area of main wheels [estimated; TO]
        nosewheel_S_front = (18*5.5)/(12^2);     % ft^2  frontal area of nosewheel   [estimated; TO]
    end

    methods

        function obj = F16GeomL3()
            obj.S_ref          = 300;       % ft^2  [TO Fig. 1-2]
            % ── Fuselage ──────────────────────────────────────────────────── %
            obj.L_fuselage     = 47.5;      % ft    [TO Fig. 1-2]
            obj.W_max_fuselage = 5.0;       % ft    [estimated; TO cross-section ~4.5×5.5 ft]
            obj.H_max_fuselage = 4.5;       % ft    [estimated; TO cross-section, slightly oval]
            obj.D_fus          = 5.0;       % ft    equivalent diameter [≈ W_max_fuselage]
            obj.L_fus          = 47.5;      % ft    [TO Fig. 1-2]
            % ── Wing (NACA 64A204) ─────────────────────────────────────────── %
            obj.S_exposed_wing = 196.4;     % ft^2  [Brandt Geom H7]
            obj.S_wet_wing     = 0;
            obj.QC_sweep_wing  = 37;        % deg   Λ_c/4  [TO Fig. 1-2]
            obj.lambda_wing    = 0.2275;    % —     [TO Fig. 1-2]
            obj.b_wing         = 30;        % ft    [sqrt(AR*S) = sqrt(3*300)]
            obj.AR_wing        = 3.0;       % —     [b^2/S_ref = 900/300]
            obj.LE_sweep_wing  = 40;        % deg   [TO Fig. 1-2]
            obj.TE_sweep_wing  = 0.0;       % deg   [derived]
            obj.c_root_wing    = 16.3;      % ft    [2*S_ref/(b*(1+λ))]
            obj.c_tip_wing     = 3.71;      % ft    [λ*c_root = 0.2275*16.3]
            obj.tc_r_wing      = 0.04;      % —     [NACA 64A204; TO]
            obj.tc_t_wing      = 0.04;      % —     [NACA 64A204; uniform section]
            % ── Horizontal tail (all-moving; biconvex) ──────────────────────── %
            obj.S_exposed_HT   = 63.70;     % ft^2  [TO Block 10]
            obj.S_wet_HT       = 0;
            obj.QC_sweep_HT    = 37;        % deg   [derived]
            obj.lambda_HT      = 0.390;     % —     [TO Fig. 1-2]
            obj.b_HT           = 17.5;      % ft    full span  [estimated; TO cross-sections]
            obj.AR_HT          = 4.81;      % —     [b^2/S = 306.25/63.70]
            obj.LE_sweep_HT    = 40;        % deg   [estimated; TO Sec I]
            obj.TE_sweep_HT    = 25;        % deg   [derived]
            obj.c_root_HT      = 5.24;      % ft    [2*S/(b*(1+λ))]
            obj.c_tip_HT       = 2.04;      % ft    [λ*c_root]
            obj.tc_r_ht        = 0.060;     % —     [TO Sec I; biconvex root ~6%]
            obj.tc_t_ht        = 0.035;     % —     [TO Sec I; biconvex tip ~3.5%]
            % ── Vertical tail (biconvex) ────────────────────────────────────── %
            obj.S_exposed_VT   = 54.75;     % ft^2  [TO]
            obj.S_wet_VT       = 0;
            obj.QC_sweep_VT    = 39;        % deg   [derived from planform; ΛLE=47.5°]
            obj.lambda_VT      = 0.437;     % —     [TO Fig. 1-2]
            obj.b_VT           = 8.9;       % ft    height  [estimated; TO Sec I]
            obj.AR_VT          = 1.45;      % —     [b^2/S = 79.21/54.75]
            obj.LE_sweep_VT    = 47.5;      % deg   [TO; reported]
            obj.TE_sweep_VT    = 1;         % deg   [derived: near-vertical TE]
            obj.c_root_VT      = 8.56;      % ft    [2*S/(b*(1+λ))]
            obj.c_tip_VT       = 3.74;      % ft    [λ*c_root]
            obj.tc_r_vt        = 0.053;     % —     [TO Sec I; biconvex root ~5.3%]
            obj.tc_t_vt        = 0.030;     % —     [TO Sec I; biconvex tip ~3.0%]
            % ── Inlet + engine duct (F100-PW-200) ───────────────────────────── %
            obj.D_inlet        = 3.4;       % ft    [estimated; TO Sec I cross-sections]
            obj.D_exit         = 2.9;       % ft    [estimated; TO Sec I]
            obj.L_duct         = 14.0;      % ft    [estimated]
        end

    end
end
