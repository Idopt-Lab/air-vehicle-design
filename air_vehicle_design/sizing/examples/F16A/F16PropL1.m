classdef F16PropL1 < PropulsionModelL1
%F16PROPL1  F-16A Block 10 Level-1 propulsion student class.
%
%   Inherits from PropulsionModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to PropL1 statics.
%
%   Level-1 model:
%     thrust_lapse — density-ratio law: α = σ^m, m=0.6 (engine-type table)
%                    [Martins AE481 course notes (metabook), Eq. 10.9]
%     TSFC         — categorical: 0.80 1/hr subsonic, 2.20 1/hr supersonic
%                    [Raymer 6th Table 3.3, low-bypass turbofan with AB]
%
%   Validation target:
%     T_SL = 23,770 lbf  [Brandt D29; T.O. 1F-16A-1]
%     α at 36 kft M=0.87: σ^0.6 ≈ 0.484  (no Mach correction at L1)
%
%   SOURCES:
%     [Brandt] Brandt F-16A.xls, sheet "Main", cells C29/D29
%     [TO]     T.O. 1F-16A-1, Sec. I

    properties
        engine_type = "low_bypass_turbofan_AB"   % PropL1 TSFC table key
        T_SL     = 23770                         % lbf — AB (max) SLS thrust  [PropulsionBase contract; Brandt D29; TO]
        T_SL_wet = 23770                         % lbf — alias for T_SL (AB)  [Brandt D29; TO]
        TSFC     = 0                             % 1/hr — populated by get_TSFC(obj, state)
    end

    methods

        function obj = F16PropL1()
            obj.engine_type = "low_bypass_turbofan_AB";
            obj.T_SL     = 23770;
            obj.T_SL_wet = 23770;
        end

        function alpha = thrust_lapse(obj, state)
            alpha = PropL1.get_thrust_lapse(obj, state);
        end

        function c_t = get_TSFC(obj, state)
            c_t = PropL1.get_TSFC(obj, state);
        end

        function alpha = compute_thrust_lapse(obj, state)
            alpha = PropL1.get_thrust_lapse(obj, state);
        end

        function c_t = lookup_TSFC(obj, state)
            c_t = PropL1.get_TSFC(obj, state);
        end

    end

end
