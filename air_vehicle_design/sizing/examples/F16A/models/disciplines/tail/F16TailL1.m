classdef F16TailL1 < TailSizingModelL1
%F16TAILL1  F-16A Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1 (abstract enforcer). size(...) is a single
%   delegation into the TailL1 static toolbox -- no equations are
%   duplicated here.
%
%   Wires in the F-16's net, corrected jet-fighter tail-volume coefficients:
%     c_HT = 0.40 * (1-0.10) * (1-0.125) = 0.315
%     c_VT = 0.07 * (1-0.10)             = 0.063
%   [Raymer 7th ed. Table 6.4, "Jet fighter" row (base 0.40/0.07), corrected
%   for relaxed static stability (-10% on both, F-16 is RSS by design) and an
%   all-moving stabilator (-12.5% on c_HT) -- see
%   TailL1.compute_tail_volume_coeffs]. Tail moment arm L_HT=L_VT=0.475*L_fus
%   [same source, aft-mounted single-engine text rule; 0.475 is the midpoint
%   of the stated 0.45-0.50 range].
%
%   No geometry object is injected at L1: GeometryModelL1 has no planform
%   (only a W_TO regression), so the caller supplies S_ref/b/cbar/L_fus as raw
%   scalars -- see TailSizingBase.m.
%
%   Constructor takes no arguments: the F-16's category (jet_fighter) and both
%   correction flags (RSS=true, all-moving-tail=true) are F-16 spec facts,
%   baked in here rather than read from JSON.
%
%   History and rationale: docs/decision_log.md

    properties (SetAccess = private)
        c_HT (1,1) double   % net horizontal-tail volume coefficient [Raymer 7th ed. Table 6.4 + text corrections] = 0.315
        c_VT (1,1) double   % net vertical-tail volume coefficient   [Raymer 7th ed. Table 6.4 + text corrections] = 0.063
    end

    methods

        function obj = F16TailL1()
        %F16TAILL1  Construct with the F-16's category/correction flags
        %   baked in: aircraft_category='jet_fighter', has_rss=true,
        %   has_all_moving_tail=true.
            [obj.c_HT, obj.c_VT] = TailL1.compute_tail_volume_coeffs('jet_fighter', true, true);
        end

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4 + text]  See TailSizingBase.m for the
        %   contract; TailL1.size for the formula.
        %
        %   S_ref  -- wing reference area, ft^2
        %   b      -- wing span, ft
        %   cbar   -- wing mean aerodynamic chord, ft
        %   L_fus  -- fuselage length, ft
            result = TailL1.size(obj, S_ref, b, cbar, L_fus);
        end

    end

end
