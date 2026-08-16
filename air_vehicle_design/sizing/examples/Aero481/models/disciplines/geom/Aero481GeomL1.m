classdef Aero481GeomL1 < GeometryModelL1
%Aero481GEOML1  F-35 (Aero 481 provenance) Level-1 geometry student class.
%
%   Inherits from GeometryModelL1 (abstract enforcer). Every abstract method
%   is satisfied by a single delegation line to GeomL1 statics -- no formulas
%   are duplicated here. Mirrors F16GeomL1 exactly (both are fighter L1
%   statistical geometry classes).
%
%   Constructor reads the .geometry block of a required unified L1 input JSON
%   (examples/Aero481/inputs/aero481_L1.json; the same file's .aerodynamics block
%   feeds Aero481AeroL1), plus the requirements JSON
%   (examples/Aero481/inputs/aero481_requirements.json) for the design Mach. L1 is a
%   pure statistical/regression fidelity level: wetted area and fuselage
%   length are regressions on takeoff gross weight, so the only true geometry
%   inputs are classification strings and a few scalars -- no numeric planform
%   dimensions exist at this tier (those first appear at L2). L1 has no tail
%   sizing -- tail sizing is a separate discipline (see
%   src/disciplines/tail_sizing/, e.g. Aero481TailL1 / F16TailL1).
%
%   DESIGN PROVENANCE: University of Michigan AEROSP 481 (Fall 2024) starter
%   code by Max Arnson (Design01/A03) -- design PROVENANCE, NOT a primary
%   source. Every A481 value carries an [A481 <file>] tag plus a primary
%   re-citation where one exists, else _TODO -- UNCITED. See
%   examples/Aero481/aero481_scribe_plan.md and
%   examples/Aero481/aero481_discrepancies.md (A1-A9).
%
%   THE Swet = 4*S REJECTION (discrepancy A1). A481 Design01.m:33-36 sets the
%   wetted area from wing area with "% I made this up" -- uncited AND
%   self-inconsistent (A03.m:60-61 is unsure area-vs-weight). It is REJECTED.
%   S_wet here is the cited Roskam Vol. I Table 3.5 jet-fighter regression on
%   TOGW (GeomL1.lookup_swet), so it is a Dependent on W_TO, NOT a wing-area
%   multiple. See Aero481GeomL1.md section 1.4 for the quoted A481 source.
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
%   _TODO -- UNCITED inputs (each guarded by a labelled testTODO; see the
%   INPUTS block below and Aero481GeomL1.md section 6):
%     AR            = 4     [A481 Design01.m:49] student value; publ. F-35A
%                           AR ~= 2.66 (35 ft span, 460 ft^2) -- discrepancy A5.
%     S_ref         = 460   published F-35A wing-area stand-in [aero481_data.md
%                           Part I]; NOT a Design01 input (Design01 fixes the
%                           design point W/S = 92.17 psf, not S_ref -- the
%                           design-point back-solve S_ref = W_TO / 92.17 is a
%                           sizing-loop output). See Aero481GeomL1.md section 1.3.
%     Lambda_LE_deg = 0     wing LE sweep; unset/0 reproduces A481's sweep-free
%                           Oswald exactly -- discrepancy A2. Consumed by
%                           Aero481AeroL1 (oswald_eff), carried here for the
%                           complete planform spec.

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

        %L_fus_ft  FIXED published fuselage length, ft. The tail-arm reference
        %   the T-S diagram's tail-resize box reads. TSDiagram.converge_W0 reads
        %   geom.L_fus (the Dependent alias below) BEFORE the weight closure sets
        %   W_TO, so this reference must NOT depend on W_TO. It is therefore a
        %   fixed spec INPUT, deliberately distinct from the W_TO-based
        %   L_fuselage regression (get_L_fus, Raymer 6th ed. Table 6.3), which
        %   stays the GeometryModelL1 contract quantity.
        L_fus_ft          = 50.5          % double; ft; publ. F-35A fuselage length [aero481_data.md Part I]. _TODO -- UNCITED (published stand-in). FIXED tail-arm reference for the T-S-diagram tail resize; NOT the W_TO regression.

        %S_ht, S_vt  Tail-area write-back slots, ft^2. Present ONLY so
        %   TSDiagram.converge_W0 can prescribe a (T,S) cell: after setting
        %   S_ref it resizes the tail and writes the results back
        %   (obj.geom.S_ht = ...; obj.geom.S_vt = ...). At L1 the weights are
        %   PURE historical fractions (Aero481WeightsL1, no tail delta), so these
        %   areas feed NOTHING into OEW -- they exist solely for the T-S diagram
        %   to prescribe the cell. NaN until the resize writes them.
        S_ht              = NaN           % double; ft^2; horizontal-tail area write-back slot (T-S-diagram only; feeds nothing at L1).
        S_vt              = NaN           % double; ft^2; vertical-tail area write-back slot (T-S-diagram only; feeds nothing at L1).

        %W_TO  Takeoff gross weight, lbf. A genuine INPUT at this fidelity
        %   level: both L1 regressions (S_wet, L_fuselage) are functions of
        %   TOGW, which geometry cannot know at L1. Set it before reading
        %   S_wet/L_fuselage (the sizing loop mutates it between iterations);
        %   NaN until then, and the Dependent getters below say so explicitly
        %   rather than returning a plausible-looking number.
        W_TO              = NaN            % double; lbf
    end

    % ======================================================================= %
    % DERIVED -- recomputed live from the inputs on every read (no cache, never
    % stale), per the F16GeomL1 / F16GeomL2 reference pattern (see CLAUDE.md
    % "Optimization-ready property design"). Read-only: assigning to one errors,
    % which is correct -- they are outputs.
    %
    % S_wet REPLACES the rejected A481 Swet = 4*S (discrepancy A1). Both are
    % TOGW regressions, so reading either before W_TO is set errors (via the
    % private requireWTO) rather than returning a silent zero -- an unset
    % S_wet would propagate as CD0 = Cfe*S_wet/S_ref = 0 (zero parasite drag,
    % infinite L/D) through any aero object this geometry is injected into.
    % ======================================================================= %
    properties (Dependent)
        S_wet          % ft^2  total wetted area  [Roskam Vol. I Table 3.5 jet_fighter regression on W_TO] -- REPLACES A481 Swet=4*S (A1)
        L_fuselage     % ft    fuselage length    [Raymer 6th ed. Table 6.3 jet_fighter regression on W_TO]

        % --- T-S-diagram tail-resize planform members ------------------------ %
        % b_wing/cbar_wing/L_fus are the arguments TSDiagram.converge_W0 passes
        % to obj.tail.size(...) when it resizes the tail for a prescribed (T,S)
        % cell. None depends on W_TO: the T-S diagram reads them BEFORE the
        % weight closure sets W_TO. b_wing/cbar_wing are generic wing identities
        % that recompute live from the (mutated) S_ref; L_fus is the fixed
        % published length alias (see L_fus_ft above), NOT the W_TO regression.
        b_wing         % ft    span = sqrt(AR*S_ref) [definitional, GeometryBase.compute_span]
        cbar_wing      % ft    standard mean chord = S_ref/b_wing [definitional]
        L_fus          % ft    fixed tail-arm reference = L_fus_ft (publ. length; NOT the W_TO L_fuselage regression)
    end

    methods

        function obj = Aero481GeomL1(json_path, req_path)
        %Aero481GEOML1  Construct from a required unified L1 input JSON path
        %   (aero481_L1.json) plus the requirements JSON path
        %   (aero481_requirements.json). No silent defaults: both must be supplied.
        %
        %   The .geometry block supplies AR, S_ref, Lambda_LE_deg, n_engines.
        %   The one canonical top-level aircraft_category selects rows in every
        %   discipline table (it belongs to no single block). M_max is a design
        %   REQUIREMENT, not airframe spec data, so it comes from the
        %   requirements file's design_mach and feeds GeomL1.get_AR_eq
        %   (Raymer 7th ed. Table 4.1). This mirrors F16GeomL1's two-path
        %   constructor and the requirements-vs-spec split.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                req_path  {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            % ONE canonical top-level category key: it selects rows in several
            % different discipline tables, so it belongs to no single block.
            obj.aircraft_category = string(J.aircraft_category);

            % .geometry block -- the true L1 geometry spec inputs.
            G = J.geometry;
            obj.AR            = G.AR;
            obj.S_ref         = G.S_ref;
            obj.Lambda_LE_deg = G.Lambda_LE_deg;
            obj.n_engines     = G.n_engines;
            % FIXED published fuselage length -- the T-S-diagram tail-arm
            % reference (read before W_TO is set), distinct from the W_TO-based
            % L_fuselage regression.
            obj.L_fus_ft      = G.L_fus_ft;

            % M_max is a design requirement, read from the requirements file.
            R = jsondecode(fileread(req_path));
            obj.M_max         = R.design_mach;
        end

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, W_TO)
            val = GeomL1.get_S_wet_statistical(obj, W_TO);
        end

        function val = get_S_wet_statistical(obj, W_TO)
            val = GeomL1.get_S_wet_statistical(obj, W_TO);
        end

        function val = get_L_fus(obj, W_TO)
            val = GeomL1.get_L_fus(obj, W_TO);
        end

        function val = get_AR_eq(obj)
            val = GeomL1.get_AR_eq(obj);
        end

        % ================================================================== %
        % DERIVED-property getters -- live from obj.W_TO on every read.
        % ================================================================== %

        function v = get.S_wet(obj)
            v = obj.get_S_wet(obj.requireWTO('S_wet'));
        end

        function v = get.L_fuselage(obj)
            v = obj.get_L_fus(obj.requireWTO('L_fuselage'));
        end

        % ================================================================== %
        % T-S-diagram tail-resize getters -- live from the (mutated) inputs,
        % none W_TO-dependent (the T-S diagram reads them before W_TO is set).
        % ================================================================== %

        function v = get.b_wing(obj)
            % Span from AR and reference area: b = sqrt(AR*S_ref)
            % [definitional, GeometryBase.compute_span]. Recomputes live from
            % S_ref so a T-S-diagram S_ref sweep is reflected immediately.
            v = GeometryBase.compute_span(obj.AR, obj.S_ref);
        end

        function v = get.cbar_wing(obj)
            % Standard mean chord = S_ref/b_wing [definitional].
            v = obj.S_ref / obj.b_wing;
        end

        function v = get.L_fus(obj)
            % FIXED published fuselage length (tail-arm reference), NOT the
            % W_TO-based L_fuselage regression. Deliberately W_TO-free: the
            % T-S diagram reads it before the weight closure sets W_TO.
            v = obj.L_fus_ft;
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Both L1 derived quantities are TOGW regressions, so reading either
        %   before W_TO is known is a caller error, not a zero. Erroring here
        %   keeps an unset S_wet from propagating as a silent zero parasite
        %   drag through any aero object this geometry is injected into.
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
