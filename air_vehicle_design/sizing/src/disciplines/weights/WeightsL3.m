classdef WeightsL3
%WEIGHTSL3  Level-3 weight estimation static toolbox — Raymer §15.3.1 buildup.
%
%   Call as WeightsL3.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16WeightsL3, etc.)
%   inherit from WeightsModelL3 and call these statics to implement each
%   abstract method.
%
%   SOURCE (single, consistent citation for every equation in this file):
%     Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA,
%     §15.3.1 — Fighter/Attack Statistical Weights, Eqs. 15.1–15.24.
%     PAGE SCHEME, unified 2026-07-25: this file cites the SECTION only.
%     The repo extract maps §15.3.1 to book pp.572–573 = PDF pp.602–603
%     (raymer_data.md:115; PDF = book + 30), so the file's former mix of
%     "p.572" in the header and "p.602" in the method comments pointed at the
%     same content by two different schemes. Neither page number is repeated
%     per method any more. todo 2026-07-24 §3c item 3.
%
%   UNITS (Raymer's nomenclature, English throughout):
%     W_dg, T, W_l, W_en, W_uav       [lbf]
%     S_w, S_ht, S_vt, S_csw, S_cs,
%       S_r, S_fw                     [ft^2]
%     L_fus, D_fus, W_fus, D_e, L_d,
%       L_s, L_tp, L_sh, L_ec, L_t,
%       L_a, B_h, F_w, H_t, H_v       [ft]
%     L_m, L_n                        [INCHES at the equation — Raymer's
%                                      nomenclature; the caller converts from
%                                      feet, see weight_landing_gear]
%     V_t, V_i, V_p                   [gal]
%     SFC                             [1/hr]
%     R_kva                           [kVA]
%     M, all K_*, all N_*             [—]
%   All outputs: W [lbf].
%
%   ============================================================================
%   ! STANDING TO-DO — EVERY §15.3.1 EXPONENT IS UNVERIFIED AGAINST THE BOOK.
%
%   Locked decision (user 2026-07-24, "approach 2"): KEEP every coefficient and
%   exponent at its current code value, re-cite them to a consistent Raymer 7th
%   ed. §15.3.1 reference, and DO NOT declare them book-verified. No value
%   changes. The complete 62-row checklist is
%   VnV/BrandtF16A/todo.md 2026-07-24 Weights §3a. Categories:
%
%     CONFLICT (2) — code disagrees with the repo extract; the CODE VALUE IS
%       KEPT by decision, and must NOT be "fixed" to match the extract:
%         Eq. 15.13  N_en^1.023   (extract says 1.078)
%         Eq. 15.3   cos(Λ_vt)^(−0.323)   (extract says −1.0)
%     FROM-CODE (9) — absent from the repo extract entirely; the value comes
%       from this project's prior WeightLevel3.m implementation, NOT the book:
%         Eq. 15.10  N_en^1.498, (L_s/L_d)^(−0.373), linear D_e
%         Eq. 15.14  N_en^1.008, L_ec^0.222
%         Eq. 15.17  N_c^0.127
%         Eq. 15.5   L_m^0.973
%         Eq. 15.6   N_nw^0.525
%     VERIFY (24) — present in raymer_data.md but OCR-flagged [verify].
%     IMAGE-ONLY (27) — Eqs. 15.1–15.7. A previous version of this header
%       claimed these had been "re-verified letter-for-letter against the Raymer
%       6th ed. p.572 equation page image (not OCR)". THAT CLAIM IS NOT
%       CHECKABLE: no such image exists anywhere in this repo, and the extract
%       still marks the equations [verify]. The claim has been REMOVED from this
%       header and from the wing/HT/VT/fuselage/gear/mounts method comments,
%       which previously contradicted the high-level methods' own [verify]
%       warnings on the same equations.
%     extract-clean (5) — Eqs. 15.8, 15.11, 15.12, 15.22, 15.24 agree with the
%       extract, but remain inside the standing "check against the physical book"
%       obligation.
%
%   Two further Eq. 15.1 uncertainties beyond the [verify] tag:
%     (a) tc_root^(−0.4) — the superscript is not legible in the printed page's
%         line-wrap at that term; −0.4 was assumed from the widely-corroborated
%         published form (it matches temp_Casey independently), NOT read off the
%         page.
%     (b) Sweep STATION — this code uses cos(Λ_LE) (leading-edge sweep), as
%         raymer_data.md:121 prints a bare "Λ". Some editions use quarter-chord
%         sweep. UNRESOLVED.
%
%   Guard: a deliberately-failing labelled test,
%   TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified, must stay RED
%   while that checklist is open. Do not change any exponent to make it green.
%   ============================================================================
%
%   TWO TIERS of statics:
%     High-level — accept the student object (obj) and W_TO [lbf]. Each unpacks
%                  the geometry/systems properties from obj and passes scalars to
%                  the corresponding low-level function. Passing obj avoids 10–15
%                  scalar arguments per call.
%     Low-level  — pure math; take only scalars (no object access). These are the
%                  citable equations.

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Total operating empty weight [lbf]; sum of all component groups.
        %   [Raymer 7th ed. §15.3.1, Eqs. 15.1–15.24 + Eq. 10.10 engine weight]
        %   W_TO — candidate gross weight [lbf]; Raymer's W_dg (design gross
        %   weight) throughout §15.3.1.
        %
        %   ! Every W_TO-dependent term is evaluated at the PASSED W_TO,
        %   including the landing gear: weight_landing_gear now takes W_TO and
        %   derives W_l from it. Before Phase 4 it took no W_TO at all and read a
        %   frozen W_l = 20681 [Brandt Wt!B41], which made the ENTIRE landing-gear
        %   group bit-identical at W_TO = 31,377 / 45,000 / 60,000 — a Brandt
        %   OUTPUT frozen as an input, the same defect class as review finding #5
        %   one tier down. todo 2026-07-25 Phase 4 §P4-17.
            W_str  = WeightsL3.weight_wing(obj, W_TO);
            W_tail = WeightsL3.weight_tail(obj, W_TO);
            W_fus  = WeightsL3.weight_fuselage(obj, W_TO);
            W_lg   = WeightsL3.weight_landing_gear(obj, W_TO);
            W_eng  = WeightsL3.weight_engine_section(obj, W_TO);
            W_sys  = WeightsL3.weight_systems(obj, W_TO);
            oew = W_str + W_tail.HT + W_tail.VT + W_fus + ...
                  W_lg.main + W_lg.nose + W_eng.total + W_sys.total;
        end

        % ------------------------------------------------------------------ %
        % Structural group
        % ------------------------------------------------------------------ %

        function W = weight_wing(obj, W_TO)
        %WEIGHT_WING  Wing structural weight [lbf].  [Raymer 7th ed. Eq. 15.1]
        %   W = 0.0103·K_dw·K_vs·(W_dg·N_z)^0.5·S_w^0.622·AR^0.785
        %       ·(t/c)_root^(-0.4)·(1+λ)^0.05·cos(Λ_LE)^(-1.0)·S_csw^0.04
        %   ⚠ Exponents UNVERIFIED — see the class header (IMAGE-ONLY ×6, plus the
        %     illegible tc_root superscript and the open LE-vs-c/4 sweep station).
        %   obj.S_w is the EXPOSED wing planform area (geometry DI:
        %   geom.S_exposed_wing).
            W = WeightsL3.wing(W_TO, obj.N_z, obj.S_w, obj.AR_w, obj.tc_root, ...
                               obj.lambda_w, obj.Lambda_LE_w, obj.S_csw, ...
                               obj.K_dw, obj.K_vs);
        end

        function W_tail = weight_tail(obj, W_TO)
        %WEIGHT_TAIL  Horizontal and vertical tail weight [lbf].
        %   [Raymer 7th ed. Eqs. 15.2 (HT) and 15.3 (VT)]
        %   Returns struct with fields HT and VT.
        %   ⚠ Exponents UNVERIFIED, incl. Eq. 15.3's code-vs-extract CONFLICT on
        %     cos(Λ_vt)^(−0.323) — see the class header.
        %   obj.S_ht / obj.S_vt are the EXPOSED planform areas (geometry DI:
        %   geom.S_exposed_ht = 51.1486 / geom.S_exposed_vt = 40.8897) — NOT the
        %   FULL planform geom.S_ht = 108 / geom.S_vt = 60, and obj.AR_vt /
        %   obj.lambda_vt are geom.AR_exposed_vt / geom.lambda_exposed_vt, NOT
        %   geom.AR_vt = 1.6 / geom.lambda_vt = 0.5. Wiring the FULL-planform
        %   names produces a plausible wrong number with no error
        %   (docs/weights_parameter_usage.md §2, the DI name traps).
        %   obj.design_mach is the requirements-file design Mach (Eq. 15.3's M).
            W_tail.HT = WeightsL3.horizontal_tail(W_TO, obj.N_z, obj.S_ht, ...
                                                   obj.F_w, obj.B_h);
            W_tail.VT = WeightsL3.vertical_tail(W_TO, obj.N_z, obj.S_vt, ...
                                                 obj.K_rht, obj.H_t, obj.H_v, ...
                                                 obj.design_mach, obj.L_t, obj.S_r, ...
                                                 obj.AR_vt, obj.lambda_vt, obj.Lambda_LE_vt);
        end

        function W = weight_fuselage(obj, W_TO)
        %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer 7th ed. Eq. 15.4]
        %   W = 0.499·K_dwf·W_dg^0.35·N_z^0.25·L_fus^0.5·D_fus^0.849·W_fus^0.685
        %   ⚠ Exponents UNVERIFIED (IMAGE-ONLY ×5) — see the class header.
        %   obj.D_fus is Eq. 15.4's maximum structural DEPTH, wired to
        %   geom.H_max_fuselage = 5.0 ft — NOT the geometry object's Dependent
        %   D_fus = 6.0 ft, which is the Roskam Vol. II Eq. 12.3 EQUIVALENT
        %   DIAMETER (W_max+H_max)/2 used only for the fuselage wetted area. Same
        %   name, different physical quantity; because Eq. 15.4 carries D_fus^0.849
        %   a 6.0-for-5.0 substitution inflates this component by +17.9 %
        %   ((6/5)^0.849). docs/weights_parameter_usage.md §2.
            W = WeightsL3.fuselage(W_TO, obj.N_z, obj.L_fus, obj.D_fus, ...
                                   obj.W_fus, obj.K_dwf);
        end

        function W_lg = weight_landing_gear(obj, W_TO)
        %WEIGHT_LANDING_GEAR  Main + nose gear weight [lbf].
        %   [Raymer 7th ed. Eqs. 15.5 (main) and 15.6 (nose)]
        %   Returns struct with fields main and nose.
        %   W_TO — candidate gross weight [lbf]; the landing weight W_l is
        %   DERIVED from it here (see landing_weight below).
        %
        %   ! SIGNATURE CHANGED 2026-07-25 (Phase 4): this method previously took
        %   NO W_TO argument and read a stored obj.W_l = 20681 [Brandt Wt!B41].
        %   Both halves of that had to change or the group stayed dead: with a
        %   frozen W_l the landing gear was bit-identical at every W_TO
        %   (1057.273 lbf at 31,377 / 45,000 / 60,000 alike — verified live), and
        %   with a W_TO-derived W_l but no W_TO argument, OEW(W_TO) would still
        %   have evaluated the gear at obj.W_TO instead of its own argument.
        %   todo 2026-07-25 Phase 4 §P4-17 / F16WeightsL3.md §4.
        %
        %   ! UNITS: Raymer's nomenclature defines L_m ("extended length of main
        %   landing gear") and L_n ("extended nose gear length") in INCHES, while
        %   obj.L_m / obj.L_n are aircraft-spec strut lengths in FEET — hence the
        %   ×12 here. This conversion is load-bearing: omitting it made the gear
        %   come out ~8× too low. It is a UNITS conversion, not a missing term.
            L_m_in = obj.L_m * 12;
            L_n_in = obj.L_n * 12;
            W_l    = WeightsL3.landing_weight(W_TO);
            W_lg.main = WeightsL3.main_gear(W_l, obj.N_l, L_m_in, ...
                                             obj.K_cb, obj.K_tpg);
            W_lg.nose = WeightsL3.nose_gear(W_l, obj.N_l, L_n_in, obj.N_nw);
        end

        function W = weight_engine_section(obj, ~)
        %WEIGHT_ENGINE_SECTION  Total propulsion group weight [lbf].
        %   Dry/UNINSTALLED engine weight (obj.W_en × obj.N_en) PLUS the §15.3.1
        %   installation-hardware items, Eqs. 15.7–15.15. Returns a struct with
        %   one field per sub-component plus .total.
        %   W_TO is accepted for API consistency but not needed by these equations.
        %
        %   ⚠ Raymer §15.3.1 gives the installation-hardware items — mounts
        %     (15.7), firewall (15.8), engine section (15.9), air induction
        %     (15.10), tailpipe (15.11), engine cooling (15.12), oil cooling
        %     (15.13), engine controls (15.14), starter (15.15) — as ADDITIONS on
        %     top of the engine's own dry weight. The dry weight itself is NOT a
        %     §15.3.1 equation: it is vendor/spec data, here supplied as Raymer
        %     7th ed. Eq. 10.10 (PropL2.engine_weight_AB) via the concrete class's
        %     Dependent W_en. Omitting it understates the propulsion group by the
        %     full engine weight (it once produced an implausible ~600 lbf "engine").
        %
        %   ! obj.W_en MUST BE THE UNINSTALLED WEIGHT AT L3 — 2775.0210 lbf
        %     (settled decision 1, user 2026-07-25). The metabook's ×1.3
        %     installed/bare factor is a lumped stand-in for exactly the nine
        %     items this method already adds individually, so applying it here
        %     would double-count the installation. ×1.3 belongs at L2 and only at
        %     L2, which has no buildup (WeightsL2.weight_installed_engine).
        %     Recorded consequence: the settled L3 OEW(31377) = 15705.33 is
        %     -21.40 % vs Brandt Wt!B12, whereas the rejected ×1.3 variant gives
        %     16546.06, i.e. -17.19 % — CLOSER to Brandt. That closer agreement is
        %     the evidence AGAINST ×1.3, not a reason to keep it: a number that
        %     agrees because a factor is counted twice is not agreement.
        %     F16WeightsL3.md §4; todo §P4-1b.
            W.engine   = obj.W_en * obj.N_en; % dry/UNINSTALLED engine weight [Raymer 7th ed. Eq. 10.10 via the concrete class; NOT a §15.3.1 equation]
            W.mounts   = WeightsL3.engine_mounts(obj.N_en, obj.T_max, obj.N_z);
            W.firewall = WeightsL3.firewall(obj.S_fw); % jets set S_fw = 0; Eq. 15.8 then returns 0 (no piston firewall)
            W.section  = WeightsL3.engine_section(obj.W_en, obj.N_en, obj.N_z);
            W.induction = WeightsL3.air_induction(obj.K_vg, obj.L_d, obj.K_d, ...
                                                    obj.N_en, obj.L_s, obj.D_e);
            W.tailpipe = WeightsL3.tailpipe(obj.D_e, obj.L_tp, obj.N_en);
            W.cooling  = WeightsL3.engine_cooling(obj.D_e, obj.L_sh, obj.N_en);
            W.oil      = WeightsL3.oil_cooling(obj.N_en);
            W.controls = WeightsL3.engine_controls(obj.N_en, obj.L_ec);
            W.starter  = WeightsL3.starter(obj.T_max, obj.N_en);
            W.total    = W.engine + W.mounts + W.firewall + W.section + W.induction + ...
                         W.tailpipe + W.cooling + W.oil + W.controls + W.starter;
        end

        function W = weight_systems(obj, W_TO)
        %WEIGHT_SYSTEMS  Fuel, controls, avionics, furnishings group [lbf].
        %   [Raymer 7th ed. Eqs. 15.16–15.24]  Returns a struct with one field per
        %   sub-component plus .total.
        %   ! Contains NO landing-gear term — the gear is Eqs. 15.5/15.6 and is
        %     summed separately by OEW. (WeightsModelL3's W_subsystems comment used
        %     to claim otherwise; corrected 2026-07-25, todo §P4-10.)
        %   obj.SFC_mission is a propulsion DI evaluated at the requirements-file
        %   cruise condition (36,000 ft / M 0.87) = 1.007116 1/hr, NOT Brandt's
        %   single stored SLS constant Main!C30 = 0.70. The +43.87 % divergence is
        %   accepted by decision (F16WeightsL3.md §3).
        %   obj.design_mach is the requirements-file design Mach (Eq. 15.17's M).
            W.fuel_sys     = WeightsL3.fuel_system(obj.V_t, obj.V_i, obj.V_p, ...
                                                     obj.N_t, obj.N_en, ...
                                                     obj.T_max, obj.SFC_mission);
            W.flight_ctrl  = WeightsL3.flight_controls(obj.design_mach, obj.S_cs, ...
                                                         obj.N_s, obj.N_c);
            W.instruments  = WeightsL3.instruments(obj.N_en, obj.N_t, obj.N_ci);
            W.hydraulics   = WeightsL3.hydraulics(obj.K_vsh, obj.N_u);
            W.electrical   = WeightsL3.electrical(obj.K_mc, obj.R_kva, obj.N_c, ...
                                                    obj.L_a, obj.N_gen);
            W.avionics     = WeightsL3.avionics(obj.W_uav);
            W.furnishings  = WeightsL3.furnishings(obj.N_c);
            W.ac_antiice   = WeightsL3.ac_antiice(obj.W_uav, obj.N_c);
            W.handling     = WeightsL3.handling_gear(W_TO);
            W.total = W.fuel_sys + W.flight_ctrl + W.instruments + W.hydraulics + ...
                      W.electrical + W.avionics + W.furnishings + W.ac_antiice + W.handling;
        end

        % ================================================================== %
        % LOW-LEVEL — individual Raymer §15.3.1 equations, plus the one
        % landing-weight rule that has no textbook source.
        % ================================================================== %

        function W_l = landing_weight(W_TO)
        %LANDING_WEIGHT  Design landing gross weight [lbf] from TOGW.
        %   W_l = 0.95 · W_TO
        %   Feeds Raymer 7th ed. Eqs. 15.5 and 15.6, whose W_l Raymer defines as
        %   the "landing design gross weight".
        %
        %   *** TODO — THE 0.95 FACTOR HAS NO CITATION IN THIS REPO. ***
        %   It was supplied by the user (settled decision 4, 2026-07-25) and is
        %   deliberately recorded as uncited rather than attributed to a source
        %   that does not say it. Grepped air_vehicle_design/sizing/ 2026-07-25:
        %   no 0.95 landing-weight fraction appears in metabook_data.md,
        %   raymer_data.md, roskam_vol1_data.md, readme_wt.md, F16Baseline.m or
        %   temp_Casey/, and Raymer §15.3.1's nomenclature defines W_l without
        %   giving any W_l/W_dg ratio.
        %   For contrast, Brandt's own implied ratio is 20680.700578 / 31377 =
        %   0.6591 [Brandt Wt!B41 = =SUM(B16:B32), live-read 2026-07-25] — but
        %   that cell is a back-calculated subtotal of his own weight statement,
        %   a DEFINITIONALLY different quantity from a design landing-weight rule,
        %   and the framework's 0.95·W_TO sits +44.14 % above it. The gap is
        %   expected and logged, not an error to chase.
        %   Needs a cited source (a Raymer/Roskam/Nicolai landing-weight fraction,
        %   or a T.O. figure). UNRESOLVED — VnV/BrandtF16A/todo.md 2026-07-25
        %   Phase 4 §P4-16. A test must fail loudly against this until it is
        %   supplied; do not substitute a plausible cited-looking number.
            W_l = 0.95 * W_TO;
        end

        function W = wing(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_LE_deg, S_csw, K_dw, K_vs)
        %WING  Raymer 7th ed. Eq. 15.1 — wing structural weight [lbf].
        %   W = 0.0103·K_dw·K_vs·(W_dg·N_z)^0.5·S_w^0.622·AR^0.785
        %       ·tc_root^(-0.4)·(1+λ)^0.05·cos(Λ_LE)^(-1.0)·S_csw^0.04
        %   [Form as printed in raymer_data.md:120-121, which flags the whole
        %    equation [verify exps].]
        %   ⚠ EXPONENTS NOT BOOK-VERIFIED (class header, IMAGE-ONLY rows 37–44).
        %     Two specific gaps, stated rather than papered over:
        %       * tc_root^(-0.4): the superscript is not legible in the printed
        %         page's line-wrap at this term. -0.4 is the widely-corroborated
        %         published form and matches this project's temp_Casey reference
        %         implementation independently — it was NOT read off the page.
        %       * Λ is taken as LEADING-EDGE sweep, matching the bare "Λ" printed
        %         in raymer_data.md:121. Some editions use quarter-chord sweep.
        %         UNRESOLVED.
        %   S_w — EXPOSED wing planform area [ft^2]. S_csw — wing control-surface
        %   area [ft^2]. K_dw = 1.0 (not a delta wing); K_vs = 1.0 (not variable
        %   sweep).
            W = 0.0103 * K_dw * K_vs ...
                * (W_dg * N_z).^0.5 ...
                * S_w.^0.622 ...
                * AR.^0.785 ...
                * tc_root.^(-0.4) ...
                * (1 + lambda).^0.05 ...
                * cosd(Lambda_LE_deg).^(-1.0) ...
                * S_csw.^0.04;
        end

        function W = horizontal_tail(W_dg, N_z, S_ht, F_w, B_h)
        %HORIZONTAL_TAIL  Raymer 7th ed. Eq. 15.2 — HT weight [lbf].
        %   W = 3.316·(1 + F_w/B_h)^(-2.0)·((W_dg·N_z)/1000)^0.260·S_ht^0.806
        %   [Form as printed in raymer_data.md:122, flagged [verify].]
        %   ⚠ EXPONENTS NOT BOOK-VERIFIED (class header, IMAGE-ONLY rows 45–47).
        %   S_ht — EXPOSED HT planform area [ft^2].
        %   F_w  — fuselage width at the HT intersection [ft].
        %   B_h  — horizontal tail span [ft].
        %   Takes only (W_dg, N_z, S_ht, F_w, B_h): HT aspect ratio and taper do
        %   NOT appear in this equation, which is why F16WeightsL3's former
        %   AR_ht / lambda_ht inputs were dead and were deleted (todo §P4-6).
            W = 3.316 * (1 + F_w/B_h).^(-2.0) ...
                * ((W_dg .* N_z) / 1000).^0.260 ...
                * S_ht.^0.806;
        end

        function W = vertical_tail(W_dg, N_z, S_vt, K_rht, H_t, H_v, M, L_t, S_r, AR_vt, lambda_vt, Lambda_LE_vt_deg)
        %VERTICAL_TAIL  Raymer 7th ed. Eq. 15.3 — VT weight [lbf].
        %   W = 0.452·K_rht·(1+H_t/H_v)^0.5·(W_dg·N_z)^0.488·S_vt^0.718
        %       ·M^0.341·L_t^(-1.0)·(1+S_r/S_vt)^0.348·AR_vt^0.223
        %       ·(1+λ_vt)^0.25·cos(Λ_vt)^(-0.323)
        %   [Form as printed in raymer_data.md:123-124, flagged [verify]; that
        %    extract line is partly elided ("·...·(1+λ)^...·A^...").]
        %   ⚠ EXPONENTS NOT BOOK-VERIFIED (class header, rows 48–55), AND one
        %     documented CODE-vs-EXTRACT CONFLICT: raymer_data.md:124 reads
        %     cos(Λ_vt)^(-1.0) where this code uses ^(-0.323). The CODE VALUE IS
        %     KEPT by locked decision (approach 2, user 2026-07-24) — do not
        %     change it to -1.0 to reconcile them; the conflict is the TO-DO.
        %   K_rht = 1.047 for a rolling (all-moving) horizontal tail. It is
        %   applied HERE, in Eq. 15.3, not in Eq. 15.2 — that is how the book
        %   prints it, not a mix-up. (The JSON keys it under
        %   .weights.horizontal_tail because the FLAG describes the HT.)
        %   H_t/H_v — tail-height ratio; 0 for a conventional mid/low tail.
        %   L_t     — tail moment arm, wing 1/4-MAC to HT 1/4-MAC [ft].
        %   S_r     — VT control-surface (rudder) area [ft^2].
        %   S_vt, AR_vt, λ_vt — the EXPOSED VT planform set (40.8897 / 1.294 /
        %   0.437), not the FULL planform (60 / 1.6 / 0.5).
            W = 0.452 * K_rht ...
                * (1 + H_t/H_v).^0.5 ...
                * (W_dg .* N_z).^0.488 ...
                * S_vt.^0.718 ...
                * M.^0.341 ...
                * L_t.^(-1.0) ...
                * (1 + S_r/S_vt).^0.348 ...
                * AR_vt.^0.223 ...
                * (1 + lambda_vt).^0.25 ...
                * cosd(Lambda_LE_vt_deg).^(-0.323);
        end

        function W = fuselage(W_dg, N_z, L_fus, D_fus, W_fus, K_dwf)
        %FUSELAGE  Raymer 7th ed. Eq. 15.4 — fuselage structural weight [lbf].
        %   W = 0.499·K_dwf·W_dg^0.35·N_z^0.25·L_fus^0.5·D_fus^0.849·W_fus^0.685
        %   [Form as printed in raymer_data.md:125, flagged [verify].]
        %   ⚠ EXPONENTS NOT BOOK-VERIFIED (class header, IMAGE-ONLY rows 56–60).
        %   L_fus — fuselage structural length [ft].
        %   D_fus — maximum fuselage structural DEPTH [ft]. NOT an equivalent
        %           diameter: see weight_fuselage's note on the +17.9 % error a
        %           6.0-for-5.0 substitution causes through D_fus^0.849.
        %   W_fus — maximum fuselage width [ft].
        %   K_dwf = 1.0 (not a delta-wing fuselage).
            W = 0.499 * K_dwf ...
                * W_dg.^0.35 ...
                * N_z.^0.25 ...
                * L_fus.^0.5 ...
                * D_fus.^0.849 ...
                * W_fus.^0.685;
        end

        function W = main_gear(W_l, N_l, L_m, K_cb, K_tpg)
        %MAIN_GEAR  Raymer 7th ed. Eq. 15.5 — main landing gear weight [lbf].
        %   W = K_cb·K_tpg·(W_l·N_l)^0.25·L_m^0.973
        %   [raymer_data.md:126 prints this as "(W_l·N_l)^0.25·L_m^...·..." — the
        %    L_m exponent is ABSENT from the extract; 0.973 is FROM-CODE (this
        %    project's prior WeightLevel3.m), not from the book. Class header,
        %    FROM-CODE list / todo §3a rows 14–15.]
        %   ⚠ NOT BOOK-VERIFIED.
        %   W_l — landing design gross weight [lbf]; supplied by
        %         WeightsL3.landing_weight (whose 0.95 factor is UNCITED, §P4-16).
        %   N_l — landing load factor.
        %   L_m — extended main-gear strut length [INCHES per Raymer's
        %         nomenclature — the caller converts from feet].
        %   K_cb = 1.0 (non-carrier-based); K_tpg = 1.0 (non-kneeling gear).
            W = K_cb * K_tpg * (W_l * N_l).^0.25 .* L_m.^0.973;
        end

        function W = nose_gear(W_l, N_l, L_n, N_nw)
        %NOSE_GEAR  Raymer 7th ed. Eq. 15.6 — nose landing gear weight [lbf].
        %   W = (W_l·N_l)^0.290·L_n^0.5·N_nw^0.525
        %   [raymer_data.md:127 prints "(W_l·N_l)^0.290·L_n^0.5·N_nw^..." — the
        %    N_nw exponent is ABSENT from the extract; 0.525 is FROM-CODE. Class
        %    header / todo §3a rows 16–18.]
        %   ⚠ NOT BOOK-VERIFIED.
        %   L_n  — extended nose-gear strut length [INCHES per Raymer's
        %          nomenclature — the caller converts from feet].
        %   N_nw — number of nose wheels.
            W = (W_l .* N_l).^0.290 .* L_n.^0.5 .* N_nw.^0.525;
        end

        function W = engine_mounts(N_en, T, N_z)
        %ENGINE_MOUNTS  Raymer 7th ed. Eq. 15.7 — engine mount weight [lbf].
        %   W = 0.013·N_en^0.795·T^0.579·N_z
        %   ⚠ EXPONENTS NOT BOOK-VERIFIED (class header, IMAGE-ONLY rows 61–62).
        %   T — total engine thrust, SLS afterburning [lbf]; propulsion DI
        %       (prop.T_SL = 23770).  N_z — ultimate load factor.
            W = 0.013 * N_en.^0.795 .* T.^0.579 .* N_z;
        end

        function W = firewall(S_fw)
        %FIREWALL  Raymer 7th ed. Eq. 15.8 — firewall weight [lbf].
        %   W = 1.13·S_fw.  S_fw — firewall area [ft^2].
        %   Agrees with the repo extract (extract-clean), but is still inside the
        %   standing verify-against-the-book obligation.
        %   A jet fighter has no piston firewall, so S_fw = 0 and this returns 0.
            W = 1.13 * S_fw;
        end

        function W = engine_section(W_en, N_en, N_z)
        %ENGINE_SECTION  Raymer 7th ed. Eq. 15.9 — engine section structure [lbf].
        %   W = 0.01·W_en^0.717·N_en·N_z
        %   ⚠ EXPONENT [verify] in raymer_data.md (class header, todo §3a row 19).
        %   W_en — engine weight EACH, dry/UNINSTALLED [lbf]. At L3 this is the
        %          Raymer Eq. 10.10 uninstalled value 2775.0210 (decision 1); do
        %          NOT pass an ×1.3 installed figure — Eqs. 15.7–15.15 already
        %          supply the installation hardware.
            W = 0.01 * W_en.^0.717 .* N_en .* N_z;
        end

        function W = air_induction(K_vg, L_d, K_d, N_en, L_s, D_e)
        %AIR_INDUCTION  Raymer 7th ed. Eq. 15.10 — inlet duct weight [lbf].
        %   W = 13.29·K_vg·L_d^0.643·K_d^0.182·N_en^1.498·(L_s/L_d)^(-0.373)·D_e
        %   ⚠ WEAKEST-SOURCED EQUATION IN THIS FILE. Three terms are FROM-CODE
        %     (absent from raymer_data.md, taken from this project's prior
        %     WeightLevel3.m): N_en^1.498, (L_s/L_d)^(-0.373) and the linear D_e.
        %     Two more are [verify] (L_d^0.643, K_d^0.182). todo §3a rows 3–7.
        %   K_vg = 1.0 (fixed-geometry inlet).
        %   K_d  — duct-shape flag. Documented as 0 (straight duct) or 1
        %          (bifurcated).
        %   L_d  — duct length [ft];  L_s — splitter/bypass length [ft];
        %   D_e  — engine face/exit diameter [ft].
        %
        %   ! K_d = 0 IS A LEGAL, DOCUMENTED INPUT THAT SILENTLY ZEROES THIS
        %     ENTIRE 227.54 lbf COMPONENT. 0^0.182 = 0 (verified live), so a
        %     straight duct evaluates to exactly 0.0000 with no error, no warning
        %     and not even a NaN to notice downstream — L3 OEW would read
        %     15477.79 instead of 15705.33. NO GUARD IS ADDED, by explicit user
        %     decision 6 (2026-07-25), and this description is deliberately not
        %     softened. Same silent-zero class as the Phase-1 F16GeomL1 defect
        %     where a frozen S_wet = 0 gave CD0 = 0 and an infinite L/D.
        %     COROLLARY WORTH RECORDING: if K_d = 0 is legal then this code's K_d
        %     cannot be Raymer's K_d as a multiplicative base — a straight duct
        %     does not weigh nothing — so the term's exponent or placement is
        %     itself suspect (that is todo §3a row 7). A guard alone would mask
        %     that, which is one reason not to add one blind.
        %     todo 2026-07-25 Phase 4 §P4-11, OPEN. The same applies to
        %     L_s = 0 -> (L_s/L_d)^(-0.373) = Inf.
            W = 13.29 * K_vg .* L_d.^0.643 .* K_d.^0.182 ...
                .* N_en.^1.498 .* (L_s./L_d).^(-0.373) .* D_e;
        end

        function W = tailpipe(D_e, L_tp, N_en)
        %TAILPIPE  Raymer 7th ed. Eq. 15.11 — tailpipe weight [lbf].
        %   W = 3.5·D_e·L_tp·N_en
        %   Agrees with the repo extract (extract-clean); still inside the
        %   standing verify-against-the-book obligation.
        %   D_e — nozzle exit diameter [ft];  L_tp — tailpipe length [ft].
            W = 3.5 * D_e .* L_tp .* N_en;
        end

        function W = engine_cooling(D_e, L_sh, N_en)
        %ENGINE_COOLING  Raymer 7th ed. Eq. 15.12 — cooling/shroud weight [lbf].
        %   W = 4.55·D_e·L_sh·N_en
        %   Agrees with the repo extract (extract-clean); still inside the
        %   standing verify-against-the-book obligation.
        %   L_sh — engine shroud length [ft].
            W = 4.55 * D_e .* L_sh .* N_en;
        end

        function W = oil_cooling(N_en)
        %OIL_COOLING  Raymer 7th ed. Eq. 15.13 — oil cooling system weight [lbf].
        %   W = 37.82·N_en^1.023
        %   ⚠ DOCUMENTED CODE-vs-EXTRACT CONFLICT: raymer_data.md gives
        %     N_en^1.078. The CODE VALUE 1.023 IS KEPT by locked decision
        %     (approach 2, user 2026-07-24) — do not change it to 1.078 to
        %     reconcile them; the conflict is the TO-DO (todo §3a row 1).
        %     At N_en = 1 the two are numerically identical (1^x = 1), so this
        %     conflict is invisible on the F-16A and must not be assumed benign.
            W = 37.82 * N_en.^1.023;
        end

        function W = engine_controls(N_en, L_ec)
        %ENGINE_CONTROLS  Raymer 7th ed. Eq. 15.14 — engine controls weight [lbf].
        %   W = 10.5·N_en^1.008·L_ec^0.222
        %   ⚠ BOTH EXPONENTS ARE FROM-CODE — absent from raymer_data.md, taken
        %     from this project's prior WeightLevel3.m. NOT book-verified.
        %     todo §3a rows 8–9.
        %   L_ec — engine-controls run length [ft].
            W = 10.5 * N_en.^(1.008) .* L_ec.^(0.222);
        end

        function W = starter(T, N_en)
        %STARTER  Raymer 7th ed. Eq. 15.15 — pneumatic starter weight [lbf].
        %   W = 0.025·T^0.760·N_en^0.72
        %   ⚠ BOTH EXPONENTS [verify] in raymer_data.md (todo §3a rows 20–21).
        %   T — engine SLS afterburning thrust [lbf]; propulsion DI.
            W = 0.025 * T.^0.760 .* N_en.^0.72;
        end

        function W = fuel_system(V_t, V_i, V_p, N_t, N_en, T, SFC)
        %FUEL_SYSTEM  Raymer 7th ed. Eq. 15.16 — fuel system weight [lbf].
        %   W = 7.45·V_t^0.47·(1+V_i/V_t)^(-0.095)·(1+V_p/V_t)·N_t^0.066
        %       ·N_en^0.052·((T·SFC)/1000)^0.249
        %   ⚠ FIVE EXPONENTS [verify] in raymer_data.md (todo §3a rows 22–26).
        %   V_t — total fuel volume [gal];  V_i — integral-tank volume [gal];
        %   V_p — pressurised-tank volume [gal];  N_t — number of tanks.
        %   T   — maximum thrust [lbf];  SFC — mission SFC [1/hr].
        %   ! V_t = 0 would give 0^0.47 · Inf -> NaN. Left UNGUARDED by decision 6
        %     (todo §P4-11); reachable only via an explicit JSON zero, since V_t
        %     is a 940 gal input rather than a derived quantity (decision 3).
        %   The equation is weakly sensitive to SFC ((T·SFC)/1000 raised to 0.249),
        %   which is why moving SFC from Brandt's 0.70 to the framework's cruise
        %   value 1.007116 (+43.87 %) moves this component only +9.48 %.
            W = 7.45 * V_t.^0.47 ...
                .* (1 + V_i./V_t).^(-0.095) ...
                .* (1 + V_p./V_t) ...
                .* N_t.^0.066 ...
                .* N_en.^0.052 ...
                .* ((T .* SFC) / 1000).^0.249;
        end

        function W = flight_controls(M, S_cs, N_s, N_c)
        %FLIGHT_CONTROLS  Raymer 7th ed. Eq. 15.17 — flight control system [lbf].
        %   W = 36.28·M^0.003·S_cs^0.489·N_s^0.484·N_c^0.127
        %   ⚠ N_c^0.127 is FROM-CODE (absent from raymer_data.md, taken from this
        %     project's prior WeightLevel3.m); the other three are [verify].
        %     NOT book-verified. todo §3a rows 10–13.
        %   M    — design maximum Mach number [—]; requirements-file design_mach.
        %   S_cs — total control-surface area [ft^2];
        %   N_s  — number of control surfaces;  N_c — number of cockpits.
            W = 36.28 * M.^0.003 .* S_cs.^0.489 .* N_s.^0.484 .* N_c.^0.127;
        end

        function W = instruments(N_en, N_t, N_ci)
        %INSTRUMENTS  Raymer 7th ed. Eq. 15.18 — instruments and navigation [lbf].
        %   W = 8.0 + 36.37·N_en^0.676·N_t^0.237 + 26.4·(1+N_ci)^1.356
        %   ⚠ THREE EXPONENTS [verify] in raymer_data.md (todo §3a rows 27–29).
        %   N_t — number of fuel tanks;  N_ci — number of comm/ID items.
            W = 8.0 + 36.37 * N_en.^0.676 .* N_t.^0.237 + 26.4 * (1 + N_ci).^1.356;
        end

        function W = hydraulics(K_vsh, N_u)
        %HYDRAULICS  Raymer 7th ed. Eq. 15.19 — hydraulics system weight [lbf].
        %   W = 37.23·K_vsh·N_u^0.664
        %   ⚠ EXPONENT [verify] in raymer_data.md (todo §3a row 30).
        %   K_vsh = 1.0 (no variable-sweep hydraulics);
        %   N_u — number of hydraulic utility functions.
            W = 37.23 * K_vsh .* N_u.^0.664;
        end

        function W = electrical(K_mc, R_kva, N_c, L_a, N_gen)
        %ELECTRICAL  Raymer 7th ed. Eq. 15.20 — electrical system weight [lbf].
        %   W = 172.2·K_mc·R_kva^0.152·N_c^0.10·L_a^0.10·N_gen^0.091
        %   ⚠ FOUR EXPONENTS [verify] in raymer_data.md (todo §3a rows 31–34).
        %   R_kva — electrical power requirement [kVA];  L_a — lead length [ft];
        %   N_gen — number of generators;  K_mc = 1.0 (<= 2 generators).
            W = 172.2 * K_mc .* R_kva.^0.152 .* N_c.^0.10 .* L_a.^0.10 .* N_gen.^0.091;
        end

        function W = avionics(W_uav)
        %AVIONICS  Raymer 7th ed. Eq. 15.21 — installed avionics weight [lbf].
        %   W = 2.117·W_uav^0.933
        %   ⚠ EXPONENT [verify] in raymer_data.md (todo §3a row 35).
        %   W_uav — UNINSTALLED avionics weight [lbf].
            W = 2.117 * W_uav.^0.933;
        end

        function W = furnishings(N_c)
        %FURNISHINGS  Raymer 7th ed. Eq. 15.22 — furnishings weight [lbf].
        %   W = 217.6·N_c   (includes ejection seats for this category)
        %   Agrees with the repo extract (extract-clean); still inside the
        %   standing verify-against-the-book obligation.
        %   N_c — number of cockpits (crew members).
            W = 217.6 * N_c;
        end

        function W = ac_antiice(W_uav, N_c)
        %AC_ANTIICE  Raymer 7th ed. Eq. 15.23 — air conditioning + anti-ice [lbf].
        %   W = 201.6·((W_uav + 200·N_c)/1000)^0.735
        %   ⚠ EXPONENT [verify] in raymer_data.md (todo §3a row 36).
            W = 201.6 * ((W_uav + 200 * N_c) / 1000).^0.735;
        end

        function W = handling_gear(W_TO)
        %HANDLING_GEAR  Raymer 7th ed. Eq. 15.24 — handling gear weight [lbf].
        %   W = 3.2e-4·W_dg
        %   Agrees with the repo extract (extract-clean); still inside the
        %   standing verify-against-the-book obligation.
            W = 3.2e-4 * W_TO;
        end

    end

end
