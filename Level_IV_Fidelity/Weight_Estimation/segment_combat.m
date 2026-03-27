function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload)
    fuel_used = time * 9906.98 * TSFC;
    W_out = W_in - fuel_used - payload;
end
