classdef AerodynamicsModelLevel2 < AerodynamicsModelLevel1
     %AerodynamicsModel Summary of this class goes here
     %   Detailed explanation goes here

     properties (Abstract) % Initialization not allowed
          Delta_CL_max_TO
          Delta_CL_max_L
          Delta_cl_max_TO % Contribution from high-lift devices (take-off config)
          Delta_cl_max_L % Contribution from high-lift devices (landing config)
          Delta_CDi
          F % Fuselage interference factor
          % I should definitely add the properties of high-lift devices'
          % deflections for take-off and landing configurations, as well as
          % properties for their types.
     end

     properties (Abstract, Constant)
          airfoiltype % "cambered" or "uncambered".
          % N.B: Consider installing a NACA airfoil database for airfoil
          % data lookup (instead of having to troll the internet).
          hld_TE % High-lift device, trailing edge (type) (e.g., "plain")
          hld_LE % High-lift device, leading edge (type) (e.g., "slat")
          delta_hld_TE_TO % Deflection of high-lift device, trailing edge, take-off config (deg)
          delta_hld_TE_L % Deflection of high-lift device, trailing edge, landing config (deg)
          C1 % Tabulated from Fig 12.12, (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          C2 % Tabulatef from Fig 12.12, (Raymer, "Aircraft Design: A Conceptual Approach", 6th ed)
          CL_max_base % Tabulated from Fig 12.13 (Raymer, 6th ed) & (C1 + 1)*(AR/beta)*cosd(Lambda_LE_deg)
          sharpness_param % Should be tabulated
          CL_max_cl_max % Should be tabulated
          cl_max % Should be taken directly from the chosen airfoil
          alpha_L0 % Zero-lift AOA (deg)
     end


     methods (Abstract)
          % e_osw = get_e_osw(AR, Lambda_LE)
          % LD_max = get_LD_max(AR, e_osw, CD0)
          % AR_wet = get_AR_wet(b, S_wet)
          % K = get_K(e_osw, AR)
          % K1 = compute_K1(M, AR, e_osw, LE_sweep)
          % K2 = compute_K2(M, K1, CLminD)
          % CD = get_CD(CD0, K, CL)
          % CD0 = get_CD0(Cf, S_wet, S_ref)
          % CDi = get_CDi(statevector, CL, e_osw, AR)
          Delta_CD0 = get_Delta_CD0(flaptype, cf_c, S_flapped, S_ref, delta_flap_deg) % This should get you the Delta_CD0 values you need. (use Raymer 12.61
          CL_minD = get_CL_minD(CL_alpha, alpha_L0)
          % Cf = get_Cf(aircraft_type, n_engines) % Using L1 until a suitable replacement is found.
          CL_max = get_CL_max_values(AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max) % This should get you the CL_max values you need (CL_max_TO, CL_max_Landing, etc)
          Delta_CL_max = get_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg) % This should be able to get you the Delta_CL_max values you need.
          Delta_cl_max = get_Delta_cl_max_values(liftdevice, config, cp_c) % this should get you the values you need (Delta_cl_max_TO, Delta_cl_max_L)
          Delta_CDi = get_Delta_CDi(areFlapsFullOrHalfSpan, Delta_CL_flap, Lambda_cbar_q_deg)
          CL_alpha = get_CL_alpha(M, cl_alpha, AR, S_exposed, S_ref, F, Lambda_max_t_deg)
          F = get_F(d, b)
     end

     %% -----------------------------------------------------------------------------

     properties (Constant)
          k_lambda = [0.88, 0.95]
          k_ww = 1.85; % Part of the wing "buried" in the fuselage (Airplane Design Vol 3, Roskam, p 167)
          Delta_cl_max_table = table({'plain'; 'split'; 'slotted'; 'fowler'; 'double slotted'; 'triple slotted'; 'fixed slat'; 'leading-edge flap'; 'Kruger flap'; 'slat'}, [0.9; 0.9; 1.3; 1.3; 1.6; 1.9; 0.2; 0.3; 0.3; 0.4], 'VariableNames',["High-Lift Device", "Delta_cl_max"]);
     end


     methods

          % Constructor
          function obj = AerodynamicsModelLevel2()

          end
          % Estimate Delta_CDi resulting from flaps
          % Source: Raymer, Aircraft Design: A Conceptual Approach, 6th ed,
          % eq 12.62
          function output = Delta_CDi_flap(k_f, Delta_CL_flap, Lambda_cbar_q_deg)
               % Lambda_cbar_q_deg = Sweep at mean geometric chord (deg)
               % k_f = 0.14 (full-span flaps) or 0.28 (half-span flaps).
               % "This induced drag increment is added to the drag due to
               % lift for the total lift using the clean wing drag due to
               % lift factor."

               output = k_f^2 * (Delta_CL_flap)^2 * cosd(Lambda_cbar_q_deg);
          end

          % Estimate Delta_CD0 resulting from flaps deployed
          % Source: Raymer, Aircraft Design: A Conceptual Approach, 6th ed,
          % eq 12.61
          function output = Delta_CD0_flap(obj, F_flap, cf_c, S_flapped, S_ref, delta_flap_deg)
               % cf_c = Ratio of FLAP CHORD LENGTH (NOT TOTAL CHORD LENGTH (WING+FLAP)) over the WING CHORD
               % LENGTH.
               % delta_flap = flap deflection down (deg)
               output = F_flap*(cf_c)*(S_flapped/S_ref)*(delta_flap_deg - 10);
          end

          % Estimate CL_max (clean) (valid for M<1, moderate sweep)
          % Raymer, 6th ed, eq 12.15
          function output = CL_max_clean_subsonic(obj, cl_max, Lambda_qc_deg)
               output = 0.9*cl_max*cosd(Lambda_qc_deg);
          end

          % Estimate CL_max (clean) (HighAR, subsonic)
          % Valid: high AR, M<1
          % Raymer, 6th ed, eq 12.16
          function output = CL_max_clean_HighAR(obj, cl_max, CL_max_cl_max, Delta_CL_max)
               % cl_max = Airfoil lift coefficient at Mach 0.2
               output = cl_max*CL_max_cl_max + Delta_CL_max;
          end

          % Estimate CL_max (clean) (Low AR, subsonic)
          % Valid: Low AR, subsonic
          % Raymer, 6th ed, eq 12.19
          function output = CL_max_clean_LowAR(obj, CL_max_base, Delta_CL_max)
               output = CL_max_base + Delta_CL_max;
          end

          % Estimate Delta_CL_max induced by a high-lift device
          % Raymer, Aircraft Design: A Conceptual Approach, 6th ed, eq
          % 12.21
          function output = Delta_CL_max(obj, Delta_cl_max, S_flapped, S_ref, Lambda_HL)
               output = 0.9*Delta_cl_max*(S_flapped/S_ref)*cosd(Lambda_HL);
          end



          % Estimate L/D max
          % Source: Airplane Design vol 3, Roskam, eq 4.3
          function output = LD_max(AR, e_osw, CD0)
               output = pi*AR*e_osw/(4*CD0)^(1/2);
          end

          % This might be better in L1
          % Estimate Delta_CL_max_TO
          % Source: Aircraft Design Vol 2, Roskam, eq 7.6
          function output = Delta_CL_max_TO_comp(CL_max_TO, CL_max)
               output = 1.05*(CL_max_TO - CL_max);
          end

          % This might be better in L1
          % Estimate Delta_CL_max_L (landing)
          % Source: Aircraft Design Vol 2, Roskam, eq 7.7
          function output = Delta_CL_max_L_comp(CL_max_L, CL_max)
               output = 1.05*(CL_max_L - CL_max); % Yes, this is the same as the one for Delta_CL_max_TO
          end

          % This might be better in L2
          % Estimate the required incrementatl section maximum lift
          % coefficient with the flaps down
          % Source: Airplane Design Vol 2, Roskam, eq 7.8
          function output = Delta_cl_max(Delta_CL_max, S_ref, S_wf, K_Lambda)
               output = Delta_CL_max*(S_ref/S_wf)/(K_Lambda);
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

          % Estimate required value of incremental section lift coefficient
          % that the flaps must generate.
          % Source: Airplane Design Vol 2, Roskam, eq 7.11
          function output = Delta_cl(K, Delta_cl_max)
               output = (1/K)*Delta_cl_max;
          end

          % Equations of Delta_cl for various types of flaps
          % Plain flap
          function output = Delta_cl_plainflap(cl_delta_f, delta_f, K_prime)
               output = cl_delta_f*delta_f*K_prime; % Airplane Design, Roskam, eq 7.12
          end

          % Split flap
          function output = Delta_cl_splitflap(k_f, Delta_cl_cf_c)
               output = k_f*Delta_cl_cf_c; % Airplane Design, Roskam, eq 7.13
          end

          % Single slotted flaps
          function output = Delta_cl_singleslottedflap(cl_alpha, alpha_delta_f, delta_f)
               output = cl_alpha*alpha_delta_f*delta_f; % Airplane Design, Roskam, eq 7.14
          end

          % Fowler flaps
          function output = Delta_cl_fowlerflaps(cl_alpha, alpha_delta_f, delta_f)
               output = cl_alpha*alpha_delta_f*delta_f; % Airplane Design, Roskam, eq 7.17
          end

          % Flapped section lift curve slope
          % Source: Airplane Design, Roskam, eq 7.15
          function output = cl_alpha_f(cl_alpha, cp_c)
               output = cl_alpha*cp_c;
          end

          % % This should go into geometry
          % % Compute c'/c (the ratio of the wing+flap chord length over the
          % % the wing chord length)
          % % Source: Airplane Design, Roskam, eq 7.16
          % function output = cp_c(z_fh, c, delta_f_deg)
          %      output = 1+ 2*(z_fh/c)*tand(delta_f_deg/2);
          % end

          % Estimate effect of leading-edge high-lift devices (substitute
          % for lack of experimental data)
          % Source: Airplane Design Vol 2, Roskam, eq 7.18
          function output = cl_max_with_LE_flap(cl_max_no_LE_flap, cpp_c)
               output = cl_max_no_LE_flap*cpp_c;
          end




          % Estimate CL_max_w (clean)
          % Source: Airplane Design Vol 2, Roskam, eq 7.3
          % This should be a wrapper
          % function output = CL_max_w(lambda, cl_max_r, cl_max_t)
          %      if (0.4 < lambda) && (lambda <= 1.0)
          %        % use k_lambda = 0.88 (k_lambda(1))
          %        output = k_lambda(1)*(cl_max_r + cl_max_t)^(2);
          %      elseif (0.0 < lambda) && (lambda <= 0.4)
          %           output = k_lambda(2)*(cl_max_r + cl_max_t)^(2);
          %      else
          %           error("Error handler.")
          %      end
          % end

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
          function output = compute_CL_minD(obj, CL_alpha, alpha_L0)
               output = CL_alpha*(-alpha_L0/2);
          end


          % Get CD (uncambered)
          % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th
          % ed, eq 12.4
          function CD = compute_CD_uncambered(CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               CD = CD0 + K.*CL.^2;
          end

          % Get CD (cambered)
          % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th ed, eq 12.5
          function CD = compute_CD_cambered(obj, CD_min, K, CL, CL_minD)
               CD = CD_min + K.*(CL - CL_minD).^2;
          end

          % Get CD0
          function CD0 = compute_CD0(obj, Cf, S_wet_aircraft, S_ref)
               CD0 = Cf * S_wet_aircraft/S_ref;
          end

          % Estimate theoretical lift-curve slope for 2-D airfoil
          % (subsonic)
          % Raymer, 6th ed, fig 12.6
          function output = cl_alpha_2D_sub(obj, M)
               output = 2*pi/(sqrt(1-M^2));
          end

          % Estimate theoretical lift-curve slope for a supersonic 2-D
          % airfoil
          % Raymer, 6th ed, fig 12.6
          function output = cl_alpha_2D_sup(obj, M)
               output = 4/(sqrt(M^2 - 1));
          end

          % Estimate lift-curve slope (per radian) for a 3-D wing
          % (subsonic)
          % Raymer, 6th ed, eq 12.6
          function output = CL_alpha_wing_sub(obj, AR, S_exposed, S_ref, F, Lambda_max_t_deg, beta, eta)
               % beta = sqrt(1 - M^2);
               % eta = cl_alpha/(2*pi/beta);

               output = (2*pi*AR)/((2 + sqrt(4 + ((AR^2 * beta^2)/(eta^2))*(1 + tand(Lambda_max_t_deg)^2/(beta^2)))))*(S_exposed/S_ref)*F;
          end

          % Estimate lift-curve slope (per radian) for a 3-D wing
          % (supersonic)
          % Raymer, 6th ed, eq 12.12
          function output = CL_alpha_wing_sup(obj, beta_mach)
               output = 4/beta_mach;
          end

          % Compute beta for mach number
          % Raymer, 6th ed, eq 12.7
          function output = beta_mach(obj, M)
               output = sqrt(1-M^2);
          end

          % Compute eta for mach number and 2-D lift-curve slope
          % Ramyer, 6th ed, eq 12.8
          function output = eta_mach(obj, cl_alpha, beta_mach)
               output = cl_alpha/(2*pi/beta_mach);
          end

          % Compute fuselage lift factor
          % Raymer, 6th ed, eq 12.9
          function output = F_comp(obj, d, b)
               output = 1.07*(1 + d/b);
          end
     end

     methods (Access = private)
     end
end