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
%   at construction, not hardcoded here.  See ConstraintAnalysis (aggregator,
%   not yet implemented) for how a list of these is combined into a design
%   point.

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

    end

end
