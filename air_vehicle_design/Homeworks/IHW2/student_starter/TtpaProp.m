classdef TtpaProp < PropulsionBase2
%TTPAPROP  Preliminary piston-propeller propulsion model.
%
%   IHW2: read the propulsion block, implement the power lapse and the
%   power ratio, and add a climb case to prop_eff.

    properties
        engine_type = "Piston Propeller"

        P_SL = NaN      % rated power of ALL engines at sea level [hp]
                        % stays NaN until the sizing sets it

        % Declared for you, with the JSON key each one is read from. The
        % property name is NOT always the key: the file names the datum and
        % carries its unit, the class keeps the short name the rest of your
        % code uses. Do not rename these.
        n_engines                    % <- J.propulsion.n_engines
        BSFC                         % <- J.propulsion.BSFC_lb_per_hp_hr
        eta_p_cruise                 % <- J.propulsion.eta_p_cruise
        eta_p_loiter                 % <- J.propulsion.eta_p_loiter
        eta_p_climb                  % <- J.propulsion.eta_p_climb
        P_TO_over_P_max_continuous   % <- J.propulsion.P_TO_over_P_max_continuous

    end

    methods

        %% Constructor
        function obj = TtpaProp(json_path)
            arguments
                json_path {mustBeTextScalar, mustBeNonzeroLengthText}
            end

            J = jsondecode(fileread(json_path));

            % TODO: read the propulsion block

        end


        %% Power Lapse
        function alpha = power_lapse(obj, state, rating)
        %POWER_LAPSE  Power at the state and rating, divided by the
        %   sea-level takeoff power of all engines [-].
        %   Nicolai & Carichner Eq. 14.5: 1.132*sigma - 0.132

            alpha = ;

        end


        %% Power Ratio at a Constraint Condition
        function kP = power_ratio(obj, state, con)
        %POWER_RATIO  Power available at the condition, divided by the
        %   sea-level takeoff power of ALL engines [-].
        %
        %   altitude and rating      power_lapse(state, rating)
        %   one engine inoperative   1 / n_engines
        %   throttle setting         con.power_setting

            % TODO: pick the rating from con.max_continuous

            kP = ;

            % TODO: the engine-out split, then the throttle setting

        end


        %% BSFC
        function C_bhp = C_bhp(obj, state)
            C_bhp = ;
        end


        %% Propeller Efficiency
        function eta_p = prop_eff(obj, state, miss_seg)

            switch lower(string(miss_seg.type))

                case "loiter"
                    eta_p = ;

                case "cruise"
                    eta_p = ;

                % TODO: a climb case. A climb-gradient CONDITION has
                %       type = "climb_gradient".

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

            % TODO: "takeoff" and "max_continuous", and an error otherwise

        end

    end

end
