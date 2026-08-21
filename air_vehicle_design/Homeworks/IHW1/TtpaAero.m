classdef TtpaAero < AerodynamicsBase

    properties
        CD0 = NaN;     % Parasitic Drag Coefficient
    end

    properties (Dependent)
        e
        K
        LD_max
    end

    methods

        %% Oswald Efficiency
        function e = get.e(obj)
            e = 1.78*(1 - 0.045*obj.AR^0.68) - 0.64;
        end


        %% Induced Drag Factor
        function K = get.K(obj)

            if isnan(obj.e) || obj.e > 1
                error('Oswald Efficiency is an impossible value')
            else
                K = 1/(pi*obj.AR*obj.e);
            end

        end


        %% Drag Polar
        function polar = drag_polar(obj, state)

            polar.CD0 = 0.028;
            polar.K1  = obj.K;
            polar.K2  = 0;

        end


        %% Maximum Lift Coefficient
        function CLmax = get_CLmax(obj, state)

            % Placeholder until a real CLmax model is implemented
            CLmax = NaN;

        end


        %% Maximum L/D
        function LD_max = get.LD_max(obj)

            LD_max = 1/(2*sqrt(obj.CD0*obj.K));

        end

    end

end