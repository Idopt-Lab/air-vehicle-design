classdef AeroLevel3 < AerodynamicsBase
    % Level III aerodynamics: component drag buildup method.
    %
    % Computes CD0 by summing component skin friction and form factor drag
    % over fuselage, wing, and tail surfaces (Raymer Ch 12 method).
    % Includes Reynolds-number-based turbulent Cf rather than tabulated Cf.
    % Returns K1 (non-zero for cambered wings) and K2 from Oswald efficiency.
    %
    % The constructor takes a geometry object that must expose:
    %   geom.S_ref, geom.S_wet, geom.b, geom.AR, geom.e_osw
    %   geom.tc_wing, geom.xc_wing, geom.Lambda_max_t_deg
    %   geom.L_fus, geom.A_max_fus, geom.S_wet_fus
    %   geom.S_wet_wing (exposed wetted area of wing)
    %   geom.S_wet_HT, geom.S_wet_VT
    %   geom.skin_roughness_k  (ft)
    %   geom.CL_minD  (if known; 0 for uncambered)

    properties
        geom    % GeometryBase subclass instance
    end

    methods
        function obj = AeroLevel3(geom)
            obj.geom = geom;
        end

        function polar = drag_polar(obj, state)
            g = obj.geom;
            M = state.mach;

            % Fuselage component drag
            [V_fl, mu_fl, ~] = AeroLevel3.get_V_and_mu(M, state.altitude);
            R_fus = AeroLevel3.R(g.L_fus, state.rho, V_fl, mu_fl);
            Rc_fus = AeroLevel3.R_cutoff_sub(g.L_fus, g.skin_roughness_k);
            Cf_fus = AeroLevel3.get_Cf_turb(AeroLevel3.Cf_turb(R_fus, M), R_fus, Rc_fus, M);
            FF_fus = AeroLevel3.FF_2(g.L_fus, g.A_max_fus);
            Dq_fus = Cf_fus * FF_fus * 1.0 * g.S_wet_fus;  % Q=1 fuselage

            % Wing component drag (using mean chord as reference length)
            cbar = g.S_ref / g.b;
            R_wing = AeroLevel3.R(cbar, state.rho, V_fl, mu_fl);
            Rc_wing = AeroLevel3.R_cutoff_sub(cbar, g.skin_roughness_k);
            Cf_wing = AeroLevel3.get_Cf_turb(AeroLevel3.Cf_turb(R_wing, M), R_wing, Rc_wing, M);
            FF_wing = AeroLevel3.FF_1(g.xc_wing, g.tc_wing, M, g.Lambda_max_t_deg);
            Dq_wing = Cf_wing * FF_wing * 1.0 * g.S_wet_wing;  % Q=1 wing

            % Tail component drag (simplified: use wing method with tail params)
            Dq_tail = Cf_wing * 1.05 * 1.0 * (g.S_wet_HT + g.S_wet_VT);  % Q=1.05 tail

            % Sum component drags
            CD0 = (Dq_fus + Dq_wing + Dq_tail) / g.S_ref;

            % Induced drag (Oswald efficiency)
            K2 = 1 / (pi * g.e_osw * g.AR);

            % Linear term (from cambered airfoil CL_minD shift)
            CL_minD = g.CL_minD;
            K1 = -2 * K2 * CL_minD;

            polar.CD0 = CD0;
            polar.K1  = K1;
            polar.K2  = K2;
        end

        function CL = CLmax(obj, state) %#ok<INUSD>
            CL = AeroLevel3.CL_max_clean(obj.geom.cl_max_airfoil, obj.geom.Lambda_qc_deg);
        end
    end

    %% Static component-drag helpers (Raymer Ch 12)
    methods (Static)

        function output = CD_uncambered(CD0, CDi)
            output = CD0 + CDi;
        end

        function output = CD_cambered(CD_min, K, CL, CL_minD)
            output = CD_min + K*(CL - CL_minD)^2;
        end

        function output = CL_alpha_2D_sub(M)
            output = 2*pi / sqrt(1 - M^2);
        end

        function output = CL_alpha_2D_sup(M)
            output = 4 / sqrt(M^2 - 1);
        end

        function output = CL_alpha_wing_sub(AR, S_exposed, S_ref, F, Lambda_max_t_deg, beta, eta)
            output = (2*pi*AR) / (2 + sqrt(4 + (AR^2*beta^2/eta^2)*(1 + tand(Lambda_max_t_deg)^2/beta^2))) * (S_exposed/S_ref) * F;
        end

        function output = CL_alpha_wing_sup(beta_mach)
            output = 4 / beta_mach;
        end

        function output = CL_max_clean(cl_max, Lambda_qc_deg)
            output = 0.9 * cl_max * cosd(Lambda_qc_deg);
        end

        function output = leading_edge_sharpness_param(airfoiltype, tc)
            if airfoiltype ~= "NACA"
                error("Only NACA airfoils accepted.")
            end
            if any(airfoiltype == ["NACA 4 digit", "NACA 5 digit"])
                output = 26*tc;
            elseif airfoiltype == "NACA 64 series"
                output = 21.3*tc;
            elseif airfoiltype == "NACA 65 series"
                output = 19.3*tc;
            elseif airfoiltype == "Biconvex"
                output = 11.8*tc;
            else
                error("Unrecognized NACA series.")
            end
        end

        function output = AR_check(AR_in, C1, Lambda_LE_deg)
            AR_comparison = 3 / ((C1+1) * cosd(Lambda_LE_deg));
            if AR_in <= AR_comparison; output = "Low AR";
            else;                     output = "High AR";
            end
        end

        function output = CL_max_clean_highAR(cl_max, CL_max_cl_max, Delta_CL_max)
            output = cl_max*CL_max_cl_max + Delta_CL_max;
        end

        function output = alpha_CL_max_highAR(CL_max, CL_alpha, alpha_L0, Delta_alpha_CL_max)
            output = CL_max/CL_alpha + alpha_L0 + Delta_alpha_CL_max;
        end

        function output = CL_max_clean_lowAR(CL_max_base, Delta_CL_max)
            output = CL_max_base + Delta_CL_max;
        end

        function output = alpha_CL_max_lowAR(alpha_CL_max_base, Delta_alpha_CL_max)
            output = alpha_CL_max_base + Delta_alpha_CL_max;
        end

        function output = Delta_CL_max_flapdown(liftdevicetype, liftdevicename, ~, ~, ~, device_chordlength, wing_chordlength)
            c_c = device_chordlength / wing_chordlength;
            if any(liftdevicetype == ["flap","flaps","Flap","Flaps"])
                switch liftdevicename
                    case {"plain","split"};         output = 0.9;
                    case "slotted";                 output = 1.3;
                    case "fowler";                  output = 1.3*c_c;
                    case "double slotted";          output = 1.6*c_c;
                    case "triple slotted";          output = 1.9*c_c;
                    otherwise; error("Unrecognized flap type: %s", liftdevicename)
                end
            elseif any(liftdevicetype == ["leading-edge device","slats"])
                switch liftdevicename
                    case "fixed slot";              output = 0.2;
                    case "leading-edge flap";       output = 0.3;
                    case "kruger flap";             output = 0.3;
                    case "slat";                    output = 0.4*c_c;
                    otherwise; error("Unrecognized LE device: %s", liftdevicename)
                end
            else
                error("Unrecognized lift device type: %s", liftdevicetype)
            end
        end

        function output = F_fus(d, b)
            output = 1.07*(1 + d/b);
        end

        function output = CL_minD(CL_alpha, alpha_L0_deg)
            output = CL_alpha * (-alpha_L0_deg * pi/180 / 2);
        end

        function output = CL_alpha_wb(CL_alpha_HT, CL_alpha_strakes, delta_eps_dalpha, S_HT, S_ref)
            output = CL_alpha_strakes + CL_alpha_HT*(1 - delta_eps_dalpha)*(S_HT/S_ref);
        end

        function output = CL_alpha_strakes(CL_alpha_w, S_ref, S_strakes)
            output = CL_alpha_w * (S_ref + S_strakes) / S_ref;
        end

        function output = K1_coeff(e_osw, AR, M, Lambda_LE_degrees)
            output.subsonic  = 1/(pi*AR*e_osw);
            output.supersonic = (AR*(M^2-1)*cosd(Lambda_LE_degrees)) / (4*AR*sqrt(M^2-1) - 2);
        end

        function output = K2_coeff(K1_struct, CL_minD_val)
            output.subsonic  = -2 * K1_struct.subsonic * CL_minD_val;
            output.supersonic = 0;
        end

        function Component_Drag = compute_component_drag(Cf, Q, S_wet, FF)
            Component_Drag = Cf * Q * S_wet * FF;
        end

        function CD0_dq = get_component_CD0_from_Dq(component_Dq, S_ref)
            CD0_dq = component_Dq / S_ref;
        end

        function output = compute_CD0_wave(M, Lambda_LE_deg, A_max, l, S_ref)
            Dq = AeroLevel3.Dq_wave(2.2, M, Lambda_LE_deg, A_max, l);
            output = Dq / S_ref;
        end

        function Cf_turb_result = get_Cf_turb(Cf_turb_value, R, R_cutoff, M)
            if R_cutoff < R
                Cf_turb_result = AeroLevel3.Cf_turb(R_cutoff, M);
            else
                Cf_turb_result = Cf_turb_value;
            end
        end

        function [V, mu, rho] = get_V_and_mu(M, h_ft)
            [T, a, ~, rho_SI] = atmosisa(h_ft * 0.3048);
            rho = rho_SI * 0.00194032033;  % kg/m³ → slug/ft³
            a   = a      * 3.2808399;      % m/s → ft/s
            V   = a * M;
            T   = T * 1.8;                 % K → R
            mu  = AeroLevel3.mu(T);
        end

        function output = mu(T)
            T_0  = 518.7;
            mu_0 = 3.62e-7;
            output = mu_0 * (T/T_0)^1.5 * ((T_0+198.72)/(T+198.72));
        end

        function avg_Cf = computeavgcf(R, R_cutoff, Cf_turb_val, Cf_lam_val)
            f_turb = R / R_cutoff;
            f_lam  = 1 - f_turb;
            avg_Cf = f_lam*Cf_lam_val + f_turb*Cf_turb_val;
        end

        function output = f(l, A_max)
            output = l / sqrt((4/pi)*A_max);
        end

        function output = FF_1(x_c, t_c, M, Lambda_m)
            output = (1 + 0.6/x_c*t_c + 100*t_c^4) * (1.34*M^0.18 * cosd(Lambda_m)^0.28);
        end

        function output = FF_2(l, A_max)
            f_val  = AeroLevel3.f(l, A_max);
            output = 0.9 + 5/f_val^1.5 + f_val/400;
        end

        function output = FF_3(l, A_max)
            output = 1 + 0.35/AeroLevel3.f(l, A_max);
        end

        function output = FF_doublewedge(d, l)
            output = 1 + d/l;
        end

        function output = FF_singlewedge(d, l)
            output = 1 + 2*d/l;
        end

        function output = R_cutoff_sub(ref_length, k)
            output = 38.21*(ref_length/k)^1.053;
        end

        function output = R_cutoff_sup(ref_length, Mach, k)
            output = 44.62*(ref_length/k)^1.053 * Mach^1.16;
        end

        function output = R(ref_length, rho, V, mu)
            output = rho*V*ref_length / mu;
        end

        function output = Cf_lam(R_val)
            output = 1.328 / sqrt(R_val);
        end

        function output = Cf_turb(R_val, Mach)
            % Raymer Eq 12.27: exponent 0.65 applies only to compressibility term
            output = 0.455 / (log10(R_val)^2.58 * (1 + 0.144*Mach^2)^0.65);
        end

        function output = Dq_upsweep(u, A_max)
            output = 3.83*u^2.5 * A_max;
        end

        function output = Dq_base_sub(M, A_base)
            output = (0.139 + 0.419*(M-0.161)^2) * A_base;
        end

        function output = Dq_base_sup(M, A_base)
            output = (0.064 + 0.042*(M-3.84)^2) * A_base;
        end

        function output = Dq_windmillingjet(A_engine_front_face)
            output = 0.3 * A_engine_front_face;
        end

        function output = Dq_searshaack(A_max, l)
            output = 9*pi/2 * (A_max/l)^2;
        end

        function output = Dq_wave(E_WD, M, Lambda_LE_deg, A_max, l)
            output = E_WD * (1 - 0.2*(M-1.2)^0.57 * (1 - pi*Lambda_LE_deg^0.77/100)) * AeroLevel3.Dq_searshaack(A_max, l);
        end

        function output = e_straight(AR)
            output = 1.78*(1 - 0.045*AR^0.68) - 0.64;
        end

        function output = e_swept(AR, Lambda_LE_deg)
            output = 4.61*(1 - 0.045*AR^0.68)*cosd(Lambda_LE_deg)^0.15 - 3.1;
        end

        function output = beta_mach(M)
            output = sqrt(1 - M^2);
        end

        function output = eta_mach(cl_alpha, beta)
            output = cl_alpha / (2*pi/beta);
        end

    end

end
