function [MFV] = wing_volume_III(tc_tip, tc_root, c_tip, c_root, S_ref)
%WING_VOLUME_IV Summary of this function goes here

t_avg = 0.7 * (c_tip * tc_tip + c_root * tc_root)/2; % ft

MFV = 0.3*S_ref*t_avg; % ft^3

end