classdef BrandtWeightAdapter < WeightsBase
%BRANDTWEIGHTADAPTER  Makes a BrandtWeight object satisfy the src
%   WeightsBase interface, so the Brandt discipline stack can feed the
%   sizing loops alongside BrandtAeroAdapter / BrandtPropAdapter /
%   BrandtMissionGeomAdapter. Added 2026-08-13 (sizing pass, user-approved).
%
%   PURPOSE. The sizing loop takes an injected WeightsBase and calls
%   OEW(W_TO) on it. This adapter wraps a VnV BrandtWeight handle (the Wt-tab
%   replication) so the SAME src sizing code draws Brandt's own component
%   weight buildup. NO new equation.
%
%   WIRING. Constructor takes the BrandtWeight AND the BrandtEngine. The
%   engine is the single LIVE thrust source (BrandtPropAdapter.set.T_SL
%   rubber-scales it in place); BrandtWeight only sees the STALE
%   inp.engine.T_AB_SLS_lb copy it took from geom.inp at construction, and
%   its engine + inlet-duct terms scale with that AB SLS thrust
%   (W_engine = 0.199*T, Brandt Wt!B11/B22). So OEW re-syncs
%   brandtWt.inp.engine.T_AB_SLS_lb from the live engine on EVERY call, then
%   re-runs the cheap W_TO-free analyze() pass before run(W_TO). Geometry
%   mutations are propagated separately, by BrandtMissionGeomAdapter's
%   dependents mechanism (which preserves this thrust sync -- see its
%   reanalyze_ ordering-hazard note).
%
%   FUEL. run(W_TO).W_fuel_lb is DELIBERATELY ignored: Brandt Wt!B6 is the
%   residual W_TO - payloads - OEW, not a mission fuel estimate. The mission
%   object owns fuel in this framework (W_energy is set by the sizing loop
%   from mission analysis, never read from Brandt's Wt tab).
%
%   GROUND-TRUTH ANCHOR. OEW(31,377) = 19,980.70 lbf [Brandt Wt!B12], with
%   payload split 700 (fixed, Main!O16) + 4,400 (expendable, Main!O17):
%     700 + 4,400 + 19,980.70 + 6,296.30 = 31,377 closes exactly.
%
%   Reference only -- lives under VnV, is NOT part of the shipped src tree.
%   It IS unconditionally on the run_all_tests path (run_all_tests.m
%   addpath(genpath(.../VnV))), not merely added by one test.

    properties
        brandtWt    % BrandtWeight handle (its geom must be analyzed)
        brandtEng   % BrandtEngine handle (analyzed; the LIVE thrust source)

        % WeightsBase abstract surface (src/base/WeightsBase.m). NOTE: no size/
        % type validators here -- MATLAB forbids adding size and validation
        % functions when implementing an inherited ABSTRACT property
        % (MATLAB:type:PropTypeNotSupportedForSubclassConcrete), and
        % WeightsBase declares these bare.
        W_TO                 = NaN  % lbf -- candidate gross TO weight; NaN until the sizing loop sets it
        W_energy             = NaN  % lbf -- internal fuel; NaN until mission analysis sets it
        W_payload_expendable = NaN  % lbf -- set from Brandt Main!O17 in the constructor
        W_payload_fixed      = NaN  % lbf -- set from Brandt Main!O16 in the constructor
    end

    methods

        function obj = BrandtWeightAdapter(brandtWt, brandtEng)
        %BRANDTWEIGHTADAPTER  Wrap a BrandtWeight + the live BrandtEngine.
        %   brandtWt  -- BrandtWeight whose geom has been analyzed (OEW calls
        %                brandtWt.analyze() itself, so the weight object need
        %                not be pre-analyzed, but its geometry must be).
        %   brandtEng -- BrandtEngine that has had analyze() called.
            arguments
                brandtWt  (1,1) BrandtWeight
                brandtEng (1,1) BrandtEngine
            end
            if ~brandtEng.analyzed_
                error('BrandtWeightAdapter:engineNotAnalyzed', ...
                    'brandtEng must be analyzed (T_sl_AB set) before wrapping.');
            end
            if ~brandtWt.geom.analyzed_
                error('BrandtWeightAdapter:geomNotAnalyzed', ...
                    'brandtWt.geom must be analyzed before wrapping.');
            end
            obj.brandtWt  = brandtWt;
            obj.brandtEng = brandtEng;

            % Payload split from the Brandt inputs (validation targets:
            % 700 + 4,400 lbf; see class header).
            obj.W_payload_fixed      = brandtWt.inp.weight.perm_payload_lb;  % Brandt Main!O16 = 700 lbf
            obj.W_payload_expendable = brandtWt.inp.weight.exp_payload_lb;   % Brandt Main!O17 = 4,400 lbf
        end

        function oew = OEW(obj, W_TO)
        %OEW  Operating empty weight [lbf] at a candidate W_TO [Brandt Wt!B12].
        %   Recomputes on every call (WeightsBase contract): no caching, and
        %   every W_TO-dependent term is evaluated at the PASSED W_TO.
            arguments
                obj  (1,1) BrandtWeightAdapter
                W_TO (1,1) double {mustBePositive, mustBeFinite}
            end

            % 1. Sync the LIVE engine thrust into the weight object's inp
            %    copy: the engine and inlet-duct weight terms scale with AB
            %    SLS thrust (W_engine = 0.199*T, Brandt Wt!B11/B22), and
            %    BrandtPropAdapter.set.T_SL may have rubber-scaled the engine
            %    since the last call.
            obj.brandtWt.inp.engine.T_AB_SLS_lb = obj.brandtEng.T_sl_AB;

            % 2. Re-run the W_TO-free geometry/thrust-dependent pass (cheap
            %    closed-form algebra; Wt C9:H9 + B11 + B24).
            obj.brandtWt.analyze();

            % 3. W_TO-dependent pass (Wt B23:B31 -> B10 -> B12).
            r   = obj.brandtWt.run(W_TO);
            oew = r.W_empty_lb;

            % r.W_fuel_lb is DELIBERATELY ignored: Brandt Wt!B6 is the
            % residual W_TO - payloads - OEW, not a fuel model; the mission
            % object owns fuel in the framework (see class header).
        end

    end

end
