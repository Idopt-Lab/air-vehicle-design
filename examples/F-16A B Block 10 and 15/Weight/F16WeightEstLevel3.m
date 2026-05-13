classdef F16WeightEstLevel3 < WeightLevel3
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
          MTOW
          OEW
          wings
          tail
          strakes
          subsystems
          engine
          landinggear
          W_TO_guess = 45000
          W_TO
          W_fixed
          total_fuel_used
          fuel_fraction
          weight_coefficients
          eps % Error tolerance
     end

     methods
          % Constructor
          function obj = F16WeightEstLevel3(design)
               obj.W_fixed = design.weights.Weights.Fixedlbf;
               obj.weight_coefficients = design.weights.Coefficients;
          end

          
          % Estimate subsystem weight
          function output = get_subsystem_weight(weight_obj, mission_obj, propulsion_obj, design)
               % Need W_TO
               propulsion_obj.get_propulsion_stats(mission_obj, design);
               weight_obj.subsystems = weight_obj.subsystem_weight_III(design.weights, weight_obj.W_TO, propulsion_obj.T0, weight_obj.engine.W_installed);
          end

          % Estimate engine weight (installed)
          function output = get_engine_weight(weight_obj, propulsion_obj, mission_obj, design)
               propulsion_obj.enginestats = propulsion_obj.get_propulsion_stats(mission_obj, design);
               weight_obj.engine = weight_obj.compute_engine_installed_weight(propulsion_obj.T0);
               weight_obj.engine.installed = 1.3*weight_obj.engine.W_total;
               output = weight_obj.engine.W_total;
          end

          % Estimate OEW
          function output = get_OEW(weight_obj, propulsion_obj, mission_obj, design, geometry_obj, W_TO)
               propulsion_obj.enginestats = propulsion_obj.get_propulsion_stats(mission_obj, design);
               get_engine_weight(weight_obj, propulsion_obj, mission_obj, design);
               weight_obj.OEW = compute_OEW_III(weight_obj, W_TO, geometry_obj); % Really this gets the empty weight of the design (wings, fuselage, subsystems)
               output = weight_obj.OEW;
          end

          % Get OEW
          function OEW = compute_OEW_III(weight_obj, W_TO, geometry_obj)
               % S_ref, S_HT, S_VT, S_wet, T0, DesignTable_weight, W_engine_installed, geometry_obj)
               %COMPUTE_OEW Summary of this function goes here
               %   Detailed explanation goes here
               % Ref area should be EXPOSED planform area!

               % Using Raymer, 6th edition, section 15.3.1 equations for component
               % weights.

               Nz = DesignTable_weight.Coefficients.Nz;
               AR_w = geometry_obj.mainwings.AR;
               AR_strakes = geometry_obj.strakes.AR;
               AR_ht = geometry_obj.HT.AR;
               AR_vt = geometry_obj.VT.AR;

               Sref_w = geometry_obj.mainwings.S_ref;
               Sref_strakes = geometry_obj.strakes.S_ref;
               Sref_ht = geometry_obj.HT.S_ref;
               Sref_vt = geometry_obj.VT.S_ref;

               b_w = geometry_obj.mainwings.b;
               b_strakes = geometry_obj.strakes.b;
               b_ht = geometry_obj.HT.b;
               b_vt = geometry_obj.VT.b;

               LEsweep_w = geometry_obj.mainwings.LE_sweep;
               LEsweep_strakes = geometry_obj.strakes.LE_sweep;
               LEsweep_ht = geometry_obj.HT.LE_sweep;
               LEsweep_vt = geometry_obj.VT.LE_sweep;

               tc_w = geometry_obj.mainwings.tc;
               tc_strakes = geometry_obj.strakes.tc;
               tc_ht = geometry_obj.HT.tc;
               tc_vt = geometry_obj.VT.tc;

               lambda_w = geometry_obj.mainwings.lambda;
               lambda_vt = geometry_obj.VT.lambda;
               lambda_ht = geometry_obj.HT.lambda;

               L = geometry_obj.fuselage.L;
               D = geometry_obj.fuselage.W_max;
               H_max = geometry_obj.fuselage.h_max;
               W = geometry_obj.fuselage.W_max;

               Kvs = DesignTable_weight.Coefficients.Kvs;

               % Sub-functions for handling component weights. Estimates.
               % Equations: Raymer, 6th edition, section 15.3.1. Fighter/Attack jet.
               OEW.W_Wing = WeightLevel3.wing_weight_III(W_TO, Nz, S_ref, DesignTable_weight.Coefficients.AR, DesignTable_weight.Coefficients.tc, DesignTable_weight.Coefficients.lambda_w, DesignTable_weight.Coefficients.LambdaQc, DesignTable_weight.Coefficients.Scsw, DesignTable_weight.Coefficients.Kdw, DesignTable_weight.Coefficients.Kvs);
               OEW.W_strakes = WeightLevel3.wing_weight_III(W_TO, Nz, geometry_obj.strakes.S_ref, geometry_obj.strakes.AR, geometry_obj.strakes.tc, geometry_obj.strakes.lambda, geometry_obj.strakes.LE_sweep, 0, DesignTable_weight.Coefficients.Kdw, DesignTable_weight.Coefficients.Kvs);
               OEW.W_tail = WeightLevel3.tail_weight_III(DesignTable_weight.Coefficients.Fw, b_ht, W_TO, DesignTable_weight.Coefficients.Nz, S_HT, DesignTable_weight.Coefficients.Krht, DesignTable_weight.Coefficients.Ht, DesignTable_weight.Coefficients.Hv, S_VT, DesignTable_weight.Coefficients.M, DesignTable_weight.Coefficients.Lt, DesignTable_weight.Coefficients.Sr, AR_vt, lambda_vt, DesignTable_weight.Coefficients.LambdaQc, DesignTable_weight.Coefficients.HtHv);
               OEW.W_fuselage = WeightLevel3.fuselage_weight_III(DesignTable_weight.Coefficients.Kdwf, W_TO, Nz, L, D, W);
               OEW.W_subsystems = WeightLevel3.subsystem_weight_III(DesignTable_weight, W_TO, T0, W_engine_installed);
               % weight_obj.engine.W_engine_installed =
               % 1.3*Engine_Sizing(T0);

               % OEW = W_Wing + W_tail + W_fuselage + W_subsystems + W_extra; % sum the weights
               weight_obj.wings = OEW.W_Wing;
               weight_obj.tail = OEW.W_tail;
               weight_obj.fuselage = OEW.W_fuselage;
               weight_obj.subsystems = OEW.W_subsystems;
               weight_obj.strakes = OEW.W_strakes;
               OEW.total = OEW.W_Wing + OEW.W_strakes + OEW.W_tail + OEW.W_fuselage + OEW.W_subsystems.total;
          end


     end


     %% ------------------------------------------------------------


     methods (Access = private)

     end

end