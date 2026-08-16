classdef Aero481TailL1 < TailSizingModelL1
%Aero481TAILL1  F-35 Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1 (abstract enforcer). size(...) is a single
%   delegation into the TailL1 static toolbox. Mirrors F16TailL1 (aft-mounted
%   single-engine fighter), with two differences:
%
%     UNCORRECTED BASE COEFFICIENTS. Takes the Raymer Table 6.4 jet-fighter
%     coefficients DIRECTLY (c_HT = 0.40, c_VT = 0.07) via
%     TailL1.lookup_tail_volume_coeffs('jet_fighter') [Raymer 7th ed. Table 6.4;
%     metabook Ch.8]. F16TailL1 applies -10% (RSS) and -12.5% (all-moving)
%     corrections; whether the F-35 does is _TODO -- UNCITED (its flags are not
%     pinned), so the base is carried (like the B777), testTODO-guarded.
%
%     AFT-MOUNTED TAIL ARM. L_HT = L_VT = 0.475*L_fus [Raymer 7th ed.,
%     aft-mounted single-engine text rule, midpoint of 0.45-0.50], via
%     TailL1.compute_tail_arm. Cited (contrast the B777's uncited wing-mounted
%     0.525). size() delegates to TailL1.size directly, the F-16 path.
%
%   No geometry object is injected at L1 (GeometryModelL1 has no planform); the
%   caller supplies S_ref/b/cbar/L_fus as raw scalars. Constructor takes no
%   arguments (jet_fighter baked in, as F16TailL1 / B777TailL1).
%
%   Inheritance: TailSizingBase -> TailSizingModelL1 -> Aero481TailL1
%
%   SOURCES:
%     [Raymer] Raymer 7th ed. Table 6.4 jet-fighter row (c_HT=0.40, c_VT=0.07);
%       aft-mounted single-engine text rule (tail arm 0.45-0.50 L_fus).
%     [metabook] metabook_data.md Ch.8 (tail-volume coefficient method).

    properties (SetAccess = private)
        c_HT (1,1) double   % horizontal-tail volume coefficient [Raymer 7th ed. Table 6.4 jet-fighter, uncorrected base] = 0.40
        c_VT (1,1) double   % vertical-tail volume coefficient   [Raymer 7th ed. Table 6.4 jet-fighter, uncorrected base] = 0.07
    end

    methods

        function obj = Aero481TailL1()
        %Aero481TAILL1  Construct with the F-35's jet-fighter coefficients baked
        %   in. Uses the UNCORRECTED base (lookup_tail_volume_coeffs): the RSS /
        %   all-moving-tail flags are _TODO -- UNCITED (see class header).
            [obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_fighter');
        end

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4]  Delegates to TailL1.size (aft-mounted arm
        %   L = 0.475*L_fus). Args: S_ref [ft^2], b [ft], cbar [ft], L_fus [ft].
            result = TailL1.size(obj, S_ref, b, cbar, L_fus);
        end

    end

end
