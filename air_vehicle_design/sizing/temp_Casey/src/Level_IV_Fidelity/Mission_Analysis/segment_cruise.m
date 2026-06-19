function [W_out, fuel_used] = segment_cruise(W_in, W_S, TSFC, Distance, Mach, a, q, CD0, e, AR, W_TO, S)
          n=20; % Number of segments
          seg_dist = Distance/n; % Divide the total distance into equi-spatial cruise segments.
          % Loop through the cruise segments
          % Compute the nth segment weight
          % Pass that into the next segment
          V = Mach * a;
          % disp("Starting loop...")
          LD = compute_revised_LD_ratio(W_in, q, S, CD0, e, AR);
          W_out = compute_revised_w_out(W_in, seg_dist, TSFC, V, LD);
          % WF = compute_weightfraction(TSFC, seg_dist, V, LD);
          fuel_used = W_in - W_out;
          % W_out = W_in - fuel_used;
          % seg_dist_i = 0;
          for i=2:n
               % seg_dist_i = seg_dist - Distance; % Increment the segment distance
               % LD = compute_LD_ratio(q, CD0, W_in, W_TO, W_S, e, AR);
               LD = compute_revised_LD_ratio(W_out, q, S, CD0, e, AR);
               W_out = compute_revised_w_out(W_in, seg_dist, TSFC, V, LD);
               % WF = compute_weightfraction(TSFC, seg_dist, V, LD);
               fuel_used = W_in - W_out;
               % W_out = W_in - fuel_used;
               % disp("Segment " + i)
               % disp("W_out: " + W_out + " lbf")
          end
          % disp("Exiting loop...")

     end