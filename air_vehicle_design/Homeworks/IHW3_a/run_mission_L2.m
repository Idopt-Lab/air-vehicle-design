function [fuel_burned, segment_weight, segment_wf, detail] = run_mission_L2(W_TO, obj)
%RUN_MISSION_L2  Mission fuel with the IMPROVED FUEL FRACTIONS of the lecture.
%
%   [fuel_burned, segment_weight, segment_wf, detail] = run_mission_L2(W_TO, obj)
%
%   Same signature and same segment order as the IHW1 run_mission, so it is a
%   drop-in replacement. The fourth output carries the per-segment L/D, lift
%   coefficient, speed and time that the L1 version never computed.
%
%   ------------------------------------------------------------------
%   WHAT CHANGED, AND WHY IT IS THE BIGGEST FIX IN IHW3a
%
%   The IHW1 mission flies cruise at L/D_max and loiter at 0.866*L/D_max.
%   Those are the L/D values the airplane WOULD reach if it were free to pick
%   its speed. It is not: the requirements name 200 KTAS at 8000 ft and 120
%   KTAS at 4000 ft. Fix the speed and the altitude and the lift coefficient
%   is no longer a choice - it is
%
%       C_L = (W/S) / q ,      q = 0.5 rho V^2
%
%   and the lift-to-drag ratio follows from the airplane's own polar. On the
%   sized TTPA that gives
%
%       cruise   C_L 0.366  ->  L/D 10.53   against 13.45 assumed   (-22%)
%       loiter   C_L 0.774  ->  L/D 13.44   against 11.64 assumed   (+15%)
%
%   Best-L/D speed for this airplane is 139 kt; the cruise requirement is
%   200 kt, so it genuinely flies well below best L/D and the L1 model cannot
%   see it. In loiter the 120 kt requirement happens to land almost exactly on
%   best L/D, so the 0.866 factor is simply wrong there.
%
%   This is the "no correlation between L/D and the estimated drag polar"
%   defect the sizing-refinement lecture opens with, and the W_0/S_ref arrow
%   into its Fuel fraction box is the fix.
%
%   ------------------------------------------------------------------
%   SEGMENT BY SEGMENT
%
%     startup/taxi/takeoff  Roskam Part I Table 2.2 fraction by default. The
%                           lecture's 15-min-idle rule is implemented but NOT
%                           the default - see the note in ground_fraction_.
%     climb                 energy method, sub-segmented. Speed for best rate
%                           of climb, real excess power, fuel from the brake
%                           specific fuel consumption.
%     cruise                Breguet in sub-segments, C_L recomputed from the
%                           current weight in each one, per the lecture's
%                           "break the range into a large number of segments".
%     descent               Roskam Table 2.2. The lecture says the historical
%                           method is good enough here.
%     loiter                Breguet endurance at the ACTUAL lift coefficient
%                           of the specified speed and altitude.
%     landing               Roskam Table 2.2.
%
%   PROPELLER FORM. The lecture writes its improved fractions for a jet, in
%   terms of C and T/W. For a propeller the conversions are
%
%       fuel flow   = C_bhp * P_shaft                        [lbf/hr]
%       thrust      = 550 * eta_p * P_shaft / V              [lbf]
%       Breguet R   = exp(-R*C_bhp/(375*eta_p*(L/D)))        R in MILES
%       Breguet E   = exp(-E*V*C_bhp/(550*eta_p*(L/D)))      E in hr, V in ft/s
%
%   The fuel-flow form is used for the ground segments instead of the
%   lecture's 1 - C*t*(T/W), which divides by the speed and is singular at
%   V = 0.
%
%   See also RUN_MISSION, MISSION_FUEL.

    arguments
        W_TO (1,1) double {mustBePositive}
        obj  (1,1) struct
    end

    P = read_options_(obj);

    W  = W_TO;
    n  = numel(obj.miss.segments);
    fuel_burned    = zeros(1, n);
    segment_wf     = zeros(1, n);
    segment_weight = zeros(1, n + 1);
    segment_weight(1) = W_TO;
    detail = repmat(struct('name', "", 'type', "", 'WF', NaN, 'fuel', NaN, ...
        'CL', NaN, 'LD', NaN, 'V_fps', NaN, 'time_hr', NaN, 'n_sub', NaN), 1, n);

    x_climb_credit = 0;   % ft of ground distance flown in the climbs
    h_prev         = 0;   % altitude the previous segment ended at [ft]

    for k = 1:n
        seg   = get_miss_seg(k, obj.miss);
        stype = lower(string(seg.type));
        d     = detail(k);
        d.name = string(obj.miss.segments(k).name);
        d.type = stype;

        switch stype

            case "takeoff"
                % Startup, taxi and takeoff as one block.
                [WF, d] = ground_fraction_(obj, P, W, "takeoff", d);

            case "climb"
                % The climb runs from wherever the previous segment left the
                % airplane up to this segment's altitude. Taking the start
                % from the PREVIOUS SEGMENT rather than searching the profile
                % keeps it correct when a profile has several climbs, or two
                % climbs to the same altitude.
                [WF, d, x_seg] = climb_fraction_(obj, P, W, seg, h_prev, d);
                x_climb_credit = x_climb_credit + x_seg;

            case "cruise"
                R_nm = seg.dist;
                if P.credit_climb && x_climb_credit > 0
                    R_nm = max(R_nm - x_climb_credit / 6076.115, 0);
                end
                [WF, d] = cruise_fraction_(obj, P, W, seg, R_nm, d);

            case "descent"
                WF = P.WF_descent;
                d.WF = WF;

            case "loiter"
                [WF, d] = loiter_fraction_(obj, P, W, seg, d);

            case "landing"
                [WF, d] = ground_fraction_(obj, P, W, "landing", d);

            otherwise
                error('run_mission_L2:UndefinedSegment', ...
                    'Mission segment type "%s" is not defined.', stype);
        end

        fuel_burned(k)      = (1 - WF) * W;
        W                   = W * WF;
        segment_wf(k)       = WF;
        segment_weight(k+1) = W;

        d.WF   = WF;
        d.fuel = fuel_burned(k);
        detail(k) = d;

        if ~isempty(seg.alt)
            h_prev = seg.alt;
        end
    end

