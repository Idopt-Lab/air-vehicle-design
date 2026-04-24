classdef PropulsionLevel2 < PropulsionModelLevel3
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here
     % This is supposed to use Mattingly's "Master Equation"

     properties
          enginestats
          TSFC
     end

     methods

          % Estimate installed TSFC (preliminary) (wrapper)
          function output = get_TSFC_installed(propulsion_obj, engine_type, state_input, theta, mil_or_max_power)
               M0 = state_input(1);
               if (engine_type == "High bypass turbofan")
                    if M0 < 0.9
                         TSFC = propulsion_obj.comp_TSFC_highBPRturbofan(M0, theta);
                    else
                         warning("Cannot use high-BPR turbofan for M > 0.9.")
                         TSFC = propulsion_obj.comp_TSFC_highBPRturbofan(M0, theta);
                    end
               elseif (engine_type == "Low bypass mixed turbofan")
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

               % Get T_SL_W_TO across constraints
               function T_SL_W_TO = get_propulsion_stats(obj, design)
                    W_TO = design.WeightResults.W_TO;
                    q = design.constraints.aero.("q (lbf/ft^2)");
                    CD0 = design.constraints.aero.CD0;
                    alpha = design.constraints.thrust.throttleLapse;
                    beta = design.constraints.W_Wto;
                    K_1 = design.constraints.K1;
                    K_2 = design.constraints.K2;
                    e = design.constraints.e;
                    h = design.constraints.Altitude_ft_;
                    V = design.constraints.("V (ft/s)");
                    delta_t = 0; % Placeholder value (time increment, units unknown)
                    n = design.constraints.n;
                    S_ref = design.geom.wings.Main.PlanformAreaft2;

                    T_SL_W_TO = compute_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t, S_ref);
                    % Outputs as an ARRAY, need a STRUCT for easy reading.
               end


               % Get T_SL_W_TO across mission segments
               % I could have one for mission and another for constraint
               % analysis
               % function T_SL_W_TO = get_propulsion_stats(obj, mission_obj, design)
               %      mission_segments = get_segment_names(obj, mission_obj.missiondata);
               %
               %      % Extract segment values
               %      segment_values = get_segment_values(obj, mission_obj.missiondata, mission_segments, design.geom.wings);
               %
               %      for i = 1:length(segment_values)
               %           q = segment_values.mission_segments(i).q;
               %           CD0 = segment_values.mission_segments(i).CD0;
               %           e = segment_values.mission_segments(i).e;
               %           K_1 = segment_values.mission_segments(i).K_1;
               %           K_2 = segment_values.mission_segments(i).K_2;
               %           V = segment_values.mission_segments(i).Vl;
               %
               %           T_SL_W_TO.mission_segments(i) = compute_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t);
               %
               %      end
               % end

               % Get T_SL_W_TO (point-performance)
               function T_SL_W_TO = get_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t)
                    % Decompose object arguments into necessary components.
                    % Initialize "missiondata" if it hasn't been already
                    % So this gets the T_SL_W_TO for... ALL mission segments.
                    % This is for the entire design

                    T_SL_W_TO = get_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t);
               end
          end





          methods (Access = private)

               % Estimate TSFC for a high-bypass-ratio turbofan engine
               % Valid: M_0 < 0.9
               function output = comp_TSFC_highBPRturbofan(M_0, theta)
                    output = (0.45 + 0.54*M_0)*sqrt(theta);
               end

               % Estimate TSFC for a low-BPR mixed turbofan engine
               function output = comp_TSFC_lowBPRmixedturbofan(M_0, theta, mil_or_max_power)
                    if (mil_or_max_power == "mil")
                         output = (0.9 + 0.30*M_0)*sqrt(theta);
                    elseif (mil_or_max_power == "max")
                         output = (1.6 + 0.27*M_0)*sqrt(theta);
                    else
                         error("mil_or_max_power - must be 'mil' or 'max'.")
                    end
               end

               % Estimate TSFC for a turbojet engine
               function output = comp_TSFC_turbojet(M_0, theta, mil_or_max_power)
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

               % Compute T at altitude
               function T_alt = compute_thrust_at_altitude(altitude)

               end


               % Extract segment values
               % I REALLY don't like this. This is TOO specialized and would fit
               % better in "missionanalysis" or something.
               function segment_values = get_segment_values(obj, missiondata, mission_segments, wings)
                    AR = wings.Main.AspectRatio;


                    for i=1:length(mission_segments)
                         segment_values.(mission_segments(i)).q = missiondata.(mission_segments(i)).qlbfft2;
                         segment_values.(mission_segments(i)).CD0 = missiondata.(mission_segments(i)).CD0;
                         segment_values.(mission_segments(i)).e = missiondata.(mission_segments(i)).e;
                         % Need alpha, beta
                         % Alpha depends on T_alt/T_SL
                         segment_values.(mission_segments(i)).K1 = 1/(pi*missiondata.(mission_segments(i)).e*AR);
                         segment_values.(mission_segments(i)).K2 = 0;
                         segment_values.(mission_segments(i)).V = missiondata.(mission_segments(i)).Vfts;
                         % segment_values.(mission_segments(i)).alpha =

                    end
               end

               % Get segment names (should probably move this to "utilities")
               function mission_segments = get_segment_names(obj, missiondata)
                    mission_segments = string(missiondata.meta.outerLabels.fields);
               end


               % Estimate engine properties
               function [T_SL_W_TO] = compute_TSL_WTO(obj, W_TO, q, CD0, alpha, beta, n, K_1, K_2, h, V, delta_t, S_ref)
                    % q, CD0, alpha, beta, K_1, K_2, W_TO, S_ref, V)
                    % Using equations from Mattingly
                    % (So-called "Master Equation")
                    % Recall, beta = W_(instant)/W_TO
                    % alpha = T_(instant)/T_SL (T_[instant] is the max thrust
                    % available at that instant)

                    g_0 = 32.2; % Acceleration due to gravity at sea level (ft/s^2)
                    % Some substitutes to shorten the equation
                    A = q.*CD0./alpha;
                    B = q./alpha .* K_1 .* ( (n.*beta)./q).^2;
                    C = K_2 .* n .* beta./alpha;
                    D = beta./alpha .* (1./V) .* delta_t .* (h + (V.^2)./(2.*g_0));

                    T_SL_W_TO = A .* (1./(W_TO./S_ref)) + B .* (W_TO./S_ref) + C + D; % "Master Equation"

               end





          end
     end