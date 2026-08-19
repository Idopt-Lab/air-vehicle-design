classdef F16GeomL1 < GeometryModelL1
%F16GEOML1  F-16A Block 10 Level-1 geometry student class.
%
%   Inherits from GeometryModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to GeomL1 statics — no formulas
%   are duplicated here.
%
%   Constructor reads the .geometry block of a required unified L1 input JSON
%   (see f16a_spec_path(1); the same file's .aerodynamics block feeds
%   F16AeroL1).  L1 is a pure statistical/regression fidelity level: only
%   classification strings/scalars are JSON inputs (aircraft category, design
%   M_max) — no numeric F-16 planform dimensions exist at this tier (those
%   first appear at L2). L1 has no tail sizing — tail sizing is a separate
%   discipline (see src/disciplines/tail_sizing/, e.g. F16TailL1 / F16TailL2).
%
%   SOURCES:
%     S_ref: T.O. 1F-16A-1, Flight Manual, Fig. 1-2 (300 ft^2) — NOT a JSON
%       input (deliberately excluded from the L1 .geometry block); kept as the
%       pre-existing hardcoded literal.
%     aircraft_category: 'jet_fighter' — selects:
%       c = -0.1289, d = 0.7506  (Roskam Vol. I Table 3.5)
%       a = 0.93,    C = 0.39    (Raymer 6th ed. Table 6.3)
%       a = 5.416,   C = -0.6222 (Raymer 7th ed. Table 4.1, "Jet fighter
%                                 (dogfighter)" row, AR_eq)
%     M_max: 2.0 [VnV/BrandtF16A/GroundTruth/f16a_geometry.json
%       aircraft.Mmax] — drives get_AR_eq.

    % ======================================================================= %
    % INPUTS — mutable spec data (see the DERIVED block below).
    % ======================================================================= %
    properties
        % TODO (8/13/2026): These should be dependency injections, not hardcoded properties.
        aircraft_category = "jet_fighter"    % string; drives GeomL1 table lookups
        S_ref             = 300              % double; ft^2  [T.O. 1F-16A-1, Fig. 1-2] % TODO (8/13/2026): This should not be hardcoded into the class.
        M_max             = 2.0              % double; design max Mach — drives get_AR_eq (Raymer 7th ed. Table 4.1)
        n_engines         = 1               % double; engine count [Brandt Main!B28; f16a_L1.json .geometry.engine.n_engines]. Not used by any L1 geometry regression — exposed only so mission analysis can read geom.n_engines by DI at every fidelity (mission takeoff warmup term). Matches F16GeomL3.n_engines.

        %W_TO  Takeoff gross weight, lbf. A genuine INPUT at L1: both regressions
        %   (S_wet, L_fuselage) are functions of TOGW. Set it before reading
        %   S_wet/L_fuselage; the sizing loop mutates it between iterations.
        W_TO              = NaN              % double; lbf
        % TODO (7/8/2026): Try finding another way of estimating S_ref, or show a workflow for students to use at L1.
    end

    % ======================================================================= %
    % DERIVED — recomputed live from obj.W_TO on every read (no cache, never
    % stale). Both are TOGW regressions.
    % ======================================================================= %
    properties (Dependent)
        % TODO (8/13/2026): Unsure if these are actually dependency injections or just data storage.
        S_wet          % ft^2  total wetted area  [Roskam Vol. I Table 3.5 regression on W_TO]
        L_fuselage     % ft    fuselage length    [Raymer 6th ed. Table 6.3 regression on W_TO]
    end

    methods

        function obj = F16GeomL1(json_path, req_path)
        %F16GEOML1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)) plus the requirements JSON path
        %   (f16a_requirements_path()). No silent defaults. S_ref is not a JSON
        %   input (see class header) and stays the hardcoded literal. M_max is a
        %   design requirement (design_mach in the requirements file) and feeds
        %   GeomL1.get_AR_eq (Raymer 7th ed. Table 4.1).
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
                req_path  {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            J = jsondecode(fileread(json_path));
            % ONE canonical top-level category key: it selects rows in several
            % discipline tables, so it belongs to no single block.
            obj.aircraft_category = string(J.aircraft_category);
            R = jsondecode(fileread(req_path));
            obj.M_max             = R.design_mach;
            obj.S_ref             = 300;
            % n_engines: read from the spec when present; single-engine default
            % otherwise. Exposed for mission DI, not used by L1 geometry.
            if isfield(J, 'geometry') && isfield(J.geometry, 'engine') ...
                    && isfield(J.geometry.engine, 'n_engines')
                obj.n_engines = J.geometry.engine.n_engines;
            end
        end

        % TODO (8/17/2026)(Casey): I'm unsure about obtaining S_ref at L1, without the sizing loop running at least once, unless it's an initial guess.
        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet_statistical(obj, W_TO)
            [c, d] = GeomL1.lookup_swet(obj.aircraft_category); % Looks up the coefficients (Roskam Vol I, Table 3.5)
            val = GeomL1.compute_s_wet_regression(c, d, W_TO); % Computes the S_wet of the whole design (Roskam, Vol I, eq ???)
        end

        % TODO (8/13/20206): Duplicate method function, but needed to satisfy the enforcer.
        % Mod (08/17/2026) (Claude)
        % function val = get_S_wet_statistical(obj, W_TO)
        %     val = obj.get_S_wet(W_TO);
        % end

        % TODO (8/14/2026): I'm noticing a lot of steps between the initial function call and the final result being returned.
        % This is concerning. Estimating the fuselage length via regression takes this path:
        % F16GeomL1.get_L_fus -> GeomL1.get_L_fus -> GeomL1.compute_l_fus_regression -> GeomL1.lookup_lfus -> return to compute_l_fus_regression, compute the the l_fus, return it to the call source..
        % In the legacy code, I believe I was able to bundle the table lookup AND the equation in the same function.
        % Ideally, the path should be: F16GeomL1.get_L_fus, calls a table lookup for the coefficients, then calls another toolbox method to estimate the fuselage length.
        % The function "compute_l_fus_regression" is what "get_L_fus" should look like. However, I'd make some changes. The psuedocode would look like this:
        % function l_fus = compute_l_fus_regression(aircraft_category, W_TO)
        %       [a, c] = GeomL1.lookup_l_fus_coeffs(aircraft_category)
        %       l_fus = GeomL1.est_l_fus(a, c, W_TO)
        % end
        % Mod (08/17/2026) (Claude)
        function val = get_L_fus(obj, W_TO)
            [a, c] = GeomL1.lookup_lfus(obj.aircraft_category); % Looks up the coefficients (Raymer 6th ed., Table 6.3)
            val = GeomL1.compute_l_fus_regression(a, c, W_TO);  % Computes the fuselage length (Raymer 6th ed., Table 6.3 power law)
        end

        % TODO (8/17/2026)(Casey): This is a wrapper that should be calling an explicit method function
        % from GeomL1 which should not be accepting "obj" as an argument. It should be accepting explicit
        % variables as arguments.
        % Mod (08/17/2026) (Claude)
        function val = get_AR_eq(obj)
            [a, C] = GeomL1.lookup_AR_eq(obj.aircraft_category); % Looks up the coefficients (Raymer 7th ed., Table 4.1, dogfighter row)
            val = GeomL1.compute_AR_eq(a, C, obj.M_max);         % Computes the equivalent aspect ratio from design Mach
        end

        % ================================================================== %
        % DERIVED-property getters — live from obj.W_TO on every read.
        % ================================================================== %

        function v = get.S_wet(obj)
            v = obj.get_S_wet(obj.requireWTO('S_wet'));
        end

        function v = get.L_fuselage(obj)
            v = obj.get_L_fus(obj.requireWTO('L_fuselage'));
        end

        % % TODO (8/13/20206): Duplicate method function; remove.
        % function v = get.S_wet(obj)
        %     v = obj.get_S_wet(obj.requireWTO('S_wet'));
        % end

        % TODO (8/13/20206): Duplicate method function; remove.
        % function v = get.L_fuselage(obj)
        %     v = obj.get_L_fus(obj.requireWTO('L_fuselage'));
        % end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Both L1 derived quantities are TOGW regressions, so reading either
        %   before W_TO is known is a caller error, not a silent zero (which
        %   would propagate as zero parasite drag into an injected aero object).
            W_TO = obj.W_TO;
            if ~isfinite(W_TO) || W_TO <= 0
                error('F16GeomL1:WTONotSet', ...
                    ['%s is a Level-1 statistical regression on takeoff gross ', ...
                     'weight, so obj.W_TO must be set to a positive value first ', ...
                     '(currently %g). Assign it from the sizing loop''s current ', ...
                     'TOGW iterate, e.g. geom.W_TO = 31377.'], whatFor, W_TO);
            end
        end

    end
end
