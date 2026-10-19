function [e, e48, e49] = oswald_raymer(A, sweep_LE)
%OSWALD_RAYMER  Oswald efficiency from Raymer's statistical fits.
%
%   [e, e48, e49] = OSWALD_RAYMER(A, sweep_LE)
%     e48 = 1.78*(1 - 0.045*A^0.68) - 0.64                     Raymer Eq. 12.48, p. 444
%     e49 = 4.61*(1 - 0.045*A^0.68)*cos(sweep_LE)^0.15 - 3.1   Raymer Eq. 12.49, p. 444
%   Eq. 12.49 is for leading-edge sweep above 30 deg. "For sweeps between 0
%   and 30, linearly interpolate between results from the two equations."
%   (p. 444). abs(sweep_LE) is used for forward sweep (assumption).
%
%   NOTE: for a high-AR transport this gives a value that is too low
%   (e about 0.4 for the 737). Lecture L03 shows this.

    arguments
        A        (1,1) double {mustBePositive}
        sweep_LE (1,1) double {mustBeReal}
    end

    s   = abs(sweep_LE);
    e48 = 1.78*(1 - 0.045*A^0.68) - 0.64;
    e49 = 4.61*(1 - 0.045*A^0.68)*cosd(s)^0.15 - 3.1;
    if s >= 30
        e = e49;
    else
        e = e48 + (e49 - e48)*s/30;
    end
end
