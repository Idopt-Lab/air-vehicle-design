classdef F16GeomL1 < GeometryModelL1
%F16GEOML1  F-16A Block 10 Level-1 geometry student class.
%
%   Inherits from GeometryModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to GeomL1 statics — no formulas
%   are duplicated here.
%
%   Constructor loads examples/F16A/geometry_L1.json by default (override by
%   passing an explicit path).  L1 is a pure statistical/regression fidelity
%   level: only classification strings/scalars are JSON inputs (aircraft
%   category, design M_max) — no numeric F-16 planform dimensions exist at
%   this tier (those first appear at L2).
%
%   SOURCES:
%     S_ref: T.O. 1F-16A-1, Flight Manual, Fig. 1-2 (300 ft^2) — NOT part of
%       geometry_L1.json (deliberately excluded, see the JSON's own
%       "_comment"); kept as the pre-existing hardcoded literal.
%     aircraft_category: 'jet_fighter' — selects:
%       c = -0.1289, d = 0.7506  (Roskam Vol. I Table 3.5)
%       a = 0.93,    C = 0.39    (Raymer 6th ed. Table 6.3)
%       a = 5.416,   C = -0.6222 (Raymer 7th ed. Table 4.1, "Jet fighter
%                                 (dogfighter)" row, AR_eq)
%     M_max: 2.0 [VnV/BrandtF16A/GroundTruth/f16a_geometry.json
%       aircraft.Mmax] — drives get_AR_eq.

    properties
        % Both were declared Abstract in GeometryModelL1 — no validation allowed.
        aircraft_category = "jet_fighter"    % string; drives GeomL1 table lookups
        S_ref             = 300              % double; ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        S_wet             = 0                % double; ft^2  — populated by get_S_wet(obj, W_TO)
        L_fuselage        = 0                % double; ft    — populated by get_L_fus(obj, W_TO)
        M_max             = 2.0              % double; design max Mach — drives get_AR_eq (Raymer 7th ed. Table 4.1)
        % TODO (7/8/2026): Try finding another way of estimating S_ref, or show a workflow for students to use at L1.
    end

    methods

        function obj = F16GeomL1(json_path)
        %F16GEOML1  Construct from examples/F16A/geometry_L1.json (default)
        %   or an explicit override path. S_ref is not part of that JSON
        %   (see class header) and stays the pre-existing hardcoded literal.
            if nargin == 0
                json_path = fullfile(fileparts(mfilename('fullpath')), 'geometry_L1.json');
            end
            J = jsondecode(fileread(json_path));
            obj.aircraft_category = string(J.aircraft_category);
            obj.M_max             = J.M_max;
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

    end
end
