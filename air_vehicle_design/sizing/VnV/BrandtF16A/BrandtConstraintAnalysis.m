classdef BrandtConstraintAnalysis < handle
% BrandtConstraintAnalysis  Replicates Brandt-F16-A.xls Consts tab.
%
% Implements Mattingly's Master Equation for performance constraint analysis.
% Each constraint method takes wing loading W/S [psf] (scalar or vector)
% and returns required thrust loading T/W [-].  Takeoff and landing use
% specialised formulas.
%
% Three-tier interface:
%   constructor(aero, eng) — store BrandtAerodynamics and BrandtEngine
%                            handles; load JSON; init all properties to NaN.
%   analyze()              — extract CLmax, S_ref, beta, mu from aero/JSON;
%                            no W/S dependence.
%   run(WS_psf)            — evaluate all constraints; dual-return contract.
%
% MASTER EQUATION (Mattingly, no K2 term):
%   T/W = (β/α) × [q·CD0/(β·WS) + K1·n²·β·WS/q + Ps/V]
%
%   CD0 = BrandtAerodynamics.run(mach).CD0 (Aero-tab CDmin_sub basis,
%         ≈0.017 subsonic) + CDx               [Consts!AM column]
%   K1  = BrandtAerodynamics.run(mach).K1     [Consts!AN column]
%   α   = BrandtEngine.run(alt, mach, AB_p).alpha_AB_ref  [Consts!AU]
%   q   = 0.5·ρ·V²   using atmosisa           [Consts!AR]
%   β   = weight fraction W/W_TO at constraint condition
%
% TAKEOFF FORMULA (Brandt/Raymer, Consts!K32):
%   T/W = k_TO²·β²·WS / (α_AB·ρ_SL·CLmax_TO·g·S_TO)
%       + 0.7·CD0_TO / (β·CLmax_TO) + μ_rolling
%   where CD0_TO = CDmin(M_liftoff) + CDx_TO
%
% LANDING FORMULA (Consts!K33) — returns max W/S, not T/W:
%   (W/S)_max = S_land·ρ_SL·g·(μ_brake·CLmax_land + 0.83·CD0_land) / k_app²
%   where CD0_land = CDmin(M≈0) + CDx_land
%
% CD0 BASIS NOTE:
%   The Consts tab sources CD0 from Aero!C6:C10 (CDmin_sub, Cfe_tab basis,
%   ≈0.017 subsonic), NOT from Miss!CD0_cruise (Cfe_eff basis, 0.027).
%   BrandtAerodynamics.run(mach) returns CDmin_sub-based values via
%   aero_at_mach(), so run().CD0 is the correct source for constraints.
%
% CROSS-DISCIPLINE DEPENDENCIES:
%   - BrandtAerodynamics.run(mach)  →  CD0, K1, CLmax_TO, CLmax_land
%   - BrandtEngine.run(alt, mach, pct_AB/100)  →  alpha_AB_ref
%   - atmosisa(alt_m)               →  ρ, a  (atmosphere at constraint alt)
%
% F-16A GROUND-TRUTH VALUES (Consts tab, β=0.89966696):
%   At W/S = 48 psf:
%     max_mach T/W        = 1.2228   (Consts!K23 at K22=48 column)
%     cruise T/W          = 0.6247   (Consts!K24)
%     max_alt T/W         = 0.4732   (Consts!K25)
%     combat_turn_sub T/W = 0.5274   (Consts!K26)
%     ps_500 T/W          = 0.8888   (Consts!K28)
%     takeoff T/W         = 0.2438   (Consts!K32)
%     landing W/S_max     = 138.48 psf  (Consts!K33)
%   Optimal design point (Size&Opt sheet):  W/S = 104.59 psf,  T/W = 0.7576
%
% DISCREPANCIES FROM GROUND-TRUTH:
%   - atmosphere: MATLAB atmosisa vs Brandt's polynomial → ≤2% on T/W
%   - CD0: analytical aero_at_mach vs tabulated Aero!C6:C10 → <1% subsonic
%   For acceptable deviation ranges, see readme_consts.md.
%
% Usage:
%   geom  = BrandtGeometry(); geom.analyze();
%   aero  = BrandtAerodynamics(geom); aero.analyze();
%   eng   = BrandtEngine(); eng.analyze();
%   constr = BrandtConstraintAnalysis(aero, eng);
%   constr.analyze();
%   r = constr.run(linspace(10, 160, 151));
%   constr.plot_constraint_diagram();
%   pt = constr.optimal_point();

    properties
        inp     (1,1) struct   % raw JSON inputs

        % Handles to discipline objects
        aero                   % BrandtAerodynamics handle
        eng                    % BrandtEngine handle

        % Extracted aircraft parameters (set by analyze())
        beta_perf   (1,1) double = NaN  % Consts!B23 = 0.89966696
        S_ref_ft2   (1,1) double = NaN  % wing reference area [ft²]
        CLmax_TO    (1,1) double = NaN  % Aero!H27 = 1.276
        CLmax_land  (1,1) double = NaN  % Aero!H29 = 1.426
        mu_rolling  (1,1) double = NaN  % Main!V12 = 0.03
        mu_braking  (1,1) double = NaN  % Main!V13 = 0.5
        liftoff_factor  (1,1) double = NaN  % Main!U12 = 1.2 (k_TO = V_TO/V_stall)
        approach_factor (1,1) double = NaN  % Main!U13 = 1.3 (k_app = V_app/V_stall)

        % run() outputs (set by run(WS_psf))
        run_WS_psf              (:,1) double = []   % W/S evaluation array [psf]
        run_TW_max_mach         (:,1) double = []   % T/W for max Mach constraint
        run_TW_cruise           (:,1) double = []   % T/W for cruise
        run_TW_max_alt          (:,1) double = []   % T/W for max altitude
        run_TW_combat_turn_sub  (:,1) double = []   % T/W for subsonic combat turn
        run_TW_combat_turn_sup  (:,1) double = []   % T/W for supersonic combat turn
        run_TW_ps500            (:,1) double = []   % T/W for Ps=500 ft/s
        run_TW_takeoff          (:,1) double = []   % T/W for takeoff
        run_WS_landing_max      (1,1) double = NaN  % max W/S from landing [psf]
        run_TW_envelope         (:,1) double = []   % max T/W over all constraints
        run_WS_opt              (1,1) double = NaN  % optimal design W/S [psf]
        run_TW_opt              (1,1) double = NaN  % optimal design T/W [-]

        analyzed_   (1,1) logical = false
    end

    methods

        % ================================================================ %
        %  TIER 1 — Constructor                                            %
        % ================================================================ %

        function obj = BrandtConstraintAnalysis(aeroObj, engObj)
        % Load JSON and store BrandtAerodynamics and BrandtEngine handles.
        %
        % aeroObj — BrandtAerodynamics that has had analyze() called.
        % engObj  — BrandtEngine that has had analyze() called.
        % If both are omitted, objects are created and analyzed automatically.
            json_path = fullfile(fileparts(mfilename('fullpath')), 'GroundTruth', 'f16a_geometry.json');
            obj.inp = jsondecode(fileread(json_path));

            if nargin < 1 || isempty(aeroObj)
                geom = BrandtGeometry();
                geom.analyze();
                aeroObj = BrandtAerodynamics(geom);
                aeroObj.analyze();
            end
            if nargin < 2 || isempty(engObj)
                engObj = BrandtEngine();
                engObj.analyze();
            end
            obj.aero = aeroObj;
            obj.eng  = engObj;
        end

        % ================================================================ %
        %  TIER 2 — analyze()                                              %
        % ================================================================ %

        function analyze(obj)
        % Extract fixed aircraft and constraint parameters.
        % Sources: BrandtAerodynamics properties and JSON.
        % Must be called before run() or any per-constraint method.
            c = obj.inp.constraints;
            m = obj.inp.mission;

            obj.beta_perf       = c.beta_perf;          % Consts!B23 = 0.89966696
            obj.S_ref_ft2       = obj.inp.wing.S_ref_ft2;  % Main!B5 = 300 ft²
            obj.CLmax_TO        = obj.aero.CLmax_takeoff;  % Aero!H27 = 1.276
            obj.CLmax_land      = obj.aero.CLmax_landing;  % Aero!H29 = 1.426
            obj.mu_rolling      = m.mu_rolling;         % Main!V12 = 0.03
            obj.mu_braking      = m.mu_braking;         % Main!V13 = 0.5
            obj.liftoff_factor  = m.liftoff_factor;     % Main!U12 = 1.2
            obj.approach_factor = m.approach_factor;    % Main!U13 = 1.3

            obj.analyzed_ = true;
        end

        % ================================================================ %
        %  TIER 3 — run()                                                  %
        % ================================================================ %

        function results = run(obj, WS_psf)
        % Evaluate all constraints at the given W/S vector.
        %
        % Dual-return contract:
        %   r = constr.run(WS_psf);   % returns struct AND stores in run_* properties
        %   constr.run(WS_psf);       % equivalent: access results via constr.run_TW_*
        %
        % WS_psf — wing loading vector [psf]  (e.g. linspace(10, 160, 151))
        %
        % Returns struct with fields matching all run_* properties.
        %
        % Note: internally calls aero.run() and eng.run() per constraint,
        % which overwrites those objects' run_* stored properties with the
        % last evaluated constraint condition.
            obj.requireAnalyzed_();

            TW_mm     = obj.max_mach(WS_psf);
            TW_cr     = obj.cruise(WS_psf);
            TW_ma     = obj.max_alt(WS_psf);
            TW_ct_sub = obj.combat_turn_sub(WS_psf);
            TW_ct_sup = obj.combat_turn_sup(WS_psf);
            TW_ps     = obj.ps_500(WS_psf);
            TW_to     = obj.takeoff(WS_psf);
            WS_land   = obj.landing();

            % Envelope: max required T/W at each W/S (feasibility boundary)
            TW_matrix = [TW_mm(:), TW_cr(:), TW_ma(:), ...
                         TW_ct_sub(:), TW_ct_sup(:), TW_ps(:), TW_to(:)];
            TW_env = max(TW_matrix, [], 2);

            % Optimal point: minimum of envelope subject to W/S <= WS_land_max
            WS_col = WS_psf(:);
            feasible = WS_col <= WS_land;
            TW_feas  = TW_env;
            TW_feas(~feasible) = Inf;
            [TW_opt_val, idx_opt] = min(TW_feas);
            WS_opt_val = WS_col(idx_opt);

            % Store to properties
            obj.run_WS_psf              = WS_col;
            obj.run_TW_max_mach         = TW_mm(:);
            obj.run_TW_cruise           = TW_cr(:);
            obj.run_TW_max_alt          = TW_ma(:);
            obj.run_TW_combat_turn_sub  = TW_ct_sub(:);
            obj.run_TW_combat_turn_sup  = TW_ct_sup(:);
            obj.run_TW_ps500            = TW_ps(:);
            obj.run_TW_takeoff          = TW_to(:);
            obj.run_WS_landing_max      = WS_land;
            obj.run_TW_envelope         = TW_env;
            obj.run_WS_opt              = WS_opt_val;
            obj.run_TW_opt              = TW_opt_val;

            % Return struct (dual-return contract)
            results.WS_psf              = WS_col;
            results.TW_max_mach         = TW_mm(:);
            results.TW_cruise           = TW_cr(:);
            results.TW_max_alt          = TW_ma(:);
            results.TW_combat_turn_sub  = TW_ct_sub(:);
            results.TW_combat_turn_sup  = TW_ct_sup(:);
            results.TW_ps500            = TW_ps(:);
            results.TW_takeoff          = TW_to(:);
            results.WS_landing_max      = WS_land;
            results.TW_envelope         = TW_env;
            results.WS_opt              = WS_opt_val;
            results.TW_opt              = TW_opt_val;

            obj.validate_run_();
        end

        % ================================================================ %
        %  PER-CONSTRAINT METHODS                                          %
        %  Input:  WS_psf — wing loading [psf], scalar or row/column vec  %
        %  Output: TW — required thrust loading T/W [-], same size as WS  %
        % ================================================================ %

        function TW = max_mach(obj, WS_psf)
        % Max Mach (supersonic sprint) constraint.  Consts!row 23.
        % h=36000 ft, M=1.6, n=1, 100%AB, Ps=0
            obj.requireAnalyzed_();
            TW = obj.masterConstraint_(WS_psf, obj.inp.constraints.conditions.max_mach);
        end

        function TW = cruise(obj, WS_psf)
        % Sustained cruise constraint.  Consts!row 24.
        % h=36000 ft, M=0.87, n=1, 0%AB, Ps=0
            obj.requireAnalyzed_();
            TW = obj.masterConstraint_(WS_psf, obj.inp.constraints.conditions.cruise);
        end

        function TW = max_alt(obj, WS_psf)
        % Maximum altitude (service ceiling, Ps=0) constraint.  Consts!row 25.
        % h=50000 ft, M=0.87, n=1, 100%AB, Ps=0
            obj.requireAnalyzed_();
            TW = obj.masterConstraint_(WS_psf, obj.inp.constraints.conditions.max_alt);
        end

        function TW = combat_turn_sub(obj, WS_psf)
        % Sustained subsonic combat turn constraint.  Consts!row 26.
        % h=20000 ft, M=0.87, n=4.5, 100%AB, Ps=0
            obj.requireAnalyzed_();
            TW = obj.masterConstraint_(WS_psf, obj.inp.constraints.conditions.combat_turn_sub);
        end

        function TW = combat_turn_sup(obj, WS_psf)
        % Supersonic combat turn constraint.  Consts!row 27.
        % h=36000 ft, M=1.4, n=1.4, 100%AB, Ps=0
            obj.requireAnalyzed_();
            TW = obj.masterConstraint_(WS_psf, obj.inp.constraints.conditions.combat_turn_sup);
        end

        function TW = ps_500(obj, WS_psf)
        % Specific excess power Ps=500 ft/s constraint.  Consts!rows 28-30.
        % h=10000 ft, M=0.87, n=1, 100%AB, Ps=500 ft/s
            obj.requireAnalyzed_();
            TW = obj.masterConstraint_(WS_psf, obj.inp.constraints.conditions.ps_500);
        end

        function TW = takeoff(obj, WS_psf)
        % Takeoff ground roll constraint.  Consts!row 32.
        %
        % Returns required T/W to meet the S_TO takeoff distance limit.
        % β = 1.0 (takeoff at full TOGW).
        %
        % Formula (Brandt/Raymer; decoded from Consts!K32):
        %   T/W = k_TO²·β²·WS / (α_AB·ρ_SL·CLmax_TO·g·S_TO)
        %       + 0.7·CD0_TO / (β·CLmax_TO) + μ_rolling
        %
        %   where CD0_TO = CDmin(M_liftoff) + CDx_TO  (Consts!AM32)
        %
        % Note (Consts!AT32 = Mach 0.2): Brandt uses M=0.2 as the approximate
        % liftoff Mach number when evaluating thrust lapse at takeoff.
            obj.requireAnalyzed_();
            tc = obj.inp.constraints.takeoff;
            beta   = 1.0;
            k_TO   = obj.liftoff_factor;    % 1.2  (Main!U12)
            S_TO   = tc.S_TO_ft;            % 4000 ft  (Consts!G32)
            CDx_TO = tc.CDx;                % 0.035  (Consts!H32)
            g_fps2 = 32.174;                % ft/s²

            % Sea-level atmosphere
            [~, ~, ~, rho_SL_SI] = atmosisa(0);
            rho_SL = rho_SL_SI / 515.379;   % slug/ft³ = 0.002377

            % Thrust lapse at liftoff (M=0.2, SL, full AB)  — Consts!AT32
            r_eng = obj.eng.run(tc.alt_ft, tc.mach_liftoff, tc.pct_AB / 100);
            alpha  = r_eng.alpha_AB_ref;

            % CD0 at liftoff Mach (Aero-tab CDmin basis) + CDx  — Consts!AM32
            r_aero = obj.aero.run(tc.mach_liftoff);
            CD0_TO = r_aero.CD0 + CDx_TO;

            % Takeoff ground-roll T/W (Consts!K32 formula, vectorised over WS)
            TW = (k_TO^2 .* beta^2 .* WS_psf) ...
                 ./ (alpha .* rho_SL .* obj.CLmax_TO .* g_fps2 .* S_TO) ...
                 + 0.7 .* CD0_TO ./ (beta .* obj.CLmax_TO) ...
                 + obj.mu_rolling;
        end

        function WS_max = landing(obj)
        % Landing ground roll constraint.  Consts!row 33.
        %
        % Returns maximum allowable W/S [psf] to meet the S_land distance
        % limit.  This is a W/S upper bound (vertical line on constraint
        % diagram), independent of T/W.  β = 1.0.
        %
        % Formula (Brandt; decoded from Consts!K33):
        %   WS_max = S_land·ρ_SL·g·(μ_brake·CLmax_land + 0.83·CD0_land) / k_app²
        %
        %   where CD0_land = CDmin(subsonic) + CDx_land  (Consts!AM33)
        %   and 0.83 is Brandt's mean-speed correction for drag during rollout.
        %
        % Note: E33 in the Excel is μ_brake (repurposed from the "n" column).
            obj.requireAnalyzed_();
            lc = obj.inp.constraints.landing;
            g_fps2   = 32.174;

            [~, ~, ~, rho_SL_SI] = atmosisa(0);
            rho_SL = rho_SL_SI / 515.379;   % slug/ft³

            % CD0 at approach (low Mach, subsonic) + CDx  — Consts!AM33
            r_aero  = obj.aero.run(0.1);
            CD0_land = r_aero.CD0 + lc.CDx;

            k_app  = obj.approach_factor;   % 1.3  (Main!U13)

            % Landing ground-roll W/S limit (Consts!K33 formula)
            WS_max = lc.S_land_ft .* rho_SL .* g_fps2 ...
                     .* (obj.mu_braking .* obj.CLmax_land + 0.83 .* CD0_land) ...
                     ./ k_app^2;
        end

        % ================================================================ %
        %  DIAGRAM AND DESIGN POINT                                        %
        % ================================================================ %

        function plot_constraint_diagram(obj)
        % Plot the constraint diagram (T/W vs W/S).
        % run() must be called first to populate run_* properties.
            if isempty(obj.run_WS_psf)
                error('LevelBrandt:notRun', ...
                    'Call run(WS_psf) before plot_constraint_diagram().');
            end

            WS = obj.run_WS_psf;

            figure('Name', 'Constraint Diagram — F-16A', 'Color', 'white');
            hold on; grid on;

            plot(WS, obj.run_TW_max_mach,        'b-',  'LineWidth',1.5, ...
                'DisplayName', 'Max Mach (M=1.6, h=36kft)');
            plot(WS, obj.run_TW_cruise,           'g-',  'LineWidth',1.5, ...
                'DisplayName', 'Cruise (M=0.87, h=36kft)');
            plot(WS, obj.run_TW_max_alt,          'r-',  'LineWidth',1.5, ...
                'DisplayName', 'Max Alt/Ceiling (h=50kft)');
            plot(WS, obj.run_TW_combat_turn_sub,  'm-',  'LineWidth',1.5, ...
                'DisplayName', 'Combat Turn Sub (n=4.5, h=20kft)');
            plot(WS, obj.run_TW_combat_turn_sup,  'c-',  'LineWidth',1.5, ...
                'DisplayName', 'Combat Turn Sup (n=1.4, h=36kft)');
            plot(WS, obj.run_TW_ps500,            'k-',  'LineWidth',1.5, ...
                'DisplayName', 'P_s=500 ft/s (M=0.87, h=10kft)');
            plot(WS, obj.run_TW_takeoff,          'b--', 'LineWidth',1.5, ...
                'DisplayName', sprintf('Takeoff (S_{TO}=%d ft)', ...
                    obj.inp.constraints.takeoff.S_TO_ft));

            % Landing: vertical line (max W/S upper bound)
            xline(obj.run_WS_landing_max, 'r--', 'LineWidth',1.5, ...
                'Label', sprintf('Land W/S_{max}=%.0f psf', obj.run_WS_landing_max), ...
                'LabelVerticalAlignment','bottom');

            % Envelope
            plot(WS, obj.run_TW_envelope, 'k-', 'LineWidth', 2.5, ...
                'DisplayName', 'Constraint Envelope');

            % Optimal design point
            plot(obj.run_WS_opt, obj.run_TW_opt, 'kp', ...
                'MarkerSize', 14, 'MarkerFaceColor', [1 0.8 0], ...
                'DisplayName', sprintf('Design Pt: W/S=%.1f, T/W=%.3f', ...
                    obj.run_WS_opt, obj.run_TW_opt));

            xlabel('Wing Loading  W/S  [psf]');
            ylabel('Thrust Loading  T_{SL}/W_{TO}  [-]');
            title('Constraint Diagram — F-16A Block 10/15');
            legend('Location', 'northeast');
            xlim([max(0, min(WS)*0.9), min(max(WS)*1.05, obj.run_WS_landing_max*1.15)]);
            ylim([0, min(3.5, max(obj.run_TW_max_mach) * 1.05)]);
        end

        function pt = optimal_point(obj)
        % Return the optimal design point as a struct with WS and TW fields.
        % Optimal = minimum of the constraint envelope subject to W/S <= landing max.
        % run() must be called first.
            obj.requireAnalyzed_();
            if isnan(obj.run_WS_opt)
                error('LevelBrandt:notRun', ...
                    'Call run(WS_psf) before optimal_point().');
            end
            pt.WS = obj.run_WS_opt;
            pt.TW = obj.run_TW_opt;
        end

    end % public methods

    % ===================================================================== %
    %  PRIVATE HELPERS                                                      %
    % ===================================================================== %

    methods (Access = private)

        function TW = masterConstraint_(obj, WS_psf, cond)
        % Apply Mattingly's Master Equation (no K2 term) for one constraint.
        %
        % Master Equation (Brandt Consts!K23:K30 family):
        %   T/W = (β/α) × [q·CD0/(β·WS) + K1·n²·β·WS/q + Ps/V]
        %
        % Arguments:
        %   WS_psf — wing loading array [psf]
        %   cond   — struct from JSON constraints.conditions with fields:
        %              alt_ft, mach, n, pct_AB (0-100), Ps_fps, CDx
        %
        % Why no K2?  The Consts tab uses the symmetric parabolic polar
        % (CD0 + K1·CL²) for constraint analysis.  K2 is non-zero for the
        % F-16A but negligibly small and omitted by Brandt in constraint sizing.
        %
        % Note on CD0 basis:
        %   aero.run(mach) returns CDmin_sub-based CD0 (≈0.017 subsonic), NOT
        %   the Miss-tab Cfe_eff-based CD0 (0.027).  This matches the Excel.

            beta = obj.beta_perf;   % Consts!B column (0.89966696)

            % Atmosphere at constraint altitude
            [~, a_SI, ~, rho_SI] = atmosisa(cond.alt_ft * 0.3048);
            a_fps   = a_SI   / 0.3048;       % speed of sound [ft/s]
            rho_fps = rho_SI / 515.379;       % density [slug/ft³]
            V_fps   = cond.mach * a_fps;      % true airspeed [ft/s]  (Consts!AQ)
            q_psf   = 0.5 * rho_fps * V_fps^2; % dynamic pressure [psf]  (Consts!AR)

            % Thrust lapse α normalised to T_sl_AB  (Consts!AU)
            r_eng = obj.eng.run(cond.alt_ft, cond.mach, cond.pct_AB / 100);
            alpha = r_eng.alpha_AB_ref;

            % Mach-dependent aerodynamics  (Consts!AM = CDmin + CDx, Consts!AN = K1)
            r_aero = obj.aero.run(cond.mach);
            CD0  = r_aero.CD0 + cond.CDx;
            K1   = r_aero.K1;

            % Mattingly Master Equation (vectorised over WS_psf)
            % T/W = (β/α) × [q·CD0/(β·WS) + K1·n²·β·WS/q + Ps/V]
            TW = (beta / alpha) .* ( ...
                     q_psf .* CD0 ./ (beta .* WS_psf(:)') ...
                     + K1 .* cond.n^2 .* beta .* WS_psf(:)' ./ q_psf ...
                     + cond.Ps_fps / V_fps );

            TW = TW(:);   % ensure column vector
        end

        function validate_run_(obj)
        % Lightweight NaN guard on key run() outputs.
            assert(~any(isnan(obj.run_TW_max_mach)), 'LevelBrandt:nanOutput', ...
                'run_TW_max_mach contains NaN');
            assert(~any(isnan(obj.run_TW_cruise)), 'LevelBrandt:nanOutput', ...
                'run_TW_cruise contains NaN');
            assert(~any(isnan(obj.run_TW_ps500)), 'LevelBrandt:nanOutput', ...
                'run_TW_ps500 contains NaN');
            assert(~any(isnan(obj.run_TW_takeoff)), 'LevelBrandt:nanOutput', ...
                'run_TW_takeoff contains NaN');
            assert(~isnan(obj.run_WS_landing_max), 'LevelBrandt:nanOutput', ...
                'run_WS_landing_max is NaN');
            assert(~isnan(obj.run_WS_opt), 'LevelBrandt:nanOutput', ...
                'run_WS_opt is NaN');
            assert(~isnan(obj.run_TW_opt), 'LevelBrandt:nanOutput', ...
                'run_TW_opt is NaN');
            assert(obj.run_WS_landing_max > 0, 'LevelBrandt:invalidOutput', ...
                'run_WS_landing_max must be positive');
            assert(obj.run_TW_opt > 0, 'LevelBrandt:invalidOutput', ...
                'run_TW_opt must be positive');
        end

        function requireAnalyzed_(obj)
            if ~obj.analyzed_
                error('LevelBrandt:notAnalyzed', ...
                    'Call analyze() before accessing constraint analysis results.');
            end
        end

    end % private methods

end % classdef
