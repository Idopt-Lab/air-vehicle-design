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
%   for relaxed static stability (-10% on both -- the F-16 is RSS by design,
%   an FLCS-era fighter) and an all-moving stabilator (-12.5% on c_HT --
%   the F-16's horizontal tail is an all-moving stabilator, already
%   documented as such throughout F16GeomL2/F16GeomL3 and
%   ControlSurfaceSizer's F-16 wiring, where S_elev=0) -- see
%   TailL1.compute_tail_volume_coeffs and TailSizing_scribe_plan.md
%   Sec. 2/4]. Tail moment arm L_HT=L_VT=0.475*L_fus [same source,
%   aft-mounted single-engine text rule; 0.475 is the midpoint of the
%   stated 0.45-0.50 range].
%
%   MIGRATED (2026-07-28) from examples/F16TailSizingLevel1.m, whose values
%   (c_HT=0.40, c_VT=0.07, tail arm=0.5*L_fus, Raymer 6th ed.) are
%   SUPERSEDED by the corrected set above -- see TailSizing_scribe_plan.md
%   Sec. 2 for the full discrepancy-resolution record (two competing L1
%   tail-sizing implementations existed in this repo; this migration
%   adopts the corrected one). examples/F16TailSizingLevel1.m and
%   src/disciplines/tail_sizing/TailSizingLevel1.m are SUPERSEDED by this
%   class and TailL1 -- retained only until the new tests are verified
%   green (per the scribe plan's "once tests pass, remove" gate), NOT to be
%   used for new work.
%
%   No geometry object is injected at L1: GeometryModelL1 has no planform
%   at all (only a W_TO regression), so the caller supplies S_ref/b/cbar/
%   L_fus as raw scalars -- unchanged interface, see TailSizingBase.m.
%
%   Constructor takes no arguments: the F-16's category (jet_fighter) and
%   both correction flags (RSS=true, all-moving-tail=true) are F-16 spec
%   facts, baked in here rather than read from JSON -- same pattern as the
%   superseded F16TailSizingLevel1's obj@TailSizingLevel1(0.40, 0.07).

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
