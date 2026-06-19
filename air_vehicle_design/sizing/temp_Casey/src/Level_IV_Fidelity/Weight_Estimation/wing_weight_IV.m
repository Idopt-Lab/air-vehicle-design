function [W_wing] = wing_weight_IV(W_dg, N_z, S_w, AR, tc_root, lambda, Lambda_qc, S_csw, K_dw, K_vs)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% W_wing = 0.0051*(W_dg * N_z)^(0.557)*(S_w^(0.649))*(AR^(0.5))*(tc_root)^(-0.4)*(1+lambda)^(0.1)*(cos(Lambda_qc))^(-1)*S_csw^(0.1);

W_wing = 0.0103*K_dw*K_vs*(W_dg*N_z)^(0.5)*S_w^(0.622)*AR^(0.785)*(tc_root) * (1+lambda)^(0.05)*cos(Lambda_qc)^(-1.0)*S_csw^(0.04); % eq 15.1

end