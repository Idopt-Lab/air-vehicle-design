function [tau, delta] = tau_delta_nicolai(lambda, AR)
%TAU_DELTA_NICOLAI  Non-elliptic lift corrections tau and delta.
%
%   [tau, delta] = TAU_DELTA_NICOLAI(lambda, AR) returns the factors that
%   Nicolai uses in
%     CL_alpha = m0/(1 + m0*(1 + tau)/(pi*AR))     Nicolai Eq. 2.9,  p. 43
%     K'       = (1 + delta)/(pi*AR)               Nicolai Eq. 2.10, p. 43
%
%   Nicolai Fig. 2.10 (p. 45) gives tau and delta against taper ratio at
%   AR = 6 only, and against AR for an untapered wing (lambda = 1) only.
%   COMBINATION RULE (assumption, approved for this lesson):
%     delta(lambda, AR) = delta_AR6(lambda) * delta_L1(AR) / delta_L1(6)
%   and the same for tau. At AR = 6 the rule returns the top panel exactly.
%   Outside the plotted AR range (2.1 to 10) the end value is held.

    arguments
        lambda double {mustBeInRange(lambda, 0, 1)}
        AR     double {mustBePositive}
    end

    d   = book_data().fig2_10;
    ARc = min(max(AR, d.AR(1)), d.AR(end));          % hold the end values

    tau6   = interp1(d.lambda, d.tau_AR6,   lambda);
    delta6 = interp1(d.lambda, d.delta_AR6, lambda);
    tauA   = interp1(d.AR, d.tau_L1,   ARc) / interp1(d.AR, d.tau_L1,   6);
    deltaA = interp1(d.AR, d.delta_L1, ARc) / interp1(d.AR, d.delta_L1, 6);

    tau   = tau6   .* tauA;
    delta = delta6 .* deltaA;
end
