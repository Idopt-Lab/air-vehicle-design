classdef MissionL1
%MISSIONL1  Level-1 mission-analysis static toolbox.
%
%   Call as MissionL1.method_name(args) -- no instantiation required.
%   Not in the inheritance chain. Student classes (F16MissionL1, etc.)
%   inherit from MissionModelL1 and call these statics to implement
%   compute_fuel.
%
%   TWO TIERS of statics (matching every other discipline toolbox):
%     High-level -- get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj):
%                   the generic named-segment dispatch loop (preserves the
%                   legacy MissionAnalysisLevel1/F16MissionAnalysisLevel1
%                   structure per direct user instruction -- see subplan's
%                   "high-level static IS the generic segment-dispatch
%                   loop" section). aero_obj/prop_obj are accepted (shared
%                   Tier-1 signature) but are NEVER called at L1 -- only
%                   AircraftState (core atmosphere, not a discipline object)
%                   is used, to get true airspeed V from Mach + altitude.
%     Low-level  -- one segment_<name> per generic mission-segment type
%                   (Startup, Taxi, Takeoff, Climb, Cruise, Dash, Combat,
%                   Loiter, Descent, Landing -- Roskam's own generic phase
%                   categories, Dash/Combat included as fighter-relevant
%                   extensions; NOT specific to any one aircraft's mission
%                   profile), plus pure-math Breguet/table-lookup helpers.
%
%   EQUATIONS (see docs/subplans/07_mission_analysis.md's "L1 -- Roskam
%   Table 2.1 fixed fractions + Table 2.2 tabulated Breguet" table for the
%   full citation-by-citation breakdown):
%     Fixed-fraction segments (Startup/Taxi/Takeoff/Climb/Descent/Landing):
%       Roskam Airplane Design Part I, Table 2.1 (category row lookup;
%       Climb uses the table's fighter-range midpoint, NOT the uncited
%       "1.0065-0.0325*Mach" legacy formula -- Known Issues #9).
%     Breguet-form segments (Cruise/Dash/Loiter):
%       Roskam Eq. 2.10 (range, Cruise/Dash) / Eq. 2.12 (endurance, Loiter);
%       L/D, TSFC from Roskam Table 2.2 category row. Cruise/Dash share the
%       identical tabulated cj/LD (Roskam's method has no separate Dash
%       category -- Known Issues #4) and Cruise/Dash's LD gets the 0.866
%       best-range correction (Known Issues #3 secondary flag).
%     Combat: Roskam Eq. 2.12 (Breguet endurance), per the method
%       demonstrated in Roskam Sec. 2.6.3 Example 3: Fighter, Table 2.19
%       "Strafe" phase -- a DIRECTLY-ASSUMED L/D=4.5, cj=0.9 (Known Issues
%       #3), since Table 2.2 has no combat/strafe category for ANY aircraft
%       type. NOT the cruise-category cj/LD (see lookup_combat_condition).
%     Mission aggregate: Roskam Eq. 2.13 (fuel fraction) + Eq. 2.14/2.15
%       (fuel weight incl. reserve, RFF=0.06 per Design Notes). Mff is
%       computed from a FUEL-ONLY running weight (W_TO - total_fuel_used),
%       deliberately excluding the Combat payload drop -- see
%       get_mission_fuel's inline comment for the full derivation of why
%       this differs from the raw W_final/W_TO ratio.

    properties (Constant)
        % Roskam Airplane Design Part I, Table 2.1 (p.12) -- fixed fuel-
        % weight fractions Wi/Wi-1 by aircraft category and mission phase.
        % Ranges are stored as {[min max]} and resolved to their mean by
        % lookup_fixed_fraction, matching AeroL1.CLmax_table's convention.
        % Fighter row independently re-verified against the book 2026-07-24
        % (subplan 07, Known Issues (A)); other rows carried forward from
        % temp_Casey/src/Disciplines/MissionAnalysis/MissionAnalysisLevel1.m
        % (spot-checked only for Fighter, not re-transcribed from scratch).
        fuel_fraction_table = MissionL1.build_fuel_fraction_table()

        % Roskam Airplane Design Part I, Table 2.2 (p.14) -- tabulated
        % cruise/loiter L/D and jet TSFC (cj, 1/hr) by aircraft category.
        % Fighter row (cruise LD=[4 7], cj=[0.6 1.4], loiter LD=[6 9],
        % cj=[0.6 0.8]) independently re-verified 2026-07-24. Propeller-only
        % columns (cp, eta_p) are intentionally omitted -- not needed by any
        % jet-category aircraft this framework currently models (PLAN.md's
        % "no feature added beyond what the current step requires").
        table22 = MissionL1.build_table22()

        % Roskam Airplane Design Part I, Sec. 2.6.3 Example 3: Fighter,
        % Table 2.19 "Strafe" phase -- the book's own worked-example
        % precedent for a combat/strafe condition (directly-assumed L/D and
        % cj, NOT derived from any generic table). Table 2.2 has NO
        % combat/strafe row for any aircraft category (Known Issues #3), so
        % this is the only citable numeric source available, and it only
        % covers "fighter" -- see lookup_combat_condition.
        combat_condition_fighter = struct('LD', 4.5, 'cj', 0.9)
    end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the missiondata struct + W_TO (+ aero/prop, unused
        % at L1), return the mission fuel result.
        % ================================================================== %

        function [W_fuel, breakdown] = get_mission_fuel(missiondata, W_TO, aero_obj, prop_obj)
        %GET_MISSION_FUEL  Loop over missiondata.segment_names, dispatch each
        %   to the matching segment_<name> static, and aggregate the running
        %   weight into a total mission fuel weight [lbf].
        %   missiondata -- struct from MissionProfileImporter.read_json /
        %                  F16MissionL1.missiondata (segment_names, alt_ft,
        %                  mach_end, dist_nm_given, time_min_given, drop_lb,
        %                  dry_or_wet, CLmax_TO, CLmax_land, mu_rolling,
        %                  liftoff_factor, warmup_fuel_per_engine_lb, RFF,
        %                  aircraft_category).
        %   W_TO        -- current gross takeoff weight guess [lbf].
        %   aero_obj    -- UNUSED at L1 (accepted only for Tier-1 signature
        %                  parity). NEVER called -- see class header.
        %   prop_obj    -- UNUSED at L1. NEVER called.
        %   Returns: W_fuel (total mission fuel [lbf], incl. RFF reserve)
        %   and breakdown (struct of per-segment arrays for a waterfall
        %   chart / fidelity-overlay plot).
        %
        %   NOTE on Mff/W_fuel vs. the running weight W: the loop's own
        %   running weight W (fed forward into each next segment, matching
        %   the legacy W_array/BrandtMission.run accumulator pattern)
        %   INCLUDES the Combat payload drop, because subsequent segments'
        %   physics must see the real (lighter) aircraft. But Roskam's Mff
        %   (Eq. 2.13) and the resulting mission FUEL weight (Eq. 2.14/2.15)
        %   are properties of FUEL burned only -- payload jettisoned is not
        %   fuel. So Mff/W_fuel are computed from total_fuel_used (the sum
        %   of each segment's own fuel_used return value, which every
        %   segment_* static already keeps separate from any payload drop --
        %   see segment_combat), NOT from the real final running weight
        %   (which would double-count the 4,400 lbf drop as if it were
        %   fuel). This is exactly the design notes' "W_drop reduces weight
        %   directly, not routed through the fuel fraction" rule, applied
        %   consistently to the aggregate Mff/W_fuel calculation too.
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
                        [W, fu] = MissionL1.segment_startup(W, category);
                    case "taxi"
                        [W, fu] = MissionL1.segment_taxi(W, category);
                    case "takeoff"
                        [W, fu] = MissionL1.segment_takeoff(W, category);
                    case "climb"
                        [W, fu] = MissionL1.segment_climb(W, category);
                    case "cruise"
                        state = AircraftState(missiondata.alt_ft(i), missiondata.mach_end(i));
                        R_ft  = missiondata.dist_nm_given(i) * NM_TO_FT;
                        TSFC  = MissionL1.lookup_table22(category, "cruise", "cj");
                        LD    = MissionL1.apply_best_range_correction(MissionL1.lookup_table22(category, "cruise", "LD"));
                        [W, fu] = MissionL1.segment_cruise(W, TSFC, R_ft, state.V, LD);
                    case "dash"
                        state = AircraftState(missiondata.alt_ft(i), missiondata.mach_end(i));
                        R_ft  = missiondata.dist_nm_given(i) * NM_TO_FT;
                        % Known Issues #4: no separate Dash category in
                        % Roskam Table 2.2 -- reuse the same tabulated
                        % cruise cj/LD (NOT a TSFC_cruise*10 scalar bug).
                        TSFC  = MissionL1.lookup_table22(category, "cruise", "cj");
                        LD    = MissionL1.apply_best_range_correction(MissionL1.lookup_table22(category, "cruise", "LD"));
                        [W, fu] = MissionL1.segment_dash(W, TSFC, R_ft, state.V, LD);
                    case "combat"
                        combat = MissionL1.lookup_combat_condition(category);
                        [W, fu] = MissionL1.segment_combat(W, missiondata.time_min_given(i), combat.cj, combat.LD, missiondata.drop_lb(i));
                    case "loiter"
                        TSFC = MissionL1.lookup_table22(category, "loiter", "cj");
                        LD   = MissionL1.lookup_table22(category, "loiter", "LD");
                        [W, fu] = MissionL1.segment_loiter(W, missiondata.time_min_given(i), TSFC, LD);
                    case "descent"
                        [W, fu] = MissionL1.segment_descent(W, category);
                    case "landing"
                        [W, fu] = MissionL1.segment_landing(W, category);
                    otherwise
                        error("MissionL1:unknownSegment", ...
                            "Unrecognized mission segment name: %s", names(i));
                end
                fuel_used(i) = fu;
                W_after(i)   = W;
            end

            total_fuel_used = sum(fuel_used);
            W_final_fuel_only = W_TO - total_fuel_used;   % excludes payload drop -- see note above
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
        % LOW-LEVEL: one static per generic mission-segment type. All
        % take/return weight in lbf. [W_out, fuel_used] = segment_<name>(W_in, ...).
        % ================================================================== %

        function [W_out, fuel_used] = segment_startup(W_in, aircraft_category)
        %SEGMENT_STARTUP  Fixed-fraction (Roskam Table 2.1).
            WF = MissionL1.lookup_fixed_fraction(aircraft_category, "startup");
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_taxi(W_in, aircraft_category)
        %SEGMENT_TAXI  Fixed-fraction (Roskam Table 2.1).
            WF = MissionL1.lookup_fixed_fraction(aircraft_category, "taxi");
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_takeoff(W_in, aircraft_category)
        %SEGMENT_TAKEOFF  Fixed-fraction (Roskam Table 2.1; corrects the
        %   legacy 0.95 bug -- see Known Issues #1).
            WF = MissionL1.lookup_fixed_fraction(aircraft_category, "takeoff");
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_climb(W_in, aircraft_category)
        %SEGMENT_CLIMB  Fixed-fraction (Roskam Table 2.1 range, representative
        %   point) -- NOT the uncited 1.0065-0.0325*Mach formula (Known
        %   Issues #9). L1 is tabulated-only by design (MissionModelL1's
        %   header) and never calls aero/prop, so the fixed-fraction table is
        %   its only climb method -- L2/L3 instead discretize Climb with a
        %   real energy-height integration (MissionL2/MissionL3.segment_climb,
        %   N=20/N=40 respectively; see those files' headers).
            WF = MissionL1.lookup_fixed_fraction(aircraft_category, "climb");
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_cruise(W_in, TSFC, R_ft, V_fts, LD)
        %SEGMENT_CRUISE  Breguet range form [Roskam Eq. 2.10]. LD is the
        %   Table 2.2 category L/D with the 0.866 best-range correction
        %   already applied (see apply_best_range_correction).
            WF = MissionL1.breguet_range_WF(TSFC, R_ft, V_fts, LD);
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_dash(W_in, TSFC, R_ft, V_fts, LD)
        %SEGMENT_DASH  Same Breguet range form as Cruise [Roskam Eq. 2.10];
        %   same tabulated TSFC/LD category (Known Issues #4 -- no separate
        %   Dash TSFC category at L1, replaces the legacy TSFC_dash=TSFC_cruise*10 bug).
            WF = MissionL1.breguet_range_WF(TSFC, R_ft, V_fts, LD);
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_combat(W_in, t_min, TSFC, LD, W_drop)
        %SEGMENT_COMBAT  Breguet endurance form [Roskam Eq. 2.12, applied per
        %   the method demonstrated in Section 2.6.3 Example 3: Fighter,
        %   "Strafe" phase -- Known Issues #3]. LD is DIRECTLY supplied (no
        %   0.866 correction -- Combat is not a best-range condition).
        %   W_drop reduces weight at the end of the segment directly (not
        %   routed through the fuel fraction).
            t_hr = t_min / 60;
            WF = MissionL1.breguet_endurance_WF(TSFC, t_hr, LD);
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used - W_drop;
        end

        function [W_out, fuel_used] = segment_loiter(W_in, t_min, TSFC, LD)
        %SEGMENT_LOITER  Breguet endurance form [Roskam Eq. 2.12].
            t_hr = t_min / 60;
            WF = MissionL1.breguet_endurance_WF(TSFC, t_hr, LD);
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_descent(W_in, aircraft_category)
        %SEGMENT_DESCENT  Fixed-fraction (Roskam Table 2.1; corrects the
        %   legacy "not implemented, WF=1.0 placeholder" gap -- Known Issues #5).
            WF = MissionL1.lookup_fixed_fraction(aircraft_category, "descent");
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        function [W_out, fuel_used] = segment_landing(W_in, aircraft_category)
        %SEGMENT_LANDING  Fixed-fraction (Roskam Table 2.1).
            WF = MissionL1.lookup_fixed_fraction(aircraft_category, "landing");
            fuel_used = W_in * (1 - WF);
            W_out     = W_in - fuel_used;
        end

        % ================================================================== %
        % LOW-LEVEL: pure math + table lookups -- scalars only.
        % ================================================================== %

        function WF = breguet_range_WF(TSFC, R_ft, V_fts, LD)
        %BREGUET_RANGE_WF  WF = exp(-(R*TSFC)/(V*LD))  [Roskam Eq. 2.10,
        %   algebraically rearranged to a weight-fraction form]. TSFC is in
        %   1/hr (PropulsionBase convention); R_ft/V_fts gives a time in
        %   SECONDS, converted to hours (/3600) before combining with TSFC
        %   so the exponent is dimensionless.
            t_hr = (R_ft / V_fts) / 3600;
            WF = exp(-(TSFC * t_hr) / LD);
        end

        function WF = breguet_endurance_WF(TSFC, t_hr, LD)
        %BREGUET_ENDURANCE_WF  WF = exp(-(t*TSFC)/LD)  [Roskam Eq. 2.12,
        %   algebraically rearranged to a weight-fraction form]. t_hr must
        %   already be in hours (matches TSFC's 1/hr convention).
            WF = exp(-(TSFC * t_hr) / LD);
        end

        function LD_range = apply_best_range_correction(LD_max)
        %APPLY_BEST_RANGE_CORRECTION  LD_range = LD_max*0.866 (=sqrt(3)/2)
        %   best-range correction for a parabolic drag polar -- Cruise/Dash
        %   ONLY (Known Issues #3 secondary flag: NOT Combat, which gets its
        %   L/D supplied directly). Uncited-but-standard result, not pinned
        %   to a Roskam equation number.
            LD_range = LD_max * 0.866;
        end

        function WF = lookup_fixed_fraction(aircraft_category, segment_name)
        %LOOKUP_FIXED_FRACTION  Roskam Table 2.1 fixed weight fraction by
        %   category row and segment column (Startup/Taxi/Takeoff/Climb/
        %   Descent/Landing). Fighters row verified 2026-07-24: 0.990,
        %   0.990, 0.990, [0.90 0.96], 0.990, 0.995.
            T   = MissionL1.fuel_fraction_table;
            cat = lower(strtrim(string(aircraft_category)));
            row = T(T.AircraftType == cat, :);
            if isempty(row)
                error('MissionL1:unknownCategory', ...
                    'Unrecognized aircraft category "%s". Add it to MissionL1.build_fuel_fraction_table.', ...
                    aircraft_category);
            end

            seg = MissionL1.normalize_segment_name(segment_name);
            switch seg
                case "startup",  WF = mean(row.Startup{1});
                case "taxi",     WF = mean(row.Taxi{1});
                case "takeoff",  WF = mean(row.Takeoff{1});
                case "climb",    WF = mean(row.Climb{1});
                case "descent",  WF = mean(row.Descent{1});
                case "landing",  WF = mean(row.Landing{1});
                otherwise
                    error('MissionL1:unknownSegment', ...
                        'Unrecognized fixed-fraction mission segment "%s".', segment_name);
            end
        end

        function val = lookup_table22(aircraft_category, phase, quantity)
        %LOOKUP_TABLE22  Roskam Table 2.2 tabulated cruise/loiter L/D or TSFC
        %   (cj) by category row. phase = "cruise" | "loiter";
        %   quantity = "LD" | "cj". Fighters row verified 2026-07-24:
        %   cruise LD=[4 7], loiter LD=[6 9] (spot-checked against the book).
            T   = MissionL1.table22;
            cat = lower(strtrim(string(aircraft_category)));
            row = T(T.AircraftType == cat, :);
            if isempty(row)
                error('MissionL1:unknownCategory', ...
                    'Unrecognized aircraft category "%s". Add it to MissionL1.build_table22.', ...
                    aircraft_category);
            end

            phase_n    = lower(strtrim(string(phase)));
            quantity_n = lower(strtrim(string(quantity)));

            switch phase_n
                case "cruise"
                    switch quantity_n
                        case "ld", val = mean(row.cruise_LD{1});
                        case "cj", val = mean(row.cruise_cj{1});
                        otherwise
                            error('MissionL1:unknownQuantity', ...
                                'quantity must be "LD" or "cj", got "%s".', quantity);
                    end
                case "loiter"
                    switch quantity_n
                        case "ld", val = mean(row.loiter_LD{1});
                        case "cj", val = mean(row.loiter_cj{1});
                        otherwise
                            error('MissionL1:unknownQuantity', ...
                                'quantity must be "LD" or "cj", got "%s".', quantity);
                    end
                otherwise
                    error('MissionL1:unknownPhase', ...
                        'phase must be "cruise" or "loiter", got "%s".', phase);
            end
        end

        function val = lookup_combat_condition(aircraft_category)
        %LOOKUP_COMBAT_CONDITION  Directly-assumed combat/strafe L/D and
        %   TSFC (cj) -- Roskam Airplane Design Part I, Sec. 2.6.3 Example 3:
        %   Fighter, Table 2.19 "Strafe" phase (L/D=4.5, cj=0.9). Roskam's
        %   generic Table 2.2 has NO combat/strafe row for any aircraft
        %   category (Known Issues #3) -- this worked-example precedent is
        %   the only citable source available, and it only covers "fighter".
        %   Returns struct with fields LD, cj.
        %   Errors for any other category rather than inventing a citation
        %   (PLAN.md rule) -- add a real citation before extending this.
            cat = lower(strtrim(string(aircraft_category)));
            switch cat
                case "fighter"
                    val = MissionL1.combat_condition_fighter;
                otherwise
                    error('MissionL1:unknownCategory', ...
                        ['No Roskam-cited combat/strafe L/D and cj are available for ' ...
                         'aircraft_category "%s" -- only "fighter" is cited (Roskam Table 2.19, ' ...
                         'Sec. 2.6.3 Example 3). Add a citation before using this category.'], ...
                        aircraft_category);
            end
        end

        function Mff = compute_mission_fuel_fraction(W_TO, W_final)
        %COMPUTE_MISSION_FUEL_FRACTION  Mff = W_final/W_TO [Roskam Eq. 2.13's
        %   telescoping product (W1/W_TO)*prod(Wi+1/Wi), which collapses
        %   exactly to W_final/W_TO]. Callers decide what "W_final" means --
        %   get_mission_fuel passes a FUEL-ONLY final weight (excluding any
        %   payload drop) so the resulting Mff is a pure fuel-weight
        %   fraction, matching Roskam's own (payload-drop-free) definition.
            Mff = W_final / W_TO;
        end

        function W_F = compute_mission_fuel_weight(W_TO, Mff, RFF)
        %COMPUTE_MISSION_FUEL_WEIGHT  W_F = (1-Mff)*W_TO + W_Fres [Roskam
        %   Eq. 2.14/2.15]; W_Fres = RFF*(1-Mff)*W_TO per the RFF=0.06
        %   reserve term (Design Notes -- generic 6% reserve+trapped-fuel
        %   allowance, NOT Roskam's own mission-specific reserve treatment).
        %   Reproduces the legacy code's validated total_fuel_used*1.06
        %   behavior exactly when Mff is the fuel-only fraction described in
        %   compute_mission_fuel_fraction's header.
            W_F_no_reserve = (1 - Mff) * W_TO;
            W_Fres = RFF * W_F_no_reserve;
            W_F = W_F_no_reserve + W_Fres;
        end

        function name = normalize_segment_name(raw)
        %NORMALIZE_SEGMENT_NAME  Lowercase, strip digits and underscores from
        %   a mission segment name (e.g. "Cruise2" -> "cruise"), matching the
        %   legacy MissionAnalysisLevel1 dispatch loop's digit-stripped
        %   string-match convention (Known Issues (C), preserved
        %   structurally). Shared by MissionL2/MissionL3's dispatch loops too.
            name = lower(string(raw));
            name = erase(name, digitsPattern());
            name = erase(name, "_");
        end

    end

    methods (Static, Access = private)

        function T = build_fuel_fraction_table()
        %BUILD_FUEL_FRACTION_TABLE  Roskam Airplane Design Part I, Table 2.1
        %   (p.12). Ranges stored as {[min max]}; lookup_fixed_fraction
        %   resolves them to their mean.
            row = @(cat, startup, taxi, takeoff, climb, descent, landing) table( ...
                string(cat), {startup}, {taxi}, {takeoff}, {climb}, {descent}, {landing}, ...
                'VariableNames', {'AircraftType', 'Startup', 'Taxi', 'Takeoff', 'Climb', 'Descent', 'Landing'});

            T = [
                row("homebuilt",                    0.998, 0.998, 0.998, 0.995,       0.995, 0.995)
                row("single_engine",                0.995, 0.997, 0.998, 0.992,       0.993, 0.993)
                row("twin_engine",                  0.992, 0.996, 0.996, 0.990,       0.992, 0.992)
                row("agricultural",                 0.996, 0.995, 0.996, 0.998,       0.999, 0.998)
                row("business_jet",                 0.990, 0.995, 0.995, 0.980,       0.990, 0.992)
                row("regional_tbp",                 0.990, 0.995, 0.995, 0.985,       0.985, 0.995)
                row("transport_jet",                0.990, 0.990, 0.995, 0.980,       0.990, 0.992)
                row("military_trainer",             0.990, 0.990, 0.990, 0.980,       0.990, 0.995)
                row("fighter",                       0.990, 0.990, 0.990, [0.90 0.96], 0.990, 0.995)
                row("mil_patrol_bomb_transport",    0.990, 0.990, 0.995, 0.980,       0.990, 0.992)
                row("flying_boat_amphibious_float", 0.992, 0.990, 0.996, 0.985,       0.990, 0.990)
                row("supersonic_cruise",            0.990, 0.995, 0.995, [0.87 0.92], 0.985, 0.992)
                ];
        end

        function T = build_table22()
        %BUILD_TABLE22  Roskam Airplane Design Part I, Table 2.2 (p.14) --
        %   jet cruise/loiter L/D and cj (1/hr) columns only.
            row = @(cat, cruise_LD, cruise_cj, loiter_LD, loiter_cj) table( ...
                string(cat), {cruise_LD}, {cruise_cj}, {loiter_LD}, {loiter_cj}, ...
                'VariableNames', {'AircraftType', 'cruise_LD', 'cruise_cj', 'loiter_LD', 'loiter_cj'});

            T = [
                row("homebuilt",                    [8 10],  NaN,       [10 12], NaN)
                row("single_engine",                [8 10],  NaN,       [10 12], NaN)
                row("twin_engine",                  [8 10],  NaN,       [9 11],  NaN)
                row("agricultural",                 [5 7],   NaN,       [8 10],  NaN)
                row("business_jet",                 [10 12], [0.5 0.9], [12 14], [0.4 0.6])
                row("regional_tbp",                 [11 13], NaN,       [14 16], NaN)
                row("transport_jet",                [13 15], [0.5 0.9], [14 18], [0.4 0.6])
                row("military_trainer",             [8 10],  [0.5 1.0], [10 14], [0.4 0.6])
                row("fighter",                      [4 7],   [0.6 1.4], [6 9],   [0.6 0.8])
                row("mil_patrol_bomb_transport",    [13 15], [0.5 0.9], [14 18], [0.4 0.6])
                row("flying_boat_amphibious_float", [10 12], [0.5 0.9], [13 15], [0.4 0.6])
                row("supersonic_cruise",            [4 6],   [0.7 1.5], [7 9],   [0.6 0.8])
                ];
        end

    end

end
