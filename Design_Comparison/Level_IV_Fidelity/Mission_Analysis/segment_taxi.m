function [W_out, fuel_used] = segment_taxi(W_in)
          WF = 0.98;
          W_out = W_in*WF;
          fuel_used = W_in - W_out;
     end