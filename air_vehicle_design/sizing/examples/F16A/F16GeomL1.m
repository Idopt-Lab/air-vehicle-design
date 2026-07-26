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
%   first appear at L2).
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
        aircraft_category = "jet_fighter"    % string; drives GeomL1 table lookups
        S_ref             = 300              % double; ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        M_max             = 2.0              % double; design max Mach — drives get_AR_eq (Raymer 7th ed. Table 4.1)

        %W_TO  Takeoff gross weight, lbf. A genuine INPUT at this fidelity
        %   level: both L1 regressions (S_wet, L_fuselage) are functions of TOGW,
        %   which cannot be known from geometry at L1. Set it before reading
        %   S_wet/L_fuselage (the sizing loop mutates it between iterations);
        %   NaN until then, and the Dependent getters below say so explicitly
        %   rather than returning a plausible-looking number.
        W_TO              = NaN              % double; lbf
        % TODO (7/8/2026): Try finding another way of estimating S_ref, or show a workflow for students to use at L1.
    end

    % ======================================================================= %
    % DERIVED — recomputed live from the inputs on every read (no cache, never
    % stale), per the F16GeomL2 reference pattern (see CLAUDE.md).
    %
    % Both were plain properties initialised to 0 and commented "populated by
    % get_S_wet(obj, W_TO)" — but get_S_wet only ever RETURNED a value, it never
    % assigned, so both sat at 0 for the object's whole life. Since
    % F16AeroL2/F16AeroL3 accept any GeometryBase, injecting an F16GeomL1
    % constructed fine and then evaluated CD0 = Cfe*S_wet/S_ref = 0 — a silent
    % zero parasite drag and an infinite L/D, with no warning. Converted to
    % Dependent 2026-07-25.
    % ======================================================================= %
    properties (Dependent)
        S_wet          % ft^2  total wetted area  [Roskam Vol. I Table 3.5 regression on W_TO]
        L_fuselage     % ft    fuselage length    [Raymer 6th ed. Table 6.3 regression on W_TO]
    end

    methods

        function obj = F16GeomL1(json_path)
        %F16GEOML1  Construct from a required unified L1 input JSON path
        %   (f16a_spec_path(1)); reads its .geometry block. No silent default:
        %   the path must be supplied. S_ref is not a JSON input (see class
        %   header) and stays the pre-existing hardcoded literal.
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end
            G = jsondecode(fileread(json_path)).geometry;
            obj.aircraft_category = string(G.aircraft_category);
            obj.M_max             = G.M_max;
            obj.S_ref             = 300;
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
        % DERIVED-property getters — live from obj.W_TO on every read.
        % ================================================================== %

        function v = get.S_wet(obj)
            v = obj.get_S_wet(obj.requireWTO('S_wet'));
        end

        function v = get.L_fuselage(obj)
            v = obj.get_L_fus(obj.requireWTO('L_fuselage'));
        end

    end

    methods (Access = private)

        function W_TO = requireWTO(obj, whatFor)
        %REQUIREWTO  Return obj.W_TO, erroring if it has not been set.
        %   Both L1 derived quantities are TOGW regressions, so reading either
        %   before W_TO is known is a caller error, not a zero. Erroring here is
        %   the whole point of the 2026-07-25 Dependent conversion: the old plain
        %   properties returned 0, which propagated as a silent zero parasite
        %   drag through any aero object this geometry was injected into.
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
