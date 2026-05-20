classdef WeightLevel2
     %F16WEIGHTESTLEVEL2 Summary of this class goes here
     %   Detailed explanation goes here
     % This is NOT purely component-level.

     properties (Constant)
          % Figure out how to put AE481 aircraft_design_metabook table 7.1
          % in here.
     end

     methods (Static)

          % Estimate OEW (Raymer, 6th ed, Table 6.1)
          function OEW = get_OEW(aircraft_type, W_TO, W0, AR, T, S_ref, M_max, K_vs)

               if (aircraft_type == "jet trainer")
                    a = 0;
                    b = 4.28;
                    c1 = -0.10;
                    c2 = 0.10;
                    c3 = 0.20;
                    c4 = -0.24;
                    c5 = 0.11;
               elseif (aircraft_type == "jet fighter")
                    a = -0.02;
                    b = 2.16;
                    c1 = -0.10;
                    c2 = 0.20;
                    c3 = 0.04;
                    c4 = -0.10;
                    c5 = 0.08;
               elseif (aircraft_type == "military cargo") || (aircraft_type == "military bomber")
                    a = 0.07;
                    b = 1.71;
                    c1 = -0.10;
                    c2 = 0.10;
                    c3 = 0.06;
                    c4 = -0.10;
                    c5 = 0.05;
               elseif (aircraft_type == "jet transport")
                    a = 0.32;
                    b = 0.66;
                    c1 = -0.13;
                    c2 = 0.30;
                    c3 = 0.06;
                    c4 = -0.05;
                    c5 = 0.05;
               elseif (aircraft_type == "sailplane - unpowered")
                    a = 0;
                    b = 0.76;
                    c1 = -0.05;
                    c2 = 0.14;
                    c3 = 0;
                    c4 = -0.30;
                    c5 = 0.06;
               elseif (aircraft_type == "sailplane - powered")
                    a = 0;
                    b = 1.21;
                    c1 = -0.04;
                    c2 = 0.14;
                    c3 = 0.19;
                    c4 = -0.20;
                    c5 = 0.05;
               elseif (aircraft_type == "homebuilt - metal") || (aircraft_type == "homebuilt - wood")
                    a = 0;
                    b = 0.71;
                    c1 = -0.10;
                    c2 = 0.05;
                    c3 = 0.10;
                    c4 = -0.05;
                    c5 = 0.17;
               elseif (aircraft_type == "homebuilt - composite")
                    a = 0;
                    b = 0.69;
                    c1 = -0.10;
                    c2 = 0.05;
                    c3 = 0.10;
                    c4 = -0.05;
                    c5 = 0.17;
               elseif (aircraft_type == "general aviation - single engine")
                    a = -0.25;
                    b = 1.18;
                    c1 = -0.20;
                    c2 = 0.08;
                    c3 = 0.05;
                    c4 = -0.05;
                    c5 = 0.27;
               elseif (aircraft_type == "general aviation - twin engine")
                    a = -0.90;
                    b = 1.36;
                    c1 = -0.10;
                    c2 = 0.08;
                    c3 = 0.05;
                    c4 = -0.05;
                    c5 = 0.20;
               elseif (aircraft_type == "agricultural aircraft")
                    a = 0;
                    b = 1.67;
                    c1 = -0.14;
                    c2 = 0.07;
                    c3 = 0.10;
                    c4 = -0.10;
                    c5 = 0.11;
               elseif (aircraft_type == "twin turboprop")
                    a = 0.37;
                    b = 0.09;
                    c1 = -0.06;
                    c2 = 0.08;
                    c3 = 0.08;
                    c4 = -0.05;
                    c5 = 0.30;
               elseif (aircraft_type == "flying boat")
                    a = 0;
                    b = 0.42;
                    c1 = -0.01;
                    c2 = 0.10;
                    c3 = 0.05;
                    c4 = -0.12;
                    c5 = 0.18;
               else
                    error("Couldn't identify aircraft type. Accepted values: jet trainer/fighter/transport, military cargo/bomber, sailplane unpowered/powered, homebuilt - metal/wood/composite, general aviation single/twin engine, agricultural aircraft, twin turboprop, flying boat.")
               end
               OEW = W_TO*(a + b*W0^(c1) * AR^(c2) * (T/W0)^(c3) * (W0/S_ref)^(c4) * M_max^(c5))*K_vs;
          end

          % Component weight functions (high-level, large objects; main
          % wings, tail, fuselage, landing gear, engine)
          % SOURCE: AE481 AIRCRAFT DESIGN METABOOK, J.R.R.A. MARTINS, TABLE
          % 7.1

          % Wing weight
          function W_wing = estimate_mainwing_weight(aircraft_type, S_exposed_planform)
               if (aircraft_type == "fighter")
                    W_wing = 9*S_exposed_planform;
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_wing = 10*S_exposed_planform;
               elseif (aircraft_type == "general aviation")
                    W_wing = 2.5*S_exposed_planform;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end

          % Horizontal tail weight
          function W_ht = estimate_HT_weight(aircraft_type, S_exposed_planform)
               if (aircraft_type == "fighter")
                    W_ht = 4*S_exposed_planform;
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_ht = 5.5*S_exposed_planform;
               elseif (aircraft_type == "general aviation")
                    W_ht = 2*S_exposed_planform;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end

          % Vertical fin (ONE FIN)
          function W_vt = estimate_VT_weight(aircraft_type, S_exposed_planform)
               if (aircraft_type == "fighter")
                    W_vt = 5.3*S_exposed_planform;
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_vt = 5.5*S_exposed_planform;
               elseif (aircraft_type == "general aviation")
                    W_vt = 2*S_exposed_planform;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end

          % Fuselage
          function W_fuselage = estimate_fuselage_weight(aircraft_type, S_exposed_planform)
               if (aircraft_type == "fighter")
                    W_fuselage = 4.8*S_exposed_planform;
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_fuselage = 5*S_exposed_planform;
               elseif (aircraft_type == "general aviation")
                    W_fuselage = 1.4*S_exposed_planform;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end

          % Landing gear
          function W_landinggear = estimate_landinggear_weight(aircraft_type, isnavy, W_TO)
               if (aircraft_type == "fighter")
                    if (isnavy == true)
                         W_landinggear = 0.045*W_TO;
                    elseif (isnavy == false)
                         W_landinggear = 0.033*W_TO;
                    else
                         error("Couldn't determine if design is Navy. Use 'true' or 'false'.")
                    end
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_landinggear = 0.043*W_TO;
               elseif (aircraft_type == "general aviation")
                    W_landinggear = 0.057*W_TO;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end

          % Installed engine
          function W_eng_installed = estimate_W_eng_installed(aircraft_type, engine_weight)
               if (aircraft_type == "fighter")
                    W_eng_installed = 1.3*engine_weight;
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_eng_installed = 1.3*engine_weight;
               elseif (aircraft_type == "general aviation")
                    W_eng_installed = 1.4*engine_weight;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end

          % "All-else empty"
          function W_allelseempty = estimate_allelseempty_weight(aircraft_type, W_TO)
               if (aircraft_type == "fighter")
                    W_allelseempty = 0.17*W_TO;
               elseif (aircraft_type == "transport") || (aircraft_type == "bomber")
                    W_allelseempty = 0.17*W_TO;
               elseif (aircraft_type == "general aviation")
                    W_allelseempty = 0.1*W_TO;
               else
                    error("Couldn't identify aircraft type. Accepted types: fighter, transport, bomber, general aviation.")
               end
          end
     end
end