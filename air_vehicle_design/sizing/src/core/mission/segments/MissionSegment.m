classdef (Abstract) MissionSegment < handle
%MISSIONSEGMENT  Abstract base for one leg of a mission profile.
%
%   Mission analogue of PointPerformanceBase: one object per segment, each
%   responsible for its own fuel burn and carrying the weight before/after.
%
%   CONTRACT. Every concrete segment implements
%       fuel = fuel_burn(obj, ctx)      % fuel burned in this leg [lbf]
%   The base template step() sets W_before, calls fuel_burn, and sets
%   W_after = W_before - fuel - drop_lb. The returned/accumulated fuel EXCLUDES
%   the payload drop; step() subtracts both, so the drop is never counted as
%   fuel. MissionAnalysisBase.total_fuel calls step() once per segment.
%
%   ctx is the run context MissionAnalysisBase.build_context assembles (aero/
%   prop/geom handles, W_TO, aircraft_category, n_engines, and the mission-
%   requirement scalars).
%
%   Flight condition: alt_end_ft/mach_end are the END waypoint; alt_start_ft/
%   mach_start are the previous segment's end. FixedFractionSegment ignores it.

    properties
        name          (1,1) string = ""     % segment label, e.g. "Cruise"
        segment_type  (1,1) string = ""     % dispatch key, e.g. "cruise"

        alt_start_ft  (1,1) double = NaN     % ft   altitude at START (prev seg end)
        alt_end_ft    (1,1) double = NaN     % ft   altitude at END
        mach_start    (1,1) double = NaN     %      Mach at START
        mach_end      (1,1) double = NaN     %      Mach at END

        distance_nm   (1,1) double = NaN     % nmi  given range (cruise/dash/egress)
        time_min      (1,1) double = NaN     % min  given duration (loiter/combat/patrol)
        drop_lb       (1,1) double = 0       % lbf  payload jettisoned during the leg
        percent_ab    (1,1) double = 0       %      afterburner setting 0-100
        cd0_increment (1,1) double = 0       %      en-route external-stores CD0 add
    end

    properties (SetAccess = protected)
        W_before      (1,1) double = NaN     % lbf  weight entering the segment
        W_after       (1,1) double = NaN     % lbf  weight leaving the segment
        debug         (1,1) struct = struct()% per-segment diagnostics (L/D, TSFC, ...)
    end

    methods (Abstract)
        %FUEL_BURN  Fuel burned in this segment [lbf], given the run context.
        %   Implementations read obj.W_before (already set by step) and the ctx
        %   discipline objects; they should populate obj.debug with the key
        %   intermediates (L/D, TSFC, ...) for the comparison report.
        fuel = fuel_burn(obj, ctx)
    end

    methods

        function fuel = step(obj, W_before, ctx)
        %STEP  Run this segment: set W_before, compute fuel, set W_after.
        %   Returns fuel burned [lbf] (payload drop NOT included). W_after
        %   subtracts both fuel and drop_lb (the physical weight leaving).
            obj.W_before = W_before;
            fuel = obj.fuel_burn(ctx);
            if ~isfinite(fuel) || fuel < 0
                error('MissionSegment:invalidFuel', ...
                    ['Segment "%s" (type "%s") produced invalid fuel %g lbf. ', ...
                     'Likely a Mach in the transonic drag-rise band (NaN drag ', ...
                     'polar), a Mach-0 condition (zero airspeed), or a missing ', ...
                     'distance_nm/time_min in the profile.'], ...
                    obj.name, obj.segment_type, fuel);
            end
            obj.W_after = W_before - fuel - obj.drop_lb;
        end

        function state = end_state(obj)
        %END_STATE  AircraftState at the end-of-segment waypoint.
            state = AircraftState(obj.alt_end_ft, obj.mach_end);
        end

        function state = start_state(obj)
        %START_STATE  AircraftState at the start-of-segment waypoint.
            state = AircraftState(obj.alt_start_ft, obj.mach_start);
        end

    end

end
