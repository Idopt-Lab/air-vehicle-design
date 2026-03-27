%% Written by Casey Chamberlain
% 02/19/2026
%
% Estimates engine weight based on thrust required of it.
% Equations taken from "Aircraft Design Metabook," J.R.R.A. Martins

function [Eng_Weight] = Engine_Sizing(Thrust)

W_dry = 0.521*Thrust^0.9; % eq 7.13
W_oil = 0.082*Thrust^0.65; % eq 7.14
W_rev = 0.034*Thrust; % eq 7.15
W_control = 0.26*Thrust^0.5; % eq 7.16
W_start = 9.33*(W_dry/1000)^1.078; % eq 7.17 (7.18?) (Technically Roskam)

Eng_Weight = W_dry + W_oil + W_rev + W_control + W_start;

end