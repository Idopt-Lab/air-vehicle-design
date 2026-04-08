classdef F16WeightEstLevel4 < WeightEstModel
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
          MTOW
          eps % Error tolerance
     end

     methods

          function [MTOW] = compute_MTOW(weight_obj, design)
               S_ref = W_TO / W_S;
               total_fuel_used = 0;

               %% ----------------------------------------------------------------------
               % Size the tail
               [S_VT, S_HT] = Tail_Sizing(c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W);

               %% ----------------------------------------------------------------------
               % Estimate wetted areas
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               S_wet = 10^(c) * W_TO^(d); % ft^2

               %% ----------------------------------------------------------------------
               % Get thrust at takeoff
               T0 = T_W*W_TO; % Fidelity III

               [enginestats] = propulsion_est_IV(T0, missiondata.Dash("Mach number"), BPR);

          end

          % Size the tail
          function size_tail(weight_obj, design)
               [design.geom.wings.VerticalTail("c_VT"), design.geom.wings.HorizontalTail("c_HT")] = Tail_Sizing(design.geom.wings.VerticalTail("c_VT"), design.geom.wings.HorizontalTail("c_HT"), design.geom.wings.Main("Span (ft)"), design.geom.wings.Main("Planform area (ft^2)"), design.geom.fuselage.Total("Length (ft)"), design.geom.wings.Main("Mean geometric chord"))

          end

          % Estimate subsystem weight
          function get_subsystem_weight(weight_obj, design)

          end

          % Estimate engine weight
          function get_engine_weight(weight_obj, mission_obj, design)
               design.PropulsionResults = propulsion_est_IV(design.propulsion.Dry("Thrust (sea level) (lbf)"), mission_obj.missiondata.Dash("Mach number"), design.propulsion.BypassRatio("Bypass Ratio"));
          end

     end

     methods (Access = private)
          function [S_VT, S_HT] = Tail_Sizing(c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W)



          end

          function [enginestats] = propulsion_est_IV(T, M, BPR)
               % Using equations from Raymer 6th edition, chapter 10, p 285, eq 10.4 ->
               % 10.15

               % ARGUMENTS
               % W = Weight (lbf)
               % T = Takeoff thrust (lbf)
               % BPR = Bypass ratio
               % M = Mach number

               % Afterburning engines (imperial units)
               W = @(T, M, BPR) (0.063*T^(1.1)*M^(0.25)*exp(-0.81*BPR)); % Engine weight (lbf) (eq 10.10, 6th ed)
               L = @(T, M) (0.255*T^(0.4)*M^(0.2)); % Engine length (ft) (eq 10.11, 6th ed)
               D = @(T, BPR) (0.024*T^(0.5)*exp(0.04*BPR)); % Engine diameter (ft) (eq 10.12, 6th ed)
               SFC_maxT = @(BPR) (2.1*exp(-0.12*BPR)); % SFC at max thrust (1/hr) (eq 10.13, 6th ed)
               T_cruise = @(T, BPR) (2.4*T^(0.74)*exp(0.023*BPR)); % Cruise thrust (lbf) (eq 10.14, 6th ed)
               SFC_cruise = @(BPR) (1.04*exp(-0.186*BPR)); % SFC at cruise conditions (1/hr) (eq 10.15, 6th ed)

               enginestats.W = W(T, M, BPR);
               enginestats.L = L(T, M);
               enginestats.D = D(T, BPR);
               enginestats.SFC_maxT = SFC_maxT(BPR)*(1/3600);
               enginestats.T_cruise = T_cruise(T, BPR);
               enginestats.SFC_cruise = SFC_cruise(BPR)*(1/3600);

          end


     end

end