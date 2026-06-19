classdef F16WeightLevel3 < WeightModelLevel3
     %F16WEIGHTESTLEVEL4 Summary of this class goes here
     %   Detailed explanation goes here
     % THIS SHOULD GET THE OEW AND SUCH

     properties
          MTOW
          OEW
          OEW_frac
          wings
          tail
          fuselage
          strakes
          subsystems
          avionics
          fuel_pumps
          engine
          landinggear
          W_TO_guess = 45000
          W_TO
          W_fixed
          total_fuel_used
          fuel_fraction
          weight_coefficients
          eps % Error tolerance
          K_vs
     end

     methods
          % Constructor
          function obj = F16WeightLevel3(design)
               obj.W_fixed = design.weights.Weights.Fixedlbf;
               obj.weight_coefficients = design.weights.Coefficients;
          end

          
          % Estimate subsystem weight
          function output = get_subsystem_weight(weight_obj, propulsion_obj, design, requirements_obj)
               % Need W_TO
               propulsion_obj.get_propulsion_stats(requirements_obj, design);
               weight_obj.subsystems = weight_obj.subsystem_weight_III(design.weights, weight_obj.W_TO, propulsion_obj.T0, weight_obj.engine.W_installed);
               output = weight_obj.subsystems;
          end

          % Estimate engine weight (installed)
          function output = get_engine_weight(weight_obj, propulsion_obj, requirements_obj)
               propulsion_obj.enginestats = propulsion_obj.get_engine_stats(propulsion_obj.T_SL_wet, requirements_obj.requirements.MaxMach.Mach, propulsion_obj.BPR, "Y");
               engine = WeightLevel3.compute_engine_installed_weight(propulsion_obj.T0);
               engine.W_installed = 1.3*engine.W_total;
               output = engine;
          end

          % Estimate OEW
          function output = get_OEW(weight_obj, propulsion_obj, design, geometry_obj, W_TO, requirements_obj)
               propulsion_obj.enginestats = propulsion_obj.get_engine_stats(propulsion_obj.T_SL_wet, requirements_obj.requirements.MaxMach.Mach, propulsion_obj.BPR, "Y");
               weight_obj.engine = weight_obj.get_engine_weight(propulsion_obj, requirements_obj);
               weight_obj.OEW = weight_obj.compute_OEW(W_TO, geometry_obj, design.weights, propulsion_obj.T0); % Really this gets the empty weight of the design (wings, fuselage, subsystems)
               output = weight_obj.OEW;
          end

          % Get OEW
          function OEW = compute_OEW(weight_obj, W_TO, geometry_obj, DesignTable_weight, T0)
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

               % Control surfaces' planform areas
               Scs_w = 69; % (fT) Hardcoded for now
               Scs_ht = geometry_obj.HT.S_ref; % All-moving horizontal stabilizer
               Scs_vt = 50;

               % Spans (ft)
               b_w = geometry_obj.mainwings.b;
               b_strakes = geometry_obj.strakes.b;
               b_ht = geometry_obj.HT.b;
               b_vt = geometry_obj.VT.b;

               % Leading edge sweep (deg)
               LEsweep_w = geometry_obj.mainwings.LE_sweep;
               LEsweep_strakes = geometry_obj.strakes.LE_sweep;
               LEsweep_ht = geometry_obj.HT.LE_sweep;
               LEsweep_vt = geometry_obj.VT.LE_sweep;

               % Thickness-to-chord ratios (dimensionless)
               tc_w = geometry_obj.mainwings.tc;
               tc_strakes = geometry_obj.strakes.tc;
               tc_ht = geometry_obj.HT.tc;
               tc_vt = geometry_obj.VT.tc;

               % Taper ratios (dimensionless)
               lambda_w = geometry_obj.mainwings.lambda;
               lambda_strakes = geometry_obj.strakes.lambda;
               lambda_vt = geometry_obj.VT.lambda;
               lambda_ht = geometry_obj.HT.lambda;

               % Quarter-chord sweep angled (deg)
               LambdaQc_w = geometry_obj.mainwings.QC_sweep;
               LambdaQc_vt = geometry_obj.VT.QC_sweep;
               LambdaQc_ht = geometry_obj.HT.QC_sweep;

               % Fuselage dimensions (ft)
               L = geometry_obj.fuselage.L; % Length
               D = geometry_obj.fuselage.W_max; % Max diameter
               H_max = geometry_obj.fuselage.h_max; % Max height
               W = geometry_obj.fuselage.W_max; % Max width

               % Misc coefficients 
               Kvs = DesignTable_weight.Coefficients.Kvs;
               Kdw = DesignTable_weight.Coefficients.Kdw;
               Fw = DesignTable_weight.Coefficients.Kdw;
               Krht = DesignTable_weight.Coefficients.Krht;
               Ht = DesignTable_weight.Coefficients.Ht;
               Hv = DesignTable_weight.Coefficients.Hv;
               M = DesignTable_weight.Coefficients.M;
               Lt = DesignTable_weight.Coefficients.Lt;
               Sr = DesignTable_weight.Coefficients.Sr;
               HtHv = DesignTable_weight.Coefficients.HtHv;
               Kdwf = DesignTable_weight.Coefficients.Kdwf;

               % Sub-functions for handling component weights. Estimates.
               % Equations: Raymer, 6th edition, section 15.3.1. Fighter/Attack jet.
               OEW.W_Wing = WeightLevel3.wing_weight_III(W_TO, Nz, Sref_w, AR_w, tc_w, lambda_w, LambdaQc_w, Scs_w, Kdw, Kvs);
               OEW.W_strakes = WeightLevel3.wing_weight_III(W_TO, Nz, Sref_strakes, AR_strakes, tc_strakes, lambda_strakes, LEsweep_strakes, 0, Kdw, Kvs);
               [OEW.W_HT, OEW.W_VT] = WeightLevel3.tail_weight_III(Fw, b_ht, W_TO, Nz, Sref_ht, Krht, Ht, Hv, Sref_vt, M, Lt, Sr, AR_vt, lambda_vt, LambdaQc_vt, HtHv);
               OEW.W_tail = OEW.W_HT + OEW.W_VT;
               OEW.W_fuselage = WeightLevel3.fuselage_weight_III(Kdwf, W_TO, Nz, L, D, W);
               OEW.W_subsystems = WeightLevel3.subsystem_weight_III(DesignTable_weight, W_TO, T0, weight_obj.engine.W_installed);
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