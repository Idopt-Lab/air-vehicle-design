classdef ControlSurfaceSizer < handle
%CONTROLSURFACESIZER  Generic quick control-surface area estimate
%   (aileron/elevator/rudder), for use in SizingLoopL2.
%
%   Not part of the aerodynamics/geometry/weights/propulsion three-tier
%   discipline pattern -- a standalone sizing helper, same category as
%   TailSizingLevel1 (see that class's header): no abstract Base/ModelLN
%   split, since it has no per-fidelity equation set to vary.
%
%   METHOD [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed.,
%   AIAA, 2018]. Control surfaces are tapered to a constant percent chord
%   along their span (p.162, Fig. 6.4), so area is well approximated as
%   (chord fraction) x (span fraction) x (reference area):
%     S_ail  = c_ail_frac  * b_ail_frac  * S_ref
%     S_elev = c_elev_frac * b_elev_frac * S_ht
%     S_rud  = c_rud_frac  * b_rud_frac  * S_vt
%
%   Elevator/rudder chord fractions (c_elev_frac, c_rud_frac) come from
%   Table 6.5, p.162 ("Elevator Ce/C", "Rudder Cr/C" -- NOT an aileron
%   column; Table 6.5 has none). Aileron chord/span fractions come from
%   Fig. 6.3, p.161, a shaded historical-guidelines BAND (chord/wing-chord
%   0.10-0.35 vs. aileron-span/wing-span ~0.3-0.9), not a single value or a
%   per-category table -- callers must pick a representative point from
%   that band (see F16's wiring for the chosen point and why). Elevator/
%   rudder span fractions default to Raymer's stated ~90% of tail span
%   (p.161: "Elevators and rudders generally begin at the side of the
%   fuselage and extend to the tip of the tail or to about 90% of the tail
%   span").
%
%   CORRECTS the original step-8 sizing plan's "S_ail = f_ail x S_ref ...
%   fractions from Table 6.5" -- verified against the actual Raymer text:
%   Table 6.5 has no aileron column at all (aileron is Fig. 6.3, a chart),
%   and its Ce/C, Cr/C entries are TAIL CHORD fractions, not area fractions
%   of S_ht/S_vt directly -- the span-fraction factor above is required to
%   get an area estimate, not just the chord fraction alone.

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
        %   All six required -- no aircraft-specific defaults -- so the
        %   same class serves any aircraft/configuration; see
        %   design_study_02_L2.m for the F-16 wiring. Zero is a legal
        %   c_elev_frac/b_elev_frac (an all-moving stabilator with no
        %   separate elevator, e.g. the F-16 -- Table 6.5's own footnote:
        %   "Supersonic usually all-moving tail without separate
        %   elevator"), so these are NOT validated positive.
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
        %   geom is duck-typed (not strictly type-checked against
        %   GeometryBase): S_ht/S_vt are an L2/L3 convention, not part of
        %   GeometryBase's Tier-1 abstract contract (only S_ref/S_wet are),
        %   matching TailSizingLevel1's b/cbar usage of geom.
        %
        %   Returns struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud)
        %   -- lowercase-first-letter field names matching this framework's
        %   S_ail/S_elev/S_rud property casing (e.g. F16GeomL2.S_ail).
            S_ail  = obj.c_ail_frac  * obj.b_ail_frac  * geom.S_ref;
            S_elev = obj.c_elev_frac * obj.b_elev_frac * geom.S_ht;
            S_rud  = obj.c_rud_frac  * obj.b_rud_frac  * geom.S_vt;
            result = struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud);
        end

    end

end
