function [W_out, fuel_used, WF, info] = segment_climb_L2(W_in, obj, seg_no)
% Level-2 climb: flown on excess power, fuel burned at climb power.
%
% IHW1 used the fixed Roskam Table 2.2 fraction 0.990. That number cannot
% know how big the engine is or how draggy the airplane is. Here the climb is
% flown: split the altitude change into n_sub bands and, in each band at its
% mid-height h,
%
%   C_L     = sqrt(3*C_D0/K1)                  minimum power required
%   V       = sqrt( 2*(W/S) / (rho*C_L) )      speed that gives that C_L
%   D       = q*S*(C_D0 + K1*C_L^2)
%   P_shaft = P_SL * power_lapse(h, "max_continuous")
%   ROC     = (550*eta_p*P_shaft - D*V) / W    excess power / weight, ft/s
%   dt      = dh / ROC                         s
%   W      <- W - c * P_shaft * dt/3600        lbf burned at climb power
%
% [Raymer Sec. 17.3. Rate of climb of a propeller airplane, Eq. (17.45),
% p. 652, which peaks at the minimum-power-required speed; C_L for minimum
% power, Eq. (17.20), p. 641 (also Nicolai & Carichner p. 77); speed from
% lift = weight, Eq. (17.10); time and fuel to climb, Eqs. (17.46)-(17.47),
% with C*T = C_bhp*bhp from Eq. (17.4).] c in lbm/(hp*hr), so c*P_shaft is
% lbm/hr. Quasi-steady: the small change in kinetic energy as V rises
% with altitude is neglected, as in Raymer's steady-climb equations.
%
% The climb starts where the PREVIOUS segment ended - the altitude of
% segment seg_no-1, or sea level for the first segment. A "climb" that does
% not gain height burns nothing.

    seg   = get_miss_seg(seg_no, obj.miss);
    h_end = seg.alt;

    % --- Milestone 1: where the climb starts -----------------------------
    % the altitude of segment seg_no-1, or 0 for the first segment
    h_start = ;

    if h_end <= h_start
        WF = 1;  fuel_used = 0;  W_out = W_in;
        info = struct('type', "climb", 'CL', NaN, 'LD', NaN, ...
                      'V_fps', NaN, 'time_hr', 0, 'n_sub', 0);
        return;
    end

    % --- Milestone 2: the altitude bands and the airplane ----------------
    n_sub = obj.miss.climb_segments;
    dh    = ;                               % ft per band
    S     = obj.geom.S_ref;
    eta_p = ;                               % the CLIMB propeller efficiency
    C     = obj.prop.C_bhp([]);
    polar = obj.aero.drag_polar([]);

    % --- Milestone 3: climb at the minimum-power lift coefficient --------
    CL = ;
    CD = ;

    W = W_in;  t_tot = 0;  V_sum = 0;
    for i = 1:n_sub
        % --- Milestone 4: one band, evaluated at its mid-height ----------
        h       = ;
        state   = get_state(h);
        V       = ;
        q       = ;
        D       = ;
        P_shaft = ;     % P_SL, lapsed to h, at MAXIMUM CONTINUOUS power
        ROC     = ;     % ft/s

        if ~(isfinite(ROC) && ROC > 0)
            error('segment_climb_L2:CannotClimb', ...
                ['The airplane cannot climb at %.0f ft: excess power is ', ...
                 'non-positive (P_shaft = %.1f hp, D = %.1f lbf). The engine ', ...
                 'is too small for this weight.'], h, P_shaft, D);
        end

        % --- Milestone 5: time in the band and the fuel it burns ---------
        dt    = ;       % s
        W     = ;       % lbf
        t_tot = t_tot + dt;
        V_sum = V_sum + V;
    end

    WF        = ;
    fuel_used = ;
    W_out     = ;

    info = struct('type', "climb", 'CL', CL, 'LD', CL/CD, ...
                  'V_fps', V_sum/n_sub, 'time_hr', t_tot/3600, 'n_sub', n_sub);
end
