classdef AeroLevel2
     %F16AEROLEVEL1 Summary of this class goes here
     %   Detailed explanation goes here
     % Level 1 aerodynamics equations go here.
     % Remember, you can separate FUNCTION classes (classes with just
     % functions) from DATA STORAGE CLASSES (classes that just store data).
     % I think WeaponGenerator2 did that.

     properties (Constant)
          k_lambda = [0.88, 0.95]
     end

     methods (Static)

          % Estimate Delta_CL_max_TO
          % Source: Aircraft Design Vol 2, Roskam, eq 7.6
          function output = Delta_CL_max_TO(CL_max_TO, CL_max)
               output = 1.05*(CL_max_TO - CL_max);
          end

          % Estimate Delta_CL_max_L (landing)
          % Source: Aircraft Design Vol 2, Roskam, eq 7.7
          function output = Delta_CL_max_L(CL_max_L - CL_max)
               output = 1.05*(CL_max_L - CL_max); % Yes, this is the same as the one for Delta_CL_max_TO
          end

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


          % Get CD
          function CD = compute_CD(CD0, K, CL) % Problem: other classes have function with same name. Can I make this private somehow?
               CD = CD0 + K*CL^2;
          end

          % Get CD0
          function CD0 = compute_CD0(Cf, S_wet_aircraft, S_ref)
               CD0 = Cf * S_wet_aircraft/S_ref;
          end
     end

     methods (Access = private)
     end
end