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

        %GET_ALPHA  Thrust lapse alpha this condition's own required_TW uses
        %   internally (e.g. ThrustConstraint's AB/mil basis selection,
        %   TakeoffConstraint's plain AB-basis lapse). Declared here (not
        %   just used privately inside each compute_A/B/C/D) so TW_margin
        %   below can read the exact same alpha value -- never an
        %   independently-supplied one that could disagree with it.
        alpha = get_alpha(obj)
    end

    methods

        function TW = required_TW(obj, WS)
        %REQUIRED_TW  T/W required at wing loading(s) WS [lbf/ft^2], per the
        %   Master Equation assembled from this condition's A/B/C/D terms.
        %   WS may be scalar or array; TW is returned the same size.
            TW = obj.compute_A() ./ WS + obj.compute_B() .* WS + obj.compute_C() + obj.compute_D();
        end

        function [margin, TW_available, TW_required] = TW_margin(obj, WS_actual, T_SL, W_TO)
        %TW_MARGIN  Extra thrust-to-weight "wiggle room" a candidate design
        %   has at this condition, beyond what required_TW demands.
        %
        %   [Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   Both_WbyS_TbyW.compute_constraint (cell 9): TbyW_actual =
        %   Tsl_N/Wto_kg, labeled "Available"; TbyW_necessary =
        %   compute_TbyW(WbyS), labeled "Required"; the notebook's own
        %   constraint = necessary - actual (feasible <= 0). This method
        %   returns the negative of that residual -- margin = available -
        %   required -- so margin >= 0 reads directly as "feasible, with
        %   this much T/W to spare," per PointPerformanceBase.m's "wiggle
        %   room" framing. required_TW is a LOWER bound (a condition demands
        %   AT LEAST this much T/W), so "more available than required" is
        %   the safe direction -- contrast Only_WbyS.WS_margin, whose
        %   WS_max is an UPPER bound and therefore has the opposite-signed
        %   formula for the same "margin >= 0 is safe" convention.]
        %
        %   TW_available is the ACTUAL thrust the engine delivers AT THIS
        %   CONDITION's altitude/Mach/power-setting -- T_SL lapsed by
        %   get_alpha(), not the flat installed T_SL -- so, unlike a plain
        %   T_SL/W_TO, it genuinely varies from condition to condition (an
        %   engine makes less real thrust at 50,000 ft than at sea level).
        %   required_TW is rescaled by that SAME alpha so both sides land on
        %   one consistent "actual thrust delivered/needed at this
        %   condition" basis (required_TW's own A/B/C/D divide thrust by
        %   alpha to express it on the SL-static axis -- multiplying back by
        %   alpha here undoes exactly that, recovering the actual-thrust
        %   requirement). Using the SAME alpha (obj.get_alpha(), the one
        %   required_TW already uses internally) on both sides is what keeps
        %   this consistent -- an independently-supplied alpha could
        %   disagree with it (same class of bug the Cruise mil/AB fix
        %   fixed, see ThrustConstraint.m's get_alpha). Because alpha is a
        %   strictly positive common factor, the margin's zero-crossing --
        %   and therefore every feasibility conclusion -- is identical to
        %   the flat-T_SL formulation; only the reported number changes
        %   (scaled by alpha), not which designs pass or fail.
        %
        %   WS_actual  -- the candidate design's actual wing loading
        %                 W_TO/S_ref [lbf/ft^2] -- a single design point,
        %                 NOT a swept range (e.g. from GeometryBase.S_ref
        %                 and WeightsBase.W_TO).
        %   T_SL       -- the candidate design's actual sea-level-static
        %                 thrust [lbf] (e.g. PropulsionBase.T_SL).
        %   W_TO       -- the candidate design's actual gross takeoff
        %                 weight [lbf] (e.g. WeightsBase.W_TO).
        %   Returns margin = TW_available - TW_required, where TW_available
        %   = alpha*T_SL/W_TO and TW_required = alpha*required_TW(WS_actual)
        %   -- both returned as optional 2nd/3rd outputs so callers (tests
        %   in particular) can inspect the two values a margin was computed
        %   from, not just their difference. margin >= 0 means the design
        %   meets or exceeds this condition's requirement; margin < 0 means
        %   it falls short by that much (actual, at-this-condition) T/W.
            arguments
                obj
                WS_actual (1,1) double {mustBePositive}
                T_SL      (1,1) double {mustBePositive}
                W_TO      (1,1) double {mustBePositive}
            end
            alpha = obj.get_alpha();
            TW_available = alpha * T_SL / W_TO;
            TW_required  = alpha * obj.required_TW(WS_actual);
            margin = TW_available - TW_required;
        end
    end
end