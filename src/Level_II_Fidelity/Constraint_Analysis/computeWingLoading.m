%% ---------------------------------------------------
% Master Equation
function T_Wto = computeWingLoading(constraints, aero, thrust, Wto_S)
    beta = constraints.W_Wto;
    alpha = thrust.throttleLapse;
    n = constraints.n;
    q = aero.("q (lbf/ft^2)");
    V = aero.("V (ft/s)");
    CD0 = aero.("CD0"); % Values should emerge from calculations performed here
    % Validate functionality independence of fidelity level (should work
    % for all)
    K1 = aero.K1;
    Ps = constraints.PS_ft_s_;

    if isnan(Ps)==1
         Ps = 0;
    end

    z = (n * beta) ./ q;
    induced = K1 .* (z.^2) .* Wto_S;
    linear_drag = CD0 ./ Wto_S;
    parasite = Ps ./ V;

    T_Wto = (beta ./ alpha) .* (q ./ beta .* (linear_drag + induced) + parasite);
end