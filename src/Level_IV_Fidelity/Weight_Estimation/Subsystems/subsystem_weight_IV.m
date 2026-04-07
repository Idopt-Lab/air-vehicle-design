function [W_subsystems] = subsystem_weight_IV(DesignTable_weight, W_TO, T0, W_engine_installed)
% THIS CALCULATES THE TOTAL WEIGHT OF ALL SUBSYSTEMS
% Need to extract required information simply without spaghettifying the code.

W_landinggear = landinggear(DesignTable_weight{"Kcb",2}, DesignTable_weight{"Ktpg",2}, DesignTable_weight{"Wl",2}, DesignTable_weight{"Nl",2}, DesignTable_weight{"Lm",2}, DesignTable_weight{"Nnw",2}, DesignTable_weight{"Ln",2});

W_engine_systems = engine_systems_weights(DesignTable_weight{"Nen",2}, T0, DesignTable_weight{"Nz",2}, W_engine_installed, DesignTable_weight{"De",2}, DesignTable_weight{"Lsh",2}, DesignTable_weight{"Lec",2}, T0);

W_firewall = 1.13*DesignTable_weight{"Sfw",2}; % eq 15.8, 6th ed

W_air_induction_system = 13.29 * DesignTable_weight{"Kvg",2} *DesignTable_weight{"Ld",2}^(0.643) * DesignTable_weight{"Kd",2}^(0.182) *DesignTable_weight{"Nen",2}^(0.1498) * (DesignTable_weight{"Ls",2}/DesignTable_weight{"Ld",2})^(-0.373) * DesignTable_weight{"De",2};
% eq 15.10, 6th ed

W_tailpipe = 3.5*DesignTable_weight{"De",2}*DesignTable_weight{"Ltp",2}*DesignTable_weight{"Nen",2};
% eq 15.11, 6th ed

W_fuelsystem_and_tanks = 7.45*DesignTable_weight{"Vt",2}^(0.47)*(1 + DesignTable_weight{"Vi",2}/DesignTable_weight{"Vt",2})^(-0.095) * (1 + DesignTable_weight{"VP",2}/DesignTable_weight{"Vt",2})*DesignTable_weight{"Nt",2}^(0.066) * DesignTable_weight{"Nen",2}^(0.052) * (T0 *DesignTable_weight{"SFC",2}/1000)^(0.249);
% eq 15.16, 6th ed

W_flight_controls = 36.28*DesignTable_weight{"M",2}^(0.003) * DesignTable_weight{"Scs",2}^(0.489) * DesignTable_weight{"Ns",2}^(0.484) * DesignTable_weight{"Nc",2}^(0.127);
% eq 15.17, 6th ed

W_instruments = 8.0 + 36.37*DesignTable_weight{"Nen",2}^(0.676) * DesignTable_weight{"Nt",2}^(0.237) +26.4*(1 + DesignTable_weight{"Nci",2})^(1.356);
% eq 15.18, 6th ed

W_hydraulics = 37.23 * DesignTable_weight{"Kvsh",2} * DesignTable_weight{"Nu",2}^(0.664);
% eq 15.19, 6th ed

W_electrical = 172.2 *DesignTable_weight{"Kmc",2} * DesignTable_weight{"Rkva",2}^(0.152) * DesignTable_weight{"Nc",2}^(0.10) * DesignTable_weight{"La",2}^(0.10) * DesignTable_weight{"Ngen",2}^(0.091);
% eq 15.20, 6th ed

W_avionics = 2.117 * DesignTable_weight{"Wuav",2}^(0.933);
% eq 15.21, 6th ed

W_furnishings = 217.6 * DesignTable_weight{"Nc",2}; % Include seats
% eq 15.22, 6th ed

W_AC_and_antiice = 201.6 * ((DesignTable_weight{"Wuav",2} +200 * DesignTable_weight{"Nc",2})/1000)^(0.735);
% eq 15.23, 6th ed

W_handling_gear = 3.2*10^(-4) * W_TO; % eq 15.24, 6th edition
% eq 15.24, 6th ed

W_subsystems = W_landinggear + W_engine_systems + W_firewall + W_air_induction_system + W_tailpipe + W_fuelsystem_and_tanks + W_flight_controls + W_instruments + W_hydraulics + W_electrical + W_avionics + W_furnishings + W_AC_and_antiice + W_handling_gear;

end