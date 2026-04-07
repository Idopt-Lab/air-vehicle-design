function [WF] = compute_weightfraction(TSFC, R, Vend, LD_ratio)
          WF = exp(-((R * TSFC) / (Vend * LD_ratio)));
     end