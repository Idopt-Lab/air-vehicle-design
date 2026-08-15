classdef BrandtPropAdapter < PropulsionBase
%BRANDTPROPADAPTER  Makes a BrandtEngine object satisfy the src
%   PropulsionBase interface, for the src-vs-Brandt reproduction test.
%
%   USED BY BOTH the constraint reproduction test AND mission analysis, so
%   the name carries no consumer qualifier. From 2026-08-07 to 2026-08-12
%   this class was named BrandtConstraintPropAdapter, to avoid a class-name
%   collision with a duplicate examples/F16A/mixed_fidelity_tests/adapters/
%   BrandtPropAdapter.m. That duplicate is deleted, so this file uses the
%   plain name again.
%
%   PURPOSE. The src constraint classes take an injected PropulsionBase
%   object and call thrust_lapse(state, rating) on it, with rating "AB" (AB
%   rows) or "mil" (mil rows). This adapter wraps a VnV BrandtEngine handle so
%   the SAME src constraint code draws Brandt's own thrust lapse -- see
%   tests/constraints/TestConstraintAnalysisVsBrandt.m.
%
%   THRUST-LAPSE BASIS. thrust_lapse returns alpha_AB_ref -- thrust normalised
%   to the AB SLS thrust T_sl_AB -- exactly the quantity Brandt's Consts tab
%   uses (Consts!AU) and BrandtConstraintAnalysis.masterConstraint_ reads.
%   The afterburner fraction is the only difference between the two ratings:
%     thrust_lapse(state,"AB")  -> run(alt, M, 1.0).alpha_AB_ref  (full AB)
%     thrust_lapse(state,"mil") -> run(alt, M, 0.0).alpha_AB_ref  (mil/dry)
%   A src Master-Equation row built with powerSetting "AB" draws the first, a
%   "mil" row (e.g. Cruise) the second -- matching Brandt, which evaluates
%   each row at eng.run(alt, mach, pct_AB/100).alpha_AB_ref with pct_AB = 100
%   for AB rows and 0 for the cruise row.
%
%   T_SL. Required abstract PropulsionBase property; reads Brandt's AB SLS
%   thrust T_sl_AB. The constraint envelope does not read it (it works on the
%   thrust-lapse alpha_AB_ref, which is already AB-normalised), but the
%   interface demands the property, so it carries the physically correct
%   value.
%
%   MUTATION-CAPABLE (2026-08-13 sizing pass, user-approved). T_SL is now
%   SETTABLE: the sizing loops rubber-scale the engine by assigning
%   propAdapter.T_SL = <new AB SLS thrust>. The setter scales T_sl_dry and
%   T_sl_AB by the SAME factor, preserving the dry/AB ratio -- the Engn(s)-tab
%   thrust-lapse alphas are pure ratios (T/T_sl), so every thrust_lapse value
%   (at either rating) is INVARIANT under the scaling; only absolute thrust
%   (and anything sized from it) moves. See set.T_SL.
%
%   THRUST OWNERSHIP. The wrapped BrandtEngine is the single LIVE thrust
%   source. BrandtWeight keeps its own inp.engine.T_AB_SLS_lb COPY (engine +
%   inlet-duct weight terms, Wt!B11/B22); that copy is synced from the live
%   engine by BrandtWeightAdapter at each OEW call -- deliberately NOT here,
%   because this adapter must not know about the weight object.
%
%   Reference only -- lives under VnV, is NOT part of the shipped src tree.
%   It IS unconditionally on the run_all_tests path (run_all_tests.m
%   addpath(genpath(.../VnV))), not merely added by one test.

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

        function set.T_SL(obj, val)
        %SET.T_SL  Rubber-scale the wrapped BrandtEngine to a new AB SLS
        %   thrust [lbf], PRESERVING the dry/AB ratio:
        %     scale    = val / T_sl_AB
        %     T_sl_dry = T_sl_dry * scale
        %     T_sl_AB  = val
        %   The Engn(s)-tab lapse formulas return alpha = T/T_sl (pure
        %   ratios), so thrust_lapse (at either rating) is invariant under
        %   this scaling. TSFC_sl_dry/TSFC_sl_AB are NOT
        %   scaled: a rubber engine keeps its specific fuel consumption.
        %
        %   NO re-analyze: BrandtEngine.analyze() caches NOTHING derived from
        %   the SLS thrusts -- it only copies inp.engine into the properties.
        %   Calling analyze() here would in fact RE-COPY from inp and undo the
        %   scale, so the inp.engine copies are synced below instead, which
        %   also makes any later analyze() call idempotent rather than a
        %   silent revert of the thrust design point.
            if ~(isnumeric(val) && isscalar(val) && isfinite(val) && val > 0)
                error('BrandtPropAdapter:invalidThrust', ...
                    'T_SL must be a positive finite numeric scalar [lbf].');
            end
            eng = obj.brandtEng;
            if ~eng.analyzed_ || ~(isfinite(eng.T_sl_AB) && eng.T_sl_AB > 0)
                error('BrandtPropAdapter:notAnalyzed', ...
                    'The wrapped BrandtEngine must be analyzed (positive T_sl_AB) before T_SL can be set.');
            end
            scale        = val / eng.T_sl_AB;
            eng.T_sl_dry = eng.T_sl_dry * scale;
            eng.T_sl_AB  = val;
            eng.inp.engine.T_mil_SLS_lb = eng.T_sl_dry;
            eng.inp.engine.T_AB_SLS_lb  = eng.T_sl_AB;
        end

        function alpha = thrust_lapse(obj, state, rating)
        %THRUST_LAPSE  Thrust lapse on the AB T_SL scale at the given rating.
        %   "AB"  -> full-AB lapse T_AB/T_sl_AB: Brandt eng.run(alt,M,1.0)
        %            .alpha_AB_ref (pct_AB = 100 %).
        %   "mil" -> mil/dry lapse on the AB T_SL scale T_mil/T_sl_AB: Brandt
        %            eng.run(alt,M,0.0).alpha_AB_ref (pct_AB = 0 %), so a
        %            dry-power row (Cruise) uses Brandt's exact dry-power alpha,
        %            not the AB value.
            arguments
                obj
                state  (1,1) AircraftState
                rating (1,1) string {mustBeMember(rating, ["mil","AB"])}
            end
            if rating == "mil"
                frac = 0.0;
            else
                frac = 1.0;
            end
            r = obj.brandtEng.run(state.altitude_ft, state.mach, frac);
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
