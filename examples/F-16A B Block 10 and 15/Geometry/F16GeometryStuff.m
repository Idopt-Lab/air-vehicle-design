classdef F16GeometryStuff < GeometryEstModel
     %F16GEOMETRYSTUFF Summary of this class goes here
     %   Detailed explanation goes here

     properties
          % Organize by physical object; separate into tail (horizontal,
          % vertical), fuselage, etc?
          % I should definitely use structs for this. Organize into wings,
          % tails, fuselage.
          S_wet
          S_HT
          S_VT
          L_VT
          L_HT
          c_VT
          c_HT
          S_ref
          L_fus
          MeanGeometricChord
     end

     methods
          % Estimate the wetted area of the aircraft
          function S_wet = get_S_wet(obj, W_TO)
               c = -0.1289; % Coefficient for fighter aircraft, given for S_wetrest equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
               d = 0.7506; % Coefficient for fighter aicraft, given for S_wetrest equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               S_wet = 10^(c) * W_TO^(d); % ft^2
          end

          % Size the tail
          function [S_HT, S_VT] = size_tail(obj, design, W_TO, S_ref)
               [S_HT, S_VT] = Tail_Sizing_IV(obj, design.geom.wings.VerticalTail.c_VT, design.geom.wings.HorizontalTail.c_HT, design.geom.wings.Main.Spanft, S_ref, design.geom.fuselage.Fuselage.Lengthft, design.geom.wings.Main.MeanGeometricChord);
          end
     end

     methods (Access = private)

          % Size the tail
          function [S_HT, S_VT] = Tail_Sizing_IV(obj, c_VT, c_HT, b_W, S_ref, L_fus, Cbar_W)

               % NOTE: S_REF IS USED BUT ITS SUPPOSED TO BE S_REF OF THE
               % MAIN WINGS
               % Assuming tail located 90% down fuselage
               L_VT = L_fus*0.8;
               L_HT = L_fus*0.8; % Allow operator to adjust this, later.

               S_VT = c_VT*b_W*S_ref/L_VT; % eq 6.28, 2nd edition

               S_HT = c_HT*Cbar_W*S_ref/L_HT; % eq 6.29, 2nd edition

          end
     end
end