classdef F16WeightEstLevel4 < WeightEstModel
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
          MTOW
          wings
          tail
          subsystems
          engine
          landinggear
          eps % Error tolerance
     end

     methods

          % CALL THIS TO ACTUALLY ESTIMATE THE DESIGN WEIGHT
          function [MTOW] = estimate_design_weight(weight_obj, mission_obj, design)
               actually_estimate_weight(weight_obj, design)
          end

          % Size the tail (probably can go with some geometry class)
          function size_tail(weight_obj, design)
               [design.geom.wings.VerticalTail("c_VT"), design.geom.wings.HorizontalTail("c_HT")] = Tail_Sizing(design.geom.wings.VerticalTail("c_VT"), design.geom.wings.HorizontalTail("c_HT"), design.geom.wings.Main("Span (ft)"), design.geom.wings.Main("Planform area (ft^2)"), design.geom.fuselage.Total("Length (ft)"), design.geom.wings.Main("Mean geometric chord"))

          end

          % Estimate subsystem weight
          function output = get_subsystem_weight(weight_obj, mission_obj, propulsion_obj, design)
               % Need W_TO
               design.PropulsionResults = propulsion_obj.get_propulsion_stats(weight_obj, mission_obj, design);
               design.WeightResults.subsystems = subsystem_weight_IV(weight_obj, design.weights, design.WeightResults.W_TO, design.PropulsionResults.T_cruise, design.PropulsionResults.W);
          end

          % Estimate engine weight
          function output = get_engine_weight(weight_obj, propulsion_obj, mission_obj, design)
               design.WeightResults = propulsion_obj.get_propulsion_stats(weight_obj, mission_obj, design);
               design.WeightResults.eng_weight = weight_obj.compute_engine_installed_weight(design.WeightResults.T_cruise);
               design.WeightResults.eng_weight.W_engine_installed = 1.3*design.WeightResults.eng_weight.W_total;
          end

          % Estimate OEW
          function output = get_OEW(weight_obj, propulsion_obj, mission_obj, design)
               design.geom.S_wet = compute_S_wet(weight_obj, design.WeightResults.W_TO);
               design.WeightResults.OEW = compute_OEW_IV(weight_obj, design.WeightResults.W_TO, design.geom.wings.Main("Planform area (ft^2)"), design.geom.wings.HorizontalTail("Planform area (ft^2)"), design.geom.wings.VerticalTail("Planform area (ft^2)"), design.geom.S_wet, design.PropulsionResults.T_cruise, design.weights, design.geom.wings.HorizontalTail("c_HT"), design.geom.wings.VerticalTail("c_VT"), design.WeightResults.eng_weight.W_engine_installed);
          end


     end


     %% ------------------------------------------------------------


     methods (Access = private)

          function output = compute_engine_installed_weight(weight_obj, Thrust)

               eng_weight.W_dry = 0.521*Thrust^0.9; % eq 7.13
               eng_weight.W_oil = 0.082*Thrust^0.65; % eq 7.14
               eng_weight.W_rev = 0.034*Thrust; % eq 7.15
               eng_weight.W_control = 0.26*Thrust^0.5; % eq 7.16
               eng_weight.W_start = 9.33*(eng_weight.W_dry/1000)^1.078; % eq 7.17 (7.18?) (Technically Roskam)

               eng_weight.W_total = eng_weight.W_dry + eng_weight.W_oil + eng_weight.W_rev + eng_weight.W_control + eng_weight.W_start;
               output = eng_weight;
          end

          function output = compute_S_wet(weight_obj, W_TO)
               %% ----------------------------------------------------------------------
               % Estimate wetted areas
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               S_wet = 10^(c) * W_TO^(d); % ft^2
               output = S_wet;
          end

          function output = actually_estimate_weight(weight_obj, design)

               S_ref = W_TO / W_S;
               total_fuel_used = 0;

               %% ----------------------------------------------------------------------
               % Size the tail
               % [S_VT, S_HT] = Tail_Sizing(c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W);

               %% ----------------------------------------------------------------------
               % Get thrust at takeoff
               T0 = T_W*W_TO; % Fidelity III

               % [enginestats] = propulsion_est_IV(T0, missiondata.Dash("Mach number"), BPR);

               % Compute empty weight
               W_engine_installed = 1.3*Engine_Sizing(T0); % Installed engine weight (lbf) (table 15.2, Raymer, 6th ed)
               [empty_weight] = Compute_OEW_IV(W_TO, S_ref, S_HT, S_VT, S_wet, T0, DesignTable_weight, c_HT, c_VT, W_engine_installed);

               % OEW - update new OEW fraction
               empty_weight_fraction = empty_weight/W_TO;

               % W_TO_new = W_fixed / (1 - fuel_fraction - empty_weight_fraction);
               W_TO_new = total_fuel_used + W_fixed + empty_weight;

               difference = W_TO_new - W_TO;
               percent_diff = 100 * difference / W_TO;


          end

          % Get OEW
          function output = compute_OEW_IV(weight_obj, W_TO, S_ref, S_HT, S_VT, S_wet, T0, DesignTable_weight, c_HT, c_VT, W_engine_installed)
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
               OEW.W_Wing = wing_weight_IV(W_TO, DesignTable_weight{"Nz",2}, S_ref, DesignTable_weight{"AR", 2}, DesignTable_weight{"t/c",2}, DesignTable_weight{"lambda_w",2}, DesignTable_weight{"Lambda qc",2}, DesignTable_weight{"Scsw",2}, DesignTable_weight{"Kdw",2}, DesignTable_weight{"Kvs",2});
               OEW.W_tail = tail_weight_IV(DesignTable_weight{"Fw",2}, DesignTable_weight{"Bh",2}, W_TO, DesignTable_weight{"Nz",2}, S_HT, DesignTable_weight{"Krht",2}, DesignTable_weight{"Ht",2}, DesignTable_weight{"Hv",2}, S_VT, DesignTable_weight{"M",2}, DesignTable_weight{"Lt",2}, DesignTable_weight{"Sr",2}, DesignTable_weight{"Arv",2}, DesignTable_weight{"lambda_vt",2}, DesignTable_weight{"Lambda qc",2});
               OEW.W_fuselage = fuselage_weight_IV(DesignTable_weight{"Kdwf",2}, W_TO, DesignTable_weight{"Nz",2}, DesignTable_weight{"L",2}, DesignTable_weight{"D",2}, DesignTable_weight{"W",2});
               OEW.W_subsystems = subsystem_weight_IV(weight_obj, DesignTable_weight, W_TO, T0, W_engine_installed);
               % W_engine_installed = 1.3*Engine_Sizing(T0);

               % OEW = W_Wing + W_tail + W_fuselage + W_subsystems + W_extra; % sum the weights
               OEW.total = OEW.W_Wing + OEW.W_tail + OEW.W_fuselage + OEW.W_subsystems.total;
               output = OEW;
          end


          % Estimate wing weight
          function [W_wing] = wing_weight_IV(weight_obj, W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_qc, S_csw, K_dw, K_vs)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               % W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);

               W_wing = 0.0103*K_dw*K_vs*(W_dg*N_z)^(0.5)*S_w^(0.622)*AR^(0.785)*(tc_root) * (1+lambda)^(0.05)*cos(Lambda_qc)^(-1.0)*S_csw^(0.04); % eq 15.1

          end

          % Estimate tail weight
          function [W_tail] = tail_weight_IV(weight_obj, F_w, B_h, W_dg, N_z, S_ht, K_rht, H_t, H_v, S_vt, M, L_t, S_r, A_vt, lambda, Lambda_VT)
               %UNTITLED Summary of this function goes here
               %   Detailed explanation goes here

               W_HT = 3.316*(1 + F_w/B_h)^(-2.0) * ((W_dg * N_z)/(1000))^(0.260) * S_ht^(0.806); % eq 15.2, 6th edition

               W_VT = 0.452*K_rht*(1 + H_t/H_v)^(0.5) * (W_dg*N_z)^(0.488)*S_vt^(0.718)*M^(0.341) * L_t^(-1.0)*(1+S_r/S_vt)^(0.348)*A_vt^(0.223) * (1+lambda)^(0.25)*cos(Lambda_VT*pi/180)^(-0.323); % eq 15.3, 6th edition

               W_tail = W_HT + W_VT;

          end

          % Size the tail
          function [S_VT, S_HT] = Tail_Sizing(c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W)



          end




          % Compute subsystem weight
          function [output] = subsystem_weight_IV(weight_obj, DesignTable_weight, W_TO, T0, W_engine_installed)
               % THIS CALCULATES THE TOTAL WEIGHT OF ALL SUBSYSTEMS
               % Need to extract required information simply without spaghettifying the code.

               subsystems.W_landinggear = landinggear(DesignTable_weight{"Kcb",2}, DesignTable_weight{"Ktpg",2}, DesignTable_weight{"Wl",2}, DesignTable_weight{"Nl",2}, DesignTable_weight{"Lm",2}, DesignTable_weight{"Nnw",2}, DesignTable_weight{"Ln",2});

               subsystems.W_engine_systems = engine_systems_weights(DesignTable_weight{"Nen",2}, T0, DesignTable_weight{"Nz",2}, W_engine_installed, DesignTable_weight{"De",2}, DesignTable_weight{"Lsh",2}, DesignTable_weight{"Lec",2}, T0);

               subsystems.W_firewall = 1.13*DesignTable_weight{"Sfw",2}; % eq 15.8, 6th ed

               subsystems.W_air_induction_system = 13.29 * DesignTable_weight{"Kvg",2} *DesignTable_weight{"Ld",2}^(0.643) * DesignTable_weight{"Kd",2}^(0.182) *DesignTable_weight{"Nen",2}^(0.1498) * (DesignTable_weight{"Ls",2}/DesignTable_weight{"Ld",2})^(-0.373) * DesignTable_weight{"De",2};
               % eq 15.10, 6th ed

               subsystems.W_tailpipe = 3.5*DesignTable_weight{"De",2}*DesignTable_weight{"Ltp",2}*DesignTable_weight{"Nen",2};
               % eq 15.11, 6th ed

               subsystems.W_fuelsystem_and_tanks = 7.45*DesignTable_weight{"Vt",2}^(0.47)*(1 + DesignTable_weight{"Vi",2}/DesignTable_weight{"Vt",2})^(-0.095) * (1 + DesignTable_weight{"VP",2}/DesignTable_weight{"Vt",2})*DesignTable_weight{"Nt",2}^(0.066) * DesignTable_weight{"Nen",2}^(0.052) * (T0 *DesignTable_weight{"SFC",2}/1000)^(0.249);
               % eq 15.16, 6th ed

               subsystems.W_flight_controls = 36.28*DesignTable_weight{"M",2}^(0.003) * DesignTable_weight{"Scs",2}^(0.489) * DesignTable_weight{"Ns",2}^(0.484) * DesignTable_weight{"Nc",2}^(0.127);
               % eq 15.17, 6th ed

               subsystems.W_instruments = 8.0 + 36.37*DesignTable_weight{"Nen",2}^(0.676) * DesignTable_weight{"Nt",2}^(0.237) +26.4*(1 + DesignTable_weight{"Nci",2})^(1.356);
               % eq 15.18, 6th ed

               subsystems.W_hydraulics = 37.23 * DesignTable_weight{"Kvsh",2} * DesignTable_weight{"Nu",2}^(0.664);
               % eq 15.19, 6th ed

               subsystems.W_electrical = 172.2 *DesignTable_weight{"Kmc",2} * DesignTable_weight{"Rkva",2}^(0.152) * DesignTable_weight{"Nc",2}^(0.10) * DesignTable_weight{"La",2}^(0.10) * DesignTable_weight{"Ngen",2}^(0.091);
               % eq 15.20, 6th ed

               subsystems.W_avionics = 2.117 * DesignTable_weight{"Wuav",2}^(0.933);
               % eq 15.21, 6th ed

               subsystems.W_furnishings = 217.6 * DesignTable_weight{"Nc",2}; % Include seats
               % eq 15.22, 6th ed

               subsystems.W_AC_and_antiice = 201.6 * ((DesignTable_weight{"Wuav",2} +200 * DesignTable_weight{"Nc",2})/1000)^(0.735);
               % eq 15.23, 6th ed

               subsystems.W_handling_gear = 3.2*10^(-4) * W_TO; % eq 15.24, 6th edition
               % eq 15.24, 6th ed

               subsystems.total = subsystems.W_landinggear + subsystems.W_engine_systems + subsystems.W_firewall + subsystems.W_air_induction_system + subsystems.W_tailpipe + subsystems.W_fuelsystem_and_tanks + subsystems.W_flight_controls + subsystems.W_instruments + subsystems.W_hydraulics + subsystems.W_electrical + subsystems.W_avionics + subsystems.W_furnishings + subsystems.W_AC_and_antiice + subsystems.W_handling_gear;

               output = subsystems;

          end


     end

end