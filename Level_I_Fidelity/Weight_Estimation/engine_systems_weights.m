function [W_eng_sys] = engine_systems_weights(N_en, T, N_z, W_en, D_e, L_sh, L_ec, T_e)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

W_engine_mounts = 0.013*N_en^(0.795) * T^(0.579) * N_z;

W_engine_section = 0.01*W_en^(0.717) * N_en * N_z;

W_engine_cooling = 4.55*D_e*L_sh*N_en;

W_oil_cooling = 37.82*N_en^(1.008)*L_ec^(0.222);

W_starter_pneumatic = 0.025*T_e^(0.760)*N_en^(0.72);

W_eng_sys = W_engine_mounts + W_engine_section + W_engine_cooling + W_oil_cooling + W_starter_pneumatic;

end