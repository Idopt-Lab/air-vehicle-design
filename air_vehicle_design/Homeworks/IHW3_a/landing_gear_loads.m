function [P_nose, P_main, P_main_per_strut] = landing_gear_loads(W_TO, obj, n_main_struts)
%LANDING_GEAR_LOADS  Static loads on the tricycle landing gear.
%
%   [P_nose, P_main, P_main_per_strut] = landing_gear_loads(W_TO, obj)
%   [P_nose, P_main, P_main_per_strut] = landing_gear_loads(W_TO, obj, n)
%
%   Inputs
%     W_TO           converged takeoff gross weight [lbf]
%     obj            discipline bundle from ttpa_disciplines
%     n_main_struts  number of main-gear struts, default 2
%   Outputs
%     P_nose             maximum static load on the nose gear [lbf]
%     P_main             maximum static load on ALL main gear [lbf]
%     P_main_per_strut   load carried by one main strut [lbf]
%
%   [Raymer Ch. 11]
%       maximum static load, nose gear  =  W * l_m / l_d
%       maximum static load, main gear  =  W * l_n / l_d
%
%   with l_d the nose-to-main wheelbase, l_n the distance from the aft cg
%   to the nose gear, and l_m the distance from the forward cg to the main
%   gear. The two ratios come from the geometry block of the requirements
%   file; until a weight-and-balance study fixes the cg envelope they are
%   the standard 0.90 and 0.15 placeholders.
%
%   A POST-CONVERGENCE CHECK, not part of the loop. Inside the loop the
%   gear WEIGHT is the Raymer Table 15.2 fraction of TOGW. This function
%   answers a different question - what the struts and the tyres have to
%   carry - and it can only be answered once W_TO has converged. Take the
%   per-strut load into Raymer Table 11.2 to pick a tyre.
%
%   Note that the ratios do NOT sum to 1: they are two separate worst
%   cases, the nose load at the forward cg and the main load at the aft cg,
%   so the two loads are never carried at the same instant.

    arguments
        W_TO          (1,1) double {mustBePositive}
        obj           (1,1) struct
        n_main_struts (1,1) double {mustBePositive, mustBeInteger} = 2
    end

    P_nose = W_TO * obj.geom.l_m_over_l_d;
    P_main = W_TO * obj.geom.l_n_over_l_d;

    P_main_per_strut = P_main / n_main_struts;

end
