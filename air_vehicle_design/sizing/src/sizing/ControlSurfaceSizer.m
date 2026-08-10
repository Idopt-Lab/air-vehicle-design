classdef ControlSurfaceSizer < handle
%CONTROLSURFACESIZER  Generic quick control-surface area estimate, for use in
%   SizingLoopL2.
%
%   Not part of the aerodynamics/geometry/weights/propulsion three-tier
%   discipline pattern -- a standalone sizing helper, same category as
%   F16TailL1 (see TailSizingBase.m's header): no abstract Base/ModelLN
%   split, since it has no per-fidelity equation set to vary.
%
%   Sizes SIX surfaces, in two families.
%
%   FAMILY 1 -- constant-percent-chord surfaces, sized by chord x span
%   fraction [Raymer, "Aircraft Design: A Conceptual Approach," 6th ed.,
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
%   per-category table -- callers must pick a representative point from that
%   band. Elevator/rudder span fractions default to Raymer's stated ~90% of
%   tail span (p.161: "Elevators and rudders generally begin at the side of
%   the fuselage and extend to the tip of the tail or to about 90% of the
%   tail span").
%
%   FAMILY 2 -- WING FLAPS, added 2026-08-10, sized from SPAN STATIONS on a
%   tapered wing rather than a bare span fraction:
%     S_flaperon = c_flaperon_frac * ratio(eta_flaperon_out, eta_flaperon_in) * S_ref
%     S_lef      = c_lef_frac      * ratio(eta_lef_out,      eta_lef_in)      * S_ref
%   where ratio(...) is AeroL2.compute_S_flapped_ratio [Roskam, "Airplane
%   Design Part II," Eq. 7.10], the fraction of the wing REFERENCE area lying
%   in the device's span band. Multiplying by the chord fraction turns that
%   wing-area fraction into the device's own planform area.
%
%   Why the two families differ: Family 1's bare (chord x span) product
%   ignores wing taper, so it silently overestimates an outboard surface on a
%   sharply tapered wing (the F-16's taper is 0.2275). Roskam Eq. 7.10 carries
%   the taper term explicitly and needs the two END STATIONS, not just the
%   extent -- an outboard-mounted 40%-of-semispan flaperon and an inboard one
%   have the same span fraction but different areas. Family 1 is kept
%   unchanged for backward compatibility (F16SandCL3 reads c_elev_frac off
%   this object) and because its inputs are what Raymer's own tables print.
%
%   ★ NOT EVERY SURFACE SIZED HERE IS A CONTROL EFFECTOR. S_lef is the
%   exception: a leading-edge flap is functionally a SLAT -- an automatic
%   stall-prevention / manoeuvre device that a flight control system schedules
%   on angle of attack and dynamic pressure to keep the wing flow attached. It
%   does not respond to pitch, roll or yaw commands. It is sized here, and
%   counted into the geometry's control-surface-area buildups, because it is an
%   actuated surface with real planform area that the weight equations must see
%   (Raymer Eq. 15.1's S_csw, Eq. 15.17's S_cs) -- not because it flies the
%   aircraft. The effectors are S_ail/S_flaperon (roll), S_elev/S_stab (pitch)
%   and S_rud (yaw). This class's name is therefore slightly broader than its
%   contents; renaming it was judged not worth the churn.
%
%   ROLE EXCLUSIVITY -- S_ail vs. S_flaperon. A flaperon IS the roll surface:
%   it serves as both aileron and trailing-edge flap. An airframe therefore
%   declares EITHER an aileron (c_ail_frac > 0, flaperon fractions 0) OR a
%   flaperon (the reverse), never both -- declaring both double-counts one
%   physical surface into two areas and inflates every downstream
%   control-surface-area sum. The constructor rejects that combination
%   rather than letting it through silently. The F-16 is the flaperon case:
%   it has no separate ailerons at all
%   [VnV/BrandtF16A/GroundTruth/f16a_ground_truth.json, takeoff-CLmax note:
%   "the F-16 has no conventional trailing-edge flaps (flaperons + LE flaps
%   only)"].
%
%   ALL-MOVING HORIZONTAL TAIL. Set ht_all_moving = true and the pitch
%   control area is the WHOLE horizontal tail, S_stab = S_ht, with S_elev
%   staying 0 -- there is no separate hinged elevator to size [Raymer
%   Table 6.5's own footnote to the Fighter/attack row: "Supersonic usually
%   all-moving tail without separate elevator"]. S_elev and S_stab are thus
%   mutually exclusive by construction, not by convention: exactly one of
%   them is nonzero for any given airframe. Keeping S_elev = 0 (rather than
%   overloading it with the full tail area) is deliberate -- F16SandCL3's
%   Delta_alpha_L0 reads c_elev_frac and MUST see 0 for an all-moving tail,
%   since Raymer Eqs. 16.16/16.18 describe a hinged flap deflection that does
%   not exist on a stabilator.
%
%   CORRECTS docs/subplans/08_sizing.md's "S_ail = f_ail x S_ref ...
%   fractions from Table 6.5" -- verified against the actual Raymer text:
%   Table 6.5 has no aileron column at all (aileron is Fig. 6.3, a chart),
%   and its Ce/C, Cr/C entries are TAIL CHORD fractions, not area fractions
%   of S_ht/S_vt directly -- the span-fraction factor above is required to
%   get an area estimate, not just the chord fraction alone.
%
%   GROUND TRUTH IS NOT AN INPUT HERE. Every fraction on this object is a
%   textbook ESTIMATE (Raymer Fig. 6.3 / Table 6.5, Roskam Eq. 7.10). The
%   real F-16's measured control-surface areas (T.O. 1F-16A-1 Fig. 1-2:
%   flaperon 31.32, LEF 36.71, rudder 11.65 ft^2) are COMPARISON TARGETS used
%   to measure how accurate those estimates are -- they are never fitted
%   backwards into the fractions below. See examples/F16A/
%   tail_sizing_brandt_comparison.m for the computed-vs-ground-truth table.

    properties (SetAccess = private)
        % -- Family 1: chord x span fraction [Raymer 6th ed. Fig. 6.3 / Table 6.5]
        c_ail_frac  (1,1) double   % aileron chord/wing chord   [Raymer 6th ed. Fig. 6.3]
        b_ail_frac  (1,1) double   % aileron span/wing span     [Raymer 6th ed. Fig. 6.3]
        c_elev_frac (1,1) double   % elevator Ce/C (tail chord) [Raymer 6th ed. Table 6.5]
        b_elev_frac (1,1) double   % elevator span/tail span    [Raymer 6th ed. p.161, ~90%]
        c_rud_frac  (1,1) double   % rudder Cr/C (tail chord)   [Raymer 6th ed. Table 6.5]
        b_rud_frac  (1,1) double   % rudder span/tail span      [Raymer 6th ed. p.161, ~90%]

        % -- Family 2: wing flaps, span stations [Roskam Part II Eq. 7.10]
        c_flaperon_frac   (1,1) double  % flaperon chord/wing chord
        eta_flaperon_in   (1,1) double  % inboard  span station, fraction of semispan
        eta_flaperon_out  (1,1) double  % outboard span station, fraction of semispan
        c_lef_frac        (1,1) double  % leading-edge-flap chord/wing chord
        eta_lef_in        (1,1) double  % inboard  span station, fraction of semispan
        eta_lef_out       (1,1) double  % outboard span station, fraction of semispan

        % -- Configuration flag
        ht_all_moving (1,1) logical  % true -> S_stab = S_ht, S_elev = 0
    end

    methods

        function obj = ControlSurfaceSizer(c_ail_frac, b_ail_frac, c_elev_frac, b_elev_frac, c_rud_frac, b_rud_frac, opts)
        %CONTROLSURFACESIZER  Construct with the six Family-1 chord/span
        %   fractions positionally, plus optional name-value Family-2 (wing
        %   flap) fractions and the all-moving-tail flag.
        %
        %   The six positional arguments are REQUIRED and unchanged from this
        %   class's original signature -- no aircraft-specific defaults -- so
        %   the same class serves any aircraft/configuration; see
        %   design_study_02_L2.m for the F-16 wiring. Zero is a legal value
        %   throughout (an all-moving stabilator has no separate elevator; a
        %   flaperon-equipped wing has no separate aileron), so none of these
        %   is validated positive.
        %
        %   Name-value arguments, all defaulting to 0 / false so that an
        %   airframe with no wing flaps and a conventional hinged elevator
        %   need not mention them:
        %     c_flaperon_frac, eta_flaperon_in, eta_flaperon_out
        %     c_lef_frac,      eta_lef_in,      eta_lef_out
        %     ht_all_moving
            arguments
                c_ail_frac  (1,1) double {mustBeNonnegative}
                b_ail_frac  (1,1) double {mustBeNonnegative}
                c_elev_frac (1,1) double {mustBeNonnegative}
                b_elev_frac (1,1) double {mustBeNonnegative}
                c_rud_frac  (1,1) double {mustBeNonnegative}
                b_rud_frac  (1,1) double {mustBeNonnegative}
                opts.c_flaperon_frac  (1,1) double {mustBeNonnegative} = 0
                opts.eta_flaperon_in  (1,1) double {mustBeInRange(opts.eta_flaperon_in, 0, 1)} = 0
                opts.eta_flaperon_out (1,1) double {mustBeInRange(opts.eta_flaperon_out, 0, 1)} = 0
                opts.c_lef_frac       (1,1) double {mustBeNonnegative} = 0
                opts.eta_lef_in       (1,1) double {mustBeInRange(opts.eta_lef_in, 0, 1)} = 0
                opts.eta_lef_out      (1,1) double {mustBeInRange(opts.eta_lef_out, 0, 1)} = 0
                opts.ht_all_moving    (1,1) logical = false
            end

            % Role exclusivity -- see the class header. A flaperon IS the roll
            % surface, so an aileron alongside it double-counts one physical
            % surface. Caught here rather than downstream, where it would only
            % show up as a quietly inflated S_csw / S_cs.
            if c_ail_frac > 0 && opts.c_flaperon_frac > 0
                error('ControlSurfaceSizer:ailAndFlaperonBothDeclared', ...
                    ['Both an aileron (c_ail_frac = %g) and a flaperon ' ...
                     '(c_flaperon_frac = %g) were declared. A flaperon already ' ...
                     'serves the aileron role, so declaring both double-counts ' ...
                     'one physical surface. Declare exactly one.'], ...
                    c_ail_frac, opts.c_flaperon_frac);
            end

            % Same argument for the pitch axis: an all-moving stabilator has no
            % separate hinged elevator to size.
            if opts.ht_all_moving && c_elev_frac > 0
                error('ControlSurfaceSizer:allMovingWithElevator', ...
                    ['ht_all_moving = true but c_elev_frac = %g is nonzero. An ' ...
                     'all-moving stabilator has no separate elevator [Raymer 6th ed. ' ...
                     'Table 6.5 footnote]; pass c_elev_frac = 0.'], c_elev_frac);
            end

            obj.c_ail_frac  = c_ail_frac;
            obj.b_ail_frac  = b_ail_frac;
            obj.c_elev_frac = c_elev_frac;
            obj.b_elev_frac = b_elev_frac;
            obj.c_rud_frac  = c_rud_frac;
            obj.b_rud_frac  = b_rud_frac;

            obj.c_flaperon_frac  = opts.c_flaperon_frac;
            obj.eta_flaperon_in  = opts.eta_flaperon_in;
            obj.eta_flaperon_out = opts.eta_flaperon_out;
            obj.c_lef_frac       = opts.c_lef_frac;
            obj.eta_lef_in       = opts.eta_lef_in;
            obj.eta_lef_out      = opts.eta_lef_out;
            obj.ht_all_moving    = opts.ht_all_moving;
        end

        function result = size(obj, geom)
        %SIZE  Control-surface areas [ft^2] from the CURRENT wing and tail.
        %   geom is duck-typed (not strictly type-checked against
        %   GeometryBase): S_ht/S_vt/lambda_wing are an L2/L3 convention, not
        %   part of GeometryBase's Tier-1 abstract contract (only S_ref/S_wet
        %   are), matching F16TailL1's b/cbar usage of geom.
        %
        %   Reads geom.S_ref, geom.S_ht, geom.S_vt and -- for the wing flaps
        %   only -- geom.lambda_wing. Every one of those moves during a
        %   SizingLoopL2 run (S_ref is solved from W_TO/WS_opt; S_ht/S_vt come
        %   from the injected tail sizer), which is why this is called every
        %   iteration rather than once.
        %
        %   Returns struct with fields S_ail, S_elev, S_rud, S_flaperon,
        %   S_lef, S_stab -- names matching this framework's property casing
        %   on the geometry objects (e.g. F16GeomL2.S_flaperon).
        %
        %   Exactly one of (S_ail, S_flaperon) and one of (S_elev, S_stab) is
        %   nonzero for any given airframe; the constructor enforces that.

            % -- Family 1: chord x span fraction [Raymer 6th ed. Fig. 6.3 / Table 6.5]
            S_ail  = obj.c_ail_frac  * obj.b_ail_frac  * geom.S_ref;
            S_elev = obj.c_elev_frac * obj.b_elev_frac * geom.S_ht;
            S_rud  = obj.c_rud_frac  * obj.b_rud_frac  * geom.S_vt;

            % -- Family 2: wing flaps [Roskam Part II Eq. 7.10 via AeroL2].
            % The ratio is the fraction of the wing REFERENCE area in the
            % device's span band; the chord fraction converts it to the
            % device's own planform area.
            S_flaperon = obj.wing_flap_area(geom, obj.c_flaperon_frac, ...
                obj.eta_flaperon_out, obj.eta_flaperon_in);
            S_lef      = obj.wing_flap_area(geom, obj.c_lef_frac, ...
                obj.eta_lef_out, obj.eta_lef_in);

            % -- All-moving stabilator: the whole tail IS the control surface
            % [Raymer 6th ed. Table 6.5 footnote].
            if obj.ht_all_moving
                S_stab = geom.S_ht;
            else
                S_stab = 0;
            end

            result = struct('S_ail', S_ail, 'S_elev', S_elev, 'S_rud', S_rud, ...
                'S_flaperon', S_flaperon, 'S_lef', S_lef, 'S_stab', S_stab);
        end

    end

    methods (Access = private)

        function val = wing_flap_area(~, geom, c_frac, eta_out, eta_in)
        %WING_FLAP_AREA  One wing flap's planform area [ft^2].
        %   c_frac * (S_flapped/S_ref) * S_ref, with the area ratio from
        %   [Roskam Part II Eq. 7.10] via AeroL2.compute_S_flapped_ratio.
        %
        %   Short-circuits to 0 when the device is not declared (c_frac = 0),
        %   so an airframe without leading-edge flaps need not supply span
        %   stations -- and so the default eta_in = eta_out = 0 never reaches
        %   the ratio formula as a degenerate zero-width band.
            if c_frac == 0
                val = 0;
                return;
            end
            ratio = AeroL2.compute_S_flapped_ratio(eta_out, eta_in, geom.lambda_wing);
            val   = c_frac * ratio * geom.S_ref;
        end

    end

end
