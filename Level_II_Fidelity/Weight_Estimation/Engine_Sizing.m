%% Written by Casey Chamberlain
% 02/19/2026
%
% Estimates engine weight based on thrust required of it.

function [Eng_Weight] = Engine_Sizing(Thrust)

W_dry = 0.521*Thrust^0.9;
W_oil = 0.082*Thrust^0.65;
W_rev = 0.034*Thrust;
W_control = 0.26*Thrust^0.5;
W_start = 9.33*(W_dry/1000)^1.078;

Eng_Weight = W_dry + W_oil + W_rev + W_control + W_start;

end