classdef ClimbGradientConstraint < Only_TbyW
%CLIMBGRADIENTCONSTRAINT  FAR-25 climb-gradient constraint (W/S-independent
%   T/W floor).
%
%   Generic Layer-1 constraint. Given a required climb gradient G (= sin gamma),
%   a speed ratio ks = V/V_stall, a high-lift configuration string, and the
%   injected aero/prop objects, it returns the T/W required to hold that
%   gradient. The relation is INDEPENDENT of wing loading (W/S cancels at the
%   fixed climb CL = CLmax/ks^2): Only_TbyW category, read as a flat T/W floor.
%
%   CD0/K1/CLmax are pulled fresh from the aero object each call (through
%   aero.get_config_polar).
%
%   EQUATION [metabook_data.md "§4.7 Climb," Eq. 4.24 with the Eq. 4.25
%   correction factors and the "§4.7" FAR-25 gradient table; worked Example
%   4.2, Eqs. 4.49-4.54]:
%
%     (T/W)_climb = (ks^2/CLmax) * CD0 + (CLmax/ks^2) * (1/(pi*AR*e)) + G   (4.24)
%     (T/W)_req   = (1/0.8) * (1/0.94) * (N/(N-1)) * (W/W_TO) * (T/W)_climb (4.25)
%
%   K-convention: the metabook's 1/(pi*AR*e) IS this repo's K1 (drag polar
%   CD = CD0 + K1*CL^2 + K2*CL). K2 does not appear in the metabook climb form
%   (the tabulated configs are uncambered-basis, K2 = 0). Assembled as:
%
%     TW_min = f_hot * f_mcont * f_oei * weight_ratio
%              * ( ks^2/CLmax * CD0_cfg + CLmax/ks^2 * K1_cfg + G )
%
%     f_hot   = 1/0.8       if hot_day        else 1   (hot-day thrust derate)
%     f_mcont = 1/0.94      if max_continuous else 1   (max-continuous vs takeoff)
%     f_oei   = N/(N-1)     if oei            else 1   (one-engine-inoperative)
%
%   Example 4.2 hand-check, Climb 1 (Eq. 4.49): (1/0.8)(2/1)(1.2^2/2.2 *
%   0.03597 + 2.2/1.2^2 * 0.04054 + 0.012) = 0.243700.
%
%   CD0_cfg/K1_cfg/CLmax are ALL read live from the config polar; this class
%   hardcodes none of them. Two metabook-internal discrepancies live in that
%   DATA but surface here -- see metabook_data.md "Known discrepancies":
%     * D1: printed takeoff-config Eqs. 4.49-4.51 use CLmax = 2.2, though p. 45
%           states CLmax,takeoff = 2.0. RESOLVED: use the printed 2.2, so the
%           takeoff config polar must carry CLmax = 2.2.
%     * D2: printed Eq. 4.49 (gear DOWN per the p. 39 config list) uses the
%           gear-UP CD0 = 0.03597. RESOLVED: use the printed gear-up CD0.
%
%   OEI with N_eng == 1 is undefined (N/(N-1) divides by zero); this errors
%   loudly (ClimbGradientConstraint:oeiSingleEngine). N_eng is a guarded read
%   of the injected prop's n_engines (engine count is a propulsion spec).
%   Mission analysis reads it from geometry; reconciling the owner is a
%   standing item (see ToDo_Darshan.md).

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
        %   from the aero object each call. Fails loudly on a non-finite result:
        %   a NaN T/W floor is silently dropped from the aggregator's envelope.
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
        %   guarded isprop read (engine count is a propulsion spec). Errors
        %   loudly if the injected prop does not expose n_engines.
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
