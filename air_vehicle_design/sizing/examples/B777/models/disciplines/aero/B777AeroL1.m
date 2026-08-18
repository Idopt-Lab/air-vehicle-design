classdef B777AeroL1 < AeroModelL1
%B777AEROL1  Boeing 777-200LR Level-1 aerodynamics class (metabook Example 4.2).
%
%   Inherits AeroModelL1 (abstract enforcer, no members beyond
%   AerodynamicsBase's drag_polar / get_CLmax).
%
%   L1 is the geometry-COUPLED metabook drag polar. Unlike F16AeroL1
%   (geometry-FREE), B777AeroL1 INJECTS a geometry object so its clean CD0 tracks
%   a mutated wing area:
%       CD0_clean = Cfe * (S_wet / S_ref)   [metabook Eq. 4.8 = Raymer Eq. 12.23]
%   with geom.S_wet = S_wet_rest + 2*S_ref [metabook Eq. 4.58], so CD0 tracks S.
%
%   DEPENDENCY INJECTION + INPUT vs DERIVED (optimization-ready, as F16AeroL2).
%   The constructor takes a REQUIRED injected geometry object and a REQUIRED L1
%   JSON path (b777_spec_path(1); reads .aerodynamics). No silent defaults.
%     (1) INPUTS -- aero spec data: the ONLY genuine JSON aero inputs are the
%         three physical CLmax overrides (CLmax_clean/_takeoff/_landing) plus the
%         top-level aircraft_category (D10, USER decision 2026-08-14). Cfe and
%         e_clean are NO LONGER JSON inputs -- they are DERIVED in the constructor
%         from the shared read-only toolboxes, mirroring how F16AeroL1 hardcodes
%         no per-config number:
%           Cfe     = AeroL2.lookup_Cfe("civil_transport")   [Raymer Table 12.3]
%           e_clean = UPPER bound of AeroL1.Delta_CD0 clean e_osw row = 0.85
%                                                            [Roskam Table 3.6]
%         The per-config scalars (ΔCD0, e, CLmax) are likewise DERIVED ONCE from
%         AeroL1.Delta_CD0 (UPPER bound; F16 uses the mean) via the 6->4 config
%         map and the three CLmax overrides (functions of toolbox Constants +
%         JSON inputs + baseline AR alone, so freezing them is correct).
%     (2) DERIVED (Dependent) -- S_ref/S_wet/AR read LIVE from obj.geom (nothing
%         stored), so the next drag_polar reflects a mutated geometry.
%
%   aircraft_category = "jet_transport": the mission reads it (MissionAnalysisBase,
%   isprop(aero,'aircraft_category')) to pick the transport fixed-fraction row.
%
%   get_config_polar(config) overrides the AerodynamicsBase contract the FAR-25
%   field-length / climb-gradient constraints read: struct(CD0, K1, K2, CLmax)
%   per config, reproducing the five printed metabook polars plus the derived
%   approach polar; CD0/K1 track S and AR live.
%
%   PHYSICAL CLmax carried: 2.0 both takeoff, 2.6 both landing, 0.9 clean, 2.21
%   approach (USER decision, b777_L1.md §3.2). The climb D1 deviation is the
%   comparison report's concern, not hardcoded here.
%
%   Inheritance: AerodynamicsBase -> AeroModelL1 -> B777AeroL1
%
%   Expected outputs at baseline S=4605, AR=9.8 (fresh B777GeomL2):
%     Cfe       = AeroL2.lookup_Cfe("civil_transport") = 0.0026   [Raymer Table 12.3]
%     CD0_clean = 0.0026*(28291/4605) ~ 0.01597   [metabook Eq. 4.8/4.58]
%     K1_clean  = 1/(pi*9.8*0.85)     ~ 0.03821    [metabook Eq. 2.10]
%     get_config_polar reproduces the five metabook polars + approach.
%
%   SOURCES:
%     [metabook] AE481 metabook Example 4.2, docs/reference_extracts/
%       metabook_data.md. CD0=Cf*Swet/Sref [Eq. 4.8 = Raymer Eq. 12.23];
%       Swet=Swet_rest+2S [Eq. 4.58]; K1=1/(pi*AR*e) [Eq. 2.10]; approach
%       [§4.11 Climb 6 note].
%     [Raymer 6th ed.] Cfe [Table 12.3, civil_transport = 0.0026, via
%       AeroL2.lookup_Cfe].
%     [Roskam Vol. I] ΔCD0 and e_osw per config [Table 3.6, UPPER bound, via
%       AeroL1.Delta_CD0]; physical CLmax overrides [Table 3.1; USER decision
%       2026-08-14].

    % ======================================================================= %
    % INPUTS -- aero-only spec data (mutable) + derived-once config scalars. The
    % only genuine JSON aero inputs are aircraft_category (top-level) and the
    % three physical CLmax overrides; Cfe and e_clean are toolbox-DERIVED in the
    % constructor (D10), NOT read from JSON. NO live geometry here (see the
    % Dependent block below).
    % ======================================================================= %
    properties
        geom                 % injected geometry object (all live geometry read from it)

        aircraft_category    % canonical class flag ("jet_transport"); read by the mission to pick the transport fixed-fraction row; translated to "civil_transport" for the AeroL2.lookup_Cfe row

        % Cfe / e_clean are DERIVED in the constructor from the shared toolboxes
        % (D10) -- NO hardcoded literal default, so no back-calculated spec value
        % survives in the class. Still plain mutable properties (an optimizer may
        % override). Cfe = AeroL2.lookup_Cfe("civil_transport") [Raymer Table 12.3];
        % e_clean = UPPER bound of AeroL1.Delta_CD0 clean e_osw row [Roskam Table 3.6].
        Cfe        % equivalent skin-friction coefficient [Raymer Table 12.3 civil_transport]; DERIVED via AeroL2.lookup_Cfe
        e_clean    % clean-config Oswald efficiency [Roskam Table 3.6 upper bound]; sets the live clean K1 = 1/(pi*AR*e_clean)

        %DELTA_CD0_CONFIG, E_CONFIG, CLMAX_CONFIG  Per-config scalars DERIVED ONCE
        %   in the constructor from the shared toolbox tables + the three CLmax
        %   overrides + baseline AR (functions of toolbox Constants + JSON inputs,
        %   not of live geometry). Keyed dictionaries: config -> scalar.
        %     Delta_CD0_config(cfg) = UPPER bound of AeroL1.Delta_CD0 ΔCD0 column,
        %                             6->4 config map [Roskam Table 3.6]
        %     e_config(cfg)         = UPPER bound of AeroL1.Delta_CD0 e_osw column,
        %                             6->4 config map [Roskam Table 3.6]
        %     CLmax_config(cfg)     = the three CLmax_* overrides (PHYSICAL);
        %                             approach = 0.85*CLmax_landing [Roskam Table 3.1]
        Delta_CD0_config
        e_config
        CLmax_config
    end

    % ======================================================================= %
    % DERIVED -- geometry read live from obj.geom on every read (no cache, never
    % stale). Read-only (no set-methods). CD0 tracks S because geom.S_wet =
    % S_wet_rest + 2*S_ref; K1 tracks AR.
    % ======================================================================= %
    properties (Dependent)
        S_ref     % ft^2  wing reference area   <- geom.S_ref
        S_wet     % ft^2  total wetted area     <- geom.S_wet (= S_wet_rest + 2*S_ref)
        AR        % --    wing aspect ratio     <- geom.AR
    end

    methods

        function obj = B777AeroL1(geom, json_path)
        %B777AEROL1  Construct from a required injected geometry object and a
        %   required L1 input JSON path (b777_spec_path(1); reads .aerodynamics).
        %   No silent defaults. Reads the three physical CLmax overrides from
        %   JSON (the only genuine aero inputs, D10) and DERIVES Cfe, e_clean and
        %   the per-config scalars ONCE from the shared read-only toolboxes; live
        %   geometry comes from the Dependent getters.
            arguments
                geom      (1,1) GeometryBase
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            obj.geom = geom;

            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;
            obj.aircraft_category = string(J.aircraft_category);   % top-level canonical key

            % ---- Physical CLmax overrides -- the ONLY genuine aero JSON inputs
            % (a USER decision that deliberately deviates from the Roskam
            % transport_jet table row) [Roskam Table 3.1; USER decision 2026-08-14].
            CLmax_clean   = A.CLmax_clean;
            CLmax_takeoff = A.CLmax_takeoff;
            CLmax_landing = A.CLmax_landing;

            % ---- Cfe and e_clean -- DERIVED from the shared toolboxes (D10),
            % NOT read from JSON.
            obj.Cfe     = obj.cfe_from_category(obj.aircraft_category);  % [Raymer Table 12.3 civil_transport = 0.0026]
            obj.e_clean = obj.roskam_e_osw_upper("clean");              % [Roskam Table 3.6 clean e_osw upper = 0.85]

            % ---- Per-config scalars, DERIVED ONCE from the Roskam Table 3.6
            % UPPER bounds (via AeroL1.Delta_CD0) through the 6->4 config map, and
            % from the three CLmax overrides. Functions of toolbox Constants +
            % JSON inputs (not live geometry), so freezing them is correct.
            dCD0_TO   = obj.roskam_Delta_CD0_upper("takeoff_flaps");    % [Roskam Table 3.6] = 0.020
            dCD0_L    = obj.roskam_Delta_CD0_upper("landing_flaps");    % [Roskam Table 3.6] = 0.075
            dCD0_gear = obj.roskam_Delta_CD0_upper("landing_gear");     % [Roskam Table 3.6] = 0.025
            e_TO      = obj.roskam_e_osw_upper("takeoff_flaps");        % [Roskam Table 3.6] = 0.80
            e_L       = obj.roskam_e_osw_upper("landing_flaps");        % [Roskam Table 3.6] = 0.75

            % gear-down ΔCD0 = flap row + landing_gear upper bound; approach ΔCD0
            % = mean of the two gear-down deltas [metabook §4.11 Climb 6 note].
            dCD0_TO_gd = dCD0_TO + dCD0_gear;                           % = 0.045
            dCD0_L_gd  = dCD0_L  + dCD0_gear;                           % = 0.100
            dCD0_appr  = mean([dCD0_TO_gd, dCD0_L_gd]);                 % = 0.0725 [metabook §4.11 Climb 6 note]

            dCD0 = dictionary;   % string -> double, configured on first insert
            eCfg = dictionary;
            CLm  = dictionary;

            dCD0("clean")                    = 0;                       % clean = no increment [Roskam Table 3.6]
            dCD0("takeoff_flaps_gear_up")    = dCD0_TO;
            dCD0("takeoff_flaps_gear_down")  = dCD0_TO_gd;
            dCD0("landing_flaps_gear_up")    = dCD0_L;
            dCD0("landing_flaps_gear_down")  = dCD0_L_gd;
            dCD0("approach")                 = dCD0_appr;

            eCfg("clean")                    = obj.e_clean;             % = 0.85
            eCfg("takeoff_flaps_gear_up")    = e_TO;                    % = 0.80
            eCfg("takeoff_flaps_gear_down")  = e_TO;                    % = 0.80
            eCfg("landing_flaps_gear_up")    = e_L;                     % = 0.75
            eCfg("landing_flaps_gear_down")  = e_L;                     % = 0.75
            eCfg("approach")                 = e_L;                     % approach e = landing e [metabook §4.11 Climb 6 note]

            CLm("clean")                     = CLmax_clean;             % PHYSICAL [Roskam Table 3.1]
            CLm("takeoff_flaps_gear_up")     = CLmax_takeoff;
            CLm("takeoff_flaps_gear_down")   = CLmax_takeoff;
            CLm("landing_flaps_gear_up")     = CLmax_landing;
            CLm("landing_flaps_gear_down")   = CLmax_landing;
            CLm("approach")                  = 0.85 * CLmax_landing;    % approach CLmax = 0.85*landing [metabook §4.11 Climb 6 note]

            obj.Delta_CD0_config = dCD0;
            obj.e_config         = eCfg;
            obj.CLmax_config     = CLm;
        end

        % ---- Dependent geometry getters (live from obj.geom) -------------- %
        function v = get.S_ref(obj); v = obj.geom.S_ref; end
        function v = get.S_wet(obj); v = obj.geom.S_wet; end
        function v = get.AR(obj);    v = obj.geom.AR;    end

        % ---- Core contract (base) ----------------------------------------- %
        function polar = drag_polar(obj, ~)
        %DRAG_POLAR  CLEAN drag polar, tracking S live. state is unused at L1
        %   (no Mach/altitude dependence in the metabook clean polar), hence ~.
        %     CD0 = Cfe*(S_wet/S_ref)   [metabook Eq. 4.8/4.58, via
        %                                AeroL2.CD0_from_Cf; S_wet tracks S]
        %     K1  = 1/(pi*AR*e_clean)   [metabook Eq. 2.10]
        %     K2  = 0                   (uncambered-basis metabook polar)
        %   At baseline S=4605, AR=9.8: CD0 ~ 0.01597, K1 ~ 0.03821.
            CD0 = AeroL2.CD0_from_Cf(obj.Cfe, obj.S_wet, obj.S_ref);
            K1  = 1 / (pi * obj.AR * obj.e_clean);
            polar = struct('CD0', CD0, 'K1', K1, 'K2', 0);
        end

        function CLmax = get_CLmax(obj, ~)
        %GET_CLMAX  Clean maximum lift coefficient (0.9) [Roskam Table 3.1;
        %   metabook §4.11]. state unused (config-independent clean value).
            CLmax = obj.CLmax_config("clean");
        end

        % ---- Per-config polar (AerodynamicsBase get_config_polar) --------- %
        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Drag polar + CLmax for a named high-lift config.
        %   Returns struct(CD0, K1, K2, CLmax) -- overrides the AerodynamicsBase
        %   contract the FAR-25 field-length / climb-gradient constraints read.
        %   Tracks BOTH S and AR live:
        %     CD0 = CD0_clean_live + Delta_CD0_config(config)  [metabook §4.11]
        %     K1  = 1/(pi*AR_live*e_config(config))            [metabook Eq. 2.10]
        %     K2  = 0
        %     CLmax = CLmax_config(config)   (PHYSICAL [Roskam Table 3.1])
        %   At baseline S/AR reproduces the five printed metabook polars + approach.
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            clean_CD0_live = AeroL2.CD0_from_Cf(obj.Cfe, obj.S_wet, obj.S_ref);
            CD0   = clean_CD0_live + obj.Delta_CD0_config(config);
            K1    = 1 / (pi * obj.AR * obj.e_config(config));
            CLmax = obj.CLmax_config(config);
            cfg = struct('CD0', CD0, 'K1', K1, 'K2', 0, 'CLmax', CLmax);
        end

        % ---- Thin wrappers over the config table -------------------------- %
        % For the MILITARY Takeoff/Landing constraints and the mission (which
        % call get_CLmax_TO/_L and get_Delta_CD0_TO/_L). Takeoff => gear-down
        % takeoff config; Landing => gear-down landing.

        function v = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Takeoff-config max lift (2.0) [Roskam Table 3.1].
            v = obj.CLmax_config("takeoff_flaps_gear_down");
        end

        function v = get_CLmax_L(obj)
        %GET_CLMAX_L  Landing-config max lift (2.6) [Roskam Table 3.1].
            v = obj.CLmax_config("landing_flaps_gear_down");
        end

        function v = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Takeoff-config parasite-drag increment over clean
        %   (gear-down takeoff row) [metabook §4.11 config increment].
            v = obj.Delta_CD0_config("takeoff_flaps_gear_down");
        end

        function v = get_Delta_CD0_L(obj)
        %GET_DELTA_CD0_L  Landing-config parasite-drag increment over clean
        %   (gear-down landing row) [metabook §4.11 config increment].
            v = obj.Delta_CD0_config("landing_flaps_gear_down");
        end

    end

    methods (Access = private)
        % Private toolbox-lookup helpers, mirroring F16AeroL1's roskam_* helpers.
        % The ONLY difference from F16 is the range statistic (UPPER bound here,
        % vs F16's mean -- metabook Example 4.2 convention, D10) and the Cfe
        % category translation. Both read the SAME shared read-only toolbox
        % Constants/statics -- no edit to AeroL1.m / AeroL2.m.

        function val = roskam_Delta_CD0_upper(~, flapconfig)
        %ROSKAM_DELTA_CD0_UPPER  UPPER bound of AeroL1.Delta_CD0's "Delta_CD0"
        %   range for flapconfig [Roskam Vol. I Table 3.6]. (F16AeroL1 takes the
        %   mean of the same range; the B777 takes the upper bound -- D10.)
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = max(row.Delta_CD0{1});
        end

        function val = roskam_e_osw_upper(~, flapconfig)
        %ROSKAM_E_OSW_UPPER  UPPER bound of AeroL1.Delta_CD0's "e_osw" range for
        %   flapconfig [Roskam Vol. I Table 3.6]. (F16AeroL1 takes the mean of
        %   the same range; the B777 takes the upper bound -- D10.)
            T   = AeroL1.Delta_CD0;
            row = T(T.FlapConfig == flapconfig, :);
            val = max(row.e_osw{1});
        end

        function val = cfe_from_category(~, aircraft_category)
        %CFE_FROM_CATEGORY  Raymer Table 12.3 equivalent skin-friction Cfe for
        %   the aircraft type, via AeroL2.lookup_Cfe. Translates the canonical
        %   "jet_transport" key to that table's own printed row name
        %   "civil_transport" (mirroring AeroL1.to_CLmax_table_row's
        %   "jet_fighter -> fighter") -- do NOT rename the table row.
        %   [Raymer 6th ed. Table 12.3, civil_transport = 0.0026].
            switch string(aircraft_category)
                case "jet_transport"
                    row = "civil_transport";   % Raymer Table 12.3's own printed row name
                otherwise
                    row = string(aircraft_category);   % pass through; AeroL2.lookup_Cfe validates
            end
            val = AeroL2.lookup_Cfe(row);
        end

    end

end
