classdef (Abstract) TailSizingBase < handle
%TAILSIZINGBASE  Tier-1 abstract enforcer for all tail-sizing discipline
%   classes.
%
%   Declares the single contract every fidelity level implements: given
%   whatever inputs that level's method needs, return the horizontal- and
%   vertical-tail reference areas as struct('S_ht', S_ht, 'S_vt', S_vt) --
%   exactly these two fields, at every level, no other fields, no injected
%   geometry object read back out of it
%   [src/disciplines/tail_sizing/TailSizing_scribe_plan.md Sec. 0].
%
%   SCOPE: sizes ONLY S_ht/S_vt (horizontal/vertical tail reference areas)
%   and whatever geometric parameters that requires (moment arm, volume
%   coefficients). Control-surface sizing (elevator/rudder/aileron chord x
%   span fractions) is a SEPARATE discipline (src/sizing/
%   ControlSurfaceSizer.m), untouched by this hierarchy.
%
%   Inheritance: TailSizingBase -> TailSizingModelLN (abstract) -> F16TailLN
%   The TailLN static toolboxes are NOT in this chain.
%
%   SIGNATURE NOTE: the abstract declaration below uses the WIDEST signature
%   any implementer needs. L1 needs it in full: GeometryModelL1 has no
%   planform at all (only a W_TO-based S_wet regression), so the caller
%   supplies S_ref/b/cbar and the two moment arms as raw scalars. L2/L3
%   instead take an injected GeometryModelL2/L3 collaborator at CONSTRUCTION
%   and implement size(obj) with no further arguments. MATLAB does not
%   enforce matching arity between an abstract declaration and its override
%   -- same idiom as GeometryBase.get_S_wet(obj, W_TO), whose own comment
%   states this explicitly and which L2/L3 geometry classes already override
%   as get_S_wet(obj).
%
%   ARGUMENT CHANGE 2026-08-11 (tail-arm definition fix): the last argument
%   was a single L_fus, from which each toolbox computed the arm internally
%   as 0.475*L_fus. It is now the PAIR OF ARMS themselves, L_HT and L_VT.
%   Reason: the arm is a station-to-station distance in the LAYOUT --
%   "tail-quarter-chord to wing-quarter-chord distance" [Raymer 6th ed.
%   Sec. 6.5.2, p.158], or initial-c.g.-to-tail-mac-quarter-chord [Nicolai &
%   Carichner Eqs. (11.1)/(11.2)] -- so it belongs to whoever holds the
%   layout, i.e. the geometry object (GeometryModelL2/L3 expose it live as
%   Dependent L_HT/L_VT). Tail sizing owns only the volume-coefficient
%   equation. The fuselage fraction survives as
%   TailL1.compute_tail_arm(L_fus), which is what Raymer prescribes at the
%   stage where no layout exists (L1) and nothing more.
%
%   Companion doc: src/base/TailSizingBase.md

    methods (Abstract)

        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt) -- lowercase field
        %   names, matching GeometryBase-derived classes' own S_ht/S_vt
        %   property casing (e.g. F16GeomL2.S_ht/S_vt).
        result = size(obj, S_ref, b, cbar, L_HT, L_VT)

    end

end
