classdef MissionAnalysisL1 < MissionAnalysisBase
%MISSIONANALYSISL1  Level-1 mission fuel analysis.
%
%   Constant historical weight fractions for most segments (Roskam Airplane
%   Design Part I, Table 2.1), and the Breguet range/endurance equations for the
%   cruise/dash and loiter/combat legs -- with L/D taken from the injected aero
%   object and TSFC from the injected prop object, so swapping the discipline
%   fidelity actually changes the result.
%
%   build_segment map (CAP profile types):
%     startup / taxi / takeoff / climb / descent / landing -> FixedFractionSegment
%     cruise / dash                                          -> BreguetRangeSegment
%     loiter / combat                                        -> BreguetEnduranceSegment
%   L1 covers the CAP profile; the extra Brandt-14 types (accel / patrol /
%   egress) are L2-only and error here by design.

    methods
        function obj = MissionAnalysisL1(aero, prop, geom, segments, scalars)
            obj@MissionAnalysisBase(aero, prop, geom, segments, scalars);
        end
    end

    methods (Static)

        function obj = from_requirements(aero, prop, geom, req_path, profile_name)
        %FROM_REQUIREMENTS  Build an L1 mission analysis from a requirements JSON
        %   profile plus the injected discipline objects. Mirrors
        %   ConstraintAnalysis.from_requirements.
            arguments
                aero (1,1) AerodynamicsBase
                prop (1,1) PropulsionBase
                geom (1,1) GeometryBase
                req_path     (1,1) string {mustBeNonzeroLengthText}
                profile_name (1,1) string {mustBeNonzeroLengthText}
            end
            profile  = MissionProfileReader.read_profile(req_path, profile_name);
            segments = MissionAnalysisBase.assemble_segments(profile, @MissionAnalysisL1.build_segment);
            scalars  = MissionAnalysisBase.scalars_from_profile(profile);
            obj = MissionAnalysisL1(aero, prop, geom, segments, scalars);
        end

        function seg = build_segment(spec)
        %BUILD_SEGMENT  Map a segment spec to its L1 concrete segment class.
            switch lower(string(spec.type))
                case {"startup", "taxi", "takeoff", "climb", "descent", "landing"}
                    seg = FixedFractionSegment();
                case {"cruise", "dash"}
                    seg = BreguetRangeSegment();
                case {"loiter", "combat"}
                    seg = BreguetEnduranceSegment();
                otherwise
                    error('MissionAnalysisL1:unknownSegmentType', ...
                        ['L1 mission analysis has no segment class for type "%s". ', ...
                         'accel/patrol/egress are L2-only.'], spec.type);
            end
        end

    end

end
