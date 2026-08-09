classdef BrandtPropAdapter < PropulsionBase
%BRANDTPROPADAPTER  Makes a BrandtEngine object satisfy the src
%   PropulsionBase interface, for the src-vs-Brandt reproduction test.
%
%   PURPOSE. The src constraint classes take an injected PropulsionBase
%   object and call thrust_lapse(state) (AB rows) or
%   thrust_lapse_mil_on_AB_scale(state) (mil rows) on it. This adapter wraps
%   a VnV BrandtEngine handle so the SAME src constraint code draws Brandt's
%   own thrust lapse -- see tests/constraints/TestConstraintAnalysisVsBrandt.m.
%
%   THRUST-LAPSE BASIS. Both methods return alpha_AB_ref -- thrust normalised
%   to the AB SLS thrust T_sl_AB -- exactly the quantity Brandt's Consts tab
%   uses (Consts!AU) and BrandtConstraintAnalysis.masterConstraint_ reads.
%   The afterburner fraction is the only difference between the two:
%     thrust_lapse                -> run(alt, M, 1.0).alpha_AB_ref  (full AB)
%     thrust_lapse_mil_on_AB_scale-> run(alt, M, 0.0).alpha_AB_ref  (mil/dry)
%   A src Master-Equation row built with powerSetting "AB" draws the first, a
%   "mil" row (e.g. Cruise) the second -- matching Brandt, which evaluates
%   each row at eng.run(alt, mach, pct_AB/100).alpha_AB_ref with pct_AB = 100
%   for AB rows and 0 for the cruise row.
%
%   T_SL. Required abstract PropulsionBase property; set to Brandt's AB SLS
%   thrust T_sl_AB. The constraint envelope does not read it (it works on the
%   thrust-lapse alpha_AB_ref, which is already AB-normalised), but the
%   interface demands the property, so it carries the physically correct
%   value.
%
%   Reference only -- lives under VnV, is NOT part of the shipped src tree,
%   and is not on the run_all_tests path by default (the test adds it).

    properties
        brandtEng   % BrandtEngine handle (analyze() already called)
    end

    properties (Dependent)
        T_SL        % lbf -- AB SLS thrust T_sl_AB, from the wrapped engine
    end

    methods

        function obj = BrandtPropAdapter(brandtEng)
        %BRANDTPROPADAPTER  Wrap an analyzed BrandtEngine handle.
        %   brandtEng -- a BrandtEngine that has had analyze() called.
            arguments
                brandtEng (1,1) BrandtEngine
            end
            obj.brandtEng = brandtEng;
        end

        function t = get.T_SL(obj)
            t = obj.brandtEng.T_sl_AB;
        end

        function alpha = thrust_lapse(obj, state)
        %THRUST_LAPSE  Full-AB thrust lapse alpha = T_AB/T_sl_AB at the state.
        %   Brandt eng.run(alt, M, 1.0).alpha_AB_ref (pct_AB = 100 %).
            r = obj.brandtEng.run(state.altitude_ft, state.mach, 1.0);
            alpha = r.alpha_AB_ref;
        end

        function alpha = thrust_lapse_mil_on_AB_scale(obj, state)
        %THRUST_LAPSE_MIL_ON_AB_SCALE  Mil-power thrust lapse on the AB T_SL
        %   scale: alpha = T_mil/T_sl_AB. Brandt eng.run(alt, M, 0.0).
        %   alpha_AB_ref (pct_AB = 0 %). OVERRIDES the PropulsionBase default
        %   (which would fall back to the full-AB lapse) so a mil-power row
        %   (Cruise) uses Brandt's exact dry-power alpha, not the AB value.
            r = obj.brandtEng.run(state.altitude_ft, state.mach, 0.0);
            alpha = r.alpha_AB_ref;
        end

        function c_t = get_TSFC(obj, state)
        %GET_TSFC  Mil-power installed TSFC [1/hr] at the state.
        %   Required by the PropulsionBase interface; the constraint envelope
        %   does not use it, but a concrete class must implement it. Returns
        %   Brandt's dry/mil-power installed TSFC (pct_AB = 0 %).
            r = obj.brandtEng.run(state.altitude_ft, state.mach, 0.0);
            c_t = r.TSFC;
        end

        function c_t = compute_TSFC_installed(obj, state)
        %COMPUTE_TSFC_INSTALLED  Brandt Miss-tab "Old"-model installed DRY TSFC
        %   [1/hr] -- the TSFC Brandt's mission (Miss tab) actually uses, which is
        %   DISTINCT from get_TSFC's BrandtEngine "New"-model run().TSFC. Mission
        %   analysis prefers this installed variant (MissionEquations.select_tsfc),
        %   so the Brandt discipline stack reproduces the Miss-tab fuel; the
        %   constraint code keeps using the thrust-lapse and is unaffected.
            c_t = obj.tsfc_old_(state, 0);
        end

        function c_t = compute_TSFC_AB_installed(obj, state)
        %COMPUTE_TSFC_AB_INSTALLED  Brandt Miss-tab "Old"-model installed
        %   full-afterburner TSFC [1/hr]. Mission-preferred AB TSFC on the Brandt
        %   stack (see compute_TSFC_installed).
            c_t = obj.tsfc_old_(state, 100);
        end

    end

    methods (Access = private)

        function cT = tsfc_old_(obj, state, pct_AB)
        %TSFC_OLD_  Brandt Miss-tab "Engn(s) Old" installed TSFC [1/hr]:
        %     cT_dry = install * TSFC_sl_dry * (1 + 0.35|M|)     * sqrt(theta)
        %     cT_AB  = install * TSFC_sl_AB  * (1 + 0.35|M-0.4|) * sqrt(theta)
        %     cT     = cT_dry + (pct_AB/100) * (cT_AB - cT_dry)
        %   theta = static temperature ratio (AircraftState.theta = T/T_std,
        %   equal to Brandt's T_ISA(h)/288.15); install = 1.08 [Miss!C25 = Main!C25,
        %   from BrandtEngine.inp.engine.TSFC_install_factor]. Replicates
        %   BrandtMission.tsfc_old_ so the Brandt discipline stack feeds mission
        %   analysis the SAME TSFC the Miss-tab ground truth uses. Added for
        %   mission analysis (user-approved, 2026-08-09); the constraint
        %   reproduction path does not use it. [readme_mission.md "Old" model]
            install = obj.brandtEng.inp.engine.TSFC_install_factor;
            theta   = state.theta;
            M       = state.mach;
            cT_dry = install * obj.brandtEng.TSFC_sl_dry * (1 + 0.35 * abs(M))       * sqrt(theta);
            cT_AB  = install * obj.brandtEng.TSFC_sl_AB  * (1 + 0.35 * abs(M - 0.4)) * sqrt(theta);
            cT = cT_dry + (pct_AB / 100) * (cT_AB - cT_dry);
        end

    end

end
