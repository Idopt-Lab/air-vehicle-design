%% Written by Casey Chamberlain
% 02/19/2026

%% TAIL SIZING
% Sizes the tail of an aircraft given some design parameters.
% Uses work from Raymer.
% ASSUMES A TRADITIONAL TAIL (NON V-TAIL)

%% Arguments
% c_VT - Tabulated
% c_HT - Tabulated (should be from excel file)

function [S_ht, S_vt] = Tail_Sizing(c_VT, c_HT, b_W, S_W, L_fus, Cbar_W)

% Assuming tail located 90% down fuselage
L_VT = L_fus*0.8;
L_HT = L_fus*0.8; % Allow operator to adjust this, later.

S_vt = c_VT*b_W*S_W/L_VT; % eq 6.28, 2nd edition

S_ht = c_HT*Cbar_W*S_W/L_HT; % eq 6.29, 2nd edition

end