end


%% ===================== segment models =====================

function [WF, d] = cruise_fraction_(obj, P, W_in, seg, R_nm, d)
%CRUISE_FRACTION_  Breguet range in sub-segments, with a live lift coefficient.
%
%   The lecture: "Break the range into a large number of segments", and in
%   each one
%       C_L = 2 W_i / (rho V^2 S)      L/D = C_L / (C_D0 + K C_L^2)
%       W_{i+1} = W_i exp( -dR C / (V (L/D)) )
%   in the propeller form, with dR in miles,
%       W_{i+1} = W_i exp( -dR C_bhp / (375 eta_p (L/D)) )
%
%   One segment over 1200 nmi gives a fraction near 0.84, well under the
%   lecture's 0.9 floor, so sub-segmenting is required, not optional.

    st    = get_state(seg.alt);
    V     = kts2fps_(seg.ktas);
    q     = 0.5 * st.rho * V^2;
    S     = obj.geom.S_ref;
    eta_p = obj.prop.prop_eff([], seg);
    C     = obj.prop.C_bhp([]);
    polar = obj.aero.drag_polar([]);

    n_sub  = P.cruise_segments;
    dR_mi  = R_nm * 1.15077945 / n_sub;     % nmi -> statute miles, per segment

    W = W_in;
    CL_sum = 0; LD_sum = 0;
    for i = 1:n_sub
        CL = W / (q * S);
        CD = polar.CD0 + polar.K1 * CL^2;
        LD = CL / CD;
        W  = W * exp(-dR_mi * C / (375 * eta_p * LD));
        CL_sum = CL_sum + CL;  LD_sum = LD_sum + LD;
    end

    WF      = W / W_in;
    d.CL    = CL_sum / n_sub;
    d.LD    = LD_sum / n_sub;
    d.V_fps = V;
    d.n_sub = n_sub;
    d.time_hr = (R_nm * 6076.115) / V / 3600;

    check_fraction_(WF, n_sub, "cruise");
