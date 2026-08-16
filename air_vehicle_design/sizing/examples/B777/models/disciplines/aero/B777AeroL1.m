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
%     (1) INPUTS -- aero spec data (Cfe, e_clean, aircraft_category) plus the
%         per-config scalars (ΔCD0, e, CLmax) DERIVED ONCE from the config-polar
%         table + baseline AR (functions of the JSON alone, so freezing them is
%         correct).
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
%     CD0_clean = 0.0026*(28291/4605) ~ 0.01597   [metabook Eq. 4.8/4.58]
%     K1_clean  = 1/(pi*9.8*0.85)     ~ 0.03821    [metabook Eq. 2.10]
%     get_config_polar reproduces the five metabook polars + approach.
%
%   SOURCES:
%     [metabook] AE481 metabook Example 4.2, docs/reference_extracts/
%       metabook_data.md. Cfe [Eq. 4.43 / Raymer Table 12.3]; CD0=Cf*Swet/Sref
%       [Eq. 4.8]; Swet=Swet_rest+2S [Eq. 4.58]; K1=1/(pi*AR*e) [Eq. 2.10];
%       config polars [§4.11 five-polar table]; approach [§4.11 Climb 6 note];
%       CLmax [Roskam Table 3.1].

    % ======================================================================= %
    % INPUTS -- aero-only spec data (mutable; from the unified L1 JSON's
    % .aerodynamics block) + derived-once config scalars. NO live geometry here
    % (see the Dependent block below).
    % ======================================================================= %
    properties
        geom                 % injected geometry object (all live geometry read from it)

        aircraft_category    % canonical class flag ("jet_transport"); read by the mission to pick the transport fixed-fraction row

        Cfe        = 0.0026  % equivalent skin-friction coefficient [Raymer Table 12.3 civil transport; metabook Eq. 4.43]
        e_clean    = 0.85    % clean-config Oswald efficiency [metabook Table 4.2]; sets the live clean K1 = 1/(pi*AR*e_clean)

        %DELTA_CD0_CONFIG, E_CONFIG, CLMAX_CONFIG  Per-config scalars DERIVED ONCE
        %   in the constructor from the JSON config-polar table + baseline AR
        %   (functions of the JSON alone). Keyed dictionaries: config -> scalar.
        %     Delta_CD0_config(cfg) = table.CD0[cfg] - table.CD0[clean]
        %     e_config(cfg)         = 1/(pi*AR_baseline*table.K1[cfg])
        %     CLmax_config(cfg)     = table.CLmax[cfg]  (PHYSICAL values)
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
        %   No silent defaults. Sets the aero inputs and derives the per-config
        %   scalars ONCE; live geometry comes from the Dependent getters.
            arguments
                geom      (1,1) GeometryBase
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            obj.geom = geom;

            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;
            obj.aircraft_category = string(J.aircraft_category);   % top-level canonical key
            obj.Cfe               = A.Cfe;                         % [Raymer Table 12.3; metabook Eq. 4.43]
            obj.e_clean           = A.e_clean;                     % [metabook Table 4.2]

            % Derive the per-config scalars ONCE from the printed table (depend
            % on the JSON + baseline AR, not live geometry).
            AR_baseline = geom.AR;
            T = A.config_polars;
            CD0_clean = T.clean.CD0;
            configs = string(fieldnames(T))';

            dCD0  = dictionary;   % string -> double, configured on first insert
            eCfg  = dictionary;
            CLm   = dictionary;
            for cfg = configs
                row = T.(cfg);
                dCD0(cfg) = row.CD0 - CD0_clean;                  % [metabook §4.11 config increment]
                % e implied by the printed K1 row: K1 = 1/(pi*AR*e) [metabook Eq. 2.10]
                eCfg(cfg) = 1 / (pi * AR_baseline * row.K1);
                CLm(cfg)  = row.CLmax;                             % PHYSICAL [Roskam Table 3.1]
            end
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

end
