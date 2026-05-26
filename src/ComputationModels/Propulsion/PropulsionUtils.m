classdef PropulsionUtils
     %PROPULSIONUTILS Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          T_std = 273.15; % Kelvin
          P_std = 100; %kPa
          gamma = 1.4;
     end

     methods (Static)

          % Compute lapse rate, alpha
          function alpha = compute_alpha(T_min, T_max, alpha_dry, alpha_AB, AB_percent)
               alpha = (alpha_dry*T_min + AB_percent*(alpha_AB*T_max - alpha_dry*T_min))/T_max;
          end

          % Compute throttle ratio (also known as theta_0)
          function TR = compute_TR(theta, gamma, M0)
               TR = theta*(1 + (gamma-1)/2 * (M0^2));
          end

          % Compute dry/wet lapse rate (this computes "alpha_dry" or
          % "alpha_wet" for a given engine at some given thrust config.
          function alpha_dryorwet = compute_alpha_dryorwet(T_alt, T_SL)
               alpha_dryorwet = T_alt/T_SL;
          end

          %% THRUST LAPSE RATES FOR VARIOUS ENGINES

          % High BPR turbofan
          % Valid: M_0 < 0.9
          % Source: Aircraft Engine Design, 2nd ed, Mattingly, 2.53
          function alpha = compute_alpha_highBPR_turbofan(M_0, theta_0, delta_0, TR)
               if (theta_0 <= TR)
                    alpha = delta_0*(1-0.49*sqrt(M_0));
               elseif (theta_0 > TR)
                    alpha = delta_0*(1- 0.49*sqrt(M_0)-((3*(theta_0 - TR))/(1.5+M_0)));
               else
                    error("Error handler.")
               end
          end

          % Low BPR mixed turbofan
          % Source: Aircraft Engine Design, 2nd ed, Mattingly, 2.54a
          function alpha = compute_alpha_lowBPR_turbofan_maxpower(delta_0, theta_0, TR)
               if (theta_0 <= TR)
                    alpha = delta_0; % 2.54a
               elseif (theta_0 > TR)
                    alpha = delta_0*(1- 3.5*(theta_0 - TR)/theta_0); % 2.54a
               else
                    error("Error handler, max.")
               end
          end

          % Low BPR mixed turbofan
          % Source: Aircraft Engine Design, 2nd ed, Mattingly, 2.54b
          function alpha = compute_alpha_lowBPR_turbofan_milpower(delta_0, theta_0, TR)
               if (theta_0 <= TR)
                    alpha = 0.6*delta_0; % 2.54b
               elseif (theta_0 > TR)
                    alpha = 0.6*delta_0*(1 - 3.8*(theta_0-TR)/theta_0);
               else
                    error("Error handler, mil.")
               end
          end

          % TURBOJET
          % Max power
          % Source: Aircraft Engine Design, 2nd ed, Mattingly, 2.55a
          function alpha = compute_alpha_turbojet_max(delta_0, theta_0, M_0, TR)
               if (theta_0 <= TR)
                    alpha = delta_0*(1-0.3*(theta_0 - 1)- 0.1*sqrt(M_0));
               elseif (theta_0 > TR)
                    alpha = delta_0*(1-0.3*(theta_0 - 1) - 0.1*sqrt(M_0) - (1.5*(theta_0 - TR)/theta_0));
               end
          end

          % Mil power
          % Source: Aircraft Engine Design, 2nd ed, Mattingly, 2.55b
          function alpha = compute_alpha_turbojet_mil(delta_0, theta_0, TR, M_0)
               if (theta_0 <= TR)
                    alpha = 0.8*delta_0*(1-0.16*sqrt(M_0));
               elseif (theta_0 > TR)
                    alpha = 0.8*delta_0*(1-0.16*sqrt(M_0)- (24*(theta_0 - TR))/((9+M_0)*theta_0));
               end
          end

          % TURBOPROP
          % Source: Aircraft Engine Design, 2nd ed, Mattingly, 2.56
          function alpha = compute_alpha_turboprop(delta_0, theta_0, TR, M_0)
               if (M_0 <= 0.1)
                    alpha = delta_0;
               elseif (theta_0 <= TR)
                    alpha = delta_0*((1-0.96*(M_0-1))^(1/4));
               elseif (theta_0 > TR)
                    alpha = delta_0*(1-0.96*(M_0 - 1)^(1/4) - (3*(theta_0 - TR))/(8.13*(M_0 - 0.1)));
               end
          end







               % Normalize engine type inputs
               % Code from ChatGPT
               function engine_type_out = classify_engine_type(engine_type_in)
                    s = lower(string(engine_type_in));
                    s = replace(s, "-", " ");
                    s = replace(s, "_", " ");
                    s = strip(s);
                    s = regexprep(s, "\s+", " ");

                    if contains(s, "turboprop")
                         engine_type_out = "turboprop";

                    elseif contains(s, "turbojet")
                         engine_type_out = "turbojet";

                    elseif contains(s, "turbofan")
                         if contains(s, "high bypass") || contains(s, "high bpr")
                              engine_type_out = "high_bypass_turbofan";
                         elseif contains(s, "low bypass") || contains(s, "low bpr")
                              engine_type_out = "low_bypass_mixed_turbofan";
                         else
                              error("Turbofan detected, but bypass class was unclear.")
                         end

                    else
                         error("Could not identify engine type from input: " + string(engine_type_in))
                    end
               end

               function output = theta(T_kelvin)
                    output = T_kelvin/PropulsionUtils.T_std;
               end

               function output = delta(P_kPa)
                    output = P_kPa/PropulsionUtils.P_std;
               end

               function output = theta_0(theta, gamma, M_0)
                    output = theta*(1 + (gamma-1)/2 * M_0^2);
               end

               function output = delta_0(delta, gamma, M_0)
                    output = delta*(1+ (gamma-1)/2 *M_0^2)^((gamma)/(gamma-1));
               end
          end
     end