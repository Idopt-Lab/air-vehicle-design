classdef F16WeightLevel2 < WeightModelLevel2
     %F16WEIGHTESTLEVEL2 Summary of this class goes here
     %   Detailed explanation goes here
     % This is NOT purely component-level.

     properties
          MTOW
          OEW
          OEW_frac
          wings
          HT
          VT
          fuselage
          landinggear
          engine
          W_TO
          total_fuel_used
          fuel_fraction
          W_TO_guess
          W_fixed
          K_vs
     end

     methods
          % Constructor
          function obj = F16WeightLevel2()

          end

          function OEW = get_OEW(weight_obj, aircraft_type, W_TO, W0, AR, T, S_ref_w, M_max, K_vs)
               OEW = WeightLevel2.get_OEW(aircraft_type, W_TO, W0, AR, T, S_ref_w, M_max, K_vs);
          end

          function W_wings = get_wing_weight(weight_obj, aircraft_type, S_exposed_planform)
               W_wings = WeightLevel2.estimate_mainwing_weight(aircraft_type, S_exposed_planform);
          end

          function W_HT = get_HT_weight(weight_obj, aircraft_type, S_exposed_planform)
               W_HT = WeightLevel2.estimate_HT_weight(aircraft_type, S_exposed_planform);
          end

          function W_VT = get_VT_weight(weight_obj, aircraft_type, S_exposed_planform)
               W_VT = WeightLevel2.estimate_VT_weight(aircraft_type, S_exposed_planform);
          end

          function W_fuselage = get_fuselage_weight(weight_obj, aircraft_type, S_wet)
               W_fuselage = WeightLevel2.estimate_fuselage_weight(aircraft_type, S_wet);
          end

          function W_landinggear = get_landinggear_weight(weight_obj, aircraft_type, isnavy, W_TO)
               W_landinggear = WeightLevel2.estimate_landinggear_weight(aircraft_type, isnavy, W_TO);
          end

          function W_eng_installed = get_eng_installed_weight(weight_obj, aircraft_type, engine_weight)
               W_eng_installed = WeightLevel2.estimate_W_eng_installed(aircraft_type, engine_weight);
          end
     end
end