function [W_out, fuel_used] = segment_climb(W_TO, W_in, Mach)
    WF_Climb = 1.0065 - 0.0325 * Mach;
    fuel_used = (1-WF_Climb) * W_in;
    W_out = W_in - fuel_used;
end
