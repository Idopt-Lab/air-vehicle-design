classdef MissionL2
%MISSIONL2  Level-2 mission-analysis static toolbox.
%
%   Call as MissionL2.method_name(args) -- no instantiation required.
%   Not in the inheritance chain. Student classes (F16MissionL2, etc.)
%   inherit from MissionModelL2 and call these statics to implement
%   compute_fuel.
%
%   TWO TIERS of statics (matching every other discipline toolbox):
%     High-level -- get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj):
%                   same generic named-segment dispatch loop shape as L1,
%                   but Cruise/Dash/Combat/Loiter now genuinely use
%                   aero_obj/prop_obj per segment.
%     Low-level  -- one segment_<name> per generic mission-segment type.
%                   Startup/Taxi/Takeoff/Descent/Landing are UNCHANGED
%                   fixed-fraction Table 2.1 lookups (delegates structurally
%                   to MissionL1 -- see MissionModelL2's header for why
%                   Table 2.1 has no aero/prop-based alternative at any
%                   fidelity level). Cruise/Dash/Combat/Loiter are
%                   single-point Breguet using REAL discipline objects
%                   instead of Table 2.2 lookups. Climb is discretized
%                   (N=20 sub-intervals, energy-height) -- see the CLIMB
%                   note at the end of this header.
%
%   EQUATIONS: same Roskam forms as L1 (Eq. 2.10 range / Eq. 2.12
%   endurance), evaluated by delegating to MissionL1's pure-math
%   segment_cruise/segment_dash/segment_combat/segment_loiter statics (the
%   underlying Breguet exponential form is fidelity-independent -- only the
%   INPUTS to it differ), but:
%     CD0/K1/K2  -- aero_obj.drag_polar(state)            [see AerodynamicsBase]
%     L/D        -- CL/CD at the segment's mid-weight CL (CL computed from
%                   the REAL flight condition's q via aero_obj.compute_CL,
%                   using the weight at the START of the segment as the
%                   single-point approximation -- matches
%                   temp_AI/docs/disciplines/05_mission_analysis.md's L2
%                   description and the legacy Level3 code's own
%                   aero_obj.CL(W_array(i-1), q, S_ref) convention). NO 0.866
%                   best-range correction here -- that factor exists only to
%                   approximate L/D at L1 when the real flight condition
%                   (and hence real CL) is unknown; at L2/L3 the mission
%                   profile already gives the exact Mach/altitude flown, so the REAL
%                   L/D at that exact point is computed directly and no
%                   idealized correction is needed (see this pass's report).
%     TSFC       -- prop_obj.get_TSFC(state) (mil, "Dry" segments) or
%                   prop_obj.compute_TSFC_AB(state) (AB, "Wet" segments --
%                   Dash/Combat), selected per-segment by missiondata.dry_or_wet.
%                   NOT an ad hoc scalar multiplier (Known Issues #4).
%   See docs/subplans/07_mission_analysis.md, "L2 -- single-point Breguet
%   with real discipline objects".
%
%   CLIMB (user-directed 2026-07-24): unlike Cruise/Dash/Combat/Loiter
%   above, Climb at L2 is NOT a single-point evaluation -- it is discretized
%   into N=20 sub-intervals (N_SUBSEGMENTS_CLIMB) of the same energy-height
%   integration MissionL3 uses for Climb (dh_e/dt=(T-D)V/W,
%   dW_fuel/dt=TSFC*T), delegating directly to MissionL3.segment_climb with
%   N=20 instead of L3's own N=40 (MissionL3.N_SUBSEGMENTS_CLIMB) -- the
%   underlying integrator is fidelity-independent; only the sub-interval
%   count differs between L2 and L3, exactly like the Breguet forms already
%   shared via MissionL1's pure-math statics.

    properties (Constant)
        N_SUBSEGMENTS_CLIMB = 20   % -- Climb sub-interval count at L2 (user-directed 2026-07-24; L3 uses N=40, see MissionL3.N_SUBSEGMENTS_CLIMB)
    end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the missiondata struct + W_TO + real aero/prop
        % objects, return the mission fuel result.
        % ================================================================== %

        function [W_fuel, breakdown] = get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj)
        %GET_MISSION_FUEL  Loop over missiondata.segment_names, dispatch each
        %   to the matching segment_<name> static (constructing an
        %   AircraftState(alt_ft(i), mach_end(i)) per segment as needed),
        %   and aggregate the running weight into total mission fuel [lbf].
        %   aero_obj/prop_obj -- REAL discipline objects, called once per
        %   segment for Cruise/Dash/Combat/Loiter (see class header).
        %   UNIT NOTE: missiondata.dist_nm_given is in nautical miles;
        %   segment_cruise/segment_dash take R_ft (feet) -- convert at
        %   6080 ft/nm (see MissionL1.get_mission_fuel).
        %   Mff/W_fuel aggregate note: see MissionL1.get_mission_fuel's
        %   header -- identical fuel-only-vs-payload-drop treatment applies
        %   here (both reuse MissionL1.compute_mission_fuel_fraction/
        %   compute_mission_fuel_weight, which are fidelity-independent).
            NM_TO_FT = 6080;   % ft/nm [VnV/BrandtF16A/BrandtMission.m convention]

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
                        [W, fu] = MissionL2.segment_startup(W, category);
                    case "taxi"
                        [W, fu] = MissionL2.segment_taxi(W, category);
                    case "takeoff"
                        [W, fu] = MissionL2.segment_takeoff(W, category);
                    case "climb"
                        % Climb's start condition is the PREVIOUS segment's
                        % end condition -- mission_profile.json's alt_ft/
                        % mach_end are AT-END-of-segment waypoints, i.e. the
                        % mission is a continuous piecewise path (same
                        % convention MissionL3.get_mission_fuel uses).
                        if i > 1
                            alt_start_ft = missiondata.alt_ft(i-1);
                            mach_start   = missiondata.mach_end(i-1);
                        else
                            alt_start_ft = missiondata.alt_ft(i);
                            mach_start   = missiondata.mach_end(i);
                        end
                        [W, fu] = MissionL2.segment_climb(W, aero_obj, prop_obj, ...
                            alt_start_ft, missiondata.alt_ft(i), mach_start, missiondata.mach_end(i));
                    case "cruise"
                        state = AircraftState(missiondata.alt_ft(i), missiondata.mach_end(i));
                        R_ft  = missiondata.dist_nm_given(i) * NM_TO_FT;
                        [W, fu] = MissionL2.segment_cruise(W, aero_obj, prop_obj, state, R_ft, missiondata.dry_or_wet(i));
                    case "dash"
                        state = AircraftState(missiondata.alt_ft(i), missiondata.mach_end(i));
                        R_ft  = missiondata.dist_nm_given(i) * NM_TO_FT;
                        [W, fu] = MissionL2.segment_dash(W, aero_obj, prop_obj, state, R_ft, missiondata.dry_or_wet(i));
                    case "combat"
                        state = AircraftState(missiondata.alt_ft(i), missiondata.mach_end(i));
                        [W, fu] = MissionL2.segment_combat(W, aero_obj, prop_obj, state, missiondata.time_min_given(i), missiondata.dry_or_wet(i), missiondata.drop_lb(i));
                    case "loiter"
                        state = AircraftState(missiondata.alt_ft(i), missiondata.mach_end(i));
                        [W, fu] = MissionL2.segment_loiter(W, aero_obj, prop_obj, state, missiondata.time_min_given(i), missiondata.dry_or_wet(i));
                    case "descent"
                        [W, fu] = MissionL2.segment_descent(W, category);
                    case "landing"
                        [W, fu] = MissionL2.segment_landing(W, category);
                    otherwise
                        error("MissionL2:unknownSegment", ...
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
        %SEGMENT_STARTUP  Fixed-fraction (Roskam Table 2.1) -- same as L1.
            [W_out, fuel_used] = MissionL1.segment_startup(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_taxi(W_in, aircraft_category)
        %SEGMENT_TAXI  Fixed-fraction (Roskam Table 2.1) -- same as L1.
            [W_out, fuel_used] = MissionL1.segment_taxi(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_takeoff(W_in, aircraft_category)
        %SEGMENT_TAKEOFF  Fixed-fraction (Roskam Table 2.1) -- same as L1.
            [W_out, fuel_used] = MissionL1.segment_takeoff(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_climb(W_in, aero_obj, prop_obj, alt_start_ft, alt_end_ft, mach_start, mach_end)
        %SEGMENT_CLIMB  Discretized energy-height integration, N=20
        %   sub-intervals (N_SUBSEGMENTS_CLIMB) -- user-directed 2026-07-24.
        %   Delegates to MissionL3.segment_climb (the energy-height
        %   integrator itself is fidelity-independent; only N differs
        %   between L2 (20) and L3 (40, MissionL3.N_SUBSEGMENTS_CLIMB)).
            [W_out, fuel_used] = MissionL3.segment_climb(W_in, aero_obj, prop_obj, ...
                alt_start_ft, alt_end_ft, mach_start, mach_end, MissionL2.N_SUBSEGMENTS_CLIMB);
        end

        function [W_out, fuel_used] = segment_descent(W_in, aircraft_category)
        %SEGMENT_DESCENT  Fixed-fraction (Roskam Table 2.1) -- same as L1.
            [W_out, fuel_used] = MissionL1.segment_descent(W_in, aircraft_category);
        end

        function [W_out, fuel_used] = segment_landing(W_in, aircraft_category)
        %SEGMENT_LANDING  Fixed-fraction (Roskam Table 2.1) -- same as L1.
            [W_out, fuel_used] = MissionL1.segment_landing(W_in, aircraft_category);
        end

        % ================================================================== %
        % LOW-LEVEL: real-aero/prop Breguet segments.
        % ================================================================== %

        function [W_out, fuel_used] = segment_cruise(W_in, aero_obj, prop_obj, state, R_ft, dry_or_wet)
        %SEGMENT_CRUISE  Breguet range form [Roskam Eq. 2.10] with CD0/K1/K2
        %   from aero_obj.drag_polar(state) and TSFC from prop_obj (mil/AB
        %   selected by dry_or_wet).
            polar = aero_obj.drag_polar(state);
            CL    = aero_obj.compute_CL(W_in, state.q, aero_obj.S_ref);
            LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            [W_out, fuel_used] = MissionL1.segment_cruise(W_in, TSFC, R_ft, state.V, LD);
        end

        function [W_out, fuel_used] = segment_dash(W_in, aero_obj, prop_obj, state, R_ft, dry_or_wet)
        %SEGMENT_DASH  Same Breguet range form as Cruise [Roskam Eq. 2.10],
        %   real aero/prop objects (typically AB/"Wet" -- prop_obj.compute_TSFC_AB).
            polar = aero_obj.drag_polar(state);
            CL    = aero_obj.compute_CL(W_in, state.q, aero_obj.S_ref);
            LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            [W_out, fuel_used] = MissionL1.segment_dash(W_in, TSFC, R_ft, state.V, LD);
        end

        function [W_out, fuel_used] = segment_combat(W_in, aero_obj, prop_obj, state, t_min, dry_or_wet, W_drop)
        %SEGMENT_COMBAT  Breguet endurance form [Roskam Eq. 2.12, per Section
        %   2.6.3 Example 3: Fighter, "Strafe" phase]. L/D from
        %   aero_obj.drag_polar(state) at the maneuvering condition (no 0.866
        %   correction -- Known Issues #3). W_drop reduces weight at the end
        %   of the segment directly.
            polar = aero_obj.drag_polar(state);
            CL    = aero_obj.compute_CL(W_in, state.q, aero_obj.S_ref);
            LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            [W_out, fuel_used] = MissionL1.segment_combat(W_in, t_min, TSFC, LD, W_drop);
        end

        function [W_out, fuel_used] = segment_loiter(W_in, aero_obj, prop_obj, state, t_min, dry_or_wet)
        %SEGMENT_LOITER  Breguet endurance form [Roskam Eq. 2.12], real
        %   aero/prop objects.
            polar = aero_obj.drag_polar(state);
            CL    = aero_obj.compute_CL(W_in, state.q, aero_obj.S_ref);
            LD    = MissionL2.LD_from_polar(CL, polar.CD0, polar.K1, polar.K2);
            TSFC  = MissionL2.select_TSFC(prop_obj, state, dry_or_wet);
            [W_out, fuel_used] = MissionL1.segment_loiter(W_in, t_min, TSFC, LD);
        end

        % ================================================================== %
        % LOW-LEVEL: pure math / dispatch helpers -- scalars only.
        % ================================================================== %

        function LD = LD_from_polar(CL, CD0, K1, K2)
        %LD_FROM_POLAR  L/D = CL / CD, CD = CD0 + K1*CL^2 + K2*CL
        %   [AerodynamicsBase.compute_CD form -- reused here, not
        %   re-derived, to stay consistent with the active drag polar].
            CD = CD0 + K1*CL^2 + K2*CL;
            LD = CL / CD;
        end

        function TSFC = select_TSFC(prop_obj, state, dry_or_wet)
        %SELECT_TSFC  Dispatch to prop_obj.get_TSFC(state) ("Dry") or
        %   prop_obj.compute_TSFC_AB(state) ("Wet") per the missiondata
        %   dry_or_wet flag.
            switch lower(strtrim(string(dry_or_wet)))
                case "dry"
                    TSFC = prop_obj.get_TSFC(state);
                case "wet"
                    TSFC = prop_obj.compute_TSFC_AB(state);
                otherwise
                    error('MissionL2:unknownDryOrWet', ...
                        'Unrecognized dry_or_wet flag "%s" -- expected "Dry" or "Wet".', dry_or_wet);
            end
        end

    end

end
