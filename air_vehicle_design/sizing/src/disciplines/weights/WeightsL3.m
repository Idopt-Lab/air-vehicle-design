classdef WeightsL3
%WEIGHTSL3  Level-3 weights static toolbox: Raymer Sec. 15.3.1 buildup.
%
%   Call as WeightsL3.method(...); never instantiated, not in the inheritance
%   chain. F16WeightsL3 inherits WeightsModelL3 and delegates to these statics.
%
%   Every equation here is [Raymer 6th ed. Sec. 15.3.1], Eqs. 15.1-15.24
%   (fighter/attack statistical weights). Individual methods cite their own
%   equation number only.
%
%   UNITS (Raymer's nomenclature, English throughout):
%     weights, thrust                          [lbf]
%     areas                                    [ft^2]
%     lengths, heights, diameters              [ft]
%     L_m, L_n                                 [INCHES at the equation --
%                                               the caller converts from feet]
%     V_t, V_i, V_p                            [gal]
%     SFC [1/hr], R_kva [kVA], K_* and N_* [-]
%
%   TODO: EVERY Sec. 15.3.1 EXPONENT IS UNVERIFIED AGAINST THE BOOK.
%   62 rows: 2 CONFLICT / 8 FROM-CODE / 26 VERIFY / 26 IMAGE-ONLY (corrected
%   2026-07-30 by a direct recount of the recovered table; the previous
%   9/24/27/5 figures summed to 67, not the table's actual 62 rows).
%   The two CONFLICT rows keep their code values: Eq. 15.13 N_en^1.023
%   (extract says 1.078) and Eq. 15.3 cos(Lambda_vt)^-0.323 (extract says
%   -1.0). Do not change a value to make the guard green. Guarded by
%   TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified; checklist in
%   VnV/BrandtF16A/todo.md 2026-07-24 Sec. 3a.
%
%   Companion doc: src/disciplines/weights/WeightsL3.md

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL
        % ================================================================== %

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function oew = OEW(obj, W_TO)
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

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_wing(obj, W_TO)
            W = WeightsL3.wing(W_TO, obj.N_z, obj.S_w, obj.AR_w, obj.tc_root, ...
                               obj.lambda_w, obj.Lambda_LE_w, obj.S_csw, ...
                               obj.K_dw, obj.K_vs);
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W_tail = weight_tail(obj, W_TO)
            W_tail.HT = WeightsL3.horizontal_tail(W_TO, obj.N_z, obj.S_ht, ...
                                                   obj.F_w, obj.B_h);
            W_tail.VT = WeightsL3.vertical_tail(W_TO, obj.N_z, obj.S_vt, ...
                                                 obj.K_rht, obj.H_t, obj.H_v, ...
                                                 obj.design_mach, obj.L_t, obj.S_r, ...
                                                 obj.AR_vt, obj.lambda_vt, obj.Lambda_LE_vt);
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_fuselage(obj, W_TO)
            W = WeightsL3.fuselage(W_TO, obj.N_z, obj.L_fus, obj.D_fus, ...
                                   obj.W_fus, obj.K_dwf);
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W_lg = weight_landing_gear(obj, W_TO)
            L_m_in = obj.L_m * 12;
            L_n_in = obj.L_n * 12;
            W_l    = WeightsL3.landing_weight(W_TO);
            W_lg.main = WeightsL3.main_gear(W_l, obj.N_l, L_m_in, ...
                                             obj.K_cb, obj.K_tpg);
            W_lg.nose = WeightsL3.nose_gear(W_l, obj.N_l, L_n_in, obj.N_nw);
        end

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_engine_section(obj, ~)
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

        % TODO (8/14/2026): Again, looks like an artefact from when this was a subclass of an enforcer. Relocate to F-16 example if that wasn't done already.
        function W = weight_systems(obj, W_TO)
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
            W_l = 0.95 * W_TO;
        end

        function W = wing(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_LE_deg, S_csw, K_dw, K_vs)
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
            W = 3.316 * (1 + F_w/B_h).^(-2.0) ...
                * ((W_dg .* N_z) / 1000).^0.260 ...
                * S_ht.^0.806;
        end

        function W = vertical_tail(W_dg, N_z, S_vt, K_rht, H_t, H_v, M, L_t, S_r, AR_vt, lambda_vt, Lambda_LE_vt_deg)
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
            W = 0.499 * K_dwf ...
                * W_dg.^0.35 ...
                * N_z.^0.25 ...
                * L_fus.^0.5 ...
                * D_fus.^0.849 ...
                * W_fus.^0.685;
        end

        function W = main_gear(W_l, N_l, L_m, K_cb, K_tpg)
            W = K_cb * K_tpg * (W_l * N_l).^0.25 .* L_m.^0.973;
        end

        function W = nose_gear(W_l, N_l, L_n, N_nw)
            W = (W_l .* N_l).^0.290 .* L_n.^0.5 .* N_nw.^0.525;
        end

        function W = engine_mounts(N_en, T, N_z)
            W = 0.013 * N_en.^0.795 .* T.^0.579 .* N_z;
        end

        function W = firewall(S_fw)
            W = 1.13 * S_fw;
        end

        function W = engine_section(W_en, N_en, N_z)
            W = 0.01 * W_en.^0.717 .* N_en .* N_z;
        end

        function W = air_induction(K_vg, L_d, K_d, N_en, L_s, D_e)
            W = 13.29 * K_vg .* L_d.^0.643 .* K_d.^0.182 ...
                .* N_en.^1.498 .* (L_s./L_d).^(-0.373) .* D_e;
        end

        function W = tailpipe(D_e, L_tp, N_en)
            W = 3.5 * D_e .* L_tp .* N_en;
        end

        function W = engine_cooling(D_e, L_sh, N_en)
            W = 4.55 * D_e .* L_sh .* N_en;
        end

        function W = oil_cooling(N_en)
            W = 37.82 * N_en.^1.023;
        end

        function W = engine_controls(N_en, L_ec)
            W = 10.5 * N_en.^(1.008) .* L_ec.^(0.222);
        end

        function W = starter(T, N_en)
            W = 0.025 * T.^0.760 .* N_en.^0.72;
        end

        function W = fuel_system(V_t, V_i, V_p, N_t, N_en, T, SFC)
            W = 7.45 * V_t.^0.47 ...
                .* (1 + V_i./V_t).^(-0.095) ...
                .* (1 + V_p./V_t) ...
                .* N_t.^0.066 ...
                .* N_en.^0.052 ...
                .* ((T .* SFC) / 1000).^0.249;
        end

        function W = flight_controls(M, S_cs, N_s, N_c)
            W = 36.28 * M.^0.003 .* S_cs.^0.489 .* N_s.^0.484 .* N_c.^0.127;
        end

        function W = instruments(N_en, N_t, N_ci)
            W = 8.0 + 36.37 * N_en.^0.676 .* N_t.^0.237 + 26.4 * (1 + N_ci).^1.356;
        end

        function W = hydraulics(K_vsh, N_u)
            W = 37.23 * K_vsh .* N_u.^0.664;
        end

        function W = electrical(K_mc, R_kva, N_c, L_a, N_gen)
            W = 172.2 * K_mc .* R_kva.^0.152 .* N_c.^0.10 .* L_a.^0.10 .* N_gen.^0.091;
        end

        function W = avionics(W_uav)
            W = 2.117 * W_uav.^0.933;
        end

        function W = furnishings(N_c)
            W = 217.6 * N_c;
        end

        function W = ac_antiice(W_uav, N_c)
            W = 201.6 * ((W_uav + 200 * N_c) / 1000).^0.735;
        end

        function W = handling_gear(W_TO)
            W = 3.2e-4 * W_TO;
        end

    end

end
