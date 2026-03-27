function [fuselage_vol] = fuselage_vol_III(A_top, A_side, L)
%FUSELAGE_VOL_III Summary of this function goes here
fuselage_vol = 3.4*((A_top)*(A_side))/(4*L); % ft^3 (Raymer, eq 7.14, 6th ed)

% Compute mission fuel volume (assuming jp-4 or something)
fuselage_vol = fuselage_vol*7.48051948; % Convert ft^3 to gallons
end