classdef F16GeometryStuff < GeometryEstModel
     %F16GEOMETRYSTUFF Summary of this class goes here
     %   Detailed explanation goes here

     properties

     end

     methods
          % Estimate the wetted area of the aircraft
          function output = get_S_wet(obj, design)
               output = calc_S_wet_III(obj, design.WeightResults.W_TO);
          end

          % Size the tail
          function [S_ht, S_vt] = size_tail(obj, design)
               S_wet = get_S_wet(obj, design);
               [S_ht, S_vt] = Tail_Sizing_IV(obj, design.geom.wings.VerticalTail("c_VT"), design.geom.wings.HorizontalTail("c_HT"), design.geom.wings.Main("Span (ft)"), S_wet, design.geom.fuselage.Fuselage("Length (ft)"), design.geom.wings.Main("Mean geometric chord"));
          end
     end

     methods (Access = private)

          % Size the tail
          function [S_ht, S_vt] = Tail_Sizing_IV(obj, c_VT, c_HT, b_W, S_W, L_fus, Cbar_W)

               % Assuming tail located 90% down fuselage
               L_VT = L_fus*0.8;
               L_HT = L_fus*0.8; % Allow operator to adjust this, later.

               S_vt = c_VT*b_W*S_W/L_VT; % eq 6.28, 2nd edition

               S_ht = c_HT*Cbar_W*S_W/L_HT; % eq 6.29, 2nd edition

          end

          % Estimate wetted area of the design
          function S_wet = calc_S_wet_III(obj, W_TO)
               %% ----------------------------------------------------------------------
               % Estimate wetted areas
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               S_wet = 10^(c) * W_TO^(d); % ft^2
          end

     end
end