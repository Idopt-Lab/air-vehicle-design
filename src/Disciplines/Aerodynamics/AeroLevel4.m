classdef AeroLevel4 < AerodynamicsBase
    % Level IV aerodynamics: high-fidelity component drag buildup.
    %
    % Inherits from AerodynamicsBase (not from AerodynamicsModelLevel3).
    % Uses the same component buildup approach as Level III but with more
    % precise form factors, interference factors, and wave drag.
    % The constructor requires a rich geometry object with all component
    % dimensions.
    %
    % Note: the original placeholder values (CD=1233, K=234) have been
    % removed.  drag_polar now delegates to AeroLevel3's static methods,
    % matching the same component buildup physics.  A true Level IV
    % improvement would add wave drag and refined per-component form
    % factors; that can be added without changing the interface.

    properties
        geom        % GeometryBase subclass instance (same requirements as AeroLevel3)
        e_osw       % Oswald span efficiency factor (-)
        Cf_fuselage % pre-computed skin friction for fuselage (optional override)
        Cf_mainwings
        Cf_HT
        Cf_VT
        Q_fuselage  % interference factor, fuselage
        Q_wing
        Q_tail
    end

    methods
        function obj = AeroLevel4(geom)
            obj.geom       = geom;
            obj.e_osw      = geom.e_osw;
            obj.Q_fuselage = 1.0;
            obj.Q_wing     = 1.0;
            obj.Q_tail     = 1.05;
        end

        function polar = drag_polar(obj, state)
            % Delegates to AeroLevel3 static methods with geometry from obj.geom.
            g = obj.geom;
            M = state.mach;

            [V_fl, mu_fl, ~] = AeroLevel3.get_V_and_mu(M, state.altitude);

            % Fuselage
            R_fus  = AeroLevel3.R(g.L_fus, state.rho, V_fl, mu_fl);
            Rc_fus = AeroLevel3.R_cutoff_sub(g.L_fus, g.skin_roughness_k);
            Cf_fus = AeroLevel3.get_Cf_turb(AeroLevel3.Cf_turb(R_fus, M), R_fus, Rc_fus, M);
            FF_fus = AeroLevel3.FF_2(g.L_fus, g.A_max_fus);
            Dq_fus = Cf_fus * FF_fus * obj.Q_fuselage * g.S_wet_fus;

            % Wing
            cbar   = g.S_ref / g.b;
            R_w    = AeroLevel3.R(cbar, state.rho, V_fl, mu_fl);
            Rc_w   = AeroLevel3.R_cutoff_sub(cbar, g.skin_roughness_k);
            Cf_w   = AeroLevel3.get_Cf_turb(AeroLevel3.Cf_turb(R_w, M), R_w, Rc_w, M);
            FF_w   = AeroLevel3.FF_1(g.xc_wing, g.tc_wing, M, g.Lambda_max_t_deg);
            Dq_w   = Cf_w * FF_w * obj.Q_wing * g.S_wet_wing;

            % Tail
            Dq_t   = Cf_w * 1.0 * obj.Q_tail * (g.S_wet_HT + g.S_wet_VT);

            % Wave drag (supersonic)
            Dq_wave = 0;
            if M > 1.0 && isfield(g, 'A_max_fus') && isfield(g, 'Lambda_LE_deg')
                Dq_wave = AeroLevel3.Dq_wave(2.2, M, g.Lambda_LE_deg, g.A_max_fus, g.L_fus);
            end

            CD0 = (Dq_fus + Dq_w + Dq_t + Dq_wave) / g.S_ref;
            K2  = 1 / (pi * obj.e_osw * g.AR);
            K1  = -2 * K2 * g.CL_minD;

            polar.CD0 = CD0;
            polar.K1  = K1;
            polar.K2  = K2;
        end

        function CL = CLmax(obj, state) %#ok<INUSD>
            CL = AeroLevel3.CL_max_clean(obj.geom.cl_max_airfoil, obj.geom.Lambda_qc_deg);
        end
    end

    methods (Static)
        % Form factor for wings/tails/pylons
        function output = FF_1(x_c, t_c, M, Lambda_m)
            output = (1 + 0.6/x_c*t_c + 100*t_c^4) * (1.34*M^0.18 * cosd(Lambda_m)^0.28);
        end

        % Form factor for fuselage/smooth canopy
        function output = FF_2(l, A_max)
            f_val  = l / sqrt((4/pi)*A_max);
            output = 0.9 + 5/f_val^1.5 + f_val/400;
        end

        % Form factor for nacelle/external store
        function output = FF_3(l, A_max)
            f_val  = l / sqrt((4/pi)*A_max);
            output = 1 + 0.35/f_val;
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

        function output = Cf_lam(R_val)
            output = 1.328 / sqrt(R_val);
        end

        function output = Cf_turb(R_val, Mach)
            output = 0.455 / ((log10(R_val)^2.58 * (1 + 0.144*Mach^2))^0.65);
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
            output = E_WD*(1-0.2*(M-1.2)^0.57*(1-pi*Lambda_LE_deg^0.77/100)) * AeroLevel4.Dq_searshaack(A_max, l);
        end

        function output = e_straight(AR)
            output = 1.78*(1 - 0.045*AR^0.68) - 0.64;
        end

        function output = e_swept(AR, Lambda_LE_deg)
            output = 4.61*(1 - 0.045*AR^0.68)*cosd(Lambda_LE_deg)^0.15 - 3.1;
        end
    end

end
