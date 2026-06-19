function [OEW] = Compute_OEW_II(W_TO, S_ref, T0, AR)
%COMPUTE_OEW Summary of this function goes here


K_vs = 1.0;
M_max = 1.6;
a = -0.02;
b = 2.16;
c1 = -0.1;
c2 = 0.2;
c3 = 0.04;
c4 = -0.1;
c5 = 0.08;

OEW = W_TO * (a + b*W_TO^(c1)*AR^(c2)*(T0/W_TO)^(c3)*(W_TO/S_ref)^(c4)*M_max^(c5))*K_vs;


end