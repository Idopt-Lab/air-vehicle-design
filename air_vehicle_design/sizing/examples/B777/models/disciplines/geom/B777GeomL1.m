classdef B777GeomL1 < GeometryModelL1
%B777GEOML1  Boeing 777-200LR Level-1 geometry class (metabook Example 4.2).
%
%   Inherits GeometryModelL1 (abstract enforcer). Unlike F16GeomL1 -- whose L1
%   geometry is a pure W_TO statistical regression -- the B777's L1 geometry
%   carries a REAL wing planform (S_ref, AR from metabook Table 4.3) plus the
%   metabook Eq. 4.58 wetted-area decomposition. It therefore ADDS the planform
%   Dependent members (span, mean chord) that F16GeomL1 lacks, exactly as
%   F16GeomL2 adds members to the L2 enforcer.
%
%   ============================================================================
%   INPUT vs DERIVED -- the optimization-ready pattern. Reference implementation:
%   examples/F16A/models/disciplines/geom/F16GeomL2.m (read its header for the
%   full rationale). Two property blocks:
%
%     (1) INPUTS -- a plain, mutable `properties` block: the genuine
%         design-variable spec data an optimizer varies (S_ref, AR, S_wet_rest,
%         L_fus, n_engines). Plus the tail write-back slots S_ht/S_vt (see
%         below). The constructor sets these once from the JSON.
%     (2) DERIVED -- a `properties (Dependent)` block: everything computed from
%         the inputs (span, mean chord, total wetted area). Each `get.<name>`
%         recomputes live from the inputs on every read -- NO stored/cached copy,
%         so nothing goes stale when an optimizer mutates an input. The instant
%         obj.S_ref or obj.AR changes, S_wet / b_wing / cbar_wing follow.
%
%   The LIVE CD0(S) COUPLING is the whole point of the Dependent S_wet here:
%   B777AeroL1.drag_polar computes CD0 = Cfe*(S_wet/S_ref), and S_wet =
%   S_wet_rest + 2*S_ref [metabook Eq. 4.58]. So when the L2 sizing loop mutates
%   the wing area S_ref, S_wet and hence CD0 track it automatically -- freezing
%   S_wet in the constructor would silently pin CD0 to the old wing.
%   ============================================================================
%
%   CONSTRUCTOR: B777GeomL1(json_path). Reads the .geometry block of a required
%   unified L1 input JSON (b777_spec_path(1)). No silent default -- the path
%   must be supplied.
%
%   Inheritance: GeometryBase -> GeometryModelL1 -> B777GeomL1
%
%   L1 STATISTICAL METHODS ARE NOT APPLICABLE HERE. GeometryModelL1 declares
%   get_S_wet_statistical(obj, W_TO) and get_L_fus(obj, W_TO) abstract (the
%   W_TO-regression path F16GeomL1 uses). The B777's L1 geometry uses the
%   metabook Eq. 4.58 PLANFORM decomposition instead of a TOGW regression, so
%   those two methods error rather than return a wrong-model number -- see their
%   implementations below.
%
%   SOURCES:
%     [metabook] AE481 metabook worked Example 4.2, docs/reference_extracts/
%       metabook_data.md. S_ref/AR [Table 4.3]; S_wet_rest [Eq. 4.58 decomposition
%       of the Eq. 4.42 MTOW regression]; L_fus [_TODO stand-in, b777_L1.md §2.2];
%       cbar = S/b [Eq. 11.5 note].

    % ======================================================================= %
    % INPUTS -- design-variable spec data (mutable; set once by the constructor,
    % may be varied by an optimizer). Every DERIVED property below recomputes
    % live from these.
    % ======================================================================= %
    properties
        S_ref       = 4605     % ft^2  wing reference area [metabook Table 4.3]
        AR          = 9.8      % --    wing aspect ratio    [metabook Table 4.3]
        S_wet_rest  = 19081    % ft^2  wetted area of everything EXCEPT the wing [metabook Eq. 4.58 decomposition; = 28291 - 2*4605]. The wing part (2*S_ref) is added live by the Dependent S_wet, so S_wet tracks a mutated wing area.
        L_fus       = 209      % ft    fuselage/overall length [metabook: _TODO stand-in = published 777-200LR length; b777_L1.md §2.2]. Feeds the tail moment arm; the metabook Example 4.2 itself does not use it.
        n_engines   = 2        % --    engine count [metabook §4.11, 2x GE90-110B]. Exposed for mission DI (geom.n_engines); not used by any L1 geometry quantity.

        % ── Tail reference areas -- sizing-loop WRITE-BACK slots ──────────── %
        % NaN until an external tail-sizing object (B777TailL1, sized against
        % this geometry) writes S_ht/S_vt back in -- same pattern as
        % F16GeomL2's tail slots. Plain (not Dependent) because there is no
        % closed-form get.S_ht/S_vt in terms of this class's OWN inputs; the tail
        % areas come from a separate discipline. Default NaN so a read before the
        % tail loop runs is an obvious not-yet-sized sentinel, not a plausible 0.
        S_ht        = NaN      % ft^2  horizontal-tail reference area [B777TailL1.size]
        S_vt        = NaN      % ft^2  vertical-tail reference area   [B777TailL1.size]
    end

    % ======================================================================= %
    % DERIVED -- computed live from the inputs on every read (no cache, never
    % stale). Read-only: assigning errors (no set-methods), which is correct --
    % they are outputs. L_fuselage satisfies the GeometryModelL1 abstract
    % property; S_wet satisfies GeometryBase's.
    % ======================================================================= %
    properties (Dependent)
        S_wet       % ft^2  total wetted area = S_wet_rest + 2*S_ref [metabook Eq. 4.58] -- the live CD0(S) coupling
        b_wing      % ft    span   = sqrt(AR*S_ref) [definitional; GeometryBase.compute_span]
        cbar_wing   % ft    standard mean chord = S_ref/b_wing [metabook Eq. 11.5 note] -- NOT the trapezoidal MAC (no taper carried at L1; b777_L1.md §2.3)
        L_fuselage  % ft    mirrors L_fus (duplicate name required by the GeometryModelL1 abstract contract)
    end

    methods

        function obj = B777GeomL1(json_path)
        %B777GEOML1  Construct from a required unified L1 input JSON path
        %   (b777_spec_path(1)); reads its .geometry block. No silent default:
        %   the path must be supplied. Sets ONLY the input properties; every
        %   derived quantity (S_wet, span, mean chord) is produced live by its
        %   Dependent getter. The tail slots S_ht/S_vt stay NaN until the tail
        %   loop writes them.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path)).geometry;
            obj.S_ref      = J.S_ref;       % [metabook Table 4.3]
            obj.AR         = J.AR;          % [metabook Table 4.3]
            obj.S_wet_rest = J.S_wet_rest;  % [metabook Eq. 4.58]
            obj.L_fus      = J.L_fus;       % [_TODO stand-in]
            obj.n_engines  = J.n_engines;   % [metabook §4.11]
        end

        % ================================================================== %
        % Accessors required by the GeometryBase abstract contract.
        % ================================================================== %

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
        %GET_S_WET  Total wetted area [ft^2]. The B777 L1 model has a real
        %   planform, so it never needs a W_TO argument (the trailing ~ absorbs
        %   the widest-signature W_TO from the abstract declaration). Delegates
        %   to the Dependent getter = S_wet_rest + 2*S_ref [metabook Eq. 4.58].
            val = obj.S_wet;
        end

        % ================================================================== %
        % GeometryModelL1 abstract W_TO-regression methods. NOT APPLICABLE to
        % the B777's L1 geometry: the metabook Example 4.2 takes wetted area from
        % the Eq. 4.58 planform decomposition, not a Roskam TOGW regression.
        % Implemented (MATLAB requires every abstract member be satisfied) but
        % they ERROR rather than return a wrong-model number -- fail loud, not
        % silent.
        % ================================================================== %

        function val = get_S_wet_statistical(obj, ~) %#ok<STOUT>
            error('B777GeomL1:notApplicable', ...
                ['B777GeomL1 has a real wing planform and computes S_wet = ', ...
                 'S_wet_rest + 2*S_ref [metabook Eq. 4.58], NOT a W_TO ', ...
                 'statistical regression. Read obj.S_wet (or get_S_wet()) ', ...
                 'instead of get_S_wet_statistical(W_TO).']);
        end

        function val = get_L_fus(obj, ~) %#ok<STOUT>
            error('B777GeomL1:notApplicable', ...
                ['B777GeomL1 reads L_fus as a direct spec input (metabook ', ...
                 '_TODO stand-in), NOT a W_TO regression. Read obj.L_fus (or ', ...
                 'obj.L_fuselage) instead of get_L_fus(W_TO).']);
        end

        % ================================================================== %
        % DERIVED-property getters -- recompute live from the inputs on every
        % read. Cheap closed-form algebra; no caching.
        % ================================================================== %

        function v = get.S_wet(obj)
            % metabook Eq. 4.58: Swet = Swet_rest + 2*S. The 2*S wing
            % approximation makes S_wet track a mutated wing area, so
            % B777AeroL1's CD0 = Cfe*S_wet/S_ref follows the optimizer.
            v = obj.S_wet_rest + 2 * obj.S_ref;
        end

        function v = get.b_wing(obj)
            v = GeometryBase.compute_span(obj.AR, obj.S_ref);
        end

        function v = get.cbar_wing(obj)
            % Standard mean chord cbar = S/b [metabook Eq. 11.5 note]. This is
            % the S/b definition, NOT the trapezoidal MAC -- no wing taper is
            % carried at L1 (b777_L1.md §2.3), and the metabook uses S/b where a
            % mean chord is needed (e.g. the tail-volume path).
            v = obj.S_ref / obj.b_wing;
        end

        function v = get.L_fuselage(obj)
            v = obj.L_fus;   % mirrors L_fus (duplicate name required by the abstract contract)
        end

    end
end
