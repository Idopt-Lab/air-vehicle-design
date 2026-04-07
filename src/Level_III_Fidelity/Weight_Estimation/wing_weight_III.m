function [weight] = wing_weight_III(Density, S_ref)
%WING_WEIGHT_III Summary of this function goes here
%   Detailed explanation goes here

% Taken from aircraft design metabook, table 

weight = Density * S_ref;

end