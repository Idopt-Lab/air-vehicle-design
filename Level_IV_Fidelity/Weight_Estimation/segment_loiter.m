function [W_out, fuel_used] = segment_loiter(W_TO, W_in, W_S, q, CD0, e, AR, time, TSFC)
    LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
    WF_Loiter = exp(-(time*60*TSFC/LD));
    fuel_used = W_in * (1 - WF_Loiter);
    W_out = W_in - fuel_used;
end
