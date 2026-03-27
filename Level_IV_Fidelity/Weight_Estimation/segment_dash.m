function [W_out, fuel_used] = segment_dash(W_in, W_TO, W_S, q, CD0, e, AR, TSFC, Distance, V)
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
    WF_Dash = compute_weightfraction(TSFC, Distance, V, LD);
    fuel_used = W_in * (1 - WF_Dash);
    W_out = W_in - fuel_used;
end
