classdef SandCLevel3 < SandCModelLevel3
     %SANDCLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          CG
          NP
          C_of_L
     end

     methods
          function obj = SandCLevel3(design)
               %SANDCLEVEL3 Construct an instance of this class
               %   Detailed explanation goes here
               obj.Property1 = inputArg1 + inputArg2;
          end

          % Estimate longitudinal location of CG
          function output = get_CG(stability_obj, weight_obj)
               % Function accepts arguments of weight. Uses longitudinal
               % location of weight components to estimate CG location

          end

          % Compute pitching moment coefficient
          function output = compute_cm(stability_obj, M, q, S_ref, c_bar)
               output = M/(q*S_ref*c_bar);
          end

          % Compute yawing moment coefficient
          function output = compute_cn(stability_obj, N, q, S_ref, b)
               output = N/(q*S_ref*b);
          end

          % Compute rolling moment coefficient
          function output = compute_cl(stability_obj, L, q, S_ref, b)
               output = L/(q*S_ref*b);
          end

          %% LONGITUDINAL STATIC STABILITY AND CONTROL

          % Compute the PITCH moment about the center of gravity
          function output = compute_MCG(stability_obj, L, X_cg, X_acw, M_w, M_w_deltaf, delta_f, M_fus, L_h, X_ach, T_z_t, F_p, X_p)
               output = L*(X_cg - X_acw) + M_w + M_w_deltaf*delta_f + M_fus - L_h*(X_ach - X_cg) - T_z_t + F_p*(X_cg - X_p);
          end

          % Compute the pitch moment coefficient about the CG
          function output = compute_Cm_cg(stability_obj, CL, X_cg, X_acw, c, C_mw, C_mwdeltaf, delta_f, C_mfus, q_h, S_h, q, S_w, C_Lh, X_ach, T_zt, F_p, X_p)
               output = CL*((X_cg - X_acw)/c) + C_mw + C_mwdeltaf*delta_f + C_mfus - ((q_h*S_h)/(q*S_w))*C_Lh*((X_ach - X_cg)/c) - (T_zt/(q*S_w*c)) + (F_p*(X_cg - X_p))/(q*S_w*c);
          end

          % Compute the derivative of the pitching moment w/r to AOA.
          function output = compute_C_malpha(stability_obj, CL_alpha, Xbar_cg, Xbar_acw, C_malphafus, eta_h, S_h, S_w, CL_alphah, delta_alphah_over_delta_alpha, F_palpha, q, Xbar_p, Xbar_ach)
               output = CL_alpha*(Xbar_cg - Xbar_acw) + C_malphafus - eta_h*(S_h/S_w)*CL_alphah*(delta_alphah_over_delta_alpha)*(Xbar_ach - Xbar_cg) + F_palpha/(q*S_w) * delta_alphah_over_delta_alpha * (Xbar_cg - Xbar_p);
          end

          % Compute the neutral point
          function output = compute_Xbar_np(stability_obj, CL_alpha, Xbar_acw, C_malphafus, eta_h, S_h, S_w, CL_alphah, delta_alpha_h_delta_alpha, Xbar_ach, F_palpha, q, delta_alpha_p_delta_alpha, Xbar_p)
               output = ( (CL_alpha*Xbar_acw - C_malphafus + (eta_h*(S_h/S_w)*CL_alphah*delta_alpha_h_delta_alpha*Xbar_ach) + ((F_palpha/(q*S_w))*delta_alpha_p_delta_alpha*Xbar_p)))/(CL_alpha + eta_h*(S_h/S_w)*CL_alphah*(delta_alpha_h_delta_alpha) + (F_palpha/(q*S_w))*delta_alpha_p_delta_alpha);
          end

          % Estimate the CM_alpha
          function output = estimate_Cm_alpha(stability_obj, CL_alpha, Xbar_np, Xbar_cg)
               output = -1*CL_alpha*(Xbar_np - Xbar_cg);
          end

          % Compute the static margin
          function output = compute_SM(stability_obj, Xbar_np, Xbar_cg)
               output = Xbar_np - Xbar_cg;
          end

          %% AERODYNAMIC CENTERS
          % Compute aerodynamic center

          function output = compute_x_ac(stability_obj, x_c4, delta_x_ac, S_wing)
               output = x_c4 + delta_x_ac*sqrt(S_wing);
          end

          % Compute delta_x_ac
          function output = get_delta_x_ac(stability_obj, M)
               if (0.4 < M) || (M < 1.1)
                    delta_x_ac = stability_obj.compute_delta_x_ac_subsonic(M);
               elseif (M > 1.1)
                    delta_x_ac = stability_obj.compute_delta_x_ac_supersonic(M);
               else
                    error("Error handler.")
               end
               output = delta_x_ac;
          end

          %% Lift coefficients
          % Wing:
          function output = compute_CL_wing(stability_obj, CL_alpha, alpha, i_w, alpha_0L)
               output = CL_alpha*(alpha + i_w - alpha_0L);
          end
          % Aft tail:
          function output = compute_CL_tail(stability_obj, CL_alpha_h, alpha, i_h, epsilon, alpha_0L_h)
               output = CL_alpha_h*(alpha + i_h - epsilon - alpha_0L_h);
          end

          %% Changes in zero-lift AOA
          % Compute delta_alpha_0L (elevator)
          function output = compute_delta_alpha_0L(stability_obj, delta_CL, CL_alpha)
               output = - (delta_CL/CL_alpha);
          end

          % Change in zero-lift AOA (plain flap)
          function output = compute_delta_alpha_0L_plainflap(stability_obj, CL_alpha, delta_CL_delta_delta_f, delta_f)
               output = (- (1/CL_alpha) * delta_CL_delta_delta_f)*delta_f;
          end

          % Compute delta_CL_delta_delta_f
          function output = compute_delta_CL_delta_f(stability_obj, K_f, delta_Cl_delta_delta_f, S_flapped, S_ref, Lambda_LE_h_deg)
               output = 0.9*K_f*(delta_Cl_delta_delta_f)*(S_flapped/S_ref)*cosd(Lambda_LE_h_deg);
          end


          %% Wing pitching moment

          % Compute the wing's pitching moment coefficient (M = 0.8)
          function output = compute_cm_w(stability_obj, C_m0_airfoil, AR, Sweepangle_deg)
               output = C_m0_airfoil*( (AR*cosd(Sweepangle_deg)^2)/(AR + 2*cosd(Sweepangle_deg)));
          end

          % Compute wing pitching moment coefficnet with flap deflection
          function output = compute_cm_w_flapdeflection(stability_obj, delta_CL_delta_delta_f, Xbar_cp, Xbar_cg)
               output = - delta_CL_delta_delta_f*(Xbar_cp - Xbar_cg);
          end

          %% Downwash, upwash, and updog
          % Estimate the change in AOA due to downwash
          function output = get_downwash_angle_derivative(stability_obj, delta_eps_delta_alpha_M0, CL_alpha, CL_alpha_M0, AR, M)
               if (1.0 <= M)
                    downwash_angle_derivative = stability_obj.compute_downwash_angle_deriv_supersonic(CL_alpha, AR);
               elseif (M < 1.0)
                    downwash_angle_derivative = stability_obj.compute_downwash_angle_derivative_subsonic(delta_eps_delta_alpha_M0, CL_alpha, CL_alpha_M0);
               else
                    error("Error handler.")
               end
               output = downwash_angle_derivative;
          end






          %% MAC equations are sourced from Brandt
          % Get MAC of a wing
          function output = get_MAC(stability_obj, c_root, lambda)
               output = (2/3)*c_root*((1+lambda+lambda^2)/(1+lambda));
          end

          % Compute MAC of a lifting surface (y)
          function output = get_y_MAC(stability_obj, b, lambda)
               output = (b/6)*(1 + 2*lambda)/(1+lambda);
          end

          % Compute MAC of a lifting surface (x)
          function output = get_x_MAC(stability_obj, x_loc_wing, y_MAC, Lambda_LE_deg)
               output = x_loc_wing + y_MAC*tand(Lambda_LE_deg);
          end

          % Compute the X-Location of the MAC of a wing
          function output = get_ac_wing(stability_obj, x_MAC, MAC)
               output = x_MAC + 0.25*MAC;
          end
     end

     methods (Access = private)

          % Compute downwash angle derivative, subsonic
          function output = compute_downwash_angle_deriv_subsonic(stability_obj, delta_eps_delta_alpha_M0, CL_alpha, CL_alpha_M0)
               output = delta_eps_delta_alpha_M0*(CL_alpha/CL_alpha_M0);
          end

          % Compute downwash angle derivative, supersonic
          function output = compute_downwash_angle_deriv_supersonic(stability_obj, CL_alpha, AR)
               output = (1.62*CL_alpha)/(pi*AR);
          end


          % Compute delta_x_ac (subsonic)
          function output = compute_delta_x_ac_subsonic(stability_obj, M)
               output = 0.26*(M - 0.4)^(2.5);
          end

          % Compute delta_x_ac (supersonic)
          function output = compute_delta_x_ac_supersonic(stability, M)
               output = 0.112 - 0.004*M;
          end
     end
end