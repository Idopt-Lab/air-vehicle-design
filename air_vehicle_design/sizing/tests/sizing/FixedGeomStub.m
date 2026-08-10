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
%   Also used by TestSizingLoopL2.m: b_wing/cbar_wing/L_fus/lambda_wing are
%   fixed inputs the injected tail- and control-surface-sizing objects need (not
%   part of GeometryBase's abstract contract -- an L2/L3 convention);
%   S_ht/S_vt/S_ail/S_elev/S_rud/S_flaperon/S_lef/S_stab are plain outputs those
%   objects mutate in place from outside this class, same role as F16GeomL2's
%   own plain properties of the same names.
%
%   TAIL/CONTROL-SURFACE SIZING (2026-08-03 absorption into Geometry
%   REVERTED, 2026-08-05): SizingLoopL2 once again takes separate tail/ctrl
%   arguments and mutates this stub's S_ht/S_vt/S_ail/S_elev/S_rud
%   externally -- this stub owns no tail-volume coefficients or
%   control-surface fractions of its own any more (those live on the
%   injected FixedTailStub / ControlSurfaceSizer objects TestSizingLoopL2.m
%   constructs instead).

    properties
        S_ref = NaN
        b_wing = 30
        cbar_wing = 11
        L_fus = 46.5
        % lambda_wing ADDED 2026-08-10: ControlSurfaceSizer needs the wing
        % taper for the Roskam Eq. 7.10 wing-flap span-station area ratio. Value
        % is the F-16's, purely so the stub exercises a realistic tapered wing;
        % nothing here is validated against it.
        lambda_wing = 0.2275
        S_ht = NaN
        S_vt = NaN
        S_ail = NaN
        S_elev = NaN
        S_rud = NaN
        % Widened 2026-08-10 with the sizer's three new surfaces.
        S_flaperon = NaN
        S_lef = NaN
        S_stab = NaN
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
