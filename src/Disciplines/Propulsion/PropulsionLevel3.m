classdef PropulsionLevel3 < PropulsionModelLevel3
     %UNTITLED Summary of this class goes here
     %   Detailed explanation goes here

     properties
          enginestats
          TSFC
          T0
     end

     methods

          % Constructor
          function obj = PropulsionLevel3(requirements_obj, design)
               obj.enginestats = get_propulsion_stats(obj, requirements_obj, design);
          end

          % Estimate engine properties
          function enginestats = get_propulsion_stats(propulsion_obj, requirements_obj, design)
               enginestats = get_engine_stats(propulsion_obj, design.propulsion.ThrustseaLevellbf.Dry, requirements_obj.requirements.MaxMach.Mach, design.propulsion.BypassRatio.BypassRatio, design.general.isafterburning);
               % There are multiple versions of equations (afterburning,
               % nonafterburning). Consider adding those, too.
               % Also I need to stop using the tables for value extraction
               % since they take up SO MUCH VISUAL SPACE!!!
          end

          % Estimate engine properties
          function output = get_engine_stats(propulsion_obj, T, M, BPR, isafterburning)
               if (isafterburning == "Y")
                    output = propulsion_obj.compute_eng_stats_ab(T, M, BPR);
               elseif (isafterburning == "N")
                    output = propulsion_obj.compute_eng_stats_noab(T, M, BPR);
               else
                    error ("Couldn't determine if engine is/isn't afterburning. Accepted states: 'Y', 'N'.")
               end
          end

          % Scale engine
          function output = scale_engine(propulsion_obj, L_actual, D_actual, W_actual, T_actual, T_required)
               eng_scale.SF = T_actual/T_required;
               eng_scale.L = L_actual*SF^(0.4); % Raymer, 6th ed, eq 10.1
               eng_scale.D = D_actual*SF^(0.5); % Raymer, 6th ed, eq 10.2
               eng_scale.W = W_actual*SF^(1.1); % Raymer, 6th ed, eq 10.3

               output = eng_scale;
          end

          % Compute TSFC
          function output = get_TSFC(propulsion_obj
     end

     methods (Access = private)


          % Estimate engine properties (AFTERBURNING ENGINE, IMPERIAL
          % UNITS)
          function [enginestats] = compute_eng_stats_ab(propulsion_obj, T, M, BPR)
               % Using equations from Raymer 6th edition, chapter 10, p 285, eq 10.4 ->
               % 10.15

               % ARGUMENTS
               % W = Weight (lbf)
               % T = Takeoff thrust (lbf)
               % BPR = Bypass ratio
               % M = Mach number

               % Afterburning engines (imperial units)
               W = @(T, M, BPR) (0.063*T^(1.1)*M^(0.25)*exp(-0.81*BPR)); % Engine weight (lbf) (eq 10.10, 6th ed) (IDK if this is "installed weight")
               L = @(T, M) (0.255*T^(0.4)*M^(0.2)); % Engine length (ft) (eq 10.11, 6th ed)
               D = @(T, BPR) (0.024*T^(0.5)*exp(0.04*BPR)); % Engine diameter (ft) (eq 10.12, 6th ed)
               SFC_maxT = @(BPR) (2.1*exp(-0.12*BPR)); % SFC at max thrust (1/hr) (eq 10.13, 6th ed)
               T_cruise = @(T, BPR) (2.4*T^(0.74)*exp(0.023*BPR)); % Cruise thrust (lbf) (eq 10.14, 6th ed)
               SFC_cruise = @(BPR) (1.04*exp(-0.186*BPR)); % SFC at cruise conditions (1/hr) (eq 10.15, 6th ed)

               enginestats.W = W(T, M, BPR);
               enginestats.L = L(T, M);
               enginestats.D = D(T, BPR);
               enginestats.SFC_maxT = SFC_maxT(BPR)*(1/3600);
               enginestats.T_cruise = T_cruise(T, BPR);
               enginestats.SFC_cruise = SFC_cruise(BPR)*(1/3600);
          end

          % Estimate engine properties (NONAFTERBURNING ENGINE, IMPERIAL
          % UNITS)
          function [enginestats] = compute_eng_stats_noab(propulsion_obj, T, M, BPR)
               % Using equations from Raymer 6th edition, chapter 10, p 285, eq 10.4 ->
               % 10.15

               % ARGUMENTS
               % W = Weight (lbf)
               % T = Takeoff thrust (lbf)
               % BPR = Bypass ratio
               % M = Mach number

               % Nonafterburning engines (imperial units)
               W = @(T, BPR) (0.084*T^(1.1)*exp(-0.045*BPR)); % Engine weight (lbf) (eq 10.4, 6th ed)
               L = @(T, M) (0.185*T^(0.4)*M^(0.2)); % Engine length (ft) (eq 10.5, 6th ed)
               D = @(T, BPR) (0.033*T^(0.5)*exp(0.04*BPR)); % Engine diameter (ft) (eq 10.6, 6th ed)
               SFC_maxT = @(BPR) (0.67*exp(-0.12*BPR)); % SFC at max thrust (1/hr) (eq 10.7, 6th ed)
               T_cruise = @(T, BPR) (0.60*T^(0.9)*exp(0.02*BPR)); % Cruise thrust (lbf) (eq 10.8, 6th ed)
               SFC_cruise = @(BPR) (0.88*exp(-0.05*BPR)); % SFC at cruise conditions (1/hr) (eq 10.9, 6th ed)

               enginestats.W = W(T, BPR);
               enginestats.L = L(T, M);
               enginestats.D = D(T, BPR);
               enginestats.SFC_maxT = SFC_maxT(BPR)*(1/3600);
               enginestats.T_cruise = T_cruise(T, BPR);
               enginestats.SFC_cruise = SFC_cruise(BPR)*(1/3600);
          end


     end
end