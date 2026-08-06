classdef BrandtAeroAdapter < AerodynamicsBase
%BRANDTAEROADAPTER  Makes a BrandtAerodynamics object satisfy the src
%   AerodynamicsBase interface, for the src-vs-Brandt reproduction test.
%
%   PURPOSE. The src constraint classes (MasterEquationConstraint subtree,
%   TakeoffConstraint, LandingConstraint) take an injected AerodynamicsBase
%   object and call drag_polar(state)/get_CLmax(state) and the high-lift
%   methods on it. This adapter wraps a VnV BrandtAerodynamics handle so the
%   SAME src constraint code can run on Brandt's own aerodynamics. When both
%   sides use identical CD0/K1/alpha, the two constraint diagrams must agree
%   -- see tests/constraints/TestConstraintAnalysisVsBrandt.m.
%
%   K2 = 0 ON PURPOSE. Brandt's constraint analysis (Consts tab, replicated
%   in BrandtConstraintAnalysis.masterConstraint_) uses the SYMMETRIC
%   parabolic drag polar CD = CD0 + K1*CL^2, with NO linear K2*CL camber
%   term. The src Master Equation carries a K2 term (its C term,
%   K2*n*beta/alpha). Returning K2 = 0 from drag_polar makes that src C term
%   vanish, so the src Master Equation reduces to exactly Brandt's form. This
%   is one of the two accounted-for modeling choices that let the two sides
%   match (the other is the shared W/S grid); it is what makes the comparison
%   an isolation of the src constraint-assembly logic rather than a test of
%   the drag model. BrandtAerodynamics does compute a nonzero k2 internally,
%   but its own masterConstraint_ never uses it, so dropping it here matches
%   Brandt exactly.
%
%   CD0 BASIS. drag_polar returns brandtAero.run(mach).CD0, the Aero-tab
%   CDmin_sub basis (~0.017 subsonic) that Brandt's Consts tab sources -- NOT
%   the Miss-tab Cfe_eff basis (0.027). This matches BrandtConstraintAnalysis,
%   which also reads run(mach).CD0. The takeoff/landing gear+flap CDx
%   increments are added by the src TakeoffConstraint/LandingConstraint via
%   get_Delta_CD0_TO/get_Delta_CD0_L below (0.035/0.045), exactly as Brandt
%   adds them (Consts!AM32/AM33). The six thrust rows need no increment
%   (Brandt CDx = 0 there), consistent with the requirements JSON.
%
%   Reference only -- lives under VnV, is NOT part of the shipped src tree,
%   and is not on the run_all_tests path by default (the test adds it).

    properties
        brandtAero   % BrandtAerodynamics handle (analyze() already called)
    end

    methods

        function obj = BrandtAeroAdapter(brandtAero)
        %BRANDTAEROADAPTER  Wrap an analyzed BrandtAerodynamics handle.
        %   brandtAero -- a BrandtAerodynamics that has had analyze() called.
            arguments
                brandtAero (1,1) BrandtAerodynamics
            end
            obj.brandtAero = brandtAero;
        end

        function polar = drag_polar(obj, state)
        %DRAG_POLAR  Brandt drag polar at the flight state's Mach.
        %   Returns struct(CD0, K1, K2) with K2 = 0 -- see class header for
        %   the K2 = 0 rationale (Brandt's symmetric parabolic polar).
            r = obj.brandtAero.run(state.mach);
            polar = struct('CD0', r.CD0, 'K1', r.K1, 'K2', 0);
        end

        function CLmax = get_CLmax(obj, ~)
        %GET_CLMAX  Clean (unflapped) maximum lift coefficient.
        %   Returns BrandtAerodynamics.CLmax_clean (Aero!H25). Mach-
        %   independent, so state is ignored. NOTE: the Brandt reproduction
        %   set has NO Stall row, so this clean value is not exercised by the
        %   comparison test -- it is returned only to complete the interface.
            CLmax = obj.brandtAero.CLmax_clean;
        end

        function CLmax = get_CLmax_TO(obj)
        %GET_CLMAX_TO  Flapped takeoff maximum lift coefficient (Aero!H27).
            CLmax = obj.brandtAero.CLmax_takeoff;
        end

        function CLmax = get_CLmax_L(obj)
        %GET_CLMAX_L  Flapped landing maximum lift coefficient (Aero!H29).
            CLmax = obj.brandtAero.CLmax_landing;
        end

        function delta = get_Delta_CD0_TO(~)
        %GET_DELTA_CD0_TO  Takeoff gear+flap drag increment CDx = 0.035
        %   (Brandt Consts!H32). No state argument: the src TakeoffConstraint
        %   dispatches on method arity and calls this 1-input form without a
        %   state -- correct here because Brandt's takeoff CDx is a fixed
        %   configuration constant, not a Reynolds-number lookup.
            delta = 0.035;
        end

        function delta = get_Delta_CD0_L(~)
        %GET_DELTA_CD0_L  Landing gear+flap drag increment CDx = 0.045
        %   (Brandt Consts landing row). No state argument -- same 1-input
        %   convention and rationale as get_Delta_CD0_TO above.
            delta = 0.045;
        end

    end

end
