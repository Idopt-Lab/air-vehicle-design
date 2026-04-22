classdef AeroLevel4 < AerodynamicsModelLevel3
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 4 aerodyanmics equations go here
     % N.B: Assisted by ChatGPT - transferred handle frunctions from old
     % Drag_Polar_IV code.

     properties
          e_osw;
          DragResults
          DQ;
          CD0 % Should have supersonic and subsonic components
          % The "below" values should be in a geometry class or something

          % The "above" values should be in a "geometry" class or something
          Cf_fuselage;
          Cf_mainwings;
          Cf_HT;
          Cf_VT;
          Q_fuselage;
          Q_wing;
          Q_tail;
     end

     methods


          function DragResults = compute_drag(obj, design)

               % KEEP THIS FORMAT
               % Do drag calculations
               % Need: CD0 (sub and sup), CD (sub and sup), K (sub and
               % sup), Mach drag divergence
               DragResults.CD0_sub = get_CD0_sub(obj, design);
               DragResults.CD = 1233;
               DragResults.K = 234;

               % Store in the object
               % obj.DragResults = DragResults;
          end


          % Component drags

          % Form factor
          % f
          function output = f(l, d, A_max)
               output = (l/(sqrt((4/pi)*A_max))); % Raymer, eq 12.33, 6th edition
          end

          % Flat-plat skin friction coefficient.
          % For wings, tails struts, pylons
          function output = FF_1(x_c, t_c, M, Lambda_m)
               output = (1 + 0.6/(x_c)*(t_c) + 100*(t_c)^4)*(1.34*M^(0.18) * cos(Lambda_m)^0.28);
               % Raymer, eq 12.30, 6th edition
          end

          % Flat-plate skin friction coefficient.
          % Fuselage, smooth canopy
          function output = FF_2(l, d, A_max)
               output = (0.9 + 5 / (obj.f(l,d,A_max)^(1.5)) + obj.f(l,d,A_max)/400);
          end
          % Raymer, eq 12.31, 6th edition

          % Flat-plate skin friction coefficient
          % Nacelle and smooth external store
          function output = FF_3(l, d, A_max)
               output = (1 + (0.35 / obj.f(l,d,A_max)));
          end
          % Raymer, eq 12.32, 6th edition

          % Boundary layer diverters (double wedge, single wedge,
          % respectively)
          function output = FF_doublewedge(d,l)
               output = (1+(d/l)); % Raymer, eq 12.34, 6th edition
          end

          function output = FF_singlewedge(d,l)
               output = (1 + ((2*d)/l)); % Raymer, eq 12.35, 6th edition
          end

          function output = R_cutoff_sub(ref_length, k)
               output = (38.21*(ref_length/k)^(1.053)); % Raymer, eq 12.28, 6th edition. Use when R_cutoff < R_component
          end

          function output = R_cutoff_sup(ref_length, Mach, k)
               output = (44.62*(ref_length/k)^(1.053)*Mach^(1.16)); % Raymer, eq 12.29, 6th edition
          end

          function output = R(ref_length, V)
               output = (rho_drag_polar*V*ref_length/mu); % Raymer, eq 12.25, 6th edition
          end

          function output = Cf_lam(R)
               output = (1.328/(sqrt(R))); % eq 12.26, 6th ed
          end

          function output = Cf_turb(R, Mach)
               output = (0.455/(((log(R)^(2.58))*(1 + 0.144*Mach^2))^(0.65)));
               % eq 12.27, 6th ed
          end

          function output = Dq_upsweep(u,A_max)
               output = (3.83*u^(2.5)*A_max); % eq 12.36
          end

          function output = Dq_base_sub(M, A_base)
               output = ((0.139 + 0.419*(M - 0.161)^2)*A_base); % eq 12.37
          end

          function output = Dq_base_sup(M, A_base)
               output = ((0.064 + 0.042*(M - 3.84)^2)*A_base); % eq 12.38
          end

          function output = Dq_windmillingjet(A_engine_front_face)
               output = (0.3*A_engine_front_face); % eq 12.40
          end

          function output = Dq_searshaack(A_max, l)
               output = (9*pi/2 * (A_max/l)^2); % eq 12.44, 6thh ed
          end

          function output = Dq_wave(E_WD, M, Lambda_LE_deg, A_max, l)
               output = (E_WD*(1-0.386*(M-1.2)^(0.57)*(1 - (pi*Lambda_le_deg^0.77)/100))*(Dq_searshaack(A_max, l))); % eq 12.45, 6th ed
          end

          function output = e_straight(AR)
               output = (1.78 * ( 1 - 0.045*AR^(0.68)) - 0.64); % For straight wings (sweep < 30 deg) (eq 12.48, 6th ed)
          end

          function output = e_swept(AR, Lambda_le_deg)
               output = (4.61*(1-0.045*AR^(0.68))*cos(Lambda_le_deg*pi/180)^(0.15) - 3.1); % For swept-wing (sweep > 30 deg) (eq 12.49, 6th ed)
          end

          function output = compute_e_osw(obj, Aircraft, Mission, Requirements)
               output = 43;
          end
     end




     % HELPER METHODS
     methods (Access = private)
          % Compute CD0_sub
          function CD0_sub = get_CD0_sub(obj, design)
               Component_Drags = get_component_drags(obj, design);
               obj.CD_misc = get_CD_misc(obj, design);
               obj.CD_LandP = get_CD_LandP(obj, design);
               CD0_sub = Component_Drags/design.S_ref + obj.CD_misc + obj.CD_LandP;
          end

          % Compute component drags
          function Component_Drags = get_component_drags(obj, design)
               Component_Fuselage = obj.Cf_fuselage*obj.Q_fuselage*design.WeightResults.S_wet;
               Component_mainwings = obj.Cf_mainwings*obj.Q_wing*design.SW_wings;
               Component_HT = obj.Cf_HT*obj.Q_tail*design.SW_HT;
               Component_VT = obj.Cf_VT*obj.Q_tail*design.SW_VT;

               Component_Drags = Component_Fuselage + Component_mainwings + Component_HT + Component_VT;
          end

          % Compute miscellaneous CDs
          function CD_misc = get_CD_misc(obj, design)
               obj.CD0_wingmillingjet = get_CD0_windmillingjet(obj, design);
               obj.CD0_upsweep = get_CD0_upsweep(obj, design);
               CD_misc = obj.CD0_windmillingjet + obj.CD0_upsweep;
          end

          % Compute CD0_widmillingjet
          function CD0_windmillingjet = get_CD0_windmillingjet(obj, design)
               obj.Dq_windmillingjet_value = get_Dq_windmillingjet(obj, design);
               CD0_windmillingjet = obj.Dq_windmillingjet_value/design.S_ref;
          end

          % Compute D/q of the windmilling jet engine
          function Dq_windmillingjet_value = get_Dq_windmillingjet(obj, design)
               obj.Dq_windmillingjet_value = (0.3* design.A_engine_front_face);
          end

          % Get CD0 upsweep
          function CD0_upsweep = get_CD0_upsweep(obj, design)
               obj.Dq_upsweep = get_Dq_upsweep(obj, design);
               CD0_upsweep = obj.Dq_upsweep/design.S_ref;
          end

          % Get D/q of the fuselage upsweep
          function Dq_upsweep = get_Dq_upsweep(obj, design)
               Dq_upsweep = (3.83*u^(2.5)*design.A_max); % "A_max" should be of fuselage, I think
          end

     end
end