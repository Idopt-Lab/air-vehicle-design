function [e, s] = oswald_kroo(A, CD0, d_over_b)
%OSWALD_KROO  Oswald efficiency by Kroo's method, with Shevell's viscous factor.
%
%   [e, s] = OSWALD_KROO(A, CD0, d_over_b)
%     A         aspect ratio (use the effective AR with winglets)
%     CD0       zero-lift drag coefficient of the whole aircraft
%     d_over_b  fuselage diameter / wing span
%
%     s = 1 - 2*(d_F/b)^2                      fuselage factor          Eq. 6
%     P = K*CD0,  K = 0.38                     viscous part             Eq. 7
%     e = 1/(1/(u*s) + K*CD0*pi*A),  u = 0.99                           Eq. 8
%
%   Reference: Nita & Scholz, "Estimating the Oswald Factor from Basic
%   Aircraft Geometrical Parameters", Deutscher Luft- und Raumfahrtkongress
%   2012, Document ID 281424, Eqs. 6-8, p. 2. They give the method to Kroo;
%   K = 0.38 comes from flight-test data of the DC-8 and DC-9 (Shevell).
%   The method has no sweep or taper term.

    arguments
        A        (1,1) double {mustBePositive}
        CD0      (1,1) double {mustBeNonnegative}
        d_over_b (1,1) double {mustBeInRange(d_over_b, 0, 0.7)}
    end

    u = 0.99;
    K = 0.38;
    s = 1 - 2*d_over_b^2;
    e = 1/(1/(u*s) + K*CD0*pi*A);
end
