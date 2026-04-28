classdef PropulsionUtils
     %PROPULSIONUTILS Summary of this class goes here
     %   Detailed explanation goes here

     properties (Constant)
          T_std = 273.15; % Kelvin
          P_std = 100; %kPa
          gamma = 1.4;
     end

     methods (Static)

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