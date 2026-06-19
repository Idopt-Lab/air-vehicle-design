function [OEW] = Compute_OEW_I(W_TO)
%COMPUTE_OEW Summary of this function goes here

a = 2.34;
b = -0.13;

OEW_frac = a*W_TO^b;

OEW = OEW_frac*W_TO;


end