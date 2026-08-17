classdef Aero481TailL1 < TailSizingModelL1
%AERO481TAILL1  AERO 481 (F-35-based student design) Level-1 tail sizing.
%
%   Inherits TailSizingModelL1. size(obj) reads the injected geometry and
%   delegates to the TailL1 static toolbox (aft-mounted arm 0.475*L_fus, the
%   F-16 path). Differs from F16TailL1: it takes the UNCORRECTED Raymer Table
%   6.4 jet-fighter coefficients (c_HT=0.40, c_VT=0.07) directly, because the
%   design's RSS / all-moving-tail flags are _TODO -- UNCITED (not pinned).
%
%   Geometry (S_ref, b_wing, cbar_wing, L_fus) is read live from the injected,
%   read-only geometry collaborator.
%
%   CONSTRUCTOR: Aero481TailL1(geom) -- geom required (a GeometryBase), no
%   silent default. jet_fighter coefficients baked in.
%
%   SOURCES:
%     [Raymer] Raymer 7th ed. Table 6.4 jet-fighter row (c_HT=0.40, c_VT=0.07);
%       aft-mounted single-engine text rule (tail arm 0.45-0.50 L_fus).
%     [metabook] metabook_data.md Ch.8 (tail-volume coefficient method).

    properties (SetAccess = private)
        c_HT (1,1) double   % horizontal-tail volume coefficient [Raymer 7th ed. Table 6.4 jet-fighter, uncorrected base] = 0.40
        c_VT (1,1) double   % vertical-tail volume coefficient   [Raymer 7th ed. Table 6.4 jet-fighter, uncorrected base] = 0.07
    end

    properties
        geom   % (1,1) GeometryBase -- injected, read-only; supplies S_ref/b_wing/cbar_wing/L_fus by DI
    end

    methods

        function obj = Aero481TailL1(geom)
        %AERO481TAILL1  Construct with a required injected geometry object and
        %   the UNCORRECTED jet-fighter coefficients (RSS / all-moving flags are
        %   _TODO -- UNCITED; see class header).
            arguments
                geom (1,1) GeometryBase
            end
            obj.geom = geom;
            [obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_fighter');
        end

        function result = size(obj)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4]  Reads obj.geom live and delegates to
        %   TailL1.size (aft-mounted arm L=0.475*L_fus). Returns
        %   struct('S_ht', S_ht, 'S_vt', S_vt).
            result = TailL1.size(obj, obj.geom.S_ref, obj.geom.b_wing, ...
                                 obj.geom.cbar_wing, obj.geom.L_fus);
        end

    end

end
