classdef F16GeomL1 < GeometryModelL1
%F16GEOML1  F-16A Block 10 Level-1 geometry student class.
%
% Inherits from GeometryModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to GeomL1 statics — no formulas
%   are duplicated here.
%
% Constructor reads the .geometry block of a required unified L1 input JSON
%   (see f16a_spec_path(1); the same file's .aerodynamics block feeds
%   F16AeroL1).  
% L1 is a pure statistical/regression fidelity level: only
%   classification strings/scalars are JSON inputs (aircraft category, design
%   M_max) — no numeric F-16 planform dimensions exist at this tier (those
%   first appear at L2). 
% L1 has no tail sizing — tail sizing is a separate
%   discipline (see src/disciplines/tail_sizing/, e.g. F16TailL1 / F16TailL2).
%
%   SOURCES:
%     S_ref: T.O. 1F-16A-1, Flight Manual, Fig. 1-2 (300 ft^2) — NOT a JSON
%       input (deliberately excluded from the L1 .geometry block); kept as the
%       pre-existing hardcoded literal.
%     aircraft_category: 'jet_fighter' — selects:
%       c = -0.1289, d = 0.7506  (Roskam Vol. I Table 3.5)
%       a = 0.93,    C = 0.39    (Raymer 6th ed. Table 6.3)
%       a = 5.416,   C = -0.6222 (Raymer 7th ed. Table 4.1, "Jet fighter (dogfighter)" row, AR_eq)
%     M_max: 2.0 [VnV/BrandtF16A/GroundTruth/f16a_geometry.json aircraft.Mmax] — drives get_AR_eq.

    % ======================================================================= %
    % INPUTS — mutable spec data (see the DERIVED block below).
    % ======================================================================= %
    properties
        aircraft_category = "jet_fighter"    % string; drives GeomL1 table lookups
        % TODO (7/8/2026): Try finding another way of estimating S_ref, or show a workflow for students to use at L1.
        S_ref             = 300              % double; ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        M_max             = 2.0              % double; design max Mach — drives get_AR_eq (Raymer 7th ed. Table 4.1)
        n_engines         = 1               % double; engine count [Brandt Main!B28; f16a_L1.json .geometry.engine.n_engines]. Not used by any L1 geometry regression — exposed only so mission analysis can read geom.n_engines by DI at every fidelity (mission takeoff warmup term). Matches F16GeomL3.n_engines.

        %W_TO  Takeoff gross weight, lbf. A genuine INPUT at L1: both regressions
        %   (S_wet, L_fuselage) are functions of TOGW. Set it before reading
        %   S_wet/L_fuselage; the sizing loop mutates it between iterations.
        W_TO              = NaN              % double; lbf
        
    end

    % ======================================================================= %
    % DERIVED — recomputed live from obj.W_TO on every read (no cache, never
    % stale). Both are TOGW regressions.
    % ======================================================================= %
    properties (Dependent)
        S_wet          % ft^2  total wetted area  [Roskam Vol. I Table 3.5 regression on W_TO]
        L_fuselage     % ft    fuselage length    [Raymer 6th ed. Table 6.3 regression on W_TO]
    end

    % ======================================================================= %
    % DERIVED. Regression on Mmax.
    % ======================================================================= %
    properties (Dependent)
        AR_eq          %       equivalent aspect ratio [Raymer 7th ed. Table 4.1, jet-fighter (dogfighter) row]
    end

    % ======================================================================= %
    % DERIVED. 
    % ======================================================================= %
    properties (Dependent)
        c_e          %       elevator chord ratio [Raymer 7th ed. Table 6.5, jet-fighter row]
        c_r          %       rudder chord ratio [Raymer 7th ed. Table 6.5, jet-fighter row]
    end

    methods

        function obj = F16GeomL1(json_path, req_path)
        %F16GEOML1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)) plus the requirements JSON path
        %   (f16a_requirements_path()). No silent defaults. S_ref is not a JSON
        %   input (see class header) and stays the hardcoded literal. M_max is a
        %   design requirement (design_mach in the requirements file) and feeds
        %   GeomL1.compute_AR_eq (Raymer 7th ed. Table 4.1).
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

        function val = get_c_e(obj)
            val = GeomL1.lookup_control_surface_fraction(obj.aircraft_category, "elevator");
        end

        function val = get_c_r(obj)
            val = GeomL1.lookup_control_surface_fraction(obj.aircraft_category, "rudder");
        end

        % ================================================================== %
        % getters 
        % ================================================================== %

        function v = get.AR_eq(obj)
            v = obj.get_AR_eq();
        end

        function v = get.c_e(obj)
            v = obj.get_c_e();
        end

        function v = get.c_r(obj)
            v = obj.get_c_r();
        end

        % ================================================================== %
        % DERIVED-property getters — live from obj.W_TO on every read.
        % ================================================================== %

        function v = get.S_wet(obj)
            v = obj.get_S_wet(obj.requireWTO('S_wet'));
        end

        function v = get.L_fuselage(obj)
            v = obj.get_L_fus_statistical(obj.requireWTO('L_fuselage'));
        end        

        % ================================================================== %
        % Required class to satisfy abstract class GeometryBase
        % ================================================================== %
        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

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
