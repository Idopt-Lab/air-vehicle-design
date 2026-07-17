classdef F16GeomL1 < GeometryModelL1
%F16GEOML1  F-16A Block 10 Level-1 geometry student class.
%
%   Inherits from GeometryModelL1 (abstract enforcer).  Every abstract method
%   is satisfied by a single delegation line to GeomL1 statics — no formulas
%   are duplicated here.
%
%   SOURCES:
%     S_ref: T.O. 1F-16A-1, Flight Manual, Fig. 1-2 (300 ft^2)
%     aircraft_category: 'jet_fighter' — selects:
%       c = -0.1289, d = 0.7506  (Roskam Vol. I Table 3.5)
%       a = 0.93,    C = 0.39    (Raymer 6th ed. Table 6.3)

    properties
        % Both were declared Abstract in GeometryModelL1 — no validation allowed.
        aircraft_category = "jet_fighter"    % string; drives GeomL1 table lookups
        S_ref             = 300              % double; ft^2  [T.O. 1F-16A-1, Fig. 1-2]
        S_wet             = 0                % double; ft^2  — populated by get_S_wet(obj, W_TO)
        L_fuselage        = 0                % double; ft    — populated by get_L_fus(obj, W_TO)
        % TODO (7/8/2026): Try finding another way of estimating S_ref, or show a workflow for students to use at L1.
    end

    methods

        function obj = F16GeomL1()
            obj.aircraft_category = "jet_fighter";
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

    end
end
