classdef (Abstract) PointPerformanceBase < handle
%POINTPERFORMANCEBASE  Abstract base for all constraint-analysis point
%   performance conditions (one point on the T/W-vs-W/S constraint diagram).
%
%   Declares the ONE method every concrete constraint must expose as
%   abstract:
%     constraint_residual(dp)  -- a single, uniform feasibility measure at a
%                                 candidate DesignPoint dp.
%   Plus a name property for diagram legends.
%
%   required_TW IS DELIBERATELY NOT ON THIS BASE (2026-08-04). A "required
%   T/W" only makes sense for a condition that actually imposes a
%   thrust-to-weight demand -- the Both_WbyS_TbyW subtree (Master-Equation
%   thrust conditions and takeoff) and the flat-floor Only_TbyW category.
%   A W/S-only wall (Only_WbyS: Landing, Stall) has NO required T/W at all;
%   forcing it to fake one (the old 0/Inf "wall curve" hack) was the defect
%   this refactor removes. required_TW is therefore declared only where it
%   is real -- abstract on Both_WbyS_TbyW, concrete on Only_TbyW -- and the
%   aggregator (ConstraintAnalysis) treats an Only_WbyS as an explicit W/S
%   wall via WS_max() rather than a curve. See
%   sizing/docs/subplans/06_constraint_analysis_refactor.md T9.
%
%   Concrete Layer-1 classes (e.g. LevelFlightConstraint, TakeoffConstraint,
%   LandingConstraint) implement the residual through their category; there
%   is no per-aircraft subclass -- the aircraft-specific data (altitude,
%   Mach, load factor, weight fraction) is supplied through the constructor,
%   and the physics comes from the aero/prop discipline objects passed in
%   at construction, not hardcoded here.  See ConstraintAnalysis for how a
%   list of these is combined into a design point.
%
%   REQUIRED vs. FEASIBILITY: the category-specific required_TW/WS_max/
%   TW_min bounds (see Both_WbyS_TbyW.m/Only_WbyS.m/Only_TbyW.m) are only the
%   "required" side of a constraint: what the flight-condition physics
%   demands, independent of any specific candidate design. To measure whether a
%   given candidate design (a DesignPoint carrying T_SL, W_TO, S_ref) actually
%   meets the condition, call constraint_residual(dp).
%
%   FEASIBILITY CONVENTION -- signed residual g, g <= 0 FEASIBLE. Every
%   category implements constraint_residual(dp) to return one signed scalar
%
%       g = required - available    (g <= 0 feasible, g > 0 infeasible),
%
%   on the sea-level-static T_SL/W_TO basis (no thrust-lapse alpha scaling).
%   This is the fmincon nonlcon sign convention: the Step-8 sizing optimizer
%   builds one DesignPoint per candidate and feeds it to every constraint, and
%   a candidate is feasible only where g <= 0 for all of them. Because
%   g = -margin, any caller wanting a ">= 0 is safe" margin uses
%   -constraint_residual(dp). Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
%   compute_constraint methods (cell 9), whose own residual is likewise
%   required - available, feasible <= 0.

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

        %CONSTRAINT_RESIDUAL  Signed feasibility residual at a candidate
        %   DesignPoint dp. Returns one scalar g = required - available, with
        %   g <= 0 FEASIBLE and g > 0 infeasible, on the SL-static T_SL/W_TO
        %   basis (no alpha scaling). g = -margin. Each category defines
        %   "required" and "available" per its own governing bound -- see the
        %   per-category implementations (Both_WbyS_TbyW, Only_WbyS,
        %   Only_TbyW). Mirrors NPTEL_Fighter_Aircraft_Sizing.ipynb's
        %   compute_constraint (cell 9).
        g = constraint_residual(obj, dp)
    end

end
