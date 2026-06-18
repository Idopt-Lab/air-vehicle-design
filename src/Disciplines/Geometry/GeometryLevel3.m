classdef GeometryLevel3 < GeometryBase
    % Level III geometry: explicit component dimensions; all geometry computed
    % from first-principles planform integration.
    %
    % Aircraft-specific subclasses (e.g., F16GeometryLevel3) set all property
    % values in their constructor.  The generic class constructor accepts a
    % struct with all required fields.
    %
    % Required struct fields for constructor:
    %   g.S_ref, g.S_wet, g.b, g.AR, g.lambda (taper ratio)
    %   g.tc_wing, g.xc_wing (x/c of max-thickness on wing)
    %   g.Lambda_LE_deg, g.Lambda_qc_deg, g.Lambda_max_t_deg
    %   g.L_fus, g.A_max_fus, g.S_wet_fus
    %   g.S_wet_wing, g.S_wet_HT, g.S_wet_VT
    %   g.skin_roughness_k (ft)
    %   g.e_osw, g.CL_minD, g.cl_max_airfoil

    properties
        % Wing planform
        b               % wingspan (ft)
        AR              % aspect ratio
        lambda          % taper ratio
        tc_wing         % wing thickness-to-chord at root
        xc_wing         % x/c location of maximum thickness
        Lambda_LE_deg   % leading-edge sweep (deg)
        Lambda_qc_deg   % quarter-chord sweep (deg)
        Lambda_max_t_deg % sweep at max-thickness line (deg)

        % Component wetted areas (ft²)
        S_wet_wing
        S_wet_fus
        S_wet_HT
        S_wet_VT

        % Fuselage
        L_fus           % fuselage length (ft)
        A_max_fus       % maximum cross-section area (ft²)

        % Aerodynamic parameters
        e_osw           % Oswald span efficiency
        CL_minD         % CL at minimum drag (from camber)
        cl_max_airfoil  % 2D max lift coefficient

        % Skin roughness
        skin_roughness_k  % surface roughness height (ft)
    end

    methods
        function obj = GeometryLevel3(g)
            % g is a struct with all required fields (see class header).
            obj.S_ref     = g.S_ref;
            obj.S_wet     = g.S_wet;
            obj.b         = g.b;
            obj.AR        = g.AR;
            obj.lambda    = g.lambda;
            obj.tc_wing   = g.tc_wing;
            obj.xc_wing   = g.xc_wing;
            obj.Lambda_LE_deg    = g.Lambda_LE_deg;
            obj.Lambda_qc_deg    = g.Lambda_qc_deg;
            obj.Lambda_max_t_deg = g.Lambda_max_t_deg;
            obj.S_wet_wing = g.S_wet_wing;
            obj.S_wet_fus  = g.S_wet_fus;
            obj.S_wet_HT   = g.S_wet_HT;
            obj.S_wet_VT   = g.S_wet_VT;
            obj.L_fus      = g.L_fus;
            obj.A_max_fus  = g.A_max_fus;
            obj.e_osw      = g.e_osw;
            obj.CL_minD    = g.CL_minD;
            obj.cl_max_airfoil = g.cl_max_airfoil;
            obj.skin_roughness_k = g.skin_roughness_k;
        end
    end

    methods (Static)

        function b = compute_b(AR, S_ref)
            b = sqrt(AR*S_ref);
        end

        function c_root = compute_c_root(S_ref, b, lambda)
            c_root = 2*S_ref / (b*(1+lambda));
        end

        function c_tip = compute_c_tip(lambda, c_root)
            c_tip = lambda * c_root;
        end

        function cbar = compute_MAC(c_root, lambda)
            % Mean aerodynamic chord
            cbar = (2/3)*c_root*(1 + lambda + lambda^2)/(1+lambda);
        end

        function S_control = size_control_surface_raymer(deltaCL_req, S_ref, K_f, dcl_ddelta_airfoil, delta_max_deg, Lambda_HL_deg)
            delta_max_rad = deg2rad(delta_max_deg);
            S_control = (deltaCL_req*S_ref) / (0.9*K_f*dcl_ddelta_airfoil*delta_max_rad*cosd(Lambda_HL_deg));
        end

        function L_hinge = compute_hinge_length_from_stations(y_in, y_out, Lambda_h_deg)
            b_control = abs(y_out - y_in);
            L_hinge   = b_control / cosd(Lambda_h_deg);
        end

        function S_exposed = get_S_exposed(tip_length, exposed_rc, exposed_halfspan)
            S_exposed = exposed_halfspan*(exposed_rc + tip_length);
        end

        function S_wet_w = get_S_wet_wing(S_exposed, tc)
            S_wet_w = S_exposed*(1.977 + 0.52*tc);
        end

        function qc_sweep = get_sweep_qc(b, LE_sweep_deg, root_chord, tip_chord)
            qc_sweep = atand(tand(LE_sweep_deg) - (root_chord - tip_chord)/(2*b));
        end

        function [S_HT, S_VT] = Tail_Sizing(c_VT, c_HT, b_W, Sref_w, L_fus, Cbar_W)
            % Raymer, Eq 6.28-6.29 (tail at 0.8*L_fus)
            L_VT = L_fus * 0.8;
            L_HT = L_fus * 0.8;
            S_VT = c_VT * b_W   * Sref_w / L_VT;
            S_HT = c_HT * Cbar_W * Sref_w / L_HT;
        end

    end

end
