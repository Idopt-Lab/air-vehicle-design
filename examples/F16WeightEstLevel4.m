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
          function get_engine_weight(weight_obj, design)

          end

     end

     methods (Access = private)
          function [S_VT, S_HT] = Tail_Sizing(c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W)



          end
     end

end