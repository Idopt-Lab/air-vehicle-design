function [LD_ratio] = compute_LD_ratio(q, CD0, W, W_TO, W_S, e, AR)
          W_by_W_TO = W / W_TO;
          W_by_S = W_by_W_TO * W_S;
          LD_ratio = 1 / ((q * CD0 / W_by_S) + (W_by_S / (q * pi * e * AR)));
     end