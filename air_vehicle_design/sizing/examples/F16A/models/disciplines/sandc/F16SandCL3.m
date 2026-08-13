classdef F16SandCL3 < SandCModelL3
%F16SANDCL3  F-16A Block 10/15 Level-3 stability & control student class.
%
%   Inherits from SandCModelL3 (abstract enforcer). Every abstract member is
%   satisfied by a single delegation into the SandCL2/SandCL3 static
%   toolboxes -- no equations are duplicated here; this file is DI/unit-
%   conversion glue only.
%
%   METHOD (primary-source-corrected 2026-08-04, see
%   docs/subplans/10_stability_control.md):
%     x_cg      -- weighted-average CG [readme_bsc.md "CG closure"], SAME
%                  static (SandCL2.weighted_cg) F16SandCL2 uses.
%     x_acw     -- wing aerodynamic center [Raymer 6th ed. Eq. 16.12].
%     x_ach     -- tail quarter-MAC point, NO Mach-shift term (documented
%                  simplification -- see SandCL3.x_ac_surface).
%     Cm_alpha_fus -- [Raymer Eq. 16.25, "per deg"] x (180/pi).
%     CL_alpha_wing/CL_alpha_tail -- read/reused from Aero, not re-derived.
%     x_np, Cm_alpha -- [Raymer Eqs. 16.9, 16.8], thrust term DROPPED per
%                  Raymer's own "power-off" sanction (p.593).
%     SM        -- [Raymer Eq. 16.11], bare (x_np-x_cg)/cbar_wing, no /100.
%     Delta_alpha_L0(delta_e_deg) -- [Raymer Eqs. 16.15/16.16/16.18], real,
%                  evaluates to 0 for the F-16 (all-moving stabilator,
%                  obj.ctrl.c_elev_frac=0).
%     CL_w(alpha_deg), CL_h(alpha_deg, i_h_deg) -- CLOSED 2026-08-04. i_w=0deg
%                  [T.O. 1F-16A-1]; alpha_0L=-1.33deg [NACA 64A204, Aero];
%                  i_h is a required CALLER argument (all-moving stabilator,
%                  not a spec constant); epsilon/alpha_0Lh=0deg (downwash
%                  out of scope; symmetric biconvex tail section).
%     Cm_cg_trim(alpha_deg, i_h_deg) -- REAL as of 2026-08-04 (was a GAP
%                  stub). x_p/z_t/F_p all resolved (x_p=geom.x_inlet;
%                  z_t=F_p=0, Raymer-sanctioned simplifications, p.604/p.609).
%                  Cm_acw [Eq. 16.19, p.598] is also now a real, cited
%                  formula (SandCL3.Cm_acw_wing) -- but it needs
%                  Cm0_airfoil_wing, the wing section's own 2D moment
%                  coefficient, which Ch. 16 does not supply and which no
%                  citable NACA 64A204 value was found anywhere in this
%                  repo/session. Per Casey's own instruction ("the users/
%                  students must be able to supply their own value"),
%                  Cm0_airfoil_wing is a USER-SUPPLIED input (defaults to
%                  NaN, f16a_L3.json .stability_control.Cm0_airfoil_wing =
%                  null) -- Cm_cg_trim returns NaN, not an error, until it
%                  is filled in. See obj.Cm_acw's own header.
%
%   ============================================================================
%   DEPENDENCY INJECTION.  Mirrors F16WeightsL3(json_path, req_path, geom,
%   prop)'s pattern -- every collaborator REQUIRED, no silent defaults:
%     geom    -- (1,1) F16GeomL3 (CONCRETE). Supplies x_apex_wing, x_le_ht,
%                LE_sweep_wing/ht, b_wing/b_ht, lambda_wing/ht, cbar_wing,
%                c_root_ht, S_ref, S_ht, AR_ht, QC_sweep_ht, W_max_fuselage,
%                L_fus -- none of these are on the GeometryModelL3 abstract
%                contract (they are F16GeomL3's own x-station/physical-
%                construction inputs -- x_apex_wing, x_le_ht in particular
%                exist ONLY on F16GeomL3, per SandCModelL2's own header), so
%                a GeometryModelL3 type guard would not actually cover what
%                this class reads. Typed concretely, matching the launch
%                instruction's own "Inject F16GeomL3" (concrete) wording.
%                NOTE (2026-08-10): geom does NOT supply c_elev_frac -- the
%                2026-08-06 tail/control-surface re-extraction (commit
%                06c1db9) moved that property off F16GeomL3 back onto the
%                standalone ControlSurfaceSizer collaborator (see ctrl,
%                below); this class's constructor now injects ctrl instead
%                of reading a since-removed obj.geom.c_elev_frac.
%     ctrl    -- (1,1) ControlSurfaceSizer. Supplies c_elev_frac=0 [Raymer
%                6th ed. Table 6.5, F-16 all-moving stabilator, no separate
%                elevator] -- the ONE input Delta_alpha_L0 needs. SAME
%                ControlSurfaceSizer(0.20, 0.40, 0, 0, 0.30, 0.90) object
%                design_study_02_L2.m/design_study_03_L3.m already inject
%                into SizingLoopL2; not yet wired into a Level-3 sizing loop
%                itself (no SizingLoopL3 exists), so this constructor takes
%                it directly rather than via a loop.
%     weights -- (1,1) F16WeightsL3 (CONCRETE, same rationale as F16SandCL2's
%                weights argument -- W_strake/weight_landing_gear/W_subsystems
%                are F16WeightsL3-specific, not on any abstract contract).
%                ALSO supplies obj.weights.cruise_mach (0.87, itself read by
%                F16WeightsL3 from f16a_requirements.json in ITS OWN
%                constructor) as the ANALYSIS MACH for every Mach-dependent
%                quantity below (x_acw's Eq. 16.12 shift, CL_alpha_wing,
%                CL_alpha_tail) -- reused by DI rather than adding a SECOND
%                requirements-file read into this class's own constructor,
%                mirroring F16WeightsL3.SFC_mission's identical "evaluate at
%                the REQUIREMENTS cruise Mach" convention.
%     aero    -- (1,1) F16AeroL3 (CONCRETE). Supplies get_CL_alpha(M) for the
%                WING lift-curve slope directly -- per this discipline's own
%                "Wing CL_alpha comes from the injected F16AeroL3.get_CL_alpha
%                (M) directly (do not re-derive it in S&C)" decision.
%     prop    -- (1,1) F16PropL2 (no L3 propulsion tier exists repo-wide --
%                same DI pattern F16WeightsL3 already uses). Stored for
%                completeness/future use (e.g. a citable T for Cm_cg_trim's
%                thrust term) -- NOT read by any currently-implemented
%                quantity, since every thrust term this pass computes is
%                either dropped (Eq. 16.8/16.9's power-off simplification) or
%                GAP-blocked (Cm_cg_trim).
%   ============================================================================
%
%   eta_h (0.90) and dalphah_dalpha (1.0) are genuine INPUT properties, set
%   explicitly below with their own citations -- NEVER hardcoded inside the
%   SandCL3 toolbox statics (both are REQUIRED arguments there). This is the
%   legacy eta_h bug's fix: the VALUE 0.90 is Raymer's own stated "typical
%   value" [p.591: "[eta_h] ranges from about 0.85-0.95... with 0.90 as the
%   typical value"], not an arbitrary default -- the bug being avoided is
%   SILENTLY overwriting a separately-computed value with no comment, which
%   this class never does (there is no separately-computed eta_h to
%   overwrite; 0.90 is the only value ever used, explicitly, here).
%   dalphah_dalpha = 1 - d(epsilon)/d(alpha) = 1 (Eq. 16.23) since downwash is
%   OUT OF SCOPE this pass (d(epsilon)/d(alpha) = 0) -- the documented
%   simplification the subplan requires wherever a Raymer equation includes a
%   downwash term.
%
%   SOURCES:
%     [Raymer] D.P. Raymer, Aircraft Design 6th ed., Ch. 16 Sec. 16.3,
%       Eqs. 16.8-16.18, 16.25 (primary-source page read 2026-08-04, book
%       pp.585-619).
%     [readme_bsc.md] VnV/BrandtF16A/readme_bsc.md -- "CG closure" and
%       "x_MAC = x_LE,r + y_MAC*tan(Lambda_LE)" cross-checks.
%     [TO] T.O. 1F-16A-1 -- via the injected F16GeomL3's own physical inputs.
%
%   Companion doc: examples/F16A/models/disciplines/sandc/F16SandCL3.md

    % ======================================================================= %
    % Fixed group order -- matches f16a_L3.json
    % .stability_control.component_x_stations.groups' own key order exactly,
    % IDENTICAL to F16SandCL2.COMPONENT_GROUP_NAMES by design (same 10
    % framework weight groups at both fidelity levels).
    % ======================================================================= %
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
        component_cg_x_ft         (1,10) double   % ft  [f16a_L3.json .stability_control.component_x_stations.groups.*.cg_x_ft, COMPONENT_GROUP_NAMES order] -- IDENTICAL values to F16SandCL2's (fidelity-independent re-aggregation, per the JSON's own note)
        component_front_edge_x_ft  (1,10) double = NaN(1,10)   % ft  [f16a_L3.json ...*.front_edge_x_ft, NaN where null] -- the REDUNDANT cross-check field Casey asked for; stored for traceability/future use, NOT consumed by any Eq. 16.x formula this pass (matches F16SandCL2's own "never read it" note -- here it is READ but not USED in x_cg or any other computation)

        %K_FUS  Fuselage moment factor off Fig. 16.14 (NACA TR 711), read at
        %   the F-16's actual root-quarter-chord position (44.17% of
        %   fuselage length). [Raymer 6th ed. Fig. 16.14; Casey's direct
        %   chart read, 2026-08-04] -- feeds Eq. 16.25's Cm_alpha,fus term.
        K_fus (1,1) double   % [f16a_L3.json .stability_control.fuselage_moment.K_fus]

        %ETA_H  Tail dynamic-pressure ratio q_h/q. [Raymer 6th ed. p.591,
        %   "typical value"] -- see class header for the full citation and
        %   why this is NOT the legacy silent-overwrite bug.
        eta_h (1,1) double = 0.90

        %DALPHAH_DALPHA  d(alpha_h)/d(alpha) = 1 - d(epsilon)/d(alpha).
        %   [Raymer 6th ed. Eq. 16.23] -- downwash is OUT OF SCOPE this pass
        %   (d(epsilon)/d(alpha) = 0), so this is 1 identically. See class
        %   header.
        dalphah_dalpha (1,1) double = 1.0

        %I_W_DEG  Wing incidence angle [deg]. [T.O. 1F-16A-1, "WINGS" data
        %   block: "Incidence ... 0deg"] -- a real, aircraft-specific,
        %   primary-source value (closed 2026-08-04; the legacy temp_Casey
        %   code only ever had an uncited `i_w = 0 -- Assume 0 for now`).
        %   Used by Eq. 16.13's CL_w. See f16a_L3.json .stability_control.i_w_deg.
        i_w_deg (1,1) double

        %CM0_AIRFOIL_WING  Wing section's own 2D zero-lift pitching-moment
        %   coefficient about its aerodynamic center [--]. USER/STUDENT-
        %   SUPPLIED -- Raymer 6th ed. Eq. 16.19 (p.598) gives the wing-level
        %   AR/sweep adjustment FROM this value, but not the value itself
        %   (airfoil-table data, e.g. NACA report / Abbott & von Doenhoff);
        %   no citable NACA 64A204 number was found in this repo or session.
        %   Defaults to NaN (f16a_L3.json .stability_control.Cm0_airfoil_wing
        %   = null) until a real value is supplied -- Cm_acw/Cm_cg_trim then
        %   compute and return NaN rather than erroring (SandCL3.Cm_acw_wing
        %   is a real, complete, cited static; only this numeric input is
        %   missing). See f16a_L3.json's _cite_Cm0_airfoil_wing note.
        Cm0_airfoil_wing (1,1) double = NaN

        % ----- Injected collaborators (NOT numeric spec data) -------------- %
        geom      % (1,1) F16GeomL3 -- supplies wing/HT geometry x-stations, chords, MAC, sweeps
        weights   % (1,1) F16WeightsL3 -- supplies every component group's WEIGHT live, by DI, AND the analysis Mach (weights.cruise_mach)
        aero      % (1,1) F16AeroL3 -- supplies the wing lift-curve slope directly (get_CL_alpha)
        prop      % (1,1) F16PropL2 -- stored for completeness/future thrust-term use; not read by any quantity implemented this pass
        ctrl      % (1,1) ControlSurfaceSizer -- supplies c_elev_frac (Delta_alpha_L0's one input; see class header)
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
        %   required injected collaborators (geom, weights, aero, prop,
        %   ctrl). NO silent default on any argument -- a defaulted injection
        %   would silently re-freeze geometry/weights/aero/engine/control-
        %   surface data, the defect class this framework's DI convention
        %   removes elsewhere (F16GeomL2.m / F16WeightsL2.m / F16WeightsL3.m).
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
            % decision, docs/subplans/10_stability_control.md).
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
        %DELTA_ALPHA_L0  [Raymer 6th ed. Eqs. 16.15/16.16/16.18]. Real,
        %   complete -- evaluates to 0 for the F-16 (obj.ctrl.c_elev_frac=0,
        %   all-moving stabilator, no separate elevator), not a special case
        %   hardcoded here.
            val = SandCL3.delta_alpha_L0_elevator(obj.ctrl.c_elev_frac, delta_e_deg);
        end

        function val = Cm_alpha_via_neutral_point(obj)
        %CM_ALPHA_VIA_NEUTRAL_POINT  [Raymer 6th ed. Eq. 16.10] -- bonus
        %   cross-check against Cm_alpha (Eq. 16.8) at the SAME inputs; not
        %   required by the subplan, essentially free once x_np/Cm_alpha
        %   exist. NOT part of the SandCModelL3 abstract contract.
            [Xnp_bar, Xcg_bar, ~] = obj.neutral_point_bar();
            g = obj.geom;
            val = SandCL3.Cm_alpha_from_neutral_point(obj.CL_alpha_wing, obj.eta_h, ...
                    g.S_ht/g.S_ref, obj.CL_alpha_tail, obj.dalphah_dalpha, Xnp_bar, Xcg_bar);
        end

        function val = CL_w(obj, alpha_deg)
        %CL_W  [Raymer 6th ed. Eq. 16.13] CLOSED 2026-08-04 (was a GAP stub).
        %   `i_w`=0deg [T.O. 1F-16A-1, "WINGS" data block, "Incidence...0deg"
        %   -- a real primary-source value, see obj.i_w_deg]. `alpha_0L`
        %   [obj.aero.alpha_L0 = -1.33deg, NACA 64A204, already cited in
        %   f16a_L3.json .aerodynamics.airfoil].
            val = SandCL3.CL_w(obj.CL_alpha_wing, alpha_deg, obj.i_w_deg, obj.aero.alpha_L0);
        end

        function val = CL_h(obj, alpha_deg, i_h_deg)
        %CL_H  [Raymer 6th ed. Eq. 16.14] CLOSED 2026-08-04 (was a GAP stub,
        %   reframed rather than resolved by a spec lookup). `i_h` is now a
        %   REQUIRED CALLER-SUPPLIED trim-condition argument, not a spec
        %   constant -- the F-16 tail is an ALL-MOVING STABILATOR
        %   (obj.ctrl.c_elev_frac=0, Raymer Table 6.5), so tail incidence IS
        %   the pilot/trim control variable, not a fixed installation angle
        %   like i_w. There is nothing to cite for a fixed i_h because it is
        %   not a constant.
        %   `epsilon`=0deg (downwash, OUT OF SCOPE this pass -- documented
        %   simplification, matches obj.dalphah_dalpha=1 elsewhere in this
        %   class). `alpha_0Lh`=0deg [T.O. 1F-16A-1, "HORIZONTAL TAILS" data
        %   block: "Airfoil: At Root 6% Biconvex, At Tip 3.5% Biconvex" --
        %   biconvex sections are SYMMETRIC (zero camber), and a symmetric
        %   airfoil's zero-lift angle of attack is 0deg by definition -- not
        %   an assumption, a direct consequence of the cited section shape].
            val = SandCL3.CL_h(obj.CL_alpha_tail, alpha_deg, i_h_deg, 0, 0);
        end

        function val = Cm_cg_trim(obj, alpha_deg, i_h_deg)
        %CM_CG_TRIM  [Raymer 6th ed. Eq. 16.5/16.7] Full pitching-moment-
        %   about-CG coefficient at the given angle of attack and tail
        %   incidence, clean/cruise condition. REAL as of 2026-08-04 (was a
        %   documented GAP stub) -- every input Casey's closure request
        %   covered is resolved:
        %     x_p = obj.geom.x_inlet [Raymer Eqs. 16.26-16.28, p.604, define
        %       F_p as specifically the INLET FRONT FACE normal force].
        %     z_t = 0, F_p = 0 [Raymer p.604/p.609 -- thrust axis near the
        %       c.g., commonly dropped in early conceptual design].
        %     delta_f = 0 [clean/cruise, no flap deflection -- the
        %       Cm_w,delta_f*delta_f term is then 0*(anything)=0].
        %     CL = obj.CL_w(alpha_deg) [Eq. 16.13, real].
        %     CL_h = obj.CL_h(alpha_deg, i_h_deg) [Eq. 16.14, real] -- takes
        %       i_h_deg as a REQUIRED caller argument, same reframing as
        %       obj.CL_h itself (all-moving stabilator, i_h IS the trim
        %       variable being solved for by a caller sweeping this method
        %       to zero, not a fixed spec constant).
        %     Cm_acw [Eq. 16.19, real -- see obj.Cm_acw's own header] --
        %       NaN until obj.Cm0_airfoil_wing is user-supplied, in which
        %       case this method RETURNS NaN rather than erroring (an
        %       honest "not yet computable" answer, not a crash) -- see
        %       f16a_L3.json .stability_control.Cm0_airfoil_wing.
        %   q (dynamic pressure) is passed as 1 -- irrelevant here since it
        %   only ever multiplies the T/F_p thrust terms, both 0.
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
        %NEUTRAL_POINT_BAR  Shared helper: computes the three MAC-fraction
        %   stations x_np/x_cg/x_acw need (Eq. 16.9 dropping the thrust
        %   term), avoiding triplicating the same eta_h/Sh_Sw/CL_alpha_tail
        %   assembly across get.x_np / get.SM / get.Cm_alpha.
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
