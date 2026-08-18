classdef Aero481GeomL1 < GeometryModelL1
%Aero481GEOML1  F-35 (Aero 481 provenance) Level-1 geometry student class.
%
%   Inherits GeometryModelL1 (abstract enforcer). Every abstract method is a
%   single delegation to a GeomL1 static -- no formulas duplicated here. Mirrors
%   F16GeomL1 (both are fighter L1 statistical geometry classes). L1 is a pure
%   statistical/regression tier: S_wet and fuselage length are regressions on
%   takeoff gross weight, so the only inputs are classification strings and a
%   few scalars (planform dimensions first appear at L2). Tail sizing is a
%   separate discipline (Aero481TailL1).
%
%   DESIGN PROVENANCE: University of Michigan AEROSP 481 (Fall 2024) starter
%   code by Max Arnson (Design01/A03) -- design PROVENANCE, NOT a primary
%   source. Each A481 value carries an [A481 <file>] tag plus a primary re-cite
%   where one exists, else _TODO -- UNCITED.
%
%   Swet = 4*S is REJECTED (disc A1): A481 Design01.m:33-36 is uncited and
%   self-inconsistent. S_wet here is the cited Roskam Vol. I Table 3.5
%   jet-fighter regression on TOGW (GeomL1.lookup_swet), a Dependent on W_TO.
%
%   History and rationale: docs/decision_log.md; companion .md; discrepancies
%   examples/Aero481/aero481_discrepancies.md (A1-A9).
%
%   SOURCES:
%     aircraft_category: 'jet_fighter' -- selects:
%       c = -0.1289, d = 0.7506  (Roskam Vol. I Table 3.5, S_wet)
%       a = 0.93,    C = 0.39    (Raymer 6th ed. Table 6.3, L_fuselage)
%       a = 5.416,   C = -0.6222 (Raymer 7th ed. Table 4.1, "Jet fighter
%                                 (dogfighter)" row, AR_eq)
%     M_max: design Mach [examples/Aero481/inputs/aero481_requirements.json
%       design_mach] -- drives get_AR_eq.
%
%   _TODO -- UNCITED inputs (each testTODO-guarded; see the INPUTS block and
%   companion .md): AR = 4 [A481 Design01.m:49] (disc A5), S_ref = 460 (disc
%   A5), Lambda_LE_deg = 0 (disc A2).

    % ======================================================================= %
    % INPUTS -- mutable spec data an optimizer varies (see the DERIVED block
    % below). Set once by the constructor from the JSON, then read/mutated by
    % the sizing loop.
    % ======================================================================= %
    properties
        aircraft_category = "jet_fighter"  % string; drives GeomL1 table lookups
        AR                = 4              % double; wing aspect ratio [A481 Design01.m:49]. _TODO -- UNCITED (publ. F-35A ~= 2.66; discrepancy A5).
        S_ref             = 460            % double; ft^2; publ. F-35A wing-area stand-in [aero481_data.md Part I]. _TODO -- UNCITED (Design01 fixes W/S = 92.17 psf, not S_ref; see Aero481GeomL1.md section 1.3).
        Lambda_LE_deg     = 0             % double; deg; wing LE sweep. _TODO -- UNCITED (unset/0 = A481's sweep-free Oswald; discrepancy A2).
        M_max             = 1.6           % double; design max Mach -- drives get_AR_eq (Raymer 7th ed. Table 4.1) [aero481_requirements.json design_mach].
        n_engines         = 1             % double; engine count [A481 NEng=1; aero481_data.md Part I, single F135-PW-100]. Not used by any L1 geometry regression -- exposed only so mission analysis can read geom.n_engines by DI at every fidelity (mission takeoff warmup term). Mirrors F16GeomL1.n_engines.

        %L_fus_ft  FIXED published fuselage length, ft -- the tail-arm reference
        %   the T-S diagram reads via L_fus BEFORE the weight closure sets W_TO,
        %   so it must NOT depend on W_TO. Distinct from the W_TO-based
        %   L_fuselage regression (get_L_fus_statistical, Raymer 6th ed. Table 6.3).
        L_fus_ft          = 50.5          % double; ft; publ. F-35A fuselage length [aero481_data.md Part I]. _TODO -- UNCITED. FIXED tail-arm reference; NOT the W_TO regression.

        %S_ht, S_vt  Tail-area write-back slots, ft^2, for TSDiagram.converge_W0
        %   to prescribe a (T,S) cell. At L1 weights are pure fractions
        %   (Aero481WeightsL1, no tail delta), so these feed NOTHING into OEW.
        S_ht              = NaN           % double; ft^2; horizontal-tail area write-back slot (T-S-diagram only; feeds nothing at L1).
        S_vt              = NaN           % double; ft^2; vertical-tail area write-back slot (T-S-diagram only; feeds nothing at L1).

        %W_TO  Takeoff gross weight, lbf. A genuine INPUT here: both L1
        %   regressions (S_wet, L_fuselage) are functions of TOGW. The sizing
        %   loop mutates it; NaN until set (the Dependent getters error if unset).
        W_TO              = NaN            % double; lbf
    end

    % ======================================================================= %
    % DERIVED -- recomputed live on every read (no cache), per the F16GeomL1
    % pattern (CLAUDE.md "Optimization-ready property design"). Read-only.
    % S_wet/L_fuselage are TOGW regressions, so reading either before W_TO is
    % set errors (private requireWTO) rather than returning a silent zero.
    % ======================================================================= %
    properties (Dependent)
        S_wet          % ft^2  total wetted area  [Roskam Vol. I Table 3.5 jet_fighter regression on W_TO] -- REPLACES A481 Swet=4*S (A1)
        L_fuselage     % ft    fuselage length    [Raymer 6th ed. Table 6.3 jet_fighter regression on W_TO]
        AR_eq          %       equivalent aspect ratio [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]

        % --- T-S-diagram tail-resize planform members ------------------------ %
        % Arguments TSDiagram.converge_W0 passes to obj.tail.size(...); none
        % depends on W_TO (read before the weight closure sets it).
        b_wing         % ft    span = sqrt(AR*S_ref) [definitional, GeometryBase.compute_span]
        cbar_wing      % ft    standard mean chord = S_ref/b_wing [definitional]
        L_fus          % ft    fixed tail-arm reference = L_fus_ft (publ. length; NOT the W_TO L_fuselage regression)
    end

    methods

        function obj = Aero481GeomL1(json_path, req_path)
        %Aero481GEOML1  Construct from a required L1 input JSON (aero481_L1.json)
        %   plus the requirements JSON (aero481_requirements.json). No silent
        %   defaults. The .geometry block supplies AR, S_ref, Lambda_LE_deg,
        %   n_engines; the top-level aircraft_category selects discipline-table
        %   rows; M_max is the requirements design_mach, feeding GeomL1.compute_AR_eq
        %   (Raymer 7th ed. Table 4.1).
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                req_path  {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            % ONE canonical top-level category key (selects rows in several tables).
            obj.aircraft_category = string(J.aircraft_category);

            % .geometry block -- the true L1 geometry spec inputs.
            G = J.geometry;
            obj.AR            = G.AR;
            obj.S_ref         = G.S_ref;
            obj.Lambda_LE_deg = G.Lambda_LE_deg;
            obj.n_engines     = G.n_engines;
            obj.L_fus_ft      = G.L_fus_ft;   % FIXED tail-arm reference (see property comment)

            % M_max is a design requirement, read from the requirements file.
            R = jsondecode(fileread(req_path));
            obj.M_max         = R.design_mach;
        end

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        % ================================================================== %
        % Computations that call the GeomL1 toolbox
        % ================================================================== %
        function val = get_whole_aircraft_S_wet_statistical(obj, W_TO)
            val = GeomL1.compute_s_wet_regression(obj.aircraft_category, W_TO);
        end

        function val = get_L_fus_statistical(obj, W_TO)
            val = GeomL1.compute_l_fus_regression(obj.aircraft_category, W_TO);
        end

        function val = get_AR_eq(obj)
            val = GeomL1.compute_AR_eq(obj.aircraft_category, obj.M_max);
        end

        % ================================================================== %
        % getters 
        % ================================================================== %

        function v = get.AR_eq(obj)
            v = obj.get_AR_eq();
        end

        % ================================================================== %
        % DERIVED-property getters -- live from obj.W_TO on every read.
        % ================================================================== %

        function v = get.S_wet(obj)
            v = obj.get_S_wet(obj.requireWTO('S_wet'));
        end

        function v = get.L_fuselage(obj)
            v = obj.get_L_fus_statistical(obj.requireWTO('L_fuselage'));
        end

        % ================================================================== %
        % T-S-diagram tail-resize getters -- live from the (mutated) inputs,
        % none W_TO-dependent (the T-S diagram reads them before W_TO is set).
        % ================================================================== %

        function v = get.b_wing(obj)
            % Span b = sqrt(AR*S_ref) [definitional, GeometryBase.compute_span].
            v = GeometryBase.compute_span(obj.AR, obj.S_ref);
        end

        function v = get.cbar_wing(obj)
            % Standard mean chord = S_ref/b_wing [definitional].
            v = obj.S_ref / obj.b_wing;
        end

        function v = get.L_fus(obj)
            % FIXED published length (tail-arm reference), NOT the L_fuselage regression.
            v = obj.L_fus_ft;
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set. Both L1
        %   derived quantities are TOGW regressions, so reading either before
        %   W_TO is known is a caller error (a silent zero would propagate as
        %   zero parasite drag).
            W_TO = obj.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('Aero481GeomL1:WTONotSet', ...
                    ['%s is a Level-1 statistical regression on takeoff gross ', ...
                     'weight, so obj.W_TO must be set to a positive value first ', ...
                     '(currently %g). Assign it from the sizing loop''s current ', ...
                     'TOGW iterate, e.g. geom.W_TO = 65900.'], whatFor, W_TO);
            end
        end

    end
end
