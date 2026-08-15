classdef ErroringPropMock < PropulsionBase
%ERRORINGPROPMOCK  Propulsion discipline stand-in that ERRORS if any method
%   is called -- used only to prove a FixedFractionSegment never touches the
%   prop object (those phases have no TSFC dependence, so the same Roskam
%   fraction holds for every discipline stack).
%
%   Mirrors tests/constraints/FixedPropStub.m's rationale, inverted: every
%   method throws, so an accidental call surfaces immediately as a test failure.

    properties
        T_SL = 0
        TSFC = 0
    end

    methods

        function alpha = thrust_lapse(~, ~, ~)
            error('ErroringPropMock:calledAtL1', ...
                'prop_obj.thrust_lapse was called -- a FixedFractionSegment must NEVER call the propulsion discipline object.');
        end

        function c_t = get_TSFC(~, ~)
            error('ErroringPropMock:calledAtL1', ...
                'prop_obj.get_TSFC was called -- a FixedFractionSegment must NEVER call the propulsion discipline object.');
        end

        function c_t = compute_TSFC_AB(~, ~)
            error('ErroringPropMock:calledAtL1', ...
                'prop_obj.compute_TSFC_AB was called -- a FixedFractionSegment must NEVER call the propulsion discipline object.');
        end

    end

end
