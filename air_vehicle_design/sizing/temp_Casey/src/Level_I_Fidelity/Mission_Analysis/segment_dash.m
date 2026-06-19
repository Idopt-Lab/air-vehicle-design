function [W_out, fuel_used] = segment_dash(W_in, S_ref, W_TO, q, CD0, e, AR, TSFC, Distance, V)
          LD = compute_revised_LD_ratio(W_in, q, S_ref, CD0, e, AR);
          WF = compute_weightfraction(TSFC, Distance, V, LD);
          fuel_used = W_in * (1 - WF);
          W_out = W_in - fuel_used;
     end