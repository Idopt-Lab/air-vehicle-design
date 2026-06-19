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

          % Estimate wetted area for planforms
          % Valid for straight tapered planforms (wing, tail, canard, fin,
          % pylons)
          % Source: Airplane Design Vol 2, Roska, eq 12.1
          function output = S_wet_planform(S_exp_plf, tc_r, tc_t, lambda)
               output = 2*S_exp_plf*(1+0.25*tc_r*(1+(tc_r/tc_t)*lambda)/(1+lambda));
          end

          % Estimate planform perimeterr
          % Source: Airplane Design Vol 2, Roskam, eq 12.2
          function output = p_plf(c, tc)
               output = 2*c*(1+0.25*tc);
          end




          % Estimate wetted area for fuselage
          % Valid: fuselages with cylindrical mid-sections
          % Source: Airplane Design Vol 2, Roskam, eq 12.3
          function output = S_wet_fus_cyl(D_f, l_f, lambda_f)
               output = pi*D_f*l_f*(1-2/lambda_f)^(2/3)*(1 + 1/lambda_f^2);
          end

          % For streamlined fueslage without a cylindrical mid-section:
          % Source: Airplane Design Vol 2, Roskam, eq 12.4
          function output = S_wet_fus_stream(D_f, l_f, l_n, lambda_f)
               output = pi*D_f*l_f(0.5 + 0.135*l_n/l_f)^(2/3) *(1.015+0.3/lambda_f^1.5);
          end


          % Wetted areas for externally mounted nacelles

          % Estimate wetted area for fan cowling
          % Source: Airplane Design Vol 2, Roska, eq 12.5
          function output = S_wet_fan_cowl(l_n, D_n, l_1, l_eta, D_hl)
               output = l_n*D_n*(2 + 0.35*l_1/l_eta + 0.81*l_1*D_hl/l_eta * D_n);
          end 

          % Estimate wetted area for gas generator
          % Source: Airplane Design Vol 2, Roskam, eq 12.6
          function output = S_wet_gas_gen(l_g, D_g, D_eg)
               output = pi*l_g*D_g*(1 - (1/3)*(1- D_eg/D_g)*(1 - 0.18*(D_g/l_g)^(5/3)));
          end

          % Estimate wetted area for the plug
          % Source: Airplane design Vol 2, Roskam, eq 12.7
          function output = S_wet_plug(l_p, D_p)
               output = 0.7*pi*l_p*D_p;
          end
          






          % Estimate fuselage finess ratio
          % Source: Airplane Design Vol 2, Roskam, eq 12.4
          function output = lambda_f(D_f, l_f)
               output = D_f/l_f;
          end


          % Tail sizing
          % Horizontal tail volume coefficient
          % Source: Airplane Design Vol 2, Roskam, eq 8.1
          function output = Vbar_h(x_h, S_h, S_ref, c_bar)
               output = x_h*S_h/(S_ref*c_bar);
          end

          % Vertical tail volume coefficient
          % Source: Airplane Design Vol 2, Roskam, eq 8.2
          function output = Vbar_v(x_v, S_v, S_ref, b)
               output = x_v*S_v/(S_ref*b);
          end

          % Horizontal tail reference area
          % Source: Airplane Design Vol 2, Roskam, eq 8.3
          function output = S_h(Vbar_h, S_ref, c_bar, x_h)
               output = Vbar_h*S_ref*c_bar/x_h;
          end

          % Vertical tail reference area
          % Source: Airplane Design Vol 2, Roskam, eq 8.4
          function output = S_v(Vbar_v, S_ref, b, x_v)
               output = Vbar_v*S_ref*b/x_v;
          end




          % This should go into geometry
          % Compute c'/c (the ratio of the wing+flap chord length over the
          % the wing chord length)
          % Source: Airplane Design, Roskam, eq 7.16
          function output = cp_c(z_fh, c, delta_f_deg)
               output = 1+ 2*(z_fh/c)*tand(delta_f_deg/2);
          end

          function [L_fuselage, a, c] = get_fus_len(aircraft_type, W_TO)
               if aircraft_type == "sailplane - unpowered"
                    a = 0.86;
                    C = 0.48;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "sailplane - powered"
                    a = 0.71;
                    C = 0.48;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "homebuilt - metal") || (aircraft_type == "homebuilt - wood")
                    a = 3.68;
                    C = 0.23;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "homebuilt - composite"
                    a = 3.50;
                    C = 0.23;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "general aviation - single engine"
                    a = 4.37;
                    C = 0.23;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "general aviation - twin engine"
                    a = 0.86;
                    C = 0.42;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "agricultural aircraft"
                    a = 4.04;
                    C = 0.23;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "twin turboprop"
                    a = 0.37;
                    C = 0.51;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "flying boat"
                    a = 1.05;
                    C = 0.40;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif aircraft_type == "jet trainer"
                    a = 0.79;
                    C = 0.41;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "Jet fighter") || (aircraft_type == "jet fighter")
                    a = 0.93;
                    C = 0.39;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
               elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber")
                    a = 0.23;
                    C = 0.50;
                    L_fuselage = GeometryLevel2.compute_fus_len(a, C, W_TO);
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