classdef WeightLevel4 < WeightsBase
    % Level IV weights: full Raymer Ch 15 component method.
    %
    % Inherits from WeightsBase (not WeightModelLevel3).
    % Uses the same coefficient-table pattern as WeightLevel3 but with
    % Raymer's Eq 15.1–15.24 component weight equations.
    %
    % Usage:
    %   wts   = WeightLevel4(coeff_table, T0, W_eng_installed);
    %   oew   = wts.OEW(31000);

    properties
        coeff           % struct with geometric/loading constants
        T0              % sea-level static thrust (lbf)
        W_eng_installed % installed engine weight (lbf)
    end

    methods
        function obj = WeightLevel4(coeff_table, T0, W_eng_installed)
            obj.coeff           = coeff_table;
            obj.T0              = T0;
            obj.W_eng_installed = W_eng_installed;
        end

        function oew_val = OEW(obj, W_TO)
            c = obj.coeff;
            W_wing  = WeightLevel4.wing_weight_IV(W_TO, c.Nz, c.S_ref, c.AR, ...
                c.tc, c.lambda_w, c.LambdaQc, c.Scsw, c.Kdw, c.Kvs);
            W_tail  = WeightLevel4.tail_weight_IV(c.Fw, c.Bh, W_TO, c.Nz, ...
                c.S_HT, c.Krht, c.Ht, c.Hv, c.S_VT, c.M, c.Lt, c.Sr, ...
                c.Arv, c.lambda_vt, c.LambdaQc);
            W_fus   = WeightLevel4.fuselage_weight_IV(c.Kdwf, W_TO, c.Nz, ...
                c.L, c.D, c.W);
            subs    = WeightLevel4.subsystem_weight_IV(c, W_TO, obj.T0, obj.W_eng_installed);
            oew_val = W_wing + W_tail + W_fus + subs.total;
        end
    end

    methods (Static)

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

        function W_wing = wing_weight_IV(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_qc, S_csw, K_dw, K_vs)
            % Raymer, 6th ed, eq 15.1
            W_wing = 0.0103*K_dw*K_vs*(W_dg*N_z)^0.5*S_w^0.622*AR^0.785 * ...
                tc_root*(1+lambda)^0.05*cosd(Lambda_qc)^(-1.0)*S_csw^0.04;
        end

        function W_tail = tail_weight_IV(F_w, B_h, W_dg, N_z, S_ht, K_rht, H_t, H_v, S_vt, M, L_t, S_r, A_vt, lambda, Lambda_VT)
            W_HT   = 3.316*(1+F_w/B_h)^(-2.0)*((W_dg*N_z)/1000)^0.260*S_ht^0.806;  % eq 15.2
            W_VT   = 0.452*K_rht*(1+H_t/H_v)^0.5*(W_dg*N_z)^0.488*S_vt^0.718*M^0.341 * ...
                L_t^(-1.0)*(1+S_r/S_vt)^0.348*A_vt^0.223*(1+lambda)^0.25*cosd(Lambda_VT)^(-0.323);  % eq 15.3
            W_tail = W_HT + W_VT;
        end

        function W_fus = fuselage_weight_IV(K_dwf, W_dg, N_z, L, D, W)
            W_fus = 0.499*K_dwf*W_dg^0.35*N_z^0.25*L^0.5*D^0.849*W^0.685;
        end

        function subsystems = subsystem_weight_IV(c, W_TO, T0, W_engine_installed)
            % Raymer, 6th ed, eqs 15.5–15.24
            W_main = c.Kcb*c.Ktpg*(c.Wl*c.Nl)^0.25*c.Lm^0.973;
            W_nose = (c.Wl*c.Nl)^0.290*c.Ln^0.5*c.Nnw^0.525;
            subsystems.W_landinggear     = W_main + W_nose;
            subsystems.W_engine_mounts   = 0.013*c.Nen^0.795*T0^0.579*c.Nz;
            subsystems.W_engine_section  = 0.01*W_engine_installed^0.717*c.Nen*c.Nz;
            subsystems.W_engine_cooling  = 4.55*c.De*c.Lsh*c.Nen;
            subsystems.W_oil_cooling     = 37.82*c.Nen^1.008*c.Lec^0.222;
            subsystems.W_starter         = 0.025*T0^0.760*c.Nen^0.72;
            subsystems.W_engine_systems  = subsystems.W_engine_mounts + ...
                subsystems.W_engine_section + subsystems.W_engine_cooling + ...
                subsystems.W_oil_cooling + subsystems.W_starter;
            subsystems.W_firewall        = 1.13*c.Sfw;
            subsystems.W_air_induction   = 13.29*c.Kvg*c.Ld^0.643*c.Kd^0.182*c.Nen^0.1498*(c.Ls/c.Ld)^(-0.373)*c.De;
            subsystems.W_tailpipe        = 3.5*c.De*c.Ltp*c.Nen;
            subsystems.W_fuelsystem      = 7.45*c.Vt^0.47*(1+c.Vi/c.Vt)^(-0.095)*(1+c.VP/c.Vt)*c.Nt^0.066*c.Nen^0.052*(T0*c.SFC/1000)^0.249;
            subsystems.W_flight_controls = 36.28*c.M^0.003*c.Scs^0.489*c.Ns^0.484*c.Nc^0.127;
            subsystems.W_instruments     = 8.0 + 36.37*c.Nen^0.676*c.Nt^0.237 + 26.4*(1+c.Nci)^1.356;
            subsystems.W_hydraulics      = 37.23*c.Kvsh*c.Nu^0.664;
            subsystems.W_electrical      = 172.2*c.Kmc*c.Rkva^0.152*c.Nc^0.10*c.La^0.10*c.Ngen^0.091;
            subsystems.W_avionics        = 2.117*c.Wuav^0.933;
            subsystems.W_furnishings     = 217.6*c.Nc;
            subsystems.W_AC              = 201.6*((c.Wuav+200*c.Nc)/1000)^0.735;
            subsystems.W_handling_gear   = 3.2e-4*W_TO;
            subsystems.total = subsystems.W_landinggear + subsystems.W_engine_systems + ...
                subsystems.W_firewall + subsystems.W_air_induction + subsystems.W_tailpipe + ...
                subsystems.W_fuelsystem + subsystems.W_flight_controls + subsystems.W_instruments + ...
                subsystems.W_hydraulics + subsystems.W_electrical + subsystems.W_avionics + ...
                subsystems.W_furnishings + subsystems.W_AC + subsystems.W_handling_gear;
        end

    end

end
