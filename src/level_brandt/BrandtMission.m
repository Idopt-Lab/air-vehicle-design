classdef BrandtMission < handle
% BrandtMission  Mission analysis replicating Brandt-F16-A.xls Miss tab.
%
% Computes fuel burn, time, and distance for each of the 14 mission
% segments defined in f16a_geometry.json ("mission" section).  Results
% match the Miss tab outputs; validation targets from the Miss tab:
%   Miss!O9 = 6000.43 lb  (total fuel)
%   Miss!O8 = 94.06 min   (total time)
%   Miss!O6 = 2884.95 ft  (landing roll distance)
%
% SEGMENT SEQUENCE (Miss tab columns B–O)
%   1  Takeoff   h=0,      M=0.282, 100% AB
%   2  Accel     h=10000,  M=0.87,    0% AB
%   3  Climb     h=40000,  M=0.87,    0% AB
%   4  Cruise    h=40000,  M=0.87,    0% AB,  190.8 nm
%   5  Patrol    h=40000,  M=0.87,    0% AB,  0 min
%   6  Dash      h=40000,  M=0.87,   50% AB,  50 nm
%   7  Patrol2   h=40000,  M=0.87,    0% AB,  0 min
%   8  Combat    h=25000,  M=0.87,   50% AB,  2 min
%   9  Egress    h=40000,  M=0.87,    0% AB,  50 nm
%  10  Patrol3   h=40000,  M=0.87,    0% AB,  0 min
%  11  Climb2    h=40000,  M=0.87,    0% AB  (zero fuel — same conditions)
%  12  Cruise2   h=40000,  M=0.87,    0% AB,  250 nm
%  13  Loiter    h=10000,  M=0.30,    0% AB,  20 min
%  14  Landing   h=0,      M=0,       0% AB  (ground roll distance only)
%
% ENGINE MODEL  (Miss tab uses "Engn(s) Old" TSFC formula — different from
%               BrandtEngine.m which uses "Engn(s) New")
%   cT_dry = install × TSFC_sl_dry × (1 + 0.35×|M|)    × sqrt(θ)
%   cT_AB  = install × TSFC_sl_AB  × (1 + 0.35×|M-0.4|)× sqrt(θ)
%   cT     = cT_dry + (%AB/100) × (cT_AB - cT_dry)
%   where θ = T_ISA(h) / 288.15 (static temperature ratio, K from atmosisa)
%   install = 1.08 (from Miss!C25 = Main!C25)
%
%   For CLIMB segments (altitude changes), cT is AVERAGED between start
%   and end conditions (Miss!D33 formula = (D34+C34)/2 pattern).
%
% THRUST LAPSE  (Miss tab uses "Engn(s) New" tab — same as BrandtEngine)
%   α_dry_norm = (T_sl_dry/T_sl_AB) × δ₀ × (1 − 0.3 M − max(0, 1.7(θ₀−TR)/θ₀))
%   α_AB_norm  =                           δ₀ × (1 − 0.1√M − max(0, 2.2(θ₀−TR)/θ₀))
%   α_norm     = α_dry_norm + (%AB/100) × (α_AB_norm − α_dry_norm)
%
% FUEL FORMULAS
%   Takeoff:
%     dW/W_TO = 1.2 × cT_AB / (g×3600) × V_stall_TO
%             + (T_sl_AB/W_TO) × cT_dry_SLS / 60
%             + warmup_fuel_per_engine × n_eng / W_TO
%     V_stall_TO = sqrt(2 × W/S / ρ_SL / CLmax_TO)
%     Sources: Miss!B13 formula; "1 min warmup at dry" + "1000 lb/eng fixed fuel"
%
%   Accel:
%     dW/W_TO = α × (T_sl_AB/W_TO) × cT × t_min/60
%     time from Ps (same as Climb); Miss!C13 uses C40×M30×C33×C8/60
%
%   Generic (Climb, Cruise, Dash, Egress, Loiter, Cruise2, Patrol, Climb2):
%     dW/W_TO = cT/60 × q_avg × (CDo_avg/WS + k1_avg×(Wf/q_avg)²×WS
%                                             + k2_avg×Wf/q_avg) × t_min
%             + cT/3600 × Wf × (Δh×2/(V_prev+V_end) + ΔV/g)
%             + drop_lb / W_TO
%     where Wf = W_frac at START of segment, WS = W_TO/S_ref
%     CDo_avg = average of CDo at start and end conditions
%     For Patrol / zero-time segments: dW/W_TO = 0
%
%   Combat:
%     fuel_burn_lb = t_min/60 × cT_I × T_avail_I
%     T_avail_I    = T_sl_AB × n_eng × α_AB_norm_I
%     dW/W_TO      = (fuel_burn_lb + drop_lb) / W_TO
%
%   Landing: dW/W_TO = 0 (fuel accounted in previous segments)
%     d_land = (approach_factor)² × (approach_factor×V_stall_land)² / (2g)
%            / (CDo_land×0.83/CLmax_TO + mu_braking)
%           = U13² × W_ref² / (ρ_SL×S×CLmax_land×g × (O26×Wf_TO×W_TO×0.83/CLmax_TO
%                                                       + V13×W_TO×Wf_TO))
%     (uses Wf after Takeoff = B12; CDo_land = CDo at takeoff = CDmin+CDx_TO)
%
% SPECIFIC EXCESS POWER (Ps)
%   Ps_end   = V_end   × (α_end/Wf_prev   × TW − q_end   × drag_coeff(..., Wf_prev/q_end))
%   Ps_start = V_start × (α_start_at_pctAB_end / Wf_prev × TW
%                        − q_start × drag_coeff(..., Wf_prev/q_start))
%   Ps = (Ps_end + Ps_start) / 2
%   dV/dt    = 32.2 × Ps / V_avg × 2   (approximate linear ramp)
%   t_Ps     = |Δh/Ps/60| + |ΔV/(dV/dt)/60|
%
% AERODYNAMICS (per segment)
%   [CDo_base, k1, k2] from BrandtAerodynamics.aero_at_mach(M)
%   CDo = CDo_base + CDx  (CDx from JSON per segment)
%
% Usage:
%   geom = BrandtGeometry();  geom.analyze();
%   aero = BrandtAerodynamics(geom);  aero.analyze();
%   eng  = BrandtEngine();            eng.analyze();
%   miss = BrandtMission(aero, eng, geom);
%   miss.run(31377.0);   % W_TO_lb required — from sizing loop or JSON
%   miss.displayMissionTable();

    properties
        inp         (1,1) struct    % parsed JSON "mission" section

        % Dependency handles
        aero_       BrandtAerodynamics
        eng_        BrandtEngine
        geom_       BrandtGeometry

        % ── Per-segment computed results (1×14 row vectors) ──────────────
        %   Index 1=Takeoff … 14=Landing

        % Inputs (populated from JSON in constructor)
        alt_ft      (1,:) double    % altitude at END of segment [ft]
        mach_end    (1,:) double    % Mach number at end of segment [-]
        pct_AB      (1,:) double    % afterburner percentage [%]
        CDx         (1,:) double    % extra drag coefficient [-]
        drop_lb     (1,:) double    % payload dropped during segment [lb]

        % Computed
        time_min    (1,:) double    % segment duration [min]; NaN until computed
        dist_nm     (1,:) double    % segment range [nmi]; NaN until computed
        fuel_lb     (1,:) double    % fuel burned [lb]; NaN until computed
        W_Wto       (1,:) double    % weight fraction at END of segment [-]
        dW_Wto      (1,:) double    % weight fraction consumed [-]

        % ── Summary totals ───────────────────────────────────────────────
        total_fuel_lb   (1,1) double = NaN  % sum of segments 1–13 [lb]
        total_time_min  (1,1) double = NaN  % sum of segments 1–13 [min]
        landing_dist_ft (1,1) double = NaN  % landing ground roll [ft]
        takeoff_dist_ft (1,1) double = NaN  % takeoff ground roll [ft]

        computed_   (1,1) logical = false
    end

    % ═════════════════════════════════════════════════════════════════════
    methods
        function obj = BrandtMission(aeroObj, engObj, geomObj)
        % BrandtMission  Constructor — loads JSON inputs, stores handles.
        %
        % Args:
        %   aeroObj  BrandtAerodynamics (must have analyze() called)
        %   engObj   BrandtEngine       (must have analyze() called)
        %   geomObj  BrandtGeometry     (must have analyze() called)
            obj.aero_ = aeroObj;
            obj.eng_  = engObj;
            obj.geom_ = geomObj;

            % Load mission section from JSON
            json_path = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                'examples', 'F-16A B Block 10 and 15', 'Ground-Truth', 'f16a_geometry.json');
            data = jsondecode(fileread(json_path));
            obj.inp = data.mission;
            % Stash install factor from engine section (Miss!C25 = 1.08)
            obj.inp.install_factor = data.engine.TSFC_install_factor;

            n = numel(obj.inp.segment_names);

            % Populate per-segment inputs from JSON arrays
            obj.alt_ft   = obj.inp.altitude_ft(:)';
            obj.mach_end = obj.inp.mach_end(:)';
            obj.pct_AB   = obj.inp.pct_AB(:)';
            obj.CDx      = obj.inp.CDx(:)';
            obj.drop_lb  = obj.inp.drop_payload_lb(:)';

            % Pre-fill computed outputs with NaN
            obj.time_min = nan(1, n);
            obj.dist_nm  = nan(1, n);
            obj.fuel_lb  = nan(1, n);
            obj.W_Wto    = nan(1, n);
            obj.dW_Wto   = nan(1, n);
        end

        function analyze(obj)
        % Validate that all dependency objects are properly analyzed before running.
        % analyze() is a design-variable pass — at Brandt level, the mission profile
        % (altitudes, Mach numbers, etc.) is fixed by the JSON inputs loaded at construction.
            if ~obj.aero_.analyzed_ || ~obj.eng_.analyzed_ || ~obj.geom_.analyzed_
                error('LevelBrandt:notAnalyzed', ...
                    'All dependency objects (aero, eng, geom) must have analyze() called first.');
            end
        end

        % ─────────────────────────────────────────────────────────────────
        function results = run(obj, W_TO_lb)
        % run  Run the full mission analysis, populating all outputs.
        %
        % W_TO_lb : takeoff gross weight [lb] — required parameter.
        %           Pass from sizing loop; JSON value (31377.0 lb) used for
        %           standalone validation.
        %
        % Iterates over all 14 segments in sequence.  Each segment
        % consumes the weight fraction output from the previous one.
            obj.analyze();

            n     = numel(obj.inp.segment_names);
            W_TO  = W_TO_lb;
            % W/S and T_sl_AB/W_TO used in Ps formula and fuel formulas
            WS    = W_TO / obj.geom_.inp.wing.S_ref_ft2;  % W/S = 104.59 psf (Main!K30 = P13)
            TW    = obj.eng_.T_sl_AB / W_TO;       % T_sl_AB/W_TO = 0.7576 (Main!M30)

            W_frac = 1.0;           % weight fraction accumulator (starts at 1)
            W_frac_after_TO = NaN;  % stored after takeoff for landing formula

            % Pre-compute Accel Row 43 q (Miss!C43 special formula).
            % C43 = rho_accel/2 × ((V_accel + V_liftoff)/2)²
            % Used in BOTH Accel and Climb: fuel formula (q_prev) and Ps time formula.
            % The standard rho_10000×V_10000²/2 = 770.7 psf is ~2.24× too high.
            % Takeoff segment is index 1, Accel is index 2 in obj.inp.segment_names.
            [V_accel_end,   ~] = obj.velocity_(obj.alt_ft(2), obj.mach_end(2));
            [V_accel_start, ~] = obj.velocity_(obj.alt_ft(1), obj.mach_end(1));
            [~, ~, ~, rho_accel_si] = atmosisa(obj.alt_ft(2) * 0.3048);
            rho_accel  = rho_accel_si / 515.379;   % kg/m³ → slug/ft³
            q_accel_43 = 0.5 * rho_accel * ...
                         ((V_accel_end + V_accel_start) / 2)^2;  % = 344.0 psf (Miss!C43)

            for i = 1:n
                seg     = obj.inp.segment_names{i};
                alt_end = obj.alt_ft(i);
                M_end   = obj.mach_end(i);
                pAB     = obj.pct_AB(i);
                cdx     = obj.CDx(i);
                drop    = obj.drop_lb(i);

                % Start-of-segment conditions (end of previous segment)
                if i == 1
                    alt_start = 0;
                    M_start   = 0;
                else
                    alt_start = obj.alt_ft(i-1);
                    M_start   = obj.mach_end(i-1);
                end

                % ── Per-segment fuel, time, distance ─────────────────────
                switch seg
                    case 'Takeoff'
                        [dW, t, d] = obj.segment_takeoff_(W_frac, WS, TW, W_TO_lb);
                        obj.takeoff_dist_ft = d * 6080 * 0.0001;  % store ft separately below
                        % d is in ft for takeoff; override dist_nm later
                        obj.takeoff_dist_ft = d;   % [ft]
                        d_nm = d / 6080;           % convert to nmi for table

                    case 'Accel'
                        % Pass q_accel_43 so segment_accel_() uses C43=344.0 psf
                        % in its Ps (time) calculation — not rho×V²/2=770.7 psf.
                        [dW, t, d_nm] = obj.segment_accel_( ...
                            alt_start, M_start, alt_end, M_end, ...
                            W_frac, pAB, cdx, WS, TW, q_accel_43);

                    case 'Combat'
                        [dW, t, d_nm] = obj.segment_combat_( ...
                            alt_end, M_end, W_frac, pAB, cdx, drop, W_TO_lb);

                    case 'Landing'
                        [dW, t, d_nm] = obj.segment_landing_(W_frac_after_TO, W_TO);
                        obj.landing_dist_ft = d_nm * 6080;  % stored in nm temporarily

                    otherwise
                        % Generic: Climb, Cruise, Patrol, Dash, Patrol2,
                        %          Egress, Patrol3, Climb2, Cruise2, Loiter
                        % For Climb: pass Accel's Row 43 q (C43) as q_prev
                        % override — the standard rho*V^2/2 at 10000ft M=0.87
                        % is ~2.24× too high due to the Accel average-speed formula.
                        if strcmp(seg, 'Climb')
                            q_prev_arg = q_accel_43;
                        else
                            q_prev_arg = NaN;
                        end
                        [dW, t, d_nm] = obj.segment_generic_( ...
                            alt_start, M_start, alt_end, M_end, ...
                            W_frac, pAB, cdx, drop, WS, TW, seg, q_prev_arg, W_TO_lb);
                end

                obj.dW_Wto(i)  = dW;
                obj.time_min(i) = t;

                % For Takeoff: store distance in ft for takeoff_dist_ft,
                % and convert to nmi for the table.
                if strcmp(seg, 'Takeoff')
                    obj.dist_nm(i) = obj.takeoff_dist_ft / 6080;
                elseif strcmp(seg, 'Landing')
                    obj.landing_dist_ft = d_nm * 6080;
                    obj.dist_nm(i) = d_nm;
                else
                    obj.dist_nm(i) = d_nm;
                end

                obj.fuel_lb(i) = dW * W_TO - obj.drop_lb(i);
                W_frac         = W_frac - dW;
                obj.W_Wto(i)   = W_frac;

                % Store W_frac after takeoff (used in landing distance formula)
                if strcmp(seg, 'Takeoff')
                    W_frac_after_TO = W_frac;
                end
            end

            % ── Totals (Miss!O8, O9) — segments 1–13 (excluding Landing)
            obj.total_fuel_lb  = sum(obj.fuel_lb(1:end-1));
            obj.total_time_min = sum(obj.time_min(1:end-1));

            % Re-compute landing distance with correct W_frac_after_TO
            % (matches Miss!O6 formula which uses Miss!B12 = W_frac after takeoff)
            obj.landing_dist_ft = obj.landingDist_(W_frac_after_TO, W_TO);

            obj.validate_run_();
            obj.computed_ = true;
            results = obj.packResults_();
        end

        % ─────────────────────────────────────────────────────────────────
        function T = displayMissionTable(obj)
        % displayMissionTable  Return (and print) mission summary as MATLAB table.
        %
        % Computed values are NaN until run() is called.
        % Columns match Main!J32:Y45 layout.
            n    = numel(obj.inp.segment_names);
            names = obj.inp.segment_names(:);

            if obj.computed_
                time_col = obj.time_min(:);
                dist_col = obj.dist_nm(:);
                fuel_col = obj.fuel_lb(:);
                wfrac    = obj.W_Wto(:);
                dwfrac   = obj.dW_Wto(:);
            else
                time_col = nan(n, 1);
                dist_col = nan(n, 1);
                fuel_col = nan(n, 1);
                wfrac    = nan(n, 1);
                dwfrac   = nan(n, 1);
            end

            T = table(names, ...
                obj.alt_ft(:), obj.mach_end(:), obj.pct_AB(:), ...
                obj.CDx(:), obj.drop_lb(:), ...
                time_col, dist_col, fuel_col, wfrac, dwfrac, ...
                'VariableNames', { ...
                    'Segment', 'Alt_ft', 'Mach', 'pct_AB', ...
                    'CDx', 'Drop_lb', ...
                    'Time_min', 'Dist_nm', 'Fuel_lb', 'W_Wto', 'dW_Wto'});

            if obj.computed_
                fprintf('\n=== BrandtMission Results ===\n');
                fprintf('  Total fuel  : %8.2f lb   (Miss!O9 ref: 6000.43 lb)\n', obj.total_fuel_lb);
                fprintf('  Total time  : %8.2f min  (Miss!O8 ref: 94.06 min)\n',   obj.total_time_min);
                fprintf('  Landing dist: %8.2f ft   (Miss!O6 ref: 2884.95 ft)\n',  obj.landing_dist_ft);
                fprintf('  Final W/W_TO:  %.4f\n', obj.W_Wto(end));
            end

            disp(T);
        end
    end

    % ═════════════════════════════════════════════════════════════════════
    methods (Access = private)

        % ── TSFC (Engn(s) Old model, Miss tab rows 34–35) ─────────────
        function cT = tsfc_old_(obj, alt_ft, mach, pct_AB)
        % tsfc_old_  Installed TSFC using the "Engn(s) Old" model.
        %
        % Miss tab rows 34–35 formula (verified against Excel cell values):
        %   cT_dry = install × TSFC_sl_dry × (1 + 0.35×|M|)    × sqrt(θ)
        %   cT_AB  = install × TSFC_sl_AB  × (1 + 0.35×|M-0.4|)× sqrt(θ)
        %   cT     = cT_dry + (%AB/100) × (cT_AB − cT_dry)
        %
        % θ = T_ISA(h)/518.69.  This differs from BrandtEngine (New model)
        % which uses sqrt(alpha) = sqrt(delta0×(1−0.3M)) for altitude
        % correction.  The Old model uses the simpler sqrt(θ) (static
        % temperature ratio), matching Miss!B34 through Miss!N34 exactly.
        %
        % install factor = 1.08 (Miss!C25 = Main!C25, duct/installation loss)
            install = obj.inp.install_factor;  % 1.08

            % ISA static temperature ratio θ via atmosisa (T in K, T_SL = 288.15 K)
            [T_K, ~, ~, ~] = atmosisa(alt_ft * 0.3048);
            theta = T_K / 288.15;

            cT_dry = install .* obj.eng_.TSFC_sl_dry ...
                     .* (1 + 0.35 .* abs(mach)) .* sqrt(theta);
            cT_AB  = install .* obj.eng_.TSFC_sl_AB ...
                     .* (1 + 0.35 .* abs(mach - 0.4)) .* sqrt(theta);

            cT = cT_dry + (pct_AB / 100) .* (cT_AB - cT_dry);
        end

        % ── Aerodynamics per segment ───────────────────────────────────
        function [CDo, k1, k2] = aero_at_(obj, mach, cdx)
        % aero_at_  Drag polar coefficients with extra drag CDx added.
        %
        % Uses BrandtAerodynamics.aero_at_mach() for Mach-dependent
        % CDo, k1, k2 (piecewise-linear interpolation across Mcrit/Mwave).
        % CDx (landing gear, pylons, etc.) is added to CDo.
        % Matches Miss tab rows 26–28.
            [CDo_base, k1, k2, ~] = obj.aero_.aero_at_mach(mach);
            CDo = CDo_base + cdx;
        end

        % ── Drag-coefficient sum ───────────────────────────────────────
        function val = drag_coeff_sum_(~, CDo, k1, k2, WS, W_frac, q)
        % drag_coeff_sum_  CD-based drag normalised by W_TO (per unit q×S).
        %
        % Computes the parenthesised expression in the generic fuel formula:
        %   CDo/(W/S) + k1×(Wf/q)²×(W/S) + k2×(Wf/q)
        % where Wf = W_frac_prev.
        % This × q_avg × cT/60 × t gives dW/W_TO for drag fuel.
        % Matches Miss tab row 13 formula (e.g. D13 part-1 expression).
            x   = W_frac ./ q;
            val = CDo ./ WS + k1 .* x.^2 .* WS + k2 .* x;
        end

        % ── Speed of sound and TAS ─────────────────────────────────────
        function [V, a] = velocity_(~, alt_ft, mach)
        % velocity_  True airspeed [ft/s] and speed of sound [ft/s].
        %
        % Uses atmosisa (altitude in metres) for ISA speed of sound.
        % a [ft/s] = a_SI [m/s] / 0.3048.
        % Matches Miss tab row 31 (sound speed) and row 32 (TAS).
            [~, a_ms, ~, ~] = atmosisa(alt_ft .* 0.3048);
            a = a_ms ./ 0.3048;   % m/s → ft/s
            V = mach .* a;
        end

        % ── Specific excess power (Ps) ─────────────────────────────────
        function Ps = Ps_(obj, ...
                alt_start, M_start, alt_end, M_end, ...
                W_frac_prev, pct_AB_end, cdx_start, cdx_end, WS, TW, ...
                q_start_override, q_end_override)
        % Ps_  Average specific excess power [ft/s].
        %
        % Miss tab row 45 formula averages Ps at end and start conditions:
        %   Ps_end   = V_end   × (α_end/Wf   × TW − q_end   × drag_sum_end)
        %   Ps_start = V_start × (α_start_mixed/Wf × TW − q_start × drag_sum_start)
        %   Ps       = (Ps_end + Ps_start) / 2
        %
        % α_start_mixed uses END segment %AB applied to START conditions,
        % which matches the Miss!C45 formula pattern:
        %   B41 + C$6/100*(B42-B41)  (column B conditions, column C %AB)
        %
        % q_start_override / q_end_override: optional overrides for the
        % dynamic pressure at start/end.  Needed when Row 43 q differs from
        % the standard rho×V²/2 formula.  Specifically:
        %   Accel Ps end  (C45 Ps_end):  uses C43=344.0 psf, not rho_10000×V²/2=770.7
        %   Climb Ps start (D45 Ps_start): uses C43=344.0 psf (same as above)
        %
        % W_frac_prev is the weight fraction at START of segment (end of prev).
            if nargin < 12, q_start_override = NaN; end
            if nargin < 13, q_end_override   = NaN; end

            [V_end, ~]   = obj.velocity_(alt_end, M_end);
            [V_start, ~] = obj.velocity_(alt_start, M_start);

            [~, ~, ~, rho_end_si]   = atmosisa(alt_end   * 0.3048);
            [~, ~, ~, rho_start_si] = atmosisa(alt_start * 0.3048);
            rho_end   = rho_end_si   / 515.379;   % kg/m³ → slug/ft³
            rho_start = rho_start_si / 515.379;
            q_end   = 0.5 * rho_end   * V_end^2;
            q_start = 0.5 * rho_start * V_start^2;

            % Apply q overrides (Row 43 special formula for Accel/Climb Ps)
            if ~isnan(q_end_override),   q_end   = q_end_override;   end
            if ~isnan(q_start_override), q_start = q_start_override; end

            alpha_end   = obj.eng_.run(alt_end,   M_end,   pct_AB_end / 100).alpha_AB_ref;
            alpha_start = obj.eng_.run(alt_start, M_start, pct_AB_end / 100).alpha_AB_ref;

            [CDo_end, k1_end, k2_end]     = obj.aero_at_(M_end,   cdx_end);
            [CDo_start, k1_start, k2_start] = obj.aero_at_(M_start, cdx_start);

            dc_end   = obj.drag_coeff_sum_(CDo_end,   k1_end,   k2_end,   WS, W_frac_prev, q_end);
            dc_start = obj.drag_coeff_sum_(CDo_start, k1_start, k2_start, WS, W_frac_prev, q_start);

            Ps_end   = V_end   * (alpha_end   / W_frac_prev * TW - q_end   * dc_end);
            Ps_start = V_start * (alpha_start / W_frac_prev * TW - q_start * dc_start);

            Ps = (Ps_end + Ps_start) / 2;
        end

        % ── TAKEOFF segment ───────────────────────────────────────────
        function [dW, t, d_ft] = segment_takeoff_(obj, W_frac, WS, TW, W_TO_lb)
        % segment_takeoff_  Fuel fraction and ground-roll for takeoff segment.
        %
        % Miss!B13 fuel formula (verified against Excel):
        %   dW/W_TO = 1.2 × cT_AB / (g×3600) × V_stall_TO     [ground-roll fuel]
        %           + TW × cT_dry_SLS / 60                       [1-min warmup at dry]
        %           + 1000 × n_eng / W_TO                        [fixed start fuel lb]
        %
        % V_stall_TO = sqrt(2 × W/S / ρ_SL / CLmax_TO)
        %
        % Miss!B7 ground-roll distance (verified against Excel B7 = 2270.3 ft):
        %   d = WS/TW × liftoff_factor² / ρ_SL / CLmax_TO / g
        %       / (1 − CD_roll_factor − μ/TW)
        %   CD_roll_factor = (CDo_TO+CDx)/2 × ρ_SL × (0.7×V_liftoff)² / WS / TW
        %
        %   NOTE: Excel formula is Main!K30/M30 × Main!U12² / B22 / L9 / 32.2 / …
        %   where Main!U12 = 1.2 (liftoff FACTOR, not Mach number).
        %   The ² applies to the liftoff factor (1.44), NOT to V_stall in ft/s.
        %
        % Miss!B8 takeoff time (verified against Excel B8 = 0.2234 min):
        %   t = V_liftoff / (g × TW × alpha_TO) / 60
        %   alpha_TO = thrust lapse at takeoff conditions (B40 = 0.9640 at 100%AB)
            g        = 32.2;           % ft/s²
            [~, ~, ~, rho_SL_si] = atmosisa(0);
            rho_SL = rho_SL_si / 515.379;   % kg/m³ → slug/ft³
            CLmax_TO = obj.inp.CLmax_TO;
            n_eng    = obj.eng_.n_engines;
            W_TO     = W_TO_lb;
            warmup   = obj.inp.warmup_fuel_per_engine_lb;

            % Takeoff: h=0, M=0.282 (liftoff Mach from JSON mach_end(1))
            M_TO  = obj.mach_end(1);
            cdx   = obj.CDx(1);

            % TSFC at takeoff conditions (100% AB, h=0)
            cT_AB  = obj.tsfc_old_(0, M_TO, 100);  % B35
            cT_dry = obj.tsfc_old_(0, M_TO, 0);    % B34 (used for warmup min)

            V_stall   = sqrt(2 * WS / rho_SL / CLmax_TO);    % Miss!B32/1.2
            V_liftoff = obj.inp.liftoff_factor * V_stall;     % Miss!B32

            % Term 1: ground-roll fuel (integrated AB at velocity ramp)
            term1 = 1.2 * cT_AB / (g * 3600) * V_stall;

            % Term 2: 1 min warmup at dry power
            term2 = TW * cT_dry / 60;

            % Term 3: fixed warmup/taxi fuel per engine (1000 lb/engine fixed)
            term3 = warmup * n_eng / W_TO;

            dW = term1 + term2 + term3;

            % Time: V_liftoff / (g × TW × alpha_TO) / 60  [Miss!B8]
            % alpha_TO = thrust lapse at 100%AB, h=0, M_TO (= Miss!B40), normalised to T_sl_AB
            alpha_TO = obj.eng_.run(0, M_TO, 1.0).alpha_AB_ref;
            t = V_liftoff / (g * TW * alpha_TO) / 60;

            % Ground-roll distance: WS/TW × liftoff_factor² / rho_SL / CLmax / g
            %   / (1 - CD_roll - mu/TW)   [Miss!B7]
            % liftoff_factor² = 1.44; NOT V_stall² in ft²/s²
            [CDo_TO, ~, ~] = obj.aero_at_(M_TO, cdx);
            CD_roll = (CDo_TO + cdx) / 2 * rho_SL * (0.7 * V_liftoff)^2 / WS / TW;
            mu  = obj.inp.mu_rolling;
            d_ft = WS / TW * obj.inp.liftoff_factor^2 / rho_SL / CLmax_TO / g ...
                   / (1 - CD_roll - mu / TW);
        end

        % ── ACCEL segment ─────────────────────────────────────────────
        function [dW, t, d_nm] = segment_accel_(obj, ...
                alt_start, M_start, alt_end, M_end, ...
                W_frac, pct_AB, cdx, WS, TW, q_accel_43_in)
        % segment_accel_  Fuel fraction for acceleration segment.
        %
        % Miss!C13 formula:
        %   dW/W_TO = α_C × TW × cT_C × t_min / 60
        % where:
        %   α_C   = thrust_lapse_norm at END conditions (0% AB)
        %   cT_C  = TSFC at END conditions (C33 = end-only, not averaged)
        %   t_min = Miss!C8 from Ps calculation
        %
        % Time from Ps (Miss!C8):
        %   t = |Δh/Ps/60| + |ΔV/(dV/dt)/60|
        %   Ps = average of start and end specific excess power
        %   dV/dt = 32.2 × Ps / V_avg × 2
        %
        % q_accel_43_in: Accel's C43 q override (rho_accel×((V_end+V_liftoff)/2)²/2)
        % used in the Ps formula for q_end.  If not provided, defaults to NaN
        % and time_from_Ps_ uses the standard rho×V²/2 (less accurate).

            if nargin < 11
                q_accel_43_in = NaN;
            end

            % Time from Ps: pass q_accel_43 as q_end override (Miss!C43 formula)
            cdx_start = obj.CDx(1);  % previous segment CDx = takeoff CDx
            t = obj.time_from_Ps_(alt_start, M_start, alt_end, M_end, ...
                W_frac, pct_AB, cdx_start, cdx, WS, TW, NaN, q_accel_43_in);

            % TSFC and thrust lapse at END conditions (normalised to T_sl_AB per Miss tab)
            cT_end  = obj.tsfc_old_(alt_end, M_end, pct_AB);
            alpha_C = obj.eng_.run(alt_end, M_end, pct_AB / 100).alpha_AB_ref;

            dW   = alpha_C * TW * cT_end * t / 60;
            [V_end, ~] = obj.velocity_(alt_end, M_end);
            d_nm = t * V_end / 6080 / 60;  % Miss!C7 = C8*C32/6080/60
        end

        % ── GENERIC segment ───────────────────────────────────────────
        function [dW, t, d_nm] = segment_generic_(obj, ...
                alt_start, M_start, alt_end, M_end, ...
                W_frac, pct_AB, cdx, drop, WS, TW, seg_name, q_prev_in, W_TO_lb)
        % segment_generic_  Fuel fraction for standard aerodynamic segments.
        %
        % Covers: Climb, Cruise, Patrol, Dash, Patrol2, Egress, Patrol3,
        %         Climb2, Cruise2, Loiter.
        %
        % Generic fuel formula (Miss tab row 13, D–N columns):
        %   dW = cT/60 × q_avg × drag_sum × t_min          [aerodynamic drag fuel]
        %      + cT/3600 × Wf × (Δh×2/(V_s+V_e) + ΔV/g)   [climb/accel energy fuel]
        %      + drop_lb / W_TO                              [jettisoned payload]
        %
        % cT is end-conditions only for constant-altitude segments;
        % averaged (start+end)/2 for climb segments (where alt_start≠alt_end).
        % Matches Miss!D33 formula = (D34+C34)/2 for Climb.
        %
        % q_prev_in (optional, default NaN): override for the start-segment
        % dynamic pressure. Used for Climb to pass Accel's C43 q value
        % (rho_accel × ((V_accel+V_liftoff)/2)²/2) rather than the standard
        % rho_start × V_start²/2 which overcounts by ~2.24×.
        %
        % W_TO_lb (optional, default from sizing loop context): takeoff gross
        % weight [lb]. Placed last so nargin checks on q_prev_in are unaffected.
        %
        % TIME determination by segment type:
        %   Climb, Climb2:           Ps formula (Miss!D8 = |Δh/Ps/60| + |ΔV/(dV/dt)/60|)
        %   Patrol, Patrol2, Patrol3: given as 0 min
        %   Cruise, Dash, Egress, Cruise2: t = dist_nm×6080/V_end/60
        %   Loiter:                  given time
        %   Combat:                  handled in segment_combat_
            g    = 32.2;
            W_TO = W_TO_lb;

            % Default q_prev_in to NaN if not provided
            if nargin < 13
                q_prev_in = NaN;
            end

            % Segment index (1-based) to look up given dist/time
            idx = find(strcmp(obj.inp.segment_names, seg_name), 1);

            given_dist = obj.inp.dist_nm_given(idx);
            given_time = obj.inp.time_min_given(idx);

            [V_end, ~]   = obj.velocity_(alt_end, M_end);
            [V_start, ~] = obj.velocity_(alt_start, M_start);
            [~, ~, ~, rho_end_si]   = atmosisa(alt_end   * 0.3048);
            [~, ~, ~, rho_start_si] = atmosisa(alt_start * 0.3048);
            rho_end   = rho_end_si   / 515.379;   % kg/m³ → slug/ft³
            rho_start = rho_start_si / 515.379;
            q_end        = 0.5 * rho_end   * V_end^2;
            % q_start: use override (e.g. Accel C43) when provided; else standard formula
            if ~isnan(q_prev_in)
                q_start = q_prev_in;
            else
                q_start = 0.5 * rho_start * V_start^2;
            end

            % ── Determine time ────────────────────────────────────────
            cdx_start = obj.CDx(max(1, idx-1));  % CDx of previous segment

            if ~isnan(given_time) && given_time == 0
                % Zero-time patrol or Climb2 with same conditions
                t = 0;
            elseif ~isnan(given_time)
                % Given time (Loiter = 20 min)
                t = given_time;
            elseif ~isnan(given_dist) && given_dist > 0
                % Given distance → time = dist / speed
                t = given_dist * 6080 / V_end / 60;
            elseif ~isnan(given_dist) && given_dist == 0
                t = 0;
            else
                % Climb: time from Ps; pass q_prev_in as q_start override
                % (for Climb, q_prev_in = q_accel_43 = C43 = 344.0 psf matching D45)
                t = obj.time_from_Ps_(alt_start, M_start, alt_end, M_end, ...
                    W_frac, pct_AB, cdx_start, cdx, WS, TW, q_prev_in, NaN);
            end

            % ── Distance ──────────────────────────────────────────────
            if ~isnan(given_dist)
                d_nm = given_dist;
            elseif t == 0
                d_nm = 0;
            else
                d_nm = t * V_end / 6080 / 60;  % approximate from end-segment speed
            end

            if t == 0
                dW = 0;
                return
            end

            % ── TSFC: average only for Ps-based climb segments ────────
            % Excel averages cT only for explicit "Climb" segments (D33, L33):
            %   D33 = (D34 + C34)/2,  L33 = (L34 + K34)/2
            % All other segments — including altitude-changing ones like Egress
            % (25000→40000 ft, J33=J34 end-only) and Loiter (40000→10000 ft
            % descent, N33=N34 end-only) — use end-conditions TSFC only.
            % Ps-based segments are identified by having neither a given time
            % nor a given distance (time_min_given=NaN, dist_nm_given=NaN).
            cT_end   = obj.tsfc_old_(alt_end,   M_end,   pct_AB);
            cT_start = obj.tsfc_old_(alt_start, M_start, pct_AB);

            is_ps_climb = isnan(given_time) && isnan(given_dist);
            if is_ps_climb
                cT = (cT_end + cT_start) / 2;
            else
                cT = cT_end;
            end

            % ── Drag and energy fuel ──────────────────────────────────
            [CDo_end,   k1_end,   k2_end]   = obj.aero_at_(M_end,   cdx);
            [CDo_start, k1_start, k2_start] = obj.aero_at_(M_start, cdx_start);
            CDo_avg = (CDo_end + CDo_start) / 2;
            k1_avg  = (k1_end  + k1_start)  / 2;
            k2_avg  = (k2_end  + k2_start)  / 2;

            q_avg   = (q_end + q_start) / 2;
            dc      = obj.drag_coeff_sum_(CDo_avg, k1_avg, k2_avg, WS, W_frac, q_avg);

            % Part 1: drag fuel
            part1 = cT / 60 * q_avg * dc * t;

            % Part 2: climb/acceleration energy fuel
            %   Δh × 2/(V_s+V_e) = time-averaged climb rate factor [s]
            %   ΔV / g            = velocity change factor [s]
            % Energy term is ONLY added for climbs/accelerations (energy_s > 0).
            % Descents are NOT credited — matches Miss tab (e.g. N13 Loiter
            % descends 30,000 ft but has no energy term in the Excel formula).
            dh = alt_end - alt_start;
            dV = V_end - V_start;
            energy_s = dh * 2 / (V_start + V_end) + dV / g;  % [s]
            if energy_s > 0
                part2 = cT / 3600 * W_frac * energy_s;
            else
                part2 = 0;
            end

            % Part 3: dropped payload
            part3 = drop / W_TO;

            dW = part1 + part2 + part3;
        end

        % ── COMBAT segment ────────────────────────────────────────────
        function [dW, t, d_nm] = segment_combat_(obj, ...
                alt_end, M_end, W_frac, pct_AB, cdx, drop, W_TO_lb)
        % segment_combat_  Fuel fraction for combat engagement.
        %
        % Miss!I9  = I8/60 × I33 × I49
        % Miss!I13 = (I9 + I10) / W_TO
        %
        % I8  = given time = 2 min
        % I33 = cT at combat conditions (50% AB, 25000 ft, M=0.87)
        % I49 = T_available = T_sl_AB × n_eng × α_AB_norm
        %       (full AB lapse at combat conditions)
        % I10 = drop payload = 4400 lb
        %
        % Note: I49 uses alpha at combat conditions (I40 = combined lapse
        % at 50% AB).  The formula I8/60 × cT × T_avail = fuel_burn [lb].

            idx = find(strcmp(obj.inp.segment_names, 'Combat'), 1);
            t   = obj.inp.time_min_given(idx);     % 2.0 min

            cT_combat    = obj.tsfc_old_(alt_end, M_end, pct_AB);
            alpha_combat = obj.eng_.run(alt_end, M_end, pct_AB / 100).alpha_AB_ref;

            T_avail = obj.eng_.T_sl_AB * obj.eng_.n_engines * alpha_combat;

            fuel_burn = t / 60 * cT_combat * T_avail;  % [lb]  Miss!I9

            dW  = (fuel_burn + drop) / W_TO_lb;
            d_nm = 0;
        end

        % ── LANDING segment ───────────────────────────────────────────
        function [dW, t, d_nm] = segment_landing_(obj, W_frac_after_TO, W_TO)
        % segment_landing_  Landing ground roll distance (no fuel burn).
        %
        % Miss!O6 formula (verified exact):
        %   d_land = U13² × (W_TO × Wf_TO)² / ρ_SL / S / CLmax_land / g
        %            / (O26 × Wf_TO × W_TO × 0.83/CLmax_TO + V13 × W_TO × Wf_TO)
        %
        % where:
        %   U13 = approach_factor = 1.3
        %   Wf_TO = W_frac after takeoff = Miss!B12 (≈ 0.9509)
        %   O26 = CDo at takeoff (CDmin + CDx_takeoff) — NOT landing CDo
        %   0.83/CLmax_TO ≈ average approach CD/CL for braking aero term
        %   V13 = mu_braking = 0.5
        %
        % Note: formula uses W_frac AFTER TAKEOFF (B12), not current
        % landing weight.  This is a textbook sizing approximation.
            dW   = 0;
            t    = 0;
            d_nm = obj.landingDist_(W_frac_after_TO, W_TO) / 6080;
        end

        function d_ft = landingDist_(obj, W_frac_after_TO, W_TO)
        % landingDist_  Compute landing distance [ft] from Miss!O6 formula.
            g    = 32.2;
            [~, ~, ~, rho_SL_si] = atmosisa(0);
            rho_SL = rho_SL_si / 515.379;   % kg/m³ → slug/ft³
            S        = obj.geom_.inp.wing.S_ref_ft2;
            CLmax_l  = obj.inp.CLmax_land;
            CLmax_TO = obj.inp.CLmax_TO;
            U13      = obj.inp.approach_factor;  % 1.3
            V13      = obj.inp.mu_braking;        % 0.5
            cdx_TO   = obj.CDx(1);                % 0.035
            [O26, ~, ~] = obj.aero_at_(obj.mach_end(1), cdx_TO);  % CDo at takeoff

            W_ref = W_TO * W_frac_after_TO;

            numer  = U13^2 * W_ref^2;
            denom  = rho_SL * S * CLmax_l * g ...
                     * (O26 * W_frac_after_TO * W_TO * 0.83 / CLmax_TO ...
                        + V13 * W_TO * W_frac_after_TO);
            d_ft = numer / denom;
        end

        % ── Time from Ps ──────────────────────────────────────────────
        function t = time_from_Ps_(obj, ...
                alt_start, M_start, alt_end, M_end, ...
                W_frac, pct_AB, cdx_start, cdx_end, WS, TW, ...
                q_start_override, q_end_override)
        % time_from_Ps_  Segment time [min] from specific excess power.
        %
        % Miss!D8 = ABS((D3-C3)/D45/60) + ABS((D32-C32)/D44/60)
        % Miss!C8 = ABS((C3-B3)/C45/60) + ABS((C32-B32)/C44/60)
        %
        % Ps (row 45) is the average of Ps at start and end conditions.
        % dV/dt (row 44) = 32.2 × Ps / V_avg × 2
        % (the factor 2 comes from linear velocity ramp assumption)
        %
        % q_start_override / q_end_override: optional q overrides forwarded to Ps_.
        % Used when Row 43 q differs from rho×V²/2 (e.g. Accel and Climb).
            if nargin < 12, q_start_override = NaN; end
            if nargin < 13, q_end_override   = NaN; end

            Ps = obj.Ps_(alt_start, M_start, alt_end, M_end, ...
                W_frac, pct_AB, cdx_start, cdx_end, WS, TW, ...
                q_start_override, q_end_override);

            [V_end, ~]   = obj.velocity_(alt_end,   M_end);
            [V_start, ~] = obj.velocity_(alt_start, M_start);

            dh = alt_end - alt_start;
            dV = V_end - V_start;

            % dV/dt = 32.2 × Ps / (V_start + V_end) × 2  (Miss!D44 formula)
            V_sum = V_start + V_end;
            if V_sum > 0 && abs(Ps) > 1e-6
                dVdt = 32.2 * Ps / V_sum * 2;
            else
                dVdt = inf;
            end

            t_alt = (abs(Ps) > 1e-6) * abs(dh / Ps / 60);
            t_vel = (abs(dVdt) > 1e-6) * abs(dV / dVdt / 60);
            t = t_alt + t_vel;
        end

        function r = packResults_(obj)
            r.segment_names        = obj.inp.segment_names;
            r.alt_ft               = obj.alt_ft;
            r.mach_end             = obj.mach_end;
            r.pct_AB               = obj.pct_AB;
            r.CDx                  = obj.CDx;
            r.drop_lb              = obj.drop_lb;
            r.time_min             = obj.time_min;
            r.dist_nm              = obj.dist_nm;
            r.fuel_lb              = obj.fuel_lb;
            r.W_Wto                = obj.W_Wto;
            r.dW_Wto               = obj.dW_Wto;
            r.total_fuel_lb        = obj.total_fuel_lb;
            r.total_time_min       = obj.total_time_min;
            r.landing_dist_ft      = obj.landing_dist_ft;
            r.takeoff_dist_ft      = obj.takeoff_dist_ft;
        end

        % ── Run validation ─────────────────────────────────────────────
        function validate_run_(obj)
            assert(~isnan(obj.total_fuel_lb),   'LevelBrandt:nanOutput', 'total_fuel_lb is NaN');
            assert(~isnan(obj.total_time_min),  'LevelBrandt:nanOutput', 'total_time_min is NaN');
            assert(~isnan(obj.landing_dist_ft), 'LevelBrandt:nanOutput', 'landing_dist_ft is NaN');
            assert(obj.total_fuel_lb > 0, 'LevelBrandt:invalidOutput', 'total_fuel_lb must be positive');
        end
    end
end
