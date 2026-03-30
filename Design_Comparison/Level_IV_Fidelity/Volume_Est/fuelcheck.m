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