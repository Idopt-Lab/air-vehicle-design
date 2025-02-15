function [T_dry_lbf, T_AB_lbf, TSFC_dry, TSFC_AB] = f100_engine_model(h_ft, M)

% References
% [1] Aircraft Engine Design, Third Edition by Mattingly et al.

ft2m = 0.3048;
gamma = 1.4;

% Engine-specific parameters
% Military thrust
Tsl_dry_lbf = 15000;  TSFCsl_dry = 0.7;  % Brandt
% Tsl_dry_lbf = 22876;  TSFCsl_dry = 0.682;  % NASA simulator
% Maximum thrust
Tsl_AB_lbf = 23770;  TSFCsl_AB = 2.2;
% Tsl_AB_lbf = 33421;  TSFCsl_AB = 1.332;
% theta0-break
theta0_break = 1.0;

% Atmosphere
[T_K,a_mps,P_Pa,rho_kgpm3,nu_m2p3,mu_kgps] = atmosisa(h_ft*ft2m);
[T0_K,a0_mps,P0_Pa,rho0_kgpm3,nu0_m2p3,mu0_kgps] = atmosisa(0);

% Non-dimensional temperature. [1] Eq. 2.52a
theta = T_K/T0_K;  
theta0 = theta.*(1+((gamma-1)/2).*M.^2);

% Non-dimensional pressure. % [1] Eq. 2.52a
delta = P_Pa/P0_Pa;
delta0 = delta.*(1+((gamma-1)/2).*M.^2).^(gamma/(gamma-1));

% Thrust lapse
if theta0< theta0_break
    alpha_dry = delta0.*(1-0.3*M.^1);   
    alpha_AB = delta0.*(1-0.1*M.^0.5);
else
    alpha_dry = delta0.*(1-0.3*M.^1-1.7.*((theta0-theta0_break)./theta0));
    alpha_AB = delta0.*(1-0.1*M.^0.5-2.2.*((theta0-theta0_break)./theta0));
end

% Thrust
T_dry_lbf = alpha_dry * Tsl_dry_lbf;
T_AB_lbf  = alpha_AB  * Tsl_AB_lbf;

% TSFC
TSFC_dry = TSFCsl_dry * (1 + 0.35 * abs(M-0.0).^1) .* (T_dry_lbf./Tsl_dry_lbf).^0.5;
TSFC_AB  = TSFCsl_AB  * (1 + 0.35 * abs(M-0.4).^1) .* (T_AB_lbf ./Tsl_AB_lbf ).^0.5;

end