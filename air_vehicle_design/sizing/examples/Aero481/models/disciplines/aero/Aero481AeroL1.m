classdef Aero481AeroL1 < AeroModelL1
%Aero481AEROL1  F-35A (Aero 481 Design01) Level-1 aerodynamics class.
%
%   Inherits AeroModelL1 (abstract enforcer). AeroModelL1 adds no abstract
%   members beyond AerodynamicsBase's drag_polar / get_CLmax.
%
%   This class combines the two existing L1 aero patterns:
%     * geometry-LIGHT, like F16AeroL1 -- the constructor takes NO injected
%       geometry object; AR and Lambda_LE_deg are two scalar wing-spec inputs
%       read directly from the .aerodynamics JSON block; and
%     * config TABLES, like B777AeroL1 -- CD0 and CLmax per high-lift config
%       come from the Design01 config tables (JSON dictionaries), NOT from the
%       Roskam type-curves the F-16 uses.
%
%   The clean drag polar uses the A03 MISSION clean CD0 = Cf*(Swet/S) =
%   0.0035*4 = 0.014 (CONSTANT). This is the value Aero 481's A03 mission burns
%   fuel against -- CD0 = Cf*Swet/S with Swet = 4*S makes Swet/S a constant 4, so
%   CD0 = Cfe*swet_over_sref is a fixed number and does NOT track wing area (no
%   geometry injection needed at this tier). [A481 Design01.m:36 Swet_Fxn = 4*S;
%   A03.m:60,65 CD0 = Cf*Swet/S]. This is the equivalent-skin-friction method
%   [metabook Eq. 4.8 = Raymer 6th ed. Eq. 12.23, CD0 = Cfe*(Swet/Sref)].
%
%   ===== A481 CLEAN-CD0 INCONSISTENCY (disc A1b) -- do NOT reconcile ==========
%   Aero 481 uses TWO DIFFERENT clean CD0 values for the F-35, and the framework
%   preserves BOTH faithfully:
%     * the MISSION (A03) uses CD0_clean = Cf*Swet/S = 0.014 [A03.m:60,65] -->
%       drag_polar returns this (the mission reads drag_polar);
%     * the CONSTRAINTS (+Constraints/*) instead read the config-table
%       CD0.Clean = 0.0236 [Design01.m:64] --> get_config_polar("clean") returns
%       this (the field-length / climb-gradient constraints read get_config_polar).
%   So drag_polar clean (0.014) INTENTIONALLY differs from
%   get_config_polar("clean") (0.0236). This is A481's OWN mission-vs-constraint
%   inconsistency, reproduced deliberately -- see aero481_discrepancies.md
%   A1b. Do NOT unify the two.
%   ==========================================================================
%
%   INDUCED-DRAG FACTOR K1 IS EQUATION-BASED, NOT A FROZEN CONSTANT. K1 =
%   1/(pi*AR*e), with e = AeroL2.oswald_eff(AR, Lambda_LE_deg) computed LIVE on
%   every read (Raymer 6th ed. Eq. 12.48 for Lambda_LE < 30 deg / Eq. 12.49 for
%   >= 30 deg). This keeps K1 optimization-ready: when an optimizer mutates AR
%   or Lambda_LE_deg, the next drag_polar reflects it. The frozen e_clean =
%   0.9153 field in the JSON is a READER'S convenience only (marked so in the
%   input .md); this class never reads it -- e is recomputed from AR/sweep.
%
%   The re-cite (disc A2): Aero 481's Utility.Oswald(AR) = 1.78*(1-0.045*
%   AR^0.68)-0.64 cites a web calculator (calculator.academy); that formula IS
%   Raymer 6th ed. Eq. 12.48 (the low-sweep branch of AeroL2.oswald_eff). So the
%   framework re-cites the A481 Oswald to [Raymer 6th ed. Eq. 12.48] and reuses
%   the shared AeroL2 static. At Lambda_LE < 30 deg the framework value equals
%   the A481 value (no sweep correction); if a real F-35 Lambda_LE >= 30 deg is
%   supplied, the framework applies Eq. 12.49 (A481 never does).
%
%   ===== NUMERICAL DISCREPANCY FLAGGED (do NOT silently reconcile) ===========
%   The scribe plan / input JSON assert AeroL2.oswald_eff(4, 0) = 0.9153. The
%   formula 1.78*(1-0.045*AR^0.68)-0.64 at AR=4 actually evaluates to ~0.9344
%   (4^0.68 = 2.56683 -> 1.78*0.884492 - 0.64 = 0.934395), confirmed against the
%   same formula TestAeroL2 validates at AR=8 (0.8105923). The documented 0.9153
%   corresponds to AR ~= 4.56, not 4 -- it appears to be a transcription error in
%   the F-35 docs. This class computes e LIVE (never the frozen 0.9153), so it
%   uses the correct ~0.9344 and the resulting K1 ~= 0.08516. The 0.9153 /
%   K1=0.08694 pairing in the docs must be corrected by the coordinator/scribe;
%   the aero equation here is right. See the report-back note.
%   ==========================================================================
%
%   K2 = 0 (uncambered-basis; no camber / CL_minD data at L1) -- Convention A
%   CD = CD0 + K1*CL^2 + K2*CL [Mattingly: Aircraft Engine Design, 2nd ed. Eq. 2.9].
%
%   aircraft_category = "jet_fighter": the mission analysis reads this off the
%   aero object (MissionAnalysisBase, isprop(aero,'aircraft_category')) to select
%   the fighter fixed-fraction MissionEquations row.
%
%   get_config_polar(config) overrides the AerodynamicsBase contract the FAR-25
%   field-length and climb-gradient constraints read: it returns
%   struct(CD0, K1, K2, CLmax) for each of the six FAR-25 high-lift configs,
%   reading the Design01 CD0/CLmax config dictionaries. All six share the same
%   live clean K1 and K2 = 0 (Design01 does not vary induced drag by config).
%
%   Inheritance: AerodynamicsBase -> AeroModelL1 -> Aero481AeroL1
%
%   Expected outputs at baseline AR = 4, Lambda_LE_deg = 0:
%     drag_polar(state): CD0 = Cfe*swet_over_sref = 0.0035*4 = 0.014 (constant)
%                                        [A481 A03.m:60,65; metabook Eq. 4.8];
%                        e   = 0.934395   [Raymer Eq. 12.48, AeroL2.oswald_eff];
%                        K1  = 1/(pi*4*0.934395) = 0.085165  [Raymer Eq. 12.50];
%                        K2  = 0.
%                        --> L/D_max = 1/(2*sqrt(CD0*K1)) = 14.48.
%     get_config_polar("clean").CD0 = 0.0236 (constant, config table, for the
%                        CONSTRAINTS -- intentionally != drag_polar, disc A1b).
%     get_CLmax(state):  1.8   [A481 Design01.m:59 CLmax.EN]
%     get_CLmax_TO:      2.0   [A481 CLmax.TO/.TS -- takeoff_flaps_gear_down]
%     get_CLmax_L:       2.6   [A481 CLmax.BA -- landing_flaps_gear_down]
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
%   Companion doc: examples/Aero481/models/disciplines/aero/Aero481AeroL1.md
%   Discrepancies: examples/Aero481/aero481_discrepancies.md (A1, A1b, A2, A5).

    % ======================================================================= %
    % INPUTS -- aircraft-type / Design01 spec data. All from the .aerodynamics
    % JSON block; mutable (an optimizer varies AR / Lambda_LE_deg). L1 owns NO
    % geometry object, so there are no Dependent geometry getters (contrast
    % B777AeroL1). The config dictionaries are read straight from the JSON --
    % they are pure Design01 tabulated inputs, not derived from AR, so unlike
    % B777AeroL1 there is no derive-once step for them.
    % ======================================================================= %
    properties
        aircraft_category  % string; canonical top-level class flag ("jet_fighter"). Read by the mission to pick the fighter fixed-fraction row.

        % Real wing spec scalars feeding the live Oswald / K1 (NOT an injected
        % geometry object -- same "Layer-2 wires in genuine spec data" pattern
        % as F16AeroL1). _TODO -- UNCITED (see class header / disc A5, A2).
        AR                 % --  wing aspect ratio  [A481 Design01.m:49]; _TODO -- UNCITED (publ. F-35A ~= 2.66, disc A5)
        Lambda_LE_deg      % deg wing leading-edge sweep  [F-35 planform, _TODO -- UNCITED; 0 reproduces A481's sweep-free Oswald, disc A2]

        % Equivalent skin-friction coefficient. USED by drag_polar: the clean
        % mission CD0 = Cfe*swet_over_sref (= 0.0035*4 = 0.014), the A03 mission
        % clean drag [A481 A03.m:60,65; metabook Eq. 4.8 = Raymer Eq. 12.23].
        % [Raymer Table 12.3 Air Force fighter; matches A481 Cf = 0.0035,
        % Design01.m:73].
        Cfe                % --  equivalent skin-friction coefficient

        % Wetted-area / reference-area ratio Swet/Sref feeding the clean mission
        % CD0 = Cfe*swet_over_sref. Aero 481's A03 mission uses Swet = 4*S
        % [A481 Design01.m:36 Swet_Fxn = @(S) 4*S], which makes Swet/S a CONSTANT
        % 4 (S-independent -- so CD0 needs no geometry injection). _TODO --
        % UNCITED: Swet = 4*S is A481's "I made this up" (Design01.m:35); kept
        % here ONLY for A03 mission fidelity, distinct from the geometry
        % wetted-area regression (Roskam Table 3.5) that REJECTS Swet=4*S (disc
        % A1). See aero481_discrepancies.md A1b.
        swet_over_sref     % --  Swet/Sref (= 4, A481 A03); _TODO -- UNCITED

        % Design01 config tables (dictionaries: config-name string -> double).
        % CD0_config(cfg) is the ABSOLUTE parasite CD0 for that config (NOT an
        % increment); the clean row is the constant used by drag_polar.
        %   [A481 Design01.m:55-68] -- _TODO -- UNCITED ("thank you Ian" /
        %   student values). Guarded by labelled testTODO until a primary source
        %   is pinned. The approach row is DERIVED (mean rule [A481 Climb.m:63]).
        CD0_config         % config string -> absolute clean-basis CD0
        CLmax_config       % config string -> max lift coefficient
    end

    methods

        function obj = Aero481AeroL1(json_path)
        %Aero481AEROL1  Construct from a required unified L1 input JSON path
        %   (aero481_spec_path(1)); reads its .aerodynamics block. No silent
        %   default: the path must be supplied. L1 takes NO injected geometry
        %   object (contrast B777AeroL1) -- AR/Lambda_LE_deg are genuine wing
        %   spec scalars read directly, same as every other Layer-2
        %   aircraft-specific input. The config dictionaries are read verbatim
        %   from the JSON (pure Design01 tables, not derived from AR).
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
        %DRAG_POLAR  CLEAN drag polar -- the A03 MISSION clean drag. state is
        %   unused at L1 (this clean polar has no Mach/altitude dependence -- CD0
        %   is a fixed number and the low-sweep Oswald is Mach-independent), so ~.
        %     CD0 = Cfe*swet_over_sref = 0.0035*4 = 0.014  (CONSTANT)
        %                                    [A481 A03.m:60,65; Design01.m:36 Swet=4*S;
        %                                     metabook Eq. 4.8 = Raymer Eq. 12.23]
        %     e   = AeroL2.oswald_eff(AR, Lambda_LE_deg)     [Raymer Eq. 12.48/12.49]
        %     K1  = 1/(pi*AR*e)  = AeroL2.K1_subsonic(e, AR) [Raymer Eq. 12.50]
        %     K2  = 0            (uncambered-basis; Convention A)
        %   At AR = 4, Lambda_LE_deg = 0: CD0 = 0.014, e = 0.934395,
        %   K1 = 0.085165 --> L/D_max = 1/(2*sqrt(0.014*0.085165)) = 14.48.
        %   K1 recomputes LIVE, so it tracks a mutated AR/sweep.
        %
        %   NOTE (disc A1b): this MISSION clean CD0 (0.014) INTENTIONALLY differs
        %   from get_config_polar("clean").CD0 (0.0236, the config table the
        %   CONSTRAINTS read). That is Aero 481's own mission-vs-constraint
        %   inconsistency (A03 uses Cf*Swet/S; +Constraints/* use Design01.CD0.Clean),
        %   reproduced faithfully -- do NOT reconcile the two.
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
        %   get_config_polar contract the FAR-25 field-length and climb-gradient
        %   constraints read. Reads the Design01 config dictionaries directly:
        %     CD0   = CD0_config(config)    [A481 Design01.m:64-68]
        %     K1    = live clean K1         [Raymer Eq. 12.50] (Design01 does
        %                                    not vary induced drag by config)
        %     K2    = 0
        %     CLmax = CLmax_config(config)  [A481 Design01.m:55-61]
        %   The approach row is the Design01 Climb-6/BO mean rule already baked
        %   into the JSON: CD0 = mean(takeoff_flaps_gear_down, landing_flaps_
        %   gear_down) = mean(0.0586, 0.1086) = 0.0836; CLmax = 2.6 (= BO)
        %   [A481 Climb.m:63]. _TODO -- UNCITED (config tables, disc rollup).
        %
        %   IMPORTANT (disc A1b): the "clean" row here is the CONSTRAINT clean CD0
        %   = 0.0236 (Design01 config table), which INTENTIONALLY differs from
        %   drag_polar's MISSION clean CD0 = 0.014 (Cf*Swet/S). The constraints
        %   read THIS config-table value; the mission reads drag_polar. This is
        %   Aero 481's own mission-vs-constraint inconsistency, preserved -- do
        %   NOT reconcile the two.
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
        % Let the F-35 also work with the MILITARY Takeoff/Landing constraints
        % and the mission (which call get_CLmax_TO/_L and get_Delta_CD0_TO/_L),
        % even though the FAR-25 path prefers get_config_polar. Takeoff => the
        % gear-down takeoff config; Landing => gear-down landing (F-16 pattern).

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
