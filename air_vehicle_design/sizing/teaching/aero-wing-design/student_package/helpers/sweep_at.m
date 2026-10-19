function Lambda_n = sweep_at(n, Lambda_m, m, AR, lambda)
%SWEEP_AT  Sweep of one chord-fraction line from the sweep of another.
%
%   Lambda_n = SWEEP_AT(n, Lambda_m, m, AR, lambda) returns the sweep (deg)
%   of the line at chord fraction n (0 = leading edge, 0.25 = quarter chord,
%   1 = trailing edge), from the sweep Lambda_m (deg) of the line at chord
%   fraction m, for a straight-tapered wing of aspect ratio AR and taper
%   ratio lambda:
%
%     tan(L_n) = tan(L_m) - (4/AR)*(n - m)*(1 - lambda)/(1 + lambda)
%
%   Reference: Gudmundsson, General Aviation Aircraft Design (2014),
%   Eq. 9-11, p. 305 (Gudmundsson gives USAF DATCOM as its origin).
%   Raymer 6th ed. p. 74 refers to the same conversion, but the 6th-edition
%   print does not show the equation. It also follows from Raymer Eqs.
%   7.5-7.7: the line n is at x = x_LE(y) + n*c(y), with c(y) linear in y.

    arguments
        n        (1,1) double {mustBeInRange(n, 0, 1)}
        Lambda_m double {mustBeReal}
        m        (1,1) double {mustBeInRange(m, 0, 1)}
        AR       double {mustBePositive}
        lambda   double {mustBeNonnegative}
    end

    Lambda_n = atand(tand(Lambda_m) - 4./AR.*(n - m).*(1 - lambda)./(1 + lambda));
end
