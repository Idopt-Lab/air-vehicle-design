classdef (Abstract) Both_WbyS_TbyW < PointPerformanceBase
%BOTH_WBYS_TBYW  Abstract category for point-performance conditions whose
%   required T/W depends on wing loading W/S -- the Mattingly "Master
%   Equation" point-performance conditions (cruise, turn, dash, climb,
%   takeoff, ...).
%
%   Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's Both_WbyS_TbyW class -- see
%   Only_WbyS.m's header for the three-category grouping this and its
%   siblings (Only_WbyS, Only_TbyW) implement.
%
%   EQUATION [Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002 -- the
%   point-performance "Master Equation" specialized to steady, wings-level
%   flight; see ThrustConstraint.m's header for the full A/B/C/D derivation
%   and citation]:
%
%     T_SL/W_TO = A/(W_TO/S) + B*(W_TO/S) + C + D
%
%   A concrete subclass supplies A, B, C, D (each a scalar, computed from its
%   own condition's state/aero/prop -- e.g. ThrustConstraint's general
%   continuous-flight case, where all four terms are live, or
%   TakeoffConstraint's ground-roll specialization, where A=C=D=0 and only B
%   survives); this class assembles them into required_TW(WS).

    methods (Abstract, Access = protected)
        A = compute_A(obj)
        B = compute_B(obj)
        C = compute_C(obj)
        D = compute_D(obj)
    end

    methods

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required at wing loading(s) WS [lbf/ft^2], per the
        %   Master Equation assembled from this condition's A/B/C/D terms.
        %   WS may be scalar or array; TW is returned the same size.
            TW = obj.compute_A() ./ WS + obj.compute_B() .* WS + obj.compute_C() + obj.compute_D();
        end

    end

end
