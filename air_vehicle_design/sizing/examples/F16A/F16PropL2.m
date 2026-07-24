classdef F16PropL2 < PropulsionModelL2
%F16PROPL2  F-16A Block 10 Level-2 propulsion student class.
%
%   Inherits from PropulsionModelL2 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to PropL2 statics.
%
%   Level-2 model (Mattingly analytical):
%     thrust_lapse — Eq. 2.54 (low-BPR mixed turbofan; TR = 1.07)
%     TSFC         — Eq. 3.12 + 3.55 coefficients
%
%   The base-class method thrust_lapse(obj, state) returns the AB/max lapse
%   (for use with T_SL = T_max).  Call compute_thrust_lapse_mil for mil power.
%   The base-class TSFC(obj, state) returns mil-power TSFC for Breguet equations.
%
%   Validation targets:
%     T_SL     = 23,770 lbf  [Brandt D29; TO]
%     T_SL_mil = 15,000 lbf  [Brandt C29; TO]
%     TR       = 1.0         [Mattingly Eq. D.6; T_t4_max=2566°F (Table C.4); T_t4_SLS unknown]
%     α_AB at 36 kft M=0.87: ≈ δ₀ ≈ 0.37  (θ₀≈0.867 < TR=1.0, so α_AB = δ₀)
%     TSFC_mil at SLS M=0: (0.90 + 0.30·0)·√1 = 0.90 1/hr
%       (vs. Brandt 0.70 1/hr — Mattingly over-predicts SLS static; correct trend vs. alt/Mach)
%
%   SOURCES:
%     [Brandt]    Brandt F-16A.xls, sheet "Main", cells C29/D29/C30/D30
%     [TO]        T.O. 1F-16A-1, Sec. I
%     [Mattingly] J.D. Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002

    properties (Constant)
        C1_mil = 0.90    % Mattingly Eq. 3.55a — mil-power TSFC coefficient 1
        C2_mil = 0.30    % Mattingly Eq. 3.55a — mil-power TSFC coefficient 2
        C1_AB  = 1.60    % Mattingly Eq. 3.55b — AB TSFC coefficient 1
        C2_AB  = 0.27    % Mattingly Eq. 3.55b — AB TSFC coefficient 2
        C1     = 0.90    % [PropulsionModelL2 contract] mil-power C1 (= C1_mil)  [Mattingly Eq. 3.55a]
        C2     = 0.30    % [PropulsionModelL2 contract] mil-power C2 (= C2_mil)  [Mattingly Eq. 3.55a]
    end

    properties
        T_SL     = 23770   % lbf — AB (max) SLS thrust  [PropulsionBase contract; Brandt D29; TO]
        T_SL_wet = 23770   % lbf — alias for T_SL (AB)  [Brandt D29; TO]
        % TODO (7/13/2026): Use either "_ab" or "_wet" to indicate "afterburner". consistent application across program.
        T_SL_mil = 15000   % lbf — mil SLS thrust        [Brandt C29; TO]
        TR               % —   — throttle ratio, computed via PropL2.compute_TR [Mattingly Eq. D.6]
        TSFC     = 0     % 1/hr — populated by get_TSFC(obj, state)
    end

    methods

        function obj = F16PropL2()
            obj.T_SL     = 23770;
            obj.T_SL_wet = 23770;
            obj.T_SL_mil = 15000;
            T_t4_max_R   = 2566 + 459.67;          % °F → °R  [Mattingly Table C.4]
            obj.TR       = PropL2.compute_TR(T_t4_max_R);  % T_t4_SLS unknown → TR = 1.0
        end

        function alpha = thrust_lapse(obj, state)
            alpha = PropL2.get_thrust_lapse(obj, state);
        end

        function c_t = get_TSFC(obj, state)
            c_t = PropL2.get_TSFC(obj, state);
        end

        function alpha = compute_thrust_lapse_mil(obj, state)
            alpha = PropL2.get_thrust_lapse_mil(obj, state);
        end

        function alpha = thrust_lapse_mil_on_AB_scale(obj, state)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  Mil lapse on AB T_SL scale.
        %   [Mattingly Eq. 2.54b; renormalized per Brandt F-16A.xls Consts
        %   col AU convention -- see PropulsionBase.m.]
            alpha = PropL2.get_thrust_lapse_mil_on_AB_scale(obj, state);
        end

        function alpha = compute_thrust_lapse_AB(obj, state)
            alpha = PropL2.get_thrust_lapse_AB(obj, state);
        end

        function c_t = compute_TSFC_mil(obj, state)
            c_t = PropL2.get_TSFC_mil(obj, state);
        end

        function c_t = compute_TSFC_AB(obj, state)
            c_t = PropL2.get_TSFC_AB(obj, state);
        end

    end

end
