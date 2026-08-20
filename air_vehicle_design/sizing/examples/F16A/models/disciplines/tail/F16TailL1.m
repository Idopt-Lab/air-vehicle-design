classdef F16TailL1 < TailSizingModelL1
%F16TAILL1  F-16A Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1. size(obj) reads the injected geometry and
%   delegates to the TailL1 static toolbox -- no equations are duplicated here.
%
%   Net, corrected jet-fighter tail-volume coefficients:
%     c_HT = 0.40 * (1-0.10) * (1-0.125) = 0.315
%     c_VT = 0.07 * (1-0.10)             = 0.063
%   [Raymer 7th ed. Table 6.4 "Jet fighter" row (base 0.40/0.07), corrected for
%   relaxed static stability (-10% on both) and an all-moving stabilator
%   (-12.5% on c_HT) -- see TailL1.compute_tail_volume_coeffs]. Tail moment arm
%   L_HT=L_VT=0.475*L_fus [same source, aft-mounted single-engine text rule;
%   0.475 is the midpoint of the stated 0.45-0.50 range].
%
%   Geometry (S_ref, b_wing, cbar_wing, L_fus) is read live from the injected,
%   read-only geometry collaborator, so size(obj) tracks the sizing loop's
%   mutations with no cached copy.
%
%   CONSTRUCTOR: F16TailL1(geom) -- geom required (a GeometryBase), no silent
%   default. category (jet_fighter) and both correction flags (RSS, all-moving
%   tail) are F-16 spec facts, baked in.
%
%   History and rationale: docs/decision_log.md

    properties (SetAccess = private)
        c_HT (1,1) double   % net horizontal-tail volume coefficient [Raymer 7th ed. Table 6.4 + text corrections] = 0.315
        c_VT (1,1) double   % net vertical-tail volume coefficient   [Raymer 7th ed. Table 6.4 + text corrections] = 0.063
    end

    properties
        geom   % (1,1) GeometryBase -- injected, read-only; supplies S_ref/b_wing/cbar_wing/L_fus by DI
    end

    methods

        function obj = F16TailL1(geom)
        %F16TAILL1  Construct with a required injected geometry object and the
        %   F-16's category/correction flags baked in (jet_fighter, RSS=true,
        %   all-moving-tail=true).
            arguments
                geom (1,1) GeometryBase
            end
            obj.geom = geom;
            [obj.c_HT, obj.c_VT] = TailL1.compute_tail_volume_coeffs('jet_fighter', true, true);
        end

        function result = size(obj)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4 + text]  Reads obj.geom live; returns
        %   struct('S_ht', S_ht, 'S_vt', S_vt). See TailL1.size for the formula.
            result = TailL1.size(obj, obj.geom.S_ref, obj.geom.b_wing, ...
                                 obj.geom.cbar_wing, obj.geom.L_fus);
        end

    end

end
