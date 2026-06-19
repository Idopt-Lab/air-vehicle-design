function [W_out, fuel_used] = segment_combat(W_in, time, TSFC, payload, CD0, e, AR, W_TO, q,  S_ref)
          LD = compute_revised_LD_ratio(W_in, q, S_ref, CD0, e, AR);
          WF = exp(-(time * 60 * TSFC / LD));
          fuel_used = W_in*(1-WF);
          W_out = W_in - fuel_used - payload;
     end