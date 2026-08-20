classdef FixedTailStub < TailSizingModelL1
%FIXEDTAILSTUB  Minimal generic (non-F-16) TailSizingBase-conforming stand-in
%   for the SizingLoopL2 / TSDiagram tests. size(obj) reads the injected
%   geometry and delegates to the real TailL1 statics (0.475*L_fus arm) with
%   arbitrary, non-F-16 coefficients. The loop-plumbing tests only check that
%   the loop wires tail.size() through and gets positive areas, so the exact
%   coefficients and arm are immaterial.

    properties
        c_HT (1,1) double = 0.40   % arbitrary, non-F-16 coefficient
        c_VT (1,1) double = 0.07   % arbitrary, non-F-16 coefficient
        geom                       % (1,1) GeometryBase -- injected, read-only
    end

    methods

        function obj = FixedTailStub(geom)
            arguments
                geom (1,1) GeometryBase
            end
            obj.geom = geom;
        end

        function result = size(obj)
        %SIZE  Delegates to TailL1's real statics (0.475*L_fus arm), reading
        %   the injected geometry, with this stub's arbitrary c_HT/c_VT.
            result = TailL1.size(obj, obj.geom.S_ref, obj.geom.b_wing, ...
                                 obj.geom.cbar_wing, obj.geom.L_fus);
        end

    end

end
