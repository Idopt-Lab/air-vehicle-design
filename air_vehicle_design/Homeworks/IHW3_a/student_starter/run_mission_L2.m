function [fuel_burned, segment_weight, segment_wf, detail] = run_mission_L2(W_TO, obj)
% Level-2 mission: the IHW1 run_mission, with the three segments that depend
% on the airplane's size replaced by their Level-2 versions.
%
%   segment   IHW1 (Level 1)            IHW3 (Level 2)
%   takeoff   0.984                     0.984              fixed fraction
%   climb     0.990                     segment_climb_L2   excess power
%   cruise    Breguet at L/D_max        segment_cruise_L2  actual C_L
%   descent   0.992                     0.992              fixed fraction
%   loiter    Breguet at 0.866 L/D_max  segment_loiter_L2  actual C_L
%   landing   0.992                     0.992              fixed fraction
%
% The fixed fractions are Roskam Part I Table 2.1, p. 12, twin-engine row.
% The takeoff value is three phases multiplied together:
% 0.992 (engine start and warm-up) x 0.996 (taxi) x 0.996 (takeoff) = 0.984.
%
% Takeoff, descent and landing stay as Roskam fractions: they depend on the
% airplane's size only weakly, and a piston engine's idle fuel flow is data
% this model does not carry.
%
% Unlike IHW1, the segments are not typed in order. The loop reads each
% segment's TYPE from the mission profile and dispatches on it, so a new
% mission is a change to the requirements file, not to this function.
%
% Outputs
%   fuel_burned     1xN  fuel burned in each segment [lbf]
%   segment_weight  1x(N+1)  weight at the start of each segment, then the end
%   segment_wf      1xN  weight fraction of each segment
%   detail          1xN  struct: C_L, L/D, speed, time of the L2 segments

    n = numel(obj.miss.segments);

    fuel_burned    = zeros(1, n);
    segment_wf     = zeros(1, n);
    segment_weight = zeros(1, n + 1);
    segment_weight(1) = W_TO;

    blank  = struct('type', "", 'CL', NaN, 'LD', NaN, 'V_fps', NaN, ...
                    'time_hr', NaN, 'n_sub', NaN);
    detail = repmat(blank, 1, n);

    W = W_TO;
    for k = 1:n
        seg  = get_miss_seg(k, obj.miss);
        info = blank;
        info.type = lower(string(seg.type));

        switch info.type
            case "takeoff"
                [W, fuel_burned(k), segment_wf(k)] = fixed_fraction_(W, 0.984);

            % TODO: one case per remaining segment type. k is the loop index
            %   AND the seg_no the segment functions take. The six labels are
            %   "takeoff" "climb" "cruise" "descent" "loiter" "landing".
            %
            %   climb, cruise, loiter - the Level-2 segment functions, which
            %   return info as a 4th output:
            %       [W, fuel_burned(k), segment_wf(k), info] = segment_xxxxx_L2(W, obj, k);
            %   descent, landing - fixed fractions, Roskam Table 2.1, 0.992:
            %       [W, fuel_burned(k), segment_wf(k)] = fixed_fraction_(W, 0.992);

            otherwise
                error('run_mission_L2:UndefinedSegment', ...
                    'Mission segment type "%s" is not defined.', info.type);
        end

        segment_weight(k + 1) = W;
        detail(k) = info;
    end
end


function [W_out, fuel_used, WF] = fixed_fraction_(W_in, WF)
% A segment flown at a fixed Roskam weight fraction, as in IHW1.
    fuel_used = (1 - WF) * W_in;
    W_out     = W_in * WF;
end
