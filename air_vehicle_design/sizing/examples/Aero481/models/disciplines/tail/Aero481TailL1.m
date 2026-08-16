classdef Aero481TailL1 < TailSizingModelL1
%Aero481TAILL1  F-35 Level-1 (volume-coefficient) tail sizing.
%
%   Inherits TailSizingModelL1 (abstract enforcer). size(...) is a single
%   delegation into the TailL1 static toolbox -- no equations are duplicated
%   here. Mirrors F16TailL1 (aft-mounted single-engine fighter), with one
%   deliberate difference for the F-35 at this fidelity:
%
%     UNCORRECTED BASE COEFFICIENTS. The F-35 takes the Raymer Table 6.4
%     jet-fighter tail-volume coefficients DIRECTLY:
%         c_HT = 0.40,  c_VT = 0.07
%     [TailL1.lookup_tail_volume_coeffs('jet_fighter'); Raymer 7th ed.
%     Table 6.4 jet-fighter row; metabook Ch.8]. F16TailL1 by contrast applies
%     -10% (relaxed static stability) and -12.5% (all-moving stabilator)
%     corrections via TailL1.compute_tail_volume_coeffs. Whether the F-35 takes
%     those same corrections is _TODO -- UNCITED (its RSS / all-moving-tail
%     flags are not yet pinned in the repo extracts -- scribe plan Sec. 5), so
%     this class carries the UNCORRECTED base coefficients until a flag is set,
%     exactly as the B777 does. It therefore calls lookup_tail_volume_coeffs
%     (the uncorrected base), NOT compute_tail_volume_coeffs. A labelled
%     testTODO must guard the RSS / all-moving-tail flags until they are cited.
%
%   AFT-MOUNTED TAIL ARM (unlike the B777). L_HT = L_VT = 0.475*L_fus
%   [Raymer 7th ed., aft-mounted single-engine text rule; 0.475 is the midpoint
%   of the stated 0.45-0.50 range], via TailL1.compute_tail_arm. This arm IS
%   cited -- contrast the B777's UNCITED wing-mounted 0.525*L_fus. Because the
%   arm is the aft-mounted one, size() delegates to TailL1.size directly (which
%   uses compute_tail_arm internally), the same path the F-16 takes.
%
%   No geometry object is injected at L1: GeometryModelL1 has no planform at all
%   (only a W_TO regression), so the caller supplies S_ref/b/cbar/L_fus as raw
%   scalars -- unchanged TailSizingBase interface. Typical wiring:
%       geom = Aero481GeomL1(aero481_spec_path(1), prop);
%       r    = Aero481TailL1().size(geom.S_ref, geom.b, geom.cbar, geom.L_fuselage);
%
%   Constructor takes no arguments: jet_fighter is an F-35 spec fact, baked in
%   here rather than read from JSON -- same pattern as F16TailL1 / B777TailL1.
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
        %Aero481TAILL1  Construct with the F-35's jet-fighter coefficients baked in.
        %   Uses the UNCORRECTED base coefficients (lookup_tail_volume_coeffs,
        %   NOT compute_tail_volume_coeffs): the F-35 RSS / all-moving-tail flags
        %   are _TODO -- UNCITED, so no correction is applied here -- contrast
        %   F16TailL1, which applies both. Matches the B777 uncorrected-base
        %   pattern.
            [obj.c_HT, obj.c_VT] = TailL1.lookup_tail_volume_coeffs('jet_fighter');
        end

        function result = size(obj, S_ref, b, cbar, L_fus)
        %SIZE  Horizontal- and vertical-tail reference areas [ft^2].
        %   [Raymer 7th ed. Table 6.4]  See TailSizingBase.m for the contract;
        %   TailL1.size for the formula. Uses the aft-mounted single-engine tail
        %   arm L = 0.475*L_fus (TailL1.compute_tail_arm, called inside
        %   TailL1.size) -- the same path the F-16 takes.
        %
        %   S_ref -- wing reference area, ft^2
        %   b     -- wing span, ft
        %   cbar  -- wing mean aerodynamic chord, ft
        %   L_fus -- fuselage length, ft
            result = TailL1.size(obj, S_ref, b, cbar, L_fus);
        end

    end

end
