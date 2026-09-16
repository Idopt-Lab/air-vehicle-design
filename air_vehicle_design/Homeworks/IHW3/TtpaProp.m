classdef TtpaProp < PropulsionBase2
%TTPAPROP  Preliminary piston-propeller propulsion model.
%
%   Provides shaft-power availability, brake-specific fuel consumption,
%   and propeller efficiency for the preliminary TTPA aircraft model.
%
%   IHW2 UPDATE
%   The mission analysis of IHW1 never asked how much power the engines
%   actually make: cruise and loiter used the Breguet equations, and every
%   other segment used a fixed weight fraction. The constraint analysis
%   does ask, so this version adds:
%
%       * a constructor that reads the propulsion block of
%         Ttpa_requirements_IHW2.json, replacing the numbers that used to
%         be typed into this file;
%       * power_lapse(state, rating), the stub of IHW1, now implemented;
%       * power_ratio(state, con), which collects every reason the power
%         at a condition differs from sea-level takeoff power;
%       * a climb case in prop_eff.
%
%   P_SL stays empty until the constraint analysis sizes the engine and
%   writes it back with size_from_design_point.

    properties
        engine_type = "Piston Propeller"

        P_SL = NaN
        % Rated shaft power of ALL engines at sea level [hp].
        % Determined by the sizing framework.

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
            %                [Nicolai & Carichner, Fundamentals of Aircraft
            %                and Airship Design, Vol. I, Eq. 14.5]
            %     rating     "takeoff" is the full rating; "max_continuous"
            %                is the takeoff power divided by
            %                P_TO_over_P_max_continuous
            %
            %   Multiply by P_SL to get shaft power in hp.

            alpha = (1.132 * state.sigma - 0.132) * obj.rating_factor(rating);

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

            if con.max_continuous
                rating = "max_continuous";
            else
                rating = "takeoff";
            end

            kP = obj.power_lapse(state, rating);

            if con.oei
                kP = kP / obj.n_engines;
            end

            kP = kP * con.power_setting;

        end


        %% BSFC
        function C_bhp = C_bhp(obj, state)
            %C_BHP  Returns brake-specific fuel consumption [lbm/(hp*hr)].
            %
            %   Uses a preliminary constant BSFC appropriate for the
            %   piston engine model.

            C_bhp = obj.BSFC;
        end


        %% Propeller Efficiency
        function eta_p = prop_eff(obj, state, miss_seg)
            %PROP_EFF  Returns propeller efficiency [-].
            %
            %   Efficiency is selected based on the current mission
            %   segment. A constraint condition is accepted in place of a
            %   mission segment: both carry a type field, and the climb
            %   gradient conditions of IHW2 use the climb value.

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

end
