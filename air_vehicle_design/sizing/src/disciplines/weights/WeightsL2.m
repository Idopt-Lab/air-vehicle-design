classdef WeightsL2
%WEIGHTSL2  Level-2 weight estimation static toolbox — surface-density buildup.
%
%   Call as WeightsL2.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16WeightsL2, etc.)
%   inherit from WeightsModelL2 and call these statics to implement each
%   abstract method.
%
%   METHOD — two DIFFERENT source tables, deliberately cited separately:
%
%   (a) Raymer Table 15.2 surface-density (psf x area) for the structure:
%         W_wing     = rho_w   * S_w        (rho_w   = 9   lbf/ft^2, fighters)
%         W_HT       = rho_ht  * S_ht       (rho_ht  = 4   lbf/ft^2)
%         W_VT       = rho_vt  * S_vt       (rho_vt  = 5.3 lbf/ft^2)
%         W_fuselage = rho_fus * S_wet_fus  (rho_fus = 4.8 lbf/ft^2)
%       S_w / S_ht / S_vt are the EXPOSED planform areas per Raymer's own
%       definition — not the full trapezoidal reference areas.
%
%   (b) AE481 metabook Sec. 7 "Fraction-Based Weight Estimates" for the rest:
%         W_LG               = f_lg * W_TO   (f_lg = 0.033, non-Navy fighter)
%         W_installed_engine = 1.3 * N_en * W_en   (W_en = bare/dry engine)
%         W_all_else_empty   = 0.17 * W_TO
%
%   OEW = W_wing + W_HT + W_VT + W_fuselage + W_LG
%         + W_installed_engine + W_all_else_empty
%
%   ! CITATION CORRECTION (settled 2026-07-25, todo Phase 4 §P4-7). The
%     fractions in (b) are NOT Raymer Table 15.2. In the repo extract, Table
%     15.2 is the psf surface-density table ONLY (metabook_data.md:319-324, four
%     rows). The landing-gear / installed-engine / all-else-empty fractions are a
%     SEPARATE, UNNUMBERED metabook table (metabook_data.md:326-334) carrying no
%     Raymer table number at all. Nothing numeric changes; the attribution does.
%
%   ! EVERY W_TO-DEPENDENT TERM IS EVALUATED AT THE W_TO PASSED TO OEW, never at
%     obj.W_TO. That is review finding #5: F16WeightsL2 used to freeze
%     W_all_else_empty at 0.17*31377 in its constructor, so OEW(45000)
%     understated by 2315.91 lbf and 31,377 (a Brandt OUTPUT, Wt!B3) had become a
%     calibration input. docs/weights_parameter_usage.md §4 / F16WeightsL2.md §4.
%
%   The Roskam statistical minimum bound lives at
%   WeightsL1.compute_We_roskam / WeightsL1.We_roskam — call it there for a
%   lower-bound comparison against this component estimate.
%
%   SOURCES:
%     Raymer, "Aircraft Design: A Conceptual Approach," 7th ed., AIAA —
%       Table 15.2, Typical Component Weights per Unit Area. Transcribed from the
%       secondary extract temp_AI/docs/disciplines/reference_extracts/
%       metabook_data.md:317-324 (the AE481 metabook's copy).
%     AE481 Aircraft Design Metabook Sec. 7, "Fraction-Based Weight Estimates"
%       table — metabook_data.md:326-334. UNNUMBERED in the source; do not
%       attribute it to a Raymer table.
%   (Edition unified to Raymer 7th ed. in Phase 4; zero value changes —
%    todo 2026-07-24 §3c item 4.)

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Surface-density-buildup operating empty weight [lbf].
        %   [Raymer 7th ed. Table 15.2 (structure) + AE481 metabook Sec. 7 (fractions)]
        %   W_TO — candidate gross weight [lbf].
        %
        %   ! Both fraction terms are recomputed HERE at the passed W_TO, via
        %   weight_installed_engine / weight_all_else_empty. It must NOT read
        %   obj.W_installed_engine / obj.W_all_else_empty: those Dependent
        %   properties are evaluated at obj.W_TO (the object's current sizing-loop
        %   iterate), which is a different quantity from this argument. Reading
        %   them here is exactly how review finding #5 escaped notice.
            W_w   = WeightsL2.weight_wing(obj, W_TO);
            W_t   = WeightsL2.weight_tail(obj, W_TO);
            W_f   = WeightsL2.weight_fuselage(obj, W_TO);
            W_lg  = WeightsL2.weight_landing_gear(obj, W_TO);
            W_ie  = WeightsL2.weight_installed_engine(obj);
            W_ale = WeightsL2.weight_all_else_empty(obj, W_TO);
            oew   = W_w + W_t.HT + W_t.VT + W_f + W_lg + W_ie + W_ale;
        end

        function W = weight_wing(obj, ~)
        %WEIGHT_WING  Wing structural weight [lbf].  [Raymer 7th ed. Table 15.2]
        %   Surface-density method: W = rho_w * S_w.
        %   rho_w = 9 lbf/ft^2 for fighters [metabook_data.md:321].
        %   obj.S_w is the EXPOSED wing planform area [ft^2], supplied by the
        %   concrete class as geom.S_exposed_wing (geometry DI).
        %   W_TO is accepted for API consistency but not used — pure area x density.
            rho = WeightsL2.wing_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_w;
        end

        function W = weight_tail(obj, ~)
        %WEIGHT_TAIL  HT and VT structural weights [lbf].  [Raymer 7th ed. Table 15.2]
        %   Returns struct with fields HT and VT.
        %   rho_ht = 4 lbf/ft^2 [metabook_data.md:322];
        %   rho_vt = 5.3 lbf/ft^2 [metabook_data.md:323] — fighter row.
        %   obj.S_ht / obj.S_vt are the EXPOSED planform areas, supplied by the
        %   concrete class as geom.S_exposed_ht / geom.S_exposed_vt — NOT the
        %   FULL planform geom.S_ht = 108 / geom.S_vt = 60 (the geometry DI name
        %   trap; docs/weights_parameter_usage.md §2).
        %   W_TO is accepted for API consistency but not used.
            rho_ht = WeightsL2.HT_unit_weight(obj.aircraft_category);
            rho_vt = WeightsL2.VT_unit_weight(obj.aircraft_category);
            W.HT = rho_ht * obj.S_ht;
            W.VT = rho_vt * obj.S_vt;
        end

        function W = weight_fuselage(obj, ~)
        %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer 7th ed. Table 15.2]
        %   Surface-density method: W = rho_fus * S_wet_fus (WETTED area, unlike
        %   the three lifting surfaces above, which take planform).
        %   rho_fus = 4.8 lbf/ft^2 for fighters [metabook_data.md:324].
        %   obj.S_wet_fus comes from geom.get_S_wet_fuselage() [Roskam Vol. II
        %   Eq. 12.3] = 730.3023 ft^2, replacing a former 750 [estimate].
        %   W_TO is accepted for API consistency but not used.
            rho = WeightsL2.fus_unit_weight(obj.aircraft_category);
            W   = rho * obj.S_wet_fus;
        end

        function W = weight_landing_gear(obj, W_TO)
        %WEIGHT_LANDING_GEAR  Total landing gear weight [lbf].
        %   [AE481 metabook Sec. 7, "Fraction-Based Weight Estimates" table]
        %   Fraction-based: W = f_lg * W_TO, f_lg = 0.033 (non-Navy fighter)
        %   [metabook_data.md:330]. Evaluated at the PASSED W_TO.
        %   ! NOT Raymer Table 15.2 — see the class header's citation correction.
        %   ! Brandt uses 0.034 (Wt!F23 = 0.034000, a bare literal; Wt!B8 = =B3*F23;
        %     Wt!B23 = 1066.818000 lbf, all live-read 2026-07-25). LOCKED decision
        %     (user 2026-07-24): the framework uses the metabook's 0.033. Two
        %     different models, reported side by side in the comparison report —
        %     never as an error. todo 2026-07-24 §3c item 2.
            f = WeightsL2.LG_fraction(obj.aircraft_category);
            W = f * W_TO;
        end

        function W = weight_installed_engine(obj)
        %WEIGHT_INSTALLED_ENGINE  Installed engine weight [lbf].
        %   [AE481 metabook Sec. 7, "Fraction-Based Weight Estimates" table]
        %   W = 1.3 * N_en * W_en, W_en = bare/dry (UNINSTALLED) engine weight.
        %   1.3 = installed/bare weight ratio [metabook_data.md:333].
        %   obj.W_en is Raymer 7th ed. Eq. 10.10, uninstalled = 2775.0210 lbf.
        %
        %   ! THE x1.3 IS L2-ONLY (settled decision 1, user 2026-07-25).
        %     L2 has no installation buildup, so one lumped factor is the right
        %     model HERE. L3's Raymer Sec. 15.3.1 adds mounts (15.7), firewall
        %     (15.8), section (15.9), induction (15.10), tailpipe (15.11), cooling
        %     (15.12), oil (15.13), controls (15.14) and starter (15.15) item by
        %     item, so applying x1.3 there would double-count the installation —
        %     WeightsL3.weight_engine_section uses the UNINSTALLED weight.
        %     F16WeightsL2.md §4 / F16WeightsL3.md §4; todo §P4-1b.
        %   ! Independent of W_TO, so it cannot go stale under the sizing loop —
        %     but it is still a Dependent property on the concrete class, so that
        %     mutating prop.T_SL flows through Eq. 10.10 into this term.
            W = 1.3 * obj.N_en * obj.W_en;
        end

        function W = weight_all_else_empty(~, W_TO)
        %WEIGHT_ALL_ELSE_EMPTY  Systems/avionics/furnishings group [lbf].
        %   [AE481 metabook Sec. 7, "Fraction-Based Weight Estimates" table]
        %   Fraction-based: W = 0.17 * W_TO  [metabook_data.md:334]. The extract
        %   states the fraction basis is W0, i.e. takeoff gross weight.
        %   Evaluated at the PASSED W_TO — obj is accepted for API symmetry with
        %   the other weight_* statics but deliberately unread, so there is no
        %   path by which this term can be pinned to a stale weight.
        %   ! This is review finding #5's equation: it used to be called ONCE in
        %     F16WeightsL2's constructor with the literal 31377 (Brandt Wt!B3, an
        %     OUTPUT) and the result frozen into a plain property.
            W = 0.17 * W_TO;
        end

        % ================================================================== %
        % LOW-LEVEL: unit-weight / fraction lookups, and the Brandt engine
        % alternate. Pure scalars in, scalar out.
        % ================================================================== %

        function rho = wing_unit_weight(aircraft_category)
        %WING_UNIT_WEIGHT  Wing structural surface density [lbf/ft^2].
        %   [Raymer 7th ed. Table 15.2; metabook_data.md:321 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 9.0;   % fighters [metabook_data.md:321]
                case 'jet_transport',    rho = 10.0;  % transport/bomber [metabook_data.md:321]
                case 'general_aviation', rho = 2.5;   % GA [metabook_data.md:321]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No wing unit weight for "%s".', aircraft_category);
            end
        end

        function rho = HT_unit_weight(aircraft_category)
        %HT_UNIT_WEIGHT  Horizontal tail structural surface density [lbf/ft^2].
        %   [Raymer 7th ed. Table 15.2; metabook_data.md:322 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 4.0;   % fighters [metabook_data.md:322]
                case 'jet_transport',    rho = 5.5;   % transport/bomber [metabook_data.md:322]
                case 'general_aviation', rho = 2.0;   % GA [metabook_data.md:322]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No HT unit weight for "%s".', aircraft_category);
            end
        end

        function rho = VT_unit_weight(aircraft_category)
        %VT_UNIT_WEIGHT  Vertical tail structural surface density [lbf/ft^2].
        %   [Raymer 7th ed. Table 15.2; metabook_data.md:323 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 5.3;   % fighters [metabook_data.md:323]
                case 'jet_transport',    rho = 5.5;   % transport/bomber [metabook_data.md:323]
                case 'general_aviation', rho = 2.0;   % GA [metabook_data.md:323]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No VT unit weight for "%s".', aircraft_category);
            end
        end

        function rho = fus_unit_weight(aircraft_category)
        %FUS_UNIT_WEIGHT  Fuselage structural surface density [lbf/ft^2].
        %   [Raymer 7th ed. Table 15.2; metabook_data.md:324 — all three rows]
            switch lower(aircraft_category)
                case 'jet_fighter',      rho = 4.8;   % fighters [metabook_data.md:324]
                case 'jet_transport',    rho = 5.0;   % transport/bomber [metabook_data.md:324]
                case 'general_aviation', rho = 1.4;   % GA [metabook_data.md:324]
                otherwise
                    error('WeightsL2:UnknownCategory', ...
                          'No fuselage unit weight for "%s".', aircraft_category);
            end
        end

        function f = LG_fraction(aircraft_category)
        %LG_FRACTION  Landing gear weight as a fraction of W_TO.
        %   [AE481 metabook Sec. 7, "Fraction-Based Weight Estimates" table]
        %   ! NOT Raymer Table 15.2 (settled 2026-07-25, todo §P4-7).
            switch lower(aircraft_category)
                case 'jet_fighter',      f = 0.033;  % non-Navy fighter [metabook_data.md:330]
                case 'jet_transport',    f = 0.043;  % transport [metabook_data.md:332]
                case 'general_aviation'
                    % TODO (todo 2026-07-25 Phase 4 §P4-7, OPEN): 0.057 is
                    % UNCITED. The metabook fraction table (metabook_data.md:328-334)
                    % has NO general-aviation landing-gear row — only fighter
                    % 0.033 (:330), Navy fighter 0.045 (:331) and transport
                    % 0.043 (:332). This value has no source anywhere in the
                    % repo; it is retained unchanged rather than deleted or
                    % re-derived, and must not be cited to the metabook until the
                    % user supplies a source. It does not affect the F-16A
                    % (jet_fighter), so this is a citation-integrity item.
                    f = 0.057;  % [UNCITED — see the TODO above]
                otherwise
                    % NOTE: the extract carries a Navy-fighter row, 0.045 *W0
                    % [metabook_data.md:331], that this lookup deliberately does
                    % NOT add — no consumer exists and adding it would be a
                    % feature beyond this phase. Recorded so its absence reads as
                    % a decision, not an oversight. todo §P4-7 (open).
                    error('WeightsL2:UnknownCategory', ...
                          'No LG fraction for "%s".', aircraft_category);
            end
        end

        function W = engine_weight_brandt(T_AB_SLS)
        %ENGINE_WEIGHT_BRANDT  Brandt's INSTALLED engine weight [lbf] — ALTERNATE.
        %   W = 0.199 * T_AB_SLS
        %   [Brandt Wt!B11 = 4730.230000 (live-read 2026-07-25), formula
        %    =IF(Main!C29=Main!D29,'Engn(s) Old'!D11*Main!B28*Main!C29,
        %        'Engn(s) Old'!D22*Main!B28*Main!D29);
        %    the 0.199 literal lives at 'Engn(s)'!D22 = 0.199 (live), routed
        %    through 'Engn(s) Old'!D22, labelled 'Engn(s) Old'!C22 =
        %    "Engine with AB:  Weng = ". readme_wt.md:230 attributes the formula
        %    to Brandt 1997, Table 6.2.]
        %   T_AB_SLS — SLS afterburning (max) thrust [lbf].
        %
        %   *** COMPARISON-REPORT ALTERNATE ONLY — never summed into any OEW. ***
        %   The framework's official engine weight at BOTH levels is Raymer 7th
        %   ed. Eq. 10.10 (PropL2.engine_weight_AB): uninstalled at L3, x1.3 at
        %   L2. This static exists so the report can show Brandt's own model fed
        %   Brandt's own thrust — a positive control that the propulsion DI
        %   delivers 23,770 lbf correctly (it reproduces Wt!B11 exactly by
        %   construction). Brandt's coefficients are NEVER ported into the
        %   framework equations.
        %
        %   ! NO x1.3 HERE (settled decision 1, user 2026-07-25). readme_wt.md:230
        %     states verbatim that 0.199*T_AB IS the INSTALLED engine weight
        %     formula, so applying the metabook's 1.3 would double-install:
        %     4730.23 -> 6149.30, and L2 OEW would read 18206.42 instead of
        %     16787.35 (both live). That variant agrees BEST with Brandt Wt!B12
        %     (-8.88 %), which is precisely why it is rejected — agreement
        %     produced by a double-counted factor is not agreement. todo §P4-1a.
        %
        %   Shared across tiers: F16WeightsL2 and F16WeightsL3 both expose it as
        %   a Dependent W_en_brandt. It lives in the L2 toolbox as the lower-level
        %   of the two rungs that use it, matching the established cross-tier
        %   low-level-static reuse pattern (cf. AeroL1.oswald_eff called from
        %   L2/L3).
            W = 0.199 * T_AB_SLS;
        end

    end

end
