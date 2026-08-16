classdef F16SandCL3 < SandCModelL3
%F16SANDCL3  F-16A Block 10/15 Level-3 stability & control student class.
%
%   Inherits from SandCModelL3 (abstract enforcer). Every abstract member
%   delegates to the SandCL2/SandCL3 static toolboxes; this file is DI/unit-
%   conversion glue only.
%
%   METHOD (citations per member):
%     x_cg      -- weighted-average CG [readme_bsc.md "CG closure"].
%     x_acw     -- wing aerodynamic center [Raymer 6th ed. Eq. 16.12].
%     x_ach     -- tail quarter-MAC point, no Mach-shift term.
%     Cm_alpha_fus -- [Raymer Eq. 16.25] x (180/pi).
%     CL_alpha_wing/CL_alpha_tail -- read from Aero, not re-derived.
%     x_np, Cm_alpha -- [Raymer Eqs. 16.9, 16.8], thrust term dropped
%                  (power-off sanction, p.593).
%     SM        -- [Raymer Eq. 16.11], (x_np-x_cg)/cbar_wing.
%     Delta_alpha_L0(delta_e_deg) -- [Raymer Eqs. 16.15/16.16/16.18];
%                  evaluates to 0 for the F-16 all-moving stabilator
%                  (obj.ctrl.c_elev_frac=0).
%     CL_w(alpha_deg), CL_h(alpha_deg, i_h_deg) -- i_w=0deg [T.O. 1F-16A-1];
%                  alpha_0L=-1.33deg [NACA 64A204, Aero]; i_h is a required
%                  caller argument; epsilon/alpha_0Lh=0deg (downwash out of
%                  scope; symmetric biconvex tail section).
%     Cm_cg_trim(alpha_deg, i_h_deg) -- [Raymer Eq. 16.5/16.7]. x_p=geom.x_inlet;
%                  z_t=F_p=0 [Raymer p.604/p.609]. Cm_acw [Eq. 16.19, p.598]
%                  needs Cm0_airfoil_wing, a user-supplied input (default NaN);
%                  Cm_cg_trim returns NaN until it is filled in.
%
%   DEPENDENCY INJECTION -- every collaborator REQUIRED, no silent defaults:
%     geom    -- (1,1) F16GeomL3 (CONCRETE). Supplies wing/HT x-stations,
%                chords, MAC, sweeps, areas, W_max_fuselage, L_fus.
%     ctrl    -- (1,1) ControlSurfaceSizer. Supplies c_elev_frac=0 [Raymer
%                6th ed. Table 6.5, F-16 all-moving stabilator] for
%                Delta_alpha_L0.
%     weights -- (1,1) F16WeightsL3 (CONCRETE). Supplies each component
%                group's weight live, and cruise_mach as the analysis Mach
%                for every Mach-dependent quantity below.
%     aero    -- (1,1) F16AeroL3 (CONCRETE). Supplies get_CL_alpha(M) for the
%                wing lift-curve slope.
%     prop    -- (1,1) F16PropL2 (no L3 propulsion tier exists). Stored for
%                future thrust-term use; not read by any current quantity.
%
%   eta_h (0.90, [Raymer p.591 "typical value"]) and dalphah_dalpha (1.0,
%   [Raymer Eq. 16.23], downwash out of scope) are genuine INPUT properties
%   set explicitly below -- NEVER hardcoded inside the SandCL3 toolbox statics.
%
%   History and rationale: docs/decision_log.md
%
%   SOURCES:
%     [Raymer] D.P. Raymer, Aircraft Design 6th ed., Ch. 16 Sec. 16.3,
%       Eqs. 16.8-16.18, 16.25 (pp.585-619).
%     [readme_bsc.md] VnV/BrandtF16A/readme_bsc.md -- "CG closure" and
%       "x_MAC = x_LE,r + y_MAC*tan(Lambda_LE)" cross-checks.
%     [TO] T.O. 1F-16A-1 -- via the injected F16GeomL3's physical inputs.
%
%   Companion doc: examples/F16A/models/disciplines/sandc/F16SandCL3.md

    % Fixed group order -- matches f16a_L3.json
    % .stability_control.component_x_stations.groups key order; same 10 groups
    % as F16SandCL2.
    properties (Constant)
        COMPONENT_GROUP_NAMES = {'wing', 'horizontal_tail', 'vertical_tail', ...
            'fuselage', 'landing_gear', 'installed_engine', 'subsystems_lump', ...
            'strake', 'payload', 'fuel'}
    end

    % ======================================================================= %
    % INPUTS -- set once by the constructor (static spec data), plus the
    % injected collaborators every DERIVED property below reads LIVE.
    % ======================================================================= %
    properties
        component_cg_x_ft         (1,10) double   % ft  [f16a_L3.json .stability_control.component_x_stations.groups.*.cg_x_ft, COMPONENT_GROUP_NAMES order]
        component_front_edge_x_ft  (1,10) double = NaN(1,10)   % ft  [f16a_L3.json ...*.front_edge_x_ft, NaN where null] -- cross-check field, read but not used in any Eq. 16.x formula

        %K_FUS  Fuselage moment factor off Fig. 16.14 (NACA TR 711), read at
        %   the F-16's root-quarter-chord position (44.17% of fuselage length).
        %   [Raymer 6th ed. Fig. 16.14] -- feeds Eq. 16.25's Cm_alpha,fus term.
        K_fus (1,1) double   % [f16a_L3.json .stability_control.fuselage_moment.K_fus]

        %ETA_H  Tail dynamic-pressure ratio q_h/q. [Raymer 6th ed. p.591,
        %   "typical value"].
        eta_h (1,1) double = 0.90

        %DALPHAH_DALPHA  d(alpha_h)/d(alpha) = 1 - d(epsilon)/d(alpha).
        %   [Raymer 6th ed. Eq. 16.23] -- downwash out of scope, so 1.0.
        dalphah_dalpha (1,1) double = 1.0

        %I_W_DEG  Wing incidence angle [deg]. [T.O. 1F-16A-1, "WINGS" data
        %   block: "Incidence ... 0deg"]. Used by Eq. 16.13's CL_w.
        i_w_deg (1,1) double

        %CM0_AIRFOIL_WING  Wing section 2D zero-lift pitching-moment
        %   coefficient about its aerodynamic center [--]. USER-SUPPLIED --
        %   Raymer 6th ed. Eq. 16.19 (p.598) gives the wing-level AR/sweep
        %   adjustment from this value, but not the value itself (airfoil-table
        %   data). Defaults to NaN; Cm_acw/Cm_cg_trim then return NaN rather
        %   than erroring.
        Cm0_airfoil_wing (1,1) double = NaN

        % ----- Injected collaborators (NOT numeric spec data) -------------- %
        geom      % (1,1) F16GeomL3 -- wing/HT geometry x-stations, chords, MAC, sweeps
        weights   % (1,1) F16WeightsL3 -- component group weights live, and the analysis Mach (weights.cruise_mach)
        aero      % (1,1) F16AeroL3 -- wing lift-curve slope (get_CL_alpha)
        prop      % (1,1) F16PropL2 -- stored for future thrust-term use; not read by any current quantity
        ctrl      % (1,1) ControlSurfaceSizer -- c_elev_frac (Delta_alpha_L0's one input)
    end

    % ======================================================================= %
    % DERIVED -- recomputed live from the injected collaborators' CURRENT
    % state on every read (no cache, never stale). Read-only (no set-method).
    % ======================================================================= %
    properties (Dependent)
        x_cg              % ft    [StabControlBase contract] weighted-average CG
        x_acw             % ft    [SandCModelL3 contract] wing aerodynamic center     [Raymer Eq. 16.12]
        x_ach             % ft    [SandCModelL3 contract] tail quarter-MAC point (no Mach shift)
        CL_alpha_wing     % 1/rad [SandCModelL3 contract] <- aero.get_CL_alpha(M)
        CL_alpha_tail     % 1/rad [SandCModelL3 contract] <- SandCL3.CL_alpha_h(geom HT props, M)
        Cm_alpha_fus      % 1/rad [SandCModelL3 contract] [Raymer Eq. 16.25] x (180/pi)
        x_np              % ft    [SandCModelL3 contract] neutral point                [Raymer Eq. 16.9], power-off
        SM                % --    [SandCModelL3 contract] static margin, frac. of cbar_wing [Raymer Eq. 16.11]
        Cm_alpha          % 1/rad [SandCModelL3 contract] [Raymer Eq. 16.8], power-off
        Cm_acw            % --    wing zero-lift moment about its own AC    [Raymer Eq. 16.19]; NaN until obj.Cm0_airfoil_wing is user-supplied
    end

    methods

        function obj = F16SandCL3(json_path, geom, weights, aero, prop, ctrl)
        %F16SANDCL3  Construct from a required unified L3 input JSON path
        %   (f16a_spec_path(3); reads its .stability_control block) plus five
        %   required injected collaborators (geom, weights, aero, prop, ctrl).
        %   No silent default on any argument.
            arguments
                json_path      {mustBeTextScalar, mustBeNonzeroLengthText}
                geom     (1,1) F16GeomL3
                weights  (1,1) F16WeightsL3
                aero     (1,1) F16AeroL3
                prop     (1,1) F16PropL2
                ctrl     (1,1) ControlSurfaceSizer
            end
            obj.geom    = geom;
            obj.weights = weights;
            obj.aero    = aero;
            obj.prop    = prop;
            obj.ctrl    = ctrl;

            S = jsondecode(fileread(json_path)).stability_control;

            names = F16SandCL3.COMPONENT_GROUP_NAMES;
            x_cg_ft    = zeros(1, numel(names));
            x_front_ft = NaN(1, numel(names));
            for i = 1:numel(names)
                grp = S.component_x_stations.groups.(names{i});
                x_cg_ft(i) = grp.cg_x_ft;
                if isfield(grp, 'front_edge_x_ft') && ~isempty(grp.front_edge_x_ft)
                    x_front_ft(i) = grp.front_edge_x_ft;
                end
            end
            obj.component_cg_x_ft        = x_cg_ft;
            obj.component_front_edge_x_ft = x_front_ft;

            obj.K_fus = S.fuselage_moment.K_fus;   % 0.025 [Raymer Fig. 16.14, Casey's chart read 2026-08-04]
            obj.i_w_deg = S.i_w_deg;               % 0 [T.O. 1F-16A-1, "WINGS" data block]
            if isfield(S, 'Cm0_airfoil_wing') && ~isempty(S.Cm0_airfoil_wing)
                obj.Cm0_airfoil_wing = S.Cm0_airfoil_wing;   % USER-SUPPLIED, see property header
            end   % else keeps the property-block default (NaN)

            % eta_h and dalphah_dalpha keep their property-block defaults
            % (0.90, 1.0) -- see the class header for the full citation.
        end

        % ================================================================== %
        % DERIVED-property getters -- each recomputes live from the injected
        % collaborators' CURRENT state on every read.
        % ================================================================== %

        function v = get.x_cg(obj)
            v = SandCL2.weighted_cg(obj.component_weights(), obj.component_cg_x_ft);
        end

        function v = get.x_acw(obj)
            g = obj.geom;
            v = SandCL3.x_ac_wing(g.x_apex_wing, g.LE_sweep_wing, g.b_wing, ...
                    g.lambda_wing, g.cbar_wing, g.S_ref, obj.weights.cruise_mach);
        end

        function v = get.x_ach(obj)
            % Tail MAC is not exposed as a named GeomL3 property -- recomputed
            % from the injected root chord/taper via the shared
            % GeometryBase.compute_mac static, EXACTLY the pattern
            % F16AeroL3.get.l_ref_comp already uses for the same quantity.
            g = obj.geom;
            cbar_ht = GeometryBase.compute_mac(g.c_root_ht, g.lambda_ht);
            v = SandCL3.x_ac_surface(g.x_le_ht, g.LE_sweep_ht, g.b_ht, g.lambda_ht, cbar_ht);
        end

        function v = get.CL_alpha_wing(obj)
            % Read DIRECTLY from Aero -- not re-derived (this discipline's own
            % decision in the original stability-and-control design).
            v = obj.aero.get_CL_alpha(obj.weights.cruise_mach);
        end

        function v = get.CL_alpha_tail(obj)
            g = obj.geom;
            v = SandCL3.CL_alpha_h(g.AR_ht, g.QC_sweep_ht, obj.weights.cruise_mach);
        end

        function v = get.Cm_alpha_fus(obj)
            g = obj.geom;
            v = SandCL3.Cm_alpha_fus_per_rad(obj.K_fus, g.W_max_fuselage, g.L_fus, g.cbar_wing, g.S_ref);
        end

        function v = get.x_np(obj)
            [Xnp_bar, ~, ~] = obj.neutral_point_bar();
            v = Xnp_bar * obj.geom.cbar_wing;
        end

        function v = get.SM(obj)
            [Xnp_bar, Xcg_bar, ~] = obj.neutral_point_bar();
            v = SandCL3.static_margin(Xnp_bar, Xcg_bar);
        end

        function v = get.Cm_alpha(obj)
            [~, Xcg_bar, Xacw_bar] = obj.neutral_point_bar();
            g = obj.geom;
            Xach_bar = obj.x_ach / g.cbar_wing;
            v = SandCL3.Cm_alpha(obj.CL_alpha_wing, Xcg_bar, Xacw_bar, obj.Cm_alpha_fus, ...
                    obj.eta_h, g.S_ht/g.S_ref, obj.CL_alpha_tail, obj.dalphah_dalpha, Xach_bar, ...
                    0, 0, 0);   % thrust term dropped -- Raymer's own "power-off" sanction, p.593
        end

        function v = get.Cm_acw(obj)
        %CM_ACW  [Raymer 6th ed. Eq. 16.19, p.598] -- SandCL3.Cm_acw_wing is
        %   complete and cited; returns NaN (not an error) whenever
        %   obj.Cm0_airfoil_wing hasn't been user-supplied yet -- see that
        %   property's own header.
            g = obj.geom;
            v = SandCL3.Cm_acw_wing(obj.Cm0_airfoil_wing, g.AR_wing, g.QC_sweep_wing);
        end

        % ================================================================== %
        % Methods -- Delta_alpha_L0 is real; CL_w/CL_h are real; Cm_cg_trim
        % is real but returns NaN until Cm0_airfoil_wing is user-supplied
        % (see SandCModelL3's own header).
        % ================================================================== %

        function val = Delta_alpha_L0(obj, delta_e_deg)
        %DELTA_ALPHA_L0  [Raymer 6th ed. Eqs. 16.15/16.16/16.18]. Evaluates
        %   to 0 for the F-16 (obj.ctrl.c_elev_frac=0, all-moving stabilator).
            val = SandCL3.delta_alpha_L0_elevator(obj.ctrl.c_elev_frac, delta_e_deg);
        end

        function val = Cm_alpha_via_neutral_point(obj)
        %CM_ALPHA_VIA_NEUTRAL_POINT  [Raymer 6th ed. Eq. 16.10] -- cross-check
        %   against Cm_alpha (Eq. 16.8) at the same inputs. Not part of the
        %   SandCModelL3 abstract contract.
            [Xnp_bar, Xcg_bar, ~] = obj.neutral_point_bar();
            g = obj.geom;
            val = SandCL3.Cm_alpha_from_neutral_point(obj.CL_alpha_wing, obj.eta_h, ...
                    g.S_ht/g.S_ref, obj.CL_alpha_tail, obj.dalphah_dalpha, Xnp_bar, Xcg_bar);
        end

        function val = CL_w(obj, alpha_deg)
        %CL_W  [Raymer 6th ed. Eq. 16.13]. i_w=0deg [T.O. 1F-16A-1, "WINGS"
        %   data block]. alpha_0L = obj.aero.alpha_L0 = -1.33deg [NACA 64A204].
            val = SandCL3.CL_w(obj.CL_alpha_wing, alpha_deg, obj.i_w_deg, obj.aero.alpha_L0);
        end

        function val = CL_h(obj, alpha_deg, i_h_deg)
        %CL_H  [Raymer 6th ed. Eq. 16.14]. i_h is a REQUIRED caller-supplied
        %   trim-condition argument, not a spec constant -- the F-16 tail is an
        %   all-moving stabilator (obj.ctrl.c_elev_frac=0, Raymer Table 6.5),
        %   so tail incidence is the trim control variable.
        %   epsilon=0deg (downwash out of scope). alpha_0Lh=0deg [T.O.
        %   1F-16A-1, "HORIZONTAL TAILS" biconvex -> symmetric section].
            val = SandCL3.CL_h(obj.CL_alpha_tail, alpha_deg, i_h_deg, 0, 0);
        end

        function val = Cm_cg_trim(obj, alpha_deg, i_h_deg)
        %CM_CG_TRIM  [Raymer 6th ed. Eq. 16.5/16.7] Full pitching-moment-
        %   about-CG coefficient at the given angle of attack and tail
        %   incidence, clean/cruise condition:
        %     x_p = obj.geom.x_inlet [Raymer Eqs. 16.26-16.28, p.604].
        %     z_t = 0, F_p = 0 [Raymer p.604/p.609].
        %     delta_f = 0 (clean/cruise).
        %     CL   = obj.CL_w(alpha_deg) [Eq. 16.13].
        %     CL_h = obj.CL_h(alpha_deg, i_h_deg) [Eq. 16.14], i_h_deg a
        %       required caller argument (all-moving stabilator).
        %     Cm_acw [Eq. 16.19] -- NaN until obj.Cm0_airfoil_wing is
        %       user-supplied, so this method returns NaN rather than erroring.
        %   q (dynamic pressure) is passed as 1 -- it only multiplies the T/F_p
        %   thrust terms, both 0.
            g = obj.geom;
            val = SandCL3.Cm_cg_coefficient(obj.CL_w(alpha_deg), obj.x_cg, obj.x_acw, ...
                    g.cbar_wing, obj.Cm_acw, 0, 0, ...
                    obj.eta_h, g.S_ht, g.S_ref, obj.CL_h(alpha_deg, i_h_deg), obj.x_ach, ...
                    1, 0, 0, 0, g.x_inlet);
        end

    end

    methods (Access = private)

        function w = component_weights(obj)
        %COMPONENT_WEIGHTS  Live weight [lbf] for each of the 10 groups, in
        %   COMPONENT_GROUP_NAMES order.
            names = obj.COMPONENT_GROUP_NAMES;
            w = zeros(1, numel(names));
            for i = 1:numel(names)
                w(i) = obj.group_weight(names{i});
            end
        end

        function val = group_weight(obj, name)
        %GROUP_WEIGHT  Live weight [lbf] for ONE named group, read from the
        %   injected F16WeightsL3 object. Mapping matches
        %   f16a_L3.json .stability_control.component_x_stations.groups.*
        %   .weights_property field-for-field:
        %     wing              -> W_wings
        %     horizontal_tail   -> W_tail.HT
        %     vertical_tail     -> W_tail.VT
        %     fuselage          -> W_fuselage
        %     landing_gear      -> weight_landing_gear(W_TO).main + .nose  (METHOD at L3, not a property -- needs weights.W_TO set)
        %     installed_engine  -> W_installed_engine
        %     subsystems_lump   -> W_subsystems                            (needs weights.W_TO set)
        %     strake            -> W_strake
        %     payload           -> W_payload_fixed + W_payload_expendable
        %     fuel              -> W_energy                                (mission-analysis STATE; NaN pre-mission -- propagates gracefully)
            wts = obj.weights;
            switch name
                case 'wing',             val = wts.W_wings;
                case 'horizontal_tail',  val = wts.W_tail.HT;
                case 'vertical_tail',    val = wts.W_tail.VT;
                case 'fuselage',         val = wts.W_fuselage;
                case 'landing_gear'
                    lg  = wts.weight_landing_gear(wts.W_TO);
                    val = lg.main + lg.nose;
                case 'installed_engine', val = wts.W_installed_engine;
                case 'subsystems_lump',  val = wts.W_subsystems;
                case 'strake',           val = wts.W_strake;
                case 'payload',          val = wts.W_payload_fixed + wts.W_payload_expendable;
                case 'fuel',             val = wts.W_energy;
                otherwise
                    error('F16SandCL3:unknownComponentGroup', ...
                        ['Unknown component-x-station group "%s" -- not one of ' ...
                         'F16SandCL3.COMPONENT_GROUP_NAMES. Check ' ...
                         'f16a_L3.json .stability_control.component_x_stations.groups.'], name);
            end
        end

        function [Xnp_bar, Xcg_bar, Xacw_bar] = neutral_point_bar(obj)
        %NEUTRAL_POINT_BAR  Shared helper: the three MAC-fraction stations
        %   x_np/x_cg/x_acw need (Eq. 16.9, thrust term dropped), shared across
        %   get.x_np / get.SM / get.Cm_alpha.
            g = obj.geom;
            Xcg_bar  = obj.x_cg  / g.cbar_wing;
            Xacw_bar = obj.x_acw / g.cbar_wing;
            Xach_bar = obj.x_ach / g.cbar_wing;
            Xnp_bar  = SandCL3.neutral_point(obj.CL_alpha_wing, Xacw_bar, obj.Cm_alpha_fus, ...
                    obj.eta_h, g.S_ht/g.S_ref, obj.CL_alpha_tail, obj.dalphah_dalpha, Xach_bar, ...
                    0, 0, 0);   % thrust term dropped -- Raymer's own "power-off" sanction, p.593
        end

    end

end
