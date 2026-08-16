classdef B777TailL1 < TailSizingModelL1
%B777TAILL1  Boeing 777-200LR Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1 (abstract enforcer). size(...) computes the arm
%   and two areas from the TailL1 static toolbox. Mirrors F16TailL1, with three
%   differences for a jet transport:
%
%     1. BASE COEFFICIENTS, NO CORRECTIONS. A jet transport is conventionally
%        stable, so it takes the jet-transport coefficients DIRECTLY (c_HT = 1.00,
%        c_VT = 0.09) via TailL1.lookup_tail_volume_coeffs('jet_transport')
%        [metabook_data.md Ch.8 Eqs. 8.1/8.2; Raymer Table 6.4]. F16TailL1
%        applies -10%/-12.5% corrections; neither applies here.
%
%     2. WING-MOUNTED-ENGINE TAIL ARM. L_HT = L_VT = 0.525*L_fus
%        [TailL1.compute_tail_arm_wing_mounted], vs F16TailL1's aft-mounted
%        0.475. *** THE 0.525 ARM IS UNCITED IN THE REPO EXTRACTS *** -- a
%        labeled TODO, testTODO-guarded until the Raymer text is transcribed.
%
%     3. size() computes the arm and areas directly (not via TailL1.size, whose
%        arm is the aft-mounted 0.475), reusing compute_S_HT / compute_S_VT.
%
%   No geometry object is injected at L1; the caller supplies S_ref/b/cbar/L_fus
%   raw (from B777GeomL2). Constructor takes no arguments (jet_transport baked
%   in, as F16TailL1).
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
        %   in. Uses the UNCORRECTED base (lookup_tail_volume_coeffs): a jet
        %   transport has neither RSS nor an all-moving tail (contrast F16TailL1).
            [obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_transport');
        end

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [metabook Ch.8; Raymer 7th ed. Table 6.4]  Returns struct(S_ht, S_vt)
        %   (TailSizingBase contract). Uses the WING-MOUNTED arm L = 0.525*L_fus
        %   (*** UNCITED-arm TODO ***), then compute_S_HT / compute_S_VT.
        %   Args: S_ref [ft^2], b [ft], cbar [ft], L_fus [ft].
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
