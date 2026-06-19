function [enginestats] = propulsion_est_III(T, M, BPR)
% Using equations from Raymer 6th edition, chapter 10, p 285, eq 10.4 ->
% 10.15

% ARGUMENTS
% W = Weight (lbf)
% T = Takeoff thrust (lbf)
% BPR = Bypass ratio
% M = Mach number

% Afterburning engines (imperial units)
W = @(T, M, BPR) (0.063*T^(1.1)*M^(0.25)*exp(-0.81*BPR)); % Engine weight (lbf)
L = @(T, M) (0.255*T^(0.4)*M^(0.2)); % Engine length (ft)
D = @(T, BPR) (0.024*T^(0.5)*exp(0.04*BPR)); % Engine diameter (ft)
SFC_maxT = @(BPR) (2.1*exp(-0.12*BPR)); % SFC at max thrust (1/hr)
T_cruise = @(T, BPR) (2.4*T^(0.74)*exp(0.023*BPR)); % Cruise thrust (lbf)
SFC_cruise = @(BPR) (1.04*exp(-0.186*BPR)); % SFC at cruise conditions (1/hr)

enginestats.W = W(T, M, BPR);
enginestats.L = L(T, M);
enginestats.D = D(T, BPR);
enginestats.SFC_maxT = SFC_maxT(BPR)*(1/3600);
enginestats.T_cruise = T_cruise(T, BPR);
enginestats.SFC_cruise = SFC_cruise(BPR)*(1/3600);

end