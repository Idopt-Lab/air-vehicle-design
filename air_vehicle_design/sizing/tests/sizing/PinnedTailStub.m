classdef PinnedTailStub < TailSizingModelL1
%PINNEDTAILSTUB  TailSizingBase-conforming stub that returns CONSTANT tail
%   areas regardless of the wing/fuselage inputs.
%
%   WHY THIS EXISTS (2026-08-14): TestSizingVsBrandt's closure-identity
%   test pins every input to Brandt's actual aircraft so that the TOGW
%   closure is an exact algebraic identity. That includes the tail areas:
%   Brandt's S_ht = 108 / S_vt = 60 ft^2 are MAIN-TAB INPUTS of the actual
%   F-16A [Brandt Main!C18 / Main!H18], while the volume-coefficient
%   method (F16TailL1: c_HT = 0.315, c_VT = 0.063, arm 0.475*L_fus)
%   predicts ~48.4 / ~25.7 ft^2 at the Brandt planform -- less than half
%   the real areas (measured 2026-08-14; a tail-sizing-discipline finding,
%   documented in sizing_brandt_comparison.m, NOT a loop bug). Pinning the
%   tail isolates the closure algebra from that discipline gap.
%
%   size() ignores all four scalars and returns the constructor values.

    properties (SetAccess = private)
        S_ht_pinned (1,1) double {mustBePositive} = 108  % ft^2
        S_vt_pinned (1,1) double {mustBePositive} = 60   % ft^2
    end

    methods

        function obj = PinnedTailStub(S_ht, S_vt)
            arguments
                S_ht (1,1) double {mustBePositive} = 108  % Brandt Main!C18
                S_vt (1,1) double {mustBePositive} = 60   % Brandt Main!H18
            end
            obj.S_ht_pinned = S_ht;
            obj.S_vt_pinned = S_vt;
        end

        function result = size(obj, ~, ~, ~, ~)
        %SIZE  Constant areas; inputs deliberately ignored (see header).
            result = struct('S_ht', obj.S_ht_pinned, 'S_vt', obj.S_vt_pinned);
        end

    end

end
