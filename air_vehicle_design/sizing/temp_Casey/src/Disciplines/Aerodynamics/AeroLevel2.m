classdef AeroLevel2
     %AEROLEVEL2 Level-2 aerodynamics equation toolbox (static methods).
     %   Called by concrete aircraft classes via AeroLevel2.<method>(...).
     %   Holds no state; equations only.

     properties (Constant)
          k_lambda = [0.88, 0.95]
          k_ww = 1.85; % Part of the wing "buried" in the fuselage (Airplane Design Vol 3, Roskam, p 167)
          Delta_cl_max_table = table({'plain'; 'split'; 'slotted'; 'fowler'; 'double slotted'; 'triple slotted'; 'fixed slat'; 'leading-edge flap'; 'Kruger flap'; 'slat'}, [0.9; 0.9; 1.3; 1.3; 1.6; 1.9; 0.2; 0.3; 0.3; 0.4], 'VariableNames',["High-Lift Device", "Delta_cl_max"]);
     end


     methods (Static)



          % Estimate CL_max (clean) (valid for M<1, moderate sweep)
          % Raymer, 6th ed, eq 12.15
          function output = CL_max_clean_subsonic(cl_max, Lambda_qc_deg)
               output = 0.9*cl_max*cosd(Lambda_qc_deg);
          end

          % Estimate CL_max (clean) (HighAR, subsonic)
          % Valid: high AR, M<1
          % Raymer, 6th ed, eq 12.16
          function output = CL_max_clean_HighAR(cl_max, CL_max_cl_max, Delta_CL_max)
               % cl_max = Airfoil lift coefficient at Mach 0.2
               output = cl_max*CL_max_cl_max + Delta_CL_max;
          end

          % Estimate CL_max (clean) (Low AR, subsonic)
          % Valid: Low AR, subsonic
          % Raymer, 6th ed, eq 12.19
          function output = CL_max_clean_LowAR(CL_max_base, Delta_CL_max)
               output = CL_max_base + Delta_CL_max;
          end



          % Estimate L/D max
          % Source: Airplane Design vol 3, Roskam, eq 4.3
          % LD_max = 0.5*sqrt(pi*AR*e/CD0); the whole ratio is under the root.
          function output = LD_max(AR, e_osw, CD0)
               output = 0.5*sqrt(pi*AR*e_osw/CD0);
          end



          % Estimate K_Lambda (effects of sweep angle)
          % Source: Airplane Design Vol 2, Roskam, eq 7.9
          function output = K_Lambda(Lambda_qc_deg)
               output = (1 - 0.08*cosd(Lambda_qc_deg)^2)/(cosd(Lambda_qc_deg)^(3/4));
          end

          % Estimate ratio of flapped area to planform area for a straight
          % unswept wing
          % Source: Airplane Design Vol 2, Roskam, eq 7.10
          function output = S_wf_S(flap_b_out, flap_b_in, lambda)
               % flap_b_out = outboard location/span of flap
               % flap_b_in = inboard location/span of flap

               output = (flap_b_out - flap_b_in)*(2-(1-lambda)*(flap_b_in + flap_b_out))/(1+lambda);
          end

          % Estimate CL_max_w (clean)
          % Source: Airplane Design Vol 2, Roskam, eq 7.3
          function output = CL_max_w(k_lambda, cl_max_r, cl_max_t)
               output = k_lambda*(cl_max_r + cl_max_t)/2;
          end

          % Determine if aircraf is "short-coupled" or "long-coupled"
          % Source: Aircraft Design Vol 2, Roskam, page 168
          function output = isShortOrLongCoupled(l_h, c_bar)
               if (0.0 <= l_h/c_bar) && (l_h/c_bar < 3.0)
                    output = "short coupled";
               elseif (l_h/c_bar >= 5.0)
                    output = "long coupled";
               else
                    output = "medium coupled";
               end
          end

          % Correct for sweep effects using the "cosine rule"
          % Source: Airplane Design Vol 2, Roskam, eq 7.2
          % outputs CL_max_w_unswept
          function output = CL_max_w_unswept(CL_max_w_swept, Lambda_qc)
               output = CL_max_w_swept/cosd(Lambda_qc);
          end

          % Get CL_minD
          function output = compute_CL_minD(CL_alpha, alpha_L0)
               output = CL_alpha*(-alpha_L0/2);
          end


          % Get CD (uncambered)
          % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th
          % ed, eq 12.4
          function CD = compute_CD_uncambered(CD0, K, CL)
               CD = CD0 + K.*CL.^2;
          end

          % Get CD (cambered)
          % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th ed, eq 12.5
          function CD = compute_CD_cambered(CD_min, K, CL, CL_minD)
               CD = CD_min + K.*(CL - CL_minD).^2;
          end

          % Get CD0
          function CD0 = compute_CD0(Cf, S_wet_aircraft, S_ref)
               CD0 = Cf * S_wet_aircraft/S_ref;
          end

          % Estimate theoretical lift-curve slope for 2-D airfoil
          % (subsonic)
          % Raymer, 6th ed, fig 12.6
          function output = cl_alpha_2D_sub(M)
               output = 2*pi/(sqrt(1-M^2));
          end

          % Estimate theoretical lift-curve slope for a supersonic 2-D
          % airfoil
          % Raymer, 6th ed, fig 12.6
          function output = cl_alpha_2D_sup(M)
               output = 4/(sqrt(M^2 - 1));
          end

          % Estimate lift-curve slope (per radian) for a 3-D wing
          % (subsonic)
          % Raymer, 6th ed, eq 12.6
          function output = CL_alpha_wing_sub(AR, S_exposed, S_ref, F, Lambda_max_t_deg, beta, eta)
               % beta = sqrt(1 - M^2);
               % eta = cl_alpha/(2*pi/beta);

               output = (2*pi*AR)/((2 + sqrt(4 + ((AR^2 * beta^2)/(eta^2))*(1 + tand(Lambda_max_t_deg)^2/(beta^2)))))*(S_exposed/S_ref)*F;
          end

          % Estimate lift-curve slope (per radian) for a 3-D wing
          % (supersonic)
          % Raymer, 6th ed, eq 12.12
          function output = CL_alpha_wing_sup(beta_mach)
               output = 4/beta_mach;
          end

          % Compute beta for mach number
          % Raymer, 6th ed, eq 12.7
          function output = beta_mach(M)
               output = sqrt(1-M^2);
          end

          % Compute eta for mach number and 2-D lift-curve slope
          % Ramyer, 6th ed, eq 12.8
          function output = eta_mach(cl_alpha, beta_mach)
               output = cl_alpha/(2*pi/beta_mach);
          end

          % Compute fuselage lift factor
          % Raymer, 6th ed, eq 12.9
          function output = F_comp(d, b)
               output = 1.07*(1 + d/b)^2;
          end
     end

     methods (Access = private)
     end
end
