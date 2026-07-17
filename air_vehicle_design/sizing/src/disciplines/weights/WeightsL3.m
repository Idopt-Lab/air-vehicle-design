classdef WeightsL3
%WEIGHTSL3  Level-3 weight estimation static toolbox.
%
%   Call as WeightsL3.method_name(args) — no instantiation required.
%   Not in the inheritance chain.  Student classes (F16WeightsL3, etc.)
%   inherit from WeightsModelL3 and call these statics to implement each
%   abstract method.
%
%   SOURCE:
%     Raymer, "Aircraft Design: A Conceptual Approach," 6th ed., AIAA, 2018,
%     §15.3.1 — Fighter/Attack Statistical Weights (Eqs. 15.1–15.24).
%     English units: W_dg [lbf], T [lbf], S [ft²], L [ft], V [gal],
%     D_e [ft], SFC [1/hr], thrust [lbf].  Output: W [lbf].
%
%   ⚠ Exponent warnings:
%     Exponents marked [verify] were extracted by OCR and may be garbled.
%     Cross-check against Raymer 6th ed. PDF pp. 602–603 before citing.
%     Exponents marked [from existing code] were resolved from the project's
%     prior WeightLevel3.m implementation (air-vehicle-design repository).
%
%   TWO TIERS of statics:
%     High-level — accept the student object (obj) and W_TO [lbf].
%                  Each high-level method unpacks the geometry properties from
%                  obj and passes scalars to the corresponding low-level function.
%                  Passing obj avoids 10–15 scalar arguments per call.
%     Low-level  — pure math; take only scalars (no object access).

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL
        % ================================================================== %

        function oew = OEW(obj, W_TO)
        %OEW  Total operating empty weight [lbf]; sum of all component groups.
        %   W_TO — candidate gross weight [lbf] (used in load-path calculations).
            W_str  = WeightsL3.weight_wing(obj, W_TO);
            W_tail = WeightsL3.weight_tail(obj, W_TO);
            W_fus  = WeightsL3.weight_fuselage(obj, W_TO);
            W_lg   = WeightsL3.weight_landing_gear(obj);
            W_eng  = WeightsL3.weight_engine_section(obj, W_TO);
            W_sys  = WeightsL3.weight_systems(obj, W_TO);
            oew = W_str + W_tail.HT + W_tail.VT + W_fus + ...
                  W_lg.main + W_lg.nose + W_eng.total + W_sys.total;
        end

        % ------------------------------------------------------------------ %
        % Structural group
        % ------------------------------------------------------------------ %

        function W = weight_wing(obj, W_TO)
        %WEIGHT_WING  Wing structural weight [lbf].  [Raymer Eq. 15.1]
        %   W = 0.0103·K_dw·K_vs·(W_dg·N_z)^0.5·S_w^0.622·AR^0.785
        %       ·(t/c)_root^(-0.4)·(1+λ)^0.05·cos(Λ_LE)^(-1.0)·S_csw^0.04
        %   ⚠ All exponents [verify from Raymer 6th ed. p.602].
        %   ⚠ Λ is defined as leading-edge sweep in raymer_data.md; some
        %     editions use quarter-chord sweep — verify sweep definition.
            W = WeightsL3.wing(W_TO, obj.N_z, obj.S_w, obj.AR_w, obj.tc_root, ...
                               obj.lambda_w, obj.Lambda_LE_w, obj.S_csw, ...
                               obj.K_dw, obj.K_vs);
        end

        function W_tail = weight_tail(obj, W_TO)
        %WEIGHT_TAIL  Horizontal and vertical tail weight [lbf].  [Raymer Eqs. 15.2-15.3]
        %   Returns struct with fields HT and VT.
            W_tail.HT = WeightsL3.horizontal_tail(W_TO, obj.N_z, obj.S_ht, ...
                                                   obj.F_w, obj.B_h);
            W_tail.VT = WeightsL3.vertical_tail(W_TO, obj.N_z, obj.S_vt, ...
                                                 obj.K_rht, obj.H_t, obj.H_v, ...
                                                 obj.M_design, obj.L_t, obj.S_r, ...
                                                 obj.AR_vt, obj.lambda_vt, obj.Lambda_LE_vt);
        end

        function W = weight_fuselage(obj, W_TO)
        %WEIGHT_FUSELAGE  Fuselage structural weight [lbf].  [Raymer Eq. 15.4]
        %   W = 0.499·K_dwf·W_dg^0.35·N_z^0.25·L_fus^0.5·D_fus^0.849·W_fus^0.685
        %   ⚠ Exponents [verify from Raymer 6th ed. p.602].
            W = WeightsL3.fuselage(W_TO, obj.N_z, obj.L_fus, obj.D_fus, ...
                                   obj.W_fus, obj.K_dwf);
        end

        function W_lg = weight_landing_gear(obj)
        %WEIGHT_LANDING_GEAR  Main + nose gear weight [lbf].  [Raymer Eqs. 15.5-15.6]
        %   Returns struct with fields main and nose.
            W_lg.main = WeightsL3.main_gear(obj.W_l, obj.N_l, obj.L_m, ...
                                             obj.K_cb, obj.K_tpg);
            W_lg.nose = WeightsL3.nose_gear(obj.W_l, obj.N_l, obj.L_n, obj.N_nw);
        end

        function W = weight_engine_section(obj, ~)
        %WEIGHT_ENGINE_SECTION  Engine support + propulsion systems [lbf].
        %   Eqs. 15.7–15.15; returns struct with sub-component fields + .total.
        %   W_TO is accepted for API consistency but not needed by these equations.
            W.mounts   = WeightsL3.engine_mounts(obj.N_en, obj.T_max, obj.N_z);
            W.firewall = WeightsL3.firewall(obj.S_fw); % jet fighters set S_fw=0; eq. returns 0 for no piston firewall
            W.section  = WeightsL3.engine_section(obj.W_en, obj.N_en, obj.N_z);
            W.induction = WeightsL3.air_induction(obj.K_vg, obj.L_d, obj.K_d, ...
                                                    obj.N_en, obj.L_s, obj.D_e);
            W.tailpipe = WeightsL3.tailpipe(obj.D_e, obj.L_tp, obj.N_en);
            W.cooling  = WeightsL3.engine_cooling(obj.D_e, obj.L_sh, obj.N_en);
            W.oil      = WeightsL3.oil_cooling(obj.N_en, obj.L_ec);
            W.controls = 0;  % Eq. 15.14 exponents not available; see [verify note] in oil_cooling
            W.starter  = WeightsL3.starter(obj.T_max, obj.N_en);
            W.total    = W.mounts + W.firewall + W.section + W.induction + ...
                         W.tailpipe + W.cooling + W.oil + W.starter;
        end

        function W = weight_systems(obj, W_TO)
        %WEIGHT_SYSTEMS  Avionics, fuel, controls, furnishings group [lbf].
        %   Eqs. 15.16–15.24; returns struct with sub-component fields + .total.
            W.fuel_sys     = WeightsL3.fuel_system(obj.V_t, obj.V_i, obj.V_p, ...
                                                     obj.N_t, obj.N_en, ...
                                                     obj.T_max, obj.SFC_mission);
            W.flight_ctrl  = WeightsL3.flight_controls(obj.M_design, obj.S_cs, ...
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
        % LOW-LEVEL — individual Raymer §15.3.1 equations
        % ================================================================== %

        function W = wing(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_LE_deg, S_csw, K_dw, K_vs)
        %WING  Raymer Eq. 15.1 — wing structural weight [lbf].
        %   W = 0.0103·K_dw·K_vs·(W_dg·N_z)^0.5·S_w^0.622·AR^0.785
        %       ·tc_root^(-0.4)·(1+λ)^0.05·cos(Λ_LE)^(-1.0)·S_csw^0.04
        %   ⚠ All exponents [verify Raymer 6th ed. p.602].
        %   ⚠ Λ_LE = leading-edge sweep [deg]; some editions use Λ_0.25c — verify.
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
        %HORIZONTAL_TAIL  Raymer Eq. 15.2 — HT weight [lbf].
        %   W = 3.316·(1 + F_w/B_h)^(-2.0)·((W_dg·N_z)/1000)^0.260·S_ht^0.806
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   F_w — fuselage width at HT intersection [ft].
        %   B_h — horizontal tail span [ft].
            W = 3.316 * (1 + F_w/B_h).^(-2.0) ...
                * ((W_dg .* N_z) / 1000).^0.260 ...
                * S_ht.^0.806;
        end

        function W = vertical_tail(W_dg, N_z, S_vt, K_rht, H_t, H_v, M, L_t, S_r, AR_vt, lambda_vt, Lambda_LE_vt_deg)
        %VERTICAL_TAIL  Raymer Eq. 15.3 — VT weight [lbf].
        %   W = 0.452·K_rht·(1+H_t/H_v)^0.5·(W_dg·N_z)^0.488·S_vt^0.718
        %       ·M^0.341·L_t^(-1.0)·(1+S_r/S_vt)^0.348·AR_vt^0.223
        %       ·(1+λ_vt)^0.25·cos(Λ_vt)^(-0.323)
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   H_t/H_v — tail-height ratio; 0 for conventional mid/low tail (not T-tail).
        %   L_t     — tail moment arm (wing ¼MAC to HT ¼MAC) [ft].
        %   S_r     — VT control surface (rudder) area [ft²].
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
        %FUSELAGE  Raymer Eq. 15.4 — fuselage structural weight [lbf].
        %   W = 0.499·K_dwf·W_dg^0.35·N_z^0.25·L_fus^0.5·D_fus^0.849·W_fus^0.685
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   L_fus — fuselage length [ft].  D_fus — max fuselage depth [ft].
        %   W_fus — max fuselage width [ft].
            W = 0.499 * K_dwf ...
                * W_dg.^0.35 ...
                * N_z.^0.25 ...
                * L_fus.^0.5 ...
                * D_fus.^0.849 ...
                * W_fus.^0.685;
        end

        function W = main_gear(W_l, N_l, L_m, K_cb, K_tpg)
        %MAIN_GEAR  Raymer Eq. 15.5 — main landing gear weight [lbf].
        %   W = K_cb·K_tpg·(W_l·N_l)^0.25·L_m^0.973
        %   [Exponent 0.973 from WeightLevel3.m (air-vehicle-design repo) = prior working impl.]
        %   W_l — landing weight [lbf].  N_l — landing load factor.
        %   L_m — main gear strut length [ft].
        %   K_cb = 1.0 (non-carrier); K_tpg = 1.0 (non-kneeling gear).
            W = K_cb * K_tpg * (W_l * N_l).^0.25 .* L_m.^0.973;
        end

        function W = nose_gear(W_l, N_l, L_n, N_nw)
        %NOSE_GEAR  Raymer Eq. 15.6 — nose landing gear weight [lbf].
        %   W = (W_l·N_l)^0.290·L_n^0.5·N_nw^0.525
        %   [Exponent 0.525 from WeightLevel3.m (air-vehicle-design repo)]
        %   L_n — nose gear strut length [ft].  N_nw — number of nose wheels.
            W = (W_l .* N_l).^0.290 .* L_n.^0.5 .* N_nw.^0.525;
        end

        function W = engine_mounts(N_en, T, N_z)
        %ENGINE_MOUNTS  Raymer Eq. 15.7 — engine mount weight [lbf].
        %   W = 0.013·N_en^0.795·T^0.579·N_z
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   T — total engine thrust (SLS AB) [lbf].  N_z — ultimate load factor.
            W = 0.013 * N_en.^0.795 .* T.^0.579 .* N_z;
        end

        function W = firewall(S_fw)
        %FIREWALL  Raymer Eq. 15.8 — firewall weight [lbf].
        %   W = 1.13·S_fw.  S_fw — firewall area [ft²].
        %   For jet fighters without piston engines, S_fw = 0.
            W = 1.13 * S_fw;
        end

        function W = engine_section(W_en, N_en, N_z)
        %ENGINE_SECTION  Raymer Eq. 15.9 — engine section structural weight [lbf].
        %   W = 0.01·W_en^0.717·N_en·N_z
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   W_en — installed engine (dry) weight [lbf]; see student class.
            W = 0.01 * W_en.^0.717 .* N_en .* N_z;
        end

        function W = air_induction(K_vg, L_d, K_d, N_en, L_s, D_e)
        %AIR_INDUCTION  Raymer Eq. 15.10 — inlet duct weight [lbf].
        %   W = 13.29·K_vg·L_d^0.643·K_d^0.182·N_en^0.1498·(L_s/L_d)^(-0.373)·D_e
        %   [Exponents 0.1498 and -0.373 from WeightLevel3.m (air-vehicle-design repo)]
        %   K_vg = 1.0 (fixed geometry); K_d = 0 (straight duct) or 1 (bifurcated).
        %   L_d — duct length [ft]; D_e — engine face diameter [ft].
        %   L_s — splitter/bypass length [ft].
            W = 13.29 * K_vg .* L_d.^0.643 .* K_d.^0.182 ...
                .* N_en.^0.1498 .* (L_s./L_d).^(-0.373) .* D_e;
        end

        function W = tailpipe(D_e, L_tp, N_en)
        %TAILPIPE  Raymer Eq. 15.11 — tailpipe weight [lbf].
        %   W = 3.5·D_e·L_tp·N_en.  D_e — nozzle exit diameter [ft].  L_tp [ft].
            W = 3.5 * D_e .* L_tp .* N_en;
        end

        function W = engine_cooling(D_e, L_sh, N_en)
        %ENGINE_COOLING  Raymer Eq. 15.12 — engine cooling/shroud weight [lbf].
        %   W = 4.55·D_e·L_sh·N_en.  L_sh — engine shroud length [ft].
            W = 4.55 * D_e .* L_sh .* N_en;
        end

        function W = oil_cooling(N_en, L_ec)
        %OIL_COOLING  Raymer Eq. 15.13 — oil cooling system weight [lbf].
        %   W = 37.82·N_en^1.008·L_ec^0.222
        %   [Exponents from WeightLevel3.m; raymer_data.md OCR had N_en^1.078 — verify]
        %   L_ec — engine controls length [ft].
            W = 37.82 * N_en.^1.008 .* L_ec.^0.222;
        end

        % Eq. 15.14 (engine controls) is omitted: exponents on N_en and L_ec
        % are missing from OCR.  Use oil_cooling above which combines 15.13+15.14
        % in the WeightLevel3.m working implementation.

        function W = starter(T, N_en)
        %STARTER  Raymer Eq. 15.15 — pneumatic starter weight [lbf].
        %   W = 0.025·T^0.760·N_en^0.72
        %   T — engine SLS AB thrust [lbf].
            W = 0.025 * T.^0.760 .* N_en.^0.72;
        end

        function W = fuel_system(V_t, V_i, V_p, N_t, N_en, T, SFC)
        %FUEL_SYSTEM  Raymer Eq. 15.16 — fuel system weight [lbf].
        %   W = 7.45·V_t^0.47·(1+V_i/V_t)^(-0.095)·(1+V_p/V_t)·N_t^0.066
        %       ·N_en^0.052·((T·SFC)/1000)^0.249
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   V_t — total fuel volume [gal]; V_i — integral tank volume [gal];
        %   V_p — pressurized tank volume [gal]; N_t — number of tanks.
        %   T — max thrust [lbf]; SFC — mission SFC [1/hr].
            W = 7.45 * V_t.^0.47 ...
                .* (1 + V_i./V_t).^(-0.095) ...
                .* (1 + V_p./V_t) ...
                .* N_t.^0.066 ...
                .* N_en.^0.052 ...
                .* ((T .* SFC) / 1000).^0.249;
        end

        function W = flight_controls(M, S_cs, N_s, N_c)
        %FLIGHT_CONTROLS  Raymer Eq. 15.17 — FCS weight [lbf].
        %   W = 36.28·M^0.003·S_cs^0.489·N_s^0.484·N_c^0.127
        %   [Exponent 0.127 on N_c from WeightLevel3.m]
        %   S_cs — total control surface area [ft²]; N_s — no. of control surfaces;
        %   N_c — no. of cockpits.
            W = 36.28 * M.^0.003 .* S_cs.^0.489 .* N_s.^0.484 .* N_c.^0.127;
        end

        function W = instruments(N_en, N_t, N_ci)
        %INSTRUMENTS  Raymer Eq. 15.18 — instruments and navigations weight [lbf].
        %   W = 8.0 + 36.37·N_en^0.676·N_t^0.237 + 26.4·(1+N_ci)^1.356
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   N_t — number of fuel tanks; N_ci — no. of communication/ID items.
            W = 8.0 + 36.37 * N_en.^0.676 .* N_t.^0.237 + 26.4 * (1 + N_ci).^1.356;
        end

        function W = hydraulics(K_vsh, N_u)
        %HYDRAULICS  Raymer Eq. 15.19 — hydraulics system weight [lbf].
        %   W = 37.23·K_vsh·N_u^0.664
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   K_vsh = 1.0 (no variable-sweep); N_u — no. of hydraulic utility functions.
            W = 37.23 * K_vsh .* N_u.^0.664;
        end

        function W = electrical(K_mc, R_kva, N_c, L_a, N_gen)
        %ELECTRICAL  Raymer Eq. 15.20 — electrical system weight [lbf].
        %   W = 172.2·K_mc·R_kva^0.152·N_c^0.10·L_a^0.10·N_gen^0.091
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
        %   R_kva — electrical power requirement [kVA]; L_a — lead length [ft];
        %   N_gen — number of generators; K_mc = 1.0 (≤2 generators).
            W = 172.2 * K_mc .* R_kva.^0.152 .* N_c.^0.10 .* L_a.^0.10 .* N_gen.^0.091;
        end

        function W = avionics(W_uav)
        %AVIONICS  Raymer Eq. 15.21 — installed avionics weight [lbf].
        %   W = 2.117·W_uav^0.933.  W_uav — uninstalled avionics weight [lbf].
        %   ⚠ Exponents [verify Raymer 6th ed. p.602].
            W = 2.117 * W_uav.^0.933;
        end

        function W = furnishings(N_c)
        %FURNISHINGS  Raymer Eq. 15.22 — furnishings weight (includes ejection seats) [lbf].
        %   W = 217.6·N_c.  N_c — number of cockpits (crew members).
            W = 217.6 * N_c;
        end

        function W = ac_antiice(W_uav, N_c)
        %AC_ANTIICE  Raymer Eq. 15.23 — air conditioning + anti-ice weight [lbf].
        %   W = 201.6·((W_uav + 200·N_c)/1000)^0.735
        %   ⚠ Exponent [verify Raymer 6th ed. p.602].
            W = 201.6 * ((W_uav + 200 * N_c) / 1000).^0.735;
        end

        function W = handling_gear(W_TO)
        %HANDLING_GEAR  Raymer Eq. 15.24 — handling gear weight [lbf].
        %   W = 3.2e-4·W_TO.
            W = 3.2e-4 * W_TO;
        end

    end

end
