classdef F16WeightEstLevel3 < WeightEstModel
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
          MTOW
          OEW
          wings
          tail
          subsystems
          engine
          landinggear
          W_TO_guess = 45000
          W_TO
          W_fixed
          total_fuel_used
          fuel_fraction
          weight_coefficients
          eps % Error tolerance
     end

     methods
          % Constructor
          function obj = F16WeightEstLevel3(design)
               obj.W_fixed = design.weights.Weights.Fixedlbf;
               obj.weight_coefficients = design.weights.Coefficients;
          end

          % Estimate subsystem weight
          function output = get_subsystem_weight(weight_obj, mission_obj, propulsion_obj, design)
               % Need W_TO
               propulsion_obj.get_propulsion_stats(mission_obj, design);
               weight_obj.subsystems = weight_obj.subsystem_weight_III(design.weights, weight_obj.W_TO, propulsion_obj.T0, weight_obj.engine.W_installed);
          end

          % Estimate engine weight (installed)
          function output = get_engine_weight(weight_obj, propulsion_obj, mission_obj, design)
               propulsion_obj.enginestats = propulsion_obj.get_propulsion_stats(mission_obj, design);
               weight_obj.engine = weight_obj.compute_engine_installed_weight(propulsion_obj.T0);
               weight_obj.engine.installed = 1.3*weight_obj.engine.W_total;
               output = weight_obj.engine.W_total;
          end

          % Estimate OEW
          function output = get_OEW(weight_obj, propulsion_obj, mission_obj, design, geometry_obj, W_TO)
               propulsion_obj.enginestats = propulsion_obj.get_propulsion_stats(mission_obj, design);
               get_engine_weight(weight_obj, propulsion_obj, mission_obj, design);
               weight_obj.OEW = compute_OEW_III(weight_obj, W_TO, geometry_obj.mainwings.S_ref, geometry_obj.HT.S_ref, geometry_obj.VT.S_ref, geometry_obj.design.S_wet, propulsion_obj.T0, design.weights, design.geom.wings.HorizontalTail.c_HT, design.geom.wings.VerticalTail.c_VT, weight_obj.engine.installed); % Really this gets the empty weight of the design (wings, fuselage, subsystems)
               output = weight_obj.OEW;
          end


          % Mission Analysis functions (for fuel estimation)
          function [WF] = compute_weightfraction(obj, TSFC, R, Vend, LD_ratio)
               WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
          end


     end


     %% ------------------------------------------------------------


     methods (Access = private)


          % Get OEW
          function OEW = compute_OEW_III(weight_obj, W_TO, S_ref, S_HT, S_VT, S_wet, T0, DesignTable_weight, c_HT, c_VT, W_engine_installed)
               %COMPUTE_OEW Summary of this function goes here
               %   Detailed explanation goes here
               % Ref area should be EXPOSED planform area!
               % W_Wing = WingDensity * S_ref; % Replace with new wing weight model (accepts arguments of AR and e and other stuff)
               % N_z = 9.0; % Ultimate load factor
               % tc_root = 0.4; % Thickness-to-chord ratio, root
               % Lambda_qc = 0.2275; % taper ratio of quarter chord
               % S_csw = 150; % Surface area of control surfaces (FIGURE THIS OUT <<<<<<<<<<<<<<<<<<<<<)

               % Using Raymer, 6th edition, section 15.3.1 equations for component
               % weights.

               % Sub-functions for handling component weights. Estimates.
               % Equations: Raymer, 6th edition, section 15.3.1. Fighter/Attack jet.
               OEW.W_Wing = weight_obj.wing_weight_III(W_TO, DesignTable_weight.Coefficients.Nz, S_ref, DesignTable_weight.Coefficients.AR, DesignTable_weight.Coefficients.tc, DesignTable_weight.Coefficients.lambda_w, DesignTable_weight.Coefficients.LambdaQc, DesignTable_weight.Coefficients.Scsw, DesignTable_weight.Coefficients.Kdw, DesignTable_weight.Coefficients.Kvs);
               OEW.W_tail = weight_obj.tail_weight_III(DesignTable_weight.Coefficients.Fw, DesignTable_weight.Coefficients.Bh, W_TO, DesignTable_weight.Coefficients.Nz, S_HT, DesignTable_weight.Coefficients.Krht, DesignTable_weight.Coefficients.Ht, DesignTable_weight.Coefficients.Hv, S_VT, DesignTable_weight.Coefficients.M, DesignTable_weight.Coefficients.Lt, DesignTable_weight.Coefficients.Sr, DesignTable_weight.Coefficients.Arv, DesignTable_weight.Coefficients.lambda_vt, DesignTable_weight.Coefficients.LambdaQc);
               OEW.W_fuselage = weight_obj.fuselage_weight_III(DesignTable_weight.Coefficients.Kdwf, W_TO, DesignTable_weight.Coefficients.Nz, DesignTable_weight.Coefficients.L, DesignTable_weight.Coefficients.D, DesignTable_weight.Coefficients.W);
               OEW.W_subsystems = weight_obj.subsystem_weight_III(DesignTable_weight, W_TO, T0, W_engine_installed);
               % weight_obj.engine.W_engine_installed = 1.3*Engine_Sizing(T0);

               % OEW = W_Wing + W_tail + W_fuselage + W_subsystems + W_extra; % sum the weights
               OEW.total = OEW.W_Wing + OEW.W_tail + OEW.W_fuselage + OEW.W_subsystems.total;
          end

          function eng_weight = compute_engine_installed_weight(weight_obj, Thrust)

               eng_weight.W_dry = 0.521*Thrust^0.9; % eq 7.13
               eng_weight.W_oil = 0.082*Thrust^0.65; % eq 7.14
               eng_weight.W_rev = 0.034*Thrust; % eq 7.15
               eng_weight.W_control = 0.26*Thrust^0.5; % eq 7.16
               eng_weight.W_start = 9.33*(eng_weight.W_dry/1000)^1.078; % eq 7.17 (7.18?) (Technically Roskam)

               eng_weight.W_total = eng_weight.W_dry + eng_weight.W_oil + eng_weight.W_rev + eng_weight.W_control + eng_weight.W_start;
               eng_weight.W_installed = 1.3*eng_weight.W_total;
          end

          function [W_fuselage] = fuselage_weight_III(weight_obj, K_dwf, W_dg, N_z, L, D, W)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               % W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);

               W_fuselage = 0.499 * K_dwf * W_dg^(0.35) * N_z^(0.25) * L^(0.5) * D^(0.849) * W^(0.685);

          end


          % Estimate wing weight
          function [W_wing] = wing_weight_III(weight_obj, W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_qc, S_csw, K_dw, K_vs)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               % W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);

               W_wing = 0.0103*K_dw*K_vs*(W_dg*N_z)^(0.5)*S_w^(0.622)*AR^(0.785)*(tc_root) * (1+lambda)^(0.05)*cos(Lambda_qc)^(-1.0)*S_csw^(0.04); % eq 15.1

          end

          % Estimate tail weight
          function [W_tail] = tail_weight_III(weight_obj, F_w, B_h, W_dg, N_z, S_ht, K_rht, H_t, H_v, S_vt, M, L_t, S_r, A_vt, lambda, Lambda_VT)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               W_HT = 3.316*(1 + F_w/B_h)^(-2.0) * ((W_dg * N_z)/(1000))^(0.260) * S_ht^(0.806); % eq 15.2, 6th edition

               W_VT = 0.452*K_rht*(1 + H_t/H_v)^(0.5) * (W_dg*N_z)^(0.488)*S_vt^(0.718)*M^(0.341) * L_t^(-1.0)*(1+S_r/S_vt)^(0.348)*A_vt^(0.223) * (1+lambda)^(0.25)*cos(Lambda_VT*pi/180)^(-0.323); % eq 15.3, 6th edition

               W_tail = W_HT + W_VT;

          end




          % Compute subsystem weight
          function subsystems = subsystem_weight_III(weight_obj, DesignTable_weight, W_TO, T0, W_engine_installed)
               % THIS CALCULATES THE TOTAL WEIGHT OF ALL SUBSYSTEMS
               % Need to extract required information simply without spaghettifying the code.

               subsystems.W_landinggear = landinggear(DesignTable_weight.Coefficients.Kcb, DesignTable_weight.Coefficients.Ktpg, DesignTable_weight.Coefficients.Wl, DesignTable_weight.Coefficients.Nl, DesignTable_weight.Coefficients.Lm, DesignTable_weight.Coefficients.Nnw, DesignTable_weight.Coefficients.Ln);

               subsystems.W_engine_systems = engine_systems_weights(DesignTable_weight.Coefficients.Nen, T0, DesignTable_weight.Coefficients.Nz, W_engine_installed, DesignTable_weight.Coefficients.De, DesignTable_weight.Coefficients.Lsh, DesignTable_weight.Coefficients.Lec, T0);

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


     end

end