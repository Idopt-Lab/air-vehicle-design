classdef TtpaProp 

    properties

        engine_type = 'Piston Propeller'
        segment = 'Cruise'
        C_bhp = 0.4
               
    end

    properties (Dependent)

        eta_p
    end

    methods
        function eta_p = get.eta_p(obj)

            switch obj.segment
                case "Cruise"
                    eta_p = 0.82;

                case "Loiter"
                    eta_p = 0.72;
                otherwise
                    error('eta_p unknown for inputted segment')

            end

        end

    end


end
