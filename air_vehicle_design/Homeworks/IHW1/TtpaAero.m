classdef TtpaAero 

    properties
        
        AR = 8;          % Aspect Ratio
        CD0 = 0.028;     % Parasitic Drag Coefficient         
    end

    properties (Dependent)
        e
        K

    end

    methods

        function e = get.e(obj)
            e = 1.78*(1 - 0.045*obj.AR^0.68) - 0.64;
        end

        function K = get.K(obj)
            if isnan(obj.e)  || obj.e > 1
                error('Oswald Efficiency is an impossible value')
            else
                K = 1/(pi*obj.AR*obj.e);
            end
        end

    end

end
