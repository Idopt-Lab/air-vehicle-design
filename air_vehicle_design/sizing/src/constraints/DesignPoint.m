classdef DesignPoint
%DESIGNPOINT  Immutable candidate sizing design point for constraint evaluation.
%
%   dp = DesignPoint(W_TO, T_SL, S_ref) packages the three design variables a
%   point-performance constraint is evaluated at into one typed argument. The
%   Step-8 sizing optimizer builds one DesignPoint per candidate and hands it
%   to every constraint's constraint_residual method (see
%   PointPerformanceBase.constraint_residual).
%
%   Inputs (English units):
%     W_TO  -- gross takeoff weight, lbf
%     T_SL  -- installed sea-level-static thrust, lbf
%     S_ref -- wing reference area, ft^2
%
%   Derived (Dependent, computed on read):
%     WS -- wing loading  W_TO / S_ref, lbf/ft^2
%     TW -- thrust-to-weight ratio  T_SL / W_TO, dimensionless
%
%   VALUE class (not handle): the three inputs are set once in the constructor
%   and are read-only thereafter; WS and TW are recomputed on every read, so a
%   DesignPoint can never carry a stale derived value. Modeled on
%   src/core/AircraftState.m.

    % ------------------------------------------------------------------ %
    properties (SetAccess = private)
        W_TO  (1,1) double   % lbf       -- gross takeoff weight (input)
        T_SL  (1,1) double   % lbf       -- installed sea-level-static thrust (input)
        S_ref (1,1) double   % ft^2      -- wing reference area (input)
    end

    % ------------------------------------------------------------------ %
    properties (Dependent, SetAccess = private)
        WS    % lbf/ft^2 -- wing loading  W_TO / S_ref
        TW    % —        -- thrust-to-weight ratio  T_SL / W_TO
    end

    % ------------------------------------------------------------------ %
    methods
        function obj = DesignPoint(W_TO, T_SL, S_ref)
        %DESIGNPOINT  Construct a candidate design point.
        %
        %   W_TO  -- gross takeoff weight, lbf (must be > 0)
        %   T_SL  -- installed sea-level-static thrust, lbf (must be > 0)
        %   S_ref -- wing reference area, ft^2 (must be > 0)
            arguments
                W_TO  (1,1) double {mustBePositive}
                T_SL  (1,1) double {mustBePositive}
                S_ref (1,1) double {mustBePositive}
            end
            obj.W_TO  = W_TO;
            obj.T_SL  = T_SL;
            obj.S_ref = S_ref;
        end

        function WS = get.WS(obj)
        %GET.WS  Wing loading W_TO / S_ref, lbf/ft^2.
            WS = obj.W_TO / obj.S_ref;
        end

        function TW = get.TW(obj)
        %GET.TW  Thrust-to-weight ratio T_SL / W_TO, dimensionless.
            TW = obj.T_SL / obj.W_TO;
        end
    end
end
