classdef TtpaProp < PropulsionBase2
%TTPAPROP  Preliminary piston-propeller propulsion model.
%
%   Provides shaft-power availability, brake-specific fuel consumption,
%   propeller efficiency and - new in IHW3a - engine SIZE for the TTPA.
%
%   IHW3a UPDATE
%   IHW2 asked one question of the engine: how much power does it MAKE.
%   That is power_lapse and power_ratio, and both are unchanged here. A
%   sizing loop asks two more:
%
%       engine_weight()   how heavy is it?  It goes into the empty weight.
%       engine_length()   how long is it?   It sizes the nacelle, and the
%                         nacelle wetted area goes into the drag.
%
%   Both answers follow from P_SL, which is one of the two states the
%   sizing loop iterates on, so both move on every iteration.
%
%       [Raymer Table 10.4, British block, horizontally-opposed column]
%           W_engine = 5.47 * bhp^0.780     [lb per engine]
%           L_engine = 0.32 * bhp^0.424     [ft per engine]
%
%   with bhp the rated power of ONE engine - divide P_SL by n_engines
%   first. Horizontally-opposed is the right column: Raymer Sec. 10.5 notes
%   that opposed engines now dominate general aviation. The regression is
%   printed for 60 to 500 bhp; outside that band these methods WARN and
%   still return a value, because an intermediate iterate of the sizing
%   loop can leave the band and come back.
%
%   P_SL is no longer written once at the end of the analysis. The sizing
%   loop writes it on every iteration, and because this is a handle class
%   every model holding a reference sees the new value at once.

    properties
        engine_type = "Piston Propeller"

        P_SL = NaN
        % Rated shaft power of ALL engines at sea level [hp].
        % A STATE of the sizing loop: written every iteration as
        % W_TO / (W/P). NaN until the loop, or the caller, sets it.

        n_engines
        % Number of engines [-].

        BSFC
        % Brake-specific fuel consumption [lbm/(hp*hr)].

        eta_p_cruise
        eta_p_loiter
        eta_p_climb
        % Propeller efficiencies [-].

        P_TO_over_P_max_continuous
        % Takeoff power / maximum continuous power [-].

        % --- engine-size regression, Raymer Table 10.4 (NEW IN IHW3a) ---
        eng_sizing
    end

    properties (Dependent)
        P_engine
        % Rated power of ONE engine at sea level [hp]. P_SL / n_engines.
    end

    methods (Access = private)

        %% Rating Factor
        function f = rating_factor(obj, rating)
        %RATING_FACTOR  Power of the rating, divided by the takeoff power [-].
            switch string(rating)

                case "takeoff"
                    f = 1;

                case "max_continuous"
                    f = 1 / obj.P_TO_over_P_max_continuous;

                otherwise
                    error('TtpaProp:UndefinedRating', ...
                        'Power rating "%s" is not defined.', string(rating));

            end
        end


    end


    methods

        %% Regression Guard
        function bhp = rated_bhp_per_engine(obj)
        %RATED_BHP_PER_ENGINE  Power per engine, range-checked [hp].
        %   Warns, and does not error, outside the band Raymer Table 10.4
        %   is printed for: a sizing iterate can pass through an
        %   unreasonable power on its way to the answer.
        %
        %   PUBLIC. P_SL is an OUTPUT of the sizing loop, not an input, so
        %   whether the CONVERGED engine falls inside the band the
        %   regression is printed for is a post-convergence check a driver
        %   has to be able to make. Keeping the guard private forced every
        %   driver to re-implement the comparison against bhp_range, which
        %   is the class's own business.
            bhp = obj.P_engine;

            if isnan(bhp)
                error('TtpaProp:PowerNotSet', ...
                    ['P_SL is NaN, so the engine cannot be sized. The ', ...
                     'sizing loop writes P_SL at the start of every ', ...
                     'iteration - call this only after it has.']);
            end

            if bhp < obj.bhp_range(1) || bhp > obj.bhp_range(2)
                warning('TtpaProp:BhpOutOfRange', ...
                    ['Rated power per engine is %.1f hp, outside the %.0f-%.0f hp ', ...
                     'band that the Raymer Table 10.4 opposed-piston regression is ', ...
                     'printed for. The value is still returned; check it if the ', ...
                     'CONVERGED answer is outside the band.'], ...
                    bhp, obj.bhp_range(1), obj.bhp_range(2));
            end
        end

    end

    methods

        %% Constructor
        function obj = TtpaProp(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            % Read requirements JSON
            J = jsondecode(fileread(json_path));

            % Read propulsion-owned data
            P = J.propulsion;

            obj.n_engines    = P.n_engines;
            obj.BSFC         = P.BSFC_lb_per_hp_hr;
            obj.eta_p_cruise = P.eta_p_cruise;
            obj.eta_p_loiter = P.eta_p_loiter;
            obj.eta_p_climb  = P.eta_p_climb;

            obj.P_TO_over_P_max_continuous = P.P_TO_over_P_max_continuous;

            % Engine-size regression
            obj.eng_sizing.engine_scaling_class = string(P.engine_scaling_class);
            obj.eng_sizing.k_W_engine = P.engine_weight_coefficient;
            obj.eng_sizing.n_W_engine = P.engine_weight_exponent;
            obj.eng_sizing.k_L_engine = P.engine_length_coefficient;
            obj.eng_sizing.n_L_engine = P.engine_length_exponent;
            obj.eng_sizing.bhp_range  = P.bhp_range_of_validity;
        end


        %% Power Per Engine
        function val = get.P_engine(obj)
        %GET.P_ENGINE  Rated sea-level power of ONE engine [hp].
            val = obj.P_SL / obj.n_engines;
        end


        %% Power Lapse
        function alpha = power_lapse(obj, state, rating)
            %POWER_LAPSE  Power at the state and rating, divided by the
            %   sea-level takeoff power of all engines [-].
            %
            %   Two effects, multiplied:
            %
            %     altitude   alpha = 1.132*sigma - 0.132, the lapse of a
            %                normally aspirated piston engine
            %                [Nicolai and Carichner, Fundamentals of
            %                Aircraft and Airship Design, Vol. I, Eq. 14.5]
            %     rating     "takeoff" is the full rating; "max_continuous"
            %                is the takeoff power divided by
            %                P_TO_over_P_max_continuous
            %
            %   Multiply by P_SL to get shaft power in hp.
            %   Unchanged from IHW2.

            % altitude term: normally aspirated piston engine
            alpha_altitude = 1.132 * state.sigma - 0.132;

            % rating term: full takeoff power, or the max-continuous derate
            f_rating = obj.rating_factor(rating);

            alpha = alpha_altitude * f_rating;

        end


        %% Power Ratio at a Constraint Condition
        function kP = power_ratio(obj, state, con)
            %POWER_RATIO  Power available at the condition, divided by the
            %   sea-level takeoff power of ALL engines [-].
            %
            %   Collects every reason the two differ, so that a constraint
            %   can be written in terms of the takeoff power loading:
            %
            %     altitude and rating      power_lapse(state, rating)
            %     one engine inoperative   1 / n_engines
            %     throttle setting         con.power_setting
            %
            %   Unchanged from IHW2.

            if con.max_continuous
                rating = "max_continuous";
            else
                rating = "takeoff";
            end

            % one engine of n_engines when the engine-out flag is set
            f_oei = 1;
            if con.oei
                f_oei = 1 / obj.n_engines;
            end

            kP = obj.power_lapse(state, rating) * f_oei * con.power_setting;

        end

        %% BSFC
        function C_bhp = C_bhp(obj, state)
            %C_BHP  Returns brake-specific fuel consumption [lbm/(hp*hr)].
            %
            %   Uses a preliminary constant BSFC appropriate for the
            %   piston engine model. Unchanged from IHW2.

            C_bhp = obj.BSFC;
        end


        %% Propeller Efficiency
        function eta_p = prop_eff(obj, state, miss_seg)
            %PROP_EFF  Returns propeller efficiency [-].
            %
            %   Efficiency is selected based on the current mission
            %   segment. A constraint condition is accepted in place of a
            %   mission segment: both carry a type field, and the climb
            %   gradient conditions use the climb value. Unchanged from
            %   IHW2.

            switch lower(string(miss_seg.type))

                case "loiter"
                    eta_p = obj.eta_p_loiter;

                case "cruise"
                    eta_p = obj.eta_p_cruise;

                case {"climb", "climb_gradient"}
                    eta_p = obj.eta_p_climb;

                otherwise
                    error('TtpaProp:UndefinedSegment', ...
                        'Propeller efficiency is not defined for segment "%s".', ...
                        string(miss_seg.type));

            end

        end

    end


end
