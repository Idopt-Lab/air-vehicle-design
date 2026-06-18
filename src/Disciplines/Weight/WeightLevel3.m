classdef WeightLevel3 < WeightsBase
    % Level III weights: component buildup method (Nicolai/Raymer Ch 15).
    %
    % OEW is estimated by summing structural component weights (wing, fuselage,
    % tail) and subsystem weights.  Requires a coefficient table (struct) that
    % holds the aircraft-specific geometric constants for each component equation.
    %
    % Usage:
    %   wts   = WeightLevel3(aircraft_type, coeff_table, T0, W_eng_installed);
    %   oew   = wts.OEW(31000);

    properties
        aircraft_type
        coeff           % struct with geometric/loading constants
        T0              % sea-level static thrust (lbf) — needed for subsystems
        W_eng_installed % installed engine weight (lbf)
    end

    methods
        function obj = WeightLevel3(aircraft_type, coeff_table, T0, W_eng_installed)
            obj.aircraft_type   = aircraft_type;
            obj.coeff           = coeff_table;
            obj.T0              = T0;
            obj.W_eng_installed = W_eng_installed;
        end

        function oew_val = OEW(obj, W_TO)
            c = obj.coeff;
            W_wing = WeightLevel3.wing_weight_III(W_TO, c.Nz, c.S_w, c.AR, ...
                c.tc_root, c.lambda, c.Lambda_qc, c.S_csw, c.K_dw, c.K_vs);
            W_fus  = WeightLevel3.fuselage_weight_III(c.K_dwf, W_TO, c.Nz, ...
                c.L, c.D, c.W);
            [W_HT, W_VT] = WeightLevel3.tail_weight_III(c.F_w, c.B_h, W_TO, ...
                c.Nz, c.S_ht, c.K_rht, c.H_t, c.H_v, c.S_vt, c.M, c.L_t, ...
                c.S_r, c.A_vt, c.lambda_vt, c.Lambda_VT, c.Ht_Hv);
            subs = WeightLevel3.subsystem_weight_III(obj.coeff, W_TO, obj.T0, obj.W_eng_installed);
            oew_val = W_wing + W_fus + W_HT + W_VT + subs.total;
        end
    end

    methods (Static)

        function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
            WF = exp(-(R * TSFC) / (Vend * LD_ratio));
        end

        function output = compute_W_all_else_empty(W_TO, aircraft_type)
            switch aircraft_type
                case {"Jet fighter","fighter"};       output = 0.17*W_TO;
                case {"Transport","Bomber","transport","bomber"}; output = 0.17*W_TO;
                case {"General aviation","general aviation"};    output = 0.10*W_TO;
                otherwise; error("Unrecognized type: %s", aircraft_type)
            end
        end

        function eng_weight = compute_engine_installed_weight(Thrust)
            eng_weight.W_dry     = 0.521*Thrust^0.9;
            eng_weight.W_oil     = 0.082*Thrust^0.65;
            eng_weight.W_rev     = 0.034*Thrust;
            eng_weight.W_control = 0.26*Thrust^0.5;
            eng_weight.W_start   = 9.33*(eng_weight.W_dry/1000)^1.078;
            eng_weight.W_total   = eng_weight.W_dry + eng_weight.W_oil + ...
                eng_weight.W_rev + eng_weight.W_control + eng_weight.W_start;
            eng_weight.W_installed = 1.3*eng_weight.W_total;
        end

        function W_fuselage = fuselage_weight_III(K_dwf, W_dg, N_z, L, D, W)
            W_fuselage = 0.499 * K_dwf * W_dg^0.35 * N_z^0.25 * L^0.5 * D^0.849 * W^0.685;
        end

        function W_wing = wing_weight_III(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_qc, S_csw, K_dw, K_vs)
            W_wing = 3.08 * ((K_vs*N_z*W_dg/tc_root) * ...
                ((tand(Lambda_qc) - 2*(1-lambda)/(AR*(1+lambda)))^2 + 1) * 1e-6)^0.593 * ...
                ((1+lambda)*AR)^0.89 * S_w^0.741;
        end

        function [W_HT, W_VT] = tail_weight_III(F_w, B_h, W_dg, N_z, S_ht, K_rht, H_t, H_v, S_vt, M, L_t, S_r, A_vt, lambda_vt, Lambda_VT, Ht_Hv)
            W_HT = 3.316*(1+F_w/B_h)^(-2.0) * ((W_dg*N_z)/1000)^0.260 * S_ht^0.806;
            W_VT = 0.452*K_rht*(1+Ht_Hv)^0.5 * (W_dg*N_z)^0.488 * S_vt^0.718 * ...
                M^0.341 * L_t^(-1.0) * (1+S_r/S_vt)^0.348 * A_vt^0.223 * ...
                (1+lambda_vt)^0.25 * cosd(Lambda_VT)^(-0.323);
        end

        function subsystems = subsystem_weight_III(c, W_TO, T0, W_engine_installed)
            subsystems.W_landinggear       = WeightLevel3.landinggear(c.Kcb, c.Ktpg, c.Wl, c.Nl, c.Lm, c.Nnw, c.Ln);
            subsystems.W_engine_systems    = WeightLevel3.engine_systems_weights(c.Nen, T0, c.Nz, W_engine_installed, c.De, c.Lsh, c.Lec, T0);
            subsystems.W_firewall          = 1.13*c.Sfw;
            subsystems.W_air_induction     = 13.29*c.Kvg*c.Ld^0.643*c.Kd^0.182*c.Nen^0.1498*(c.Ls/c.Ld)^(-0.373)*c.De;
            subsystems.W_tailpipe          = 3.5*c.De*c.Ltp*c.Nen;
            subsystems.W_fuelsystem        = 7.45*c.Vt^0.47*(1+c.Vi/c.Vt)^(-0.095)*(1+c.VP/c.Vt)*c.Nt^0.066*c.Nen^0.052*(T0*c.SFC/1000)^0.249;
            subsystems.W_flight_controls   = 36.28*c.M^0.003*c.Scs^0.489*c.Ns^0.484*c.Nc^0.127;
            subsystems.W_instruments       = 8.0 + 36.37*c.Nen^0.676*c.Nt^0.237 + 26.4*(1+c.Nci)^1.356;
            subsystems.W_hydraulics        = 37.23*c.Kvsh*c.Nu^0.664;
            subsystems.W_electrical        = 172.2*c.Kmc*c.Rkva^0.152*c.Nc^0.10*c.La^0.10*c.Ngen^0.091;
            subsystems.W_avionics          = 2.117*c.Wuav^0.933;
            subsystems.W_furnishings       = 217.6*c.Nc;
            subsystems.W_AC                = 201.6*((c.Wuav+200*c.Nc)/1000)^0.735;
            subsystems.W_handling_gear     = 3.2e-4*W_TO;
            subsystems.total = subsystems.W_landinggear + subsystems.W_engine_systems + ...
                subsystems.W_firewall + subsystems.W_air_induction + subsystems.W_tailpipe + ...
                subsystems.W_fuelsystem + subsystems.W_flight_controls + subsystems.W_instruments + ...
                subsystems.W_hydraulics + subsystems.W_electrical + subsystems.W_avionics + ...
                subsystems.W_furnishings + subsystems.W_AC + subsystems.W_handling_gear;
        end

        function W_lg = landinggear(K_cb, K_tpg, W_l, N_l, L_m, N_nw, L_n)
            W_main = K_cb*K_tpg*(W_l*N_l)^0.25*L_m^0.973;
            W_nose = (W_l*N_l)^0.290*L_n^0.5*N_nw^0.525;
            W_lg   = W_main + W_nose;
        end

        function W_eng_sys = engine_systems_weights(N_en, T, N_z, W_en, D_e, L_sh, L_ec, T_e)
            W_mounts  = 0.013*N_en^0.795*T^0.579*N_z;
            W_section = 0.01*W_en^0.717*N_en*N_z;
            W_cooling = 4.55*D_e*L_sh*N_en;
            W_oil     = 37.82*N_en^1.008*L_ec^0.222;
            W_start   = 0.025*T_e^0.760*N_en^0.72;
            W_eng_sys = W_mounts + W_section + W_cooling + W_oil + W_start;
        end

    end

end
