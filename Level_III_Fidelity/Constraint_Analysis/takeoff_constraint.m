%% ---------------------------------------------------
% Takeoff Constraint
function T_Wto = takeoff_constraint(Wto_S, TO)
    g = 32.174;
    V_Vstall = TO.Vstall;
    beta = TO.W_Wto;
    alpha = TO.throttleLapse;
    rho = TO.("rho (lb/ft^3)");
    CLmax = TO.CLmax;
    Distance = TO.Distance_ft_;
    CD0 = TO.CD0;
    mu = TO.SurfaceFrictionCoefficient_mu_;

    term1 = V_Vstall^2 * beta^2 .* Wto_S ./ (alpha * rho * CLmax * g * Distance);
    term2 = 0.7 * CD0 / (beta * CLmax) + mu;
    T_Wto = term1 + term2;
end