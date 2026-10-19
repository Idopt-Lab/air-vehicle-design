function [CLa, info] = cl_alpha_raymer(A, M, sweep_maxt, eta, S_exp_over_S, d_over_b)
%CL_ALPHA_RAYMER  Subsonic wing lift-curve slope (per rad).
%
%   CLa = CL_ALPHA_RAYMER(A, M, sweep_maxt, eta, S_exp_over_S, d_over_b)
%     A            aspect ratio (use the effective AR with winglets, p. 400)
%     M            Mach number (< 1)
%     sweep_maxt   sweep of the max-thickness line (deg)
%     eta          airfoil efficiency = cl_alpha/(2*pi/beta)       Eq. 12.8
%     S_exp_over_S exposed / reference area
%     d_over_b     fuselage diameter / span
%
%   CLa = 2*pi*A / (2 + sqrt(4 + (A*beta/eta)^2*(1 + tan^2(sweep)/beta^2)))
%         * (S_exp/S_ref)*F                       Raymer Eq. 12.6, p. 400
%   beta^2 = 1 - M^2                              Raymer Eq. 12.7, p. 400
%   F = 1.07*(1 + d/b)^2                          Raymer Eq. 12.9, p. 400
%   (S_exp/S_ref)*F is limited to 0.98: "This is unlikely and should probably
%   be suppressed by setting this product to ... 0.98"          Raymer p. 400
%
%   info returns beta, F, the product before the limit, and the limited one.

    arguments
        A            (1,1) double {mustBePositive}
        M            (1,1) double {mustBeInRange(M, 0, 1, "exclude-upper")}
        sweep_maxt   (1,1) double {mustBeReal}
        eta          (1,1) double {mustBePositive}
        S_exp_over_S (1,1) double {mustBePositive}
        d_over_b     (1,1) double {mustBeNonnegative}
    end

    beta = sqrt(1 - M^2);
    F    = 1.07*(1 + d_over_b)^2;
    SF   = S_exp_over_S*F;
    SFc  = min(SF, 0.98);
    CLa  = 2*pi*A/(2 + sqrt(4 + (A*beta/eta)^2*(1 + tand(sweep_maxt)^2/beta^2)))*SFc;

    info = struct('beta', beta, 'F', F, 'SF', SF, 'SF_used', SFc);
end
