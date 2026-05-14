classdef GeometryLevel2
     %F16GEOMETRYSTUFF Summary of this class goes here
     %   Detailed explanation goes here

     properties
          % Organize by physical object; separate into tail (horizontal,
          % vertical), fuselage, etc?
          % I should definitely use structs for this. Organize into wings,
          % tails, fuselage.
     end

     methods (Static)

          % Add functions for estimating control surface sizing

           % Estimate the wetted area of the aircraft
          function [S_wet, c, d] = get_design_S_wet(aircraft_type, W_TO)
               % Source: Airplane Design, vol 1, Roskam, table 3.5
               if (aircraft_type == "Homebuilt")
                    c = 1.2362;
                    d = 0.4319;
               elseif (aircraft_type == "single engine prop")
                    c = 1.0892;
                    d = 0.5147;
               elseif (aircraft_type == "twin engine prop")
                    c = 0.8635;
                    d = 0.5632;
               elseif (aircraft_type == "agricultural")
                    c = 1.0447;
                    d = 0.5326;
               elseif (aircraft_type == "business jet")
                    c = 0.2263;
                    d = 0.6977;
               elseif (aircraft_type == "Regional turboprop")
                    c = -0.0866;
                    d = 0.8099;
               elseif (aircraft_type == "transport jet")
                    c = 0.0199;
                    d = 0.7351;
               elseif (aircraft_type == "Military trainer") % Clean wet
                    c = 0.8565;
                    d = 0.5423;
               elseif (aircraft_type == "fighter") % Clean wet
                    c = -0.1289; % Coefficient for fighter aircraft, given for S_wet equation, provided by Roskam's Aircraft Design Volume 1 (1985), Table 3.5.
                    d = 0.7506; % Coefficient for fighter aicraft, given for S_wet equation, provided by Roskam's Aircraf Design Volume 1 (1985), Table 3.5.
               elseif (aircraft_type == "Military patrol") || (aircraft_type == "Military bomber") || (aircraft_type == "Military transport")
                    c = 0.1628;
                    d = 0.7316;
               elseif (aircraft_type == "flying boat") || (aircraft_type == "amphibious") || (aircraft_type == "float")
                    c = 0.6295;
                    d = 0.6708;
               elseif (aircraft_type == "Supersonic cruise")
                    c = -1.1868;
                    d = 0.9609;
               else
                    error("Couldn't identify aircraft type.")
               end
               S_wet = 10^(c) * W_TO^(d); % ft^2
               % (Aircraft Design, vol 1, Roskam, eq 3.22) 
          end

          % Estimate exposed surface area (lifting surface)
          % Source: Brandt, "F16A", "Geom" sheet, cell H7.
          function output = get_S_exposed_wing(geometry_obj, tip_length, exposed_rc, exposed_halfspan)
               output = exposed_halfspan*(exposed_rc + tip_length);
          end

          % Estimate exposed wetted areas (lifting surfaces) (Wrapper)
          function S_wet_wing = get_S_wet_wing(geometry_obj, S_exposed, tc)
               if tc <= 0.05
                    S_wet_wing = geometry_obj.compute_S_wet_wing_lowtc(S_exposed);
               elseif tc > 0.05
                    S_wet_wing = geometry_obj.compute_S_wet_wing_hightc(S_exposed, tc);
               end
          end

          % Estimate wetted area (body)
          % "Body" = "fuselage + nose cone + whatever isn't the wings from
          % a silouetted side-view"
          % "Fuselage" = "the fuselage"
          function output = compute_S_wet_body(A_top, A_side)
               output = 3.4*(A_top + A_side)/2; % Raymer, 6th ed, eq 7.13
          end
     end

     methods (Access = private)

          % Compute S_wet for wings with low tc
          function output = compute_S_wet_wing_lowtc(geometry_obj, S_exposed)
               output = 2.003*S_exposed; % Raymer, 6th ed, eq 7.11
          end

          % Compute S_wet for wings with high tc
          function output = compute_S_wet_wing_hightc(geometry_obj, S_exposed, tc)
               output = S_exposed*(1.977 + 0.52*tc);
          end
     end
end