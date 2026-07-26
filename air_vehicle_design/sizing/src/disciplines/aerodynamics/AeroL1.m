classdef AeroL1
%AEROL1  Level-1 aerodynamics static toolbox -- aircraft-type only, NO geometry.
%
%   Call as AeroL1.method_name(args) -- no instantiation required.
%   Not in the inheritance chain.  Student classes (F16AeroL1, etc.) inherit
%   from AeroModelL1 and call these statics to implement drag_polar/get_CLmax.
%
%   TWO TIERS of statics:
%     High-level  -- take the student object (obj) and return a computed result.
%     Low-level   -- pure math; take only scalars/arrays.
%
%   APPROVED TARGET (Aero deep-dive Phase C, 2026-07-23): L1 is a geometry-FREE
%   Mattingly type-curve drag polar. The geometry-dependent skin-friction /
%   Oswald-induced machinery that used to live here (oswald_eff, K1_subsonic,
%   K1_supersonic, K2_value, CD0_from_Cf, lookup_Cf, compute_AR_wet,
%   compute_LD_max) has MIGRATED to the AeroL2 toolbox (the geometry-dependent
%   tier). Only the aircraft-type-based content remains: the Mattingly curves
%   and the Roskam CLmax / high-lift-device Delta tables.
%
%   EQUATIONS:
%     CD = CD0(M) + K1(M)*CL^2 + K2*CL
%       Mattingly, "Aircraft Engine Design," 2nd ed., AIAA, 2002, Eq. 2.9.
%     CD0(M) : Mattingly Fig. 2.10 (fighter "Current" curve), interp. by Mach.
%     K1(M)  : Mattingly Fig. 2.11 (fighter "Current" curve), interp. by Mach.
%     K2     : 0 for a high-performance (uncambered) fighter  (Mattingly Sec. 2.3.1).
%     CLmax  : type-based lookup                              (Roskam Vol. I Table 3.1/3.3).
%
%   *** PLACEHOLDER curve data (TODO): Mattingly Fig. 2.10/2.11 are NOT in the
%   repo. The f16a_L1.json .aerodynamics cd0_curve/k1_curve blocks seed the
%   CD0(M)/K1(M) "Current" curves from the 5 AAF worked-example points in
%   reference_extracts/mattingly_data.md PART 9; they are marked _placeholder
%   until the real figures are transcribed. See VnV/BrandtF16A/todo.md. ***

