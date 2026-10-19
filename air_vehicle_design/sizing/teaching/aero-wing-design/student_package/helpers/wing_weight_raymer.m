function m_wing = wing_weight_raymer(W_dg, Nz, S_w, A, tc_root, lambda, sweep_c4, S_csw)
%WING_WEIGHT_RAYMER  Transport wing weight, Raymer Eq. 15.25, in SI units.
%
%   m_wing = WING_WEIGHT_RAYMER(W_dg, Nz, S_w, A, tc_root, lambda, sweep_c4, S_csw)
%     W_dg     flight design gross weight, as a MASS (kg)
%     Nz       ultimate load factor (1.5 x limit load factor)
%     S_w      trapezoidal wing area, through the fuselage (m^2)  [Raymer p. 72]
%     A        aspect ratio
%     tc_root  thickness ratio at the root
%     lambda   taper ratio
%     sweep_c4 wing sweep at 25 % MAC (deg)                       [Raymer p. 576-579]
%     S_csw    wing-mounted control-surface area, flaps included (m^2)
%   Returns the wing mass in kg.
%
%   Raymer Eq. 15.25 (p. 574) is in British units, "Results in Pounds":
%     W_wing = 0.0051*(W_dg*Nz)^0.557 * S_w^0.649 * A^0.5 * (t/c)_root^-0.4
%              * (1 + lambda)^0.1 * cos(Lambda)^-1.0 * S_csw^0.1
%   So the inputs are converted to lb and ft^2 first, and the result back to kg.
%   1 lb = 0.45359237 kg and 1 ft = 0.3048 m, exactly (NIST SP 811, App. B).
%   A pound-mass at standard gravity weighs one pound-force, so the mass in lb
%   is the W_dg (lbf) that Raymer means.

    arguments
        W_dg     double {mustBePositive}
        Nz       (1,1) double {mustBePositive}
        S_w      double {mustBePositive}
        A        double {mustBePositive}
        tc_root  double {mustBePositive}
        lambda   double {mustBeNonnegative}
        sweep_c4 double {mustBeReal}
        S_csw    double {mustBePositive}
    end

    lb  = 0.45359237;          % kg per lb
    ft2 = 0.3048^2;            % m^2 per ft^2

    W_dg_lb  = W_dg/lb;
    S_w_ft2  = S_w/ft2;
    Scsw_ft2 = S_csw/ft2;

    W_lb = 0.0051*(W_dg_lb.*Nz).^0.557 .* S_w_ft2.^0.649 .* A.^0.5 .* tc_root.^(-0.4) ...
           .* (1 + lambda).^0.1 .* cosd(sweep_c4).^(-1.0) .* Scsw_ft2.^0.1;

    m_wing = W_lb*lb;
end
