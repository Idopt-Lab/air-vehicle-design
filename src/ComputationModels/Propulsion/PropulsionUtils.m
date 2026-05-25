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
     end
end