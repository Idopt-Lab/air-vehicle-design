classdef TtpaProp < PropulsionBase2
%TTPAPROP  Preliminary piston-propeller propulsion model.
%
%   Provides shaft-power availability, brake-specific fuel consumption,
%   and propeller efficiency for the preliminary TTPA aircraft model.

    properties
        engine_type = "Piston Propeller"
        P_SL
    end

    methods

        %% Power Available
        function P = power_available(obj, state, rating)
            %POWER_AVAILABLE  Returns available shaft power [hp].
            %
            %   Applies the propulsion power lapse factor to the
            %   sea-level rated shaft power. Propeller efficiency is
            %   not included; this function returns engine shaft power.

            % alpha = obj.power_lapse(state, rating);
            % 
            % P = alpha * obj.P_SL;

        end


        %% BSFC
        function C_bhp = C_bhp(obj, state)
            %C_BHP  Returns brake-specific fuel consumption [lbm/(hp*hr)].
            %
            %   Uses a preliminary constant BSFC appropriate for the
            %   piston engine model.

            C_bhp = 0.4;
        end


        %% Propeller Efficiency
        function eta_p = prop_eff(obj, state)
            %PROP_EFF  Returns propeller efficiency [-].
            %
            %   Efficiency is selected based on the current mission
            %   segment.

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