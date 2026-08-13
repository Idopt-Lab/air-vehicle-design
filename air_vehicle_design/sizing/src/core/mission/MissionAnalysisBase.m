classdef (Abstract) MissionAnalysisBase < handle
%MISSIONANALYSISBASE  Abstract aggregator for mission fuel analysis.
%
%   Cross-discipline analysis (like ConstraintAnalysis), NOT a per-aircraft
%   discipline: it is dependency-injected with the aerodynamics, propulsion, and
%   geometry objects, holds an ordered list of MissionSegment objects, and
%   returns the total fuel weight for a given takeoff gross weight.
%
%   The concrete fidelity subclasses (MissionAnalysisL1, MissionAnalysisL2)
%   supply only two things: a static build_segment(spec) that maps a segment
%   type to the concrete segment class for that fidelity, and a static
%   from_requirements(aero, prop, geom, req_path, profile_name) convenience
%   factory. Everything else -- the weight-threading loop, the reserve markup,
%   the run context, and the profile assembly -- lives here and is shared.
%
%   total_fuel(W_TO) re-runs the whole segment loop live off the injected
%   discipline objects; nothing is cached, so a sizing loop that mutates
%   aero/prop/geom in place sees fresh numbers on the next call.

    properties (SetAccess = protected)
        aero    % (1,1) AerodynamicsBase -- injected
        prop    % (1,1) PropulsionBase   -- injected
        geom    % (1,1) GeometryBase     -- injected
        segments (1,:) cell              % ordered MissionSegment objects

        % ── Mission-requirement scalars (from the profile's JSON block) ────── %
        reserve_fuel_fraction     (1,1) double = 0
        warmup_fuel_per_engine_lb (1,1) double = 0
        mu_rolling                (1,1) double = 0
        mu_braking                (1,1) double = 0
        liftoff_factor            (1,1) double = 1
        approach_factor           (1,1) double = 1
    end

    methods

        function obj = MissionAnalysisBase(aero, prop, geom, segments, scalars)
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                geom (1,1) GeometryBase
                segments (1,:) cell
                scalars (1,1) struct
            end
            for i = 1:numel(segments)
                if ~isa(segments{i}, 'MissionSegment')
                    error('MissionAnalysisBase:invalidSegment', ...
                        'segments{%d} must be a MissionSegment object.', i);
                end
            end
            obj.aero = aero;
            obj.prop = prop;
            obj.geom = geom;
            obj.segments = segments;

            obj.reserve_fuel_fraction     = MissionAnalysisBase.field_or(scalars, 'reserve_fuel_fraction', 0);
            obj.warmup_fuel_per_engine_lb = MissionAnalysisBase.field_or(scalars, 'warmup_fuel_per_engine_lb', 0);
            obj.mu_rolling                = MissionAnalysisBase.field_or(scalars, 'mu_rolling', 0);
            obj.mu_braking                = MissionAnalysisBase.field_or(scalars, 'mu_braking', 0);
            obj.liftoff_factor            = MissionAnalysisBase.field_or(scalars, 'liftoff_factor', 1);
            obj.approach_factor           = MissionAnalysisBase.field_or(scalars, 'approach_factor', 1);
        end

        function [W_fuel, breakdown] = total_fuel(obj, W_TO)
        %TOTAL_FUEL  Total mission fuel weight [lbf] at takeoff gross weight W_TO.
        %   Threads W_before -> W_after through every segment, summing the
        %   per-segment fuel (which EXCLUDES payload drop) into raw_burn, then
        %   marks it up by the reserve fuel fraction [Roskam Part I Eq. 2.14/2.15]:
        %     W_fuel = raw_burn * (1 + reserve_fuel_fraction).
        %   The ~6000 lb soft-check target is raw_burn (breakdown.raw_burn), not
        %   W_fuel. breakdown carries per-segment names/fuel/W_after plus each
        %   segment's debug struct (L/D, TSFC, ...) for the comparison report.
            arguments
                obj
                W_TO (1,1) double {mustBePositive}
            end
            ctx = obj.build_context(W_TO);

            % Note (Casey): You really ought to pre-load every single segment name, instead of obtaining it with each iteration of the loop.
            n         = numel(obj.segments);
            names     = strings(1, n);
            fuel_lbf  = zeros(1, n);
            W_after   = zeros(1, n);
            seg_debug = cell(1, n);

            W = W_TO;
            raw_burn = 0;
            % Note (Casey): I don't like how this re-loads the mission profile every time it runs. It's inefficient.
            for i = 1:n
                seg  = obj.segments{i};
                fuel = seg.step(W, ctx);
                W    = seg.W_after;
                raw_burn = raw_burn + fuel;

                names(i)     = seg.name;
                fuel_lbf(i)  = fuel;
                W_after(i)   = seg.W_after;
                seg_debug{i} = seg.debug;
            end

            W_fuel = raw_burn * (1 + obj.reserve_fuel_fraction);

            breakdown = struct( ...
                'names',                 names, ...
                'fuel_lbf',              fuel_lbf, ...
                'W_after',               W_after, ...
                'raw_burn',              raw_burn, ...
                'reserve_fuel_fraction', obj.reserve_fuel_fraction, ...
                'W_fuel_with_reserve',   W_fuel, ...
                'W_TO',                  W_TO, ...
                'debug',                 {seg_debug});
        end

        function W_fuel = compute_fuel(obj, aero, prop, W_TO) %#ok<INUSL>
        %COMPUTE_FUEL  Sizing-loop-compatible entry point.
        %   Signature matches the retired MissionBase.compute_fuel(aero, prop,
        %   W_TO) so SizingLoopL1/L2 change only their type annotation. The aero
        %   and prop arguments are accepted for signature compatibility but the
        %   INJECTED handles are used (they are the same objects the sizing loop
        %   mutates and passed to from_requirements). Returns the total fuel
        %   weight (with reserve).
            W_fuel = obj.total_fuel(W_TO);
        end

    end

    methods (Access = protected)

        function ctx = build_context(obj, W_TO)
        %BUILD_CONTEXT  Assemble the per-run context struct handed to each
        %   segment. Reads the two SPEC values from the injected disciplines
        %   (aircraft_category from aero, n_engines from geom) rather than the
        %   requirements JSON.
            cat = "";
            if isprop(obj.aero, 'aircraft_category')
                cat = string(obj.aero.aircraft_category);
            end
            ne = 1;
            if isprop(obj.geom, 'n_engines')
                ne = obj.geom.n_engines;
            end

            ctx = struct( ...
                'aero', obj.aero, 'prop', obj.prop, 'geom', obj.geom, ...
                'W_TO', W_TO, ...
                'aircraft_category', cat, ...
                'n_engines', ne, ...
                'warmup_fuel_per_engine_lb', obj.warmup_fuel_per_engine_lb, ...
                'mu_rolling', obj.mu_rolling, ...
                'mu_braking', obj.mu_braking, ...
                'liftoff_factor', obj.liftoff_factor, ...
                'approach_factor', obj.approach_factor);
        end

    end

    methods (Static)

        function segments = assemble_segments(profile, build_segment_fn)
        %ASSEMBLE_SEGMENTS  Build the ordered MissionSegment cell array from a
        %   profile struct (MissionProfileReader output). Chooses each segment's
        %   class via build_segment_fn(spec) (the fidelity's type->class map),
        %   then sets the common segment properties here -- including threading
        %   the START flight condition from the previous segment's END
        %   (alt/mach carried forward; ground segments that omit alt_ft/mach_end
        %   simply keep the running value).
            specs = profile.segments;
            n = numel(specs);
            segments = cell(1, n);

            prev_alt  = 0;
            prev_mach = 0;
            for i = 1:n
                spec = specs(i);
                alt_end  = MissionAnalysisBase.field_or(spec, 'alt_ft',   prev_alt);
                mach_end = MissionAnalysisBase.field_or(spec, 'mach_end', prev_mach);

                seg = build_segment_fn(spec);
                seg.segment_type  = string(spec.type);
                seg.name          = string(MissionAnalysisBase.field_or(spec, 'name', spec.type));
                seg.alt_start_ft  = prev_alt;
                seg.alt_end_ft    = alt_end;
                seg.mach_start    = prev_mach;
                seg.mach_end      = mach_end;
                seg.distance_nm   = MissionAnalysisBase.field_or(spec, 'distance_nm',   NaN);
                seg.time_min      = MissionAnalysisBase.field_or(spec, 'time_min',      NaN);
                seg.drop_lb       = MissionAnalysisBase.field_or(spec, 'drop_lb',       0);
                seg.percent_ab    = MissionAnalysisBase.field_or(spec, 'percent_ab',    0);
                seg.cd0_increment = MissionAnalysisBase.field_or(spec, 'cd0_increment', 0);

                segments{i} = seg;
                prev_alt  = alt_end;
                prev_mach = mach_end;
            end
        end

        function scalars = scalars_from_profile(profile)
        %SCALARS_FROM_PROFILE  Extract the mission-requirement scalar block.
            scalars = struct( ...
                'reserve_fuel_fraction',     MissionAnalysisBase.field_or(profile, 'reserve_fuel_fraction', 0), ...
                'warmup_fuel_per_engine_lb', MissionAnalysisBase.field_or(profile, 'warmup_fuel_per_engine_lb', 0), ...
                'mu_rolling',                MissionAnalysisBase.field_or(profile, 'mu_rolling', 0), ...
                'mu_braking',                MissionAnalysisBase.field_or(profile, 'mu_braking', 0), ...
                'liftoff_factor',            MissionAnalysisBase.field_or(profile, 'liftoff_factor', 1), ...
                'approach_factor',           MissionAnalysisBase.field_or(profile, 'approach_factor', 1));
        end

        function v = field_or(s, name, default)
        %FIELD_OR  s.(name) if present and non-empty, else default.
        %   Non-empty because MissionProfileReader returns a union-of-fields
        %   struct array (an absent optional key comes back present-but-[]).
            if isfield(s, name) && ~isempty(s.(name))
                v = s.(name);
            else
                v = default;
            end
        end

    end

end
