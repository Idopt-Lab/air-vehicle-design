function atm = isa_si(H)
%ISA_SI  1976 U.S. Standard Atmosphere, two lowest layers, SI units.
%
%   atm = ISA_SI(H) returns T (K), P (Pa), rho (kg/m^3), a (m/s),
%   mu (Pa s) and nu (m^2/s) at geopotential altitude H (m), 0 <= H <= 20 km.
%   A flight level (pressure altitude) is a geopotential altitude here.
%
%   Source: U.S. Standard Atmosphere, 1976, NOAA/NASA/USAF ("USSA").
%   This function needs no toolbox.

    arguments
        H (1,1) double {mustBeGreaterThanOrEqual(H, 0), mustBeLessThanOrEqual(H, 20000)}
    end

    g0    = 9.80665;     % m/s^2                     [USSA p. 3]
    T0    = 288.15;      % K                         [USSA p. 4]
    P0    = 101325.0;    % Pa                        [USSA p. 3]
    L0    = -0.0065;     % K/m, layer 0 (0-11 km)    [USSA Table 4, p. 3]
    H1    = 11000;       % m, base of layer 1 (L = 0)[USSA Table 4, p. 3]
    Rstar = 8314.32;     % J/(kmol K)                [USSA p. 3]
    M0    = 28.9644;     % kg/kmol                   [USSA p. 9]
    gam   = 1.40;        %                           [USSA p. 18]
    betaS = 1.458e-6;    % kg/(s m K^0.5)            [USSA p. 19]
    S_S   = 110.4;       % K, Sutherland constant    [USSA p. 19]

    if H <= H1
        atm.T = T0 + L0*H;                                    % USSA Eq. (23), p. 10
        atm.P = P0*(T0/atm.T)^(g0*M0/(Rstar*L0));             % USSA Eq. (33a), p. 12
    else
        T1 = T0 + L0*H1;                                      % USSA Eq. (23)
        P1 = P0*(T0/T1)^(g0*M0/(Rstar*L0));                   % USSA Eq. (33a)
        atm.T = T1;                                           % L = 0 in layer 1
        atm.P = P1*exp(-g0*M0*(H - H1)/(Rstar*T1));           % USSA Eq. (33b), p. 12
    end
    atm.rho = atm.P*M0/(Rstar*atm.T);                         % USSA Eq. (42), p. 15
    atm.a   = sqrt(gam*Rstar*atm.T/M0);                       % USSA Eq. (50), p. 18
    atm.mu  = betaS*atm.T^1.5/(atm.T + S_S);                  % USSA Eq. (51), p. 19
    atm.nu  = atm.mu/atm.rho;                                 % USSA Eq. (52), p. 19
end
