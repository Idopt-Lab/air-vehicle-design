classdef SubsystemsLevel3 < SubsystemsModelLevel3
     %SUBSYSTEMSLEVEL3 Summary of this class goes here
     %   Detailed explanation goes here

     properties
          internal_volume % gal
          fuel_volume % gal
     end

     methods
          function obj = SubsystemsLevel3(geometry_obj, weight_obj, design)
               %SUBSYSTEMSLEVEL3 Construct an instance of this class
               %   Detailed explanation goes here
               fuel_weight = weight_obj.total_fuel_used;
               obj.internal_volume = obj.get_internal_volume(geometry_obj, design);
               fuel_type = design.general.fuel_type;
               obj.fuel_volume = obj.get_fuel_volume(fuel_weight, fuel_type);
          end

          function output = get_internal_volume(subsys_obj, geometry_obj, design)
               A_top = design.geom.fuselage.Fuselage.Areatopft2;
               A_side = design.geom.fuselage.Fuselage.Areasideft2;
               L = geometry_obj.fuselage.L;
               internal_vol.fuselage_vol = subsys_obj.compute_fuselage_vol(A_top, A_side, L);

               tc_tip = geometry_obj.mainwings.tc;
               c_tip = geometry_obj.mainwings.tip_chord;
               c_root = geometry_obj.mainwings.c_root;
               S_ref = geometry_obj.mainwings.S_ref;
               internal_vol.wing_vol = subsys_obj.compute_wing_vol(tc_tip, tc_tip, c_tip, c_root, S_ref);

               internal_vol.total = internal_vol.fuselage_vol + internal_vol.wing_vol;

               subsys_obj.internal_volume = internal_vol;

               output = internal_vol.total;
          end

          % Estimate avionics volume occupation
          function output = compute_avionics_volume(subsys_obj, avionics)
               % Estimate the total volume occupied by the avionics
          end

          % ADD FUEL VOLUME CHECK
          function output = checkfuelvol(subsys_obj, internal_vol, fuel_vol)
               % Determine if there's enough space inside the vehicle for
               % fuel (account for avionics occupation)
               if (internal_vol < fuel_vol)
                    IsSufficientFuelVolume = False;
               elseif (internal_vol >= fuel_vol)
                    IsSufficientFuelVolume = True;
               else
                    error("Error handler.")
               end
               output = IsSufficientFuelVolume;
          end

          function [fuselage_vol] = compute_fuselage_vol(subsys_obj, A_top, A_side, L)
               %FUSELAGE_VOL_III Summary of this function goes here
               fuselage_vol = 3.4*((A_top)*(A_side))/(4*L); % ft^3 (Raymer, eq 7.14, 6th ed)

               % Compute mission fuel volume (assuming jp-4 or something)
               fuselage_vol = fuselage_vol*7.48051948; % Convert ft^3 to gallons
          end


          function [MFV] = compute_wing_vol(subsys_obj, tc_tip, tc_root, c_tip, c_root, S_ref)
               %WING_VOLUME_IV Summary of this function goes here

               t_avg = 0.7 * (c_tip * tc_tip + c_root * tc_root)/2; % ft

               MFV = 0.3*S_ref*t_avg; % ft^3

          end

          function output = get_fuel_volume(subsys_obj, fuel_weight, fuel_type)
               fuel_density = subsys_obj.get_fuel_density(fuel_type);
               fuel_required_vol = fuel_weight/fuel_density;
               output = fuel_required_vol;
          end

          function output = get_fuel_density(subsys_obj, fuel_type)
               if (fuel_type == "JP-4")
                    fuel_density = 6.47;
               else
                    error("Couldn't identify fuel type.")
               end
               output = fuel_density;
          end


          function [fuelresults] = fuelcheck(Designgeo_fuselage, fuel_weight, geometry_wings, Weight_Results)
               %FUELCHECK - Checks if design can physically carry estimated fuel amount
               % Estimates internal volume

               % Estimate mission fuel volume
               fuel_required_vol = fuel_weight/6.47;

               fuselage_vol = fuselage_vol_III(Designgeo_fuselage.Fuselage("Area (top) (ft^2)"), Designgeo_fuselage.Fuselage("Area (side) (ft^2)"), Designgeo_fuselage.Fuselage("Length (ft)")); % gal
               fuselage_vol = fuselage_vol*(6.47); % jp-4 is 6.47 lbf/gal


               % Check wing volume
               tc_tip = geometry_wings.Main("t/c");
               tc_root = geometry_wings.Main("t/c");
               c_tip = geometry_wings.Main("Tip chord length (ft)");
               c_root = geometry_wings.Main("Root chord length (ft)");
               S_ref = Weight_Results.S_ref;
               wing_vol = wing_volume_III(tc_tip, tc_root, c_tip, c_root, S_ref)*7.48051948; % Estimate wing fuel tank vol and convert to gal

               % compute wing fuel weight
               wing_vol = wing_vol*6.47;

               % Should definitely account for volume occupied by avionics & engines


               % Compute total internal volume / fuel volume

               fuelresults.fuel_required = fuel_required_vol;
               fuelresults.internalvolume = fuselage_vol + wing_vol;

          end
     end
end