% Type-based tables (no geometry): Roskam CLmax by category and the
% high-lift-device Delta_CD0 / e-osw table. Consumed by F16AeroL1's
% CLmax and HLD-delta methods.
     properties (Constant)
          CLmax_table = AeroL1.build_CLmax_table()    % Roskam Vol. I Table 3.1 (clean/TO/landing CLmax by type)
          Delta_CD0   = AeroL1.build_DeltaCD0_table() % Roskam Vol. I Table 3.6 (Delta_CD0/e by flap+gear config)
     end

    methods (Static)

        % ================================================================== %
        % HIGH-LEVEL: take the student object, return the result.
        % ================================================================== %

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Assemble the Mattingly type-curve drag polar.
        %   Returns struct(CD0, K1, K2). CD0(M)/K1(M) are interpolated from the
        %   student object's Mattingly Fig. 2.10/2.11 "Current" curve tables;
        %   K2 = 0 for the fighter/uncambered type.  Mattingly AED Eq. 2.9.
            polar = AeroL1.mattingly_polar(obj.cd0_curve_mach, obj.cd0_curve_value, ...
                                           obj.k1_curve_mach,  obj.k1_curve_value, ...
                                           state.mach, obj.design_type);
        end

        function CLmax = get_CLmax(obj)
        %GET_CLMAX  Type-based clean CLmax, Roskam Vol. I Table 3.1 (range mean
        %   of the aircraft type's clean column).
        %
        %   TABLE 3.1 THROUGHOUT (user decision 2026-07-25). L1's clean CLmax and
        %   its takeoff/landing increments must come from ONE table, because the
        %   increments are differences within it:
        %     get_Delta_CLmax_TO = mean(CL_max_TO) - mean(CL_max_clean)
        %     get_Delta_CLmax_L  = mean(CL_max_L)  - mean(CL_max_clean)
        %   Until 2026-07-25 this returned Table 3.3's 0.90 while the increments
        %   were Table 3.1 differences off a 1.50 clean base, so the fighter
        %   totals (0.90+0.20=1.10 TO, 0.90+0.60=1.50 landing) matched neither
        %   table -- Table 3.1's own fighter means are 1.70 and 2.10. Two unit
        %   tests locked each half independently, so nothing caught the sum.
        %
        %   Consequence, deliberate and documented: fighter clean CLmax is now
        %   1.50 against L2/L3's geometry-based 0.913 (Raymer Eq. 12.15), the
        %   largest step in the fidelity ladder. That is the honest size of a
        %   type-only statistical estimate for a thin 40-deg swept wing -- not a
        %   bug. See AeroL1.md and fidelity_comparison.m's notes.
        %
        %   AeroL1.lookup_CLmax (Table 3.3) is retained as a standalone utility
        %   but is deliberately NOT wired here -- see its header.
            CLmax = AeroL1.roskam_CLmax_value(obj.aircraft_category, "CL_max_clean");
        end

        % ================================================================== %
        % LOW-LEVEL: pure math -- scalars/arrays only, no object access.
        % ================================================================== %

        function polar = mattingly_polar(cd0_mach, cd0_value, k1_mach, k1_value, M, design_type)
        %MATTINGLY_POLAR  {CD0(M), K1(M), K2} from the Mattingly Fig. 2.10/2.11
        %   curves.  Mattingly AED 2nd ed. Eq. 2.9 (fighter K2=0, Sec. 2.3.1).
        %   cd0_mach/cd0_value, k1_mach/k1_value -- the "Current" curve (mach,
        %   value) breakpoint vectors. M -- flight Mach. design_type -- airfoil
        %   camber class ("uncambered" -> K2=0).
            cd0 = AeroL1.interp_curve(cd0_mach, cd0_value, M);
            k1  = AeroL1.interp_curve(k1_mach,  k1_value,  M);
            k2  = AeroL1.mattingly_K2(design_type);
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function v = interp_curve(mach_pts, val_pts, M)
        %INTERP_CURVE  Linear interpolation of a value-vs-Mach curve, clamped at
        %   the curve endpoints for Mach outside the tabulated range. Unlike the
        %   Raymer Eq. 12.51 supersonic K1 path (AeroL2), a tabulated figure has
        %   NO transonic singularity, so the Mattingly curve is evaluated across
        %   the whole Mach range (including the transonic band) directly.
        %   The endpoint clamp assumes mach_pts is STRICTLY ASCENDING -- it
        %   clamps to mach_pts(1)/mach_pts(end) as the min/max of the range. An
        %   unsorted or duplicated breakpoint vector would clamp to the wrong
        %   bounds and/or make interp1 return NaN, silently, so both are checked
        %   here rather than trusted (added 2026-07-25).
            arguments
                mach_pts (1,:) double {mustBeReal}
                val_pts  (1,:) double {mustBeReal}
                M        (1,1) double {mustBeReal}
            end
            if numel(mach_pts) ~= numel(val_pts)
                error('AeroL1:curveLengthMismatch', ...
                    'mach_pts has %d elements but val_pts has %d.', ...
                    numel(mach_pts), numel(val_pts));
            end
            if numel(mach_pts) < 2
                error('AeroL1:curveTooShort', ...
                    'A value-vs-Mach curve needs at least 2 breakpoints (got %d).', ...
                    numel(mach_pts));
            end
            if any(diff(mach_pts) <= 0)
                error('AeroL1:curveNotAscending', ...
                    ['Curve Mach breakpoints must be strictly ascending (got %s). ', ...
                     'interp_curve clamps to the first/last element as the range ', ...
                     'bounds, so an unsorted or duplicated vector clamps wrongly ', ...
                     'or returns NaN.'], mat2str(mach_pts));
            end
            Mc = min(max(M, mach_pts(1)), mach_pts(end));
            v  = interp1(mach_pts, val_pts, Mc, 'linear');
        end

        function K2 = mattingly_K2(design_type)
        %MATTINGLY_K2  Linear polar-offset term for the Mattingly type-curve.
        %   A high-performance (uncambered) fighter sets K2 = 0 -- the polar is
        %   symmetric, CD = K1*CL^2 + CD0 (Mattingly AED 2nd ed. Sec. 2.3.1).
        %   TODO: cargo/passenger (cambered) types keep K2 != 0
        %   (K2 = -2*K''*CL_min); those curves are not yet fitted at L1 -- error
        %   loudly rather than silently returning 0. See VnV/BrandtF16A/todo.md.
            switch string(design_type)
                case "uncambered"
                    K2 = 0;
                otherwise
                    error('AeroL1:unsupportedDesignType', ...
                        ['L1 Mattingly type-curve K2 is only defined for the ' ...
                         'uncambered (fighter) type (K2=0, Mattingly Sec. 2.3.1). ' ...
                         'design_type="%s" needs a cambered-type K2=-2*K''''*CL_min ' ...
                         'curve fit that is not yet in the repo (TODO).'], design_type);
            end
        end

        function rowName = to_CLmax_table_row(aircraft_category)
        %TO_CLMAX_TABLE_ROW  Canonical aircraft_category -> AeroL1.CLmax_table row name.
        %
        %   WHY A TRANSLATION LAYER RATHER THAN ONE GLOBAL SPELLING (Phase 3,
        %   2026-07-25). The framework's regression/lookup tables are transcribed
        %   from FOUR different textbook tables, and those tables name their
        %   categories differently:
        %     Roskam Vol. I Table 3.5 (S_wet)        -> "jet_fighter"
        %     Raymer 6th Table 6.3    (L_fus)        -> "jet_fighter"
        %     Raymer 7th Table 4.1    (AR_eq)        -> "jet_fighter"
        %     Raymer 6th Table 3.1    (empty weight) -> "jet_fighter"
        %     Roskam Vol. I Table 3.1 (CLmax, HERE)  -> "fighter"
        %   (they also disagree elsewhere: transport_jet vs jet_transport,
        %   military_cargo vs military_cargo_bomber).
        %
        %   The input JSON carries ONE canonical aircraft_category. Renaming this
        %   table's row to match it was considered and rejected: the row name is
        %   the category name Roskam actually prints, and renaming it would break
        %   the source traceability this project treats as non-negotiable. So the
        %   canonical value is translated at the table boundary instead -- one
        %   input key, every table still faithful to its own source.
            arguments
                aircraft_category (1,1) string
            end
            switch aircraft_category
                case {"jet_fighter", "fighter"}
                    rowName = "fighter";          % Roskam Vol. I Table 3.1's own name
                otherwise
                    rowName = aircraft_category;  % pass through; the caller validates
            end
        end

        function CLmax = roskam_CLmax_value(aircraft_category, column)
        %ROSKAM_CLMAX_VALUE  Range mean of one AeroL1.CLmax_table column for an
        %   aircraft category.  Source: Roskam, "Airplane Design Vol. I," Table 3.1.
        %   column -- "CL_max_clean" | "CL_max_TO" | "CL_max_L".
        %
        %   Takes the CANONICAL category (e.g. "jet_fighter") and translates it to
        %   this table's own row name via to_CLmax_table_row -- see that method for
        %   why the two differ.
        %
        %   Low-level static (scalars/strings only): the single place the Table
        %   3.1 range means are computed, shared by AeroL1.get_CLmax and the
        %   concrete classes' HLD-increment methods so the clean base and the
        %   increments can never again come from different tables.
            arguments
                aircraft_category (1,1) string
                column            (1,1) string {mustBeMember(column, ["CL_max_clean","CL_max_TO","CL_max_L"])}
            end
            T   = AeroL1.CLmax_table;
            row = T(T.AircraftType == AeroL1.to_CLmax_table_row(aircraft_category), :);
            if isempty(row)
                error('AeroL1:unknownAircraftType', ...
                    ['Unknown aircraft_category "%s" for Roskam Table 3.1 (no row "%s"). ', ...
                     'Known rows: %s.'], aircraft_category, ...
                     AeroL1.to_CLmax_table_row(aircraft_category), ...
                     strjoin(cellstr(T.AircraftType), ', '));
            end
            CLmax = mean(row.(column){1});
        end

        function CLmax = lookup_CLmax(aircraft_type)
        %LOOKUP_CLMAX  Clean CLmax by aircraft type (historical, no HLD).
        %   Source: Roskam, "Airplane Design Vol. I," Table 3.3.
        %
        %   NOT the L1 CLmax path. Deliberately unwired from AeroL1.get_CLmax on
        %   2026-07-25: Table 3.3's clean values (0.90 for a fighter) cannot be
        %   combined with the Table 3.1 takeoff/landing increments, whose own
        %   clean base is 1.50. Retained as a standalone reference lookup and for
        %   comparison reporting -- see get_CLmax's header for the full rationale.
            switch string(aircraft_type)
                case {"fighter", "jet_fighter"}, CLmax = 0.90;
                case "military_cargo",           CLmax = 1.20;
                case "transport_jet",            CLmax = 1.30;
                case "business_jet",             CLmax = 1.10;
                case "general_aviation_single",  CLmax = 1.30;
                case "general_aviation_twin",    CLmax = 1.20;
                case "sailplane",                CLmax = 1.40;
                otherwise
                    error('AeroL1:unknownCategory', ...
                        'Unknown aircraft_type "%s". Add it to AeroL1.lookup_CLmax.', ...
                        aircraft_type);
            end
        end

    end

methods (Static, Access = private)

          function quantity = normalize_DeltaCD0_quantity(quantity)

               quantity = lower(strtrim(string(quantity)));
               quantity = replace(quantity, "-", "_");
               quantity = replace(quantity, " ", "_");

               if any(quantity == ["all", "data", "table"])
                    quantity = "all";

               elseif any(quantity == ["dcd0", ...
                         "delta_cd0", ...
                         "delta_c_d0", ...
                         "cd0_increment"])
                    quantity = "Delta_CD0";

               elseif any(quantity == ["e", ...
                         "e_osw", ...
                         "eosw", ...
                         "oswald", ...
                         "oswald_efficiency"])
                    quantity = "e_osw";
               end
          end


          function flapconfig = normalize_flapconfig(flapconfig)

               flapconfig = lower(strtrim(string(flapconfig)));
               flapconfig = replace(flapconfig, "-", "_");
               flapconfig = replace(flapconfig, " ", "_");
               flapconfig = replace(flapconfig, "/", "_");

               if any(flapconfig == ["clean", "none", "no_flaps"])
                    flapconfig = "clean";

               elseif any(flapconfig == ["takeoff", ...
                         "takeoff_flaps", ...
                         "take_off", ...
                         "take_off_flaps", ...
                         "to_flaps"])
                    flapconfig = "takeoff_flaps";

               elseif any(flapconfig == ["landing", ...
                         "landing_flaps", ...
                         "land_flaps"])
                    flapconfig = "landing_flaps";

               elseif any(flapconfig == ["landing_gear", ...
                         "gear", ...
                         "lg",...
                         "geardown"])
                    flapconfig = "landing_gear";
               end
          end

          function T = build_CLmax_table()

               row = @(aircraftType, CL_clean, CL_TO, CL_L) table( ...
                    string(aircraftType), ...
                    {CL_clean}, ...
                    {CL_TO}, ...
                    {CL_L}, ...
                    'VariableNames', {'AircraftType', 'CL_max_clean', 'CL_max_TO', 'CL_max_L'});

               T = [
                    row("homebuilt",                    [1.2 1.8], [1.2 1.8], [1.2 2.0])
                    row("single_engine_propeller",      [1.3 1.9], [1.3 1.9], [1.6 2.3])
                    row("twin_engine_propeller",        [1.2 1.8], [1.4 2.0], [1.6 2.5])
                    row("agricultural",                 [1.3 1.9], [1.3 1.9], [1.3 1.9])
                    row("business_jet",                 [1.4 1.8], [1.6 2.2], [1.6 2.6])
                    row("regional_tbp",                 [1.5 1.9], [1.7 2.1], [1.9 3.3])
                    row("transport_jet",                [1.2 1.8], [1.6 2.2], [1.8 2.8])
                    row("military_trainer",             [1.2 1.8], [1.4 2.0], [1.6 2.2])
                    row("fighter",                      [1.2 1.8], [1.4 2.0], [1.6 2.6])
                    row("mil_patrol_bomb_transport",    [1.2 1.8], [1.6 2.2], [1.8 3.0])
                    row("flying_boat_amphibious_float", [1.2 1.8], [1.6 2.2], [1.8 3.4])
                    row("supersonic_cruise",            [1.2 1.8], [1.6 2.0], [1.8 2.2])
                    ];
          end

          function condition = normalize_CL_condition(condition)

               condition = lower(strtrim(string(condition)));
               condition = replace(condition, "-", "_");
               condition = replace(condition, " ", "_");

               if any(condition == ["", "all"])
                    condition = "";

               elseif any(condition == ["clean", ...
                         "clmax", ...
                         "cl_max", ...
                         "cl_max_clean"])
                    condition = "clean";

               elseif any(condition == ["to", ...
                         "takeoff", ...
                         "take_off", ...
                         "clmax_to", ...
                         "cl_max_to", ...
                         "cl_max_takeoff"])
                    condition = "takeoff";

               elseif any(condition == ["l", ...
                         "land", ...
                         "landing", ...
                         "clmax_l", ...
                         "cl_max_l", ...
                         "cl_max_landing"])
                    condition = "landing";
               end
          end

          function output = build_DeltaCD0_table()

               row = @(flapconfig, DeltaCD0, e_osw) table( ...
                    string(flapconfig), ...
                    {DeltaCD0}, ...
                    {e_osw}, ...
                    'VariableNames', {'FlapConfig', 'Delta_CD0', 'e_osw'});

               output = [
                    row("clean",          [0.000 0.000], [0.80 0.85])
                    row("takeoff_flaps",  [0.010 0.020], [0.75 0.80])
                    row("landing_flaps",  [0.055 0.075], [0.70 0.75])
                    row("landing_gear",   [0.015 0.025], NaN)
                    ];
          end


     end

end
