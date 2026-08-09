classdef (Abstract) MissionSegment < handle
%MISSIONSEGMENT  Abstract base for one leg of a mission profile.
%
%   Mission analogue of PointPerformanceBase (constraint analysis): one object
%   per mission segment, each responsible for its own fuel burn and carrying the
%   weight before/after the leg. Inspired by NPTEL_Fighter_Aircraft_Sizing's
%   segment decomposition and VnV/BrandtF16A/BrandtMission.m's per-segment loop.
%
%   CONTRACT. Every concrete segment implements
%       fuel = fuel_burn(obj, ctx)      % fuel burned in this leg [lbf]
%   and the base provides the template method
%       fuel = step(obj, W_before, ctx) % set W_before, call fuel_burn,
%                                        % set W_after = W_before - fuel - drop_lb
%   The aggregator (MissionAnalysisBase.total_fuel) calls step() once per
%   segment, threading W_before -> W_after. Centralizing the payload-drop
%   bookkeeping in step() -- W_after subtracts BOTH fuel AND drop_lb, but the
%   returned/accumulated fuel excludes the drop -- removes the drop/fuel
%   double-count that is easy to get wrong per-segment.
%
%   ctx is the run context struct the aggregator builds once per total_fuel call:
%     .aero .prop .geom              injected discipline objects (handles)
%     .W_TO                          fixed takeoff gross weight this run [lbf]
%     .aircraft_category             read from .aero (spec data)
%     .n_engines                     read from .geom (spec data)
%     .warmup_fuel_per_engine_lb .mu_rolling .mu_braking
%     .liftoff_factor .approach_factor            mission-requirement scalars
%
%   Flight condition: alt_end_ft/mach_end are the END-of-segment waypoint;
%   alt_start_ft/mach_start are the previous segment's end (threaded by the
%   aggregator's assembly). end_state()/start_state() build the AircraftState.
%   FixedFractionSegment ignores the flight condition entirely.

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
