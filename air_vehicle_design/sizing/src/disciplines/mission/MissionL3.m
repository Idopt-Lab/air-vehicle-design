classdef MissionL3
%MISSIONL3  Level-3 mission-analysis static toolbox.
%
%   Call as MissionL3.method_name(args) -- no instantiation required.
%   Not in the inheritance chain. Student classes (F16MissionL3, etc.)
%   inherit from MissionModelL3 and call these statics to implement
%   compute_fuel.
%
%   TWO TIERS of statics (matching every other discipline toolbox):
%     High-level -- get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj):
%                   same generic named-segment dispatch loop shape as L1/L2.
%     Low-level  -- Cruise/Dash/Combat/Loiter sub-segment into N=20
%                   sub-intervals of real-aero/prop single-point Breguet
%                   (weight updated between sub-intervals -- captures the
%                   cruise-climb L/D improvement as fuel burns off). Climb
%                   uses its OWN, separately-set sub-interval count, N=40
%                   (user-directed 2026-07-24: L3's climb resolution is
%                   double L2's N=20 climb resolution -- decoupled from the
%                   N=20 used here for Cruise/Dash/Combat/Loiter; see
%                   N_SUBSEGMENTS vs. N_SUBSEGMENTS_CLIMB below). Startup/
%                   Taxi/Takeoff/Descent/Landing are UNCHANGED fixed-fraction
%                   Table 2.1 lookups (same rationale as L2 -- see
%                   MissionModelL2's header).
%
%   EQUATIONS:
%     Cruise/Dash/Combat/Loiter: same Roskam Eq. 2.10/2.12 Breguet forms as
%       L2 (via MissionL1.breguet_range_WF/breguet_endurance_WF, reused
%       fidelity-independent), evaluated at N=20 sub-intervals with L/D
%       recomputed at each sub-interval's own (updated) weight -- NO 0.866
%       correction, same reasoning as L2 (see MissionL2.m header).
%     Climb: energy-height method, N=40 sub-intervals (N_SUBSEGMENTS_CLIMB,
%       user-directed 2026-07-24 -- double L2's N=20 climb resolution).
%       The mission profile's altitude/Mach are
%       "AT END of segment" waypoints (mission_profile.json convention), so
%       Climb's START condition is the PREVIOUS segment's end condition
%       (alt_ft(i-1), mach_end(i-1)) -- get_mission_fuel supplies this.
%       At each of N sub-intervals (linearly interpolating BOTH altitude and
%       Mach from start to end -- the mission profile prescribes the flown
%       trajectory, so climb speed is not separately re-optimized, unlike
%       the legacy code's self-derived best-climb-speed formula):
%         Ps = energy_height_rate(T, D, V, W) = (T-D)*V/W   [specific excess
%             power; T = mil-power thrust = prop_obj.thrust_lapse_mil_on_AB_scale(state)*prop_obj.T_SL.
%             SCOPE NOTE: Climb is modeled as always flown at mil power
%             (Dry) -- a deliberate simplification, not read from
%             missiondata.dry_or_wet for the Climb segment (unlike every
%             other segment type, which does dispatch mil/AB per-segment).
%             Every Climb segment across this repo's example missions is in
%             fact "Dry", so this has no numeric effect today; a future
%             generic mission profile that flies an afterburner climb would
%             need this extended to dispatch on dry_or_wet like the other
%             segments do;
%             D from aero_obj.drag_polar(state) at the current weight's CL]
%         dt = delta_he / Ps                                [time to cross this sub-interval's energy-height gain]
%         dW_fuel = TSFC * T * dt_hr                         [dW_fuel/dt = TSFC*T, Mattingly-style;
%             TSFC = prop_obj.get_TSFC(state), mil-power (same Dry-only scope note as above)]
%       he = h + V^2/(2*g(h)), g(h) = g0*(r_e/(r_e+h))^2      [energy height with altitude-varying
%             gravity -- fixes Known Issues #7's SECONDARY bug (gravity array
%             computed once then abandoned in the legacy loop)]
%       Every sub-interval constructs its own AircraftState(h, M), which
%       always performs the ft->m conversion correctly -- fixes Known
%       Issues #7's PRIMARY bug (the legacy loop's atmosisa call, past the
%       first iteration, silently omitted the ft->m conversion).
%       This is structurally consistent with Mattingly's Case 1/Case 3
%       energy-height climb forms (Aircraft Engine Design, 2nd ed.,
%       Eq. 3.17/3.20) -- an explicit numerical (Euler) integration of the
%       stated dh_e/dt, dW_fuel/dt ODEs, rather than the legacy code's
%       single-step closed-form exp() shortcut (see this pass's report for
%       the full derivation showing the two forms agree in the small-step
%       limit; the direct numerical form was chosen because the subplan
%       explicitly calls for the method to be "integrated numerically").

    properties (Constant)
        N_SUBSEGMENTS = 20         % -- sub-interval count for Cruise/Dash/Combat/Loiter [subplan 07, "L3 -- sub-segmented Breguet"]
        N_SUBSEGMENTS_CLIMB = 40   % -- sub-interval count for Climb ONLY, decoupled from N_SUBSEGMENTS above (user-directed 2026-07-24: double MissionL2's N=20 climb resolution)

        % Engineering safeguard, NOT a physical constant/citation (user-directed
        % 2026-07-24, found while testing a heavier-than-Brandt starting weight):
        % segment_climb's energy-height integration divides by Ps = (T-D)*V/W.
        % At mil power, a heavy-enough aircraft can have D > T partway up a
        % fixed climb schedule (drag exceeds available thrust before reaching
        % the schedule's end altitude/Mach) -- Ps goes negative, and dt =
        % delta_he/Ps flips sign, producing NEGATIVE fuel burn (the aircraft
        % appears to GAIN weight climbing) instead of a large-but-positive
        % "struggling to climb" result. PS_FLOOR_FTS clamps Ps to a small
        % positive value in that regime so fuel/time stay positive and
        % finite -- this is a numerical safeguard against a genuine physical
        % edge case (mil power insufficient for the requested climb), not a
        % substitute for the real fix (an afterburner-climb option, not yet
        % implemented -- see segment_climb's Dry-only SCOPE NOTE).
        PS_FLOOR_FTS = 10
    end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the missiondata struct + W_TO + real aero/prop
        % objects, return the mission fuel result.
        % ================================================================== %

        function [W_fuel, breakdown] = get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj)
        %GET_MISSION_FUEL  Loop over missiondata.segment_names, dispatch each
        %   to the matching segment_<name> static, and aggregate the running
        %   weight into total mission fuel [lbf]. Cruise/Dash/Combat/Loiter
        %   are internally sub-segmented at N=20; Climb is sub-segmented
        %   separately at N=40 (N_SUBSEGMENTS_CLIMB); see class header.
        %   UNIT NOTE: missiondata.dist_nm_given is in nautical miles;
        %   segment_cruise/segment_dash take R_ft (feet) -- convert at
        %   6080 ft/nm (see MissionL1.get_mission_fuel).
        %   CLIMB START CONDITION: the previous segment's alt_ft/mach_end
        %   (segment i-1) is used as Climb's start altitude/Mach, since
        %   mission_profile.json's alt_ft/mach_end are AT-END-of-segment
        %   waypoints, i.e. the mission is a continuous piecewise path (see
        %   class header). Falls back to the Climb segment's own end
        %   condition if Climb is the first segment (defensive; never
        %   happens on the F-16 CAP profile, but any generic mission profile
        %   could in principle start with Climb).
        %   Mff/W_fuel aggregate note: see MissionL1.get_mission_fuel's
        %   header -- identical fuel-only-vs-payload-drop treatment.
            NM_TO_FT = 6080;   % ft/nm [VnV/BrandtF16A/BrandtMission.m convention]
            N       = MissionL3.N_SUBSEGMENTS;         % Cruise/Dash/Combat/Loiter
            N_climb = MissionL3.N_SUBSEGMENTS_CLIMB;   % Climb only -- decoupled, see class header

            names    = missiondata.segment_names;
            n        = numel(names);
            category = missiondata.aircraft_category;

            W         = W_TO;
            fuel_used = zeros(1, n);
            W_after   = zeros(1, n);

            for i = 1:n
                seg = MissionL1.normalize_segment_name(names(i));
                switch seg
                    case "startup"
                        [W, fu] = MissionL3.segment_startup(W, category);
                    case "taxi"
                        [W, fu] = MissionL3.segment_taxi(W, category);
                    case "takeoff"
                        [W, fu] = MissionL3.segment_takeoff(W, category);
                    case "climb"
                        if i > 1
                            alt_start_ft = missiondata.alt_ft(i-1);
                            mach_start   = missiondata.mach_end(i-1);
                        else
                            alt_start_ft = missiondata.alt_ft(i);
                            mach_start   = missiondata.mach_end(i);
                        end
                        [W, fu] = MissionL3.segment_climb(W, aero_obj, prop_obj, ...
                            alt_start_ft, missiondata.alt_ft(i), mach_start, missiondata.mach_end(i), N_climb);
                    case "cruise"
                        R_ft = missiondata.dist_nm_given(i) * NM_TO_FT;
                        [W, fu] = MissionL3.segment_cruise(W, aero_obj, prop_obj, ...
                            missiondata.alt_ft(i), missiondata.mach_end(i), R_ft, missiondata.dry_or_wet(i), N);
                    case "dash"
                        R_ft = missiondata.dist_nm_given(i) * NM_TO_FT;
                        [W, fu] = MissionL3.segment_dash(W, aero_obj, prop_obj, ...
                            missiondata.alt_ft(i), missiondata.mach_end(i), R_ft, missiondata.dry_or_wet(i), N);
                    case "combat"
                        [W, fu] = MissionL3.segment_combat(W, aero_obj, prop_obj, ...
                            missiondata.alt_ft(i), missiondata.mach_end(i), missiondata.time_min_given(i), ...
                            missiondata.dry_or_wet(i), missiondata.drop_lb(i), N);
                    case "loiter"
                        [W, fu] = MissionL3.segment_loiter(W, aero_obj, prop_obj, ...
                            missiondata.alt_ft(i), missiondata.mach_end(i), missiondata.time_min_given(i), ...
                            missiondata.dry_or_wet(i), N);
                    case "descent"
                        [W, fu] = MissionL3.segment_descent(W, category);
                    case "landing"
                        [W, fu] = MissionL3.segment_landing(W, category);
                    otherwise
                        error("MissionL3:unknownSegment", ...
                            "Unrecognized mission segment name: %s", names(i));
                end
                fuel_used(i) = fu;
                W_after(i)   = W;
            end

            total_fuel_used   = sum(fuel_used);
            W_final_fuel_only = W_TO - total_fuel_used;   % excludes payload drop -- see MissionL1.get_mission_fuel
            Mff    = MissionL1.compute_mission_fuel_fraction(W_TO, W_final_fuel_only);
            W_fuel = MissionL1.compute_mission_fuel_weight(W_TO, Mff, missiondata.RFF);

            breakdown = struct( ...
                'segment_names',       names, ...
                'fuel_used_lbf',       fuel_used, ...
                'W_after_lbf',         W_after, ...
                'W_TO_lbf',            W_TO, ...
                'total_fuel_used_lbf', total_fuel_used, ...
                'Mff',                 Mff, ...
                'W_fuel_lbf',          W_fuel);
        end

        % ================================================================== %
        % LOW-LEVEL: fixed-fraction segments -- delegate structurally to
        % MissionL1 (Roskam Table 2.1 has no aero/prop-based alternative).
        % ================================================================== %

        function [W_out, fuel_used] = segment_startup(W_in, aircraft_category)
        %SEGMENT_STARTUP  Fixed-fraction (Roskam Table 2.1) -- same as L1/L2.
            [W_out, fuel_used] = MissionL1.segment_startup(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_taxi(W_in, aircraft_category)
        %SEGMENT_TAXI  Fixed-fraction (Roskam Table 2.1) -- same as L1/L2.
            [W_out, fuel_used] = MissionL1.segment_taxi(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_takeoff(W_in, aircraft_category)
        %SEGMENT_TAKEOFF  Fixed-fraction (Roskam Table 2.1) -- same as L1/L2.
            [W_out, fuel_used] = MissionL1.segment_takeoff(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_descent(W_in, aircraft_category)
        %SEGMENT_DESCENT  Fixed-fraction (Roskam Table 2.1) -- same as L1/L2.
            [W_out, fuel_used] = MissionL1.segment_descent(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_landing(W_in, aircraft_category)
        %SEGMENT_LANDING  Fixed-fraction (Roskam Table 2.1) -- same as L1/L2.
            [W_out, fuel_used] = MissionL1.segment_landing(W_in, aircraft_category);
        end

        % ================================================================== %
        % LOW-LEVEL: sub-segmented real-aero/prop Breguet segments (N=20).
        % ================================================================== %

        function [W_out, fuel_used] = segment_cruise(W_in, aero_obj, prop_obj, alt_ft, mach, R_ft, dry_or_wet, N)
        %SEGMENT_CRUISE  Sub-segmented Breguet range form [Roskam Eq. 2.10],
        %   N sub-intervals, weight (and hence L/D via the drag polar)
        %   updated between sub-intervals.
            arguments
                W_in
                aero_obj
                prop_obj
                alt_ft
                mach
                R_ft
                dry_or_wet
                N (1,1) double {mustBePositive, mustBeInteger} = MissionL3.N_SUBSEGMENTS
            end
        %   [alt_ft, mach] describe the (constant-altitude/Mach) cruise
        %   condition; state = AircraftState(alt_ft, mach) is constructed
        %   once (or per sub-interval, if a future refinement varies it).
            state = AircraftState(alt_ft, mach);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            R_step_ft = R_ft / N;

            W = W_in;
            fuel_used = 0;
            for k = 1:N
                polar = aero_obj.drag_polar(state);
                CL    = aero_obj.compute_CL(W, state.q, aero_obj.S_ref);
                LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
                [W, fu] = MissionL3.breguet_range_step(W, TSFC, R_step_ft, state.V, LD);
                fuel_used = fuel_used + fu;
            end
            W_out = W;
        end

        function [W_out, fuel_used] = segment_dash(W_in, aero_obj, prop_obj, alt_ft, mach, R_ft, dry_or_wet, N)
        %SEGMENT_DASH  Same sub-segmented Breguet range form as Cruise.
            arguments
                W_in
                aero_obj
                prop_obj
                alt_ft
                mach
                R_ft
                dry_or_wet
                N (1,1) double {mustBePositive, mustBeInteger} = MissionL3.N_SUBSEGMENTS
            end
            state = AircraftState(alt_ft, mach);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            R_step_ft = R_ft / N;

            W = W_in;
            fuel_used = 0;
            for k = 1:N
                polar = aero_obj.drag_polar(state);
                CL    = aero_obj.compute_CL(W, state.q, aero_obj.S_ref);
                LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
                [W, fu] = MissionL3.breguet_range_step(W, TSFC, R_step_ft, state.V, LD);
                fuel_used = fuel_used + fu;
            end
            W_out = W;
        end

        function [W_out, fuel_used] = segment_combat(W_in, aero_obj, prop_obj, alt_ft, mach, t_min, dry_or_wet, W_drop, N)
        %SEGMENT_COMBAT  Sub-segmented Breguet endurance form [Roskam
        %   Eq. 2.12, per Section 2.6.3 Example 3: Fighter]. W_drop reduces
        %   weight at the end of the (whole) segment, not per sub-interval.
            arguments
                W_in
                aero_obj
                prop_obj
                alt_ft
                mach
                t_min
                dry_or_wet
                W_drop
                N (1,1) double {mustBePositive, mustBeInteger} = MissionL3.N_SUBSEGMENTS
            end
            state = AircraftState(alt_ft, mach);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            t_step_hr = (t_min / 60) / N;

            W = W_in;
            fuel_used = 0;
            for k = 1:N
                polar = aero_obj.drag_polar(state);
                CL    = aero_obj.compute_CL(W, state.q, aero_obj.S_ref);
                LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
                [W, fu] = MissionL3.breguet_endurance_step(W, TSFC, t_step_hr, LD);
                fuel_used = fuel_used + fu;
            end
            W_out = W - W_drop;
        end

        function [W_out, fuel_used] = segment_loiter(W_in, aero_obj, prop_obj, alt_ft, mach, t_min, dry_or_wet, N)
        %SEGMENT_LOITER  Sub-segmented Breguet endurance form [Roskam Eq. 2.12].
            arguments
                W_in
                aero_obj
                prop_obj
                alt_ft
                mach
                t_min
                dry_or_wet
                N (1,1) double {mustBePositive, mustBeInteger} = MissionL3.N_SUBSEGMENTS
            end
            state = AircraftState(alt_ft, mach);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            t_step_hr = (t_min / 60) / N;

            W = W_in;
            fuel_used = 0;
            for k = 1:N
                polar = aero_obj.drag_polar(state);
                CL    = aero_obj.compute_CL(W, state.q, aero_obj.S_ref);
                LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
                [W, fu] = MissionL3.breguet_endurance_step(W, TSFC, t_step_hr, LD);
                fuel_used = fuel_used + fu;
            end
            W_out = W;
        end

        function [W_out, fuel_used] = segment_climb(W_in, aero_obj, prop_obj, alt_start_ft, alt_end_ft, mach_start, mach_end, N)
        %SEGMENT_CLIMB  Energy-height integration (dh_e/dt = (T-D)V/W,
        %   dW_fuel/dt = TSFC*T), N sub-intervals between the start/end
        %   altitude+Mach. Fixes Known Issues #7's two legacy bugs (altitude
        %   unit conversion; abandoned gravity-variation array) -- does not
        %   replicate them. Mil-power thrust/TSFC are used unconditionally
        %   (Dry-only scope simplification -- see class header's SCOPE NOTE).
            arguments
                W_in
                aero_obj
                prop_obj
                alt_start_ft
                alt_end_ft
                mach_start
                mach_end
                N (1,1) double {mustBePositive, mustBeInteger} = MissionL3.N_SUBSEGMENTS_CLIMB
            end
            g0  = 32.174;      % ft/s^2 -- standard sea-level gravitational acceleration
            r_e = 20902231;    % ft -- mean Earth radius (standard value; legacy constant retained)

            h_pts = linspace(alt_start_ft, alt_end_ft, N+1);
            M_pts = linspace(mach_start, mach_end, N+1);

            state0  = AircraftState(h_pts(1), M_pts(1));
            g0_h    = g0 * (r_e / (r_e + h_pts(1)))^2;
            he_prev = h_pts(1) + state0.V^2 / (2*g0_h);

            W = W_in;
            fuel_used = 0;

            for k = 2:numel(h_pts)
                state_k = AircraftState(h_pts(k), M_pts(k));
                g_k     = g0 * (r_e / (r_e + h_pts(k)))^2;   % [Known Issues #7 secondary flag -- fixed: recomputed every step]
                he_k    = h_pts(k) + state_k.V^2 / (2*g_k);
                delta_he = he_k - he_prev;

                T = prop_obj.thrust_lapse_mil_on_AB_scale(state_k) * prop_obj.T_SL;  % mil-power thrust [lbf]
                polar = aero_obj.drag_polar(state_k);
                CL = aero_obj.compute_CL(W, state_k.q, aero_obj.S_ref);
                CD = aero_obj.compute_CD(polar.CD0, polar.K1, polar.K2, CL);
                D  = CD * state_k.q * aero_obj.S_ref;

                Ps_raw = MissionL3.energy_height_rate(T, D, state_k.V, W);   % ft/s
                Ps = max(Ps_raw, MissionL3.PS_FLOOR_FTS);   % engineering floor -- see class header PS_FLOOR_FTS note
                dt_s  = delta_he / Ps;   % s
                dt_hr = dt_s / 3600;     % hr

                TSFC = prop_obj.get_TSFC(state_k);   % mil-power TSFC [1/hr]
                fu = TSFC * T * dt_hr;                % dW_fuel = TSFC*T*dt
                W  = W - fu;
                fuel_used = fuel_used + fu;

                he_prev = he_k;
            end

            W_out = W;
        end

        % ================================================================== %
        % LOW-LEVEL: pure math -- single sub-interval steps, scalars only.
        % ================================================================== %

        function [W_out, fuel_used] = breguet_range_step(W_in, TSFC, R_step_ft, V_fts, LD)
        %BREGUET_RANGE_STEP  One N-th of segment_cruise/segment_dash's total
        %   range, reusing MissionL1.breguet_range_WF's form.
            WF = MissionL1.breguet_range_WF(TSFC, R_step_ft, V_fts, LD);
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = breguet_endurance_step(W_in, TSFC, t_step_hr, LD)
        %BREGUET_ENDURANCE_STEP  One N-th of segment_combat/segment_loiter's
        %   total time, reusing MissionL1.breguet_endurance_WF's form.
            WF = MissionL1.breguet_endurance_WF(TSFC, t_step_hr, LD);
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function dhe_dt = energy_height_rate(T, D, V, W)
        %ENERGY_HEIGHT_RATE  dh_e/dt = (T-D)*V/W  [Mattingly: Aircraft Engine Design, 2nd edition,
        %   structurally consistent with Case 1/Case 3 forms, Eq. 3.17/3.20].
            dhe_dt = (T - D) * V / W;
        end

    end

end
