classdef (Abstract) GeometryModelL2 < GeometryBase
%GEOMETRYMODELL2  Tier-2 abstract enforcer for Level-2 geometry -- the
%   AIRCRAFT-AGNOSTIC core contract.
%
%   Inherits GeometryBase directly, not GeometryModelL1: each fidelity level
%   satisfies the Tier-1 contract independently.
%
%   AGNOSTIC CORE (slimmed 2026-08-15). This enforcer declares ONLY the geometry
%   quantities that any aircraft's L2 geometry must supply and that cross-
%   discipline consumers read regardless of aircraft type:
%     - the L2 WEIGHTS build-up reads the exposed wing/HT/VT planform areas and
%       the fuselage wetted area (surface density x area);
%     - the tail-sizing / tail-volume path reads the wing span and the HT/VT
%       reference areas (the sizing-loop write-back slots);
%     - the fuselage length anchors the tail arm.
%   Both F16GeomL2 (fighter) and B777GeomL2 (transport) satisfy exactly this set.
%
%   WHAT IS **NOT** HERE (2026-08-15 slim). The detailed per-surface breakdown a
%   COMPONENT DRAG BUILD-UP needs -- per-surface t/c, leading/trailing/quarter-
%   chord sweeps, taper, aspect ratios, root/tip chords, per-surface wetted
%   areas, the inlet/engine duct wetted area, and the whole-aircraft wave-drag
%   geometry (Amax, L_aircraft) -- is NOT aircraft-agnostic: only a high-fidelity
%   drag build-up (the F-16's F16AeroL2/L3, F16WeightsL3, F16SubsystemsL2)
%   consumes it, and a transport with a simple Cfe*Swet/Sref polar has no use for
%   it. Those members therefore live as CONCRETE members on F16GeomL2 (where they
%   always did), NOT as an abstract obligation on every L2 geometry. A concrete
%   class MAY expose more than this core; it just is not forced to. The F-16
%   drag-build-up consumers still read that detail off the concrete F16GeomL2
%   object they are handed (their mustBeA guard accepts any GeometryModelL2, and
%   F16GeomL2 carries the detail concretely).
%
%   INPUT vs DERIVED. A concrete class supplies the design-variable inputs
%   (reference areas an optimizer varies) as plain properties and every quantity
%   computed from them (spans, exposed/wetted areas) as Dependent getters that
%   recompute on read, never as stored values.
%   examples/F16A/models/disciplines/geom/F16GeomL2.m is the fighter reference
%   implementation; examples/B777/models/disciplines/geom/B777GeomL2.m the
%   transport one.


    % Abstract properties cannot have validation attributes in MATLAB.
    % Size/type validation is enforced in the first concrete class.
    properties (Abstract)
        L_fuselage      % ft    fuselage length (anchors the tail arm)
        b_wing          % ft    wing span (tail-volume / tail-sizing input)

        S_ht            % ft^2  FULL H-tail reference planform area -- sizing-loop
                        %       write-back slot the tail-sizing object sets
        S_vt            % ft^2  FULL V-tail reference planform area -- write-back slot

        S_exposed_wing  % ft^2  exposed wing planform   (L2 weights build-up)
        S_exposed_ht    % ft^2  exposed H-tail planform  (L2 weights build-up)
        S_exposed_vt    % ft^2  exposed V-tail planform  (L2 weights build-up)
    end

    methods (Abstract)
        %GET_S_WET_FUSELAGE  Fuselage wetted area, ft^2. Read by the L2 weights
        %   fuselage term (surface density x wetted area).
        val = get_S_wet_fuselage(obj)

        %GET_S_EXPOSED_WING  Passthrough accessor for the wing exposed area.
        val = get_S_exposed_wing(obj)
    end
end
