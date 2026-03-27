function [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO)
    V = Mach * a;
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
    WF_Cruise = compute_weightfraction(TSFC, Distance, V, LD);
    fuel_used = W_in * (1 - WF_Cruise);
    W_out = W_in - fuel_used;
end
