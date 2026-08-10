classdef LoiterSegment < MasterEquationSegment
%LOITERSEGMENT  L2 time-given leg (loiter, and the zero-duration patrol
%   waypoints). Time is simply the given time_min. A patrol with time_min = 0
%   at unchanged conditions yields zero drag fuel and zero energy fuel, i.e. a
%   ~0-lb burn -- a computed result for a bookkeeping waypoint, not an omission.

    methods
        function t = segment_time(obj, ~)
            t = obj.time_min;
        end
    end
end
