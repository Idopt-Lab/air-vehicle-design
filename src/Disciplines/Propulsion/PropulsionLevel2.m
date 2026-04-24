classdef PropulsionLevel2 < PropulsionModelLevel2
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This is supposed to use Mattingly's "Master Equation"

     properties
          enginestats
          TSFC
     end

     methods

          % Estimate installed TSFC (preliminary) (wrapper) (1/hr)
          function output = get_TSFC_installed(propulsion_obj, engine_type, state_input, mil_or_max_power)
               M0 = state_input(1);
               h_ft = state_input(2);
               theta = PropulsionUtils.theta(h_ft);
               engine_type = propulsion_obj.classify_engine_type(engine_type); % "normalize" engine type input.
               if (engine_type == "high_bypass_turbofan")
                    if M0 < 0.9
                         TSFC = propulsion_obj.comp_TSFC_highBPRturbofan(M0, theta);
                    else
                         warning("Cannot use high-BPR turbofan for M > 0.9.")
                         TSFC = propulsion_obj.comp_TSFC_highBPRturbofan(M0, theta);
                    end
               elseif (engine_type == "low_bypass_mixed_turbofan")
                    TSFC = propulsion_obj.comp_TSFC_lowBPRmixedturbofan(M0, theta, mil_or_max_power);
               elseif (engine_type == "turbojet")
                    TSFC = propulsion_obj.comp_TSFC_turbojet(M0, theta, mil_or_max_power);
               elseif (engine_type == "turboprop")
                    TSFC = propulsion_obj.comp_TSFC_turboprop(M0, theta);
               else
                    error("Could not identify engine type." + newline + "Accepted types:" + newline + "High bypass turbofan" + newline + "Low bypass mixed turbofan" + newline + "turbojet" + newline + "turboprop")
               end
               output = TSFC;
          end
     end





     methods (Access = private)

          % Estimate TSFC for a high-bypass-ratio turbofan engine
          % Valid: M_0 < 0.9
          function output = comp_TSFC_highBPRturbofan(propulsion_obj, M_0, theta)
               output = (0.45 + 0.54*M_0)*sqrt(theta);
          end

          % Estimate TSFC for a low-BPR mixed turbofan engine
          function output = comp_TSFC_lowBPRmixedturbofan(propulsion_obj, M_0, theta, mil_or_max_power)
               if (mil_or_max_power == "mil")
                    output = (0.9 + 0.30*M_0)*sqrt(theta);
               elseif (mil_or_max_power == "max")
                    output = (1.6 + 0.27*M_0)*sqrt(theta);
               else
                    error("mil_or_max_power - must be 'mil' or 'max'.")
               end
          end

          % Estimate TSFC for a turbojet engine
          function output = comp_TSFC_turbojet(propulsion_obj, M_0, theta, mil_or_max_power)
               if (mil_or_max_power == "mil")
                    output = (1.1 + 0.30*M_0)*sqrt(theta);
               elseif (mil_or_max_power == "max")
                    output = (1.5 + 0.23*M_0)*sqrt(theta);
               else
                    error("mil_or_max_power - must be 'mil' or 'max'.")
               end
          end

          % Estimate TSFC for a turboprop engine
          function output = comp_TSFC_turboprop(M_0, theta)
               output = (0.18 + 0.8*M_0)*sqrt(theta);
          end

          % Normalize engine type inputs
          % Code from ChatGPT
          function engine_type_out = classify_engine_type(propulsion_obj, engine_type_in)
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
     end
end