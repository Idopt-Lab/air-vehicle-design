function [W_landinggear] = landinggear(K_cb, K_tpg, W_l, N_l, L_m, N_nw, L_n)
% THIS IIS WHERE SOME MAGIC HAPPENS LOL

W_main_gear = K_cb*K_tpg * (W_l * N_l)^(0.25) * L_m^(0.973);

W_nose_gear = (W_l * N_l)^(0.290) * L_n^(0.5) * N_nw^(0.525);

W_landinggear = W_main_gear + W_nose_gear;
end