end


function [WF, d] = loiter_fraction_(obj, P, W_in, seg, d)
%LOITER_FRACTION_  Breguet endurance at the ACTUAL lift coefficient.
%
%   The lecture allows loiter to stay a single segment if L/D is held
%   constant, and says to fly at maximum L/D when the speed is free. Here the
%   speed is NOT free - the requirement names 120 KTAS at 4000 ft - so the
%   lift coefficient is whatever that condition produces. It happens to land
%   very close to the best-L/D value, which is why the IHW1 factor of 0.866
%   is 13 percent pessimistic.

    st    = get_state(seg.alt);
    V     = kts2fps_(seg.ktas);
    q     = 0.5 * st.rho * V^2;
    S     = obj.geom.S_ref;
    eta_p = obj.prop.prop_eff([], seg);
    C     = obj.prop.C_bhp([]);
    polar = obj.aero.drag_polar([]);

    E  = seg.time_min / 60;                 % hr
    CL = W_in / (q * S);
    CD = polar.CD0 + polar.K1 * CL^2;
    LD = CL / CD;

    WF = exp(-E * V * C / (LD * 550 * eta_p));

    d.CL = CL;  d.LD = LD;  d.V_fps = V;  d.time_hr = E;  d.n_sub = 1;
end


function [WF, d, x_ground] = climb_fraction_(obj, P, W_in, seg, h_start, d)
%CLIMB_FRACTION_  Energy-method climb in sub-segments.
%
%   The lecture's climb block, in propeller form. Per sub-segment:
%     - fly at the speed for best rate of climb. For a propeller that is the
%       minimum-power-required condition, C_L = sqrt(3 C_D0 / K), rather than
%       the jet expression the lecture prints, which is built on T/W.
%     - excess power gives the rate of climb:
%         ROC = ( 550 eta_p P_shaft - D V ) / W
%     - time from the altitude increment, fuel from the brake specific fuel
%       consumption:
%         dW = C_bhp * P_shaft * dt
%
%   The climb starts at the previous segment's altitude and ends at this
%   segment's alt_ft. Ground distance is accumulated so it can optionally be
%   credited against the cruise range, as the lecture allows.

    h_end = seg.alt;
    if h_end <= h_start
        WF = 1; x_ground = 0; d.n_sub = 0;
        return;
    end

    n_sub = P.climb_segments;
    dh    = (h_end - h_start) / n_sub;
    S     = obj.geom.S_ref;
    eta_p = obj.prop.prop_eff([], struct('type', "climb"));
    C     = obj.prop.C_bhp([]);
    polar = obj.aero.drag_polar([]);
    CL    = sqrt(3 * polar.CD0 / polar.K1);   % minimum power required

    W = W_in;  t_tot = 0;  x_ground = 0;  LD_sum = 0;
    for i = 1:n_sub
        h  = h_start + (i - 0.5) * dh;
        st = get_state(h);

        V  = sqrt(2 * (W / S) / (st.rho * CL));
        q  = 0.5 * st.rho * V^2;
        CD = polar.CD0 + polar.K1 * CL^2;
        D  = q * S * CD;

        % Maximum continuous shaft power at this altitude, all engines.
        P_shaft = obj.prop.P_SL * obj.prop.power_lapse(st, "max_continuous");

        ROC = (550 * eta_p * P_shaft - D * V) / W;     % ft/s
        if ~(isfinite(ROC) && ROC > 0)
            error('run_mission_L2:CannotClimb', ...
                ['The airplane cannot climb at %.0f ft: excess power is ', ...
                 'non-positive (P_shaft = %.1f hp, D = %.1f lbf, V = %.1f ft/s). ', ...
                 'The engine is too small for this weight.'], h, P_shaft, D, V);
        end

        dt       = dh / ROC;                            % s
        W        = W - C * P_shaft * (dt / 3600);       % lbf
        t_tot    = t_tot + dt;
        x_ground = x_ground + sqrt(max(V^2 - ROC^2, 0)) * dt;
        LD_sum   = LD_sum + CL / CD;
    end

    WF = W / W_in;
    d.CL = CL;  d.LD = LD_sum / n_sub;  d.time_hr = t_tot / 3600;  d.n_sub = n_sub;
