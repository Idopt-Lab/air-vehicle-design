classdef (Abstract) PointPerformanceBase < handle
%POINTPERFORMANCEBASE  Abstract base for all constraint-analysis point
%   performance conditions (one point on the T/W-vs-W/S constraint diagram).
%
%   Declares the single method the constraint-analysis aggregator calls
%   (required_TW) as abstract, plus a name property for diagram legends.
%
%   Concrete Layer-1 classes (e.g. ThrustConstraint) implement this directly;
%   there is no per-aircraft subclass -- the aircraft-specific data (altitude,
%   Mach, load factor, weight fraction) is supplied through the constructor,
%   and the physics comes from the aero/prop discipline objects passed in
%   at construction, not hardcoded here.  See ConstraintAnalysis for how a
%   list of these is combined into a design point.
%
%   AVAILABLE/MARGIN: required_TW (and the category-specific WS_max/TW_min
%   it's built from -- see Both_WbyS_TbyW.m/Only_WbyS.m/Only_TbyW.m) is only
%   the "required" side of a constraint: what the flight-condition physics
%   demands, independent of any specific candidate design. The "available"
%   side -- what an actual candidate design (given T_SL, W_TO, S_ref) can
%   actually provide -- and the margin/"wiggle room" between the two are
%   computed by each category's own TW_margin/WS_margin method
%   (Both_WbyS_TbyW.TW_margin, Only_WbyS.WS_margin, Only_TbyW.TW_margin), not
%   here: the natural inputs differ per category (a W/S-wall condition needs
%   no T_SL at all, for instance), so unlike required_TW there is no single
%   uniform signature to declare abstractly at this level. Mirrors
%   NPTEL_Fighter_Aircraft_Sizing.ipynb's compute_constraint methods (cell 9).

    properties (Abstract, SetAccess = protected)
        name    % string -- condition label, e.g. "Max Mach", for diagram legends
    end

    properties (Constant)
        %WS_RANGE_BRANDT  Wing-loading sweep used by Brandt's F-16A.xls
        %   constraint-diagram tables (Consts sheet): 20:7:160 psf, 21 points.
        %   [Brandt F-16A.xls; temp_Casey/src/.../ConstraintAnalysisClass.m
        %   Wto_S_range -- range only, not the (buggy) equation cross-checked
        %   there]. Shared here so every constraint condition sweeps the same
        %   W/S points Brandt used, for diagram/verification parity.
        WS_RANGE_BRANDT = 20:7:160
    end

    methods (Abstract)

        %REQUIRED_TW  Thrust-to-weight ratio required to satisfy this
        %   constraint at the given wing loading(s).
        %   WS -- wing loading W_TO/S_ref, lbf/ft^2 (scalar or array).
        %   Returns TW the same size as WS.
        TW = required_TW(obj, WS)
        % TODO (7/23/2026): Replace with "compute_constraint", which must
        % return the T/W and W/S for the given constraint condition. It
        % must be done by computing the thrust and then the weight.
    end

end