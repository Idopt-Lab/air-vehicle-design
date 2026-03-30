% LD ratio - Revision function
     function [LD_ratio] = compute_revised_LD_ratio(W, q, S, CD0, e, AR)
          CL = 2*W/(q*S);
          K = 1/(pi*e*AR);
          LD_ratio = CL/(CD0 + K * CL^2);
     end