classdef FixedGeomStub < GeometryBase
%FIXEDGEOMSTUB  A minimal stand-in geometry object, used only by tests.
%
%   Mirrors tests/constraints/FixedAeroStub.m's rationale: SizingLoopL1
%   needs a GeometryBase object with a settable S_ref (the loop assigns
%   geom.S_ref = W_TO/WS_opt every iteration), not a real F16GeomLN.
%
%   S_wet is an arbitrary fixed multiple of S_ref -- unused by
%   SizingLoopL1 itself, only present to satisfy GeometryBase's abstract
%   contract.
%
%   Also used by TestSizingLoopL2.m: b_wing/cbar_wing/L_fus are fixed
%   inputs a TailSizingBase implementer's size(obj, S_ref, b, cbar, L_fus)
%   needs (not part of GeometryBase's abstract contract -- an L2/L3
%   convention; see FixedTailStub.m, the TailSizingBase-conforming object
%   TestSizingLoopL2.m injects as of 2026-07-28); S_ht/S_vt/S_ail/S_elev/
%   S_rud are plain outputs SizingLoopL2 mutates in place, same role as
%   F16GeomL2's own plain properties of the same names.

    properties
        S_ref = NaN
        b_wing = 30
        cbar_wing = 11
        L_fus = 46.5
        S_ht = NaN
        S_vt = NaN
        S_ail = NaN
        S_elev = NaN
        S_rud = NaN
    end

    properties (Dependent)
        S_wet
    end

    methods

        function val = get_S_ref(obj)
            val = obj.S_ref;
        end

        function val = get_S_wet(obj, ~)
            val = 2 * obj.S_ref;
        end

        function v = get.S_wet(obj)
            v = obj.get_S_wet(obj.S_ref);
        end

    end

end
