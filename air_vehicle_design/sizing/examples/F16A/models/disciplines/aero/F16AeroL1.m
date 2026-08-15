classdef F16AeroL1 < AeroModelL1
%F16AEROL1  F-16A Block 10 Level-1 aerodynamics student class.
%
%   Inherits AeroModelL1 (abstract enforcer). The drag polar is
%   CD = CD0(M) + K1(M)*CL^2 + K2*CL (Mattingly: Aircraft Engine Design, 2nd edition Eq. 2.9), and
%   CLmax is a Roskam type-based lookup. Every abstract method delegates to
%   the AeroL1 static toolbox.
%
%   CD0(M): interpolated from the Mattingly Fig. 2.10 fighter "Current"
%   type-curve (still geometry-free -- see cd0_curve_mach/value below).
%
%   K1(M): EQUATION-BASED, NOT A CURVE (changed 2026-07-29, user direction --
%   see git history for the full diagnostic trail). Previously interpolated
%   Mattingly's GENERIC Fig. 2.11 fighter type-curve (flat 0.18 subsonic),
%   which was ~55% higher than Brandt's own calibrated F-16 K1=0.1160 and,
%   because ThrustConstraint's induced-drag term scales with K1*n^2
%   (ThrustConstraint.m compute_B), pulled design_study_01_L1's
%   optimal_point() down to W/S=76.00 instead of Brandt's W/S=104.59 (the
%   "Combat Subsonic" n=4.5 sustained-turn condition rose ~55% steeper than
%   Brandt's own chart and became binding too soon). K1 is now computed by
%   AeroL1.k1_from_geometry(obj.AR, obj.Lambda_LE_deg, state.mach), which
%   reuses AeroL2's own Raymer equations (Eq. 12.48-12.50 subsonic, Eq. 12.51
%   supersonic) fed the F-16's real wing AR/sweep (this class's AR/
%   Lambda_LE_deg properties below) -- reproduces Brandt's calibrated K1 to
%   within 0.7% at subsonic Mach (e_osw=0.9086, K1=0.1168 vs. Brandt's
%   0.1160) essentially from first principles, and raises
%   design_study_01_L1's WS_opt to 111.00 (T/W=0.7252), much closer to
%   Brandt. See AeroL1.m's class header ("K1 -- EQUATION-BASED, NOT A CURVE")
%   for the equations and the resulting transonic-NaN-band caveat (K1 is
%   NaN for 0.95<=M<1.05 -- CD0 has no such gap).
%
%   AR/Lambda_LE_deg ARE GENUINE SPEC DATA, NOT A GEOMETRY OBJECT: this class
%   still takes NO geometry object (contrast F16AeroL2/L3, whose constructors
%   require an injected geometry object) -- AR and Lambda_LE_deg are two
%   scalar wing-spec inputs read directly from the .aerodynamics JSON block
%   (same real F-16 values as f16a_L2.json's .geometry.wing: AR=3.0,
%   sweep_LE_deg=40.0), the same "Layer 2 wires in genuine spec data" pattern
%   every other Tier-3 class uses, not derived/computed geometry.
%
%   Inheritance: AerodynamicsBase -> AeroModelL1 -> F16AeroL1
%
%   Expected outputs (F-16A "Current" fighter curve for CD0; equation-based K1):
%     drag_polar(M=0.6): CD0~0.016, K1~0.1168 [Raymer Eq. 12.48-12.50, AR=3.0/sweep=40deg], K2=0
%     get_CLmax        : 1.50  [Roskam Vol. I Table 3.1, fighter clean mean]
%     get_CLmax_TO     : 1.70  [Table 3.1 fighter TO mean]
%     get_CLmax_L      : 2.10  [Table 3.1 fighter landing mean]
%
%   TABLE 3.1 THROUGHOUT (2026-07-25). Clean CLmax and the takeoff/landing
%   increments all come from Roskam Table 3.1, so the totals equal that table's
%   own fighter means. Previously the clean base was Table 3.3's 0.90 while the
%   increments were Table 3.1 differences off a 1.50 base, giving totals
%   (1.10/1.50) that belonged to neither table. Note the resulting L1->L2
%   discontinuity is large and INTENTIONAL: 1.50 here vs. 0.913 at L2/L3
%   (Raymer Eq. 12.15, geometry-based) -- see AeroL1.get_CLmax's header.

    % ======================================================================= %
    % INPUTS -- aircraft-type / technology-curve spec data, plus AR/Lambda_LE_deg
    % (genuine wing spec scalars, NOT an injected geometry object -- see class
    % header). All from JSON; mutable. L1 owns NO geometry object, so there are
    % no Dependent geometry getters here (contrast F16AeroL2/L3).
    % ======================================================================= %
    properties
        aircraft_category % string; canonical class flag, read from the single top-level key. Selects the Roskam CLmax row (translated to that table's own "fighter" name by AeroL1.to_CLmax_table_row) and the Mattingly fighter curve.
        design_type       % string; "uncambered" -> K2=0 (Mattingly Sec. 2.3.1)
        curve             % string; Mattingly technology curve ("Current"/"Future"), CD0 only (see class header)

        % Mattingly Fig. 2.10 "Current"-curve breakpoints, (mach, value)
        % vectors read from the placeholder CD0 curve JSON. K1 no longer
        % comes from a curve -- see AR/Lambda_LE_deg below and class header.
        cd0_curve_mach
        cd0_curve_value

        % Real F-16 wing spec data (same values as f16a_L2.json's
        % .geometry.wing) feeding AeroL1.k1_from_geometry -- see class header
        % "K1 -- EQUATION-BASED, NOT A CURVE".
        AR                % --  wing aspect ratio
        Lambda_LE_deg     % deg wing leading-edge sweep
    end

    methods

        function obj = F16AeroL1(json_path)
        %F16AEROL1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)); reads its .aerodynamics block (aircraft type,
        %   camber class, technology-curve selector, the folded-in Mattingly
        %   Fig. 2.10 CD0 curve table, and the real wing AR/Lambda_LE_deg used
        %   to compute K1 -- see class header). No silent default: the path
        %   must be supplied. L1 takes NO injected geometry object (contrast
        %   F16AeroL2/L3) -- AR/Lambda_LE_deg are genuine spec scalars read
        %   directly, same as every other Layer-2 aircraft-specific input.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;
            % ONE canonical top-level category key (Phase 3, 2026-07-25): it was
            % previously stored three times under two spellings, and the four
            % readers did not accept the same vocabulary.
            obj.aircraft_category = string(J.aircraft_category);

            obj.design_type   = string(A.design_type);
            obj.curve         = string(A.curve);

            cd0_curve = A.cd0_curve.(char(obj.curve));
            obj.cd0_curve_mach  = [cd0_curve.mach];
            obj.cd0_curve_value = [cd0_curve.value];

            obj.AR            = A.AR;
            obj.Lambda_LE_deg = A.Lambda_LE_deg;
        end

        function polar = drag_polar(obj, state)
            polar = AeroL1.drag_polar(obj, state);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = AeroL1.get_CLmax(obj);
        end

        % ================================================================ %
        % High-lift-device / gear deltas -- pure tabulation (Roskam Vol. I
        % Tables 3.1 and 3.6, "fighter" row). Type-based, NO geometry.
        % Reads AeroL1's Constant tables directly.
        % ================================================================ %

        function val = get_Delta_e_osw_TO(obj)
        %GET_DELTA_E_OSW_TO  Roskam Table 3.6: e(TO flaps) - e(clean).
            val = obj.roskam_e_osw("takeoff_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_e_osw_L(obj)
        %GET_DELTA_E_OSW_L  Roskam Table 3.6: e(landing flaps) - e(clean).
            val = obj.roskam_e_osw("landing_flaps") - obj.roskam_e_osw("clean");
        end

        function val = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Roskam Table 3.6: Delta_CD0(TO flaps) + Delta_CD0(gear).
            val = obj.roskam_Delta_CD0("takeoff_flaps") + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CD0_L(obj)
        %GET_DELTA_CD0_L  Roskam Table 3.6: Delta_CD0(landing flaps) + Delta_CD0(gear).
            val = obj.roskam_Delta_CD0("landing_flaps") + obj.roskam_Delta_CD0("landing_gear");
        end

        function val = get_Delta_CLmax_TO(obj)
        %GET_DELTA_CLMAX_TO  Roskam Table 3.1: CLmax_TO(fighter) - CLmax_clean(fighter).
            val = obj.roskam_CLmax("CL_max_TO") - obj.roskam_CLmax("CL_max_clean");
        end

        function val = get_Delta_CLmax_L(obj)
        %GET_DELTA_CLMAX_L  Roskam Table 3.1: CLmax_L(fighter) - CLmax_clean(fighter).
            val = obj.roskam_CLmax("CL_max_L") - obj.roskam_CLmax("CL_max_clean");
        end

        function val = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Clean CLmax + Delta_CLmax_TO.
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_TO();
        end

        function val = get_CLmax_L(obj)
        %GET_CLMAX_L  Clean CLmax + Delta_CLmax_L.
            val = obj.get_CLmax([]) + obj.get_Delta_CLmax_L();
        end

        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Per-high-lift-config polar, built on the F-16 clean
        %   drag polar plus this class's config-distinguishing methods
        %   (get_CLmax_TO/_L, get_Delta_CD0_TO/_L) -- the AerodynamicsBase
        %   contract the FAR-25 field-length/climb constraints read.
        %
        %   The clean CD0/K1 are Mach-dependent, but the six configs are
        %   LOW-SPEED high-lift states, so they are evaluated at a nominal
        %   takeoff/landing condition (sea level, M = 0.2). The F-16 sizes with
        %   the MILITARY Takeoff/Landing constraints, not the FAR-25 field-
        %   length path, so this method completes the base contract by reusing
        %   the existing config deltas. F-16 aero models clean/takeoff/landing
        %   (no separate gear-up/gear-down split), so both takeoff_* configs map
        %   to the takeoff deltas and both landing_* plus approach to landing.
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            ref   = AircraftState(0, 0.2);   % nominal low-speed takeoff/landing condition
            clean = obj.drag_polar(ref);
            switch config
                case "clean"
                    CD0 = clean.CD0;                          CLmax = obj.get_CLmax(ref);
                case {"takeoff_flaps_gear_up", "takeoff_flaps_gear_down"}
                    CD0 = clean.CD0 + obj.get_Delta_CD0_TO(); CLmax = obj.get_CLmax_TO();
                otherwise   % landing_flaps_gear_up/down, approach
                    CD0 = clean.CD0 + obj.get_Delta_CD0_L();  CLmax = obj.get_CLmax_L();
            end
            cfg = struct('CD0', CD0, 'K1', clean.K1, 'K2', clean.K2, 'CLmax', CLmax);
        end

    end

    methods (Access = private)

        function val = roskam_e_osw(~, flapconfig)
        %ROSKAM_E_OSW  Mean of AeroL1.Delta_CD0's "e_osw" range for flapconfig.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.e_osw{1});
        end

        function val = roskam_Delta_CD0(~, flapconfig)
        %ROSKAM_DELTA_CD0  Mean of AeroL1.Delta_CD0's "Delta_CD0" range for flapconfig.
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = mean(row.Delta_CD0{1});
        end

        function val = roskam_CLmax(obj, column)
        %ROSKAM_CLMAX  Mean of AeroL1.CLmax_table's column for this aircraft type.
        %   Delegates to the AeroL1.roskam_CLmax_value low-level static, which
        %   AeroL1.get_CLmax also uses for the clean column -- so the clean base
        %   and these increments are guaranteed to come from the same table
        %   (Roskam Table 3.1). See AeroL1.get_CLmax's header.
            val = AeroL1.roskam_CLmax_value(obj.aircraft_category, column);
        end

    end
end
