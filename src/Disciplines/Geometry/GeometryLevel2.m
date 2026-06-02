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

          function [L_fuselage, a, c] = get_fus_len(aircraft_type, W_TO)
               if aircraft_type == "sailplane - unpowered"
                    a = 0.86;
                    C = 0.48;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "sailplane - powered"
                    a = 0.71;
                    C = 0.48;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "homebuilt - metal") || (aircraft_type == "homebuilt - wood")
                    a = 3.68;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "homebuilt - composite"
                    a = 3.50;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "general aviation - single engine"
                    a = 4.37;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "general aviation - twin engine"
                    a = 0.86;
                    C = 0.42;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "agricultural aircraft"
                    a = 4.04;
                    C = 0.23;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "twin turboprop"
                    a = 0.37;
                    C = 0.51;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "flying boat"
                    a = 1.05;
                    C = 0.40;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "jet trainer"
                    a = 0.79;
                    C = 0.41;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "Jet fighter") || (aircraft_type == "jet fighter")
                    a = 0.93;
                    C = 0.39;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber")
                    a = 0.23;
                    C = 0.50;
                    L_fuselage = GeometryLevel1.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "jet transport")
                    a = 0.67;
                    C = 0.43;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               else
                    error("Unrecognized aircraft type. Accepted inputs: sailplane - unpowered, sailplane - powered, homebuilt - metal, homebuilt - wood, homebuilt - composite, general aviation - single engine, general aviation - twin engine, agricultural aircraft, twin turboprop, flying boat, jet trainer, jet fighter, military cargo, military bomber, jet transport.") % Include list of acceptable parameters
               end
          end

          % Estimate fuselage length based on historical trend
          function output = compute_fus_len(a, C, W_TO)
               output = a*W_TO^(C); % Raymer, 6th ed, table 6.3
          end

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
          function output = get_S_exposed_wing(tip_length, exposed_rc, exposed_halfspan)
               output = exposed_halfspan*(exposed_rc + tip_length);
          end

          % Estimate exposed wetted areas (lifting surfaces) (Wrapper)
          function S_wet_wing = get_S_wet_wing(S_exposed, tc)
               if tc <= 0.05
                    S_wet_wing = GeometryLevel2.compute_S_wet_wing_lowtc(S_exposed);
               elseif tc > 0.05
                    S_wet_wing = GeometryLevel2.compute_S_wet_wing_hightc(S_exposed, tc);
               end
          end

          % Estimate wetted area (body)
          % "Body" = "fuselage + nose cone + whatever isn't the wings from
          % a silouetted side-view"
          % "Fuselage" = "the fuselage"
          % I think this is better for level 1
          function S_wet_body = compute_S_wet_body(A_top, A_side)
               S_wet_body = 3.4*(A_top + A_side)/2; % Raymer, 6th ed, eq 7.13
          end

          % Compute S_wet for wings with low tc
          function output = compute_S_wet_wing_lowtc(S_exposed)
               output = 2.003*S_exposed; % Raymer, 6th ed, eq 7.11
          end

          % Compute S_wet for wings with high tc
          function output = compute_S_wet_wing_hightc(S_exposed, tc)
               output = S_exposed*(1.977 + 0.52*tc);
          end


          % Estimate tail properties based on historical trend of aircraft
          % types
          % This is probably better for stability and control
          function [c_HT, c_VT] = est_tail_propers(aircraft_type)
               if aircraft_type == "sailplane"
                    c_HT = 0.50;
                    c_VT = 0.02;
               elseif (aircraft_type == "homebuilt")
                    c_HT = 0.50;
                    c_VT = 0.04;
               elseif aircraft_type == "general aviation - single engine"
                    c_HT = 0.70;
                    c_VT = 0.04;
               elseif aircraft_type == "general aviation - twin engine"
                    c_HT = 0.80;
                    c_VT = 0.07;
               elseif aircraft_type == "agricultural"
                    c_HT = 0.50;
                    c_VT = 0.04;
               elseif aircraft_type == "twin turboprop"
                    c_HT = 0.90;
                    c_VT = 0.08;
               elseif aircraft_type == "flying boat"
                    c_HT = 0.70;
                    c_VT = 0.06;
               elseif aircraft_type == "jet trainer"
                    c_HT = 0.70;
                    c_VT = 0.06;
               elseif aircraft_type == "jet fighter"
                    c_HT = 0.40;
                    c_VT = 0.07; % 0.07 - 0.12, longer fuselage -> higher value
               elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber")
                    c_HT = 1.00;
                    c_VT = 0.08;
               elseif (aircraft_type == "jet transport")
                    c_HT = 1.00;
                    c_VT = 0.09;
               else
                    error("Unrecognized aircraft type.") % Include list of acceptable parameters
               end
          end

          % Estimate tail AR and lambda
          function [HT, VT] = tab_tail_AR_lambda(aircraft_type, tail_type)
               if aircraft_type == "fighter"
                    HT.AR = 3;
                    HT.lambda = 0.2;
                    VT.AR = 0.6;
                    VT.lambda = 0.2;
               elseif aircraft_type == "sailplane"
                    HT.AR = 6;
                    HT.lambda = 0.3;
                    VT.AR = 1.5;
                    VT.lambda = 0.4;
               elseif (aircraft_type ~= "fighter") || (aircraft_type ~= "sailplane")
                    HT.AR = 3;
                    HT.lambda = 0.3;
                    VT.AR = 1.3;
                    VT.lambda = 0.3;
               elseif (tail_type == "T-tail")
                    HT.AR = 0;
                    HT.lambda = 0;
                    VT.AR = 0.7;
                    VT.lambda = 0.6;
               else
                    error("Couldn't identify aircraft or tail type.")
               end
          end
     end
end