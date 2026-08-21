classdef TtpaProp < PropulsionBase2

    properties
        P_SL
        eta_p
        engine_type = 'Piston Propeller'
    end

    methods

        %% Thrust Available
        function T = available_thrust(obj, state, rating)

            P = obj.power_available(state, rating);

            T = obj.eta_p * P / state.V;

        end

        %% Fuel Mass Flow
        function mdot_f = fuel_flow(obj, state, rating)

            P = obj.power_available(state, rating);
            BSFC = obj.get_BSFC(state);

            mdot_f = BSFC * P;

        end

        %% Power Available
        function P = power_available(obj, state, rating)

            alpha = obj.power_lapse(state, rating);

            P = alpha * obj.P_SL;

        end

        %% BSFC
        function BSFC = get_BSFC(obj, state)

            % Calculate BSFC from engine operating condition.
            %
            % BSFC units should be consistent with P. For example:
            %   BSFC [lbm/(hp*hr)] with P [hp]
            %   gives mdot_f [lbm/hr].

            BSFC = 0.4; 

        end

    end

end