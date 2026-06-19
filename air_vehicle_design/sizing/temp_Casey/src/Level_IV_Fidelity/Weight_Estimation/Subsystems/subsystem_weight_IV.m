function [W_subsystems] = subsystem_weight_IV(DesignTable_weight, W_TO, T0, W_engine_installed)
% THIS CALCULATES THE TOTAL WEIGHT OF ALL SUBSYSTEMS
% Need to extract required information simply without spaghettifying the code.

W_landinggear = landinggear(DesignTable_weight.Coefficients.Kcb, DesignTable_weight.Coefficients.Ktpg, DesignTable_weight.Coefficients.Wl, DesignTable_weight.Coefficients.Nl, DesignTable_weight.Coefficients.Lm, DesignTable_weight.Coefficients.Nnw, DesignTable_weight.Coefficients.Ln);

W_engine_systems = engine_systems_weights(DesignTable_weight.Coefficients.Nen, T0, DesignTable_weight.Coefficients.Nz, W_engine_installed, DesignTable_weight.Coefficients.De, DesignTable_weight.Coefficients.Lsh, DesignTable_weight.Coefficients.Lec, T0);

W_firewall = 1.13*DesignTable_weight.Coefficients.Sfw; % eq 15.8, 6th ed

W_air_induction_system = 13.29 * DesignTable_weight.Coefficients.Kvg *DesignTable_weight.Coefficients.Ld^(0.643) * DesignTable_weight.Coefficients.Kd^(0.182) *DesignTable_weight.Coefficients.Nen^(0.1498) * (DesignTable_weight.Coefficients.Ls/DesignTable_weight.Coefficients.Ld)^(-0.373) * DesignTable_weight.Coefficients.De;
% eq 15.10, 6th ed

W_tailpipe = 3.5*DesignTable_weight.Coefficients.De*DesignTable_weight.Coefficients.Ltp*DesignTable_weight.Coefficients.Nen;
% eq 15.11, 6th ed

W_fuelsystem_and_tanks = 7.45*DesignTable_weight.Coefficients.Vt^(0.47)*(1 + DesignTable_weight.Coefficients.Vi/DesignTable_weight.Coefficients.Vt)^(-0.095) * (1 + DesignTable_weight.Coefficients.VP/DesignTable_weight.Coefficients.Vt)*DesignTable_weight.Coefficients.Nt^(0.066) * DesignTable_weight.Coefficients.Nen^(0.052) * (T0 *DesignTable_weight.Coefficients.SFC/1000)^(0.249);
% eq 15.16, 6th ed

W_flight_controls = 36.28*DesignTable_weight.Coefficients.M^(0.003) * DesignTable_weight.Coefficients.Scs^(0.489) * DesignTable_weight.Coefficients.Ns^(0.484) * DesignTable_weight.Coefficients.Nc^(0.127);
% eq 15.17, 6th ed

W_instruments = 8.0 + 36.37*DesignTable_weight.Coefficients.Nen^(0.676) * DesignTable_weight.Coefficients.Nt^(0.237) +26.4*(1 + DesignTable_weight.Coefficients.Nci)^(1.356);
% eq 15.18, 6th ed

W_hydraulics = 37.23 * DesignTable_weight.Coefficients.Kvsh * DesignTable_weight.Coefficients.Nu^(0.664);
% eq 15.19, 6th ed

W_electrical = 172.2 *DesignTable_weight.Coefficients.Kmc * DesignTable_weight.Coefficients.Rkva^(0.152) * DesignTable_weight.Coefficients.Nc^(0.10) * DesignTable_weight.Coefficients.La^(0.10) * DesignTable_weight.Coefficients.Ngen^(0.091);
% eq 15.20, 6th ed

W_avionics = 2.117 * DesignTable_weight.Coefficients.Wuav^(0.933);
% eq 15.21, 6th ed

W_furnishings = 217.6 * DesignTable_weight.Coefficients.Nc; % Include seats
% eq 15.22, 6th ed

W_AC_and_antiice = 201.6 * ((DesignTable_weight.Coefficients.Wuav +200 * DesignTable_weight.Coefficients.Nc)/1000)^(0.735);
% eq 15.23, 6th ed

W_handling_gear = 3.2*10^(-4) * W_TO; % eq 15.24, 6th edition
% eq 15.24, 6th ed

W_subsystems = W_landinggear + W_engine_systems + W_firewall + W_air_induction_system + W_tailpipe + W_fuelsystem_and_tanks + W_flight_controls + W_instruments + W_hydraulics + W_electrical + W_avionics + W_furnishings + W_AC_and_antiice + W_handling_gear;

end