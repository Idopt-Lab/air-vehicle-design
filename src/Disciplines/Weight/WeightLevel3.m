classdef WeightLevel3
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
     end

     methods (Static)


          % Mission Analysis functions (for fuel estimation)
          function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


          % Compute all-else empty weight
          function output = compute_W_all_else_empty(W_TO, aircraft_type)
               if (aircraft_type == "Jet fighter")
                    W_all_else_empty = 0.17*W_TO;
               elseif (aircraft_type == "Transport") || (aircraft_type == "Bomber")
                    W_all_else_empty = 0.17*W_TO;
               elseif (aircraft_type == "General aviation")
                    W_all_else_empty = 0.1*W_TO;
               else
                    error("Couldn't identify aircraft type (fighter, transport, bomber, general aviation).")
               end
               output = W_all_else_empty;
          end

          function eng_weight = compute_engine_installed_weight(Thrust)

               eng_weight.W_dry = 0.521*Thrust^0.9; % eq 7.13
               eng_weight.W_oil = 0.082*Thrust^0.65; % eq 7.14
               eng_weight.W_rev = 0.034*Thrust; % eq 7.15
               eng_weight.W_control = 0.26*Thrust^0.5; % eq 7.16
               eng_weight.W_start = 9.33*(eng_weight.W_dry/1000)^1.078; % eq 7.17 (7.18?) (Technically Roskam)

               eng_weight.W_total = eng_weight.W_dry + eng_weight.W_oil + eng_weight.W_rev + eng_weight.W_control + eng_weight.W_start;
               eng_weight.W_installed = 1.3*eng_weight.W_total;
          end

          function [W_fuselage] = fuselage_weight_III(K_dwf, W_dg, N_z, L, D, W)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here
               % W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);
               W_fuselage = 0.499 * K_dwf * W_dg^(0.35) * N_z^(0.25) * L^(0.5) * D^(0.849) * W^(0.685);
          end


          % Estimate wing weight
          function [W_wing] = wing_weight_III(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_qc, S_csw, K_dw, K_vs)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here
               % W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);
               % W_wing = 0.0103*K_dw*K_vs*(W_dg*N_z)^(0.5)*(S_w^(0.622))*AR^(0.785)*(tc_root) * (1+lambda)^(0.05)*cosd(Lambda_qc)^(-1.0)*S_csw^(0.04); % eq 15.1
               W_wing = 3.08*( ( (K_vs*N_z*W_dg) / (tc_root) )*( (tand(Lambda_qc) - ( 2*(1 - lambda))/(AR*(1 + lambda)) )^2 + 1.0)*10^(-6) )^(0.593)*((1 + lambda)*AR)^(0.89)*(S_w)^0.741; % Nicolai Eq. 20.1a
          end

          % Estimate tail weight
          function [W_HT, W_VT] = tail_weight_III(F_w, B_h, W_dg, N_z, S_ht, K_rht, H_t, H_v, S_vt, M, L_t, S_r, A_vt, lambda_vt, Lambda_VT, Ht_Hv)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               % Horizontal tail:
               W_HT = 3.316*(1 + F_w/B_h)^(-2.0) * ((W_dg * N_z)/(1000))^(0.260) * S_ht^(0.806); % eq 15.2, 6th edition
               
               % if (isnan(H_t/H_v)==true)
               %      W_VT = 0.452*K_rht*(1 + 0)^(0.5) * (W_dg*N_z)^(0.488)*S_vt^(0.718)*M^(0.341) * L_t^(-1.0)*(1+S_r/S_vt)^(0.348)*A_vt^(0.223) * (1+lambda)^(0.25)*cos(Lambda_VT*pi/180)^(-0.323); % eq 15.3, 6th edition
               % elseif (isnan(H_t/H_v)==false)
               %      W_VT = 0.452*K_rht*(1 + H_t/H_v)^(0.5) * (W_dg*N_z)^(0.488)*S_vt^(0.718)*M^(0.341) * L_t^(-1.0)*(1+S_r/S_vt)^(0.348)*A_vt^(0.223) * (1+lambda)^(0.25)*cos(Lambda_VT*pi/180)^(-0.323); % eq 15.3, 6th edition
               % else
               %      error("Error handler.")
               % end

               % Recompute control surface area!
               % Vertical tail:
               W_VT = 0.452*K_rht*(1 + H_t/H_v)^(0.5) * (W_dg*N_z)^(0.488)*S_vt^(0.718)*M^(0.341) * L_t^(-1.0)*(1+S_r/S_vt)^(0.348)*A_vt^(0.223) * (1+lambda_vt)^(0.25)*cosd(Lambda_VT)^(-0.323); % eq 15.3, 6th edition

               % W_tail = W_HT + W_VT;

          end


          % Compute subsystem weight
          function subsystems = subsystem_weight_III(DesignTable_weight, W_TO, T0, W_engine_installed)
               % THIS CALCULATES THE TOTAL WEIGHT OF ALL SUBSYSTEMS
               % Need to extract required information simply without spaghettifying the code.

               subsystems.W_landinggear = WeightLevel3.landinggear(DesignTable_weight.Coefficients.Kcb, DesignTable_weight.Coefficients.Ktpg, DesignTable_weight.Coefficients.Wl, DesignTable_weight.Coefficients.Nl, DesignTable_weight.Coefficients.Lm, DesignTable_weight.Coefficients.Nnw, DesignTable_weight.Coefficients.Ln);

               subsystems.W_engine_systems = WeightLevel3.engine_systems_weights(DesignTable_weight.Coefficients.Nen, T0, DesignTable_weight.Coefficients.Nz, W_engine_installed, DesignTable_weight.Coefficients.De, DesignTable_weight.Coefficients.Lsh, DesignTable_weight.Coefficients.Lec, T0);

               subsystems.W_firewall = 1.13*DesignTable_weight.Coefficients.Sfw; % eq 15.8, 6th ed

               subsystems.W_air_induction_system = 13.29 * DesignTable_weight.Coefficients.Kvg *DesignTable_weight.Coefficients.Ld^(0.643) * DesignTable_weight.Coefficients.Kd^(0.182) *DesignTable_weight.Coefficients.Nen^(0.1498) * (DesignTable_weight.Coefficients.Ls/DesignTable_weight.Coefficients.Ld)^(-0.373) * DesignTable_weight.Coefficients.De;
               % eq 15.10, 6th ed

               subsystems.W_tailpipe = 3.5*DesignTable_weight.Coefficients.De*DesignTable_weight.Coefficients.Ltp*DesignTable_weight.Coefficients.Nen;
               % eq 15.11, 6th ed

               subsystems.W_fuelsystem_and_tanks = 7.45*DesignTable_weight.Coefficients.Vt^(0.47)*(1 + DesignTable_weight.Coefficients.Vi/DesignTable_weight.Coefficients.Vt)^(-0.095) * (1 + DesignTable_weight.Coefficients.VP/DesignTable_weight.Coefficients.Vt)*DesignTable_weight.Coefficients.Nt^(0.066) * DesignTable_weight.Coefficients.Nen^(0.052) * (T0 *DesignTable_weight.Coefficients.SFC/1000)^(0.249);
               % eq 15.16, 6th ed

               subsystems.W_flight_controls = 36.28*DesignTable_weight.Coefficients.M^(0.003) * DesignTable_weight.Coefficients.Scs^(0.489) * DesignTable_weight.Coefficients.Ns^(0.484) * DesignTable_weight.Coefficients.Nc^(0.127);
               % eq 15.17, 6th ed

               subsystems.W_instruments = 8.0 + 36.37*DesignTable_weight.Coefficients.Nen^(0.676) * DesignTable_weight.Coefficients.Nt^(0.237) +26.4*(1 + DesignTable_weight.Coefficients.Nci)^(1.356);
               % eq 15.18, 6th ed

               subsystems.W_hydraulics = 37.23 * DesignTable_weight.Coefficients.Kvsh * DesignTable_weight.Coefficients.Nu^(0.664);
               % eq 15.19, 6th ed

               subsystems.W_electrical = 172.2 *DesignTable_weight.Coefficients.Kmc * DesignTable_weight.Coefficients.Rkva^(0.152) * DesignTable_weight.Coefficients.Nc^(0.10) * DesignTable_weight.Coefficients.La^(0.10) * DesignTable_weight.Coefficients.Ngen^(0.091);
               % eq 15.20, 6th ed

               subsystems.W_avionics = 2.117 * DesignTable_weight.Coefficients.Wuav^(0.933);
               % eq 15.21, 6th ed

               subsystems.W_furnishings = 217.6 * DesignTable_weight.Coefficients.Nc; % Include seats
               % eq 15.22, 6th ed

               subsystems.W_AC_and_antiice = 201.6 * ((DesignTable_weight.Coefficients.Wuav +200 * DesignTable_weight.Coefficients.Nc)/1000)^(0.735);
               % eq 15.23, 6th ed

               subsystems.W_handling_gear = 3.2*10^(-4) * W_TO; % eq 15.24, 6th edition
               % eq 15.24, 6th ed

               subsystems.total = subsystems.W_landinggear + subsystems.W_engine_systems + subsystems.W_firewall + subsystems.W_air_induction_system + subsystems.W_tailpipe + subsystems.W_fuelsystem_and_tanks + subsystems.W_flight_controls + subsystems.W_instruments + subsystems.W_hydraulics + subsystems.W_electrical + subsystems.W_avionics + subsystems.W_furnishings + subsystems.W_AC_and_antiice + subsystems.W_handling_gear;
          end

          function [W_landinggear] = landinggear(K_cb, K_tpg, W_l, N_l, L_m, N_nw, L_n)

               W_main_gear = K_cb*K_tpg * (W_l * N_l)^(0.25) * L_m^(0.973); % eq 15.5, 6th ed

               W_nose_gear = (W_l * N_l)^(0.290) * L_n^(0.5) * N_nw^(0.525); % eq 15.6, 6th ed

               W_landinggear = W_main_gear + W_nose_gear;
          end

          function [W_eng_sys] = engine_systems_weights(N_en, T, N_z, W_en, D_e, L_sh, L_ec, T_e)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               W_engine_mounts = 0.013*N_en^(0.795) * T^(0.579) * N_z; % eq 15.7, 6th ed

               W_engine_section = 0.01*W_en^(0.717) * N_en * N_z; % eq 15.9, 6th ed

               W_engine_cooling = 4.55*D_e*L_sh*N_en; % eq 15.12, 6th ed

               W_oil_cooling = 37.82*N_en^(1.008)*L_ec^(0.222); % eq 15.13, 6th ed

               W_starter_pneumatic = 0.025*T_e^(0.760)*N_en^(0.72); % eq 15.15, 6th ed

               W_eng_sys = W_engine_mounts + W_engine_section + W_engine_cooling + W_oil_cooling + W_starter_pneumatic;

          end


     end


     %% ------------------------------------------------------------


     methods (Access = private)


     end

end