classdef WeightsL3
%WEIGHTSL3  Level-3 weights static toolbox: Raymer Sec. 15.3.1 buildup.
%
%   Call as WeightsL3.method(...); never instantiated. F16WeightsL3 inherits
%   WeightsModelL3 and delegates here.
%
%   Every equation here is [Raymer 6th ed. Sec. 15.3.1], Eqs. 15.1-15.24
%   (fighter/attack statistical weights). Each method cites its own equation.
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
%   TODO: EVERY Sec. 15.3.1 EXPONENT IS UNVERIFIED AGAINST THE BOOK. 62 rows:
%   2 CONFLICT / 8 FROM-CODE / 26 VERIFY / 26 IMAGE-ONLY. The two CONFLICT
%   rows keep their code values: Eq. 15.13 N_en^1.023 (extract says 1.078) and
%   Eq. 15.3 cos(Lambda_vt)^-0.323 (extract says -1.0). Do not change a value
%   to make the guard green. Guarded by
%   TestWeightsL3.testTODO_Raymer1531ExponentsNotBookVerified; checklist in
%   VnV/BrandtF16A/todo.md Sec. 3a.
%
%   Companion doc: src/disciplines/weights/WeightsL3.md

    methods (Static)

        % ================================================================== %
        % LOW-LEVEL — individual Raymer §15.3.1 equations, plus the one
        % landing-weight rule that has no textbook source.
        % ================================================================== %

        % TODO (9/4/2026)(Casey): Every equation below this comment is from Raymer, 6th edition,
        % sec 15.3.1; these equations are relevant to fighter/attack aircraft.
        % ADD SEC 15.3.2 & 15.3.3.

        % TODO (9/4/2026)(Casey): This is NOT a component weight.
        function W_l = compute_landing_weight(W_TO)
            W_l = 0.95 * W_TO;
        end

        function W = compute_wing_weight(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_LE_deg, S_csw, K_dw, K_vs)
            % Source: Eq 15.1, Raymer 6th ed.
            W = 0.0103 * K_dw * K_vs ...
                * (W_dg * N_z).^0.5 ...
                * S_w.^0.622 ...
                * AR.^0.785 ...
                * tc_root.^(-0.4) ...
                * (1 + lambda).^0.05 ...
                * cosd(Lambda_LE_deg).^(-1.0) ...
                * S_csw.^0.04;
        end

        function W = compute_horizontal_tail_weight(W_dg, N_z, S_ht, F_w, B_h)
            % Source: Eq 15.2, Raymer 6th ed.
            W = 3.316 * (1 + F_w/B_h).^(-2.0) ...
                * ((W_dg .* N_z) / 1000).^0.260 ...
                * S_ht.^0.806;
        end

        function W = compute_vertical_tail_weight(W_dg, N_z, S_vt, K_rht, H_t, H_v, M, L_t, S_r, AR_vt, lambda_vt, Lambda_LE_vt_deg)
            % Source: Eq 15.3, Raymer 6th ed.
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

        function W = compute_fuselage_weight(W_dg, N_z, L_fus, D_fus, W_fus, K_dwf)
            % Source: Eq 15.4, Raymer 6th ed.
            W = 0.499 * K_dwf ...
                * W_dg.^0.35 ...
                * N_z.^0.25 ...
                * L_fus.^0.5 ...
                * D_fus.^0.849 ...
                * W_fus.^0.685;
        end

        function W = compute_main_gear_weight(W_l, N_l, L_m, K_cb, K_tpg)
            % Source: Eq 15.5, Raymer 6th ed.
            W = K_cb * K_tpg * (W_l * N_l).^0.25 .* L_m.^0.973;
        end

        function W = compute_nose_gear_weight(W_l, N_l, L_n, N_nw)
            % Source: Eq 15.6, Raymer 6th ed.
            W = (W_l .* N_l).^0.290 .* L_n.^0.5 .* N_nw.^0.525;
        end

        function W = compute_engine_mounts_weight(N_en, T, N_z)
            % Source: Eq 15.7, Raymer 6th ed.
            W = 0.013 * N_en.^0.795 .* T.^0.579 .* N_z;
        end

        function W = compute_firewall_weight(S_fw)
            % Source: Eq 15.8, Raymer 6th ed.
            W = 1.13 * S_fw;
        end

        function W = compute_engine_section_weight(W_en, N_en, N_z)
            % Source: Eq 15.9, Raymer 6th ed.
            W = 0.01 * W_en.^0.717 .* N_en .* N_z;
        end

        function W = compute_air_induction_weight(K_vg, L_d, K_d, N_en, L_s, D_e)
            % Source: Eq 15.10, Raymer 6th ed.
            W = 13.29 * K_vg .* L_d.^0.643 .* K_d.^0.182 ...
                .* N_en.^1.498 .* (L_s./L_d).^(-0.373) .* D_e;
        end

        function W = compute_tailpipe_weight(D_e, L_tp, N_en)
            % Source: Eq 15.11, Raymer 6th ed.
            W = 3.5 * D_e .* L_tp .* N_en;
        end

        function W = compute_engine_cooling_weight(D_e, L_sh, N_en)
            % Source: Eq 15.12, Raymer 6th ed
            W = 4.55 * D_e .* L_sh .* N_en;
        end

        function W = compute_oil_cooling_weight(N_en)
            % Source: Eq 15.13, Raymer 6th ed.
            W = 37.82 * N_en.^1.023;
        end

        function W = compute_engine_controls_weight(N_en, L_ec)
            % Source: Eq 15.14, Raymer 6th ed
            W = 10.5 * N_en.^(1.008) .* L_ec.^(0.222);
        end

        function W = compute_starter_weight(T, N_en)
            % Source: Eq 15.15, Raymer 6th ed
            W = 0.025 * T.^0.760 .* N_en.^0.72;
        end

        function W = compute_fuel_system_weight(V_t, V_i, V_p, N_t, N_en, T, SFC)
            % Source: Eq 15.16, Raymer 6th ed.
            W = 7.45 * V_t.^0.47 ...
                .* (1 + V_i./V_t).^(-0.095) ...
                .* (1 + V_p./V_t) ...
                .* N_t.^0.066 ...
                .* N_en.^0.052 ...
                .* ((T .* SFC) / 1000).^0.249;
        end

        function W = compute_flight_controls_weight(M, S_cs, N_s, N_c)
            % Source: Eq 15.17, Raymer 6th ed.
            W = 36.28 * M.^0.003 .* S_cs.^0.489 .* N_s.^0.484 .* N_c.^0.127;
        end

        function W = compute_instruments_weight(N_en, N_t, N_ci)
            % Source: Eq 15.18, Raymer 6th ed.
            W = 8.0 + 36.37 * N_en.^0.676 .* N_t.^0.237 + 26.4 * (1 + N_ci).^1.356;
        end

        function W = compute_hydraulics_weight(K_vsh, N_u)
            % Source: Eq 15.19, Raymer 6th ed.
            W = 37.23 * K_vsh .* N_u.^0.664;
        end

        function W = compute_electrical_weight(K_mc, R_kva, N_c, L_a, N_gen)
            % Source: Eq 15.20, Raymer 6th ed.
            W = 172.2 * K_mc .* R_kva.^0.152 .* N_c.^0.10 .* L_a.^0.10 .* N_gen.^0.091;
        end

        % Note (9/4/2026)(Casey): Why is "W_uav" an argument?
        % Weight of the uav? This is only relevant to UAVs.
        % W_uav = Weight of "Uninstalled AVionics".
        function W = compute_avionics_weight(W_uav)
            % Source: Eq 15.21, Raymer 6th ed.
            W = 2.117 * W_uav.^0.933;
        end

        function W = compute_furnishings_weight(N_c)
            % Source: Eq 15.22, Raymer 6th ed.
            W = 217.6 * N_c;
        end

        function W = compute_ac_antiice_weight(W_uav, N_c)
            % Source: Eq 15.23, Raymer 6th ed.
            W = 201.6 * ((W_uav + 200 * N_c) / 1000).^0.735;
        end

        function W = compute_handling_gear_weight(W_TO)
            % Source: Eq 15.24, Raymer 6th ed.
            W = 3.2e-4 * W_TO;
        end

        function W = compute_arresting_gear_weight(W_dg, isNavy)
            arguments
                W_dg   (1,1) double {mustBePositive}
                isNavy (1,1) logical = false % false = default value.
            end

            % Source: Table 15.3, Raymer 6th ed.
            if isNavy
                W = 0.008 * W_dg;
            else
                W = 0.002 * W_dg;
            end
        end

        function W = compute_pylon_and_launcher_weight(W_missile)
            % Source: Table 15.3, Raymer 6th ed., p. 571 (Missiles block).
            W = 0.12*W_missile;
        end

    end

end
