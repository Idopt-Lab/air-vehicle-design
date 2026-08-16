classdef Aero481AeroL1 < AeroModelL1
%Aero481AEROL1  F-35A (Aero 481 Design01) Level-1 aerodynamics class.
%
%   Inherits AeroModelL1 (abstract enforcer, no members beyond
%   AerodynamicsBase's drag_polar / get_CLmax). Equations live in the AeroL2
%   toolbox; this class supplies Design01 spec data and delegates.
%
%   Geometry-light like F16AeroL1 (AR and Lambda_LE_deg are scalar wing-spec
%   inputs, no injected geometry) plus config tables like B777AeroL1 (CD0/CLmax
%   per high-lift config from the Design01 JSON dictionaries).
%
%   drag_polar clean CD0 = Cfe*swet_over_sref = 0.0035*4 = 0.014 (CONSTANT), the
%   A03 mission clean drag [A481 A03.m:60,65; Design01.m:36 Swet=4*S; metabook
%   Eq. 4.8 = Raymer 6th ed. Eq. 12.23]. Swet/S = 4 is S-independent, so CD0
%   does not track wing area and no geometry injection is needed.
%
%   K1 = 1/(pi*AR*e) with e = AeroL2.oswald_eff(AR, Lambda_LE_deg) computed LIVE
%   [Raymer 6th ed. Eq. 12.48 for Lambda_LE < 30 deg / Eq. 12.49 for >= 30 deg;
%   K1 via Eq. 12.50], so K1 tracks a mutated AR/sweep. K2 = 0 (uncambered-basis,
%   Convention A) [Mattingly: Aircraft Engine Design 2nd ed. Eq. 2.9].
%
%   drag_polar clean CD0 (0.014, MISSION) INTENTIONALLY differs from
%   get_config_polar("clean").CD0 (0.0236, config table read by the CONSTRAINTS):
%   Aero 481's own mission-vs-constraint inconsistency, disc A1b. Do NOT unify.
%
%   aircraft_category = "jet_fighter": the mission reads it (MissionAnalysisBase,
%   isprop(aero,'aircraft_category')) to pick the fighter fixed-fraction row.
%
%   get_config_polar(config) overrides the AerodynamicsBase contract the FAR-25
%   field-length and climb-gradient constraints read: struct(CD0, K1, K2, CLmax)
%   per config, from the Design01 CD0/CLmax dictionaries; all six share the live
%   clean K1 and K2 = 0.
%
%   Baseline (AR = 4, Lambda_LE_deg = 0): drag_polar CD0 = 0.014, e = 0.934395,
%   K1 = 0.085165 --> L/D_max = 14.48. get_config_polar("clean").CD0 = 0.0236.
%   get_CLmax = 1.8 [CLmax.EN]; get_CLmax_TO = 2.0; get_CLmax_L = 2.6.
%
%   Inheritance: AerodynamicsBase -> AeroModelL1 -> Aero481AeroL1
%   History and rationale: docs/decision_log.md; companion .md; discrepancies
%   examples/Aero481/aero481_discrepancies.md (A1, A1b, A2, A5). The frozen JSON
%   e_clean = 0.9153 is not read here (a docs transcription error; live e ~=
%   0.9344, K1 ~= 0.08516).
%
%   SOURCES:
%     [A481] University of Michigan AEROSP 481 (Fall 2024) starter code by Max
%       Arnson (design PROVENANCE, not a primary source),
%       docs/reference_extracts/aero481_data.md Part II. CD0 config table
%       [Design01.m:64-68]; CLmax config table [Design01.m:55-61]; AR
%       [Design01.m:49]; approach mean rule [Climb.m:63].
%     [Raymer] Raymer 6th ed. -- Oswald Eq. 12.48/12.49 (via AeroL2.oswald_eff);
%       K1 = 1/(pi*AR*e) Eq. 12.50 (via AeroL2.K1_subsonic).
%     [Mattingly] Aircraft Engine Design 2nd ed. Eq. 2.9 -- CD = CD0+K1*CL^2+K2*CL.

    % ======================================================================= %
    % INPUTS -- Design01 spec data from the .aerodynamics JSON block; mutable
    % (an optimizer varies AR / Lambda_LE_deg). No injected geometry object, so
    % no Dependent geometry getters (contrast B777AeroL1). The config
    % dictionaries are read verbatim (Design01 tables, not derived from AR).
    % ======================================================================= %
    properties
        aircraft_category  % string; canonical top-level class flag ("jet_fighter"). Read by the mission to pick the fighter fixed-fraction row.

        % Wing spec scalars feeding the live Oswald / K1 (F16AeroL1 pattern).
        AR                 % --  wing aspect ratio  [A481 Design01.m:49]; _TODO -- UNCITED (publ. F-35A ~= 2.66, disc A5)
        Lambda_LE_deg      % deg wing leading-edge sweep  [F-35 planform, _TODO -- UNCITED; 0 reproduces A481's sweep-free Oswald, disc A2]

        % Equivalent skin-friction coefficient; USED by drag_polar for the clean
        % mission CD0 = Cfe*swet_over_sref [Raymer Table 12.3 Air Force fighter;
        % matches A481 Cf = 0.0035, Design01.m:73].
        Cfe                % --  equivalent skin-friction coefficient

        % Swet/Sref feeding the clean mission CD0. Swet = 4*S [A481 Design01.m:36]
        % makes this a CONSTANT 4. _TODO -- UNCITED: kept for A03 mission fidelity
        % only, distinct from the geometry Swet regression (Roskam Table 3.5,
        % disc A1). See aero481_discrepancies.md A1b.
        swet_over_sref     % --  Swet/Sref (= 4, A481 A03); _TODO -- UNCITED

        % Design01 config tables (dictionaries: config string -> double).
        % CD0_config(cfg) is the ABSOLUTE parasite CD0; the clean row is used by
        % drag_polar. [A481 Design01.m:55-68] _TODO -- UNCITED, testTODO-guarded.
        % The approach row is DERIVED (mean rule [A481 Climb.m:63]).
        CD0_config         % config string -> absolute clean-basis CD0
        CLmax_config       % config string -> max lift coefficient
    end

    methods

        function obj = Aero481AeroL1(json_path)
        %Aero481AEROL1  Construct from a required unified L1 input JSON path
        %   (aero481_spec_path(1)); reads its .aerodynamics block. No silent
        %   default. No injected geometry object (contrast B777AeroL1).
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            A = J.aerodynamics;

            % ONE canonical top-level category key (mirrors F16AeroL1 /
            % B777AeroL1) -- selects the fighter mission fixed-fraction row.
            obj.aircraft_category = string(J.aircraft_category);

            obj.AR             = A.AR;              % [A481 Design01.m:49]; _TODO -- UNCITED (disc A5)
            obj.Lambda_LE_deg  = A.Lambda_LE_deg;   % [F-35 planform]; _TODO -- UNCITED (disc A2)
            obj.Cfe            = A.Cfe;             % [Raymer Table 12.3]; feeds clean mission CD0
            obj.swet_over_sref = A.swet_over_sref;  % [A481 A03, Swet=4*S]; _TODO -- UNCITED (disc A1b)

            % Config tables read verbatim from the JSON dictionaries. The JSON
            % decodes each as a struct (field per config); convert to a keyed
            % dictionary so lookups are by the canonical config string.
            obj.CD0_config   = Aero481AeroL1.struct_to_dict(A.CD0_config);   % [A481 Design01.m:64-68]; _TODO -- UNCITED
            obj.CLmax_config = Aero481AeroL1.struct_to_dict(A.CLmax_config); % [A481 Design01.m:55-61]; _TODO -- UNCITED
        end

        % ---- Core contract (base) ----------------------------------------- %
        function polar = drag_polar(obj, ~)
        %DRAG_POLAR  CLEAN drag polar -- the A03 MISSION clean drag. state
        %   unused at L1 (no Mach/altitude dependence).
        %     CD0 = Cfe*swet_over_sref = 0.0035*4 = 0.014  (CONSTANT)
        %                                    [A481 A03.m:60,65; Design01.m:36 Swet=4*S;
        %                                     metabook Eq. 4.8 = Raymer Eq. 12.23]
        %     e   = AeroL2.oswald_eff(AR, Lambda_LE_deg)     [Raymer Eq. 12.48/12.49]
        %     K1  = 1/(pi*AR*e)  = AeroL2.K1_subsonic(e, AR) [Raymer Eq. 12.50]
        %     K2  = 0            (uncambered-basis; Convention A)
        %   At AR = 4, Lambda_LE_deg = 0: CD0 = 0.014, K1 = 0.085165, L/D_max =
        %   14.48. This MISSION CD0 (0.014) INTENTIONALLY differs from
        %   get_config_polar("clean").CD0 (0.0236), disc A1b -- do NOT reconcile.
            CD0 = obj.Cfe * obj.swet_over_sref;                    % [A481 A03.m:60,65; metabook Eq. 4.8 = Raymer Eq. 12.23]
            e   = AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg);    % [Raymer Eq. 12.48/12.49]
            K1  = AeroL2.K1_subsonic(e, obj.AR);                   % [Raymer Eq. 12.50]
            polar = struct('CD0', CD0, 'K1', K1, 'K2', 0);
        end

        function CLmax = get_CLmax(obj, ~)
        %GET_CLMAX  Clean (en-route) maximum lift coefficient = 1.8
        %   [A481 Design01.m:59 CLmax.EN]. state unused (config-independent
        %   clean value). _TODO -- UNCITED (Design01 student value).
            CLmax = obj.CLmax_config("clean");
        end

        % ---- Per-config polar (AerodynamicsBase get_config_polar) --------- %
        function cfg = get_config_polar(obj, config)
        %GET_CONFIG_POLAR  Drag polar + CLmax for a named high-lift config.
        %   Returns struct(CD0, K1, K2, CLmax) -- overrides the AerodynamicsBase
        %   contract the FAR-25 field-length / climb-gradient constraints read.
        %     CD0   = CD0_config(config)    [A481 Design01.m:64-68]
        %     K1    = live clean K1         [Raymer Eq. 12.50]
        %     K2    = 0
        %     CLmax = CLmax_config(config)  [A481 Design01.m:55-61]
        %   The approach row is the Design01 Climb-6/BO mean rule baked into the
        %   JSON: CD0 = 0.0836, CLmax = 2.6 [A481 Climb.m:63]. _TODO -- UNCITED.
        %   The "clean" row here (0.0236) INTENTIONALLY differs from drag_polar's
        %   MISSION clean CD0 (0.014), disc A1b -- do NOT reconcile.
            arguments
                obj
                config (1,1) string {mustBeMember(config, ...
                    ["clean", ...
                     "takeoff_flaps_gear_up", "takeoff_flaps_gear_down", ...
                     "landing_flaps_gear_up", "landing_flaps_gear_down", ...
                     "approach"])}
            end
            e   = AeroL2.oswald_eff(obj.AR, obj.Lambda_LE_deg);   % [Raymer Eq. 12.48/12.49]
            K1  = AeroL2.K1_subsonic(e, obj.AR);                  % [Raymer Eq. 12.50]
            cfg = struct( ...
                'CD0',   obj.CD0_config(config), ...              % [A481 Design01.m:64-68]
                'K1',    K1, ...
                'K2',    0, ...
                'CLmax', obj.CLmax_config(config));               % [A481 Design01.m:55-61]
        end

        % ---- Thin wrappers over the config table -------------------------- %
        % For the MILITARY Takeoff/Landing constraints and the mission (which
        % call get_CLmax_TO/_L and get_Delta_CD0_TO/_L). Takeoff => gear-down
        % takeoff config; Landing => gear-down landing (F-16 pattern).

        function v = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Takeoff-config max lift = 2.0
        %   [A481 Design01.m CLmax.TO/.TS -- takeoff_flaps_gear_down]. _TODO -- UNCITED.
            v = obj.CLmax_config("takeoff_flaps_gear_down");
        end

        function v = get_CLmax_L(obj)
        %GET_CLMAX_L  Landing-config max lift = 2.6
        %   [A481 Design01.m CLmax.BA -- landing_flaps_gear_down]. _TODO -- UNCITED.
            v = obj.CLmax_config("landing_flaps_gear_down");
        end

        function v = get_Delta_CD0_TO(obj)
        %GET_DELTA_CD0_TO  Takeoff-config parasite-drag increment over clean
        %   (gear-down takeoff row): CD0_config(TO gear-down) - CD0_config(clean)
        %   = 0.0586 - 0.0236 = 0.0350  [A481 Design01.m:64-68]. _TODO -- UNCITED.
            v = obj.CD0_config("takeoff_flaps_gear_down") - obj.CD0_config("clean");
        end

        function v = get_Delta_CD0_L(obj)
        %GET_DELTA_CD0_L  Landing-config parasite-drag increment over clean
        %   (gear-down landing row): CD0_config(landing gear-down) - CD0_config(clean)
        %   = 0.1086 - 0.0236 = 0.0850  [A481 Design01.m:64-68]. _TODO -- UNCITED.
            v = obj.CD0_config("landing_flaps_gear_down") - obj.CD0_config("clean");
        end

    end

    methods (Static, Access = private)

        function d = struct_to_dict(s)
        %STRUCT_TO_DICT  Convert a jsondecode'd config struct (one field per
        %   config name -> double) into a keyed dictionary(string -> double), so
        %   lookups use the canonical config strings the constraints pass.
            d = dictionary;
            names = string(fieldnames(s))';
            for name = names
                d(name) = s.(name);
            end
        end

    end

end
