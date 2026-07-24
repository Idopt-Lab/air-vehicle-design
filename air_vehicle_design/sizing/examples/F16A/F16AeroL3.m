classdef F16AeroL3 < AeroModelL3
%F16AEROL3  F-16A Block 10 Level-3 aerodynamics student class.
%
%   Inherits from AeroModelL3 (abstract enforcer).  Most abstract methods are
%   satisfied by a single delegation line to AeroL3 statics -- the exceptions
%   are drag_polar/get_CD0_buildup, which add this class's own supersonic
%   wave-drag term (compute_CD0_wave, Raymer 6th ed. Eqs. 12.44-12.45) on top
%   of the generic AeroL3 buildup, since wave drag is unique to supersonic
%   designs and doesn't belong in the shared toolbox used by every
%   fidelity-3 aircraft.
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
        taper         = 0.2275     % —     wing taper ratio [T.O. 1F-16A-1; F16Baseline b.geom.taper]
        CL_minD       = 0.0        % —

        % --- Component arrays (5 components: wing, HT, VT, fuselage, duct)
        % TODO: canopy is NOT modeled as a 6th component. No citable numeric
        % canopy geometry (length, diameter, S_wet) exists anywhere in this
        % repo (temp_Casey, VnV/BrandtF16A, or
        % temp_AI/docs/disciplines/reference_extracts/) -- see
        % F16AeroL3_wave_drag_fix.md Sec. 3. It is also UNRESOLVED whether
        % the fuselage S_wet_comp(4)=644 figure below already implicitly
        % includes canopy wetted area: Brandt's own fuselage frame table
        % (BrandtGeometry.m / GroundTruth/f16a_geometry.json) shows a local
        % height bulge over x≈12-20 ft (the plausible cockpit/canopy
        % station range) baked directly into the frame data it integrates
        % S_wet from, suggestive (not conclusive) that canopy area is
        % already folded into 644. A future canopy addition must resolve
        % this double-counting question with a primary source (e.g. T.O.
        % 1F-16A-1 canopy drawing) before adding a 6th term, not just
        % append a naive additional S_wet value.
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

        % --- Whole-aircraft wave-drag geometry (Raymer Eq. 12.44 Sears-Haack
        % term needs a single WHOLE-VEHICLE Amax/length pair, not a
        % per-component value -- distinct from l_ref_comp(4)/D_comp(4) above,
        % which stay fuselage-component-only for the skin-friction Re/FF_body
        % calc). Genuine independently-sourced spec/ground-truth constants,
        % not derived from this class's other properties -- see
        % F16AeroL3_wave_drag_fix.md Sec. 2.
        Amax_ft2      = 25.110556  % ft^2  whole-aircraft max cross-section, net of
                                    %       engine flow-through area [Brandt Geom!B20/H47,
                                    %       25.1106 ft^2 live; BrandtGeometry.m computeAmax()
                                    %       independently reproduces 25.110556, +0.002%]
        L_aircraft_ft = 48.304     % ft    overall aircraft length (nose to aftmost of
                                    %       fuselage/nozzle/VT-TE) [Brandt Geom!B21,
                                    %       48.3039 ft live; BrandtGeometry.m
                                    %       aircraft_length_ft reproduces 48.304, 0.000%]

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
        %
        % WHY SUBSONIC CD0 READS ~10-16% LOW VS. BRANDT (investigated
        % 2026-07-23, remaining_constraints_scrape.md Sec 5 -- not a bug,
        % logged here so it isn't re-investigated as a mystery later):
        % component-by-component check at Cruise (36 kft, M=0.87) and Combat
        % Turn 1 (20 kft, M=0.87) confirms every buildup formula matches its
        % cited Raymer 6th ed. equation exactly (12.25-12.31) and the
        % roughness-limited Re cutoff (Eq. 12.28) never binds at either
        % point (actual Re always well below Re_cutoff for all 5
        % components) -- no clamping or formula bug. Two real, expected
        % effects instead: (1) this class's blended skin-friction*FF*Q
        % averages ~0.0026-0.0028 across the 5 components, genuinely below
        % the flat Cfe=0.0035 jet-fighter lookup (AeroL1.lookup_Cf,
        % Raymer Table 12.3) F16AeroL1/L2 use -- an idealized clean
        % component buildup with only 2 of Raymer Table 12.7's many
        % possible miscellaneous-drag items (gun port + hook, see above)
        % is expected to read below an empirically-calibrated whole-
        % aircraft Cfe unless a fuller miscellaneous-drag catalog is added,
        % which no cited F-16 source currently supports beyond what's
        % listed above; (2) this buildup is Reynolds-number sensitive
        % (correctly, per Eq. 12.27) and predicts a LOWER CD0 at the
        % higher-Re, lower-altitude Combat Turn 1 point (0.01434 at 20 kft)
        % than at Cruise (0.01536 at 36 kft) -- but Brandt's own
        % F16Baseline.m uses the IDENTICAL CD0=0.01700 for both
        % b.constraints.cruise and b.constraints.combat_sub despite the
        % altitude difference, so part of the apparent "error" is this
        % class correctly modeling a Reynolds effect Brandt's simpler
        % tabulated value does not vary with altitude. Not fixing further:
        % per PLAN.md, fabricating additional Table 12.7 items or
        % Reynolds-independent recalibration without a primary source would
        % be hardcoding a calibrated result, not implementing a cited
        % equation.
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
        % Empirical wave-drag efficiency factor, Raymer 6th ed. Eq. 12.45 --
        % E_WD=1 is a perfectly area-ruled (Sears-Haack) body, higher values
        % penalize a real fuselage's departure from that ideal. F-16 value
        % of 2.2 cross-checked against two independent sources: Brandt's own
        % F-16 model (temp_AI/docs/disciplines/01_aerodynamics.md, Sec. 5,
        % "Ewd = 2.2 for the F-16, from f16a_geometry.json aero.Ewd") and
        % temp_Casey's F16-specific class (same constant, same value) --
        % only the value is cross-checked here, not the surrounding code.
        E_WD            = 2.2
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
          Delta_CD0_TO_gear
          Delta_CD0_L_flap
          Delta_CD0_L_slat
          Delta_CD0_L_gear

          Delta_CL_max_TO_flap
          Delta_CL_max_TO_slat
          Delta_CL_max_L_flap
          Delta_CL_max_L_slat

          Delta_CDi_TO_flap  % slat contribution = 0, see Delta_CDi_slat note below
          Delta_CDi_L_flap

          Delta_e_osw_TO     % tabulated -- Roskam Table 3.6 (no closed-form
          Delta_e_osw_L      % flapped-wing Oswald-efficiency formula in Raymer Ch. 12)
     end

     % --- Trailing-edge flap (flaperon) geometry -- estimates, F-16
     % flap-panel dimensions not in Brandt workbook / F16Baseline.
     % TODO: verify against T.O. 1F-16A-1 general-arrangement drawing.
     properties (Constant)
          hld_TE            = "plain"    % F-16 flaperon type [legacy F16AeroLevel2/L3 constant]
          c_flap_over_c     = 0.25       % —     flap chord ratio c'/c, estimated
          eta_flap_in       = 0.10       % —     flap inboard span station (frac. semispan), estimated
          eta_flap_out      = 0.90       % —     flap outboard span station (frac. semispan), estimated
          % F-16 flaperons are a small-authority camber-changing device (max
          % ~20 deg down), NOT a dedicated high-lift Fowler/slotted-flap
          % system -- Raymer 6th ed. Sec.12.6.5's stated "typical" 20-40 deg
          % TO / 60-70 deg landing ranges assume the latter and are far too
          % aggressive here (verified: using those midpoints overshoots
          % Brandt's TO/landing CD0 by 80-210%). TODO: verify against T.O.
          % 1F-16A-1 flaperon deflection schedule.
          delta_flap_TO_deg = 15         % deg
          delta_flap_L_deg  = 20         % deg
          k_f_flap          = 0.28       % —     Raymer 6th ed. Eq. 12.62; F-16 flaperon treated as partial-span
     end

     % --- Leading-edge slat (maneuvering flap) geometry -- chord ratio is
     % a flagged estimate; span is full-span, a well-established public
     % F-16 fact (unlike the TE flaperon span). Hinge line = Lambda_LE_deg
     % (40 deg), which is an exact T.O.-cited value, not an estimate.
     properties (Constant)
          hld_LE            = "slat"     % F-16 leading-edge flap, modeled as a slat-type device [Table 12.2]
          c_slat_over_c     = 0.15       % —     LE device chord ratio c'/c, estimated (TODO: verify)
          eta_slat_in       = 0.0        % —     full-span LE flap
          eta_slat_out      = 0.98       % —     full-span LE flap (minus root fillet)
          % F-16's LE flap is scheduled automatically by AOA/Mach via the
          % flight control computer (T.O. 1F-16A-1), not a discrete pilot
          % detent like the TEF -- so unlike delta_flap_TO/L_deg above, TO
          % and landing are modeled with the SAME deflection: both are
          % low-speed/high-AOA regimes the LEF schedule treats alike.
          % Magnitude (~17 deg) is a flagged estimate, chosen close to the
          % LEF's publicly documented ~20-25 deg max deflection and
          % verified to bring both TO/landing CD0 within ~5-7% of Brandt
          % (vs. -34%/-21% with slat CD0=0). TODO: verify against T.O.
          % 1F-16A-1 LEF deflection schedule.
          F_slat            = 0.0144     % —     Raymer Eq.12.61 "F_flap" analog, un-slotted (plain) value:
                                          %       F-16 LEF is a hinged flap with no slot/gap, same construction
                                          %       class as the TE flaperon's "plain" F_flap.
          delta_slat_TO_deg = 17         % deg
          delta_slat_L_deg  = 17         % deg
          k_slat            = 0.14       % —     Raymer Eq.12.62 "k_f" analog, full-span value (eta=[0,0.98]),
                                          %       vs. the TE flaperon's 0.28 partial-span value.
     end

     % --- Landing-gear component-buildup inputs. F-16 tricycle gear: 1
     % nosewheel + 2 mainwheels, 3 struts total (standard configuration).
     % strut_ref_length is a flagged estimate (TODO: verify against T.O.
     % 1F-16A-1 gear drawing).
     properties (Constant)
          strut_ref_length = 0.3    % ft -- estimated strut diameter
          n_nosewheel      = 1
          n_mainwheel      = 2
          n_gear_legs      = 3
     end

    methods

        function obj = F16AeroL3()
            obj.S_ref          = 300;
            obj.AR             = 3.0;
            obj.Lambda_LE_deg  = 40;
            obj.Lambda_c4_deg  = 37;
            obj.taper          = 0.2275;
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
            obj.Amax_ft2       = 25.110556;
            obj.L_aircraft_ft  = 48.304;
            obj.CD0_misc       = (obj.Dq_gun_port + obj.Dq_hook_USAF) / obj.S_ref;  % Raymer Table 12.7
            obj.CD0_LandP      = 0.0010;
        end

        % TODO (7/13/2026): Must add functions and equations that are unique to the F-16's case.
        % Remaining example: CL_alpha accounting for the effects of the strakes.
        % (Supersonic wave drag, landing-gear/high-lift-device Delta_CD0/Delta_CL_max/Delta_CDi
        % are implemented below -- see compute_CD0_wave and the HLD/gear methods further down.)

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Raymer component buildup (AeroL3) + F-16 supersonic
        %   wave drag (see get_CD0_buildup override below).
            M      = state.mach;
            cd0    = obj.get_CD0_buildup(state);
            e      = AeroL3.get_e_osw(obj);
            k1_sub = AeroL1.K1_subsonic(e, obj.AR);
            k2     = AeroL3.get_K2(obj, k1_sub, M);
            if M < 1
                k1 = k1_sub;
            else
                k1 = AeroL1.K1_supersonic(M, obj.AR, obj.Lambda_LE_deg);
            end
            polar = struct('CD0', cd0, 'K1', k1, 'K2', k2);
        end

        function CLmax = get_CLmax(~, ~)
            % TODO (7/13/2026): This should use a L3 function that should work for a wing with or without high-lift devices.
        %GET_CLMAX  Historical fallback — override with a high-lift model when needed.
            CLmax = AeroL1.lookup_CLmax('jet_fighter');
        end

        function e = get_e_osw(obj)
            e = AeroL3.get_e_osw(obj);
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
        %GET_CD0_BUILDUP  Generic Raymer component buildup (AeroL3, shared
        %   by every fidelity-3 aircraft) plus the F-16's own supersonic
        %   wave-drag-due-to-volume term (Raymer 6th ed. Eqs. 12.44-12.45),
        %   added only for M >= 1.2 -- Eq. 12.45's own domain, since its
        %   (M-1.2)^0.57 factor is undefined below that Mach. Wave drag is
        %   not generic (a subsonic-only airframe would never need it), so
        %   it lives here in the F-16 example rather than in the shared
        %   AeroL3 toolbox. Raymer's transonic fairing between the
        %   subsonic buildup and this supersonic term (1.0 < M < 1.2) is
        %   not implemented -- CD0 is continuous with the pre-wave-drag
        %   buildup across that gap.
            val = AeroL3.get_CD0_buildup(obj, state);
            if state.mach >= 1.2
                val = val + obj.compute_CD0_wave(state);
            end
        end

        function val = compute_CD0_wave(obj, state)
        %COMPUTE_CD0_WAVE  Supersonic wave drag due to volume distribution.
        %   Raymer 6th ed. Eq. 12.44 (Sears-Haack) + Eq. 12.45 (E_WD/sweep/
        %   Mach correction), valid M >= 1.2:
        %     (D/q)_SH   = (9*pi/2) * (Amax/l)^2                                    [12.44]
        %     (D/q)_wave = E_WD*[1 - 0.386*(M-1.2)^0.57*(1-(pi*Lambda_LE_deg^0.77)/100)]
        %                  * (D/q)_SH                                               [12.45]
        %     CD0_wave   = (D/q)_wave / S_ref
        %   Amax/l are WHOLE-AIRCRAFT quantities [Brandt Geom!B20/H47, B21 --
        %   see F16AeroL3_wave_drag_fix.md], distinct from
        %   l_ref_comp(4)/D_comp(4) (fuselage-component-only values used
        %   elsewhere in this class for the skin-friction Re/FF_body calc --
        %   do not conflate the two length scales).
            M = state.mach;
            Dq_SH = (9*pi/2) * (obj.Amax_ft2 / obj.L_aircraft_ft)^2;
            val = obj.E_WD ...
                * (1 - 0.386*(M-1.2)^0.57*(1 - (pi*obj.Lambda_LE_deg^0.77)/100)) ...
                * Dq_SH / obj.S_ref;
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

        % ================================================================ %
        % High-lift-device / gear deltas (L3: trailing-edge flap AND
        % leading-edge slat, both from real geometry; gear from the
        % existing Reynolds-based component-drag buildup).
        % ================================================================ %

        function val = compute_S_flapped_ratio(~, eta_out, eta_in, lambda_taper)
        %COMPUTE_S_FLAPPED_RATIO  S_flapped/S_ref (or S_slatted/S_ref) for a
        %   device spanning [eta_in, eta_out] of the semispan on a
        %   straight-tapered wing.  Roskam, Airplane Design Part II, Eq. 7.10.
            val = (eta_out - eta_in) * (2 - (1 - lambda_taper) * (eta_in + eta_out)) / (1 + lambda_taper);
        end

        function val = Delta_CD0_flap(obj, delta_flap_deg)
        %DELTA_CD0_FLAP  Raymer 6th ed. Eq. 12.61 (Sec. 12.6.5, "Flap Drag").
        %   F_flap = 0.0144 (plain) / 0.0074 (slotted); F-16 flaperon = plain.
        %   Eq. 12.61 is for trailing-edge flap types only -- see
        %   Delta_CD0_slat below for the leading-edge device.
            F_flap = 0.0144;
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            val = F_flap * obj.c_flap_over_c * S_flapped_ratio * (delta_flap_deg - 10);
        end

        function val = Delta_CDi_flap(obj, Delta_CL_flap)
        %DELTA_CDI_FLAP  Raymer 6th ed. Eq. 12.62.  Lambda is the WING
        %   quarter-chord sweep (not the flap hinge line).  TE-flap-specific
        %   -- see Delta_CDi_slat below.
            val = obj.k_f_flap * Delta_CL_flap^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CD0_slat(obj, delta_slat_deg)
        %DELTA_CD0_SLAT  Raymer 6th ed. Eq. 12.61 form, adapted for the F-16's
        %   leading-edge device: F_flap->F_slat, delta_flap->delta_slat,
        %   Cf/C->c_slat_over_c. Eq. 12.61 itself is stated for
        %   trailing-edge flap types only (Fig. 12.18) with no LE-device
        %   analog given in the text -- this reuses the same functional
        %   form with the LE device's own geometry/deflection, not a
        %   separately-cited LE formula.
            S_slatted_ratio = obj.compute_S_flapped_ratio(obj.eta_slat_out, obj.eta_slat_in, obj.taper);
            val = obj.F_slat * obj.c_slat_over_c * S_slatted_ratio * (delta_slat_deg - 10);
        end

        function val = Delta_CDi_slat(obj, Delta_CL_slat)
        %DELTA_CDI_SLAT  Raymer 6th ed. Eq. 12.62 form, adapted for the LE
        %   device (k_f->k_slat, full-span coefficient since eta=[0,0.98]
        %   vs. the flaperon's partial span). Same caveat as Delta_CD0_slat:
        %   no LE-device analog is given in the text for Eq. 12.62 either.
            val = obj.k_slat * Delta_CL_slat^2 * cosd(obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_flap(obj, config)
        %DELTA_CLMAX_FLAP  Raymer 6th ed. Table 12.2 + Eq. 12.21 (via the
        %   AeroL3 toolbox, already delegated by lookup_Delta_cl_max_values /
        %   compute_Delta_CL_max_values above).  config: 'TO' or 'L'.
            S_flapped_ratio = obj.compute_S_flapped_ratio(obj.eta_flap_out, obj.eta_flap_in, obj.taper);
            S_flapped       = S_flapped_ratio * obj.S_ref;
            Delta_cl_max    = obj.lookup_Delta_cl_max_values(obj.hld_TE, config, obj.c_flap_over_c);
            val = obj.compute_Delta_CL_max_values(Delta_cl_max, S_flapped, obj.S_ref, obj.Lambda_c4_deg);
        end

        function val = Delta_CLmax_slat(obj, config)
        %DELTA_CLMAX_SLAT  Raymer 6th ed. Table 12.2 + Eq. 12.21, using the
        %   LE device's own span (full-span) and hinge line (=Lambda_LE_deg,
        %   an exact T.O.-cited value).  config: 'TO' or 'L'.
            S_slatted_ratio = obj.compute_S_flapped_ratio(obj.eta_slat_out, obj.eta_slat_in, obj.taper);
            S_slatted       = S_slatted_ratio * obj.S_ref;
            Delta_cl_max    = obj.lookup_Delta_cl_max_values(obj.hld_LE, config, obj.c_slat_over_c);
            val = obj.compute_Delta_CL_max_values(Delta_cl_max, S_slatted, obj.S_ref, obj.Lambda_LE_deg);
        end

        function val = compute_Delta_CD0_geardown(obj, state)
        %COMPUTE_DELTA_CD0_GEARDOWN  Landing-gear parasite-drag increment,
        %   via the existing component-buildup Reynolds machinery
        %   (compute_Re) and Dq_wheels/Dq_strut_highRE/Dq_strut_lowRE
        %   [Raymer 6th ed. Table 12.6, already declared Constant on this
        %   class].  F-16 tricycle gear: 1 nosewheel + 2 mainwheels, 3
        %   struts total.
            Re = obj.compute_Re(state, obj.strut_ref_length);
            if Re > 3.0e5
                CD0_strut = obj.Dq_strut_highRE / obj.S_ref;
            else
                CD0_strut = obj.Dq_strut_lowRE / obj.S_ref;
            end
            CD0_wheels = obj.Dq_wheels / obj.S_ref;
            val = CD0_wheels * (obj.n_nosewheel + obj.n_mainwheel) + CD0_strut * obj.n_gear_legs;
        end

        function val = get_Delta_e_osw_TO(obj)
        %GET_DELTA_E_OSW_TO  Roskam Table 3.6: e(TO flaps) - e(clean).
            val = obj.roskam_e_osw('takeoff_flaps') - obj.roskam_e_osw('clean');
        end

        function val = get_Delta_e_osw_L(obj)
        %GET_DELTA_E_OSW_L  Roskam Table 3.6: e(landing flaps) - e(clean).
            val = obj.roskam_e_osw('landing_flaps') - obj.roskam_e_osw('clean');
        end

        function val = get_Delta_CD0_TO(obj, state)
        %GET_DELTA_CD0_TO  Flap (Eq. 12.61) + slat (Eq. 12.61 form) + gear (component buildup).
            val = obj.Delta_CD0_flap(obj.delta_flap_TO_deg) + obj.Delta_CD0_slat(obj.delta_slat_TO_deg) ...
                + obj.compute_Delta_CD0_geardown(state);
        end

        function val = get_Delta_CD0_L(obj, state)
        %GET_DELTA_CD0_L  Flap (Eq. 12.61) + slat (Eq. 12.61 form) + gear (component buildup).
            val = obj.Delta_CD0_flap(obj.delta_flap_L_deg) + obj.Delta_CD0_slat(obj.delta_slat_L_deg) ...
                + obj.compute_Delta_CD0_geardown(state);
        end

        function val = get_Delta_CLmax_TO(obj)
        %GET_DELTA_CLMAX_TO  Flap + slat contributions, Table 12.2 + Eq. 12.21.
            val = obj.Delta_CLmax_flap('TO') + obj.Delta_CLmax_slat('TO');
        end

        function val = get_Delta_CLmax_L(obj)
        %GET_DELTA_CLMAX_L  Flap + slat contributions, Table 12.2 + Eq. 12.21.
            val = obj.Delta_CLmax_flap('L') + obj.Delta_CLmax_slat('L');
        end

        function val = get_Delta_CDi_TO(obj)
        %GET_DELTA_CDI_TO  Raymer 6th ed. Eq. 12.62 (flap) + Eq. 12.62 form (slat).
            val = obj.Delta_CDi_flap(obj.Delta_CLmax_flap('TO')) + obj.Delta_CDi_slat(obj.Delta_CLmax_slat('TO'));
        end

        function val = get_Delta_CDi_L(obj)
        %GET_DELTA_CDI_L  Raymer 6th ed. Eq. 12.62 (flap) + Eq. 12.62 form (slat).
            val = obj.Delta_CDi_flap(obj.Delta_CLmax_flap('L')) + obj.Delta_CDi_slat(obj.Delta_CLmax_slat('L'));
        end

        function val = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Clean CLmax + Delta_CLmax_TO (flap + slat).
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_TO();
        end

        function val = get_CLmax_L(obj)
        %GET_CLMAX_L  Clean CLmax + Delta_CLmax_L (flap + slat).
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_L();
        end

        function obj = populate_HLD_deltas(obj, state)
        %POPULATE_HLD_DELTAS  Fill in the Delta_*_flap/slat/gear properties
        %   declared above (previously unset placeholders).
            obj.Delta_CD0_TO_flap   = obj.Delta_CD0_flap(obj.delta_flap_TO_deg);
            obj.Delta_CD0_TO_slat   = obj.Delta_CD0_slat(obj.delta_slat_TO_deg);
            obj.Delta_CD0_TO_gear   = obj.compute_Delta_CD0_geardown(state);
            obj.Delta_CD0_L_flap    = obj.Delta_CD0_flap(obj.delta_flap_L_deg);
            obj.Delta_CD0_L_slat    = obj.Delta_CD0_slat(obj.delta_slat_L_deg);
            obj.Delta_CD0_L_gear    = obj.compute_Delta_CD0_geardown(state);

            obj.Delta_CL_max_TO_flap = obj.Delta_CLmax_flap('TO');
            obj.Delta_CL_max_TO_slat = obj.Delta_CLmax_slat('TO');
            obj.Delta_CL_max_L_flap  = obj.Delta_CLmax_flap('L');
            obj.Delta_CL_max_L_slat  = obj.Delta_CLmax_slat('L');

            obj.Delta_CDi_TO_flap = obj.Delta_CDi_flap(obj.Delta_CL_max_TO_flap);
            obj.Delta_CDi_L_flap  = obj.Delta_CDi_flap(obj.Delta_CL_max_L_flap);
            % NOTE: Delta_CDi_TO_flap/L_flap properties predate the slat
            % work and only hold the flap term; get_Delta_CDi_TO/L() above
            % (flap+slat) is the correct total to use.

            obj.Delta_e_osw_TO = obj.get_Delta_e_osw_TO();
            obj.Delta_e_osw_L  = obj.get_Delta_e_osw_L();
        end

    end

    methods (Access = private)

        function val = roskam_e_osw(~, flapconfig)
        %ROSKAM_E_OSW  Mean of AeroL1.Delta_CD0's "e_osw" range for flapconfig.
        %   Roskam, Airplane Design Part I, Table 3.6. Reads AeroL1's
        %   existing Constant table directly; no toolbox change.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.e_osw{1});
        end

    end
end
