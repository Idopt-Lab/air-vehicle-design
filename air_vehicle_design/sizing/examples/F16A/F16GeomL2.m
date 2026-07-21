classdef F16GeomL2 < GeometryModelL2
%F16GEOML2  F-16A Block 10 Level-2 geometry student class.
%
%   Inherits from GeometryModelL2 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to GeomL2 statics — no formulas
%   are duplicated here.
%
%   Inheritance: GeometryBase → GeometryModelL2 → F16GeomL2
%
%   S_wet breakdown (expected for validation):
%     Wing:      196.4 * (1.977 + 0.52*0.04)  = 392.4 ft^2
%     HT:         63.7 * (1.977 + 0.52*0.048) = 127.5 ft^2
%     VT:         54.75* (1.977 + 0.52*0.042) = 109.4 ft^2
%     Fuselage:  (Roskam Eq. 12.3, D=5.0, L=47.5) = 644.7 ft^2
%     Total:                                  = 1274.0 ft^2
%   Reference: Brandt F-16A.xls Main!L3 → 1371 ft^2 (7% below; statistical)
%
%   SOURCES:
%     [TO]     T.O. 1F-16A-1, Fig. 1-2, Block 10
%     [Brandt] Brandt F-16A.xls, Geom sheet

    properties
        S_ref          = 300       % ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        S_wet          = 0         % ft^2  — populated by get_S_wet()

        % Wing (NACA 64A204; uniform t/c = 4%)
        S_exposed_wing = 196.4     % ft^2  [Brandt Geom H7]
        S_wet_wing     = 0         % ft^2  — populated by get_S_wet_wing()
        tc_wing        = 0.04      % —     [NACA 64A204; TO]
        QC_sweep_wing  = 37        % deg   Λ_c/4  [derived from planform]
        lambda_wing    = 0.2275    % —     [TO Fig. 1-2]
        b_wing         = 30        % ft    [sqrt(AR*S) = sqrt(3*300)]
        AR_wing        = 3.0       % —     [b^2/S_ref = 900/300]
        LE_sweep_wing  = 40        % deg   [TO Fig. 1-2]
        TE_sweep_wing  = 0.0       % deg   [derived]
        c_root_wing    = 16.3      % ft    [2*S_ref/(b*(1+λ))]
        c_tip_wing     = 3.71      % ft    [λ*c_root]

        % Horizontal tail (all-moving; biconvex; ~6% root, ~3.5% tip)
        S_exposed_ht   = 63.70     % ft^2  [TO, Block 10]
        tc_ht          = 0.048     % —     average; TO Sec I

        % Vertical tail (biconvex; ~5.3% root, ~3.0% tip)
        S_exposed_vt   = 54.75     % ft^2  [TO]
        tc_vt          = 0.042     % —     average; TO Sec I

        % Fuselage (equivalent cylindrical midsection)
        L_fuselage     = 47.5      % ft    (same as L_fus)
        W_max_fuselage = 5.0       % ft    [estimated; TO cross-section ~4.5×5.5 ft]
        H_max_fuselage = 4.5       % ft    [estimated; TO cross-section]
        D_fus          = 5.0       % ft    [estimated; TO cross-section ~4.5×5.5 ft]
        L_fus          = 47.5      % ft    [TO, Fig. 1-2]
    end

    methods

        function obj = F16GeomL2()
        end

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, W_TO)
            val = GeomL2.get_S_wet(obj, W_TO);
        end

        function val = get_S_wet_wing(obj)
            val = GeomL2.get_S_wet_wing(obj);
        end

        function val = get_S_wet_HT(obj)
            val = GeomL2.get_S_wet_HT(obj);
        end

        function val = get_S_wet_VT(obj)
            val = GeomL2.get_S_wet_VT(obj);
        end

        function val = get_S_wet_fuselage(obj)
            val = GeomL2.get_S_wet_fuselage(obj);
        end

    end
end
