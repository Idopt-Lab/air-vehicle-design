function s = build_b777_stack_s(varargin)
%BUILD_B777_STACK_S  A fresh B777 stack, returned as a struct.
%
%   s = BUILD_B777_STACK_S() returns struct with fields aero, prop, wts,
%   geom, miss, con, tail. Same objects as BUILD_B777_STACK; the struct form
%   is convenient when a stack has to be passed around as one value, as in
%   SIZING_SENSITIVITY.

    [s.aero, s.prop, s.wts, s.geom, s.miss, s.con, s.tail] = ...
        build_b777_stack(varargin{:});
end