end


function [WF, d] = ground_fraction_(obj, P, W_in, which, d)
%GROUND_FRACTION_  Startup/taxi/takeoff, or landing.
%
%   DEFAULT: the Roskam Part I Table 2.2 fraction, unchanged from IHW1.
%
%   OPTION 'lecture_idle_rule': the lecture's own rule - 15 minutes at idle
%   with idle taken as 5 percent of maximum power, plus 1 minute at takeoff
%   power - evaluated with the propeller fuel-flow form C_bhp * P * t rather
%   than the lecture's 1 - C t (T/W), which is singular at zero speed.
%
%   THE LECTURE RULE IS NOT THE DEFAULT, DELIBERATELY. It is written for a
%   jet. Applied to this piston twin with a single constant BSFC it predicts
%   roughly 6.5 lbf for start, taxi and takeoff together, against 82 lbf from
%   Roskam. The reason is physical: a piston engine's specific fuel
%   consumption at idle is far worse than at cruise, and a constant-BSFC model
%   cannot represent that. The lecture says to use the idle fuel flow "for
%   your particular engine" - data this model does not carry. Roskam's
%   GA-calibrated fraction is the better answer, and the lecture makes the
%   same call for descent and landing.

    if which == "landing"
        WF = P.WF_landing;
        d.WF = WF;
        return;
    end

    switch P.ground_method

        case "roskam_fraction"
            WF = P.WF_takeoff;

        case "lecture_idle_rule"
            C       = obj.prop.C_bhp([]);
            P_SL    = obj.prop.P_SL;
            W_idle  = C * (P.idle_power_fraction * P_SL) * (P.taxi_time_min / 60);
            W_to    = C * P_SL * (P.takeoff_time_min / 60);
            WF      = (W_in - W_idle - W_to) / W_in;
            d.time_hr = (P.taxi_time_min + P.takeoff_time_min) / 60;

        otherwise
            error('run_mission_L2:UndefinedGroundMethod', ...
                'ground_segment_method "%s" is not defined.', P.ground_method);
    end

    d.WF = WF;
end


%% ===================== helpers =====================

function P = read_options_(obj)
%READ_OPTIONS_  Pull the L2 mission options off the profile, with defaults.
    m = obj.miss;
    P.cruise_segments      = get_(m, 'cruise_segments',      12);
    P.climb_segments       = get_(m, 'climb_segments',        4);
    P.ground_method        = string(get_(m, 'ground_segment_method', "roskam_fraction"));
    P.credit_climb         = logical(get_(m, 'credit_climb_distance', false));
    % Roskam Part I Table 2.2, unchanged from IHW1.
    P.WF_takeoff  = 0.984;
    P.WF_descent  = 0.992;
    P.WF_landing  = 0.992;
    % Lecture idle rule, used only when ground_method says so.
    P.idle_power_fraction = 0.05;
    P.taxi_time_min       = 15;
    P.takeoff_time_min    = 1;
end

function v = get_(s, name, default)
    if isfield(s, name) && ~isempty(s.(name))
        v = s.(name);
    else
        v = default;
    end
end

function check_fraction_(WF, n_sub, name)
%CHECK_FRACTION_  The lecture's own accuracy rule.
%   "If a climb or cruise segment fuel fraction is less than 0.9, then
%    increase the number of segments to avoid loss of accuracy."
%   Applied per SUB-segment: the whole-segment fraction is allowed to be
%   small, it is the individual steps that must stay shallow.
    WF_sub = WF^(1/max(n_sub,1));
    if WF_sub < 0.9
        warning('run_mission_L2:SegmentTooCoarse', ...
            ['A %s sub-segment weight fraction is %.3f, below the 0.9 the ', ...
             'lecture sets as the accuracy floor. Increase the sub-segment ', ...
             'count in the missions block.'], name, WF_sub);
    end
end

function fps = kts2fps_(kts)
    fps = kts * 6076.115 / 3600;
end
