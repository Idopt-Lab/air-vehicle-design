function Cf = skin_friction(Re, M, len, k)
%SKIN_FRICTION  Fully turbulent flat-plate skin-friction coefficient.
%
%   Cf = SKIN_FRICTION(Re, M, len, k) returns C_f for Reynolds number Re,
%   Mach number M, reference length len (m) and surface roughness k (m).
%   Re is limited to the roughness cut-off value first.
%
%   Raymer Eq. 12.27 has the same form, but it is blank in the PDF scan used
%   for this lesson, so Nicolai is cited for the C_f equation.

    arguments
        Re  double {mustBePositive}
        M   double {mustBeNonnegative}
        len (1,1) double {mustBePositive}
        k   (1,1) double {mustBePositive}
    end

    Re_cut = 38.21*(len/k)^1.053;                 % Raymer Eq. 12.28, p. 421 (subsonic)
    Re     = min(Re, Re_cut);
    Cfi    = 0.455./log10(Re).^2.58;              % Nicolai Eq. 2.22, p. 64
    Cf     = Cfi./(1 + 0.144*M.^2).^0.65;         % Nicolai Eq. 2.25, p. 64
end
