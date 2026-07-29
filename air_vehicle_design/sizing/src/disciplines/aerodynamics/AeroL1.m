classdef AeroL1
%AEROL1  Level-1 aerodynamics static toolbox: aircraft type only, no geometry.
%
%   Call as AeroL1.method(...); never instantiated, not in the inheritance
%   chain. F16AeroL1 inherits AeroModelL1 and delegates to these statics.
%
%   Two tiers: high-level statics take the concrete object; low-level statics
%   take only scalars and arrays.
%
%   Drag polar: [Mattingly 2nd ed. Eq. 2.9]. CD0(M) interpolated from the
%   fighter "Current" type-curve [Mattingly 2nd ed. Fig. 2.10]; K2 = 0 for an
%   uncambered fighter [Mattingly 2nd ed. Sec. 2.3.1]. CLmax and the high-lift
%   increments: [Roskam Vol. I Table 3.1, Table 3.6].
%
%   K1 -- EQUATION-BASED, NOT A CURVE (changed 2026-07-29, user direction):
%   K1 previously interpolated Mattingly's GENERIC Fig. 2.11 fighter type-curve
%   (flat 0.18 subsonic), which was ~55% higher than Brandt's own calibrated
%   F-16 K1=0.1160 and was found to pull design_study_01_L1's optimal_point()
%   down to W/S=76 instead of Brandt's 104.59 (see git history / F16AeroL1.m's
%   prior header for the full diagnostic). k1_from_geometry below instead
%   reuses AeroL2's own Raymer equations (Eq. 12.48-12.50 subsonic Oswald-e/K1,
%   Eq. 12.51 supersonic K1), fed the real F-16 wing AR/sweep (genuine spec
%   data, not derived geometry -- see F16AeroL1.m's AR/Lambda_LE_deg
%   properties), the same low-level cross-tier reuse pattern this repo already
%   uses for the skin-friction primitives (AeroL2.dyn_viscosity/compute_Re/
%   Cf_turbulent, shared with the L3 component buildup). This makes L1's K1 a
%   real, cited equation instead of an un-digitized placeholder table -- see
%   TestAeroL1.testTODO_MattinglyCurvesArePlaceholder, now CD0-only.
%
%   TRANSONIC GAP (NEW for L1, matches L2/L3): Raymer Eq. 12.51's pole near
%   M=1 (AeroL2.m class header) means k1_from_geometry returns NaN in
%   AeroL2's transonic band (0.95 <= M < 1.05) -- a real behavior change from
%   the old smooth Mattingly curve, and from L1's own CD0(M), which stays a
%   smooth curve interpolation with no gap. None of the F-16's actual
%   Constraints.xlsx conditions fall in that band (all are M<=0.87 or
%   M>=1.05), so this does not affect F16ConstraintSet.build("L1").
%
%   TODO: Mattingly Fig. 2.10 is not in this repo. The CD0 curve block in
%   f16a_L1.json is seeded from 5 AAF worked-example points and marked
%   _placeholder. Guarded by TestAeroL1.testTODO_MattinglyCurvesArePlaceholder.
%
%   Companion doc: src/disciplines/aerodynamics/AeroL1.md

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
        %DRAG_POLAR  Assemble the L1 drag polar.  Returns struct(CD0, K1, K2).
        %   CD0(M) interpolated from the student object's Mattingly Fig. 2.10
        %   "Current" curve table; K1 computed from the object's real wing
        %   AR/Lambda_LE_deg via k1_from_geometry (Raymer Eq. 12.48-12.50/
        %   12.51, see class header "K1 -- EQUATION-BASED"); K2 = 0 for the
        %   fighter/uncambered type.  Mattingly AED Eq. 2.9.
            cd0 = AeroL1.interp_curve(obj.cd0_curve_mach, obj.cd0_curve_value, state.mach);
            k1  = AeroL1.k1_from_geometry(obj.AR, obj.Lambda_LE_deg, state.mach);
            k2  = AeroL1.mattingly_K2(obj.design_type);
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function CLmax = get_CLmax(obj)
            CLmax = AeroL1.roskam_CLmax_value(obj.aircraft_category, "CL_max_clean");
        end

        % ================================================================== %
        % LOW-LEVEL: pure math -- scalars/arrays only, no object access.
        % ================================================================== %

        function K1 = k1_from_geometry(AR, Lambda_LE_deg, M)
        %K1_FROM_GEOMETRY  Induced-drag factor from real wing AR/sweep,
        %   reusing AeroL2's own low-level Raymer equations -- see class
        %   header "K1 -- EQUATION-BASED, NOT A CURVE" for the full rationale
        %   and why this cross-tier reuse of AeroL2's pure-math statics
        %   matches the codebase's existing precedent (skin-friction
        %   primitives shared with the L3 component buildup).
        %     Subsonic (M < AeroL2.MACH_SUBSONIC_MAX):
        %       e  = AeroL2.oswald_eff(AR, Lambda_LE_deg)   [Raymer Eq. 12.48/12.49]
        %       K1 = AeroL2.K1_subsonic(e, AR)              [Raymer Eq. 12.50]
        %     Supersonic (M >= AeroL2.MACH_SUPERSONIC_MIN):
        %       K1 = AeroL2.K1_supersonic(M, AR, Lambda_LE_deg)  [Raymer Eq. 12.51]
        %     Transonic band in between: NaN (Eq. 12.51 pole near M=1, same
        %     "not modeled" convention as AeroL2.drag_polar -- see that
        %     class's header). Unlike L1's CD0(M), which stays a smooth curve
        %     interpolation through this band with no gap.
            arguments
                AR            (1,1) double {mustBePositive}
                Lambda_LE_deg (1,1) double {mustBeReal}
                M             (1,1) double {mustBeReal, mustBeNonnegative}
            end
            regime = AeroL2.flight_regime(M);
            switch regime
                case "subsonic"
                    e_osw = AeroL2.oswald_eff(AR, Lambda_LE_deg);
                    K1    = AeroL2.K1_subsonic(e_osw, AR);
                case "supersonic"
                    K1 = AeroL2.K1_supersonic(M, AR, Lambda_LE_deg);
                otherwise   % "transonic"
                    K1 = NaN;
            end
        end

        function v = interp_curve(mach_pts, val_pts, M)
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
