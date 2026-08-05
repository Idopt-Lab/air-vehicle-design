classdef (Abstract) PointPerformanceBase < handle
%POINTPERFORMANCEBASE  Abstract base for a constraint-analysis point
%   performance condition (one point on the T/W-vs-W/S constraint diagram).
%
%   Declares the one method every concrete constraint exposes:
%     constraint_residual(dp)  -- a signed feasibility measure at a candidate
%                                 DesignPoint dp.
%   Plus a name property for diagram legends.
%
%   required_TW is NOT declared here. It exists only where a T/W demand is
%   real: abstract on Both_WbyS_TbyW (Master-Equation + takeoff), concrete on
%   Only_TbyW. A W/S-only wall (Only_WbyS: Landing, Stall) has no required T/W;
%   the aggregator (ConstraintAnalysis) reads it as a W/S wall via WS_max().
%
%   Concrete Layer-1 classes (e.g. LevelFlightConstraint, TakeoffConstraint,
%   LandingConstraint) implement the residual through their category. There is
%   no per-aircraft subclass: the condition data (altitude, Mach, load factor,
%   weight fraction) comes through the constructor, and the physics comes from
%   the injected aero/prop discipline objects, not hardcoded here.
%
%   FEASIBILITY CONVENTION -- signed residual g, g <= 0 FEASIBLE. Every
%   category returns one signed scalar
%
%       g = required - available    (g <= 0 feasible, g > 0 infeasible),
%
%   on the sea-level-static T_SL/W_TO basis (no thrust-lapse alpha scaling) --
%   the fmincon nonlcon sign convention. g = -margin, so a caller wanting a
%   ">= 0 is safe" margin uses -constraint_residual(dp). Mirrors
%   NPTEL_Fighter_Aircraft_Sizing.ipynb's compute_constraint (cell 9):
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
