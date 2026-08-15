classdef B777TailL1 < TailSizingModelL1
%B777TAILL1  Boeing 777-200LR Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1 (abstract enforcer). size(...) is a single
%   delegation into the TailL1 static toolbox -- no equations are duplicated
%   here. Mirrors F16TailL1, with three deliberate differences for a jet
%   transport:
%
%     1. BASE COEFFICIENTS, NO CORRECTIONS. A jet transport is conventionally
%        stable with a fixed (non-all-moving) horizontal tail, so it takes the
%        Raymer Table 6.4 / metabook Ch.8 jet-transport tail-volume coefficients
%        DIRECTLY:
%            c_HT = 1.00,  c_VT = 0.09
%        [TailL1.lookup_tail_volume_coeffs('jet_transport'); metabook_data.md
%        Ch.8 Eqs. 8.1/8.2]. F16TailL1 by contrast applies -10% (relaxed static
%        stability) and -12.5% (all-moving stabilator) corrections via
%        TailL1.compute_tail_volume_coeffs -- NEITHER applies to the B777, so
%        this class calls lookup_tail_volume_coeffs (the uncorrected base) rather
%        than compute_tail_volume_coeffs.
%
%     2. WING-MOUNTED-ENGINE TAIL ARM. L_HT = L_VT = 0.525*L_fus
%        [TailL1.compute_tail_arm_wing_mounted], the wing-mounted-engine
%        transport rule, vs. F16TailL1's aft-mounted 0.475*L_fus. *** THE 0.525
%        ARM IS UNCITED IN THE REPO EXTRACTS *** -- metabook_data.md carries the
%        jet-transport tail-volume coefficients but NOT the 50-55% wing-mounted
%        arm fraction. It is a labeled TODO in the toolbox
%        (TailL1.compute_tail_arm_wing_mounted's header); a deliberately-failing
%        testTODO must guard it until the printed Raymer text is transcribed.
%
%     3. size() reuses the same TailL1.compute_S_HT / compute_S_VT statics as the
%        F-16, but through TailL1.size the arm comes from compute_tail_arm
%        (aft-mounted 0.475). To use the WING-MOUNTED arm this class computes the
%        arm and the two areas directly here rather than calling TailL1.size.
%
%   No geometry object is injected at L1: GeometryModelL1 exposes S_ref/b/cbar as
%   scalars, so the caller supplies S_ref/b/cbar/L_fus raw -- unchanged
%   TailSizingBase interface. Typical wiring reads them off B777GeomL2:
%       geom = B777GeomL2(b777_spec_path(1));
%       r    = B777TailL1().size(geom.S_ref, geom.b_wing, geom.cbar_wing, geom.L_fus);
%
%   Constructor takes no arguments: jet_transport is a B777 spec fact, baked in
%   here rather than read from JSON -- same pattern as F16TailL1.
%
%   Inheritance: TailSizingBase -> TailSizingModelL1 -> B777TailL1
%
%   SOURCES:
%     [metabook] metabook_data.md Ch.8 Eqs. 8.1/8.2 (c_HT=1.0, c_VT=0.09).
%     [Raymer]   Raymer 7th ed. Table 6.4 jet-transport row (agrees); the
%       wing-mounted 50-55% tail-arm text is the UNCITED-in-repo TODO above.

    properties (SetAccess = private)
        c_HT (1,1) double   % horizontal-tail volume coefficient [metabook Ch.8 Eq. 8.2; Raymer 7th ed. Table 6.4 jet-transport] = 1.00
        c_VT (1,1) double   % vertical-tail volume coefficient   [metabook Ch.8 Eq. 8.1; Raymer 7th ed. Table 6.4 jet-transport] = 0.09
    end

    methods

        function obj = B777TailL1()
        %B777TAILL1  Construct with the B777's jet-transport coefficients baked
        %   in. Uses the UNCORRECTED base coefficients
        %   (lookup_tail_volume_coeffs, NOT compute_tail_volume_coeffs): a jet
        %   transport has neither relaxed static stability nor an all-moving
        %   tail, so no correction applies -- contrast F16TailL1, which applies
        %   both.
            [obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_transport');
        end

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [metabook Ch.8; Raymer 7th ed. Table 6.4]  Returns
        %   struct('S_ht', S_ht, 'S_vt', S_vt), matching the TailSizingBase
        %   contract exactly.
        %
        %   Uses the WING-MOUNTED-engine tail arm L = 0.525*L_fus
        %   (compute_tail_arm_wing_mounted) -- the *** UNCITED-arm TODO *** noted
        %   in the class header -- NOT TailL1.size's aft-mounted 0.475*L_fus. The
        %   two areas then reuse the same cited TailL1.compute_S_HT /
        %   compute_S_VT statics the F-16 path uses.
        %
        %   S_ref -- wing reference area, ft^2
        %   b     -- wing span, ft
        %   cbar  -- wing mean aerodynamic chord (S/b at L1), ft
        %   L_fus -- fuselage length, ft
            arguments
                obj
                S_ref (1,1) double {mustBePositive}
                b     (1,1) double {mustBePositive}
                cbar  (1,1) double {mustBePositive}
                L_fus (1,1) double {mustBePositive}
            end
            L_arm = TailL1.compute_tail_arm_wing_mounted(L_fus);   % 0.525*L_fus [UNCITED TODO]
            S_ht  = TailL1.compute_S_HT(obj.c_HT, cbar, S_ref, L_arm);
            S_vt  = TailL1.compute_S_VT(obj.c_VT, b, S_ref, L_arm);
            result = struct('S_ht', S_ht, 'S_vt', S_vt);
        end

    end

end
