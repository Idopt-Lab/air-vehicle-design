classdef F16AeroL3 < AeroModelL3
%F16AEROL3  F-16A Block 10 Level-3 aerodynamics student class.
%
%   Inherits from AeroModelL3 (abstract enforcer).  Every abstract method is
%   satisfied by a single delegation line to AeroL3 statics — no equations
%   are duplicated here.
%
%   Concrete utility methods (compute_CD, compute_CL, compute_CD0, get_CDi) are
%   inherited from AerodynamicsBase.
%
%   Component order: [1] wing, [2] HT, [3] VT, [4] fuselage, [5] duct
%
%   Component geometry sources:
%     Wing : MAC ≈ 12.0 ft, tc=0.04, x/c_max=0.40 [NACA 64A series]
%            Lambda_m50 ≈ 35 deg, Q=1.0  [T.O. 1F-16A-1; Raymer Table 12.6]
%     HT   : MAC ≈ 5.8 ft, tc=0.047, x/c_max=0.35, Lambda_m50≈35 deg, Q=1.05
%     VT   : MAC ≈ 6.5 ft, tc=0.042, x/c_max=0.35, Lambda_m50≈42 deg, Q=1.05
%     Fus  : L=47.5 ft, D=5.0 ft, body (FF via Raymer Eq 12.31), Q=1.0
%     Duct : L=14.0 ft, D_avg=3.15 ft, body (cylinder approx), Q=1.0
%
%   Surface roughness: smooth paint k = 2.08e-5 ft  [Raymer 6th ed. Table 12.2]
%   Laminar fraction: 5% on all surfaces (operational fighter in service)
%   Misc drag: 1x cannon port + 1x arresting hook (USAF)  [Raymer 6th ed. Table 12.7]
%
%   Expected CD0 at M=0.5, sea level (for validation):
%     Total should be within ±40% of Raymer Fig 12.32 value of 0.020
%     (see TestAeroL3.testCD0PhysicalRangeSL_M05).

    properties
        % --- Aircraft-specific inputs
        S_ref         = 300        % ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        AR            = 3.0        % —     [T.O. 1F-16A-1: b=30ft, S=300ft^2]
        Lambda_LE_deg = 40         % deg   [T.O. 1F-16A-1, Fig. 1-2]
        Lambda_c4_deg = 37         % deg   [derived from F-16 planform geometry]
        CL_minD       = 0.0        % —

        % --- Component arrays (5 components: wing, HT, VT, fuselage, duct)
        %             [  wing    HT      VT      fus     duct  ]
        l_ref_comp  = [12.0,   5.8,    6.5,   47.5,   14.0  ]  % ft  — MAC or length
        D_comp      = [ 0,     0,      0,      5.0,    3.15  ]  % ft  — 0 for surfaces
        S_wet_comp  = [397,   130,   111,    644,    139   ]  % ft^2 [hand-copied estimate, not live-read from F16GeomL2 -- see docs/geometry_parameter_usage.md]
        tc_comp     = [ 0.04,  0.047,  0.042,  0,      0     ]  % —
        x_c_max_comp= [ 0.40,  0.35,   0.35,   0,      0     ]  % —
        Lambda_m_comp=[35,    35,     42,     0,      0     ]  % deg
        Q_comp      = [ 1.0,   1.05,   1.05,   1.0,    1.0   ]  % —   [Raymer Table 12.6]
        f_lam_comp  = [ 0.05,  0.05,   0.05,   0,      0     ]  % fraction laminar flow
        is_body_comp= [false, false,  false,  true,   true  ]  % true → FF_body

        % --- Miscellaneous drag
        % CD0_misc = (Dq_gun_port + Dq_hook_USAF)/S_ref, set in the
        % constructor [Raymer 6th ed. Table 12.7] -- single cannon port +
        % USAF arresting hook, the two Table 12.7 items applicable to a
        % clean F-16.
        %
        % Audited against temp_Casey's F16AeroLevel3.compute_CD0_misc
        % (upsweep + windmilling-jet) and neither of ITS terms was ported:
        %   Upsweep (Raymer Eq. 12.36, Dq=3.83*u^2.5*A_max): temp_Casey uses
        %     u=0.01 rad in this F-16-specific class but u=0 (i.e. no
        %     contribution) in the generic Drag_Polar_III/IV toolboxes --
        %     neither value is cited to an F-16 drawing/source, so it is not
        %     reproducible here without fabricating a number.
        %   Windmilling-jet drag (Raymer Eq. 12.40, Dq=0.3*A_engine_face):
        %     represents an inoperative/windmilling engine, i.e. an
        %     engine-out contingency drag increment -- not applicable to the
        %     baseline (engine running) CD0 used for the mission polar.
        % TODO: add upsweep once a cited F-16 aft-fuselage upsweep angle is
        % available (T.O. 1F-16A-1 drawing or equivalent primary source).
        CD0_misc    = 0.0010      % = (0.20+0.10)/300, overwritten in constructor
        CD0_LandP   = 0.0010       % leakage & protuberance allowance [Raymer §12.5]

        % --- Component-level buildup results (populated by get_CD0_buildup)
        R_components = []
        R_cutoff     = []
        FF           = []

        % --- Computed aerodynamic quantities (populate by calling methods)
        e_osw_clean  = 0
        K_LD         = 0
        K            = 0
        K1           = 0
        K2           = 0
        Cf           = 0
        CL_max_clean = 0
        CD0          = 0
        CDi          = 0
        CL           = 0
        CD           = 0
        F            = 0
    end

    properties (Constant)
        % Tabulated from Raymer figures/tables for the F-16A NACA 64A204 wing.
        airfoiltype     = "cambered"
        C1              = 0.5       % Raymer 6th ed. Fig. 12.12, λ = 0.23
        C2              = 0.65      % Raymer 6th ed. Fig. 12.12, λ = 0.23
        CL_max_base     = 0.91      % Raymer 6th ed. Fig. 12.13
        sharpness_param = 0.7720    % Raymer 6th ed. Table 12.1
        CL_max_cl_max   = 1.1       % Raymer 6th ed. Fig. 12.9, Λ_LE = 40°
        cl_max          = 1.0       % NTRS-19870017427 p. 14 (NACA 64A204)
        alpha_L0        = -1.01     % deg — zero-lift AOA [NACA 64A204 data]
        k               = 2.08e-5   % ft  — smooth paint [Raymer 6th ed. Table 12.2]
    end

    % Landing-gear drag items (not yet wired into get_CD0_buildup -- gear is
    % retracted for the clean cruise/mission polar this class targets).
     % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th ed,
     % Table 12.6.
     properties (Constant)
          Dq_wheels = 0.18; % Regular wheel and tire
          Dq_strut_highRE = 0.30; % Round strut
          Dq_strut_lowRE = 1.17; % Round strut
     end

    % Miscellaneous drag items included in CD0_misc (see constructor).
     % Source: Raymer, "Aircraft Design: A Conceptual Approach", 6th ed,
     % Table 12.7.
     properties (Constant)
          Dq_gun_port  = 0.20; % ft^2 -- single cannon port (F-16: 1x M61A1 20mm)
          Dq_hook_USAF = 0.10; % ft^2 -- arresting hook, USAF
     end

    % Custom properties
     properties
          DragResults % Data storage property
          CD_wave

          Delta_CD0_TO_flap
          Delta_CD0_TO_slat
          Delta_CD0_L_flap
          Delta_CD0_L_slat

          Delta_CL_max_TO_flap
          Delta_CL_max_TO_slat
          Delta_CL_max_L_flap
          Delta_CL_max_L_slat
     end

    methods

        function obj = F16AeroL3()
            obj.S_ref          = 300;
            obj.AR             = 3.0;
            obj.Lambda_LE_deg  = 40;
            obj.Lambda_c4_deg  = 37;
            obj.CL_minD        = 0.0;
            obj.l_ref_comp     = [12.0,  5.8,   6.5,  47.5,  14.0];
            obj.D_comp         = [ 0,    0,     0,     5.0,   3.15];
            obj.S_wet_comp     = [397,   130,   111,   644,   139 ];
            obj.tc_comp        = [ 0.04, 0.047, 0.042, 0,     0   ];
            obj.x_c_max_comp   = [ 0.40, 0.35,  0.35,  0,     0   ];
            obj.Lambda_m_comp  = [35,   35,    42,     0,     0   ];
            obj.Q_comp         = [ 1.0,  1.05,  1.05,  1.0,   1.0 ];
            obj.f_lam_comp     = [ 0.05, 0.05,  0.05,  0,     0   ];
            obj.is_body_comp   = [false, false, false, true,  true];
            obj.CD0_misc       = (obj.Dq_gun_port + obj.Dq_hook_USAF) / obj.S_ref;  % Raymer Table 12.7
            obj.CD0_LandP      = 0.0010;
        end

        % TODO (7/13/2026): Must add functions and equations that are unique to the F-16's case.
        % Examples: supersonic wave drag, CL_alpha accounting for the effects of the strakes,
        % Delta_CD0 from landing gear, high-lift devices, Delta_CL_max, Delta_CDi.

        function polar = drag_polar(obj, state)
            polar = AeroL3.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(~, ~)
            % TODO (7/13/2026): This should use a L3 function that should work for a wing with or without high-lift devices.
        %GET_CLMAX  Historical fallback — override with a high-lift model when needed.
            CLmax = AeroL1.lookup_CLmax('jet_fighter');
        end

        function Re = compute_Re(~, state, l_ref)
            Re = AeroL3.compute_Re(state, l_ref);
        end

        function cf = compute_Cf_lam(~, Re)
            cf = AeroL3.compute_Cf_lam(Re);
        end

        function cf = compute_Cf_turb(~, Re, M)
            cf = AeroL3.compute_Cf_turb(Re, M);
        end

        function ff = compute_FF_surface(~, tc, x_c_max, Lambda_m50_deg, M)
            ff = AeroL3.compute_FF_surface(tc, x_c_max, Lambda_m50_deg, M);
        end

        function ff = compute_FF_fus(~, L_body, D_body)
            ff = AeroL3.compute_FF_fus(L_body, D_body);
        end

        function val = get_CD0_buildup(obj, state)
            val = AeroL3.get_CD0_buildup(obj, state);
        end

        function val = get_K1(obj, M)
            val = AeroL3.get_K1(obj, M);
        end

        function val = get_K2(obj, K1_sub, M)
            val = AeroL3.get_K2(obj, K1_sub, M);
        end

        function val = compute_K(~, e_osw, AR)
            val = AeroL3.compute_K(e_osw, AR);
        end

        function val = compute_CL_minD(~, airfoil_type, CL_min, ~)
            val = AeroL3.compute_CL_minD(airfoil_type, CL_min);
        end

        function [Cf_lam_result, Cf_turb_result] = compute_Cf(~, R, M)
            [Cf_lam_result, Cf_turb_result] = AeroL3.compute_Cf(R, M);
        end

        function val = get_R_cutoff(obj, ref_length, M)
            val = AeroL3.get_R_cutoff(obj, ref_length, M);
        end

        function val = get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max)
            val = AeroL3.get_CL_max_values(obj, AR, Lambda_LE_deg, CL_max_base, Delta_CL_max, cl_max, CL_max_cl_max);
        end

        function val = get_CL_alpha(obj, M)
        %GET_CL_ALPHA  Uses Lambda_c4_deg (quarter-chord sweep) per Raymer Eq. 12.6.
            val = AeroL2.CL_alpha(obj.AR, obj.Lambda_c4_deg, M);
        end

        function val = compute_F(~, d, b)
            val = AeroL3.compute_F(d, b);
        end

        function val = compute_Delta_CL_max_values(~, Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg)
            val = AeroL3.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, S_ref, Lambda_HL_deg);
        end

        function val = lookup_Delta_cl_max_values(~, liftdevice, config, cp_c)
            val = AeroL3.lookup_Delta_cl_max_values(liftdevice, config, cp_c);
        end

    end
end
