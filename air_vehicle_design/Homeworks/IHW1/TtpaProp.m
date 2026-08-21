classdef TtpaProp < PropulsionBase2

    properties
        P_SL
        engine_type = "Piston Propeller"
    end

    methods

        %% Thrust Available
        function T = available_thrust(obj, state, rating)

            P = obj.power_available(state, rating);
            eta_p = obj.compute_eta_p(state);

            T = eta_p * P * 550 / state.V;

        end


        %% Fuel Mass Flow
        function mdot_f = fuel_flow(obj, state, rating)

            P = obj.power_available(state, rating);
            C_bhp = obj.C_bhp(state);

            mdot_f = C_bhp * P;

        end


        %% Power Available
        function P = power_available(obj, state, rating)

            alpha = obj.power_lapse(state, rating);

            P = alpha * obj.P_SL;

        end


        %% BSFC
        function C_bhp = C_bhp(obj, state)

            % Preliminary piston-engine BSFC [lbm/(hp*hr)]

            C_bhp = 0.4;

        end


        %% Propeller Efficiency
        function eta_p = compute_eta_p(obj, state)

            switch lower(string(state.seg_type))

                case "loiter"
                    eta_p = 0.72;

                case "cruise"
                    eta_p = 0.82;

                otherwise
                    error('TtpaProp:UndefinedSegment', ...
                        'Propeller efficiency is not defined for segment "%s".', ...
                        string(state.seg_type));

            end

        end

    end

end