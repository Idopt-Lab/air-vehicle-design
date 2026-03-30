function [W_fuselage] = fuselage_weight_IV(K_dwf, W_dg, N_z, L, D, W)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);

W_fuselage = 0.499 * K_dwf * W_dg^(0.35) * N_z^(0.25) * L^(0.5) * D^(0.849) * W^(0.685); % eq 15.4, 6th ed

end