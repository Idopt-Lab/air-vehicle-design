classdef MissionAnalysisL2 < MissionAnalysisBase
%MISSIONANALYSISL2  Level-2 mission fuel analysis.
%
%   Brandt's generic "master" mission fuel equation (MasterEquationSegment),
%   specialized per segment by time source, consuming the injected aero drag
%   polar and prop TSFC/thrust-lapse -- NOT Brandt's internal tsfc_old. Segments
%   the master form does not model fall back to the Roskam Table 2.1 constant
%   fractions (FixedFractionSegment), so EVERY segment yields a fuel burn.
%
%   build_segment map (handles both CAP and the 14-segment Brandt profile):
%     startup / taxi / descent / landing -> FixedFractionSegment  (Roskam 2.1)
%     takeoff                            -> TakeoffSegment         (ground roll)
%     climb / accel                      -> ClimbSegment           (Ps-based time)
%     cruise / dash / egress             -> CruiseSegment          (given distance)
%     loiter / patrol                    -> LoiterSegment          (given time)
%     combat                             -> CombatSegment          (thrust*TSFC*t)
%
%   NOTE: L2 landing uses FixedFractionSegment (Roskam 0.995) -- it burns fuel
%   like every other segment; the informational landing ground-roll DISTANCE
%   (Brandt Miss!O6) is a deferred debug-only output, not needed for the
%   fuel-focused analysis.

    methods
        function obj = MissionAnalysisL2(aero, prop, geom, segments, scalars)
            obj@MissionAnalysisBase(aero, prop, geom, segments, scalars);
        end
    end

    methods (Static)

        function obj = from_requirements(aero, prop, geom, req_path, profile_name)
        %FROM_REQUIREMENTS  Build an L2 mission analysis from a requirements JSON
        %   profile plus the injected discipline objects.
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                geom (1,1) GeometryBase
                req_path     (1,1) string {mustBeNonzeroLengthText}
                profile_name (1,1) string {mustBeNonzeroLengthText}
            end
            profile  = MissionProfileReader.read_profile(req_path, profile_name);
            segments = MissionAnalysisBase.assemble_segments(profile, @MissionAnalysisL2.build_segment);

            % Ground-fuel double-count guard: if the profile carries explicit
            % Startup/Taxi legs (CAP), those already account for the ground phase
            % via their Roskam fractions, so the takeoff must not ALSO add the
            % 1-min warm-up + fixed start fuel. Brandt-14 has no Startup/Taxi, so
            % its takeoff keeps them. See TakeoffSegment.
            types = string(cellfun(@(s) char(s.segment_type), segments, 'UniformOutput', false));
            if any(ismember(types, ["startup", "taxi"]))
                for i = 1:numel(segments)
                    if isa(segments{i}, 'TakeoffSegment')
                        segments{i}.include_warmup_start = false;
                    end
                end
            end

            scalars = MissionAnalysisBase.scalars_from_profile(profile);
            obj = MissionAnalysisL2(aero, prop, geom, segments, scalars);
        end

        function seg = build_segment(spec)
        %BUILD_SEGMENT  Map a segment spec to its L2 concrete segment class.
            switch lower(string(spec.type))
                case {"startup", "taxi", "descent", "landing"}
                    seg = FixedFractionSegment();
                case "takeoff"
                    seg = TakeoffSegment();
                case {"climb", "accel"}
                    seg = ClimbSegment();
                case {"cruise", "dash", "egress"}
                    seg = CruiseSegment();
                case {"loiter", "patrol"}
                    seg = LoiterSegment();
                case "combat"
                    seg = CombatSegment();
                otherwise
                    error('MissionAnalysisL2:unknownSegmentType', ...
                        'L2 mission analysis has no segment class for type "%s".', spec.type);
            end
        end

    end

end
