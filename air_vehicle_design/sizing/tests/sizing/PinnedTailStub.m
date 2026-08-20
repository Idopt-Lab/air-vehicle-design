classdef PinnedTailStub < TailSizingModelL1
%PINNEDTAILSTUB  TailSizingBase-conforming stub that returns CONSTANT tail
%   areas regardless of geometry. Used by TestSizingVsBrandt's closure-identity
%   test, which pins every input to Brandt's actual aircraft so the TOGW
%   closure is an exact algebraic identity -- including the tail areas (Brandt
%   S_ht=108 / S_vt=60 ft^2, Main!C18/H18). Pinning the tail isolates the
%   closure algebra from the tail-sizing discipline gap.
%
%   size() ignores geometry and returns the constructor values.

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

        function result = size(obj)
        %SIZE  Constant areas; geometry deliberately ignored (see header).
            result = struct('S_ht', obj.S_ht_pinned, 'S_vt', obj.S_vt_pinned);
        end

    end

end
