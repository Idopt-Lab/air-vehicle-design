classdef F16PropulsionLevel2 < PropulsionModelLevel2
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This is supposed to use Mattingly's "Master Equation"

     properties
          enginestats
          TSFC
          T0
     end

     methods

          % Constructor
          function obj = F16PropulsionLevel2(design)
               % obj.t_sl_dry = design.propulsion.ThrustseaLevellbf.Dry;
               % obj.t_sl_wet = design.propulsion.ThrustseaLevellbf.Wet;
               obj.TSFC.wet_sl = obj.get_TSFC_installed("low bpr turbofan", [0, 0], "max");
               obj.TSFC.dry_sl = obj.get_TSFC_installed("low bpr turbofan", [0, 0], "max");
          end

          % Estimate installed TSFC (preliminary) (wrapper) (1/sec)
          function TSFC = get_TSFC_installed(propulsion_obj, engine_type, state_input, mil_or_max_power)
               M0 = state_input(1);
               theta = PropulsionLevel2.get_theta(state_input);
               engine_type = PropulsionUtils.classify_engine_type(engine_type); % "normalize" engine type input.
               if (engine_type == "high_bypass_turbofan")
                    if M0 <= 0.9
                         TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
                    else
                         warning("Cannot use high-BPR turbofan for M > 0.9.")
                         TSFC = PropulsionLevel2.comp_TSFC_highBPRturbofan(M0, theta);
                    end
               elseif (engine_type == "low_bypass_mixed_turbofan")
                    TSFC = PropulsionLevel2.comp_TSFC_lowBPRmixedturbofan(M0, theta, mil_or_max_power);
               elseif (engine_type == "turbojet")
                    TSFC = PropulsionLevel2.comp_TSFC_turbojet(M0, theta, mil_or_max_power);
               elseif (engine_type == "turboprop")
                    TSFC = PropulsionLevel2.comp_TSFC_turboprop(M0, theta);
               else
                    error("Could not identify engine type." + newline + "Accepted types:" + newline + "High bypass turbofan" + newline + "Low bypass mixed turbofan" + newline + "turbojet" + newline + "turboprop")
               end
               TSFC = TSFC/3600;
          end

     end





     methods (Access = private)

     end
end