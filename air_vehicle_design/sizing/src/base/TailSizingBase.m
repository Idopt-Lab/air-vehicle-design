classdef (Abstract) TailSizingBase < handle
%TAILSIZINGBASE  Tier-1 abstract enforcer for all tail-sizing discipline
%   classes.
%
%   Declares the single contract every fidelity level implements: return the
%   horizontal- and vertical-tail reference areas as struct('S_ht', S_ht,
%   'S_vt', S_vt) -- exactly these two fields, no injected geometry read back.
%
%   SCOPE: sizes only S_ht/S_vt and the geometry that requires (moment arm,
%   volume coefficients). Control-surface sizing is a separate discipline
%   (src/sizing/ControlSurfaceSizer.m).
%
%   Inheritance: TailSizingBase -> TailSizingModelLN (abstract) -> F16TailLN.
%   The TailLN static toolboxes are not in this chain.
%
%   Every level takes an injected geometry collaborator at construction and
%   implements size(obj), reading S_ref/b_wing/cbar_wing/L_fus from it live.
%   L1 is the volume-coefficient method; L2 is a not-implemented stub.
%
%   Companion doc: src/base/TailSizingBase.md

    methods (Abstract)

        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   Returns struct('S_ht', S_ht, 'S_vt', S_vt) -- lowercase field
        %   names, matching GeometryBase-derived classes' own S_ht/S_vt
        %   property casing (e.g. F16GeomL2.S_ht/S_vt).
        result = size(obj)

    end

    methods (Static)

        function S = tail_volume_area(coef, length_scale, S_ref, arm)
        %TAIL_VOLUME_AREA  Tail area from its volume coefficient.
        %   S = coef * length_scale * S_ref / arm -- the volume-coefficient
        %   definition solved for area. Shared by TailL1/TailL2: horizontal
        %   tail uses length_scale = cbar, vertical tail uses span b.
            S = coef * length_scale * S_ref / arm;
        end

    end

end
