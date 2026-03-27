function [W_tail] = tail_weight_IV(F_w, B_h, W_dg, N_z, S_ht, K_rht, H_t, H_v, S_vt, M, L_t, S_r, A_vt, lambda, Lambda_VT)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

W_HT = 3.316*(1 + F_w/B_h)^(-2.0) * ((W_dg * N_z)/(1000))^(0.260) * S_ht^(0.806); % eq 15.2, 6th edition

W_VT = 0.452*K_rht*(1 + H_t/H_v)^(0.5) * (W_dg*N_z)^(0.488)*S_vt^(0.718)*M^(0.341) * L_t^(-1.0)*(1+S_r/S_vt)^(0.348)*A_vt^(0.223) * (1+lambda)^(0.25)*cos(Lambda_VT*pi/180)^(-0.323); % eq 15.3, 6th edition

W_tail = W_HT + W_VT;

end