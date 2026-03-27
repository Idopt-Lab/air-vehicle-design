function [W_out, fuel_used] = segment_takeoff(W_in)
    WF = 0.95;
    W_out = W_in * WF;
    fuel_used = W_in - W_out;
end
