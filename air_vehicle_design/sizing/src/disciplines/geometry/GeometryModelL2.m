classdef (Abstract) GeometryModelL2 < GeometryBase
%GEOMETRYMODELL2  Tier-2a abstract enforcer for Level-2 geometry.
%
%   Inherits GeometryBase directly — NOT GeometryModelL1.
%   Each fidelity level independently satisfies the Tier-1 contract.
%
%   Declares the component-level S_wet sub-methods a concrete L2 toolbox
%   must implement.  No equations, no formula constants.
%
%   2026-07-22: Geometry's L3 fidelity tier was eliminated and merged into
%   L2 (user decision — see src/disciplines/geometry/GeomL2.md's dated
%   note). This class now declares the full HT/VT property/method contract
%   formerly enforced by GeometryModelL3 (deleted), plus the duct and
%   exposed-wing-passthrough methods that used to live there. HT/VT property
%   names use the lowercase `_ht`/`_vt` suffix convention resolved in
%   examples/F16A/F16GeomL2.md (2026-07-22 casing resolution): only the
%   trailing HT/VT suffix is lowercased (matching the pre-existing wing
%   property `QC_sweep_wing`'s casing) — the prefix keeps its original
%   capitalization (`QC_sweep_ht`/`QC_sweep_vt`, `AR_ht`, `LE_sweep_ht`,
%   etc.), never the whole property name. (An earlier implementation had
%   `qc_sweep_ht`/`qc_sweep_vt` fully lowercase, inconsistent with every
%   other HT/VT property's prefix casing; corrected 2026-07-22.)
%
%   INPUT vs DERIVED — the optimization-ready pattern (2026-07-22, PATTERN
%   TO BE FOLLOWED by all future Tier-3 concrete classes, Aero/Weights/etc.):
%   The abstract properties below fall into two kinds. (1) INPUTS — genuine
%   design-variable spec data an optimizer varies (S_ref, AR_*, taper,
%   sweep_LE, t/c, tail reference areas S_ht/S_vt, fuselage envelope, duct
%   length). (2) DERIVED — planform quantities computed from the inputs
%   (span, root/tip chord, MAC, sweep-station conversions, exposed & wetted
%   areas, equivalent/nacelle diameters). A concrete class satisfies each
%   abstract property with EITHER a stored (mutable) property for an input
%   OR a `Dependent` property whose getter recomputes live from the inputs
%   for a derived quantity. See examples/F16A/F16GeomL2.m for the reference
%   implementation: every derived quantity is `Dependent`, so it is always
%   consistent with the current inputs (no stale cached value) the instant
%   it is read — which is exactly what an optimizer needs when it mutates an
%   input between iterations.
%
%   Inheritance: GeometryBase → GeometryModelL2 → GeomL2 → F16GeomL2

    % Abstract properties cannot have validation attributes in MATLAB.
    % Size/type validation is enforced in the first concrete class (GeomL2).
    % Properties for the fuselage
    properties (Abstract)
        L_fuselage % Fuselage length (ft)
        W_max_fuselage % Maximum width of the fuselage (ft)
        H_max_fuselage % Maximum height of the fuselage

        %AMAX, L_AIRCRAFT  Whole-aircraft wave-drag geometry (added 2026-07-25,
        %   Phase 2). Declared here as well as on GeometryModelL3 so an aero
        %   consumer typed against either tier has one declared contract --
        %   F16AeroL3 reads both live for the Raymer Eq. 12.44 Sears-Haack term.
        %   Before Phase 2 they were frozen Brandt OUTPUTS stored as aero
        %   INPUTS, so supersonic wave drag could not respond to a fuselage
        %   change at all.
        %     Amax       [DERIVED] max cross-section, ft^2, via
        %                GeometryBase.compute_Amax_elliptical -- distinct from
        %                Brandt Geom!B20's area-ruled flow-through-net figure.
        %     L_aircraft [INPUT]   overall length, ft -- distinct from
        %                L_fuselage; provenance OPEN, todo.md 2026-07-25 §6.
        Amax
        L_aircraft
    end

         % Properties for the main wings
     properties (Abstract)
          S_exposed_wing
          S_wet_wing
          QC_sweep_wing
          lambda_wing
          b_wing
          AR_wing
          LE_sweep_wing
          TE_sweep_wing
          c_tip_wing
          c_root_wing
          tc_wing
          tc_r_wing
          tc_t_wing
     end

    % Properties for the horizontal tail (moved from the former
    % GeometryModelL3, 2026-07-22 L3-elimination merge). Naming: lowercase
    % `_ht` suffix throughout; `QC_sweep_ht` keeps the `QC` prefix
    % capitalized to match the pre-existing wing property `QC_sweep_wing` —
    % only the trailing HT/VT suffix is lowercased project-wide, never the
    % whole property name (2026-07-22 casing resolution, corrected from an
    % earlier fully-lowercase `qc_sweep_ht` — see F16GeomL2.md). AR/LE/TE/
    % c_root/c_tip prefixes keep their original capitalization, matching the
    % codebase convention already used outside Geometry (WeightsL2.S_ht,
    % WeightsL3.AR_ht). tc_ht/tc_r_ht/tc_t_ht are included here (they were
    % NOT part of the former L3 abstract contract, which had the same gap on
    % the wing side) because the now-official S_wet formula
    % (compute_roskam_planform) requires the root/tip split — see
    % F16GeomL2.md's "full breakdown is required" resolution.
    properties (Abstract)
          S_ht            % INPUT: full reference planform area, ft^2 (was a
                          % constructor local `S_ht_full` before 2026-07-22;
                          % promoted to a first-class input property so span/
                          % chord/exposed-area derivations read it live)
          S_exposed_ht
          S_wet_ht
          QC_sweep_ht
          lambda_ht
          b_ht
          AR_ht
          LE_sweep_ht
          TE_sweep_ht
          c_root_ht
          c_tip_ht
          tc_ht
          tc_r_ht
          tc_t_ht
    end

    % Properties for the vertical tail (same rationale as the horizontal
    % tail block above).
    properties (Abstract)
          S_vt            % INPUT: full reference planform area, ft^2 (was a
                          % constructor local `S_vt_full` before 2026-07-22;
                          % promoted to a first-class input property — same
                          % rationale as S_ht above)
          S_exposed_vt
          S_wet_vt
          QC_sweep_vt
          lambda_vt
          b_vt
          AR_vt
          LE_sweep_vt
          TE_sweep_vt
          c_root_vt
          c_tip_vt
          tc_vt
          tc_r_vt
          tc_t_vt
    end

    methods (Abstract)
        %GET_S_WET_WING  Wing wetted area. Official formula (2026-07-22
        %   resolution): Roskam Vol. II Eq. 12.1, variable root/tip t/c.
        val = get_S_wet_wing(obj)

        %GET_S_WET_HT  Horizontal tail wetted area.
        val = get_S_wet_HT(obj)

        %GET_S_WET_VT  Vertical tail wetted area.
        val = get_S_wet_VT(obj)

        %GET_S_WET_FUSELAGE  Fuselage wetted area (cylindrical midsection model).
        val = get_S_wet_fuselage(obj)

        %GET_S_WET_DUCT  Inlet + engine duct wetted area (frustum formula).
        %   Moved from the former GeometryModelL3 (Geometry L3 eliminated
        %   2026-07-22, merged into L2 — see GeomL2.md's dated note).
        val = get_S_wet_duct(obj)

        %GET_S_EXPOSED_WING  Passthrough accessor for the wing exposed area.
        %   Moved from the former GeometryModelL3.
        val = get_S_exposed_wing(obj)
    end
end
