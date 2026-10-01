function [W_out, fuel_used, WF, info] = segment_cruise_L2(W_in, obj, seg_no)
% Level-2 cruise: Breguet range, flown at the lift coefficient the airplane
% actually has, recomputed as fuel burns off.
%
% IHW1 flew the whole cruise at L/D_max. That is only right if the airplane
% happens to cruise at the best-L/D lift coefficient. It does not: 200 KTAS at
% 8000 ft pins C_L = W/(q*S), and that C_L is well below the best-L/D value.
% So the cruise is split into n_sub pieces and each piece uses its own C_L:
%
%   C_L  = W / (q*S)                      lift equals weight
%   C_D  = C_D0 + K1*C_L^2                the airplane's own polar
%   W   <- W * exp( -dR * c / (375 * eta_p * C_L/C_D) )
%
% [Breguet range, propeller: Roskam Part I Eq. (2.9), p. 13, in statute
% miles with the constant 375; the same relation as Raymer Eq. (6.12) in
% feet with 550.] c in lbm/(hp*hr). 375 = 550 ft*lbf/(s*hp) * 3600 s/hr /
% 5280 ft/mi. Raymer Eq. (6.13) gives L/D from the ACTUAL wing loading at
% the flight condition - Raymer's own note: "not takeoff wing loading".
%
% Accuracy floor [sizing-refinement lecture]: every sub-segment weight
% fraction should be at least 0.9. If one is not, use more sub-segments.

    % --- Milestone 1: the segment, its atmosphere, and the airplane ------
    seg   = get_miss_seg(seg_no, obj.miss);
    state = ;
    V     = ;                               % ft/s
    q     = ;                               % lbf/ft^2
    S     = ;                               % THIS pass's wing, ft^2
    eta_p = ;
    C     = ;                               % lbm/(hp*hr)
    polar = ;

    % --- Milestone 2: split the range into n_sub pieces ------------------
    n_sub = obj.miss.cruise_segments;
    dR_mi = ;                               % statute miles per piece

    % --- Milestone 3: fly every piece at its own C_L ---------------------
    W      = W_in;
    CL_sum = 0;
    LD_sum = 0;
    for i = 1:n_sub
        CL = ;
        CD = ;
        LD = ;
        W  = ;
        CL_sum = CL_sum + CL;
        LD_sum = LD_sum + LD;
    end

    % --- Milestone 4: the segment's weight fraction and fuel -------------
    WF        = ;
    fuel_used = ;
    W_out     = ;

    if WF^(1/n_sub) < 0.9
        warning('segment_cruise_L2:SegmentTooCoarse', ...
            ['A cruise sub-segment weight fraction is %.3f, below the 0.9 ', ...
             'accuracy floor. Increase missions.std_mission.cruise_segments.'], ...
            WF^(1/n_sub));
    end

    info = struct('type', "cruise", 'CL', CL_sum/n_sub, 'LD', LD_sum/n_sub, ...
                  'V_fps', V, 'time_hr', seg.dist*6076.115/V/3600, 'n_sub', n_sub);
end
