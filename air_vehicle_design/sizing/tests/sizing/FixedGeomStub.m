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
%   inputs the self-mutating size_tail() method below needs (not part of
%   GeometryBase's abstract contract -- an L2/L3 convention); S_ht/S_vt/
%   S_ail/S_elev/S_rud are plain outputs size_tail()/size_control_surfaces()
%   mutate in place, same role as F16GeomL2's own plain properties of the
%   same names.
%
%   TAIL/CONTROL-SURFACE SIZING (updated 2026-08-03): SizingLoopL2 no
%   longer takes separate tail/ctrl arguments -- it calls
%   geom.size_tail()/geom.size_control_surfaces() directly, so this stub
%   gained its own self-mutating implementations, reproducing exactly what
%   the retired FixedTailStub (c_HT=0.40, c_VT=0.07, via
%   GeomL1.compute_tail_arm/compute_S_HT/compute_S_VT) and the retired
%   inline ControlSurfaceSizer(0.20, 0.40, 0.30, 0.90, 0.30, 0.90) did
%   before -- same arbitrary, non-F-16 coefficients/fractions, so
%   TestSizingLoopL2.m stays "generic (non-F-16-specific)" per its own
%   class header. NOTE: this stub's control-surface fractions differ from
%   the F-16 production ones (nonzero elevator fraction 0.30/0.90), since
%   TestSizingLoopL2.testTailAndControlSurfaceAreasPositive asserts
%   S_elev > 0 -- preserved here exactly, not the F-16 defaults.

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

        c_HT (1,1) double = 0.40   % arbitrary, non-F-16 coefficient [was FixedTailStub.c_HT]
        c_VT (1,1) double = 0.07   % arbitrary, non-F-16 coefficient [was FixedTailStub.c_VT]

        c_ail_frac  (1,1) double = 0.20   % arbitrary, non-F-16 fraction [was the retired inline ControlSurfaceSizer(...) call]
        b_ail_frac  (1,1) double = 0.40
        c_elev_frac (1,1) double = 0.30   % nonzero -- testTailAndControlSurfaceAreasPositive asserts S_elev > 0
        b_elev_frac (1,1) double = 0.90
        c_rud_frac  (1,1) double = 0.30
        b_rud_frac  (1,1) double = 0.90
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

        function result = size_tail(obj)
        %SIZE_TAIL  Delegates to GeomL1's real statics (0.475*L_fus tail
        %   arm) -- not a duplicated formula -- using this stub's arbitrary
        %   c_HT/c_VT. Self-mutates obj.S_ht/obj.S_vt, mirroring F16GeomL2/
        %   F16GeomL3's production size_tail() methods.
            L_HT = GeomL1.compute_tail_arm(obj.L_fus);
            L_VT = L_HT;
            result   = struct( ...
                'S_ht', GeomL1.compute_S_HT(obj.c_HT, obj.cbar_wing, obj.S_ref, L_HT), ...
                'S_vt', GeomL1.compute_S_VT(obj.c_VT, obj.b_wing, obj.S_ref, L_VT));
            obj.S_ht = result.S_ht;
            obj.S_vt = result.S_vt;
        end

        function result = size_control_surfaces(obj)
        %SIZE_CONTROL_SURFACES  Delegates to GeomL2's real static -- not a
        %   duplicated formula -- using this stub's arbitrary fractions.
        %   Self-mutates obj.S_ail/obj.S_elev/obj.S_rud.
            result = GeomL2.compute_control_surface_areas( ...
                obj.c_ail_frac, obj.b_ail_frac, obj.c_elev_frac, obj.b_elev_frac, ...
                obj.c_rud_frac, obj.b_rud_frac, obj.S_ref, obj.S_ht, obj.S_vt);
            obj.S_ail  = result.S_ail;
            obj.S_elev = result.S_elev;
            obj.S_rud  = result.S_rud;
        end

    end

end
