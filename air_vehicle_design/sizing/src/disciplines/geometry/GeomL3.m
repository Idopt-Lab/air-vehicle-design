classdef GeomL3
%GEOML3  Level-3 geometry static toolbox: object-reading accessors for the
%   detailed PHYSICAL / T.O.-geometry tier, plus the low-level AREA-RULING
%   formulas that exist nowhere else in the geometry stack.
%
%   Call as GeomL3.method_name(args) — no instantiation required.  Not in the
%   inheritance chain.  The concrete class (F16GeomL3) inherits from
%   GeometryModelL3 and calls these statics to implement each abstract method.
%
%   2026-07-24: GeomL3 (re)introduced (user decision, reversing 2026-07-22).
%   2026-07-25 (Phase 2): promoted from a weights-only tier to the FULL L3
%   geometry tier consumed by L3 geometry + aero + weights (locked user
%   decision; examples/F16A/F16GeomL3.md is the authoritative spec).
%   2026-07-25 (Phase 2, SUB-STEP 2h): the AREA-RULED Amax buildup landed here.
%
%   Everything OTHER than the area-ruling block stays DELIBERATELY THIN: every
%   lifting-surface / fuselage / duct wetted-area equation is REUSED from the
%   GeomL2 toolbox or from the GeometryBase planform identities.  Those
%   high-level wrappers only select which reused low-level static to call, in
%   what order, with which inputs — the equation citations therefore live on the
%   reused statics, and each wrapper names the reused static and its source.
%
%   TWO formulas needed earlier in Phase 2 do NOT live here, deliberately
%   (F16GeomL3.md §C reuse gaps; todo.md 2026-07-25 §12):
%     GeometryBase.compute_Amax_elliptical(W_max, H_max)  — the LOW-fidelity
%       fuselage-envelope ellipse.  Still the L2 answer; NO LONGER the L3
%       answer (see the sub-step 2h note below).  No pinnable equation
%       number (§D).
%     GeometryBase.compute_nacelle_diameter(T_AB_SLS_lb)  — the sqrt(T/1900)
%       nacelle formula previously existed ONLY as an inline expression inside
%       F16GeomL2.get.D_inlet, i.e. an uncited magic number about to be
%       duplicated across two tiers.  Extracted and cited once; BOTH
%       F16GeomL2 and F16GeomL3 call it.
%   Both were briefly authored into THIS file during Phase 2 and then moved to
%   GeometryBase (2026-07-25), because both are fidelity-INDEPENDENT identities
%   used by more than one tier — leaving them here made F16GeomL2, an L2
%   concrete class, depend on the L3 toolbox, inverting the fidelity layering.
%   GeometryBase's "Fidelity-independent planform identities" block (alongside
%   compute_span / compute_mac / convert_sweep) is their correct home.
%
%   ======================================================================== %
%   SUB-STEP 2h (locked user decision, 2026-07-25) — Amax is now AREA-RULED.
%
%   WHAT CHANGED.  L3's Amax was GeometryBase.compute_Amax_elliptical =
%   (pi/4)*W_max*H_max = 27.488936 ft^2.  That is the FUSELAGE-ONLY, LOW-
%   fidelity definition — readme_geom.md §7's own fidelity table classifies it
%   that way ("Amax | low: Cylindrical fuselage only | high: Full component
%   buildup — wing + tail + nacelle added") — and it had been placed in the
%   FINEST tier, where the Raymer 6th ed. Eq. 12.44 Sears-Haack term wants the
%   whole-aircraft area-ruled maximum.  It inflated CD0_wave by +23.15 % and
%   pushed the L3 constraint optimum out of bounds (todo.md 2026-07-25 Phase 2
%   §16.6 / §17).  L2 KEEPS the envelope ellipse — it is the correct answer for
%   the LOW-fidelity tier, and F16GeomL2 was not touched by this sub-step.
%
%   WHAT REPLACED IT.  Brandt's whole-aircraft buildup, Geom!H26:H45 -> H47:
%       Amax = MAX_over_stations( A_fuse + A_wing + A_HT + A_VT + A_nacelle )
%              - n_engines * pi * D_engine^2 / 5
%   with each component from readme_geom.md §4.5 (lifting surfaces, §4.2
%   (fuselage frames) and Geom!AE31 (nacelle).  Low-level statics below;
%   assembled by the high-level get_Amax(obj).
%
%   THE FOUR DECISIONS THIS BUILDUP ENCODES (all locked by the user
%   2026-07-25; recorded here so no future reader has to reconstruct them):
%     1. VARIANT D — the fuselage area distribution comes from a NORMALIZED
%        20-frame table (x/L, w/W_max, h/H_max) rescaled by THIS tier's own
%        L_fus / W_max_fuselage / H_max_fuselage.  Storing Brandt's raw table
%        instead left W_max with the WRONG SIGN on Amax and H_max completely
%        DEAD (todo §16.5).  The affine-rescaling assumption behind variant D
%        is ★ UNCITED — see denormalize_frames below.
%     2. "/5" — the inlet flow-through deduction keeps Brandt's bare literal
%        divisor 5, not the self-consistent 4.  UNJUSTIFIED in the workbook;
%        todo.md 2026-07-25 Phase 2 §5 stays OPEN.  See compute_Amax_area_ruled.
%     3. STRAKE DEFERRED — no strake component, and Brandt's two documented
%        strake bugs (readme_geom.md §5.1) are DECLINED.  Provably worth
%        0.000 % of Amax here (todo §16.2/§16.3).  See compute_surface_cs_area.
%     4. x_inlet = 15.0, NOT 14.0 — the live workbook chain (todo §18).
%
%   DISCRETIZATION (documented choice, todo.md 2026-07-25 Phase 2 §20):
%   compute_frame_cs_area replicates Brandt's SIX-POINT cosine sampling rather
%   than the exact integral, for consistency with decisions 2 and 4 above (both
%   of which follow Brandt's convention).  The exact integral is available as
%   the labelled alternate compute_frame_cs_area_exact and is +0.83 % per frame
%   / +0.76 % on Amax.  Neither is "more correct" as physics — the cosine
%   section is itself a shape model; the 6-point form is the one every expected
%   value in the sub-step 2h spec is built on.
%
%   VERIFIED LIVE 2026-07-25 (mcp__matlab__evaluate_matlab_code):
%     as-built L3 (L_fus = 47.5) ....... Amax = 24.703652 ft^2  (-1.62 % vs
%                                        Brandt Geom!B20/H47 = 25.110556, a
%                                        physical fidelity divergence)
%     ROUND-TRIP CONTROL, L_fus := 46.5  Amax = 25.110534 ft^2  (-0.000 % vs
%                                        Brandt; normalising and de-normalising
%                                        by the same envelope is an identity,
%                                        so this proves the method rather than
%                                        fitting it)
%   ======================================================================== %
%
%   S_wet scope note (CHANGED in Phase 2): GeomL3's total wetted area is now
%   wing + HT + VT + fuselage + DUCT, matching GeomL2 — the L3 input set gained
%   L_duct and the propulsion-injected nacelle diameter, so the duct component
%   exists at this tier.  (Before Phase 2 the L3 total was airframe-only
%   because there was no duct geometry to add.)
%
%   OFFICIAL vs ALTERNATE lifting-surface S_wet (Decision 2, user 2026-07-25;
%   F16GeomL3.md §A.5).  OFFICIAL at L3 = Roskam Vol. II Eq. 12.1
%   (GeomL2.compute_roskam_planform), fed the T.O. root/tip t/c splits — the
%   same choice L2 makes.  Brandt's own uniform-t/c Geom!B13 form stays
%   reachable as GeomL2.compute_wet_planform for the COMPARISON REPORT ONLY,
%   never as the computed value; call it as
%   GeomL2.compute_wet_planform(g.S_exposed_ht, g.tc_ht) with the DERIVED
%   root/tip mean tc_ht = 0.0475 / tc_vt = 0.0415 as the uniform t/c, exactly
%   as the L2 report rows do.  Recorded deliberately: the official choice moves
%   L3 FURTHER from Brandt's ground truth (wing +1.11 %, HT +4.47 %, VT
%   +1.78 %) and that is CORRECT, not a regression — Brandt's GT figures are
%   the output of his own coarser uniform-t/c formula fed his own inputs, so
%   the alternate matches them almost exactly BY CONSTRUCTION.
%
%   REUSED EQUATIONS (see GeomL2.m / GeometryBase.m for the cited formulas):
%     Lifting-surface S_wet, OFFICIAL (variable root/tip t/c):
%       GeomL2.compute_roskam_planform
%       S_wet = 2*S_exp*(1 + 0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda))
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.1]
%     Lifting-surface S_wet, ALTERNATE (uniform t/c): GeomL2.compute_wet_planform
%       S_wet = S_exposed*(1.977 + 0.52*tc)   [Brandt F-16A workbook, Geom!B13]
%     Fuselage S_wet (cylindrical midsection): GeomL2.compute_s_wet_fus_cyl
%       [Jan Roskam, Airplane Design Vol. II, DAR Corp., 1997, Eq. 12.3]
%     Duct/inlet S_wet (frustum lateral area): GeomL2.compute_s_wet_duct
%       [Raymer, Aircraft Design: A Conceptual Approach, 6th ed., Sec. 7.3]
%     Exposed lifting-surface area (fuselage-clipped):
%       GeomL2.compute_S_exposed_horizontal / _vertical
%       [Brandt F-16A workbook; VnV/BrandtF16A/readme_geom.md Section 4.3]
%     Span / root chord / tip chord / MAC: GeometryBase.compute_span /
%       _root_chord / _tip_chord / _mac [span definitional; chords and MAC
%       Raymer 7th ed. Eq. 7.6 / 7.7 / 7.8].
%     Sweep-station conversion: GeometryBase.convert_sweep (MIRRORED, 4/AR —
%       wing and horizontal tail) and GeometryBase.convert_sweep_panel
%       (SINGLE-PANEL, 2/AR — vertical tail) [standard swept-wing planform
%       identity, uncited to an edition/equation number; see GeometryBase.md].
%     Nacelle diameter: GeometryBase.compute_nacelle_diameter
%       D_engine = sqrt(T_AB_SLS/1900)  [Brandt Geom!C475; Engn(s)!L22 = 1900].

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result. Each simply
        % selects a REUSED GeomL2 low-level static — no new formula here.
        % (get_Amax is the one exception: it assembles the sub-step 2h
        % area-ruling statics further down this file.)
        % ================================================================== %

        function val = get_S_wet(obj)
        %GET_S_WET  Total wetted area: wing + HT + VT + fuselage + duct.
        %   The duct term was ADDED in Phase 2 (2026-07-25) together with the
        %   L_duct input and the propulsion-injected nacelle diameter — see the
        %   class header's S_wet scope note. NO W_TO argument: L3 has real
        %   planform geometry (mirrors the F16GeomL2 get_S_wet(obj) decision,
        %   2026-07-22).
        %   Lifting-surface terms use the OFFICIAL Roskam Eq. 12.1 formula
        %   (Decision 2); the Brandt uniform-t/c alternate is a report row only.
            val = GeomL3.get_S_wet_wing(obj) + GeomL3.get_S_wet_HT(obj) + ...
                  GeomL3.get_S_wet_VT(obj)   + GeomL3.get_S_wet_fuselage(obj) + ...
                  GeomL3.get_S_wet_duct(obj);
        end

        function val = get_S_wet_wing(obj)
        %GET_S_WET_WING  OFFICIAL: Roskam Vol. II Eq. 12.1 (variable root/tip
        %   t/c) via GeomL2.compute_roskam_planform. Wing is modeled uniform-tc,
        %   so tc_r_wing/tc_t_wing both mirror tc_wing and Eq. 12.1 degenerates
        %   to its equal-t/c special case. Decision 2 (user, 2026-07-25).
            val = GeomL2.compute_roskam_planform(obj.S_exposed_wing, ...
                      obj.tc_r_wing, obj.tc_t_wing, obj.lambda_wing);
        end

        function val = get_S_wet_HT(obj)
        %GET_S_WET_HT  OFFICIAL: Roskam Vol. II Eq. 12.1 via
        %   GeomL2.compute_roskam_planform, fed the T.O. 1F-16A-1 Sec. I
        %   biconvex root/tip splits (0.060 / 0.035) and the FULL-planform
        %   taper. Decision 2 (user, 2026-07-25).
            val = GeomL2.compute_roskam_planform(obj.S_exposed_ht, ...
                      obj.tc_r_ht, obj.tc_t_ht, obj.lambda_ht);
        end

        function val = get_S_wet_VT(obj)
        %GET_S_WET_VT  OFFICIAL: Roskam Vol. II Eq. 12.1 via
        %   GeomL2.compute_roskam_planform, fed the T.O. 1F-16A-1 Sec. I
        %   biconvex root/tip splits (0.053 / 0.030) and the FULL-planform
        %   taper. Decision 2 (user, 2026-07-25).
            val = GeomL2.compute_roskam_planform(obj.S_exposed_vt, ...
                      obj.tc_r_vt, obj.tc_t_vt, obj.lambda_vt);
        end

        function val = get_S_wet_fuselage(obj)
        %GET_S_WET_FUSELAGE  Roskam Vol. II Eq. 12.3 (cylindrical midsection)
        %   via GeomL2.compute_s_wet_fus_cyl(D_fus, L_fus). D_fus is the
        %   equivalent diameter (W+H)/2, NOT the max depth H_max_fuselage.
            val = GeomL2.compute_s_wet_fus_cyl(obj.D_fus, obj.L_fus);
        end

        function val = get_S_wet_duct(obj)
        %GET_S_WET_DUCT  Inlet + engine-duct wetted area, frustum lateral area
        %   [Raymer 6th ed. Sec. 7.3] via GeomL2.compute_s_wet_duct. ADDED in
        %   Phase 2: L3 aero reads it as S_wet_comp(5). D_inlet == D_exit here
        %   (Brandt models the nacelle as a constant-diameter cylinder), so the
        %   frustum degenerates to pi*D*L.
            val = GeomL2.compute_s_wet_duct(obj.D_inlet, obj.D_exit, obj.L_duct);
        end

        function val = get_S_exposed_wing(obj)
        %GET_S_EXPOSED_WING  Passthrough accessor for the DERIVED wing exposed
        %   area (the Dependent getter does the compute).
            val = obj.S_exposed_wing;
        end

        function val = get_Amax(obj)
        %GET_AMAX  Whole-aircraft AREA-RULED maximum cross-sectional area, ft^2.
        %   [Brandt F-16A workbook, Geom!H26:H45 -> Geom!H47 -> Geom!B20;
        %    VnV/BrandtF16A/readme_geom.md Sections 4.2 / 4.5]
        %
        %   Amax = MAX_x( A_fuse + A_wing + A_HT + A_VT + A_nacelle )
        %          - n_engines * pi * D_engine^2 / 5
        %
        %   Feeds the Raymer 6th ed. Eq. 12.44 Sears-Haack supersonic wave-drag
        %   term as (Amax/L_aircraft)^2.  Replaces the fuselage-only envelope
        %   ellipse at THIS tier only (sub-step 2h, locked user decision
        %   2026-07-25); GeometryBase.compute_Amax_elliptical stays the L2
        %   answer, which is where readme_geom.md §7 says it belongs.
        %
        %   EVERY input to the buildup is read live off obj — the stations are
        %   rescaled from the normalized frame table on every call and every
        %   chord / sweep / Xexp / diameter is a Dependent recompute — so Amax
        %   tracks an optimizer's mutations instead of freezing (CLAUDE.md
        %   "Optimization-ready property design").  Liveness measured 2026-07-25
        %   for +10 % on each input: W_max +9.164 %, H_max +9.164 % (identical —
        %   the frame area is exactly bilinear in w*h), L_fus +12.478 %, S_ref
        %   +4.184 %, LE_sweep_wing +7.289 %, prop.T_SL +0.795 %.  S_ht / B_h /
        %   S_vt / tc_ht are 0.000 % each: the tail cross-sections only begin
        %   aft of x ~ 38.7 ft while the governing station is far forward.  That
        %   is a genuine geometric fact for THIS configuration, not a dead
        %   input — under mutation the governing station can migrate aft
        %   (todo.md 2026-07-25 Phase 2 §16.5).
        %
        %   THE STRAKE IS DELIBERATELY ABSENT (locked user decision): its active
        %   range is 12.0 < x < 21.551 ft, and strake-out / strake-with-Brandt's-
        %   bug / strake-corrected all give an identical Amax (todo §16.2/§16.3).
            [x, w, h] = GeomL3.denormalize_frames(obj.frames_normalized, ...
                            obj.L_fus, obj.W_max_fuselage, obj.H_max_fuselage);

            A_fuse = GeomL3.compute_frame_cs_area(w, h);

            A_wing = GeomL3.compute_surface_cs_area(x, obj.Xexp_wing, ...
                         obj.c_exp_root_wing, obj.c_tip_wing, ...
                         obj.G_hs_exp_wing, obj.LE_sweep_wing, obj.tc_wing);

            A_HT   = GeomL3.compute_surface_cs_area(x, obj.Xexp_ht, ...
                         obj.c_exp_root_ht, obj.c_tip_ht, ...
                         obj.G_hs_exp_ht, obj.LE_sweep_ht, obj.tc_ht);

            A_VT   = GeomL3.compute_surface_cs_area(x, obj.Xexp_vt, ...
                         obj.c_exp_root_vt, obj.c_tip_vt, ...
                         obj.G_hs_exp_vt, obj.LE_sweep_vt, obj.tc_vt);

            A_nac  = GeomL3.compute_nacelle_cs_area(x, obj.n_engines, ...
                         obj.D_inlet, obj.x_inlet, obj.x_nacelle_aft);

            val = GeomL3.compute_Amax_area_ruled( ...
                      A_fuse + A_wing + A_HT + A_VT + A_nac, ...
                      obj.n_engines, obj.D_inlet);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math on scalars/vectors, no object.  Added in
        % sub-step 2h (2026-07-25) for the AREA-RULED Amax.  These are the only
        % formulas that originate in this toolbox; every other equation GeomL3
        % uses is reused from GeomL2 / GeometryBase (see the class header).
        % ================================================================== %

        function [x, w, h] = denormalize_frames(frames_normalized, L_fus, W_max, H_max)
        %DENORMALIZE_FRAMES  Rescale the stored NORMALIZED fuselage frame table
        %   to physical stations and section dimensions.
        %
        %       x = (x/L)      * L_fus      [ft]
        %       w = (w/W_max)  * W_max      [ft]
        %       h = (h/H_max)  * H_max      [ft]
        %
        %   frames_normalized — (N,3) double, columns [x_over_L, w_over_Wmax,
        %                       h_over_Hmax] in Brandt's nose->tail frame order.
        %
        %   SOURCE OF THE TABLE ITSELF: Brandt's 20-station fuselage cross-
        %   section table [Brandt Main!A34:F53; readme_geom.md §2], divided
        %   through by his own envelope (L 46.5 [Main!B32], W 7.0 [Main!C32],
        %   H 5.0 [Main!D32]) — see examples/F16A/f16a_L3.json
        %   .geometry.fuselage._frames_normalized_src for the full provenance,
        %   including which columns were dropped and why (z_chine and z_center
        %   cancel EXACTLY out of the cross-sectional AREA — the integrand is
        %   dz = h*cos(pi/2*t), which contains neither; readme_geom.md §4.2).
        %
        %   ★ UNCITED ASSUMPTION, stated plainly and not papered over: the
        %   AFFINE-SCALING assumption — that a fixed normalized cross-section
        %   shape distribution can be rescaled by the fuselage envelope — has NO
        %   textbook source.  No Raymer / Roskam / Mattingly / metabook equation
        %   number exists for it anywhere in this repo and none was invented.
        %   It is the same class of citation gap as the elliptical-Amax identity;
        %   STANDING OPEN item, VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §4
        %   (which also records the one lead found: the repo's own Roskam Vol. II
        %   extract names Roskam Part VI as the authority for cross-sectional
        %   area-ruling, and Roskam Part VI is not in this repo).
        %
        %   WHY VARIANT D AND NOT BRANDT'S RAW TABLE (locked user decision
        %   2026-07-25): with a frozen raw table, Amax responds to W_max with
        %   the WRONG SIGN (-0.561 % for +10 %, because W_max then enters only
        %   through the exposed-root-chord clip) and to H_max not at all.
        %   Normalizing puts both back, correctly and identically at +9.164 %
        %   (todo §16.5).  POSITIVE CONTROL: rescaling with L_fus = 46.5 returns
        %   Brandt's own stations bit-for-bit and Amax = 25.110534.
        %
        %   MODELLING CONSEQUENCE, real and not a data error: max(h/H_max) =
        %   1.50 at frame 6 — the CANOPY BULGE — so "max fuselage depth" is not
        %   the maximum frame height of the table it scales, and a 10 % deeper
        %   fuselage gets a 10 % taller canopy.
            arguments
                frames_normalized (:,3) double
                L_fus             (1,1) double {mustBePositive}
                W_max             (1,1) double {mustBePositive}
                H_max             (1,1) double {mustBePositive}
            end
            x = frames_normalized(:,1) * L_fus;
            w = frames_normalized(:,2) * W_max;
            h = frames_normalized(:,3) * H_max;
        end

        function A = compute_frame_cs_area(w, h)
        %COMPUTE_FRAME_CS_AREA  Cross-sectional area of one fuselage frame under
        %   Brandt's COSINE section model, on his SIX-POINT sampling grid.
        %   [VnV/BrandtF16A/readme_geom.md Section 4.2, "verified against Geom
        %    rows 51-61"; cross-checked against (never copied from)
        %    VnV/BrandtF16A/BrandtGeometry.frameCrossSection]
        %
        %   The section model, per §4.2:
        %       t   = [0, 0.2, 0.4, 0.6, 0.8, 1.0],   y = t*(w/2)
        %       z_upper(y) = z_chine + (z_top - z_chine)*cos(pi/2 * t)
        %       z_lower(y) = z_chine + (z_bot - z_chine)*cos(pi/2 * t)
        %       z_top = z_center + h/2,   z_bot = z_center - h/2
        %   so the local section HEIGHT is
        %       dz(t) = z_upper - z_lower = (z_top - z_bot)*cos(pi/2 * t)
        %             = h * cos(pi/2 * t)
        %   — the chine and centre offsets cancel exactly, which is why this
        %   static needs only (w, h) and why the stored frame table drops the
        %   two z columns (they survive only in the PERIMETER, which drives a
        %   different quantity this tier does not compute).  Then
        %       A = 2 * trapz(y, dz)                       [both sides]
        %         = 2 * (w/2) * h * trapz(t, cos(pi/2*t))
        %         = w * h * I_cos
        %   with I_cos the 6-point trapezoidal value of int_0^1 cos(pi/2 t) dt.
        %   The factored form is algebraically identical to integrating the
        %   polygon directly and is vectorized over the frame table.
        %
        %   DISCRETIZATION — a deliberate choice, not an accident.  I_cos =
        %   0.63137515 on 6 points, against the exact 2/pi = 0.63661977: the
        %   6-point rule is 0.824 % LOW.  Brandt's discrete value is kept, for
        %   consistency with the two sibling decisions in this sub-step that
        %   also follow his conventions (the /5 flow-through divisor and the
        %   coarse 20-station MAX), and because every expected value in the
        %   sub-step 2h specification is built on it: at the governing frame of
        %   the round-trip control (x = 29.1 ft, w = 5.5, h = 5.0) this returns
        %   17.3628 ft^2 where the exact integral gives 17.5070 ft^2.  The exact
        %   form is available as compute_frame_cs_area_exact and is +0.76 % on
        %   Amax.  Logged as an open item: todo.md 2026-07-25 Phase 2 §20.
            arguments
                w (:,1) double {mustBeNonnegative}
                h (:,1) double {mustBeNonnegative}
            end
            N_PTS = 6;                                % Brandt's sampling grid
            t     = linspace(0, 1, N_PTS);            % [0 .2 .4 .6 .8 1]
            I_cos = trapz(t, cos(pi/2 * t));          % 0.63137515
            A     = w .* h * I_cos;
        end

        function A = compute_frame_cs_area_exact(w, h)
        %COMPUTE_FRAME_CS_AREA_EXACT  LABELLED ALTERNATE to
        %   compute_frame_cs_area: the SAME cosine section model integrated
        %   exactly instead of on Brandt's 6-point grid.
        %       A = 2 * int_0^{w/2} h*cos(pi/2 * (2y/w)) dy = (2/pi) * w * h
        %   [same shape model: VnV/BrandtF16A/readme_geom.md Section 4.2]
        %
        %   NOT the computed value.  Provided so the +0.824 %-per-frame
        %   discretization gap is measurable rather than asserted, and so a
        %   comparison report can carry it as an alternate row — the same
        %   pattern GeomL2/GeomL3 already use for Brandt's uniform-t/c S_wet.
        %   At the round-trip control's governing frame (w = 5.5, h = 5.0) this
        %   returns 17.5070 ft^2 vs the 6-point 17.3628 ft^2; propagated through
        %   the whole buildup it moves the as-built L3 Amax from 24.703652 to
        %   24.891147 ft^2 (+0.76 %).  See todo.md 2026-07-25 Phase 2 §20.
            arguments
                w (:,1) double {mustBeNonnegative}
                h (:,1) double {mustBeNonnegative}
            end
            A = (2/pi) * w .* h;
        end

        function val = compute_c_root_exposed(c_root, c_tip, span_root_to_tip, span_clipped)
        %COMPUTE_C_ROOT_EXPOSED  Chord of a linearly-tapered lifting surface at
        %   the station where the fuselage side cuts it — i.e. the EXPOSED root
        %   chord.  Linear-taper interpolation:
        %
        %       c_exp_root = c_root - (span_clipped/span_root_to_tip)
        %                             * (c_root - c_tip)
        %
        %   [VnV/BrandtF16A/readme_geom.md Section 4.3; Brandt Geom!F7 (wing) /
        %    F8 (pitch ctrl) / F10 (vertical tail), the "Root Chord (exposed)"
        %    column of the Geom!A5:I10 exposed-lifting-surface table]
        %
        %   span_root_to_tip — geometric root -> tip distance the taper is
        %                      defined over: the HALF span b/2 for a mirrored
        %                      surface (wing, HT), the FULL single-panel span
        %                      b_vt for a vertical tail [readme_geom.md §4.3].
        %   span_clipped     — how much of that the fuselage hides: the
        %                      fuselage HALF-WIDTH for a horizontal surface, the
        %                      fuselage HALF-DEPTH for a vertical one (same §).
        %
        %   Verified 2026-07-25 against Brandt: wing 13.35641 (Geom!F7 =
        %   13.3564, exact), VT 7.12330 (Geom!F10 = 7.1233, exact).  The HT
        %   gives 6.73148 vs Brandt's 6.8391 — purely L3's Decision-1 span
        %   (18.5 vs 18.0), an intentional fidelity divergence, not an error.
        %
        %   PROVENANCE / PLACEMENT NOTE.  This expression already existed twice
        %   in the codebase as an unnamed LOCAL VARIABLE — inside
        %   GeomL2.compute_S_exposed_horizontal and
        %   GeomL2.compute_S_exposed_vertical — computed and then thrown away.
        %   Sub-step 2h needs it as a first-class value (the area-rule cosine
        %   columns are keyed on it), so it was extracted and cited here.  It
        %   BELONGS in GeomL2 beside those two statics (or in GeometryBase, as a
        %   fidelity-independent planform identity), with both of them
        %   refactored to call it; it is here only because GeomL2.m was outside
        %   the sub-step's editable scope.  Flagged for the coordinator.
            arguments
                c_root           (1,1) double {mustBePositive}
                c_tip            (1,1) double {mustBeNonnegative}
                span_root_to_tip (1,1) double {mustBePositive}
                span_clipped     (1,1) double {mustBeNonnegative}
            end
            val = c_root - (span_clipped/span_root_to_tip) * (c_root - c_tip);
        end

        function A = compute_surface_cs_area(x, Xexp, c_exp_root, c_tip, ...
                                             G_hs_exp, sweep_LE_deg, tc)
        %COMPUTE_SURFACE_CS_AREA  Cross-sectional area contributed by ONE
        %   lifting surface at each fuselage station x, under Brandt's
        %   closed-form COSINE area-distribution model.
        %   [VnV/BrandtF16A/readme_geom.md Section 4.5, "KEY DISCOVERY: the
        %    Excel does NOT use a NACA thickness integral"; Brandt Geom columns
        %    Y26:Y45 (wing), AA26:AA45 (pitch control), AC26:AC45 (vertical
        %    tail), rows 26-45 = the 20 frame stations.  Cross-checked against
        %    (never copied from) VnV/BrandtF16A/BrandtGeometry.brandtCSArea]
        %
        %   Active range:  Xexp < x < Xexp + X_max_range
        %       Area(x) = tc*(c_exp_root + c_tip)*y_span*(1 - cos(2*pi*xi))
        %                 / DIVISOR
        %   where
        %       X_max_range = MAX(c_exp_root, G_hs_exp*tan(sweep) + c_tip)
        %       X_max_cos   = MAX(c_exp_root, G_hs_exp*tan(sweep) + c_tip)
        %       y_span      = MIN(G_hs_exp, (x - Xexp)/tan(sweep))
        %       xi          = (x - Xexp)/X_max_cos
        %   and Area = 0 outside the active range.
        %
        %   Xexp     — x of the EXPOSED root leading edge (where the surface
        %              emerges from the fuselage) [Brandt Geom!B7/B8/B10].
        %   G_hs_exp — exposed half-span (mirrored surfaces) or exposed full
        %              span (vertical tail) [Brandt Geom!G7/G8/G10].
        %
        %   CITATION STATUS OF THE MODEL ITSELF: Brandt's own construction.  No
        %   "1 - cos" area-distribution formula, and no area-ruling method of
        %   any kind, appears in any reference extract in this repo; the one
        %   lead is that the repo's Roskam Vol. II extract names Roskam Part VI
        %   as the authority for area-ruling, and Part VI is not in this repo.
        %   No equation number was invented.  todo.md 2026-07-25 Phase 2 §4.
        %
        %   TWO BRANDT BUGS DELIBERATELY NOT REPLICATED (both readme_geom.md §5;
        %   CLAUDE.md forbids encoding a known error into this framework's own
        %   implementation, and both are numerically free to decline here):
        %     * VT column (Geom!AC31) uses the WING tip chord D$7 in the
        %       active-range test while using the VT tip chord D$10 in the
        %       cosine denominator — a copy-paste error that makes X_max_range
        %       and X_max_cos differ.  Here they are one expression, evaluated
        %       from the surface's OWN c_tip.  Worth 0.000 % of the F-16A Amax:
        %       the VT section starts at x ~ 38.73 ft, far aft of the governing
        %       station (todo §16.5).
        %     * STRAKE column (Geom!AG31) uses the pitch-control Xexp as its
        %       cosine reference and omits the /2 (divisor = 1).  The strake is
        %       DEFERRED entirely by locked user decision, so neither its clean
        %       nor its bugged column is implemented; DIVISOR is fixed at the
        %       wing/HT/VT value 2.  Declining the bug costs exactly nothing —
        %       strake-out, strake-bugged and strake-corrected give an identical
        %       Amax for this aircraft (todo §16.2/§16.3).
            arguments
                x            (:,1) double
                Xexp         (1,1) double
                c_exp_root   (1,1) double {mustBePositive}
                c_tip        (1,1) double {mustBeNonnegative}
                G_hs_exp     (1,1) double {mustBePositive}
                sweep_LE_deg (1,1) double
                tc           (1,1) double {mustBeNonnegative}
            end
            DIVISOR = 2;                 % wing / HT / VT (Brandt's strake col. uses 1 — see above)

            tan_sweep   = tand(sweep_LE_deg);
            X_max_range = max(c_exp_root, G_hs_exp*tan_sweep + c_tip);
            X_max_cos   = X_max_range;   % one expression: the VT copy-paste bug is NOT replicated

            active = x > Xexp & x < Xexp + X_max_range;
            y_span = min(G_hs_exp, (x - Xexp)/tan_sweep);
            xi     = (x - Xexp)/X_max_cos;

            A = zeros(size(x));
            A(active) = tc * (c_exp_root + c_tip) * y_span(active) ...
                        .* (1 - cos(2*pi*xi(active))) / DIVISOR;
        end

        function val = compute_engine_length(D_engine)
        %COMPUTE_ENGINE_LENGTH  Engine length from its diameter, ft.
        %       L_engine = 4.5 * D_engine
        %   F-16A: 4.5 * 3.537022 = 15.9166 ft.
        %
        %   [Brandt Geom!D475 = C475 * 'Engn(s) Old'!Q22, with
        %    'Engn(s) Old'!Q22 = ='Engn(s)'!R22 = 4.5 — cell chain live-verified
        %    2026-07-25, VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §18]
        %
        %   A slenderness ratio, not a textbook equation: no Raymer/Roskam/
        %   Mattingly equation number is claimed for it, only the workbook cell
        %   it comes from.  NB the source cell reads the 'Engn(s) Old' SHEET,
        %   which merely forwards to 'Engn(s)'!R22 — recorded in §18 because
        %   readme_geom.md §3 cites 'Engn(s)' directly.
            arguments
                D_engine (1,1) double {mustBePositive}
            end
            L_OVER_D = 4.5;
            val      = L_OVER_D * D_engine;
        end

        function A = compute_nacelle_cs_area(x, n_engines, D_engine, x_start, x_end)
        %COMPUTE_NACELLE_CS_AREA  Cross-sectional area contributed by the
        %   engine nacelle(s) at each fuselage station x — a CONSTANT-diameter
        %   cylinder over its active range, zero outside:
        %
        %       A(x) = n_engines * pi * D_engine^2 / 4   for x_start <= x <= x_end
        %            = 0                                 otherwise
        %
        %   [Brandt Geom!AE26:AE45; live cell formula 2026-07-25:
        %    Geom!AE31 = IF(C31>=C$480, IF(C31<=C$484, Main!B$28*3.1416/4*C$475^2, 0), 0)
        %    with Main!B28 = N_eng, Geom!C475 = D_engine.  Note the workbook's
        %    hardcoded 3.1416 here vs 3.141579 in Geom!H47 — MATLAB pi is used
        %    for both, which accounts for the ~2e-5 residual against the live
        %    cell value.  VnV/BrandtF16A/readme_geom.md Section 4.5]
        %
        %   x_start / x_end come from the LIVE workbook chain, not the replica's
        %   (todo.md 2026-07-25 Phase 2 §18):
        %       Geom!C480 = Main!F31          = x_inlet                 = 15.0
        %       Geom!C482 = C480 + Main!F32   = + duct length           = 29.0
        %       Geom!C484 = C482 + D475       = + L_engine (4.5*D)      = 44.9166
        %   i.e. inlet lip -> compressor face -> nozzle.  BrandtGeometry.m and
        %   readme_geom.md §4.5 instead use [14.0, 43.9166] — both endpoints
        %   1.0 ft low, because the read-only ground-truth JSON key
        %   `inlet_x_ft` = 14.0 is MISLABELLED (14.0 is Main!F32, the DUCT
        %   LENGTH; the genuine inlet station is 15.0).  Numerically identical
        %   over the F-16A's 20 frame stations — pure luck of the spacing — but
        %   only the live chain is defensible on any other grid.  Do NOT
        %   "correct" x_inlet back to 14.0.
        %
        %   Boundary test is inclusive at BOTH ends (>= / <=), matching the live
        %   IF() above; frame 6 sits exactly on x = 15.0 and IS included.
            arguments
                x         (:,1) double
                n_engines (1,1) double {mustBeNonnegative}
                D_engine  (1,1) double {mustBeNonnegative}
                x_start   (1,1) double
                x_end     (1,1) double
            end
            A = zeros(size(x));
            A(x >= x_start & x <= x_end) = n_engines * pi * D_engine^2 / 4;
        end

        function val = compute_Amax_area_ruled(A_total_stations, n_engines, D_engine)
        %COMPUTE_AMAX_AREA_RULED  Whole-aircraft area-ruled maximum cross-
        %   sectional area from a per-station total, less the engine
        %   flow-through deduction:
        %
        %       Amax = MAX(A_total_stations) - n_engines*pi*D_engine^2 / 5
        %
        %   [Brandt Geom!H47 = MAX(H26:H45) - Main!B28*3.141579*C475^2/5,
        %    surfaced as Geom!B20 "Total Aircraft Amax:" = 25.110556;
        %    VnV/BrandtF16A/readme_geom.md Section 4.5]
        %
        %   The MAX is taken over the 20 frame stations ONLY, exactly as
        %   Geom!H26:H45 does — deliberately NOT over a refined grid.  A 0.02-ft
        %   grid with interpolation gives +1.89 % (todo §16.1 variant A'); the
        %   coarse station set is Brandt's convention and is what the sub-step's
        %   expected values are built on.
        %
        %   ★ THE DIVISOR 5 IS AN UNJUSTIFIED BARE LITERAL IN THE WORKBOOK, kept
        %   by locked user decision (2026-07-25) and flagged, not rationalized.
        %   Stated plainly: a live 2026-07-25 search of the entire Brandt nacelle
        %   block Geom!A470:E490 found NO inlet capture area, NO throat diameter
        %   and nothing else in the workbook dividing by 5, while
        %   readme_geom.md §4.5 uses pi*D^2/4 for the SAME nacelle's own
        %   cross-section — so the deduction removes 80 % of what the AE column
        %   added, for no documented reason.  No rationale is invented here.
        %   VnV/BrandtF16A/todo.md 2026-07-25 Phase 2 §5 stays OPEN.
        %   Recorded consequences of the alternative: /4 would make the
        %   flow-through nacelle net exactly zero (the textbook area-rule
        %   treatment of a fully-ducted body) and give Amax 23.145385 (-7.82 %),
        %   CD0_wave -15.04 %, and an Amax completely INSENSITIVE to engine
        %   thrust; under /5 the nacelle nets +pi*D^2/20 and thrust moves Amax
        %   by +0.795 % per +10 % (todo §5 UPDATE / §16.4).
            arguments
                A_total_stations (:,1) double
                n_engines        (1,1) double {mustBeNonnegative}
                D_engine         (1,1) double {mustBeNonnegative}
            end
            INLET_FLOW_THROUGH_DIVISOR = 5;   % ★ Brandt's bare literal — see above
            val = max(A_total_stations) ...
                  - n_engines * pi * D_engine^2 / INLET_FLOW_THROUGH_DIVISOR;
        end

    end
end
