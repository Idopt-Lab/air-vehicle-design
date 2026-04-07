% W_out - Revised function
     function [W_out] = compute_revised_w_out(W_in, seg_dist, TSFC, V, LD)
          W_out = W_in * exp( -(seg_dist*TSFC)/(V*LD));
     end