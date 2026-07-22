classdef FixedAeroStub < AerodynamicsBase
%FIXEDAEROSTUB  A minimal stand-in aerodynamics object, used only by tests.
%
%   WHY THIS EXISTS: constraint classes like LandingConstraint don't take
%   raw CLmax/CD0/K1/K2 numbers -- their constructor takes an aero
%   discipline object (e.g. F16AeroL1/L2/L3) and internally calls
%   aero.get_CLmax(state)/aero.drag_polar(state) on it. That's the right
%   design for production code (a constraint diagram should track whichever
%   aero model is currently active), but it means a test that wants to
%   check "does LandingConstraint.WS_max reproduce Brandt's exact number?"
%   can't just hand it plain numbers -- it needs something shaped like an
%   aero object to pass to the constructor.
%
%   FixedAeroStub is that minimal aero-shaped object: build one with
%   FixedAeroStub(CLmax, CD0, K1, K2) and it always returns those same four
%   values from get_CLmax(state)/drag_polar(state), no matter what state is
%   passed in. Tests use it to feed a real LandingConstraint object exact
%   numbers -- Brandt's own worksheet values, or one fidelity level's
%   flapped-landing totals -- and then call that object's real WS_max(), so
%   the test exercises LandingConstraint's actual code instead of a
%   hand-copied re-derivation of its formula.
%
%   It subclasses AerodynamicsBase only because that is the type
%   LandingConstraint's constructor requires. The extra properties below
%   (CDi, CL, CD, ...) are unused placeholders that abstract class demands;
%   they have no effect on any test.

    properties
        e_osw_clean = 0
        CD0
        CDi = 0
        CL = 0
        CD = 0
        CL_minD = 0
        CL_max_clean = 0
        Cf = 0
        K1
        K2
        CLmax
    end

    methods

        function obj = FixedAeroStub(CLmax, CD0, K1, K2)
            arguments
                CLmax (1,1) double
                CD0   (1,1) double
                K1    (1,1) double = 0
                K2    (1,1) double = 0
            end
            obj.CLmax = CLmax;
            obj.CD0   = CD0;
            obj.K1    = K1;
            obj.K2    = K2;
        end

        function polar = drag_polar(obj, ~)
            polar = struct('CD0', obj.CD0, 'K1', obj.K1, 'K2', obj.K2);
        end

        function CLmax = get_CLmax(obj, ~)
            CLmax = obj.CLmax;
        end

    end

end
