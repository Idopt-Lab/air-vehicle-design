function [W_out, fuel_used] = segment_landing(W_in, W_TO)
    WF_Landing = 0.995;
    fuel_used = W_in * (1 - WF_Landing);
    W_out = W_in - fuel_used;
end
