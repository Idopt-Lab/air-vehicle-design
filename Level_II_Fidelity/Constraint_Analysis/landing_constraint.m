%% ---------------------------------------------------
% Landing Constraint
function Wto_S = landing_constraint(Landing)
    g = 32.174;
    Distance = Landing.Distance_ft_;
    beta = Landing.W_Wto;
    rho = Landing.("rho (lb/ft^3)");
    CLmax = Landing.CLmax;
    CD0 = Landing.CD0;
    mu = Landing.SurfaceFrictionCoefficient_mu_;

    Wto_S = (Distance * rho * g * (mu * CLmax + 0.83 * CD0)) / (1.69 * beta);
end
