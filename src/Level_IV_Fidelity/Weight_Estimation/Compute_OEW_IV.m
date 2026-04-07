function [OEW] = Compute_OEW_IV(W_TO, S_ref, S_HT, S_VT, S_wet, T0, DesignTable_weight, c_HT, c_VT, W_engine_installed)
%COMPUTE_OEW Summary of this function goes here
%   Detailed explanation goes here
% Ref area should be EXPOSED planform area!
% W_Wing = WingDensity * S_ref; % Replace with new wing weight model (accepts arguments of AR and e and other stuff)
% N_z = 9.0; % Ultimate load factor
% tc_root = 0.4; % Thickness-to-chord ratio, root
% Lambda_qc = 0.2275; % taper ratio of quarter chord
% S_csw = 150; % Surface area of control surfaces (FIGURE THIS OUT <<<<<<<<<<<<<<<<<<<<<)

% Using Raymer, 6th edition, section 15.3.1 equations for component
% weights.

% Sub-functions for handling component weights. Estimates.
% Equations: Raymer, 6th edition, section 15.3.1. Fighter/Attack jet.
W_Wing = wing_weight_IV(W_TO, DesignTable_weight{"Nz",2}, S_ref, DesignTable_weight{"AR", 2}, DesignTable_weight{"t/c",2}, DesignTable_weight{"lambda_w",2}, DesignTable_weight{"Lambda qc",2}, DesignTable_weight{"Scsw",2}, DesignTable_weight{"Kdw",2}, DesignTable_weight{"Kvs",2});
W_tail = tail_weight_IV(DesignTable_weight{"Fw",2}, DesignTable_weight{"Bh",2}, W_TO, DesignTable_weight{"Nz",2}, S_HT, DesignTable_weight{"Krht",2}, DesignTable_weight{"Ht",2}, DesignTable_weight{"Hv",2}, S_VT, DesignTable_weight{"M",2}, DesignTable_weight{"Lt",2}, DesignTable_weight{"Sr",2}, DesignTable_weight{"Arv",2}, DesignTable_weight{"lambda_vt",2}, DesignTable_weight{"Lambda qc",2});
W_fuselage = fuselage_weight_IV(DesignTable_weight{"Kdwf",2}, W_TO, DesignTable_weight{"Nz",2}, DesignTable_weight{"L",2}, DesignTable_weight{"D",2}, DesignTable_weight{"W",2});
W_subsystems = subsystem_weight_IV(DesignTable_weight, W_TO, T0, W_engine_installed);
% W_engine_installed = 1.3*Engine_Sizing(T0);

% OEW = W_Wing + W_tail + W_fuselage + W_subsystems + W_extra; % sum the weights
OEW = W_Wing + W_tail + W_fuselage + W_subsystems;
end