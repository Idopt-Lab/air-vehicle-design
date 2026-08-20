classdef B777TailL1 < TailSizingModelL1
%B777TAILL1  Boeing 777-200LR Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1. size(obj) reads the injected geometry and
%   computes the arm and two areas from the TailL1 static toolbox. Differs from
%   F16TailL1 for a jet transport:
%     1. Base coefficients, NO corrections: jet-transport c_HT=1.00, c_VT=0.09
%        via TailL1.lookup_tail_volume_coeffs('jet_transport')
%        [metabook_data.md Ch.8 Eqs. 8.1/8.2; Raymer 7th ed. Table 6.4].
%     2. Wing-mounted-engine tail arm L_HT=L_VT=0.525*L_fus
%        [TailL1.compute_tail_arm_wing_mounted] vs F16TailL1's 0.475.
%        *** THE 0.525 ARM IS UNCITED IN THE REPO EXTRACTS *** -- a labeled
%        TODO until the Raymer text is transcribed.
%
%   Geometry (S_ref, b_wing, cbar_wing, L_fus) is read live from the injected,
%   read-only geometry collaborator.
%
%   CONSTRUCTOR: B777TailL1(geom) -- geom required (a GeometryBase), no silent
%   default. jet_transport coefficients baked in.
%
%   SOURCES:
%     [metabook] metabook_data.md Ch.8 Eqs. 8.1/8.2 (c_HT=1.0, c_VT=0.09).
%     [Raymer]   Raymer 7th ed. Table 6.4 jet-transport row; the wing-mounted
%       50-55% tail-arm text is the UNCITED-in-repo TODO above.

    properties (SetAccess = private)
        c_HT (1,1) double   % horizontal-tail volume coefficient [metabook Ch.8 Eq. 8.2; Raymer 7th ed. Table 6.4 jet-transport] = 1.00
        c_VT (1,1) double   % vertical-tail volume coefficient   [metabook Ch.8 Eq. 8.1; Raymer 7th ed. Table 6.4 jet-transport] = 0.09
    end

    properties
        geom   % (1,1) GeometryBase -- injected, read-only; supplies S_ref/b_wing/cbar_wing/L_fus by DI
    end

    methods

        function obj = B777TailL1(geom)
        %B777TAILL1  Construct with a required injected geometry object and the
        %   B777's UNCORRECTED jet-transport coefficients (no RSS, no all-moving
        %   tail; contrast F16TailL1).
            arguments
                geom (1,1) GeometryBase
            end
            obj.geom = geom;
            [obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_transport');
        end

        function result = size(obj)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [metabook Ch.8; Raymer 7th ed. Table 6.4]  Reads obj.geom live and
        %   uses the WING-MOUNTED arm L=0.525*L_fus (*** UNCITED-arm TODO ***),
        %   then compute_S_HT / compute_S_VT. Returns struct('S_ht','S_vt').
            S_ref = obj.geom.S_ref;
            b     = obj.geom.b_wing;
            cbar  = obj.geom.cbar_wing;
            L_fus = obj.geom.L_fus;
            L_arm = TailL1.compute_tail_arm_wing_mounted(L_fus);   % 0.525*L_fus [UNCITED TODO]
            S_ht  = TailL1.compute_S_HT(obj.c_HT, cbar, S_ref, L_arm);
            S_vt  = TailL1.compute_S_VT(obj.c_VT, b, S_ref, L_arm);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

    end

end
