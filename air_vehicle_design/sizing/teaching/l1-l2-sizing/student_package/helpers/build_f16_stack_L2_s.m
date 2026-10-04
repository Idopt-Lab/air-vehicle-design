function s = build_f16_stack_L2_s(varargin)
%BUILD_F16_STACK_L2_S  A fresh F-16A Level-2 stack, returned as a struct.
%
%   s = BUILD_F16_STACK_L2_S() returns struct with fields aero, prop, wts,
%   geom, miss, con, tail.

    [s.aero, s.prop, s.wts, s.geom, s.miss, s.con, s.tail] = ...
        build_f16_stack_L2(varargin{:});
end
