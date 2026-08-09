classdef CruiseSegment < MasterEquationSegment
%CRUISESEGMENT  L2 distance-given leg (cruise / dash / egress / cruise2).
%   Time comes from the given range and the end-of-segment true airspeed:
%     t_min = distance_nm * 6080 / V_end / 60   [Brandt Miss-tab generic form].
%   The MasterEquationSegment base then applies the drag-fuel term over this
%   time plus the energy term if the leg gains altitude/speed (e.g. Egress
%   climbs 25000 -> 40000 ft, so it carries both a drag and an energy term).

    methods
        function t = segment_time(obj, ~)
            V_end = obj.end_state().V;
            t = obj.distance_nm * MissionEquations.NM_TO_FT / V_end / 60;
        end
    end
end
