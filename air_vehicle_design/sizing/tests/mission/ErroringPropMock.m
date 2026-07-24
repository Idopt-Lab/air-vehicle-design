classdef ErroringPropMock < PropulsionBase
%ERRORINGPROPMOCK  Propulsion discipline stand-in that ERRORS if any method
%   is called -- used only to prove Mission L1 never touches prop_obj
%   (subplan 07 Design Notes: "L1 does NOT call... prop.get_TSFC/
%   compute_TSFC_AB. Arguments accepted but unused -- test this with a mock
%   that errors if called").
%
%   Mirrors tests/constraints/FixedPropStub.m's rationale, inverted: every
%   method throws instead of returning a fixed value, so an accidental call
%   from MissionL1's dispatch loop surfaces immediately as a test failure.

    properties
        T_SL = 0
        TSFC = 0
    end

    methods

        function alpha = thrust_lapse(~, ~)
            error('ErroringPropMock:calledAtL1', ...
                'prop_obj.thrust_lapse was called -- Mission L1 must NEVER call the propulsion discipline object.');
        end

        function c_t = get_TSFC(~, ~)
            error('ErroringPropMock:calledAtL1', ...
                'prop_obj.get_TSFC was called -- Mission L1 must NEVER call the propulsion discipline object.');
        end

        function c_t = compute_TSFC_AB(~, ~)
            error('ErroringPropMock:calledAtL1', ...
                'prop_obj.compute_TSFC_AB was called -- Mission L1 must NEVER call the propulsion discipline object.');
        end

    end

end
