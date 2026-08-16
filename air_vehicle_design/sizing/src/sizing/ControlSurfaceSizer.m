classdef ControlSurfaceSizer < handle
%CONTROLSURFACESIZER  Quick control-surface area estimate
%   (aileron/elevator/rudder), for use in SizingLoopL2.
%
%   Standalone sizing helper, not part of the three-tier discipline
%   pattern (same category as TailSizingLevel1): no per-fidelity equation
%   set to vary.
%
%   METHOD [Raymer 6th ed., AIAA 2018]. Control surfaces run at a constant
%   percent chord along their span (p.162, Fig. 6.4), so area is
%   (chord fraction) x (span fraction) x (reference area):
%     S_ail  = c_ail_frac  * b_ail_frac  * S_ref
%     S_elev = c_elev_frac * b_elev_frac * S_ht
%     S_rud  = c_rud_frac  * b_rud_frac  * S_vt
%
%   Elevator/rudder chord fractions (Ce/C, Cr/C) come from Table 6.5, p.162
%   (Table 6.5 has no aileron column). Aileron chord/span fractions come
%   from Fig. 6.3, p.161, a shaded historical band (chord/wing-chord
%   0.10-0.35, span/wing-span ~0.3-0.9) -- the caller picks a point from
%   that band. Elevator/rudder span fractions default to Raymer's ~90% of
%   tail span (p.161).

    properties (SetAccess = private)
        c_ail_frac  (1,1) double   % aileron chord/wing chord   [Raymer 6th ed. Fig. 6.3]
        b_ail_frac  (1,1) double   % aileron span/wing span     [Raymer 6th ed. Fig. 6.3]
        c_elev_frac (1,1) double   % elevator Ce/C (tail chord) [Raymer 6th ed. Table 6.5]
        b_elev_frac (1,1) double   % elevator span/tail span    [Raymer 6th ed. p.161, ~90%]
        c_rud_frac  (1,1) double   % rudder Cr/C (tail chord)   [Raymer 6th ed. Table 6.5]
        b_rud_frac  (1,1) double   % rudder span/tail span      [Raymer 6th ed. p.161, ~90%]
    end

    methods

        function obj = ControlSurfaceSizer(c_ail_frac, b_ail_frac, c_elev_frac, b_elev_frac, c_rud_frac, b_rud_frac)
        %CONTROLSURFACESIZER  Construct with the six chord/span fractions.
        %   All six required (no aircraft-specific defaults). Zero is legal
        %   for c_elev_frac/b_elev_frac (an all-moving stabilator with no
        %   separate elevator, e.g. the F-16 -- Table 6.5 footnote), so
        %   these are not validated positive.
            arguments
                c_ail_frac  (1,1) double {mustBeNonnegative}
                b_ail_frac  (1,1) double {mustBeNonnegative}
                c_elev_frac (1,1) double {mustBeNonnegative}
                b_elev_frac (1,1) double {mustBeNonnegative}
                c_rud_frac  (1,1) double {mustBeNonnegative}
                b_rud_frac  (1,1) double {mustBeNonnegative}
            end
            obj.c_ail_frac  = c_ail_frac;
            obj.b_ail_frac  = b_ail_frac;
            obj.c_elev_frac = c_elev_frac;
            obj.b_elev_frac = b_elev_frac;
            obj.c_rud_frac  = c_rud_frac;
            obj.b_rud_frac  = b_rud_frac;
        end

        function result = size(obj, geom)
        %SIZE  Aileron/elevator/rudder areas [ft^2] from geom.S_ref/S_ht/S_vt.
        %   geom is duck-typed: S_ht/S_vt are an L2/L3 convention, not part
        %   of GeometryBase's Tier-1 contract.
        %
        %   Returns struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud).
            S_ail  = obj.c_ail_frac  * obj.b_ail_frac  * geom.S_ref;
            S_elev = obj.c_elev_frac * obj.b_elev_frac * geom.S_ht;
            S_rud  = obj.c_rud_frac  * obj.b_rud_frac  * geom.S_vt;
            result = struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud);
        end

    end

end
