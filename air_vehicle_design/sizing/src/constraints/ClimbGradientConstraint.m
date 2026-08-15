classdef ClimbGradientConstraint < Only_TbyW
%CLIMBGRADIENTCONSTRAINT  FAR-25 climb-gradient constraint (W/S-independent
%   T/W floor).
%
%   Generic Layer-1 constraint. Given a required climb gradient G (= sin gamma),
%   a speed ratio ks = V/V_stall, a high-lift configuration string, and the
%   injected aero/prop discipline objects, it returns the thrust-to-weight
%   ratio required to hold that gradient in the specified segment. The
%   climb-gradient relation is INDEPENDENT of wing loading (W/S cancels between
%   the drag and lift terms at the fixed climb CL = CLmax/ks^2), so it belongs
%   to the Only_TbyW category: required_TW returns this same TW_min at every
%   W/S, and the aggregator reads it as a flat T/W floor.
%
%   CD0/K1/CLmax are pulled fresh from the injected aero object each call
%   (through aero.get_config_polar, for the constructor's config string), so
%   the constraint tracks the current sizing-loop iteration and fidelity level.
%
%   EQUATION [Metabook (Aero 481 metabook), docs/reference_extracts/
%   metabook_data.md "§4.7 Climb," Eq. 4.24 with the Eq. 4.25 correction
%   factors and the "§4.7" FAR-25 gradient table; worked Example 4.2,
%   Eqs. 4.49-4.54]:
%
%     (T/W)_climb = (ks^2/CLmax) * CD0 + (CLmax/ks^2) * (1/(pi*AR*e)) + G   (4.24)
%     (T/W)_req   = (1/0.8) * (1/0.94) * (N/(N-1)) * (W/W_TO) * (T/W)_climb (4.25)
%
%   K-CONVENTION MAPPING. The metabook writes the induced-drag term with the
%   explicit Oswald factor 1/(pi*AR*e). This repo's drag polar is
%   CD = CD0 + K1*CL^2 + K2*CL with K1 = 1/(pi*AR*e), so the metabook's
%   1/(pi*AR*e) IS our K1 (the quadratic/induced factor). The class therefore
%   uses CLmax/ks^2 * K1_cfg for the induced term. (K2, the camber-offset term,
%   does not appear in the metabook's climb form and is not added here; the
%   FAR-25 high-lift configs the metabook tabulates are uncambered-basis
%   polars, K2 = 0.)
%
%   Assembled with the Eq. 4.25 correction factors as multiplicative flags:
%
%     TW_min = f_hot * f_mcont * f_oei * weight_ratio
%              * ( ks^2/CLmax * CD0_cfg + CLmax/ks^2 * K1_cfg + G )
%
%     f_hot   = 1/0.8       if hot_day        else 1   (hot-day thrust derate)
%     f_mcont = 1/0.94      if max_continuous else 1   (max-continuous vs takeoff thrust)
%     f_oei   = N/(N-1)     if oei            else 1   (one-engine-inoperative)
%
%   where G is the required gradient sin(gamma) (dimensionless), ks = V/V_stall,
%   and CD0_cfg/K1_cfg/CLmax are the drag polar and max-lift of the segment's
%   high-lift configuration. Example 4.2 hand-check, Climb 1 (Eq. 4.49, TO
%   flaps gear up, two engines, OEI, hot day): (1/0.8)(2/1)(1.2^2/2.2 * 0.03597
%   + 2.2/1.2^2 * 0.04054 + 0.012) = 0.243700.
%
%   CLmax SOURCE (and two metabook-internal discrepancies that surface HERE).
%   CD0_cfg, K1_cfg AND CLmax are ALL read live from the injected aero object
%   for the constructor's config string (aero.get_config_polar(config).CLmax)
%   -- this class hardcodes NEITHER the polar NOR CLmax. So the
%   CLmax used in the induced term is whatever the config polar carries; the
%   worked-example parity value is that config's CLmax, supplied as data, not a
%   constant baked into this class. Two known metabook-internal discrepancies
%   therefore live in the DATA (the config polar), not in this equation, but
%   surface at this constraint -- see docs/reference_extracts/metabook_data.md
%   "Known discrepancies," entries D1 and D2:
%     * D1: the printed takeoff-config climb Eqs. 4.49-4.51 use CLmax = 2.2 in
%           every CLmax slot, although p. 45 states the Roskam Table 3.1
%           assumption CLmax,takeoff = 2.0. RESOLVED (Sarojini 2026-08-13): use
%           the PRINTED 2.2 for worked-example parity, so the takeoff config
%           polar the aero object reports must carry CLmax = 2.2 to reproduce
%           Eqs. 4.49-4.51. This class does not choose 2.2 vs 2.0 -- it reads
%           whatever the injected config polar reports.
%     * D2: printed Eq. 4.49 (FAR 25.111 takeoff climb, gear DOWN per the p. 39
%           config list) uses the gear-UP CD0 = 0.03597, not the gear-down
%           0.06097. RESOLVED (Sarojini 2026-08-13): use the PRINTED gear-up
%           CD0 for parity. Again a config-polar/data choice, not this equation.
%
%   OEI ON A SINGLE-ENGINE AIRCRAFT IS UNDEFINED. If oei is requested with
%   N_eng == 1 the f_oei factor N/(N-1) is a division by zero -- an
%   engine-out climb has no meaning for a single-engine aircraft. This errors
%   loudly (ClimbGradientConstraint:oeiSingleEngine) rather than returning Inf.
%
%   ENGINE COUNT. N_eng is read from the injected propulsion object via a
%   GUARDED isprop read (obj.prop.n_engines) -- engine count is
%   propulsion-system spec, not airframe data, so it is owned by propulsion.
%   NOTE: mission analysis reads the engine count from the geometry object
%   (geom.n_engines) for its own purposes; the two must agree, and reconciling
%   them onto a single owner is a standing item (see ToDo_Darshan.md).

    properties (SetAccess = protected)
        name            % string -- condition label, e.g. "2nd Segment Climb"
    end

    properties (SetAccess = private)
        aero            % AerodynamicsBase -- supplies CD0/K1/CLmax via aero.get_config_polar(config)
        prop            % PropulsionBase   -- supplies engine count via n_engines (guarded read)
        G               % double -- required climb gradient sin(gamma), dimensionless
        ks              % double -- speed ratio V/V_stall at the climb condition
        config          % string -- high-lift configuration name (an aero.get_config_polar config)
        oei             % logical -- one-engine-inoperative segment
        hot_day         % logical -- apply the 1/0.8 hot-day thrust derate
        max_continuous  % logical -- apply the 1/0.94 max-continuous-thrust factor
        weight_ratio    % double -- W/W_TO segment weight fraction (e.g. MLW/MTOW for a balked landing)
    end

    properties (Constant, Access = private)
        HOT_DAY_FACTOR = 1/0.8    % -- Eq. 4.25 hot-day thrust derate
        MCONT_FACTOR   = 1/0.94   % -- Eq. 4.25 max-continuous-thrust factor
    end

    methods

        function obj = ClimbGradientConstraint(name, aero, prop, G, ks, config, opts)
            arguments
                name   (1,1) string
                aero   (1,1) AerodynamicsBase
                prop   (1,1) PropulsionBase
                G      (1,1) double
                ks     (1,1) double {mustBePositive}
                config (1,1) string
                opts.oei            (1,1) logical = false
                opts.hot_day        (1,1) logical = false
                opts.max_continuous (1,1) logical = false
                opts.weight_ratio   (1,1) double {mustBePositive} = 1.0
            end
            obj.name           = name;
            obj.aero           = aero;
            obj.prop           = prop;
            obj.G              = G;
            obj.ks             = ks;
            obj.config         = config;
            obj.oei            = opts.oei;
            obj.hot_day        = opts.hot_day;
            obj.max_continuous = opts.max_continuous;
            obj.weight_ratio   = opts.weight_ratio;
        end

        function TW = TW_min(obj)
        %TW_MIN  T/W required to hold the climb gradient G in this segment, per
        %   the class-header equation (Metabook Eq. 4.24 with the Eq. 4.25
        %   correction factors). W/S-independent -- Only_TbyW.required_TW
        %   returns this at every W/S.
        %
        %   CD0/K1/CLmax are the segment's high-lift config values, pulled fresh
        %   from the aero object each call (aero.get_config_polar). FAILS LOUDLY
        %   on a non-finite result: the config polar can be non-finite (a
        %   mis-injected aero object or an unmodeled config), and a NaN T/W
        %   floor is silently dropped from the aggregator's envelope -- error
        %   here so an un-evaluable climb constraint is a visible failure.
        %
        %   [Metabook Eqs. 4.24-4.25; worked Ex. 4.2 Eqs. 4.49-4.54.]
            cfg = obj.aero.get_config_polar(obj.config);

            f_hot   = 1.0;
            f_mcont = 1.0;
            f_oei   = 1.0;
            if obj.hot_day
                f_hot = ClimbGradientConstraint.HOT_DAY_FACTOR;      % Eq. 4.25 (1/0.8)
            end
            if obj.max_continuous
                f_mcont = ClimbGradientConstraint.MCONT_FACTOR;      % Eq. 4.25 (1/0.94)
            end
            if obj.oei
                N = obj.get_n_engines();
                if N == 1
                    error('ClimbGradientConstraint:oeiSingleEngine', ...
                        ['Constraint "%s": an OEI (one-engine-inoperative) climb ', ...
                         'gradient is undefined for a single-engine aircraft ', ...
                         '(n_engines = 1): the Eq. 4.25 factor N/(N-1) divides ', ...
                         'by zero. Do not request oei=true for a single-engine ', ...
                         'aircraft.'], obj.name);
                end
                f_oei = N / (N - 1);                                 % Eq. 4.25 (N/(N-1))
            end

            % Eq. 4.24 climb T/W (K-convention: metabook 1/(pi*AR*e) = our K1).
            tw_climb = obj.ks^2 / cfg.CLmax * cfg.CD0 ...
                     + cfg.CLmax / obj.ks^2 * cfg.K1 ...
                     + obj.G;

            % Eq. 4.25 corrections.
            TW = f_hot * f_mcont * f_oei * obj.weight_ratio * tw_climb;

            if ~isfinite(TW)
                error('ClimbGradientConstraint:nonFiniteTerm', ...
                    ['Constraint "%s": climb-gradient T/W floor is non-finite ', ...
                     '(TW_min = %s) from config "%s" [CD0 = %s, K1 = %s, ', ...
                     'CLmax = %s], ks = %g, G = %g. The usual cause is a config ', ...
                     'polar that is not modeled at this segment.'], ...
                    obj.name, mat2str(TW, 6), obj.config, mat2str(cfg.CD0, 6), ...
                    mat2str(cfg.K1, 6), mat2str(cfg.CLmax, 6), obj.ks, obj.G);
            end
        end

    end

    methods (Access = private)

        function N = get_n_engines(obj)
        %GET_N_ENGINES  Engine count from the injected propulsion object, via a
        %   guarded isprop read. Engine count is propulsion-system spec (it sets
        %   the OEI factor N/(N-1)), so it is owned by propulsion, not
        %   hardcoded here. Errors loudly naming the contract if the injected
        %   prop object does not expose n_engines.
            if ~isprop(obj.prop, 'n_engines')
                error('ClimbGradientConstraint:missingNEngines', ...
                    ['Constraint "%s": the injected propulsion object (class ', ...
                     '%s) has no n_engines property. An OEI climb-gradient ', ...
                     'constraint needs the engine count to form the Eq. 4.25 ', ...
                     'factor N/(N-1); every PropulsionBase subclass passed to ', ...
                     'ClimbGradientConstraint with oei=true must expose ', ...
                     'n_engines.'], obj.name, class(obj.prop));
            end
            N = obj.prop.n_engines;
        end

    end

    methods (Static)

        function obj = fromCondition(cond, aero, prop)
        %FROMCONDITION  Build from a requirements-JSON condition struct + the
        %   injected aero/prop. Reads cond.G, cond.ks, cond.config and the
        %   optional flag fields cond.oei / cond.hot_day / cond.max_continuous /
        %   cond.weight_ratio (each defaulted to the constructor default when
        %   absent). Uniform factory dispatched by ConstraintType.
            opts = struct();
            if isfield(cond, 'oei') && ~isempty(cond.oei)
                opts.oei = logical(cond.oei);
            end
            if isfield(cond, 'hot_day') && ~isempty(cond.hot_day)
                opts.hot_day = logical(cond.hot_day);
            end
            if isfield(cond, 'max_continuous') && ~isempty(cond.max_continuous)
                opts.max_continuous = logical(cond.max_continuous);
            end
            if isfield(cond, 'weight_ratio') && ~isempty(cond.weight_ratio)
                opts.weight_ratio = cond.weight_ratio;
            end
            optargs = namedargs2cell(opts);
            obj = ClimbGradientConstraint(string(cond.name), aero, prop, ...
                cond.G, cond.ks, string(cond.config), optargs{:});
        end

    end

end
