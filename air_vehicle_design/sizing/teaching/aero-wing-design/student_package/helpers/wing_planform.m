function p = wing_planform(S, AR, lambda, sweep_c4, d_fus, xc_m)
%WING_PLANFORM  Trapezoidal-wing geometry from area, AR, taper and sweep.
%
%   p = WING_PLANFORM(S, AR, lambda, sweep_c4, d_fus, xc_m) returns the
%   derived planform of a straight-tapered wing (SI units, degrees):
%     b, c_root, c_tip, MAC, ybar, c_bar (= S/b), sweep_LE, sweep_maxt,
%     c_side (chord at the fuselage side), S_exp (exposed area, both sides).
%   d_fus is the fuselage width at the wing (m). xc_m is the chordwise
%   position of maximum thickness.

    arguments
        S        (1,1) double {mustBePositive}
        AR       (1,1) double {mustBePositive}
        lambda   (1,1) double {mustBeNonnegative}
        sweep_c4 (1,1) double {mustBeReal}
        d_fus    (1,1) double {mustBeNonnegative} = 0
        xc_m     (1,1) double {mustBeInRange(xc_m, 0, 1)} = 0.30
    end

    p.b      = sqrt(AR*S);                                   % Raymer Eq. 7.5, p. 191
    p.c_root = 2*S/(p.b*(1 + lambda));                       % Raymer Eq. 7.6, p. 191
    p.c_tip  = lambda*p.c_root;                              % Raymer Eq. 7.7, p. 191
    p.MAC    = 2/3*p.c_root*(1 + lambda + lambda^2)/(1 + lambda);  % Raymer Eq. 7.8, p. 192
    p.ybar   = p.b/6*(1 + 2*lambda)/(1 + lambda);            % Raymer Eq. 7.9, p. 192
    p.c_bar  = S/p.b;                                        % mean geometric chord

    p.sweep_LE   = sweep_at(0,    sweep_c4, 0.25, AR, lambda);   % Gudmundsson Eq. 9-11, see sweep_at
    p.sweep_maxt = sweep_at(xc_m, sweep_c4, 0.25, AR, lambda);

    % Exposed planform: the trapezoid outboard of the fuselage side
    p.c_side = p.c_root - (p.c_root - p.c_tip)*(d_fus/2)/(p.b/2);
    p.S_exp  = (p.c_side + p.c_tip)/2*(p.b - d_fus);
end
