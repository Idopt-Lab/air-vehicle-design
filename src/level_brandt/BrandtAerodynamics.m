classdef BrandtAerodynamics < handle
% BrandtAerodynamics  Replicates Brandt-F16-A.xls Aero tab.
%
% Usage:
%   geom = BrandtGeometry(); geom.compute();
%   aero = BrandtAerodynamics(geom);
%   aero.compute();
%
%   % Subsonic drag polar (Miss tab basis, CD0=0.0270):
%   CD = aero.drag_polar(CL);
%   CD = aero.drag_polar_takeoff(CL);
%
%   % Mach-dependent polar (Aero tab A5:E10 basis, CDmin_sub=0.01691):
%   [CDo, k1_m, k2_m, CDmin] = aero.aero_at_mach(mach);
%
%   % CLmax:
%   aero.CLmax_clean    % H25 = 0.984
%   aero.CLmax_takeoff  % H27 = 1.276
%   aero.CLmax_landing  % H29 = 1.426

    properties
        inp   (1,1) struct   % raw JSON inputs + geom reference

        % ------- Mach thresholds -------
        Mcrit       (1,1) double = NaN   % Aero!A12 = 0.8727
        M_wave      (1,1) double = NaN   % Aero!G8  = 1.0547  (wave drag onset)
        M_LE_super  (1,1) double = NaN   % Aero!F9  = 1.3054  (LE becomes supersonic)

        % ------- Oswald efficiency -------
        e0          (1,1) double = NaN   % Aero!G12 = 0.9144  (for k1 via e0 formula)
        e_wing      (1,1) double = NaN   % Aero!A19 = 0.7227  (wing span efficiency)
        e_pitch     (1,1) double = NaN   % Aero!A28 = 0.7227  (stabilator span efficiency)

        % ------- Lift curve slopes (per degree, incompressible) -------
        CL_alpha_wing   (1,1) double = NaN   % Aero!A15 = 0.05431
        CL_alpha_pitch  (1,1) double = NaN   % Aero!A23 = 0.05431
        CL_alpha_total  (1,1) double = NaN   % Aero!A32 = 0.06150 (wing+strake+tail)
        downwash        (1,1) double = NaN   % Aero!A40 = 0.8175  (de/dalpha)

        % ------- Polar shape (subsonic, Miss tab basis) -------
        CL0         (1,1) double = NaN   % Aero!G20 = 0.02716
        Cfe_eff     (1,1) double = NaN   % JSON Cfe = 0.005908
        CD0         (1,1) double = NaN   % Miss!CD0_cruise = 0.0270
        k1          (1,1) double = NaN   % Miss!k1 = 0.1160
        k2          (1,1) double = NaN   % Miss!k2 = -0.00630
        CD0_takeoff (1,1) double = NaN   % Miss!CD0_TO = 0.0520
        LD_max      (1,1) double = NaN   % Miss!LD_max = 8.93
        CL_opt      (1,1) double = NaN   % Miss!CL_opt = 0.482

        % ------- Aero tab (tabulated Cfe, for A5:E10 validation) -------
        CDmin_sub   (1,1) double = NaN   % Aero!G3 = 0.01691 (CDmin using Cfe_tab)

        % ------- Flapped area -------
        S_flapped   (1,1) double = NaN   % Aero!L31 = 144.745 ft²

        % ------- CLmax -------
        CLmax_clean   (1,1) double = NaN   % Aero!H25 = 0.984
        CLmax_takeoff (1,1) double = NaN   % Aero!H27 = 1.276
        CLmax_landing (1,1) double = NaN   % Aero!H29 = 1.426

        computed_ (1,1) logical = false
    end

    methods
        function obj = BrandtAerodynamics(brandtGeomObj)
        % Load JSON and store reference to an already-computed BrandtGeometry.
        % brandtGeomObj must have had compute() called before passing in.
            json_path = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), ...
                'examples', 'F-16A B Block 10 and 15', 'Ground-Truth', 'f16a_geometry.json');
            obj.inp = jsondecode(fileread(json_path));
            obj.inp.geom_ = brandtGeomObj;   % handle reference, not a copy
        end

        function compute(obj)
        % Compute all Aero-tab quantities in Brandt formula order.

            g   = obj.inp.geom_;          % BrandtGeometry handle
            w   = obj.inp.wing;
            pc  = obj.inp.pitch_ctrl;
            ae  = obj.inp.aero;

            S_ref    = w.S_ref_ft2;       % 300 ft²
            AR       = w.AR;              % 3.0
            S_wet    = g.S_wet_total_accurate_ft2;  % 1371.09 ft² (corrected)
            S_strake = obj.inp.strake.S_ft2;        % 20 ft²
            S_pitch  = pc.S_ft2;          % 108 ft²

            sweep_LE_rad = deg2rad(w.sweep_LE_deg); % 40° → rad

            % ---------------------------------------------------------------
            % 1. MACH THRESHOLDS
            % ---------------------------------------------------------------
            % Aero!A12: Mcrit from airfoil t/c and LE sweep
            NACA_code = str2double(strrep(w.airfoil, 'NACA ', ''));
            tc_pct    = mod(NACA_code, 100);   % last 2 digits = t/c percent (4 for NACA 1404)
            obj.Mcrit = 1 - 0.065 * (cos(sweep_LE_rad) * tc_pct)^0.6;

            % Aero!G8: Mach where wave drag onset = sec(ΛLE)^0.2
            obj.M_wave = (1/cos(sweep_LE_rad))^0.2;

            % Aero!F9: Mach where LE becomes supersonic = sec(ΛLE)
            obj.M_LE_super = 1/cos(sweep_LE_rad);

            % ---------------------------------------------------------------
            % 2. WING TE SWEEP (needed for e_wing and CLmax flap angle)
            % ---------------------------------------------------------------
            % TE sweep from geometry: atan((x_TE_tip - x_TE_root)/half_span)
            x_TE_root = w.x_apex_ft + g.wing.c_root_ft;
            x_LE_tip  = w.x_apex_ft + g.wing.half_span_ft * tan(sweep_LE_rad);
            x_TE_tip  = x_LE_tip + g.wing.c_tip_ft;
            TE_sweep_deg  = atan2d(x_TE_tip - x_TE_root, g.wing.half_span_ft); % ≈ 0°
            TE_sweep_pitch_deg = TE_sweep_deg;  % same formula applies to stabilator

            % ---------------------------------------------------------------
            % 3. SPAN EFFICIENCY FOR LIFT CURVE SLOPE
            % ---------------------------------------------------------------
            % Aero!A19: e_wing = MAX(0.6, 2/(2-AR+sqrt(4+AR^2*(1+tan^2(avg_sweep)))))
            % avg_sweep = (LE_sweep + TE_sweep)/2 ≈ 20° for F-16A
            avg_sweep_wing_rad  = deg2rad((w.sweep_LE_deg  + TE_sweep_deg)  / 2);
            avg_sweep_pitch_rad = deg2rad((pc.sweep_LE_deg + TE_sweep_pitch_deg) / 2);
            AR_pitch = pc.AR;

            e_w = 2 / (2 - AR + sqrt(4 + AR^2 * (1 + tan(avg_sweep_wing_rad)^2)));
            obj.e_wing = max(0.6, e_w);

            e_p = 2 / (2 - AR_pitch + sqrt(4 + AR_pitch^2 * (1 + tan(avg_sweep_pitch_rad)^2)));
            obj.e_pitch = max(0.6, e_p);

            % ---------------------------------------------------------------
            % 4. LIFT CURVE SLOPES  (per degree, incompressible)
            % ---------------------------------------------------------------
            % Aero!A15: CL_alpha_wing [/deg] = 0.1 / (1 + 5.73/(pi*e_wing*AR))
            obj.CL_alpha_wing  = 0.1 / (1 + 5.73 / (pi * obj.e_wing  * AR));
            obj.CL_alpha_pitch = 0.1 / (1 + 5.73 / (pi * obj.e_pitch * AR_pitch));

            % ---------------------------------------------------------------
            % 5. OSWALD e0 (for induced drag / k1)
            % ---------------------------------------------------------------
            % Aero!G12: e0 = MAX(0.4, 4.6*(1-0.033*AR^0.53)*cos(ΛLE)^0.1 - 3.3)
            obj.e0 = max(0.4, 4.6 * (1 - 0.033 * AR^0.53) * cos(sweep_LE_rad)^0.1 - 3.3);

            % Aero!G10: k1 = 1/(pi*e0*AR)
            obj.k1 = 1 / (pi * obj.e0 * AR);

            % ---------------------------------------------------------------
            % 6. CL0 AND k2
            % ---------------------------------------------------------------
            % Aero!G20: CL0 = CL_alpha_wing[/deg] * floor(sqrt(NACA/1000)) / 2
            % For NACA 1404: floor(sqrt(1.404)) = 1  →  CL0 = A15/2
            naca_camber_digit = floor(sqrt(NACA_code / 1000));
            obj.CL0 = obj.CL_alpha_wing * naca_camber_digit / 2;

            % Aero!G17: k2 = -2*k1*CL0
            obj.k2 = -2 * obj.k1 * obj.CL0;

            % ---------------------------------------------------------------
            % 7. DRAG POLAR (subsonic) — two bases
            % ---------------------------------------------------------------
            % CDmin_sub: Aero tab basis (Cfe_tab = J3, gives Aero!G3 = 0.01691)
            obj.Cfe_eff   = ae.Cfe;
            obj.CDmin_sub = ae.Cfe_tab * S_wet / S_ref;

            % CD0: Mission tab basis (Cfe_eff, gives Miss!CD0_cruise = 0.0270)
            obj.CD0        = ae.Cfe * S_wet / S_ref;
            obj.CD0_takeoff= ae.CD0_takeoff;

            % Aero!G15/Miss!LD_max = 0.5/sqrt(CD0*k1)  [simplified, ignores k2]
            obj.LD_max = 0.5 / sqrt(obj.CD0 * obj.k1);
            obj.CL_opt = sqrt(obj.CD0 / obj.k1);

            % ---------------------------------------------------------------
            % 8. STRAKE-CORRECTED AND TOTAL CL_ALPHA
            % ---------------------------------------------------------------
            % Aero!A36: account for strake adding lift area
            CL_alpha_strake = obj.CL_alpha_wing * (S_ref + S_strake) / S_ref;

            % Aero!A40: downwash gradient de/dalpha (= A40 in Excel)
            c_root_w = g.wing.c_root_ft;   % 16.293 ft
            c_tip_w  = g.wing.c_tip_ft;    % 3.707 ft
            b_full   = 2 * g.wing.half_span_ft;  % 30 ft
            x_apex_w = w.x_apex_ft;        % 17.786 ft
            x_le_pc  = pc.x_le_ft;         % 36.0 ft
            taper    = w.taper;            % 0.2275
            dz       = pc.z_ft - w.z_ft;  % vertical separation (0 for F-16A)

            delta_x  = x_le_pc - 0.25*c_tip_w - x_apex_w - 0.25*c_root_w;
            c_avg    = (c_root_w + c_tip_w) / 2;  % 10.0 ft
            A40 = min(1, sign(delta_x) * 21 * obj.CL_alpha_wing / sqrt(AR) ...
                * (c_avg / abs(delta_x))^0.25 ...
                * (10 - 3*taper) / 7 ...
                * (1 - dz / b_full));
            obj.downwash = A40;

            % Aero!A32: CL_alpha_total = CL_alpha_strake + CL_alpha_pitch*(1-A40)*S_pitch/S_ref
            obj.CL_alpha_total = CL_alpha_strake ...
                + obj.CL_alpha_pitch * (1 - A40) * S_pitch / S_ref;

            % ---------------------------------------------------------------
            % 9. FLAPPED AREA  (Aero!L31)
            % ---------------------------------------------------------------
            % S_flapped = S_ref - outboard_strip - inboard_strip
            % Outboard (aileron tip → wing tip, rectangle approx):
            %   (half_span - y_ail_tip)*2*(c_tip + (c_root-c_tip)*(half_span-y_ail_tip)/half_span)
            % Inboard (centerline → aileron root, bilateral trapezoid):
            %   y_ail_root*(c_root + c_at_ail_root)
            half_span  = g.wing.half_span_ft;  % 15.0 ft
            y_ail_root = g.aileron.y_root_ft;  % 3.5 ft
            y_ail_tip  = g.aileron.y_tip_ft;   % 11.246 ft
            c_at_ail_root = c_root_w - (c_root_w - c_tip_w) * y_ail_root / half_span;

            outboard_strip = (half_span - y_ail_tip) * 2 ...
                * (c_tip_w + (c_root_w - c_tip_w) * (half_span - y_ail_tip) / half_span);
            inboard_strip  = y_ail_root * (c_root_w + c_at_ail_root);
            obj.S_flapped  = max(0, S_ref - outboard_strip - inboard_strip);

            % ---------------------------------------------------------------
            % 10. CLmax  (Aero!H25, H27, H29)
            % ---------------------------------------------------------------
            % Aero!H25: CLmax_clean = CL_alpha_total[/deg] * alpha_stall_deg
            % alpha_stall = floor(NACA_camber + 15)  where NACA_camber = INT(NACA/1000)
            naca_camber   = floor(NACA_code / 1000);          % 1 for NACA 1404
            alpha_stall   = floor(naca_camber + 15);          % 16°
            obj.CLmax_clean = obj.CL_alpha_total * alpha_stall;

            % Aero!L33: Da_landing = 15*S_flapped/S_ref*cos(TE_sweep_rad)
            Da_landing = 15 * obj.S_flapped / S_ref * cosd(TE_sweep_deg);

            % Aero!L35: delta_CLmax = CL_alpha_total * Da_landing
            delta_CLmax = obj.CL_alpha_total * Da_landing;

            % Aero!L37: CLmax_from_flaps = CLmax_clean + delta_CLmax
            CLmax_from_flaps = obj.CLmax_clean + delta_CLmax;

            % Aero!L29: CLmax_trim_limited = CLmax_clean + pitch ctrl can trim
            % l_t = |x_le_pitch + 0.25*c_root_pitch - x_apex_wing - 0.5*c_root_wing|
            c_root_pc = g.pitch_ctrl.c_root_ft;  % 9.776 ft
            l_t       = abs(x_le_pc + 0.25*c_root_pc - x_apex_w - 0.5*c_root_w);
            CLmax_trim = obj.CLmax_clean ...
                + (obj.CL_alpha_pitch / obj.CL_alpha_wing) ...
                * (S_pitch / S_ref) * l_t / c_root_w / 0.5;

            % Aero!H29: CLmax_landing = min(trim_limit, flap_CLmax)
            obj.CLmax_landing = min(CLmax_trim, CLmax_from_flaps);

            % Aero!H27: CLmax_takeoff = CLmax_clean + 0.66*(CLmax_landing - CLmax_clean)
            obj.CLmax_takeoff = obj.CLmax_clean + 0.66 * (obj.CLmax_landing - obj.CLmax_clean);

            obj.computed_ = true;
        end

        % ------------------------------------------------------------------ %
        %  SUBSONIC DRAG POLAR  (Miss tab basis, CD0 = 0.0270)
        % ------------------------------------------------------------------ %

        function CD = drag_polar(obj, CL)
        % Clean drag polar: CD = CD0 + k1*CL^2 + k2*CL  (Miss tab basis)
        %
        % Input:  CL — scalar or vector
        % Output: CD — drag coefficient (same size as CL)
            obj.requireComputed_();
            CD = obj.CD0 + obj.k1 .* CL.^2 + obj.k2 .* CL;
        end

        function CD = drag_polar_takeoff(obj, CL)
        % Takeoff drag polar: CD0_TO + k1*CL^2 + k2*CL  (Miss tab basis)
            obj.requireComputed_();
            CD = obj.CD0_takeoff + obj.k1 .* CL.^2 + obj.k2 .* CL;
        end

        function [CL_opt, LD] = max_LD(obj)
        % Returns (CL, L/D) at maximum lift-to-drag ratio.
        % Brandt simplified formula (k2 ignored).
            obj.requireComputed_();
            CL_opt = obj.CL_opt;
            LD     = obj.LD_max;
        end

        % ------------------------------------------------------------------ %
        %  MACH-DEPENDENT DRAG POLAR  (Aero tab A5:E10 basis)
        % ------------------------------------------------------------------ %

        function [CDo, k1_m, k2_m, CDmin] = aero_at_mach(obj, mach)
        % Mach-dependent drag polar coefficients (Aero tab A5:E10 methodology).
        %
        % Uses the tabulated Cfe (Cfe_tab) for CDmin_sub, then adds Sears-Haack
        % wave drag above M_wave, following the exact Excel formulas in A5:E10.
        %
        % Input:  mach — scalar Mach number
        % Output: CDo  — drag coefficient at CL=0
        %         k1_m — induced drag factor
        %         k2_m — polar camber term
        %         CDmin— minimum drag coefficient (at CL_min_drag)
        %
        % Ground truth (Aero!A5:E10): M=0.1→CDmin=0.01691; M=M_wave→CDmin=0.04558
            obj.requireComputed_();

            Mcrit_      = obj.Mcrit;
            M_wave_     = obj.M_wave;
            M_LE_super_ = obj.M_LE_super;
            k1_sub_     = obj.k1;
            k2_sub_     = obj.k2;
            AR_         = obj.inp.wing.AR;
            sweep_rad_  = deg2rad(obj.inp.wing.sweep_LE_deg);
            S_ref_      = obj.inp.wing.S_ref_ft2;
            g_          = obj.inp.geom_;

            % k1 supersonic formula (D10 in Excel, row 10 = M=2.0 reference)
            k1_super_f  = @(M) AR_*(M^2-1)/(4*AR_*sqrt(M^2-1)-2)*cos(sweep_rad_);
            k1_M2       = k1_super_f(2.0);           % reference k1 at M=2.0 = 0.367

            % k1 at M_wave (Aero!D8): MAX(formula, (k1_sub+k1_M2)/2)
            k1_Mwave = max(k1_super_f(M_wave_), (k1_sub_ + k1_M2)/2);

            % Wave drag increment factor (Aero!B8 formula numerics)
            Amax  = g_.Amax_ft2;
            L_ac  = g_.aircraft_length_ft;
            Ewd   = obj.inp.aero.Ewd;
            wave_factor = 4.5*pi/S_ref_ * (Amax/L_ac)^2 * Ewd ...
                * (0.74 + 0.37*cos(sweep_rad_));

            if mach <= Mcrit_
                % Subsonic: all quantities at tabulated baseline
                CDmin  = obj.CDmin_sub;
                k1_m   = k1_sub_;
                k2_m   = k2_sub_;

            elseif mach <= M_wave_
                % Transition (Mcrit < M <= M_wave): interpolate linearly
                % At M = M_wave exactly: frac=1 → k1_m = k1_Mwave, CDmin = CDmin_sub + wave_factor
                frac   = (mach - Mcrit_) / (M_wave_ - Mcrit_);
                CDwave_at_Mwave = wave_factor;  % (1-0.3*(0)^0.5) = 1 at M_wave
                CDmin  = obj.CDmin_sub + frac * CDwave_at_Mwave;
                k1_m   = k1_sub_ + frac * (k1_Mwave - k1_sub_);
                k2_m   = k2_sub_ * (1.5 - mach) / (1.5 - Mcrit_);

            elseif mach <= 2.0
                % Supersonic: wave drag + k1 floor + k2 linear decay toward zero at M=1.5
                % min(0,...) clamps correctly: k2_sub<0, so (1.5-M)/(1.5-Mcrit) is positive
                % for M>1.5, making the product positive; min clamps that to 0.
                M_cap  = min(mach, M_LE_super_);
                CDwave = wave_factor * (1 - 0.3*(M_cap - M_wave_)^0.5);
                CDmin  = obj.CDmin_sub + CDwave;
                k1_m   = max(k1_super_f(mach), (k1_Mwave + k1_M2)/2);
                k2_m   = min(0, k2_sub_ * (1.5 - mach) / (1.5 - Mcrit_));

            else
                % M > 2.0: cap wave drag at M_LE_super, k1 uses formula
                M_cap  = M_LE_super_;
                CDwave = wave_factor * (1 - 0.3*(M_cap - M_wave_)^0.5);
                CDmin  = obj.CDmin_sub + CDwave;
                k1_m   = k1_super_f(mach);
                k2_m   = 0;
            end

            % CDo = CDmin + k1*CL0^2  (constant camber offset, Aero!B8 pattern)
            CDo = CDmin + obj.k1 * obj.CL0^2;
        end
    end

    methods (Access = private)
        function requireComputed_(obj)
            if ~obj.computed_
                error('LevelBrandt:notComputed', ...
                    'Call compute() before accessing aerodynamics results.');
            end
        end
    end
end
