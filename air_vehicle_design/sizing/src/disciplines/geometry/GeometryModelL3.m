classdef (Abstract) GeometryModelL3 < GeometryBase
%GEOMETRYMODELL3  Tier-2a abstract enforcer for Level-3 geometry.
%
%   Inherits GeometryBase directly — NOT GeometryModelL2 (each fidelity level
%   independently satisfies the Tier-1 contract, per the project three-tier
%   pattern). Mirrors GeometryModelL2's structure and, since Phase 2, its
%   PROPERTY MEANINGS: L3 is the detailed PHYSICAL / T.O.-geometry tier.
%
%   2026-07-24: GeomL3 (re)introduced (user decision, reversing the
%   2026-07-22 "Geometry has no L3").
%   2026-07-25 (Phase 2, locked user decision): promoted from a weights-only
%   tier to the FULL L3 geometry tier consumed by L3 geometry + aero + weights.
%   Authoritative spec: examples/F16A/F16GeomL3.md (§A the input/derived
%   classification, §B the rename, §C the complete L3-aero contract, §D Amax,
%   §E L_aircraft). This tier is HIGHER fidelity than GeomL2's Brandt-reference
%   geometry: where a physical/T.O. value differs from Brandt, GeomL3 uses the
%   physical one (VT LE sweep 47.5°, L_fus 47.5 ft, HT span B_h 18.5 ft as the
%   PRIMARY span, exposed HT/VT AR 2.114/1.294 and tapers 0.390/0.437). Those
%   divergences from GeomL2 are INTENTIONAL fidelity differences, not errors
%   (locked decision, VnV/BrandtF16A/todo.md 2026-07-24 GeomL3 + 2026-07-25
%   Phase 2 §§3/7).
%
%   ============================================================================
%   NAME COLLISION REMOVED — Phase 2 rename (F16GeomL3.md §B).
%
%   BEFORE 2026-07-25 this contract used AR_ht / lambda_ht / AR_vt / lambda_vt
%   for the EXPOSED planform (2.114 / 0.390 / 1.294 / 0.437) while
%   GeometryModelL2 used the SAME FOUR NAMES for the FULL planform (3.0 /
%   0.2275 / 1.6 / 0.5), and carried no S_ht / S_vt at all. Both tiers are
%   GeometryBase subclasses and F16AeroL2/F16AeroL3 accept `geom (1,1)
%   GeometryBase`, so injecting the wrong tier compiled, ran, and silently
%   resolved one property name to a different physical quantity — e.g.
%   F16AeroL3.get.l_ref_comp calls GeometryBase.compute_mac(g.c_root_ht,
%   g.lambda_ht), and Raymer 7th ed. Eq. 7.8 requires the FULL-planform taper
%   that goes with the chord it is handed; the exposed 0.390 would have produced
%   a wrong HT MAC, hence a wrong component Reynolds number, hence a wrong
%   Raymer Eq. 12.30 form factor, with no error and no warning.
%
%   AFTER the rename, on BOTH tiers:
%     * AR_ht / lambda_ht / S_ht / S_vt / AR_vt / lambda_vt  = FULL planform.
%     * S_exposed_ht / S_exposed_vt                          = exposed planform.
%     * AR_exposed_ht / lambda_exposed_ht / AR_exposed_vt /
%       lambda_exposed_vt = the physical exposed-planform values the Raymer
%       Eq. 15.2/15.3 weights build-up wants — unambiguous by name, L3 only.
%     * H_max_fuselage = the max fuselage DEPTH (weights' "D_fus", Raymer
%       Eq. 15.4). The Dependent D_fus is the EQUIVALENT diameter (W+H)/2 = 6.0
%       used ONLY for the Roskam Eq. 12.3 fuselage S_wet term — a weights DI
%       must read H_max_fuselage, NOT D_fus (residual trap, todo 2026-07-24
%       GeomL3 §5; the same is true of S_exposed_ht/_vt vs S_ht/S_vt).
%   ============================================================================
%
%   INPUT vs DERIVED — the optimization-ready pattern (per CLAUDE.md; see
%   F16GeomL2.m for the reference implementation). A concrete class satisfies
%   each abstract property with EITHER a stored (mutable) property for a
%   genuine design-variable input, OR a `Dependent` property whose getter
%   recomputes live from the inputs for a derived quantity — never a frozen
%   constant for something derivable. Every property below is tagged [INPUT] or
%   [DERIVED] with the kind F16GeomL3 must use; F16GeomL3.md §A.1/§A.2 carry
%   the authoritative 33-input / 34-derived classification and every citation.
%
%   Nothing derivable may stay frozen (§A.3). Five quantities that WERE stored
%   inputs before Phase 2 are now [DERIVED] and must not be re-frozen:
%     AR_ht (= B_h^2/S_ht — Decision 1, see below), S_exposed_ht,
%     S_exposed_vt, tc_ht, tc_vt.
%   A sixth, engine SLS thrust, left geometry entirely: it is injected from a
%   propulsion object and is concrete-only (see below).
%
%   DECISION 1 (user, 2026-07-25 — option B, "physical span primary"): the
%   whole L3 HT planform is fixed by the S_ht + B_h INPUT PAIR, and AR_ht is
%   [DERIVED] = B_h^2/S_ht = 3.1690. Rationale: area and span are what a 3-view
%   measures; aspect ratio is definitional. A stored AR_ht alongside both S_ht
%   and B_h would be self-contradictory (sqrt(3.0*108) = 18.0 ft, not 18.5) AND
%   would go stale the instant an optimizer moved the span. Brandt Main!C19 =
%   3.0 is now a comparison reference, not an input. Consequences, all BY
%   DESIGN: c_root_ht 9.5118, c_tip_ht 2.1639, S_exposed_ht 51.1486 (+2.611 %
%   vs Brandt Geom!8), HT MAC 6.6085, QC/TE_sweep_ht 32.6400 / 2.5617°.
%
%   VERTICAL-TAIL SWEEP FORM: QC_sweep_vt / TE_sweep_vt take
%   GeometryBase.convert_sweep_panel (SINGLE-PANEL, 2/AR), never convert_sweep.
%   A vertical tail is one panel — root->tip spans the full b_vt — so the
%   mirrored 4/AR coefficient double-counts the taper term. Wing and HT are
%   mirrored surfaces and keep convert_sweep.
%
%   AREA-RULED Amax (sub-step 2h, locked user decision 2026-07-25). L3's Amax
%   is NO LONGER the fuselage-envelope ellipse (pi/4)*W*H — that is the
%   LOW-fidelity definition per readme_geom.md §7's own fidelity table, and it
%   had been sitting in the finest tier, inflating the Raymer Eq. 12.44
%   Sears-Haack term by +23.15%. It is now the whole-aircraft area-ruled
%   maximum, MAX over stations of fuselage + wing + HT + VT + nacelle cross-
%   sections less an n_engines*pi*D^2/5 engine flow-through deduction
%   [Brandt Geom!H26:H45 -> H47]. GeometryModelL2 KEEPS the ellipse: it is the
%   right answer for the low-fidelity tier. Six new [INPUT]s pay for it — five
%   x-stations/counts plus the NORMALIZED fuselage frame table — and every
%   intermediate it needs (exposed root chords, exposed spans, Xexp stations,
%   engine length, nacelle aft limit) is [DERIVED], never stored: todo.md
%   2026-07-25 Phase 2 §16.1 verified each one is derivable from inputs L3
%   already carries. Equations and citations live in the GeomL3 toolbox.
%
%   PROPULSION INJECTION (Phase 2/3a): engine SLS thrust is NOT geometry spec
%   data and is no longer a geometry input. The concrete class takes a required
%   injected propulsion object and exposes T_AB_SLS_lb as Dependent on
%   prop.T_SL, so the nacelle diameter — and hence duct wetted area, and hence
%   CD0 — tracks the engine instead of staying pinned to a stale 23,770 lbf
%   copy. T_AB_SLS_lb and the injected object are deliberately NOT in this
%   abstract contract: they are engine, not airframe, data (the same judgment
%   F16GeomL2 already documents for T_AB_SLS_lb), and a different concrete
%   class may size its duct differently. D_inlet / D_exit / L_duct ARE in the
%   contract, because L3 aero reads them.
%
%   Inheritance: GeometryBase → GeometryModelL3 → F16GeomL3
%   (GeomL3 is the static toolbox alongside, NOT in the chain.)
%
%   Declares no equations and no formula constants — those live in the GeomL3
%   static toolbox and the reused GeomL2 / GeometryBase statics.

    % Abstract properties cannot have validation attributes in MATLAB.
    % Size/type validation is enforced in the concrete class (F16GeomL3).

    % ── Fuselage / whole aircraft ───────────────────────────────────────── %
    properties (Abstract)
        L_fus             % Fuselage length (ft)               [INPUT]  47.5, physical
        L_fuselage        % Mirrors L_fus (GeometryModelL2 contract parity) [DERIVED]
        W_max_fuselage    % Maximum fuselage width (ft)        [INPUT]
        H_max_fuselage    % Maximum fuselage DEPTH (ft)        [INPUT]  weights' "D_fus"
        frames_normalized % (N,3) NORMALIZED frame table       [INPUT]  cols [x/L, w/W_max, h/H_max]
        D_fus             % Equivalent diameter (W+H)/2 (ft)   [DERIVED] Roskam Eq. 12.3 term only
        Amax              % Max cross-sectional area (ft²)     [DERIVED] AREA-RULED buildup; Raymer Eq. 12.44
        L_aircraft        % Overall aircraft length (ft)       [INPUT]  Raymer Eq. 12.44 only; NOT L_fus
    end

    % ── Main wing (full-planform inputs; everything else DERIVED) ───────── %
    properties (Abstract)
        AR_wing        % Wing aspect ratio                     [INPUT]  weights' "AR_w"
        lambda_wing    % Wing taper ratio (FULL planform)      [INPUT]  weights' "lambda_w"
        LE_sweep_wing  % Wing LE sweep (deg)                   [INPUT]  weights' "Lambda_LE_w"
        tc_wing        % Wing uniform t/c                      [INPUT]  wing has no root/tip split
        S_csw          % Wing control-surface area (ft²)       [INPUT]  weights' "S_csw"
        x_apex_wing    % Wing apex (root LE) x-station (ft)    [INPUT]  17.786 [Brandt Main!B23]
        b_wing         % Wing span (ft)                        [DERIVED]
        c_root_wing    % Wing root chord (ft)                  [DERIVED] Raymer Eq. 7.6
        c_tip_wing     % Wing tip chord (ft)                   [DERIVED] Raymer Eq. 7.7
        cbar_wing      % Wing MAC (ft)                         [DERIVED] Raymer Eq. 7.8; aero l_ref_comp(1)
        QC_sweep_wing  % Wing Λ_c/4 (deg)                      [DERIVED] convert_sweep(x=0.25)
        TE_sweep_wing  % Wing Λ_TE (deg)                       [DERIVED] convert_sweep(x=1.0)
        tc_r_wing      % Wing root t/c (mirrors tc_wing)       [DERIVED] weights' "tc_root"
        tc_t_wing      % Wing tip  t/c (mirrors tc_wing)       [DERIVED]
        S_exposed_wing % Exposed wing planform area (ft²)      [DERIVED] weights' "S_w"
        S_wet_wing     % Wing wetted area (ft²)                [DERIVED] Roskam Eq. 12.1
    end

    % ── Horizontal tail — FULL planform from the S_ht + B_h pair ────────── %
    properties (Abstract)
        S_ht              % FULL reference planform area (ft²)  [INPUT]  108; same meaning as L2
        B_h               % HT full span (ft)                   [INPUT]  18.5, PRIMARY (Decision 1)
        lambda_ht         % FULL-planform taper ratio           [INPUT]  0.2275
        LE_sweep_ht       % HT LE sweep (deg)                   [INPUT]  40
        tc_r_ht           % HT root t/c                         [INPUT]  0.060 [T.O. Sec. I]
        tc_t_ht           % HT tip  t/c                         [INPUT]  0.035 [T.O. Sec. I]
        F_w               % Fuselage width at HT (ft)           [INPUT]  weights' "F_w"
        AR_exposed_ht     % HT EXPOSED aspect ratio             [INPUT]  2.114; weights' "AR_ht"
        lambda_exposed_ht % HT EXPOSED taper ratio              [INPUT]  0.390; weights' "lambda_ht"
        x_le_ht           % HT root LE x-station (ft)           [INPUT]  36.0 [Brandt Main!C23]
        AR_ht             % FULL aspect ratio = B_h²/S_ht       [DERIVED] 3.1690 (Decision 1)
        b_ht              % HT span (ft), mirrors B_h           [DERIVED]
        c_root_ht         % HT root chord (ft)                  [DERIVED] Raymer Eq. 7.6
        c_tip_ht          % HT tip chord (ft)                   [DERIVED] Raymer Eq. 7.7
        QC_sweep_ht       % HT Λ_c/4 (deg)                      [DERIVED] convert_sweep(x=0.25)
        TE_sweep_ht       % HT Λ_TE (deg)                       [DERIVED] convert_sweep(x=1.0)
        tc_ht             % HT uniform t/c = (tc_r+tc_t)/2      [DERIVED] 0.0475
        S_exposed_ht      % Exposed HT planform area (ft²)      [DERIVED] 51.1486; weights' "S_ht"
        S_wet_ht          % HT wetted area (ft²)                [DERIVED] Roskam Eq. 12.1
    end

    % ── Vertical tail — FULL planform, single panel ─────────────────────── %
    properties (Abstract)
        S_vt              % FULL reference planform area (ft²)  [INPUT]  60; same meaning as L2
        AR_vt             % FULL aspect ratio (single panel)    [INPUT]  1.6
        lambda_vt         % FULL-planform taper ratio           [INPUT]  0.5
        LE_sweep_vt       % VT LE sweep (deg)                   [INPUT]  47.5, physical; weights' "Lambda_LE_vt"
        tc_r_vt           % VT root t/c                         [INPUT]  0.053 [T.O. Sec. I]
        tc_t_vt           % VT tip  t/c                         [INPUT]  0.030 [T.O. Sec. I]
        S_r               % VT rudder area (ft²)                [INPUT]  weights' "S_r"
        H_t               % HT height above fuselage CL (ft)    [INPUT]  weights' "H_t"
        H_v               % VT height / nonzero denominator (ft)[INPUT]  weights' "H_v"
        AR_exposed_vt     % VT EXPOSED aspect ratio             [INPUT]  1.294; weights' "AR_vt"
        lambda_exposed_vt % VT EXPOSED taper ratio              [INPUT]  0.437; weights' "lambda_vt"
        x_le_vt           % VT root LE x-station (ft)           [INPUT]  36.0 [Brandt Main!H23]
        b_vt              % VT span (ft), full single panel     [DERIVED] sqrt(S_vt*AR_vt), NOT halved
        c_root_vt         % VT root chord (ft)                  [DERIVED] Raymer Eq. 7.6
        c_tip_vt          % VT tip chord (ft)                   [DERIVED] Raymer Eq. 7.7
        QC_sweep_vt       % VT Λ_c/4 (deg)                      [DERIVED] convert_sweep_PANEL(x=0.25)
        TE_sweep_vt       % VT Λ_TE (deg)                       [DERIVED] convert_sweep_PANEL(x=1.0)
        tc_vt             % VT uniform t/c = (tc_r+tc_t)/2      [DERIVED] 0.0415
        S_exposed_vt      % Exposed VT planform area (ft²)      [DERIVED] 40.8897; weights' "S_vt"
        S_wet_vt          % VT wetted area (ft²)                [DERIVED] Roskam Eq. 12.1
    end

    % ── Inlet + engine duct ─────────────────────────────────────────────── %
    % T_AB_SLS_lb and the injected propulsion object are deliberately NOT here
    % (engine, not airframe, data — see the class header). D_inlet/D_exit/
    % L_duct are, because L3 aero reads them as D_comp(5) / l_ref_comp(5).
    properties (Abstract)
        L_duct         % Inlet-duct length (ft)                [INPUT]  14.0 [Brandt Main!F32]
        x_inlet        % Inlet-lip x-station (ft)              [INPUT]  15.0 [Brandt Main!F31] — NOT 14.0
        n_engines      % Number of engines (--)                [INPUT]  1 [Brandt Main!B28]
        D_inlet        % Nacelle/inlet diameter (ft)           [DERIVED] sqrt(T_AB_SLS_lb/1900)
        D_exit         % Duct exit diameter (ft) = D_inlet     [DERIVED] constant-section nacelle
        L_engine       % Engine length (ft) = 4.5*D_inlet      [DERIVED] [Brandt Geom!D475]
        x_nacelle_aft  % Nacelle aft limit (ft)                [DERIVED] x_inlet+L_duct+L_engine [Geom!C484]
    end

    % ── Area-ruled Amax buildup — DERIVED intermediates ─────────────────── %
    % These nine, plus L_engine and x_nacelle_aft declared with the duct above,
    % are recomputed live from the inputs; todo.md 2026-07-25 Phase 2 §16.1
    % verified every one is derivable, so none may be stored.
    % Declared in the contract (rather than left as concrete-only locals)
    % because they are also the Brandt comparison-report rows — Geom!F/G/B
    % columns of the Geom!A5:I10 exposed-lifting-surface table.
    % Formulas + citations: GeomL3.compute_c_root_exposed and the class header.
    properties (Abstract)
        c_exp_root_wing % Wing exposed root chord (ft)   [DERIVED] 13.3564 [Brandt Geom!F7]
        c_exp_root_ht   % HT exposed root chord (ft)     [DERIVED] 6.7315  [cf. Geom!F8 = 6.8391]
        c_exp_root_vt   % VT exposed root chord (ft)     [DERIVED] 7.1233  [Brandt Geom!F10]
        G_hs_exp_wing   % Wing exposed half-span (ft)    [DERIVED] 11.5    [Brandt Geom!G7]
        G_hs_exp_ht     % HT exposed half-span (ft)      [DERIVED] 5.75    [cf. Geom!G8 = 5.5]
        G_hs_exp_vt     % VT exposed span (ft), 1 panel  [DERIVED] 7.2980  [Brandt Geom!G10]
        Xexp_wing       % Wing exposed-root LE x (ft)    [DERIVED] 20.7226 [Brandt Geom!B7]
        Xexp_ht         % HT exposed-root LE x (ft)      [DERIVED] 38.9368 [Brandt Geom!B8]
        Xexp_vt         % VT exposed-root LE x (ft)      [DERIVED] 38.7283 [cf. Geom!B10 = 38.0978]
    end

    % ── Configuration ──────────────────────────────────────────────────── %
    properties (Abstract)
        L_t            % Tail arm, wing ¼-MAC → HT ¼-MAC (ft)  [INPUT]  weights' "L_t"
        S_cs           % Total control-surface area (ft²)      [INPUT]  weights' "S_cs"
    end

    methods (Abstract)
        %GET_S_WET_WING  Wing wetted area (ft²). OFFICIAL formula at L3
        %   (Decision 2, user 2026-07-25): Roskam Vol. II Eq. 12.1, variable
        %   root/tip t/c. Brandt's uniform-t/c Geom!B13 form is a
        %   comparison-report alternate only.
        val = get_S_wet_wing(obj)

        %GET_S_WET_HT  Horizontal-tail wetted area (ft²). Roskam Eq. 12.1.
        val = get_S_wet_HT(obj)

        %GET_S_WET_VT  Vertical-tail wetted area (ft²). Roskam Eq. 12.1.
        val = get_S_wet_VT(obj)

        %GET_S_WET_FUSELAGE  Fuselage wetted area (ft²). Roskam Eq. 12.3.
        val = get_S_wet_fuselage(obj)

        %GET_S_WET_DUCT  Inlet + engine-duct wetted area (ft²), frustum lateral
        %   area [Raymer 6th ed. Sec. 7.3]. ADDED in Phase 2 (2026-07-25): L3
        %   aero reads it as S_wet_comp(5).
        val = get_S_wet_duct(obj)

        %GET_S_EXPOSED_WING  Passthrough accessor for the wing exposed area.
        val = get_S_exposed_wing(obj)
    end
end
