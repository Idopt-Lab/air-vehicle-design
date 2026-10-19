function V = wing_fuel_volume(S, b, tc_root, tc_tip, lambda)
%WING_FUEL_VOLUME  Wing fuel volume (m^3), Roskam Eqs. 6.2 and 6.3.
%
%   V = WING_FUEL_VOLUME(S, b, tc_root, tc_tip, lambda)
%     V   = 0.54*(S^2/b)*(t/c)_r*(1 + lambda*sqrt(tau) + lambda^2*tau)/(1 + lambda)^2
%     tau = (t/c)_tip/(t/c)_root
%       Roskam, Airplane Design Part II, Eqs. 6.2, 6.3, p. 153
%       (Roskam gives Torenbeek, Eq. B-12, as the origin)
%   The equation has consistent dimensions (S^2/b is a volume), so SI works.
%   No packaging factor is applied: Roskam says the equation "presumably
%   accounts for any required dry bays" (p. 153).

    arguments
        S       double {mustBePositive}
        b       double {mustBePositive}
        tc_root double {mustBePositive}
        tc_tip  double {mustBePositive}
        lambda  double {mustBeNonnegative}
    end

    tau = tc_tip./tc_root;
    V   = 0.54*(S.^2./b).*tc_root.*(1 + lambda.*sqrt(tau) + lambda.^2.*tau)./(1 + lambda).^2;
end
